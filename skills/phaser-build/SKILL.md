---
name: phaser-build
description: This skill should be used when the user asks to "build my game", "run my Phaser game", "start dev server", "deploy my game", "fix build errors", "configure Vite for Phaser", "game won't build", "TypeScript errors in Phaser", "publish to itch.io", or needs to compile, run, troubleshoot, or deploy a Phaser 4 project.
version: 0.8.0
---

# Phaser 4 Build and Deployment

## Development Server

Start the dev server with hot reload:

```bash
npm run dev
```

Serves at `http://localhost:5173` by default — Vite picks the next free port if that is taken, so read the URL it prints. Changes auto-reload in the browser.

## Production Build

```bash
npm run build            # tsc --noEmit + vite build → dist/
npm run preview          # serve dist/ locally
npm run playtest:build   # build + run every scenario against the minified bundle
```

Output in `dist/` — static files ready for any web host.

## Diagnose the Project

Run the validation script before building:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/phaser-build/scripts/validate-project.sh" .
```

The script checks for common issues automatically.

## TypeScript Type Checking

```bash
npx tsc --noEmit
```

Fix all type errors before shipping. Common Phaser 4 TypeScript issues:

**Missing Phaser types:**
```json
// tsconfig.json — Phaser 4 resolves its own types via its exports map
{
  "compilerOptions": {
    "module": "ESNext",
    "moduleResolution": "bundler",
    "skipLibCheck": true
  }
}
```

Then import it explicitly in each file: `import Phaser from 'phaser';`

If you see `TS2688: Cannot find type definition file for 'Phaser'`, the project is carrying
the v3-era `typeRoots` + `types: ["Phaser"]` pair. Delete both keys — Phaser 4 ships a single
`types/phaser.d.ts`, which is not a valid type-root package.

**`this.input.keyboard` nullable:**
```typescript
// Wrong:
const cursors = this.input.keyboard.createCursorKeys();
// Correct:
const cursors = this.input.keyboard!.createCursorKeys();
```

**`sprite.body` nullable:**
```typescript
// Wrong:
sprite.body.velocity.x
// Correct:
(sprite.body as Phaser.Physics.Arcade.Body).velocity.x
// Or:
sprite.body?.velocity.x
```

**`this.scene.get()` returns base Scene type:**
```typescript
// Cast to specific scene class:
const game = this.scene.get('GameScene') as GameScene;
```

## Common Build Errors

### "Cannot find module 'phaser'"

```bash
npm install phaser   # installs Phaser 4 (latest stable). Do NOT use phaser — that tag still points at 4.2.1
```

### Asset 404 Errors (game loads but assets missing)

In Vite, assets must be in the `public/` directory. They are served as-is at the root.

```
✅ public/assets/images/sky.png  → loads as 'assets/images/sky.png'
❌ src/assets/images/sky.png     → won't work with this.load.image()
```

Never import assets via ES imports for Phaser. Just reference the path string:
```typescript
this.load.image('sky', 'assets/images/sky.png');  // ✅
```

### "Phaser.Geom.Point is not a constructor"

v3 → v4 breaking change. Replace with `Vector2`:
```typescript
// Old (v3):
const pt = new Phaser.Geom.Point(x, y);
// New (v4):
const pt = new Phaser.Math.Vector2(x, y);
```

### "Math.PI2 is undefined"

v3 → v4 breaking change:
```typescript
// Old (v3):
const angle = Math.PI2;        // was π (wrong!) in v3
// New (v4):
const angle = Math.TAU;        // π×2
const half = Math.PI_OVER_2;   // π/2
```

### Black Screen on Launch

1. Check browser console for errors (F12)
2. Check for 404s in Network tab (missing assets)
3. Verify scene is in GameConfig's `scene: []` array
4. Verify HTML has `<div id="game-container">` if using `parent: 'game-container'`
5. Try removing `parent` config to append to document.body directly

### WebGL Context Lost

```typescript
// Try Canvas renderer as fallback
const config = {
  type: Phaser.CANVAS,   // instead of Phaser.AUTO or Phaser.WEBGL
  // ...
};
```

Or add WebGL context loss recovery listener:
```typescript
this.game.renderer.on('contextlost', () => {
  console.warn('WebGL context lost — attempting recovery');
});
```

## Vite Configuration

Projects from `/phaser-new` already have the production config; the canonical copy is
`skills/phaser-init/template/vite.config.ts`. What matters in it, for Vite 8:

```typescript
// vite.config.ts (excerpt)
export default defineConfig({
  base: './',                  // relative: works on itch.io, GitHub Pages sub-paths, Netlify, Capacitor
  plugins: [contentSecurityPolicy()],   // CSP <meta> injected at build only
  build: {
    target: 'es2022',
    sourcemap: false,          // don't publish your source
    chunkSizeWarningLimit: 2000,
    rolldownOptions: {
      output: {
        // Phaser in its own long-cached chunk; patches only re-download your code.
        codeSplitting: { groups: [{ name: 'phaser', test: /node_modules[\\/]phaser/ }] },
      },
    },
  },
});
```

Vite 8 bundles with Rolldown and minifies with Oxc. Two consequences for older configs:

- **`minify: 'terser'`** fails the build (`terser not found`) unless terser is
  installed. Delete the line; the default is faster and comparable in size.
- **`build.rollupOptions.output.manualChunks: { phaser: ['phaser'] }`** no longer works —
  Rolldown dropped the object form. Use `rolldownOptions.output.codeSplitting.groups` as above.

**`base: './'` is critical.** With the default `/`, assets resolve from the domain root
and 404 on any sub-path host (itch.io, `user.github.io/repo/`). Relative works everywhere
a single-page game is served, so there is no need for a per-host `base`.

## Deployment Targets

> This section covers the mechanics of getting a build onto a host. For deciding whether
> the game is *ready* — the readiness gate, versioning, store presence, launch day — see
> `skills/phaser-release/`. For CSP, headers, secrets and supply chain, see
> `references/production-hardening.md`.

**Whatever the host: ship a clean build.** `--mode build` playtests build with
`VITE_PLAYTEST=true`, which keeps the test hook in `dist/`. Run a plain `npm run build`
immediately before packaging or uploading.

### itch.io

1. `npm run verify`, then `npm run build`
2. Zip the *contents* of `dist/` (`cd dist && zip -r ../game.zip .`) — not the folder
3. Upload → Kind of project: HTML → "This file will be played in the browser"
4. Set the viewport to the game's design size (or enable fullscreen)

### GitHub Pages

Projects from `/phaser-new` include `.github/workflows/deploy-pages.yml`: on a `v*` tag
or a manual run it runs `npm run verify`, rebuilds clean, and deploys with the official
`actions/upload-pages-artifact` + `actions/deploy-pages`. Every action is pinned to a
full commit SHA, and only the deploy job gets `pages: write` / `id-token: write`. One-time
setup: repo **Settings → Pages → Source: GitHub Actions**. For an older project, copy
the workflow from `skills/phaser-init/template/.github/workflows/`.

Avoid third-party deploy actions that push to a `gh-pages` branch with a write token: the
official flow needs no branch, no `contents: write`, and no extra trust.

### Netlify / Vercel

Connect the git repo. Set:
- Build command: `npm run build`
- Output directory: `dist`

Both auto-deploy on push to main. Add security headers with a `public/_headers` file
(Netlify, Cloudflare Pages) or `vercel.json` — see `references/production-hardening.md`.

### Capacitor (iOS/Android)

```bash
npm install @capacitor/core @capacitor/cli @capacitor/ios @capacitor/android
npx cap init
npx cap add ios
npx cap add android
npm run build
npx cap sync
npx cap open ios    # Opens Xcode
npx cap open android  # Opens Android Studio
```

## Performance Checklist Before Shipping

- [ ] `arcade: { debug: false }` in GameConfig
- [ ] Assets in texture atlases (not individual images)
- [ ] Audio compressed (128kbps MP3 for BGM, 96kbps for SFX)
- [ ] Object pooling for bullets/particles/enemies
- [ ] `maxParticles` set on all particle emitters
- [ ] `npm run verify` passes (typecheck, unit tests, every scenario on the production build)
- [ ] Tested in Chrome, Firefox, and Safari
- [ ] Mobile tested (if targeting mobile)

> For a detailed performance playbook (measurement-first prompting, per-frame allocation elimination, spatial grid, audio lazy-load, atlas packing, tween leak fixes), see `skills/phaser-analyze/references/performance-playbook.md`. Use `/phaser-analyze` for a full project audit before shipping if FPS is a concern.

## Scripts

Run the project validator:
```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/phaser-build/scripts/validate-project.sh" .
```

The validator checks: Phaser version, tsconfig fields, scene registration, removed v3
APIs, Vite 8 config pitfalls, CSP, secret-looking `VITE_*` variables, listener leaks and
asset-key consistency. Exit 0 = no errors, 1 = errors.

## References

- `references/production-hardening.md` — CSP, response headers, secrets, supply chain, client trust
- `references/testing-patterns.md` — Vitest for pure logic, playtest scenarios for runtime

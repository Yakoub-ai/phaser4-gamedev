---
name: phaser-build
description: This skill should be used when the user asks to "build my game", "run my Phaser game", "start dev server", "deploy my game", "fix build errors", "configure Vite for Phaser", "game won't build", "TypeScript errors in Phaser", "publish to itch.io", or needs to compile, run, troubleshoot, or deploy a Phaser 4 project.
version: 0.1.0
---

# Phaser 4 Build and Deployment

## Development Server

Start the dev server with hot reload:

```bash
npm run dev
```

Opens at `http://localhost:5173` (Vite default). Changes auto-reload in the browser.

## Production Build

```bash
npm run build     # Compiles TypeScript + bundles with Vite → dist/
npm run preview   # Serve the dist/ folder locally to test production build
```

Output in `dist/` — static files ready for any web host.

## Diagnose the Project

Run the validation script before building:

```bash
bash scripts/validate-project.sh
```

The script checks for common issues automatically.

## TypeScript Type Checking

```bash
npx tsc --noEmit
```

Fix all type errors before shipping. Common Phaser 4 TypeScript issues:

**Missing Phaser types:**
```json
// tsconfig.json — REQUIRED for Phaser 4 types to work
{
  "compilerOptions": {
    "typeRoots": ["./node_modules/phaser/types"],
    "types": ["Phaser"]
  }
}
```

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
npm install phaser@beta   # NOT npm install phaser (that's Phaser 3)
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

```typescript
// vite.config.ts
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',             // IMPORTANT for itch.io and subdirectory deployment
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    minify: 'terser',
    rollupOptions: {
      output: {
        manualChunks: {
          phaser: ['phaser'],  // Bundle Phaser separately for caching
        },
      },
    },
  },
  server: {
    port: 5173,
  },
});
```

**`base: './'` is critical** for itch.io, GitHub Pages, and any subdirectory deployment. Without it, assets load from `/` (root) which breaks on subdirectory hosts.

## Deployment Targets

### itch.io

1. `npm run build`
2. Zip the `dist/` folder contents (not the folder itself — zip what's inside)
3. Upload the zip to itch.io → "Upload files" → HTML game
4. Set "This file will be played in the browser"
5. Check "SharedArrayBuffer support" if needed

### GitHub Pages

```yaml
# .github/workflows/deploy.yml
name: Deploy to GitHub Pages
on:
  push:
    branches: [main]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-node@v3
        with: { node-version: '18' }
      - run: npm ci
      - run: npm run build
      - uses: peaceiris/actions-gh-pages@v3
        with:
          github_token: ${{ secrets.GITHUB_TOKEN }}
          publish_dir: ./dist
```

Set `base: '/repo-name/'` in vite.config.ts for GitHub Pages (subdirectory).

### Netlify / Vercel

Connect the git repo. Set:
- Build command: `npm run build`
- Output directory: `dist`

Both auto-deploy on push to main.

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
- [ ] `npx tsc --noEmit` passes with 0 errors
- [ ] Tested in Chrome, Firefox, and Safari
- [ ] Mobile tested (if targeting mobile)

## Scripts

Run the project validator:
```bash
bash scripts/validate-project.sh
```

The validator checks: Phaser version, tsconfig fields, presence of scene files, deprecated v3 API usage.

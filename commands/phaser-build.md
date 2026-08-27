---
description: Build the Phaser game for production
---

Build the Phaser 4 game for production deployment.

## Process

1. **Pre-flight check** — Verify `package.json` exists and has a `build` script. If not, suggest running `/phaser-new` or `/phaser-validate`.

2. **TypeScript check first:**
   ```bash
   npx tsc --noEmit
   ```
   If TypeScript reports errors, stop and fix them before building. TypeScript errors in a Phaser project usually mean API misuse — show the errors and suggest the phaser-debugger agent.

3. **Run the production build:**
   ```bash
   npm run build
   ```

4. **Report build results:**
   - Show the `dist/` directory size (use `du -sh dist/`)
   - List the main output files
   - Note if the total size is large (>20MB warns, >50MB is a concern for web games)

5. **Verify the built game actually runs — before recommending deployment:**
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --project . --mode build
   ```

   A successful `npm run build` only means the bundler finished. It does not mean the
   bundle works. This step is where the deploy-breaking bugs surface — the ones that
   never appear in dev:
   - wrong `base` in `vite.config.ts` → every asset 404s on itch.io and GitHub Pages
   - assets referenced from `src/` that were never copied into `dist/`
   - minification breaking code that relies on class or function `.name`
   - a scene tree-shaken away because it is only referenced dynamically

   If it fails, **do not proceed to deployment advice.** Report the failures and fix
   them first. If Playwright is unavailable, say explicitly that the production bundle
   was built but not verified.

6. **Deployment options** — After a successful *and verified* build, remind the user of deployment targets:
   - **itch.io**: Zip the `dist/` folder and upload as HTML game. Set "Kind of project" to "HTML".
   - **GitHub Pages**: Push to a `gh-pages` branch or use GitHub Actions (see phaser-build skill for the workflow YAML).
   - **Netlify/Vercel**: Connect the repo and set build command to `npm run build`, output directory to `dist`.

## Common Build Errors

- **"Cannot find module 'phaser'"** → run `npm install phaser`
- **TypeScript errors on Phaser types** → check the file does `import Phaser from 'phaser';` and that `tsconfig.json` uses `moduleResolution: "bundler"`. If it still sets `typeRoots`/`types: ["Phaser"]`, remove them — that pair fails on v4.
- **Asset 404s in production** → ensure all assets are in `public/` directory
- **Large bundle size** → check for unused imports; Phaser tree-shakes well with Vite

## Performance Check

After building, check:
- `dist/assets/*.js` — the Phaser bundle should be ~1-3MB gzipped
- `dist/assets/*.png` — check no individual texture exceeds 2MB
- Any suspiciously large files → report to user

---
description: Validate the Phaser project structure and check for issues
---

Run a comprehensive validation check on the current Phaser 4 project.

## Process

1. **Check for the validation script** — Look for `skills/phaser-build/scripts/validate-project.sh` relative to the plugin, or for a local copy. If the user has a Phaser project open, run the validation against it.

2. **Run the validation script:**
   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/skills/phaser-build/scripts/validate-project.sh"
   ```

3. **Report results** — Present the output in a clear summary:
   - List all ERRORs (must fix — will break the build or runtime)
   - List all WARNINGs (should fix — best practice issues)
   - List all OK checks (passing)
   - Show a final score: "X errors, Y warnings"

4. **For each error found**, provide the specific fix. Do not just repeat the error — explain what to change and where.

## What Gets Checked

- `package.json` has phaser dependency and dev/build scripts
- `node_modules/phaser` is installed
- `tsconfig.json` uses `moduleResolution: "bundler"`/`node16` and does **not** set the v3-era `typeRoots` + `types: ["Phaser"]` pair
- `src/` directory exists with a main entry point
- At least one scene file exists
- No deprecated Phaser v3 APIs in source files
- Vite config has `base: './'` for subdirectory deployment
- `public/` directory exists for assets

## After Validation

- **0 errors and the playtest passes**: "Project is healthy and verified running. Use `/phaser-build` to create a production build."
- **0 structural errors but the playtest fails**: the project is *not* healthy. Report the runtime failures — do not describe it as passing.
- **Errors found**: Fix each one. The phaser-debugger agent handles runtime issues; the phaser-migrate skill handles v3 API errors.

### Phase 2 — Compile

1. Run `npx tsc --noEmit`. Report any errors and stop here if it fails — nothing
   downstream is meaningful on code that does not compile.
2. Run `npm run build`. Report the `dist/` size. Flag over 20MB (warn) or 50MB
   (error) for a web game.

### Phase 3 — Runtime Verification (do not skip)

Structural checks and a green compile say nothing about whether the game runs. Verify
it by actually running it:

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --project .
node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --project . --mode build
```

The first run tests the dev build; the second tests the production bundle, where
base-path, asset-copying, and tree-shaking bugs appear. Run any scenarios in
`playtest/` as well.

If Playwright is missing, offer to install it
(`npm install -D playwright && npx playwright install chromium`). If the user declines,
state clearly in the report that runtime behaviour was **not verified** — do not let
structural checks stand in for it.

Report exactly what the harness reports: scenes active, canvas rendering, assets
loading, FPS, console and page errors. For each failure, give the diagnosis from the
failure table in `skills/phaser-playtest/SKILL.md`, then fix it and re-run.

### Phase 4 — Pre-Deployment Checklist

Generate `docs/deploy-checklist.md`, marking each item that the harness already
verified as **checked, with the evidence** — leave only genuinely manual items open:

Verified automatically (tick these from the playtest results):
- [ ] Game boots and reaches its first playable scene
- [ ] Canvas renders content (not a black screen)
- [ ] All assets load — no 404s, no `text/html` masking a missing file
- [ ] No uncaught exceptions or console errors
- [ ] Frame rate holds (headless is a regression signal, not a device measurement)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `npm run build` succeeds and the built game runs from `dist/`

Verified by inspection (grep the source):
- [ ] `arcade: { debug: false }` in the production GameConfig
- [ ] `console.log` removed or gated behind `import.meta.env.DEV`
- [ ] `vite.config.ts` has the correct `base` for the deployment target
- [ ] Bundle size under budget

Genuinely manual — state that these remain unverified:
- [ ] Tested in Firefox and Safari (the harness runs Chromium only)
- [ ] Tested on real iOS and Android hardware (emulation is not Safari)
- [ ] Audio is audibly correct (the harness confirms playback state, not sound)
- [ ] No memory leak over a 5-minute session
- [ ] The game is actually fun and readable

Do not tick an item the project has not actually passed. A checklist that overstates
its coverage is worse than no checklist.

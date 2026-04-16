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
- `tsconfig.json` has correct `typeRoots` and `types: ["Phaser"]`
- `src/` directory exists with a main entry point
- At least one scene file exists
- No deprecated Phaser v3 APIs in source files
- Vite config has `base: './'` for subdirectory deployment
- `public/` directory exists for assets

## After Validation

- **0 errors**: "Project is healthy. Use `/phaser-build` to create a production build."
- **Errors found**: Fix each one. The phaser-debugger agent can help with runtime issues; the phaser-migrate skill helps with v3 API errors.

### Enhanced Validation (Phase 2)

After structural validation passes, perform these additional checks:

**Runtime Verification:**
1. Run `npx tsc --noEmit` to check TypeScript compilation — report any errors
2. Run `npm run build` to verify the full build succeeds — report dist/ directory size
3. Flag if dist/ total size exceeds 20MB (warn) or 50MB (error for web games)

**Smoke Test Generation:**
After validation, generate a `docs/smoke-test-checklist.md` customized to the project's scenes. For each scene found in the project:
- "[ ] Navigate to [SceneName] — verify it loads without console errors"
- For BootScene: "[ ] Verify transition to PreloaderScene happens automatically"
- For PreloaderScene: "[ ] Verify loading bar fills and transitions to next scene"  
- For GameScene: "[ ] Verify player spawns, controls respond, physics work"
- For physics games: "[ ] Verify gravity applies correctly, collisions trigger"
- For audio: "[ ] Verify background music plays after first user interaction"
- For mobile-targeted games: "[ ] Test on Chrome DevTools mobile emulator at 375x667"
- For HUDScene: "[ ] Verify score/health display updates during gameplay"

**Pre-Deployment Checklist:**
Generate a `docs/deploy-checklist.md` with:
- [ ] `arcade: { debug: false }` in GameConfig (no physics debug outlines)
- [ ] All `console.log` statements removed or gated behind `import.meta.env.DEV`
- [ ] All assets load without 404 errors (check Network tab)
- [ ] `npx tsc --noEmit` passes with zero errors
- [ ] `npm run build` succeeds
- [ ] Built game in `dist/` runs correctly
- [ ] Game tested in Chrome, Firefox, Safari
- [ ] Mobile tested if targeting mobile (iOS Safari, Android Chrome)
- [ ] Controls work: keyboard (desktop), touch (mobile), gamepad (if supported)
- [ ] Scale Manager responsive at multiple screen sizes
- [ ] `vite.config.ts` has correct `base` for deployment target
- [ ] Bundle size under 20MB total
- [ ] No memory leaks (play 5 minutes, check DevTools Memory tab)

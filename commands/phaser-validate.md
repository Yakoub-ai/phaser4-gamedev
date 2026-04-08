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

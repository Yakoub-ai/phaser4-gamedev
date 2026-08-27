---
description: Start the Phaser dev server and verify the game boots
---

Start the Phaser 4 development server and confirm the game actually runs.

## Process

1. **Check for package.json** — If none is found in the current directory, tell the user this is not a Node.js project and suggest `/phaser-new`. Stop.

2. **Check for node_modules** — If `node_modules/` does not exist, run `npm install` first.

3. **Check for the phaser dependency** — Look in `package.json` for `"phaser"`. If missing, warn and suggest `npm install phaser`.

4. **Type-check** — Run `npx tsc --noEmit`. Report any errors before starting the server; a project that does not compile will not run.

5. **Start the dev server in the background.** Do not run `npm run dev` in the foreground — it never exits and blocks the session.

   ```bash
   npm run dev
   ```

   Run this as a background command. Then read its output to find the actual URL —
   Vite auto-increments the port when 5173 is taken, so never assume the port. Wait
   until the server reports its `Local:` URL before continuing.

6. **Verify it boots.** Starting a server proves nothing about the game. Confirm it
   with the playtest harness against the running server:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --url <the URL from step 5>
   ```

   This catches black screens, asset 404s, uncaught exceptions, and dead scenes in a
   few seconds — the failures the user would otherwise have to find by hand.

   If Playwright is not installed, skip this step, say plainly that the game was
   started but **not verified**, and offer to install it:
   `npm install -D playwright && npx playwright install chromium`

7. **Report to the user:**
   - The actual URL the game is served at
   - The verification result — pass, or the specific failures found
   - That hot reload is active, and that some Phaser state (scene instances, loaded
     textures, physics bodies) does not hot-reload cleanly — hard-refresh when
     behaviour looks stale
   - That the server is running in the background, and how to stop it

## Troubleshooting

- **"Command not found: vite"** → run `npm install`
- **"Port already in use"** → Vite auto-selects the next port; use the URL it prints, not 5173
- **Black screen** → do not guess. Run `/phaser-playtest` and read `.playtest/report.json` and the screenshot, then hand off to the phaser-debugger agent with the actual error
- **Server exits immediately** → read its output; usually a Vite config error or a missing `index.html`

## Related

- `/phaser-playtest` — full runtime verification, including scripted input and production-build mode
- `/phaser-validate` — structural + runtime health check of the whole project

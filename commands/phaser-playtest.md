---
description: Run the game headless and verify it actually works
argument-hint: [dev|build|mobile] — optional mode, defaults to dev
---

Verify the Phaser 4 game actually runs, using the headless playtest harness. This is
runtime verification, not type checking — it catches black screens, asset 404s,
uncaught exceptions, dead scenes, and FPS collapse.

Interpret $ARGUMENTS as the mode: `dev` (default), `build` (production bundle), or
`mobile` (iPhone viewport). If no argument was given, use `dev`.

## Process

1. **Check prerequisites.**
   - `package.json` must exist. If not, tell the user to run `/phaser-new` first and stop.
   - `node_modules/` missing → run `npm install`.
   - Playwright missing from the project → install it:
     ```bash
     npm install -D playwright && npx playwright install chromium
     ```
     Say what you're installing and why before running it.

2. **Type-check first.** Run `npx tsc --noEmit`. If it fails, report the errors and
   stop — a build that does not compile cannot be playtested.

3. **Run the harness.**
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --project .
   ```
   Append `--mode build` for `build`, or `--device iphone` for `mobile`.

   If the project has scenarios in `playtest/`, run each one with `--scenario`.

   The harness manages the dev server itself — do not start `npm run dev` separately.

4. **Report results faithfully.**
   - State the pass/fail/warning counts as reported. Never describe a failing
     playtest as working.
   - For each failure, give the diagnosis from the harness's failure table in
     `skills/phaser-playtest/SKILL.md` — not just a restatement of the error.
   - `Phaser game instance found` warning → tell the user the one-line fix and offer
     to apply it, since it unlocks all the deep checks.

5. **Fix what failed.** Follow investigation-first discipline: read the relevant
   source, explain the cause, then propose the fix. For runtime bugs, hand off to the
   phaser-debugger agent. Re-run the harness after each fix and report the new
   result — do not claim a fix works without re-running.

6. **Show the evidence.** Screenshots land in `.playtest/`. Read the boot screenshot
   and describe what actually rendered. If the user is looking at a visual bug, the
   screenshot is the primary evidence.

## When to run this

- After any change to scene lifecycle, asset loading, physics, or rendering
- Before telling the user a feature is complete
- Before `/phaser-build` and any deploy (use `build` mode)
- Whenever the user reports something that "doesn't work" — reproduce it here first

## Notes

- FPS in headless Chromium is software-rendered. Treat it as a regression signal
  between runs, not a real-device measurement.
- Exit code 2 means the harness itself failed (server never started, Playwright
  missing) — that is not a game failure. Fix the invocation and re-run.

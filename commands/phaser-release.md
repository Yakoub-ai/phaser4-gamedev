---
description: Run the release gate and prepare the game for players
argument-hint: [check|prepare|ship] — defaults to check
---

Take a Phaser 4 game from "it works on my machine" to released. Interpret $ARGUMENTS as
the stage: `check` (default — run the gate and report), `prepare` (gate plus store
assets), or `ship` (gate, assets, and the launch-day sequence).

Read `${CLAUDE_PLUGIN_ROOT}/skills/phaser-release/SKILL.md` and follow it.
`references/release-checklist.md` is the full gate.

## Process

1. **Run the readiness gate.** Nothing else matters until this passes.

   ```bash
   npx tsc --noEmit
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --project . --mode build
   ```

   Then every scenario in `playtest/`, in build mode. Add `--device iphone` if the game
   claims mobile support, and `--heap` with a long-session scenario.

   **`--mode build` is not optional here.** Dev mode hides the failures only players hit:
   a wrong `base` that 404s every asset, assets that never reached `dist/`, minification
   breaking `.name` lookups, tree-shaking dropping a dynamically-referenced scene.

   Report results faithfully. A failing gate means not ready — say that plainly rather
   than listing caveats around a release.

2. **Work the checklist.** Go through `references/release-checklist.md`. Report what
   passes, what fails, and what you cannot verify automatically — the manual items
   (playing it end to end, a stranger playing it unassisted, audio on headphones and
   speakers, a real phone) are real gate items, not suggestions. Do not mark them passed
   on the user's behalf.

3. **Check versioning.** The game should carry a version read from `package.json` at
   build time and displayed in-game. Save data should carry its own separate version
   number. If save versioning is missing and the game has saves, raise it now — adding it
   after players have saves is a migration against data you cannot test.

4. **Store assets** (`prepare` and `ship`). Write a `playtest/showcase.mjs` scenario that
   plays the most visually interesting ten seconds, and capture it:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" \
     --project . --scenario playtest/showcase.mjs --video --mode build
   ```

   Then draft the one-line hook, the description, the controls block and the tags. See
   `references/store-presence.md`. The capture matters more than any of the text — people
   watch before they read.

5. **Launch sequence** (`ship`). Confirm the feedback path is live and being watched
   *before* announcing, verify against the deployed URL with `--url`, and confirm a
   rollback build is kept and the rollback steps are written down.

6. **Point at the loop.** After release, feedback goes through `/phaser-feedback`, and
   each reproduced bug leaves a `playtest/repro-*.mjs` behind that joins the gate for the
   next release.

## Report back

| Item | Status |
|---|---|
| tsc | pass |
| build-mode playtest | pass |
| scenarios (7) | 6 pass, 1 fail |
| mobile | not claimed |
| manual: stranger playthrough | not done — needs the user |

End with a clear verdict: ready, or not ready and what specifically blocks it.

## Notes

- Deployment mechanics per host live in `skills/phaser-build/` — this command is about
  readiness and presentation, not the upload.
- Never describe a game with a failing gate as ready to ship, however small the failure
  looks. The most common launch failure is a build that was perfect in dev.

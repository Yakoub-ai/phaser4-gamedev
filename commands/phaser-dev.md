---
description: Implement the next phase of docs/ARCHITECTURE.md and prove it works with playtests
argument-hint: [phase] — phase number; defaults to the first phase not marked done
---

Build one phase of the game: turn its exit conditions into playtest scenarios, implement
until they pass, and leave them in place as regression tests. One phase per run — small
verified steps beat one large unverified one.

## Process

1. **Preconditions.**
   - No `package.json` with `phaser` → suggest `/phaser-new` and stop.
   - No `docs/ARCHITECTURE.md`:
     - `docs/GDD.md` exists → delegate to the phaser-architect agent to write it, show the
       phase list, and stop for the user's review.
     - Neither → suggest `/phaser-brainstorm` or `/phaser-gdd`. For a one-off change
       that needs no plan, use the phaser-coder agent directly instead of this command.

2. **Baseline.** Run `npm run verify` (or `npx tsc --noEmit` plus
   `node tools/playtest.mjs --project . --scenario playtest` on a project without that
   script). If it is red, stop: report it and fix that first. Never layer a phase on a
   broken base.

3. **Select the phase.** $ARGUMENTS if given, otherwise the first `### Phase N` whose
   status is not `[x]`. Show its scope and exit-condition table. If the phase involves
   AI, physics or collisions, propose the approach in a few lines and wait for approval
   before writing code.

4. **Write the tests first.**
   - Each `auto` exit condition → an `expect` step in `playtest/phase-<N>-<slug>.mjs`
     (step format: `skills/phaser-playtest/examples/scenario.example.mjs`). Drive real
     input (`key`, `press`, `click`, `tap`) for anything a player does; use `eval` only
     to set up state.
   - Pure rules (damage, scoring, spawning tables, grid logic) → Vitest tests in
     `tests/`, with the logic in a Phaser-free module under `src/logic/`.
   - Run the new scenario and confirm it **fails** for the right reason. A test that
     passes before the feature exists tests nothing.

5. **Implement.** Delegate to the phaser-coder agent with the phase section, the exit
   table, the new test files and the relevant skill names (e.g. `phaser-physics`,
   `phaser-tilemap`, `phaser-ui`). Expose any state a scenario asserts on as a public
   field or a registry key.

6. **Gate.** All must pass:
   ```bash
   npx tsc --noEmit
   npm test
   npm run playtest          # every scenario — earlier phases are the regression suite
   ```
   On failure follow investigation-first (read, explain cause, then fix) and the
   2-attempt pivot rule: after two failed approaches, stop and propose 2–3 different ones.
   At the end of the phase also run `npm run playtest:build` — minification, base-path
   and CSP problems only appear there.

7. **Close the phase.** Set its status to `Status: [x] done — verified <YYYY-MM-DD>` in
   `docs/ARCHITECTURE.md`. Read the final screenshot in `.playtest/` and describe what
   actually rendered.

8. **Report.**
   - What changed (files) and the gate results with pass counts.
   - The `human` exit conditions, as a short checklist for the user to try in
     `npm run dev` — these are not verified and must not be presented as if they were.
   - The next phase, and a suggestion to commit this one before starting it.

## Rules

- Never weaken, skip or delete an existing scenario to make a phase pass. If a
  scenario is genuinely obsolete because the design changed, say so and ask first.
- If the plan turns out to be wrong (an exit condition is untestable, a phase is too
  big), propose the edit to `docs/ARCHITECTURE.md` rather than silently diverging.

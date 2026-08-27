---
description: Triage pasted player feedback, reproduce it, fix it, and verify
argument-hint: paste the feedback (Discord, itch.io, QA notes, reviews) — or a file path
---

Take raw player feedback and drive it all the way to verified fixes. This is the loop
that runs after a build is in players' hands.

$ARGUMENTS is the feedback itself, pasted in whatever form it arrived. If it looks like a
file path, read that file. If it is empty, ask the user to paste the feedback and stop.

Read `${CLAUDE_PLUGIN_ROOT}/skills/phaser-feedback/SKILL.md` and follow it. The steps
below are the operational summary; the skill and its references carry the detail.

## Process

1. **Intake, verbatim.** Restate each distinct item exactly as written, with its source
   and how many people reported it. Do not merge, tidy, or translate into technical
   language yet — words like "sometimes", "after a while", "on my phone" and "it used to
   work" each change how the item gets reproduced.

   For anything platform-shaped, ask for device posture before proceeding: browser and
   version, iOS vs Android, Safari tab vs PWA vs Capacitor, orientation, touch vs mouse.

2. **Triage into four kinds** — defect, tuning, design, unactionable — plus taste, which
   gets labelled rather than processed. See
   `skills/phaser-feedback/references/triage-guide.md`.

   **Show the user the triage table before writing any code.** A misclassification
   corrected here costs a sentence; found after the fix, it costs the session. Tuning
   and design items need the user's decision — do not invent a numeric target for
   "too hard" or "feels floaty".

3. **Group by suspected root cause.** Separate reports often share one. State the
   grouping and why, since grouped symptoms point at a cause far faster than any single
   symptom does.

4. **Reproduce before fixing.** For each defect, write a failing scenario in
   `playtest/repro-<player's-complaint>.mjs` and run it:

   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" \
     --project . --scenario playtest/repro-NAME.mjs
   ```

   It **must fail first**. A repro that passes has not reproduced anything, and the fix
   that follows is aimed at nothing — go back and get more detail from the reporter.

   If the report said "sometimes", add `--repeat 10` and read the verdict; add `--seed 42`
   to separate an RNG-dependent bug from a timing one. For "gets slower over time", add
   `--heap`. For platform reports, add `--device iphone` or `--device android`.
   `skills/phaser-feedback/references/feedback-to-scenario.md` maps each claim shape to
   its construct.

5. **Fix, investigation-first.** Read the source, explain what is causing it and why,
   propose the approach, and get agreement before implementing. If an approach fails
   twice, stop and propose two or three genuinely different ones. Fix the grouped cause,
   not each symptom.

6. **Verify both directions.** The repro must now pass — repeatedly, if the bug was
   intermittent, since one green run on a 3-in-10 bug is the same coin flip that hid it.
   Then re-run every other scenario plus `npx tsc --noEmit` and `--mode build` to confirm
   nothing else broke. Report the counts faithfully; a fix that trades one bug for two is
   not done.

7. **Reply to the reporters.** Per item, quoting their words, in their language — what
   you fixed, what you changed and want checked, and what you still need from them. See
   `skills/phaser-feedback/references/response-templates.md`. Offer the user a
   player-facing changelog entry too.

8. **Keep the scenarios.** Every `playtest/repro-*.mjs` stays committed as a regression
   test. This is what makes feedback compound instead of recurring.

## Report back

End with a table the user can act on:

| Report | Kind | Status | Needs |
|---|---|---|---|
| "fall through platform" | defect | fixed, verified 20/20 | — |
| "boss impossible" | tuning | open | target from user |
| "shop is broken" | unactionable | open | question sent to reporter |

Unresolved items are a correct outcome when they are unresolved *for a stated reason*.
Shipping a guess at a tuning value is not better than asking.

## Notes

- The game must expose its state for any of this to work. If scenes keep everything in
  closures, say so and fix it first — `skills/phaser-playtest/references/instrumenting-games.md`.
- Players are on the built bundle, so reproduce anything they saw with `--mode build`
  where it could be a base-path or bundling issue.
- Headless FPS is software-rendered. Never use it to confirm or deny a performance
  report from a real device — route those through `/phaser-analyze`.

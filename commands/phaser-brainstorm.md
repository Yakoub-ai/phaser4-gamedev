---
description: Shape a game idea into something buildable and correctly scoped
argument-hint: [your idea, or nothing at all if you don't have one yet]
---

Turn a vague idea — or no idea — into a concept that is worth building and small enough
to finish. This runs before `/phaser-gdd`.

$ARGUMENTS is the starting idea, if there is one. If it is empty, the user does not have
one yet; start from the constraints instead and generate.

Read `${CLAUDE_PLUGIN_ROOT}/skills/phaser-brainstorm/SKILL.md` and follow it.

## Process

1. **Establish the constraints first.** Ask about time available, audience, art and audio
   capability, and what the user has finished before. Do not generate ideas before these
   are answered — an idea generated without them is a coin flip, and enthusiasm for a
   wrongly-sized project is how the next six months get spent.

2. **Find or sharpen the hook.** A genre is not a concept. Push until there is one
   sentence containing a verb nobody expects. `references/ideation-prompts.md` has
   generators for when the user is stuck: constraints, mechanic inversions, mashups,
   feeling-first, and working from assets that already exist.

3. **Size it honestly against the time available.** Use
   `references/scope-calibration.md` for real hour estimates by system. Show the
   arithmetic rather than asserting that something is ambitious — naming which lines are
   the problem is what makes a scope conversation land. Multiply estimates by three.

4. **Pressure-test.** Run the six questions in the skill. Weak answers are cheap to find
   now and expensive to find in month three.

5. **Check it suits Phaser 4.** Say plainly if it does not — 3D is the clear case. Note
   where Phaser 4 specifically changes what is affordable: `SpriteGPULayer` for very high
   sprite counts, cone lights for stealth vision, filters on any object.

6. **Deliver a decision, not a menu.** One concept, the scope call and what was cut, a
   prototype described in days, the named risk, and the next command to run. If the user
   brought several ideas, recommend one and say why — a ranked list avoids the decision
   they came for.

## Then

- `/phaser-new` — scaffold and prototype the core mechanic. For anything beyond a jam,
  do this **before** the GDD: a design document for a mechanic nobody has felt yet is
  fiction.
- `/phaser-gdd` — write the design document once the mechanic is proven to feel good.

## Notes

- Push back on scope. Agreeing to a plan you expect to fail costs the user months and
  costs you nothing at the time, which is exactly why it happens.
- If the honest answer is that the idea will not fit, give a specific estimate, the
  reason, and an alternative that keeps the hook intact.
- "Would you play it?" is a real question, not a rhetorical one. If no, say so.

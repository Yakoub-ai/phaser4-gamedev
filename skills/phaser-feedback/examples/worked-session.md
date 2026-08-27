# Worked Session: One Discord Paste, End to End

A realistic pass through the loop. The feedback below is the kind that actually arrives:
unstructured, mixed-kind, partly unactionable, with the most important detail buried in
a throwaway clause.

---

## The paste

> **@rin** — ok played for like 40 min. jump feels floaty. sometimes i just fall
> straight through the moving platform in level 2?? also i clipped into the wall doing
> the dash once. the boss is impossible i gave up after 12 tries. shop is broken. oh and
> it got really choppy near the end
>
> **@dmitri** — +1 on the platform thing, happened to me on the lift in level 2
>
> **@kass** — the dash goes through walls sometimes lol

---

## Step 1 — Intake

Verbatim, with source and the words that carry information marked:

| # | Report | Source | Signal words |
|---|---|---|---|
| 1 | "jump feels floaty" | rin | — |
| 2 | "**sometimes** i just fall straight through the moving platform in level 2" | rin, +dmitri | *sometimes*, *moving*, *level 2* |
| 3 | "i clipped into the wall doing the dash **once**" | rin, +kass | *once*, *dash* |
| 4 | "the boss is impossible, gave up after **12 tries**" | rin | *12 tries* — a number! |
| 5 | "shop is broken" | rin | — |
| 6 | "got really **choppy near the end**" | rin | *near the end* — accumulation |

Note #4: "12 tries" is the only number in the whole paste, and it turns the vaguest-
sounding complaint into the most actionable one.

Note #6: "near the end" is not "in the last level". It is a *time* claim, which makes it
an accumulation report, not a level-specific one.

---

## Step 2 — Triage

| # | Kind | Reasoning |
|---|---|---|
| 1 | **Tuning** | Gravity is doing what it is set to. Fix is a number; the user picks it. |
| 2 | **Defect** | It should have landed. Two reporters. |
| 3 | **Defect** | Passing through a wall is never designed. |
| 4 | **Tuning** | Nothing broken; the fight is too long or too damaging. |
| 5 | **Unactionable** | No route to a repro. Ask. |
| 6 | **Defect** (probable) | "Near the end" + 40 min ⇒ accumulation, not a heavy scene. |

---

## Step 3 — Group by root cause

**#2 and #3 look like one bug.** Falling through a platform and dashing through a wall
are both *a fast-moving body crossing a thin collider between physics steps*. The dash is
the fastest thing in the game; a falling player on a moving platform is the second. Both
are "sometimes", which fits a per-frame displacement that only occasionally exceeds the
collider thickness.

Treat as one investigation. If one fix closes both, the grouping was right.

**#6 is on its own**, but note it may interact: 40 minutes of play is exactly when
accumulated objects would start costing frames.

Grouped worklist:

| Priority | Item | Kind |
|---|---|---|
| 1 | #2 + #3 — tunnelling | Defect |
| 2 | #6 — degradation over time | Defect |
| 3 | #5 — shop | Blocked on rin |
| 4 | #4 — boss difficulty | Tuning, target known-ish |
| 5 | #1 — jump feel | Tuning, needs target |

---

## Step 4 — Reproduce

### Repro A — tunnelling (#2 + #3)

```javascript
// playtest/repro-fall-through-moving-platform.mjs
export default [
  { name: 'start at the level 2 lift', action: 'scene',
    key: 'GameScene', data: { level: 2, checkpoint: 'lift' }, settle: 800 },

  { name: 'drop onto the lift from height, as reported', action: 'eval', code: `
      const s = scene('GameScene');
      s.player.setPosition(s.lift.x, s.lift.y - 320);
      s.player.body.setVelocityY(0);
  ` },

  { name: 'player ends up standing on the lift', action: 'waitFor',
    expression: `scene('GameScene').player.body.blocked.down`, timeout: 3000 },

  // The negative half. A player who tunnelled has also stopped falling —
  // at the bottom of the level. Without this the repro passes on the bug.
  { name: 'and is above the lift, not below it', action: 'expect',
    expect: { expression: `scene('GameScene').player.y - scene('GameScene').lift.y`, below: 0 } },
];
```

```bash
node .../playtest.mjs --project . --scenario playtest/repro-fall-through-moving-platform.mjs --repeat 10
```

```
run 1/10: clean
run 2/10: 1 failed assertion(s)
...
[FAIL] scenario stability — INTERMITTENT — failed in 3/10 runs:
       and is above the lift, not below it: ... below 0 (3/10)
```

Reproduced, intermittent. Now split RNG from timing:

```bash
node .../playtest.mjs --project . --scenario playtest/repro-fall-through-moving-platform.mjs --repeat 10 --seed 42
```

```
[FAIL] scenario stability — INTERMITTENT — failed in 4/10 runs
```

Still intermittent under a fixed seed ⇒ **timing, not RNG**. Consistent with the
tunnelling theory: whether the body crosses the collider depends on where in its travel
the platform is when the frame lands, not on any random roll.

Second scenario for the dash, same suspected cause:

```javascript
// playtest/repro-dash-through-wall.mjs
export default [
  { name: 'stand next to the wall', action: 'eval', code: `
      const s = scene('GameScene');
      s.player.setPosition(s.testWall.x - 40, s.testWall.y);
  ` },
  { name: 'dash into it', action: 'hold', keys: ['ArrowRight', 'ShiftLeft'], duration: 400 },
  { name: 'player is still on the near side of the wall', action: 'expect',
    expect: { expression: `scene('GameScene').player.x`, below: `` } },
];
```

> The last assertion needs a number, not an empty expression — resolve it against the
> wall's actual x before running. Left visible here because this is exactly the point
> where a repro is easy to write wrong: an assertion that cannot fail is not a repro.

### Repro B — degradation over time (#6)

```javascript
// playtest/repro-slowdown-over-session.mjs
export default [
  { action: 'repeat', times: 25, steps: [
      { action: 'eval', code: `scene('GameScene').scene.restart()` },
      { action: 'wait', ms: 400 },
  ] },
  { name: 'framerate survives 25 scene restarts', action: 'expect',
    expect: { expression: `game.loop.actualFps`, atLeast: 50 } },
];
```

```bash
node .../playtest.mjs --project . --scenario playtest/repro-slowdown-over-session.mjs --heap
```

```
[FAIL] framerate survives 25 scene restarts: game.loop.actualFps >= 50 — got 31.2
[WARN] heap growth — +180.4 MB over the session (68.1 → 248.5 MB)
```

Reproduced, and the heap number names the cause: something is surviving `restart()`.

---

## Step 5 — Fix

**Tunnelling.** Investigation first: the dash sets velocity to 1800 px/s; at 60fps that
is 30px of travel per step, and the lift collider is 16px thick. The body crosses it
entirely between steps and never registers an overlap. It is not intermittent in any
meaningful sense — it depends on where in the 30px stride the collider happens to sit,
which is why it fires perhaps a third of the time.

That reading is worth stating before writing code, because it rules out the fix most
people reach for first (adding a second collider) and points at the real options:
thicker colliders, a swept check, or a capped per-step displacement.

**Slowdown.** The heap figure and the restart trigger together point at listeners
registered in `create()` without teardown — every restart adds another set, and each one
keeps its captured scene alive.

Both fixes go through the normal discipline: propose, get agreement, implement, and pivot
after two failed attempts rather than iterating a third time.

---

## Step 6 — Verify

```bash
npx tsc --noEmit

# The repros, repeated — a single green run on an intermittent bug is the same
# coin flip that hid it in the first place.
node .../playtest.mjs --project . --scenario playtest/repro-fall-through-moving-platform.mjs --repeat 20
node .../playtest.mjs --project . --scenario playtest/repro-dash-through-wall.mjs --repeat 20
node .../playtest.mjs --project . --scenario playtest/repro-slowdown-over-session.mjs --heap

# Nothing else broke.
for f in playtest/*.mjs; do node .../playtest.mjs --project . --scenario "$f" || break; done
node .../playtest.mjs --project . --mode build
```

Twenty clean runs on a bug that reproduced 3-in-10 is meaningful. Two clean runs is not.

One fix closing both #2 and #3 confirms the grouping. Had it closed only one, the right
move is to say so and re-group — not to patch the other separately.

---

## Step 7 — Reply

> Thanks rin, dmitri, kass — that was a useful 40 minutes.
>
> > "sometimes i just fall straight through the moving platform"
> > "i clipped into the wall doing the dash once"
>
> Both fixed, and they were the same bug: moving fast enough carried you across a thin
> platform between physics steps, and the dash is the fastest thing in the game. Fixed
> for both.
>
> > "it got really choppy near the end"
>
> Fixed. Some things weren't being cleaned up when a level restarted, so they piled up
> over a long session. After 40 minutes it would have been noticeably worse than at the
> start — which matches exactly what you saw.
>
> > "jump feels floaty"
>
> Not changed yet — I don't want to guess. Should it be snappier overall, or is it the
> hang at the top of the arc specifically?
>
> > "the boss is impossible, gave up after 12 tries"
>
> 12 is way past where I want that fight. What would have felt fair — 3 or 4? I can take
> it out of its health or its damage, and those feel different to play.
>
> > "shop is broken"
>
> Couldn't reproduce this one. I tried buying with no gold and with a full inventory and
> both behaved. What did you click, and what happened instead?

---

## What is left behind

```
playtest/
  repro-fall-through-moving-platform.mjs
  repro-dash-through-wall.mjs
  repro-slowdown-over-session.mjs
```

Committed, and run from now on. The tunnelling pair in particular is the kind of bug that
comes back the next time someone touches movement speed — and now it comes back as a red
run instead of another Discord message.

Two of the six items are still open, both waiting on rin. That is a correct end state.
The failure mode is not "some items are unresolved"; it is shipping a guess at the jump
feel and a guess at the boss difficulty and finding out in a week that both went the
wrong way.

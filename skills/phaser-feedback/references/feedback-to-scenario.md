# Feedback → Playtest Scenario

How to turn a sentence a player wrote into a scenario that fails for the reason they
described. Every scenario here runs against the harness in
`skills/phaser-playtest/scripts/playtest.mjs`; see
`skills/phaser-playtest/references/playtest-harness.md` for the full action reference.

Two bindings are available in every `expression` and every `eval` `code` block:

| Binding | What it is |
|---|---|
| `game` | The running `Phaser.Game` |
| `scene(key)` | `game.scene.getScene(key)` |

---

## The three questions

Before writing a line, answer these. They determine the entire shape of the scenario.

**1. What state was the player in?** → an `eval` step that establishes it directly.
Almost never "play the game from the start". If the report is about the boss, start
at the boss.

**2. What did they do?** → the input steps. Be literal. "I was holding right when I
jumped" is `hold: ['ArrowRight', 'Space']`, not two separate presses.

**3. What should have happened instead?** → the assertion. This is the part reporters
leave out, and the part you must pin down. "It should not do that" is not an assertion;
"the player should still be above y=500" is.

---

## Claim shapes

Feedback comes in a small number of shapes. Recognise the shape and the construct
follows.

### "It happens sometimes" — a frequency claim

Never assert this with one run. Reproduce with repetition:

```bash
node playtest.mjs --project . --scenario playtest/repro.mjs --repeat 10
```

Then read the verdict:

- `10/10 clean` — you have not reproduced it. Get more detail; do not start fixing.
- `INTERMITTENT — failed in 3/10` — real, and race- or RNG-shaped.
- `failed in all 10` — deterministic. Your repro is exact.

Add `--seed 42` to split RNG from timing. Consistent under a seed ⇒ an RNG path reaches
a state the code does not handle. Still intermittent under a seed ⇒ frame ordering, an
async load, or an event racing `update()`.

### "X gets stuck" — a claim about variance

A stuck object is one whose position stops changing. That is a statement about a value
over time, so sample it:

```javascript
{ name: 'enemy never wedges on the corner',
  action: 'sample',
  expression: `scene('GameScene').enemies[0].x`,
  duration: 5000,
  interval: 100,
  expect: { stat: 'range', atLeast: 64 } }
```

`range` is the right statistic: an enemy that patrols back to where it started has a
`delta` of zero but a healthy `range`. Asserting on `delta` would fail a working enemy.

### "It takes too long" / "it never finishes" — a timing claim

```javascript
{ name: 'boss dies within 8 seconds of sustained attack',
  action: 'waitFor',
  expression: `scene('GameScene').boss.hp <= 0`,
  timeout: 8000 }
```

`waitFor` reports the elapsed time on success, which is the number you need for the
tuning conversation that usually follows.

### "It happens for no reason" — an unexplained change

Sample the value while doing nothing, and assert it does not move:

```javascript
{ name: 'health does not drain when nothing is attacking',
  action: 'sample',
  expression: `scene('GameScene').player.hp`,
  duration: 5000,
  interval: 250,
  expect: { stat: 'delta', equals: 0 } }
```

### "It gets slower the longer I play" — an accumulation claim

Restart the thing they were doing many times, and watch the heap:

```javascript
export default [
  { action: 'repeat', times: 20, steps: [
      { action: 'eval', code: `scene('GameScene').scene.restart()` },
      { action: 'wait', ms: 400 },
  ] },
  { name: 'framerate survives twenty restarts', action: 'expect',
    expect: { expression: `game.loop.actualFps`, atLeast: 50 } },
];
```

```bash
node playtest.mjs --project . --scenario playtest/repro-leak.mjs --heap
```

Steady heap growth across restarts means objects or listeners are surviving the
restart. The usual culprits are `scene.events.on` without a matching `off`, timers
that outlive the scene, and DOM listeners added in `create()`.

### "It only happens on my phone" — a platform claim

```bash
node playtest.mjs --project . --scenario playtest/repro.mjs --device iphone
node playtest.mjs --project . --scenario playtest/repro.mjs --device android
```

Use `tap` rather than `click` in the scenario — touch and mouse are separate input
paths in Phaser, and a bug in one does not imply a bug in the other.

> `--device` emulates viewport, DPR, touch and user-agent. It is **not** Safari. It will
> not reproduce iOS-specific WebGL, audio-unlock or safe-area bugs. When the report is
> shaped like one of those, say so rather than declaring it not reproducible — see
> `skills/phaser-mobile/references/device-profiles.md`.

### "The controls fight me" — an input-combination claim

Diagonals, run+jump and strafe+fire are separate code paths from any single key:

```javascript
{ name: 'can jump while running right',
  action: 'hold',
  keys: ['ArrowRight', 'Space'],
  duration: 600,
  expect: { expression: `scene('GameScene').player.body.velocity.y`, below: 0 } }
```

### "It broke after the update" — a regression claim

Do not hunt the bug first. Write the scenario, then run it against the previous commit:

```bash
git stash && git checkout HEAD~1
node playtest.mjs --project . --scenario playtest/repro.mjs   # expect: passes
git checkout - && git stash pop
node playtest.mjs --project . --scenario playtest/repro.mjs   # expect: fails
```

A scenario that fails on both was never a regression, and the report's framing was
wrong. A scenario that passes on both has not reproduced the bug. Either way you have
learned something before spending time in the debugger.

### "The screen went black" / "nothing loaded"

No scenario needed — the harness's default checks cover this. Run it plainly and read
`all assets load` first: an asset the dev server answered with `200 text/html` is the
single most common cause, and it looks like a successful request in every browser
devtools panel.

```bash
node playtest.mjs --project . --mode build
```

Use `--mode build` for anything a player saw, since players are on the built bundle.
Base-path errors and dropped dynamic imports only exist there.

---

## Establishing state with `eval`

Most reports describe a state deep in the game. Playing to it is slow and flaky; set it
directly.

```javascript
{ action: 'eval', code: `
    const s = scene('GameScene');
    s.player.hp = 1;
    s.player.gold = 0;
    s.inventory.clear();
    s.spawnBoss();
` }
```

This depends on the game exposing enough surface to be driven. If a scene keeps
everything in closures, nothing here is reachable. See
`skills/phaser-playtest/references/instrumenting-games.md` — the fix is small and it is
the difference between a testable game and one you can only test by hand.

To skip to a level, use `scene` rather than replicating the route to it:

```javascript
{ action: 'scene', key: 'GameScene', data: { level: 5, checkpoint: 'boss' }, settle: 800 }
```

---

## Writing assertions that do not lie

**Use `within` for anything positional.** Float coordinates do not land on round
numbers, so `equals` on a position is a guaranteed false failure:

```javascript
expect: { expression: `scene('GameScene').player.x`, within: { of: 400, tolerance: 8 } }
```

**Assert the consequence, not the mechanism.** `player.body.blocked.down === true` says
the player landed. `player.body.touching.down === true` might be a different frame.
Assert the thing the player experienced.

**One claim per assertion.** A step that checks three things tells you only that one of
them broke, which is the least useful information the run could have given you.

**Assert the negative too.** "The player lands on the platform" is incomplete without
"and is not below it" — a player who tunnelled through has also stopped falling, at the
bottom of the level.

---

## Naming and keeping scenarios

```
playtest/
  repro-fall-through-platform.mjs     one report, one file
  repro-shop-empty-inventory.mjs
  smoke-main-flow.mjs                 the always-run happy path
```

Name the file after the **player's complaint**, not the diagnosis. The diagnosis changes
as you learn more; the complaint is what you promised to fix, and in six months it is
the name that tells you what the file is for.

Commit them. A repro scenario is a regression test that was written from something a
real person actually did, which is more than most test suites can claim.

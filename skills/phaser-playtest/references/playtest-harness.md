# playtest.mjs — Full Reference

Headless runtime verification for Phaser 4 games. Located at
`skills/phaser-playtest/scripts/playtest.mjs`.

---

## Requirements

```bash
npm install -D playwright
npx playwright install chromium
```

The harness resolves Playwright from the **project** first, then from its own
location, so a globally installed `playwright` also works. It accepts
`playwright`, `@playwright/test`, or `playwright-core`.

---

## Invocation

```bash
node playtest.mjs [options]
```

| Option | Default | Description |
|---|---|---|
| `--project DIR` | `cwd` | Project root. Must contain `package.json` unless `--url` is given. |
| `--url URL` | — | Test an already-running server. Skips server management entirely. |
| `--mode dev\|build` | `dev` | `dev` runs `npm run dev`. `build` runs `npm run build` then `npm run preview`. |
| `--scenario FILE` | — | `.mjs` module default-exporting a step array. |
| `--out DIR` | `<project>/.playtest` | Artifact directory for screenshots and `report.json`. |
| `--settle MS` | `3000` | Delay after load before probing. Raise for long preloads. |
| `--timeout MS` | `90000` | Server startup timeout. |
| `--viewport WxH` | `1280x720` | Viewport size. |
| `--device NAME` | — | `iphone` (390×844 @3x) or `android` (412×915 @2.6x). Sets touch + UA. Overrides `--viewport`. |
| `--fail-on-warn` | off | Warnings count as failures. |
| `--json` | off | Suppress human output; print the JSON report to stdout. |
| `--headed` | off | Show the browser window. |
| `--repeat N` | `1` | Run the scenario N times from a fresh page load and report the flake rate. Requires `--scenario`. |
| `--seed N` | — | Seed `Math.random` so a run is reproducible. |
| `--heap` | off | Measure JS heap growth across the session. |
| `--video` | off | Record video of the session into `<out>/video/`. |
| `--trace` | off | Write a Playwright trace to `<out>/trace.zip`. |
| `--slowmo MS` | `0` | Pause between actions — pair with `--headed` to watch a repro. |
| `--browser PATH` | — | Use a specific Chromium binary. Also read from `PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH`. |

### Exit codes

| Code | Meaning |
|---|---|
| `0` | All checks passed (warnings allowed unless `--fail-on-warn`) |
| `1` | One or more checks failed |
| `2` | Harness error — server never started, Playwright missing, bad scenario file |

Exit `2` is **not** a game failure. Fix the harness invocation before reading results.

---

## Modes

**`--mode dev`** — fast, and `import.meta.env.DEV` is true, so test hooks and the
`__PHASER_GAME__` global are present. Use for state assertions and scenarios.

**`--mode build`** — runs the real production pipeline. Catches what dev mode cannot:

- wrong `base` in `vite.config.ts` (assets 404 on itch.io / GitHub Pages)
- assets referenced from `src/` that were never copied to `dist/`
- minification breaking code that relies on function or class `.name`
- tree-shaking dropping a scene that is only referenced dynamically

Run `--mode build` before every deploy. Dev-only globals are absent by design, so
deep state checks downgrade to a warning.

---

## Checks

| Check | Status on failure | Meaning |
|---|---|---|
| `page loads` | fail | Document did not return 2xx |
| `production build` | (build mode) | `npm run build` exit code |
| `canvas created` | fail | No sized `<canvas>` within 15s — Phaser never booted |
| `Phaser game instance found` | warn | Not on `window`; deep checks skipped |
| `game booted` | fail | `game.isBooted === false` |
| `active scenes` | fail | No scene running |
| `scenes render content` | warn | A running scene has an empty display list |
| `frame rate` | fail <30 / warn <50 | 5th-percentile FPS over ~90 sampled frames |
| `canvas renders content` | fail | Blank or near-blank pixels |
| `no uncaught exceptions` | fail | `pageerror` fired |
| `no console errors` | fail | `console.error` called |
| `all assets load` | fail | Failed request, 4xx/5xx, or asset served as `text/html` |
| `console warnings` | warn | Non-error console output |

### Blank-canvas detection

The canvas is screenshotted, decoded back inside the page, downsampled to 320×180,
and quantised to 4 bits per channel. Two numbers are derived:

- **uniqueColors** — distinct quantised colours
- **coverage** — fraction of pixels that are *not* the single most common colour

Blank is `uniqueColors <= 2 || coverage < 0.005`. A solid background plus a small
sprite still passes; a background alone does not.

Note that a scene rendering only its background colour is *by this measure* blank —
which is the intended behaviour, because that is exactly what a failed `create()`
looks like.

### The `text/html` asset check

Vite and most SPA dev servers answer a missing `assets/player.png` with `200` and the
contents of `index.html` rather than a 404. The request looks successful; Phaser then
fails with an opaque `Failed to process file`. The harness flags any URL with an asset
extension whose `content-type` is `text/html`. This is the single highest-value check
for "my sprite doesn't show up".

---

## Scenario Format

A scenario is an `.mjs` module whose default export is an array of steps, executed in
order.

```javascript
export default [
  { name: 'human-readable label', action: 'key', key: 'ArrowRight', duration: 600 },
];
```

### Actions

| Action | Fields | Behaviour |
|---|---|---|
| `wait` | `ms` (default 500) | Pause |
| `key` | `key`, `duration` (default 200) | Hold one key down, wait, release. Movement. |
| `press` | `key` | Single keydown+keyup. Jump, fire, confirm. |
| `hold` | `keys[]`, `duration` (default 300) | Hold **several** keys at once. Diagonals, run+jump, strafe+fire. |
| `click` | `x`, `y`, `button`, `count` | Mouse click at canvas-relative pixels (defaults to centre) |
| `move` | `x`, `y`, `steps` | Pointer move without clicking. Hover states, aiming. |
| `drag` | `from{x,y}`, `to{x,y}`, `steps`, `hold` | Press, glide, release. Drag-drop, swipes, virtual joysticks. |
| `tap` | `x`, `y` | Touch tap. Needs `--device iphone`/`--device android`. |
| `wheel` | `dx`, `dy` | Scroll. Zoom controls. |
| `eval` | `code` | Run arbitrary setup code in the page. Put the game into the reported state directly. |
| `scene` | `key`, `data`, `settle` | `scene.start(key, data)` — jump straight to a level instead of playing to it. |
| `waitFor` | `expression`, `timeout` (5000), `poll` (100) | Poll until truthy. Asserts a **timing** claim. |
| `sample` | `expression`, `duration`, `interval`, `series` | Record a value over time; assert on its statistics. |
| `repeat` | `times`, `steps[]` | Run a block N times. Button mashing, repeated waves. |
| `screenshot` | `name` | PNG into the artifact directory |
| `expect` | — | Assertion only, no interaction |

`key` values are [Playwright key names](https://playwright.dev/docs/api/class-keyboard):
`ArrowLeft`, `Space`, `KeyW`, `Enter`, `Escape`, `Digit1`.

Before the scenario runs, the harness clicks the canvas corner — this focuses it for
keyboard delivery and satisfies the browser's audio-unlock gesture requirement.

### Reaching the game

Every `expression` and every `eval` `code` block runs in page context with two bindings:

| Binding | What it is |
|---|---|
| `game` | The located `Phaser.Game` instance |
| `scene(key)` | Shorthand for `game.scene.getScene(key)` |

Page globals (`window.__TEST__`, `document`) are reachable too.

### `eval` — start from the reported state

Most bug reports describe a *state*, not a route to it: "the boss softlocks if you kill
it mid-dash", "the shop breaks when you can't afford anything". Playing up to that state
is slow and flaky. Set it directly:

```javascript
{ action: 'eval', code: `
  const s = scene('GameScene');
  s.player.hp = 1;
  s.player.gold = 0;
  s.spawnBoss();
` }
```

### `waitFor` — assert a timing claim

"The enemy should die within about three seconds" is a claim about time. A fixed `wait`
either flakes or wastes seconds; `waitFor` reports how long it actually took.

```javascript
{ name: 'boss dies within 8s of the combo',
  action: 'waitFor',
  expression: `scene('GameScene').boss.hp <= 0`,
  timeout: 8000 }
```

### `sample` — assert on behaviour over time

"Enemies sometimes get stuck on corners" is a claim about *variance*, and a single
reading cannot confirm or deny it. `sample` watches a value and computes statistics:

```javascript
{ name: 'enemy keeps moving, never wedges',
  action: 'sample',
  expression: `scene('GameScene').enemies[0].x`,
  duration: 5000,
  interval: 100,
  expect: { stat: 'range', atLeast: 32 } }
```

Available statistics: `min`, `max`, `range`, `mean`, `stddev`, `first`, `last`, `delta`,
`samples`, `numeric`. `stat` defaults to `last`. Add `series: true` to keep every raw
reading in `report.json`.

Which statistic answers which complaint:

| Report | Statistic |
|---|---|
| "enemies get stuck" | `range` — `atLeast` the distance it should have covered |
| "the camera jitters" | `stddev` — `atMost` a small number |
| "my health drains when nothing is hitting me" | `delta` — `equals: 0` |
| "the framerate tanks in the arena" | `min` — `atLeast: 30` |
| "the score keeps climbing after I die" | `delta` — `equals: 0` |

### Assertions

Any step may carry an `expect`. It runs **after** the step's action, so you can act
and assert in one entry.

```javascript
{ action: 'press', key: 'Space',
  expect: { expression: `game.registry.get('jumps')`, atLeast: 1 } }
```

The `expression` is evaluated in page context with `game` bound to the located
`Phaser.Game`. Any page global (`window.__TEST__`, `document`) is also reachable.

| Form | Comparison |
|---|---|
| `{ expression, equals: v }` | Deep equality via `JSON.stringify` |
| `{ expression, notEquals: v }` | Deep inequality |
| `{ expression, atLeast: n }` | `>= n` |
| `{ expression, atMost: n }` | `<= n` |
| `{ expression, above: n }` | `> n` (strict) |
| `{ expression, below: n }` | `< n` (strict) |
| `{ expression, within: { of: n, tolerance: t } }` | `abs(value - n) <= t` — for float positions |
| `{ expression, oneOf: [a, b] }` | Matches any listed value — for legitimately variable state |
| `{ expression, contains: v }` | Substring, or array membership |
| `{ expression }` | Truthy |

Prefer `within` over `equals` for anything positional. Float coordinates rarely land on
a round number, and an `equals` assertion on one is a guaranteed false failure.

When an assertion fails, the harness screenshots the canvas at that moment into the
artifact directory as `NN-FAIL-<step name>.png`. That image is usually the fastest route
to understanding what the game actually did.

Multi-statement expressions work via the comma operator or an IIFE:

```javascript
expect: { expression: `(() => { const s = game.scene.getScene('GameScene'); return s.enemies.countActive(true); })()`, equals: 0 }
```

---

## Hunting intermittent bugs: `--repeat`

The hardest reports to act on are the ones that say *sometimes*. One green run proves
nothing about a bug that fires one time in four.

```bash
node playtest.mjs --project . --scenario repro.mjs --repeat 10
```

Each run starts from a fresh page load. The harness then reports one of three verdicts:

| Verdict | Meaning | What to do |
|---|---|---|
| `scenario stability — 10/10 runs clean` | Not reproduced | Your repro does not capture what the player did. Get more detail before changing code. |
| `INTERMITTENT — failed in 4/10 runs` | Reproduced, race-shaped | A race, an RNG path, or frame-timing. Add `--seed` to pin the RNG and see whether it becomes consistent. |
| `failed in all 10 runs — consistent` | Reproduced, deterministic | Not a flake at all. Fix it directly. |

The verdict names which assertions failed and how often, so a repro that asserts several
things at once still tells you which one is unstable.

**Distinguishing an RNG bug from a timing bug** is the useful next step:

```bash
node playtest.mjs --project . --scenario repro.mjs --repeat 10 --seed 42
```

`--seed` replaces `Math.random` with a seeded generator before any page script runs. If
the failure becomes consistent under a seed, it is RNG-dependent — some spawn roll or
loot roll reaches a state the code does not handle. If it stays intermittent, the cause
is timing: frame ordering, an async load, or an event that races `update()`.

> Seeding `Math.random` does not seed Phaser's own RNG if the game passes an explicit
> `seed` in its game config — Phaser's `Math.RandomDataGenerator` is separate. For a
> fully deterministic game, seed Phaser too and expose the seed so a repro can set it.

## Leak hunting: `--heap`

"The game gets slower the longer I play" is a memory complaint. `--heap` samples the JS
heap after boot and again after the scenario:

```bash
node playtest.mjs --project . --scenario long-session.mjs --heap
```

Pair it with a `repeat` block that restarts a scene many times — objects and listeners
that survive a scene restart are the usual culprit, and they show up as steady growth
rather than a spike.

---

## report.json

```jsonc
{
  "url": "http://localhost:5173",
  "mode": "dev",
  "canvasSize": { "w": 800, "h": 600 },
  "state": {
    "phaserVersion": "4.2.1",
    "renderType": "WEBGL",
    "isBooted": true,
    "activeScenes": [{ "key": "GameScene", "displayList": 43, "bodies": 1, "tweens": 0 }],
    "totalScenes": 2,
    "textureKeys": 3,
    "soundsPlaying": 0
  },
  "fps": { "samples": 91, "min": 58, "p5": 59, "median": 60 },
  "pixels": { "width": 800, "height": 600, "uniqueColors": 333, "coverage": 0.056 },
  "pageErrors": [],
  "consoleErrors": [],
  "failedRequests": [],
  "checks": [{ "name": "canvas renders content", "status": "pass", "detail": "..." }],
  "summary": { "passed": 16, "failed": 0, "warnings": 0 }
}
```

Parse `summary.failed` in CI; read `checks` for detail; read `failedRequests` first
when sprites are missing.

---

## Recipes

**After writing a feature**
```bash
npx tsc --noEmit && node playtest.mjs --project .
```

**Reproduce a reported black screen**
```bash
node playtest.mjs --project . --settle 6000 --headed
```

**Pre-deploy gate**
```bash
node playtest.mjs --project . --mode build --fail-on-warn
```

**Mobile check**
```bash
node playtest.mjs --project . --device iphone --scenario playtest/touch.mjs
```

**Against a server you already have running**
```bash
node playtest.mjs --url http://localhost:5173 --scenario playtest/combat.mjs
```

**Machine-readable, for another tool to consume**
```bash
node playtest.mjs --project . --json > result.json
```

**Reproduce a player's "it happens sometimes" report**
```bash
node playtest.mjs --project . --scenario repro.mjs --repeat 10
```

**Decide whether that flake is RNG or timing**
```bash
node playtest.mjs --project . --scenario repro.mjs --repeat 10 --seed 42
```

**Watch a repro happen, slowly, with your own eyes**
```bash
node playtest.mjs --project . --scenario repro.mjs --headed --slowmo 400
```

**Capture evidence to attach to a bug report**
```bash
node playtest.mjs --project . --scenario repro.mjs --video --trace
```

**Chase a "the game slows down over time" report**
```bash
node playtest.mjs --project . --scenario long-session.mjs --heap
```

**On a CI image that already ships Chromium**
```bash
node playtest.mjs --project . --browser /usr/bin/chromium
```

---

## Limitations

- **WebGL is software-rendered** in headless Chromium (SwiftShader). FPS numbers are
  therefore a *regression signal*, not a measurement of real device performance. A
  drop from 60 → 20 between runs is meaningful; the absolute number is not. Profile
  real hardware for actual performance work — see `/phaser-analyze`.
- **Audio does not truly play.** `soundsPlaying` confirms Phaser *believes* it is
  playing; it does not verify audible output.
- **No visual regression diffing.** Screenshots are captured for human review. For
  pixel-diffing baselines, use Playwright's own `toHaveScreenshot` — see
  `phaser-build/references/testing-patterns.md`.
- **`--device` emulates viewport, DPR, touch, and UA only.** It is not Safari, and it
  will not reproduce iOS-specific WebGL or audio bugs. Use real devices for those; see
  `phaser-mobile/references/device-profiles.md`.
- **Scenarios drive input, not intent.** They cannot judge whether the game is *fun*,
  whether difficulty curves work, or whether art reads clearly. Those still need a
  human.

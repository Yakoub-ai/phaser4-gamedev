# Instrumenting a Phaser 4 Game for Automated Testing

A game that cannot be inspected from outside can only be tested by a human looking at
it. These are the hooks that make a Phaser 4 game observable and deterministic, in
increasing order of investment. All of them are dev-only — none ship to production.

---

## 1. Expose the Game Instance (required)

Bundlers keep `game` in module scope, so nothing outside can reach it.

```typescript
// src/main.ts
const game = new Phaser.Game(config);

if (import.meta.env.DEV) {
  (window as any).__PHASER_GAME__ = game;
}

export default game;
```

`import.meta.env.DEV` is `false` in `npm run build`, so the global is stripped from
production bundles by dead-code elimination.

This single line unlocks scene inspection, FPS sampling, state assertions, and every
`expect` expression in a scenario.

> **Testing the production build:** `--mode build` intentionally has no global. That
> is correct — it verifies what ships. Use `--mode build` for boot/asset/render checks
> and `--mode dev` for state assertions.

---

## 2. A Typed Test Surface

Rather than reaching into scene internals from scenarios (brittle — renames break
tests), publish a small, deliberate API. Scenarios then assert against a contract you
control.

```typescript
// src/debug/test-hooks.ts
import type { Game } from 'phaser';

export interface TestHooks {
  activeScene(): string | undefined;
  playerPos(): { x: number; y: number } | null;
  score(): number;
  enemyCount(): number;
  setState(patch: Record<string, unknown>): void;
}

export function installTestHooks(game: Game): void {
  if (!import.meta.env.DEV) return;

  const scene = () => game.scene.getScenes(true)[0];

  const hooks: TestHooks = {
    activeScene: () => scene()?.scene.key,
    playerPos: () => {
      const p = (scene() as any)?.player;
      return p ? { x: Math.round(p.x), y: Math.round(p.y) } : null;
    },
    score: () => game.registry.get('score') ?? 0,
    enemyCount: () => (scene() as any)?.enemies?.countActive(true) ?? 0,
    setState: (patch) => {
      for (const [k, v] of Object.entries(patch)) game.registry.set(k, v);
    },
  };

  (window as any).__TEST__ = hooks;
}
```

Scenario assertions become stable and readable:

```javascript
{ expect: { expression: `window.__TEST__.activeScene()`, equals: 'GameScene' } }
{ expect: { expression: `window.__TEST__.enemyCount()`, equals: 0 } }
```

---

## 3. Determinism

A test that passes 70% of the time is worse than no test. Three sources of
nondeterminism dominate Phaser games.

### Seeded RNG

Phaser ships a seedable RNG — use it instead of `Math.random()` everywhere.

```typescript
const config: Phaser.Types.Core.GameConfig = {
  seed: [import.meta.env.DEV ? 'playtest-seed' : String(Date.now())],
  // ...
};

// In game code — never Math.random()
const roll = Phaser.Math.RND.between(1, 6);
const pick = Phaser.Math.RND.pick(lootTable);
```

With a fixed seed, enemy spawns, loot rolls, and level generation repeat exactly, so
an assertion on "3 enemies spawn in wave 1" is meaningful.

### Skip Intros and Timers

Long splash sequences make every scenario slow and flaky.

```typescript
// src/scenes/BootScene.ts
const params = new URLSearchParams(location.search);
const skipIntro = import.meta.env.DEV && params.has('skipIntro');

this.scene.start(skipIntro ? 'GameScene' : 'SplashScene');
```

Then target it directly:

```bash
node playtest.mjs --url http://localhost:5173/?skipIntro&scene=GameScene
```

### Jump Straight to State

Reaching level 7 by playing takes minutes and fails for unrelated reasons. Inject
instead:

```typescript
if (import.meta.env.DEV) {
  const p = new URLSearchParams(location.search);
  if (p.has('level')) this.registry.set('level', Number(p.get('level')));
  if (p.has('hp')) this.registry.set('hp', Number(p.get('hp')));
}
```

```bash
node playtest.mjs --url "http://localhost:5173/?level=7&hp=1" --scenario playtest/death.mjs
```

---

## 4. Fixing the Timestep

Real-time waits (`{ action: 'wait', ms: 500 }`) couple assertions to machine speed. For
physics-sensitive tests, drive the loop in fixed steps instead.

```typescript
// src/debug/test-hooks.ts (add to installTestHooks)
(window as any).__TEST__.step = (frames: number, delta = 16.666) => {
  game.loop.sleep();                    // stop rAF driving the loop
  for (let i = 0; i < frames; i++) game.loop.step(performance.now() + i * delta);
};
```

```javascript
{ name: 'fall 30 frames', action: 'expect',
  expect: { expression: `(window.__TEST__.step(30), game.scene.getScene('GameScene').player.body.blocked.down)`, equals: true } }
```

Use this only where timing is the thing under test — for most scenarios, real-time
input with a generous `duration` is simpler and closer to real play.

---

## 5. An Error Beacon

Some failures are swallowed by `try/catch` in game code and never reach `pageerror`.
Surface them explicitly.

```typescript
if (import.meta.env.DEV) {
  (window as any).__ERRORS__ = [] as string[];
  const push = (m: string) => (window as any).__ERRORS__.push(m);

  window.addEventListener('error', (e) => push(e.message));
  window.addEventListener('unhandledrejection', (e) => push(String(e.reason)));

  // Phaser's loader fails quietly for missing files — this is the loudest signal
  // you will get for a bad asset path.
  game.events.on('ready', () => {
    game.scene.scenes.forEach((s) => {
      s.load.on('loaderror', (file: Phaser.Loader.File) =>
        push(`ASSET FAILED: ${file.key} → ${file.url}`));
    });
  });
}
```

Then assert on it in every scenario:

```javascript
{ name: 'no swallowed errors', action: 'expect',
  expect: { expression: `window.__ERRORS__.length`, equals: 0 } }
```

---

## 6. What Not to Instrument

- **Do not** add test hooks to production builds. Gate everything on `import.meta.env.DEV`.
- **Do not** reshape game architecture purely for testability. Extracting pure logic
  into testable modules (see `phaser-build/references/testing-patterns.md`) is good
  design anyway; adding indirection layers that exist only for tests is not.
- **Do not** assert on pixel positions of decorative elements. Assert on state the
  design document actually specifies — HP, score, scene key, entity counts.
- **Do not** let scenarios depend on wall-clock timing beyond a generous margin.

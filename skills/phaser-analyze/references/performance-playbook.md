# Phaser 4 Performance Playbook

A nine-phase playbook for taking a Phaser 4 game from sluggish to smooth on mid-range mobile (roughly Snapdragon 600-series Android, iPhone 11-class iOS). Use this when a game is already slow — NOT as a premature-optimization checklist. Apply phases in order of measured impact, not in sequence.

## Step 1 — Measure, don't guess

Generic "my game is slow" prompts produce generic advice. Measurement-first prompts that list specific bottlenecks produce targeted fixes. Before asking for help (or before touching any code), collect these numbers:

| Metric | How to measure | Useful threshold |
|---|---|---|
| Actual FPS | `game.loop.actualFps` logged every second | <55 on target hardware is worth fixing |
| Heap size | Chrome DevTools → Performance → Memory | Growth per 10s of gameplay indicates a leak |
| Audio boot budget | `Network` tab total MB loaded before first frame | Budget 5 MB for mobile web; 15 MB for PWA |
| Physics checks/frame | Count live bodies: `this.physics.world.bodies.entries.length` | >200 on mobile is a red flag |
| HTTP request count | `Network` tab, "Img" filter | >30 individual images → atlas |
| Draw calls/frame | Phaser Beam stats (dev build) or WebGL inspector | >80 in a 2D game is high |

A prompt that reads like a profiling report (with these numbers filled in) produces one-shot fixes. A prompt that reads like a complaint ("frame rate is bad") produces generic advice that may not address the actual culprit.

## Step 2 — The nine-phase playbook

Apply in order. Each phase stops when its metric is acceptable. Don't do all nine for a game that only needs three.

### Phase 1: Per-frame allocations → zero

Every `const arr = []` and `const v = new Phaser.Math.Vector2()` inside `update()` creates GC pressure. GC spikes are the #1 cause of micro-stutters at 30+ entities.

```typescript
// BAD — new array every frame:
update(): void {
  const nearby = this.enemies.filter(e => Math.abs(e.x - this.x) < 200);
  // ...
}

// GOOD — scratch buffer reused:
private scratchNearby: Enemy[] = [];
update(): void {
  this.scratchNearby.length = 0;
  for (const e of this.enemies) {
    if (Math.abs(e.x - this.x) < 200) this.scratchNearby.push(e);
  }
  // ... use this.scratchNearby ...
}
```

Apply to: collision scratch buffers, particle parameter objects, Vector2 math temporaries.

### Phase 2: Registry updates tier-throttled

If 50 entities each write `this.registry.set('entityCount', n)` every frame, the Registry fires 50 `changedata` events per frame to every listener.

Tier by read frequency:
- **HUD numbers read every frame (score, HP):** throttle writes to 60 ms (16 FPS for the Registry, not for the game).
- **Bestiary / codex data read on pause-screen only:** throttle writes to 500 ms or only write on meaningful change.
- **Save-critical data (high score, unlocks):** write immediately; these fire once per event, not every frame.

### Phase 3: Audio boot budget reduction via lazy-load

Don't preload every track in BootScene. Load only the menu music + UI SFX; lazy-load biome / boss / dungeon tracks on demand.

```typescript
// In GameScene, on biome entry:
if (!this.cache.audio.exists(`bgm-${biomeKey}`)) {
  this.load.audio(`bgm-${biomeKey}`, [`assets/audio/${biomeKey}.mp3`, `assets/audio/${biomeKey}.ogg`]);
  this.load.once('complete', () => this.playBgm(biomeKey));
  this.load.start();
}
```

Compression pass: a 2D action game with ~40 music tracks typically compresses from ~80 MB raw to ~25-30 MB combined at 96 kbps mono mp3 for music, 64 kbps for SFX. Budget before compression, not after — always check the compressed size.

### Phase 4: VFX Graphics pooled

Creating and destroying `Phaser.GameObjects.Graphics` per hit is expensive: each creation allocates WebGL buffers. Pool instead.

```typescript
class VfxPool {
  private pool: Phaser.GameObjects.Graphics[] = [];
  spawn(x: number, y: number): Phaser.GameObjects.Graphics {
    const gfx = this.pool.pop() ?? this.scene.add.graphics();
    gfx.setPosition(x, y).setActive(true).setVisible(true);
    // ... draw effect ...
    this.scene.time.delayedCall(200, () => this.recycle(gfx));
    return gfx;
  }
  recycle(gfx: Phaser.GameObjects.Graphics): void {
    gfx.clear().setActive(false).setVisible(false);
    this.pool.push(gfx);
  }
}
```

### Phase 5: Spatial grid replaces brute-force proximity

Brute-force O(n²) proximity: 400 entities → 160 000 checks/frame. Spatial grid: 400 entities × 9 cells (3×3 neighborhood) → ~3 600 checks/frame (~96% fewer). Typical result when this phase is applied to a game of similar scope.

```typescript
class SpatialGrid {
  private readonly cellSize: number;
  private cells = new Map<string, Set<Entity>>();
  constructor(cellSize: number) { this.cellSize = cellSize; }
  key(x: number, y: number): string {
    return `${Math.floor(x / this.cellSize)},${Math.floor(y / this.cellSize)}`;
  }
  insert(e: Entity): void {
    const k = this.key(e.x, e.y);
    if (!this.cells.has(k)) this.cells.set(k, new Set());
    this.cells.get(k)!.add(e);
  }
  neighbors(x: number, y: number): Entity[] {
    const cx = Math.floor(x / this.cellSize);
    const cy = Math.floor(y / this.cellSize);
    const out: Entity[] = [];
    for (let dx = -1; dx <= 1; dx++) for (let dy = -1; dy <= 1; dy++) {
      const k = `${cx + dx},${cy + dy}`;
      const cell = this.cells.get(k);
      if (cell) cell.forEach((e) => out.push(e));
    }
    return out;
  }
  clear(): void { this.cells.clear(); }
}
```

Rebuild the grid each frame in `update()` (cheap — one insert per entity) before running proximity logic.

### Phase 6: Atlas pack to reduce HTTP requests

Bundle sprites into texture atlases at build time. Individual PNG requests are individual HTTP round-trips; a mid-size 2D action game with unatlased sprites can easily generate 150–200 requests on first load — atlased, the same assets typically collapse to fewer than 10. On a cold mobile connection, this alone can cut load time by 20+ seconds.

Tools:
- `texturepacker` — gold standard; outputs Phaser-compatible JSON.
- `free-tex-packer-cli` — free alternative.
- Vite plugin: `vite-plugin-texture-atlas` can pack on build.

One atlas per category: `hud.atlas.png/json`, `enemies.atlas.png/json`, `tiles.atlas.png/json`. Keep each atlas ≤2048×2048 for mobile GPU compatibility.

### Phase 7: Stat-change events throttled 60 ms

If `player.health` changes every frame during a DoT tick, and 10 listeners (HUD text, healthbar, damage indicator, etc.) react to every change, that's 10 handlers × 60 FPS = 600 callbacks/second.

Throttle at the source:

```typescript
class ThrottledEvent {
  private lastFire = 0;
  fire(): void {
    const now = performance.now();
    if (now - this.lastFire < 60) return;
    this.lastFire = now;
    this.emitter.emit(this.eventName, this.value);
  }
}
```

### Phase 8: Off-screen AI tick-skip (with real delta)

Entities that are offscreen can tick at reduced frequency (every 4th frame). CRITICAL: when tick-skipping, pass REAL wall-clock delta to the entity's update, not Phaser's per-frame delta. Otherwise timers run in slow-motion and stuck-detection watchdogs never fire.

```typescript
// BAD — tick-skip with Phaser delta: timers run at 1/4 speed:
update(time: number, delta: number): void {
  if (this.frame % 4 !== 0) return;
  this.aiUpdate(time, delta);  // delta is 16 ms even though 64 ms passed
}

// GOOD — pass real wall-clock delta:
private lastAiTime = 0;
update(time: number): void {
  if (this.frame % 4 !== 0) return;
  const realDelta = time - this.lastAiTime;
  this.lastAiTime = time;
  this.aiUpdate(time, realDelta);
}
```

### Phase 9: Kill tweens on destroy

`this.tweens.add({ targets: sprite, ... })` holds a reference to `sprite` until the tween completes. If you destroy the sprite mid-tween, the tween keeps running and holding memory, and may throw when it tries to set a property on a destroyed object.

```typescript
// In shutdown() or sprite.destroy() handler:
this.scene.tweens.killTweensOf(sprite);
sprite.destroy();
```

Apply to: floating damage numbers, XP orbs, projectiles, any pooled entity with tween-driven animation.

## Decision tree: which phase applies?

```
Is actual FPS below 55 on target?
├── No  → stop, you're done.
└── Yes → which metric is worst?
    ├── Heap growing during gameplay         → Phase 9 (tweens) + Phase 1 (allocations)
    ├── GC spikes every few seconds          → Phase 1 (allocations) + Phase 4 (VFX pool)
    ├── CPU pegged in Chrome profiler        → Phase 5 (spatial grid) if >100 entities, else Phase 8 (AI tick-skip)
    ├── First-load takes >10 s on mobile     → Phase 3 (audio lazy) + Phase 6 (atlas pack)
    ├── HUD stutters under damage-over-time  → Phase 2 + Phase 7 (event throttle)
    └── Only low-end Android is slow         → apply ALL phases, plus lower texture resolution.
```

## Prompting template for performance work

A well-formed performance-help prompt looks like this:

> The game is running at 34 FPS on a Pixel 6a during combat with ~180 enemies alive. Chrome DevTools shows 92% CPU in the main thread, heap growing +2 MB per 10 seconds of gameplay, and `this.physics.world.bodies.entries.length` reports 312. Audio boot loads 47 MB before first frame. My tween count (`this.tweens.getTweens().length`) is 240 during combat.

Then ask: "Which playbook phases apply?"

Compare to the generic ask:

> The game is slow. Can you help?

The first prompt produces Phase 5 (spatial grid) + Phase 3 (audio lazy) + Phase 9 (tween leaks) + Phase 1 (allocations from 240 tween recreations). The second produces "use object pooling and texture atlases" which may or may not address the actual culprit.

## Cross-references

- `skills/phaser-analyze/scripts/analyze-project.sh` — automated baseline metrics and flag detection.
- `skills/phaser-analyze/references/analysis-checklist.md` — full 5-phase audit checklist.
- `agents/phaser-debugger.md` → "Performance Problems" diagnostic category.
- `skills/phaser-build/SKILL.md` → production build optimization.

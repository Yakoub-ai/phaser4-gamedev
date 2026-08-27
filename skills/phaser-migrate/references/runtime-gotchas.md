# Phaser 4 Runtime Gotchas

Behaviour that compiles cleanly and still surprises you at runtime. These are empirical
findings from shipping Phaser 4 games — masks, animation state switches, camera follow,
tilemap collision, physics landing detection, cross-scene wiring, and viewport sizing.

Each entry gives the **defensive pattern**: the call shape that behaves correctly across
Phaser 4 releases, so you are not depending on which point release a user installed.
Read this when something works in one build and not another, or when the compiler is
happy but the game is not.

For what changed *between releases*, see `v4-release-notes.md`.
For v3 → v4 API replacements, see `v3-to-v4-changes.md`.

---

## 1. Masking: `createGeometryMask()` and `BitmapMask` Are Gone

Phaser 4 removed the v3 masking classes outright. `BitmapMask` does not exist in the
type definitions at all, and neither `createGeometryMask()` nor `createBitmapMask()` is a
method on Game Objects any more. `GeometryMask` survives as a class, but only the Canvas
renderer consumes it — under Beam (WebGL) it does nothing.

WebGL masking now runs through the **Filters** system.

| What you want | Phaser 4 approach |
|---|---|
| Rectangular clip region (scroll panel, minimap) | `camera.setViewport(x, y, w, h)` on a dedicated camera |
| Arbitrary shape / texture mask | `obj.enableFilters(); obj.filters.internal.addMask(source)` |
| Inverted mask ("show everything except") | `addMask(source, true)` |
| Soft / gradient mask | `addMask()` with a texture that has an alpha ramp |

**BEFORE (Phaser 3)** — geometry mask for a scrollable settings panel:
```typescript
const maskShape = this.add.graphics();
maskShape.fillStyle(0xffffff);
maskShape.fillRect(x, y, w, h);
const mask = maskShape.createGeometryMask();  // removed in v4
panelContent.setMask(mask);
```

**AFTER (Phaser 4)** — a dedicated camera whose viewport *is* the clip rect:
```typescript
const panelCam = this.cameras.add(x, y, w, h);
panelCam.setScroll(scrollX, scrollY);

// Show only the panel content in this camera, and hide it from the main camera.
panelCam.ignore(this.children.list.filter(c => c !== panelContent));
this.cameras.main.ignore(panelContent);
```

**AFTER (Phaser 4)** — non-rectangular mask via the Filters system:
```typescript
const maskShape = this.add.graphics();
maskShape.fillStyle(0xffffff).fillCircle(64, 64, 64);

panelContent.enableFilters();                       // required before touching .filters
panelContent.filters!.internal.addMask(maskShape);  // GameObject or texture key
```

> **There is no `camera.setScissor()` in Phaser 4.** If you find that call in a guide or in
> older code, it does not exist on `Phaser.Cameras.Scene2D.Camera` — use `setViewport()`.

**`enableFilters()` is not optional.** `filters` is `null` until you call it, so
`obj.filters.internal.addBlur()` on a fresh object throws. The pattern is always:

```typescript
obj.enableFilters();
obj.filters!.internal.addBlur(0, 2, 2, 1);   // internal = object-local space
obj.filters!.external.addGlow(0xff00ff, 4);  // external = screen space, after camera transform
```

---

## 2. Animation `stop()` Required Before `play()` on State Switch

Switching animations mid-playback by calling `sprite.play(newKey)` can silently no-op if the previous animation has not ended. Always call `sprite.anims.stop()` before `sprite.play(newKey, true)` when interrupting. The no-op is silent, which makes it expensive to find later.

```typescript
// Fragile — may no-op if the current animation is still running:
sprite.play('walk', true);

// Reliable — stop first, so the switch always fires:
sprite.anims.stop();
sprite.play('walk', true);
```

**Action required:** Audit every animation state-switch call site. The silent no-op makes this hard to notice in testing.

---

## 3. `ANIMATION_COMPLETE` Event Timing Drift

`Phaser.Animations.Events.ANIMATION_COMPLETE` (and the keyed variant `ANIMATION_COMPLETE_KEY + '<key>'`) is not guaranteed to land before the next `update()` tick. Do **not** mutate position or state synchronously inside the handler — `update()` may run first and overwrite you.

```typescript
// RISKY — state mutation may be stomped by update() on the next tick:
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'attack', () => {
  player.state = 'idle';  // may be overwritten
});

// SAFER — defer by a tick, OR use a flag the update() loop reads:
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'attack', () => {
  player.pendingStateChange = 'idle';
});

// In update():
if (player.pendingStateChange) {
  player.state = player.pendingStateChange;
  player.pendingStateChange = null;
}
```

**Important:** See also `skills/phaser-animation/references/state-machine-patterns.md` for the `cinematicMode` pattern that solves this class of bug.

---

## 4. Camera `setFollowOffset` + World-Bounds Wrap Math

The camera's follow offset is applied **after** the lerp/deadzone calculation. Any scroll correction you write in `update()` is computed before the follow math runs and gets overwritten by it, which shows up as visible lag at world-wrap edges.

**Action required:** Move world-wrap scroll correction to the `cameraupdate` event:

```typescript
// WRONG — overwritten by the follow math that runs after update():
// this.cameras.main.scrollX = Phaser.Math.Wrap(this.cameras.main.scrollX, 0, worldWidth);

// CORRECT — wrap inside cameraupdate, which runs after follow is applied:
this.cameras.main.on('cameraupdate', (cam: Phaser.Cameras.Scene2D.Camera) => {
  cam.scrollX = Phaser.Math.Wrap(cam.scrollX, 0, worldWidth);
  cam.scrollY = Phaser.Math.Wrap(cam.scrollY, 0, worldHeight);
});
```

---

## 5. Tilemap `setCollisionByProperty` — Pass All Three Arguments

The current signature is:

```typescript
setCollisionByProperty(properties: object, collides?: boolean, recalculateFaces?: boolean, layer?: string | number | TilemapLayer)
```

The optional arguments default in ways that are easy to misread, and `recalculateFaces` is what makes one-way platform edges behave. Be explicit.

**Implicit — relies on defaults, and skips face recalculation on some paths:**
```typescript
layer.setCollisionByProperty({ collides: true });
```

**Explicit — says exactly what you mean:**
```typescript
layer.setCollisionByProperty({ collides: true }, /* collides= */ true, /* recalculateFaces= */ true);
```

**Action required:** Run `grep -rn 'setCollisionByProperty' src/` and make each call site explicit. If tiles collide but a player slides along a seam between two solid tiles, `recalculateFaces` is your suspect.

---

## 6. `body.onFloor()` Frame-Timing Drift

`body.onFloor()` exists and works, but it resolves from the tile/world collision pass, which can land a step after `blocked.down` is set. For frame-accurate jump-landed detection — coyote time, landing squash, jump buffering — prefer the combined check.

```typescript
// Can be a frame late, which breaks tight platformer feel:
if (body.onFloor()) { landPlayer(); }

// Frame-accurate — blocked.down is set during the physics step itself:
const landed = body.blocked.down || body.onFloor();
if (landed) { landPlayer(); }
```

**Important:** Relying on `onFloor()` alone can produce a single frame of "in the air" after landing. At 60fps that is 16ms of dropped jump input — enough for players to report the game "eating" their jumps.

---

## 7. Cross-Scene Input Init: Use `READY`, Not `CREATE`

For cross-scene input wiring (e.g. a shared virtual joystick used across gameplay scenes), listen on the target scene's `READY` event. `CREATE` fires before the target scene's plugins are guaranteed to be attached, so `scene.input` / `scene.anims` references taken there can be null.

```typescript
// FRAGILE — fires too early; input references may still be null:
const inputScene = this.scene.get('InputScene');
inputScene.events.on(Phaser.Scenes.Events.CREATE, () => { /* wire joystick */ });

// RELIABLE — plugins are attached by READY:
const inputScene = this.scene.get('InputScene');
inputScene.events.once(Phaser.Scenes.Events.READY, () => { /* wire joystick */ });
```

**Action required:** Search for `events.on.*Events.CREATE` cross-scene wiring and migrate it to `READY`.

---

## 8. Group `createMultiple` / `setPosition` Signature Change

Setting positions inside the `createMultiple()` options object runs before each child's physics body is attached, so radial placement (an ambush ring of enemies around the player, a bullet spread) lands the sprite but not its body. Position after creation instead.

```typescript
// Unreliable: position inside createMultiple options — the physics body may not exist yet.
// Reliable: create first, then position after creation.
const enemies = this.enemies.createMultiple({
  key: 'enemy',
  quantity: 8,
  active: true,
  visible: true,
});

// Place each in a ring, now that every physics body exists:
enemies.forEach((enemy, i) => {
  const angle = (i / enemies.length) * Phaser.Math.PI2;
  enemy.setPosition(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
  enemy.setActive(true).setVisible(true);
});
```

---

## 9. `scale.on('resize')` After Orientation Flip

`scale.on('resize')` only fires if the parent container's reported size actually changed. On iOS, orientation changes and Safari toolbar collapse sometimes do not report a size change in time. Call `this.scale.refresh()` after `orientationchange` / `resize` DOM events as a safety net.

> Phaser 4.2.1 fixed a related bug where the Scale Manager failed to resize to its parent container at all (#7213). If you are chasing a parent-sizing bug, confirm you are on 4.2.1 or later before working around it.

| Platform | Resize trigger reliability |
|---|---|
| Desktop Chrome/Firefox | Reliable |
| Android Chrome | Generally reliable |
| iOS Safari | Unreliable — toolbar collapse may not fire |
| iOS PWA | Unreliable — orientation change timing varies |

```typescript
// scale.on('resize') covers most platforms; add a manual refresh safety net for iOS:
window.addEventListener('orientationchange', () => {
  // Wait one frame for the browser to settle, then force a refresh:
  requestAnimationFrame(() => this.scale.refresh());
});
```

---

## 10. Scale Manager + READY Event for Cold-Start Sizing (iOS PWA)

On iOS PWA cold-launch (PWA woken vertically from the app switcher), the initial viewport settles **after** Phaser's first sizing pass. Call your `syncGameSize()` equivalent inside Phaser's `READY` event and retry once at 300 ms.

```typescript
// iOS PWA: the viewport may not be final even at READY — add a 300ms safety net.

game.events.once(Phaser.Core.Events.READY, () => {
  syncGameSize();
  setTimeout(syncGameSize, 300); // safety net for late-settling viewports
});
```

**Important:** See `skills/phaser-mobile/references/device-profiles.md` for the full iOS PWA device profile.

---

## Audit Grep Checklist

Run these against any Phaser 4 codebase — inherited, migrated, or your own after a long gap:

```bash
# Removed masking API — migrate to camera viewports or the Mask filter
grep -rn 'createGeometryMask\|createBitmapMask\|BitmapMask\|setScissor' src/

# Animation switching without stop() — inspect each call site
grep -rn '\.play\(' src/ | grep -v ', true)'

# setCollisionByProperty — re-verify signature
grep -rn 'setCollisionByProperty' src/

# body.onFloor() — consider combining with body.blocked.down
grep -rn '\.onFloor()' src/

# Cross-scene CREATE listeners — consider migrating to READY
grep -rn "events\.on.*Events\.CREATE\|events\.on.*'create'" src/
```

Fix each match or confirm it is safe to ignore. Then run the playtest harness — every one of these
failures is invisible to `tsc` and visible at runtime:

```bash
node skills/phaser-playtest/scripts/playtest.mjs --project .
```

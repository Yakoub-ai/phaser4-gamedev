# Phaser 4 RC6 → RC7 Behavioral Drift

This file documents RC-to-RC behavioral drift within Phaser 4, distinct from the v3→v4 changes covered in the sibling reference. Read this when upgrading between RC releases, or when `anims`/camera/mask/tilemap/group/scene-event behavior silently differs from code that worked in an earlier RC.

---

## 1. Geometry Masks Broken for Rectangular Clipping

In RC7, geometry masks used for rectangular clip regions (e.g., scrollable panels) render incorrectly or not at all. Use Camera `scissor` for rectangular clips.

| Approach | RC6 | RC7 |
|---|---|---|
| Geometry mask for rect clip | Works | Broken |
| Alpha mask | Works | Works |
| Bitmap mask | Works | Works |
| Camera scissor | Works | Works (preferred) |

**BEFORE (RC6)** — Geometry mask for a scrollable settings panel:
```typescript
// RC6: geometry mask for rectangular scroll clip
const maskShape = this.add.graphics();
maskShape.fillStyle(0xffffff);
maskShape.fillRect(x, y, w, h);
const mask = maskShape.createGeometryMask();
panelContent.setMask(mask);
```

**AFTER (RC7)** — Camera scissor:
```typescript
// RC7: use Camera scissor for rectangular clips
const camera = this.cameras.add(x, y, w, h);
camera.setScroll(/* scrollX, scrollY */);
// Render only `panelContent` to this camera:
camera.ignore(this.children.list.filter(c => c !== panelContent));
```

**Important:** Alpha masks and bitmap masks are still valid in RC7. Only geometry masks for rectangular clipping are affected.

`[DEVLOG Chapter 7 — 2026-04-16 Settings scroll clipping]`

---

## 2. Animation `stop()` Required Before `play()` on State Switch

In RC7, switching animations mid-playback by calling `sprite.play(newKey)` can silently no-op if the previous animation hasn't ended. Always call `sprite.anims.stop()` before `sprite.play(newKey, true)` when interrupting.

| Scenario | RC6 | RC7 Safe Call |
|---|---|---|
| Switch state (idle → walk) mid-animation | `sprite.play('walk', true)` | `sprite.anims.stop(); sprite.play('walk', true);` |
| Restart same-key animation | `sprite.play(key, true)` | `sprite.play(key, true)` (unchanged) |
| First play (no prior animation) | `sprite.play(key)` | `sprite.play(key)` (unchanged) |

```typescript
// RC6: direct play sometimes worked mid-animation
sprite.play('walk', true);

// RC7: stop first to guarantee the switch fires
sprite.anims.stop();
sprite.play('walk', true);
```

**Action required:** Audit every animation state-switch call site. The silent no-op makes this hard to notice in testing.

`[DEVLOG Chapter 3 — 2026-04-14 Hub town anims; Chapter 7 — 2026-03-31 Animation state audit]`

---

## 3. `ANIMATION_COMPLETE` Event Timing Drift

In RC7, `Phaser.Animations.Events.ANIMATION_COMPLETE` (and the keyed variant `ANIMATION_COMPLETE_KEY + '<key>'`) fires **one tick later** than in RC6 for single-shot animations. Do **not** mutate position or state synchronously inside the handler — the next `update()` tick will run first and overwrite you.

```typescript
// RISKY in RC7 — state mutation may be stomped by update() on the next tick:
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

`[DEVLOG Chapter 3 — 2026-04-14]`

---

## 4. Camera `setFollowOffset` + World-Bounds Wrap Math

In RC7, the camera's follow offset is applied **after** the lerp/deadzone calculation, which changes visible behavior at world-wrap edges. Games with wrapping worlds see visible lag when the player approaches world-bounds.

| Wrap correction location | RC6 | RC7 |
|---|---|---|
| `update()` | Works | Overwritten by follow math |
| `cameraupdate` event | Works | Works (correct) |

**Action required:** Move world-wrap scroll correction to the `cameraupdate` event:

```typescript
// RC6: sometimes worked in update() — do NOT use this in RC7
// this.cameras.main.scrollX = Phaser.Math.Wrap(this.cameras.main.scrollX, 0, worldWidth);

// RC7: correct pattern — wrap inside cameraupdate, not update()
this.cameras.main.on('cameraupdate', (cam: Phaser.Cameras.Scene2D.Camera) => {
  cam.scrollX = Phaser.Math.Wrap(cam.scrollX, 0, worldWidth);
  cam.scrollY = Phaser.Math.Wrap(cam.scrollY, 0, worldHeight);
});
```

`[DEVLOG Chapter 7 — 2026-04-10 Camera wrap]`

---

## 5. Tilemap `setCollisionByProperty` Signature Change

The second argument's meaning changed in RC7. Verify your call-site.

| Argument form | RC6 | RC7 |
|---|---|---|
| Single-argument `{ collides: true }` | Worked | May behave differently |
| Explicit `(props, true, true)` | Worked | Required for full behavior |

**BEFORE (RC6)** — single-argument form still worked:
```typescript
// RC6:
layer.setCollisionByProperty({ collides: true });
```

**AFTER (RC7)** — explicit second arg required for full behavior, and the boolean polarity flipped in edge cases:
```typescript
// RC7: read the current signature in node_modules/phaser/types/ before writing new code
layer.setCollisionByProperty({ collides: true }, /* collides= */ true, /* recalculateFaces= */ true);
```

**Action required:** Run `grep -rn 'setCollisionByProperty' src/` after upgrading and re-verify each call site.

`[DEVLOG Chapter 4 — 2026-04-15 Prop collision]`

---

## 6. `body.onFloor()` Frame-Timing Drift

`body.onFloor()` still exists in RC7 but returns `true` **one physics step later** than in RC6. For jump-landed detection, prefer the combined check.

| Check | RC6 | RC7 |
|---|---|---|
| `body.onFloor()` alone | Reliable | 1 step late |
| `body.blocked.down` alone | Reliable | Reliable |
| `body.blocked.down \|\| body.onFloor()` | Reliable | Reliable (preferred) |

```typescript
// RC6: onFloor() alone was reliable
if (body.onFloor()) { landPlayer(); }

// RC7: combine with blocked.down for frame-accurate detection
const landed = body.blocked.down || body.onFloor();
if (landed) { landPlayer(); }
```

**Important:** Using `onFloor()` alone in RC7 can cause a frame of "in the air" after landing, which breaks tight platformer mechanics and coyote-time systems.

`[DEVLOG Chapter 7 — 2026-04-15 Enemy stuck detection]`

---

## 7. Cross-Scene Input Init: Use `READY`, Not `CREATE`

For cross-scene input wiring (e.g., a shared virtual joystick used across gameplay scenes), listen on the target scene's `READY` event. In RC7, `CREATE` on the launcher scene fires **before** the target scene's plugins are fully attached.

| Event | RC6 | RC7 |
|---|---|---|
| `Phaser.Scenes.Events.CREATE` | Plugins attached | Plugins may be null |
| `Phaser.Scenes.Events.READY` | Plugins attached | Plugins attached (use this) |

```typescript
// BEFORE (worked in RC6) — fires too early in RC7, input references may be null:
const inputScene = this.scene.get('InputScene');
inputScene.events.on(Phaser.Scenes.Events.CREATE, () => { /* wire joystick */ });

// AFTER (reliable in RC7):
const inputScene = this.scene.get('InputScene');
inputScene.events.once(Phaser.Scenes.Events.READY, () => { /* wire joystick */ });
```

**Action required:** Search for `events.on.*Events.CREATE` cross-scene wiring and migrate to `READY`.

`[DEVLOG Chapter 7 — 2026-04-11 Mobile joystick placement]`

---

## 8. Group `createMultiple` / `setPosition` Signature Change

The options object passed to `Group.createMultiple()` and the per-child `setPosition` call changed slightly in RC7. Notably, radial placement (e.g., an ambush ring of enemies around the player) must now set position after creation, not inside `createMultiple`.

```typescript
// RC6: position inside createMultiple options sometimes worked
// RC7: position inside createMultiple is unreliable — physics body may not exist yet

// RC7-safe pattern: create first, then position post-creation
const enemies = this.enemies.createMultiple({
  key: 'enemy',
  quantity: 8,
  active: true,
  visible: true,
});

// Place each in a ring (post-creation, after physics body exists):
enemies.forEach((enemy, i) => {
  const angle = (i / enemies.length) * Phaser.Math.PI2;
  enemy.setPosition(cx + Math.cos(angle) * r, cy + Math.sin(angle) * r);
  enemy.setActive(true).setVisible(true);
});
```

`[DEVLOG Chapter 7 — 2026-04-12 Ambush ring]`

---

## 9. `scale.on('resize')` After Orientation Flip

RC7's `scale.on('resize')` only fires if the parent container's reported size actually changed. On iOS, orientation changes and Safari toolbar collapse sometimes do not trigger a size change in time. Manually call `this.scale.refresh()` after `orientationchange` / `resize` DOM events if the listener doesn't fire.

| Platform | Resize trigger reliability (RC7) |
|---|---|
| Desktop Chrome/Firefox | Reliable |
| Android Chrome | Generally reliable |
| iOS Safari | Unreliable — toolbar collapse may not fire |
| iOS PWA | Unreliable — orientation change timing varies |

```typescript
// RC6: scale.on('resize') was sufficient on most platforms
// RC7: add a manual refresh safety net for iOS
window.addEventListener('orientationchange', () => {
  // Wait one frame for the browser to settle, then force a refresh:
  requestAnimationFrame(() => this.scale.refresh());
});
```

`[DEVLOG Chapter 6 — 2026-04-08 PWA / iOS safe-area]`

---

## 10. Scale Manager + READY Event for Cold-Start Sizing (iOS PWA)

On iOS PWA cold-launch (PWA held vertically from app-switcher wake), the initial viewport settles **after** Phaser's first sizing pass. Call your `syncGameSize()` equivalent inside Phaser's `READY` event and retry once at 300 ms.

```typescript
// RC6: single syncGameSize() call on game creation was sufficient
// RC7 / iOS PWA: viewport may not be final at READY — add a 300ms safety net

game.events.once(Phaser.Core.Events.READY, () => {
  syncGameSize();
  setTimeout(syncGameSize, 300); // safety net for late-settling viewports
});
```

**Important:** See `skills/phaser-mobile/references/device-profiles.md` for the full iOS PWA device profile.

`[DEVLOG Chapter 6 — 2026-04-18 iOS PWA cold-start]`

---

## RC7 Upgrade Grep Checklist

Run these after upgrading from RC6:

```bash
# Geometry masks — migrate rectangular clips to Camera scissor
grep -rn 'createGeometryMask\|setMask.*createGeometryMask' src/

# Animation switching without stop() — inspect each call site
grep -rn '\.play\(' src/ | grep -v ', true)'

# setCollisionByProperty — re-verify signature
grep -rn 'setCollisionByProperty' src/

# body.onFloor() — consider combining with body.blocked.down
grep -rn '\.onFloor()' src/

# Cross-scene CREATE listeners — consider migrating to READY
grep -rn "events\.on.*Events\.CREATE\|events\.on.*'create'" src/
```

Fix each match or confirm it is safe to ignore.

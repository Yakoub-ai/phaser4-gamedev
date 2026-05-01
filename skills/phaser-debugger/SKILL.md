---
name: phaser-debugger
description: This skill should be used when the user reports a Phaser 4 bug, black screen, missing sprite, failed collision, broken physics, animation issue, crash, console error, performance problem, slow game, save/load issue, mobile runtime issue, or unexpected gameplay behavior.
version: 0.5.0
---

# Phaser 4 Debugger

Use this skill to diagnose and fix Phaser 4 issues from evidence rather than guessing.

## Workflow

1. Collect the exact symptom, error text, stack trace, browser/device context, and reproduction steps when available.
2. Read the relevant code before editing. For black screens, inspect `src/main.ts`, scene registration, scene transitions, preload paths, and browser console/network errors.
3. Trace likely root causes using Phaser lifecycle order: config, preload, create, update, asset keys, physics body creation, collisions, input, scene start/stop state, and rendering depth.
4. Make the smallest fix that addresses the root cause.
5. Verify with `npx tsc --noEmit` for TypeScript projects and, when practical, a local dev-server smoke test.

## Debugging Checklist

- Asset 404s and mismatched texture keys
- Scene not registered or wrong scene key
- `this.physics`, `this.input`, or `this.anims` used before scene initialization
- Arcade body missing because object was created without physics
- Collider/overlap registered with the wrong object or group
- Animation key/frame mismatch
- Depth/alpha/camera bounds hiding an object
- Phaser 3 API usage after upgrading to Phaser 4
- Per-frame allocations, unbounded groups, and missing object pooling
- **Timer events not tracked** — `time.addEvent()` without a stored reference accumulates across scene restarts
- **Physics groups not explicitly destroyed** — evolved weapon groups and spawn-phase groups leak if not `clear(true,true)` + `destroy()`'d
- **Stat mutations without base+modifiers** — two systems writing the same stat in the same frame produce race-condition values
- **Notification dedup by string equality** — drops legitimate rapid repeat events (e.g. two coin pickups in 200 ms); use a time-window dedup instead
- **Overlay/panel backdrops sized from module-level constants** — freeze at boot size; use `this.cameras.main.width/height` + resize listener

## Common Silent Failure Categories

When the game freezes or behaves incorrectly with **no console error**, use these fast diagnostic paths before reaching for the full guide in `references/agent-guidance.md`.

**Silent freeze (no error):**
```typescript
// Add to main.ts BEFORE new Phaser.Game(config)
window.onerror = (msg, _src, _line, _col, err) => {
  console.error('GLOBAL ERROR:', msg, err?.stack);
};
window.onunhandledrejection = (ev) => {
  console.error('UNHANDLED REJECTION:', ev.reason);
};
```
Then hard-refresh. Any previously silent failure will now log. See `references/agent-guidance.md → Silent Freeze` for the full checklist.

**Spawns stop mid-session (no error):**
Pool slot leak — entities leaving the camera view without recycling their slot. Add `console.log('pool free:', pool.getTotalFree())` in your spawn call. If it hits zero and stays there, a slot is being held. See `references/agent-guidance.md → Pool Slot Leak`.

**Forced animation plays one frame then reverts:**
Entity `update()` overwrites forced animation one tick later. Fix with `cinematicMode` flag. See `skills/phaser-animation/references/state-machine-patterns.md`.

**Speed or stat jumps to wrong value intermittently:**
Two systems mutate the same stat on the same frame. Use base+modifiers pattern. See `references/agent-guidance.md → Race Between Two Systems`.

**Stuck entity detection fires incorrectly (false positives or negatives):**
`body.velocity` returns 0 when pushing against a wall. Use position-delta sampling instead. See `references/agent-guidance.md → Stuck Detection Fails`.

## Full Guidance

For the complete diagnostic playbook, read `references/agent-guidance.md`. It is copied from the Claude subagent definition but should be applied as a portable skill; ignore Claude-only fields such as `model`, `color`, and `tools`.

# Animation State-Machine Patterns (Phaser 4 RC7)

## Why a state machine

Without a state machine, any "forced" animation — a cinematic entry, a boss intro, a death sequence, a dungeon walk-in — will play for ONE frame and then be overwritten by the entity's default update-loop state logic on the very next tick. The fix is always the same: a `cinematicMode` flag that short-circuits `update()` before the default state logic runs.

## The `cinematicMode` flag pattern

```typescript
export class Player extends Phaser.Physics.Arcade.Sprite {
  private cinematicMode = false;

  /**
   * Play a forced one-shot animation that update() must not override.
   * Clears cinematicMode automatically when the animation completes.
   */
  setCinematicMode(active: boolean, forcedAnimKey?: string): void {
    this.cinematicMode = active;
    if (active && forcedAnimKey) {
      this.anims.stop();                     // REQUIRED before play() on state switch in RC7
      this.play(forcedAnimKey, true);
      this.once(
        Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + forcedAnimKey,
        () => { this.cinematicMode = false; }
      );
    }
  }

  update(cursors: Phaser.Types.Input.Keyboard.CursorKeys): void {
    // Early exit — MUST be at the top of update, before any state logic:
    if (this.cinematicMode) return;

    const body = this.body as Phaser.Physics.Arcade.Body;
    if (body.velocity.x !== 0 || body.velocity.y !== 0) {
      this.play('player-walk', true);
    } else {
      this.play('player-idle', true);
    }
  }
}
```

## Canonical state list

For standard platformer / top-down characters, use these six states:

| State   | Interrupts                       | Notes                                        |
|---------|----------------------------------|----------------------------------------------|
| idle    | walk, attack, dodge, hurt, death | default resting state                        |
| walk    | attack, dodge, hurt, death       | movement state                               |
| attack  | hurt, death                      | locked; only hurt/death can interrupt        |
| dodge   | death                            | locked during i-frames                       |
| hurt    | death                            | brief stun; resumes to idle when complete    |
| death   | (none — terminal)                | cannot be interrupted                        |

Implement transitions as a lookup rather than a cascade of `if` statements — it makes invalid transitions obvious on read.

## Transition table

```typescript
const TRANSITIONS: Record<CharState, CharState[]> = {
  idle:   ['walk', 'attack', 'dodge', 'hurt', 'death'],
  walk:   ['idle', 'attack', 'dodge', 'hurt', 'death'],
  attack: ['hurt', 'death'],
  dodge:  ['death'],
  hurt:   ['death', 'idle'],
  death:  [],
};

function canTransition(from: CharState, to: CharState): boolean {
  return TRANSITIONS[from].includes(to);
}
```

## RC7 ordering rule: always `stop()` before `play()` on state switch

In Phaser 4 RC7, calling `sprite.play(newKey)` mid-animation can silently no-op when the previous animation hasn't ended. ALWAYS:

```typescript
// Switching state (idle → walk):
sprite.anims.stop();
sprite.play('walk', true);

// Restarting same animation:
sprite.play('walk', true);  // true = ignoreIfPlaying=false (force restart)

// First play on a fresh sprite:
sprite.play('idle');  // no stop() needed
```

See also `skills/phaser-migrate/references/rc6-to-rc7-changes.md` → section 2 for the RC6 behavior.

## RC7 `ANIMATION_COMPLETE` timing drift

In RC7, `ANIMATION_COMPLETE` (and the keyed variant) fires one tick later than in RC6 for single-shot animations. Do NOT mutate position or state synchronously inside the handler — the next `update()` tick runs FIRST and overwrites you.

```typescript
// RISKY in RC7:
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'attack', () => {
  player.state = 'idle';  // may be overwritten by update() before next render
});

// SAFER — set a pending flag the update() loop reads:
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'attack', () => {
  player.pendingStateChange = 'idle';
});

// BEST — combine with cinematicMode flag for forced anims (see above pattern).
```

## Worked example: cinematic dungeon-entry walk-in

A complete example showing `cinematicMode` in action — a player character walking into a dungeon entrance with fade and shrink tweens layered over a looping walk animation. Without `cinematicMode`, the first `update()` tick after the forced `play('player-walk-up', true)` would revert to idle, because `body.velocity.x/y` is zero (the tween tweens `x/y` directly, not velocity).

```typescript
// In GameScene, when the player interacts with a dungeon entrance:
startDungeonEntry(): void {
  const arch = this.dungeonEntrance;

  // Flip player facing north and force the north-walk animation:
  this.player.setCinematicMode(true, 'player-walk-up');
  this.player.setDepth(arch.depth - 1);  // keystone covers player as they walk under

  // Walk into the arch with continuous walk animation looping:
  this.tweens.add({
    targets:  this.player,
    x:        arch.x,
    y:        arch.y + 4,
    duration: 400,
    scale:    0.8,       // shrink as they walk in
    alpha:    0,         // fade as they disappear
    onComplete: () => {
      this.player.setCinematicMode(false);
      this.scene.start('DungeonScene');
    },
  });
}
```

The critical line is `setCinematicMode(true, 'player-walk-up')` BEFORE the tween starts. Without it, the first `update()` tick after `play('player-walk-up', true)` would call `play('player-idle', true)` because `body.velocity.x/y` is zero during the tween — the tween tweens `x/y` directly, not velocity. The flag prevents update() from stomping the forced walk animation.

## Anti-pattern: guarded setCinematicMode

```typescript
// BAD — only sets mode if not mid-attack; leaves walk-loops playing if dialog opens mid-attack:
setCinematicMode(active: boolean): void {
  if (active && !this.isPlayingAttack && !this.isAttacking) {
    this.cinematicMode = active;
  }
}
```

The guarded form leaves walk-loops playing when dialogue opens mid-movement. The UNCONDITIONAL form (see pattern above) stops the current animation, clears transient flags, and snaps to the forced state. Prefer unconditional.

## Cross-references

- `skills/phaser-migrate/references/rc6-to-rc7-changes.md` — sections 2 (stop/play ordering) and 3 (ANIMATION_COMPLETE timing).
- `agents/phaser-coder.md` → "Animation Pattern" and "Critical Rules" have pointers back to this file.
- `agents/phaser-debugger.md` → "Forced Animation Stomped by Next Tick" category lists this file as the canonical fix.

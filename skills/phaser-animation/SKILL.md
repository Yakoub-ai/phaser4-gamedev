---
name: phaser-animation
description: This skill should be used when the user asks to "create animation", "animate sprite", "add tweens", "sprite animation not playing", "character animations", "easing", "tween timeline", "idle animation", "walk animation", "fade in", "fade out", or "scale animation".
version: 0.2.0
---

# Phaser 4 Animations and Tweens

Phaser 4 has two distinct animation systems: **frame-based sprite animations** (flip through frames in a texture atlas or spritesheet) and **tweens** (interpolate numeric properties over time). Use both together for polished game feel.

## Creating Spritesheet Animations

A spritesheet packs multiple frames into a single image in a regular grid. Define animations in `AnimationManager` using frame indices.

```typescript
// preload()
preload(): void {
  this.load.spritesheet('player', 'assets/player.png', {
    frameWidth: 48,
    frameHeight: 48,
  });
}

// create() — or PreloaderScene.create() for global animations (see below)
create(): void {
  this.anims.create({
    key:       'player-idle',
    frames:    this.anims.generateFrameNumbers('player', { start: 0, end: 3 }),
    frameRate: 8,
    repeat:    -1,           // -1 = loop forever
  });

  this.anims.create({
    key:       'player-walk',
    frames:    this.anims.generateFrameNumbers('player', { start: 4, end: 11 }),
    frameRate: 12,
    repeat:    -1,
  });

  this.anims.create({
    key:       'player-jump',
    frames:    this.anims.generateFrameNumbers('player', { start: 12, end: 15 }),
    frameRate: 10,
    repeat:    0,            // 0 = play once
  });

  this.anims.create({
    key:       'player-attack',
    frames:    this.anims.generateFrameNumbers('player', { start: 16, end: 23 }),
    frameRate: 16,
    repeat:    0,
  });
}
```

### generateFrameNumbers Options

```typescript
this.anims.generateFrameNumbers('texture', {
  start:  0,          // first frame index
  end:    7,          // last frame index (inclusive)
  first:  0,          // override which frame plays first
  frames: [0, 2, 4],  // manual frame list (use instead of start/end)
});
```

## Atlas-Based Animations

Texture atlases store frames with named keys rather than grid positions. Use `generateFrameNames` for these:

```typescript
// preload()
this.load.atlas('hero', 'assets/hero.png', 'assets/hero.json');

// create()
this.anims.create({
  key:       'hero-run',
  frames:    this.anims.generateFrameNames('hero', {
    prefix:  'run_',    // frame names are run_01, run_02, ...
    start:   1,
    end:     8,
    zeroPad: 2,         // zero-pad the number to 2 digits
    suffix:  '',        // optional suffix after the number
  }),
  frameRate: 12,
  repeat:    -1,
});

// Manual frame list from atlas
this.anims.create({
  key:    'hero-die',
  frames: [
    { key: 'hero', frame: 'die_01' },
    { key: 'hero', frame: 'die_02' },
    { key: 'hero', frame: 'die_03' },
  ],
  frameRate: 8,
  repeat:    0,
});
```

## Where to Define Animations

**Define animations in `PreloaderScene.create()` — not in each individual scene.** Animations registered on the global `AnimationManager` are available in every scene without re-registering:

```typescript
// src/scenes/PreloaderScene.ts
export class PreloaderScene extends Phaser.Scene {
  preload(): void {
    this.load.spritesheet('player', 'assets/player.png', { frameWidth: 48, frameHeight: 48 });
    this.load.atlas('enemies', 'assets/enemies.png', 'assets/enemies.json');
  }

  create(): void {
    // All anims defined here are available in GameScene, UIScene, etc.
    this.anims.create({ key: 'player-idle', /* ... */ });
    this.anims.create({ key: 'player-walk', /* ... */ });
    this.anims.create({ key: 'enemy-walk',  /* ... */ });

    this.scene.start('GameScene');
  }
}
```

If an animation only makes sense in a single scene (a cutscene animation, for example), define it in that scene's `create()`.

## Playing Animations

```typescript
// Basic play
sprite.play('player-walk');

// Play but don't restart if already playing this animation
sprite.play('player-walk', true);    // ignoreIfPlaying = true

// Play starting from a specific frame
sprite.playFromFrame('player-walk', 3);

// Stop on a specific frame number
sprite.stopOnFrame(this.anims.get('player-attack').frames[7]);

// Reverse playback
sprite.playReverse('player-walk');

// Check state
sprite.anims.isPlaying;                    // boolean
sprite.anims.currentAnim?.key;             // string | undefined
sprite.anims.currentFrame?.index;          // current frame index
```

## Animation Events

Listen for animation lifecycle events on the **sprite** (not the AnimationManager):

```typescript
// Fires when any animation completes on this sprite
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE, (anim, frame, gameObject) => {
  console.log('animation complete:', anim.key);
});

// Fires when a SPECIFIC animation completes (preferred — avoids key checks)
sprite.on(
  Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'player-attack',
  (anim, frame, gameObject) => {
    this.player.returnToIdle();
  }
);

// Other events
sprite.on(Phaser.Animations.Events.ANIMATION_START,   cb);  // animation started
sprite.on(Phaser.Animations.Events.ANIMATION_REPEAT,  cb);  // loop restarted
sprite.on(Phaser.Animations.Events.ANIMATION_RESTART, cb);  // play() called while already playing
sprite.on(Phaser.Animations.Events.ANIMATION_STOP,    cb);  // stop() called
sprite.on(Phaser.Animations.Events.ANIMATION_UPDATE,  cb);  // every frame change
```

Always remove listeners when the sprite is destroyed to prevent memory leaks:

```typescript
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE, this.onAnimComplete, this);
// In shutdown():
sprite.off(Phaser.Animations.Events.ANIMATION_COMPLETE, this.onAnimComplete, this);
```

## Animation Chaining

Play a sequence of animations one after another:

```typescript
// Chain via array — plays 'attack', then 'idle' automatically
sprite.chain(['player-attack', 'player-idle']);
sprite.play('player-attack');

// Chain via ANIMATION_COMPLETE event
sprite.play('player-jump');
sprite.once(
  Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'player-jump',
  () => sprite.play('player-fall')
);
```

## Character State Machine Pattern

For characters with idle/walk/jump/attack states, use an explicit state machine in `update()`. This prevents impossible state transitions and makes animation logic readable.

```typescript
type CharState = 'idle' | 'walk' | 'jump' | 'attack' | 'hurt';

export class Player extends Phaser.Physics.Arcade.Sprite {
  private state: CharState = 'idle';

  setState(newState: CharState): void {
    if (this.state === newState) return;
    this.state = newState;
    switch (newState) {
      case 'idle':   this.play('player-idle',   true); break;
      case 'walk':   this.play('player-walk',   true); break;
      case 'jump':   this.play('player-jump',   true); break;
      case 'attack': this.play('player-attack', true); break;
      case 'hurt':
        this.play('player-hurt', true);
        this.once(
          Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'player-hurt',
          () => this.setState('idle')
        );
        break;
    }
  }

  update(cursors: Phaser.Types.Input.Keyboard.CursorKeys): void {
    const body = this.body as Phaser.Physics.Arcade.Body;

    if (this.state === 'attack' || this.state === 'hurt') return;  // locked states

    if (!body.blocked.down) {
      this.setState('jump');
    } else if (cursors.left.isDown || cursors.right.isDown) {
      this.setState('walk');
    } else {
      this.setState('idle');
    }

    if (Phaser.Input.Keyboard.JustDown(cursors.space)) {
      this.setState('attack');
      this.once(
        Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'player-attack',
        () => this.setState('idle')
      );
    }
  }
}
```

## Stopping and Pausing Animations

```typescript
sprite.stop();            // stop and stay on current frame
sprite.anims.pause();     // pause on current frame (resumable)
sprite.anims.resume();    // resume paused animation
sprite.anims.restart();   // restart from frame 0
```

## Tweens

Tweens interpolate any numeric property on any object over time. They are Phaser's primary tool for UI animations, cutscenes, and visual feedback.

```typescript
this.tweens.add({
  targets:    sprite,       // one object, an array, or a group
  x:          400,          // tween x to 400
  y:          300,
  alpha:      1,
  duration:   800,          // milliseconds
  ease:       'Quad.Out',   // easing function
  delay:      0,            // ms before starting
  repeat:     0,            // 0 = once; -1 = infinite
  yoyo:       false,        // reverse back to start after completing
  hold:       0,            // ms to hold at end before yoyo
  onStart:    () => {},     // fires when tween starts
  onUpdate:   () => {},     // fires every frame
  onComplete: () => {},     // fires on completion
});
```

## Common Tween Patterns

### Fade In

```typescript
sprite.setAlpha(0);
this.tweens.add({ targets: sprite, alpha: 1, duration: 400, ease: 'Linear' });
```

### Fade Out and Destroy

```typescript
this.tweens.add({
  targets:    sprite,
  alpha:      0,
  duration:   300,
  ease:       'Linear',
  onComplete: () => sprite.destroy(),
});
```

### Scale Pulse (hit feedback, collectible)

```typescript
this.tweens.add({
  targets:  sprite,
  scaleX:   1.3,
  scaleY:   1.3,
  duration: 80,
  ease:     'Quad.Out',
  yoyo:     true,
});
```

### Slide In From Edge

```typescript
// Slide in from left
sprite.setX(-100);
this.tweens.add({
  targets:  sprite,
  x:        400,
  duration: 500,
  ease:     'Back.Out',
});
```

### Bounce Landing

```typescript
sprite.setY(targetY - 100);
this.tweens.add({
  targets:  sprite,
  y:        targetY,
  duration: 600,
  ease:     'Bounce.Out',
});
```

## Tween Easing Functions

See `references/easing-reference.md` for the complete guide with all easing functions and use cases.

Quick reference:
- `'Linear'` — constant speed; mechanical, UI bars
- `'Quad.Out'` — fast start, decelerates; most natural movement
- `'Quad.In'` — accelerates; falling objects, winding up
- `'Quad.InOut'` — symmetric ease; camera moves
- `'Back.Out'` — overshoots target then settles; UI popups, dialog slides
- `'Bounce.Out'` — bounces at destination; objects hitting ground
- `'Elastic.Out'` — spring oscillation; comic, bouncy UI

## Tween Timelines

Sequence multiple tweens without nesting `onComplete` callbacks:

```typescript
this.tweens.timeline({
  tweens: [
    {
      targets:  panel,
      alpha:    1,
      duration: 200,
    },
    {
      targets:  panel,
      y:        300,
      duration: 400,
      ease:     'Back.Out',
    },
    {
      targets:  title,
      alpha:    1,
      duration: 300,
      offset:   '-=100',   // start 100ms before previous tween ends (overlap)
    },
    {
      targets:  button,
      alpha:    1,
      duration: 200,
      // no offset = starts after previous completes
    },
  ],
});
```

`offset` controls timing relative to the previous tween:
- `'-=200'` — overlap by 200ms
- `'+=200'` — add 200ms gap
- absolute number — start at that ms from timeline start

## Particle Animations (Brief)

For burst effects (explosions, pickups, impacts), use the built-in particle system:

```typescript
// One-shot burst
this.add.particles(x, y, 'spark', {
  speed:     { min: 50, max: 200 },
  angle:     { min: 0, max: 360 },
  scale:     { start: 1, end: 0 },
  lifespan:  600,
  quantity:  12,
  emitting:  false,         // don't start automatically
}).explode(12);             // emit 12 particles immediately then stop

// Persistent emitter (fire, rain)
const emitter = this.add.particles(x, y, 'flame', {
  speed:    30,
  lifespan: 1200,
  scale:    { start: 0.8, end: 0 },
  alpha:    { start: 1, end: 0 },
  frequency: 80,            // ms between emissions
});
// Stop later:
emitter.stop();
```

## Additional Resources

### Reference Files
- **`references/animation-api.md`** — Complete AnimationManager, AnimationConfig, Animation events, TweenManager, and Timeline API reference
- **`references/easing-reference.md`** — All built-in easing functions with descriptions, use cases, and code examples

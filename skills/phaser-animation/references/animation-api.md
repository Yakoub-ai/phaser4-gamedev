# Phaser 4 Animation & Tween API Reference

## AnimationManager

Access via `this.anims` inside any Scene. Animations are globally registered — define once, use in any scene.

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `add` | `add(key: string, animation: Animation): Animation` | Register an already-constructed `Animation` object. Prefer `create()`. |
| `create` | `create(config: AnimationConfig): Animation \| false` | Create and register an animation from config. Returns `false` if key already exists. |
| `exists` | `exists(key: string): boolean` | Check if an animation key is registered. |
| `generateFrameNames` | `generateFrameNames(key: string, config?: GenerateFrameNamesConfig): AnimationFrame[]` | Generate frame list from a texture atlas using named frames. |
| `generateFrameNumbers` | `generateFrameNumbers(key: string, config?: GenerateFrameNumbersConfig): AnimationFrame[]` | Generate frame list from a spritesheet using frame indices. |
| `get` | `get(key: string): Animation` | Get a registered animation by key. Throws if not found. |
| `getAll` | `getAll(): Animation[]` | Get all registered animations. |
| `play` | `play(key: string, gameObjects: GameObject \| GameObject[]): void` | Play a named animation on one or more game objects. |
| `pause` | `pause(): AnimationManager` | Pause all animations globally. |
| `resume` | `resume(): AnimationManager` | Resume all globally paused animations. |
| `remove` | `remove(key: string): Animation \| undefined` | Remove and return an animation by key. |
| `toJSON` | `toJSON(key?: string): JSONAnimationManager` | Serialize all (or one) animation to JSON. |
| `fromJSON` | `fromJSON(data: string \| JSONAnimationManager \| JSONAnimation, clearCurrentAnimations?: boolean): Animation[]` | Recreate animations from JSON. |
| `destroy` | `destroy(): void` | Destroy all animations and remove the manager. |

### Properties

| Property | Type | Description |
|----------|------|-------------|
| `anims` | `CustomMap<string, Animation>` | Map of all registered animations. |
| `paused` | `boolean` | Whether global animation pause is active. |
| `name` | `string` | Plugin name (`'AnimationManager'`). |
| `textureManager` | `TextureManager` | Reference to the game's texture manager. |
| `globalTimeScale` | `number` | Multiplier for all animation frame times. |

---

## AnimationConfig Interface

`Phaser.Types.Animations.Animation`

```typescript
interface AnimationConfig {
  key:            string;              // REQUIRED — unique identifier
  frames?:        AnimationFrame[];    // frame array from generateFrameNumbers/generateFrameNames
  defaultTextureKey?: string;          // fallback texture key if frames don't specify one
  frameRate?:     number;              // frames per second (default: 24)
  duration?:      number;              // total duration in ms — overrides frameRate if set
  skipMissedFrames?: boolean;          // skip frames if update is slow (default: true)
  delay?:         number;              // ms before first play (default: 0)
  repeat?:        number;              // 0 = once, -1 = loop forever, N = play N+1 times
  repeatDelay?:   number;              // ms to wait between repeats (default: 0)
  yoyo?:          boolean;             // reverse direction after each play (default: false)
  showBeforeDelay?: boolean;           // show first frame during initial delay (default: false)
  showOnStart?:   boolean;             // make gameObject visible when animation starts (default: false)
  hideOnComplete?: boolean;            // hide gameObject when animation completes (default: false)
}
```

### GenerateFrameNumbersConfig

```typescript
interface GenerateFrameNumbersConfig {
  start?:  number;    // first frame index (default: 0)
  end?:    number;    // last frame index (default: -1 = last frame)
  first?:  number;    // which frame to display first in the animation
  frames?: number[];  // explicit list of frame indices (use instead of start/end)
}
```

### GenerateFrameNamesConfig

```typescript
interface GenerateFrameNamesConfig {
  prefix?:  string;   // frame name prefix (e.g. 'walk_')
  start?:   number;   // start number (default: 0)
  end?:     number;   // end number (default: 0)
  suffix?:  string;   // frame name suffix (e.g. '.png' — most atlases don't need this)
  zeroPad?: number;   // zero-pad the number to this many digits (e.g. 2 → '01', '02')
  frames?:  string[]; // explicit list of frame names (use instead of prefix/start/end)
  outputArray?: AnimationFrame[];  // append to existing array
}
```

---

## Animation Events

`Phaser.Animations.Events`

Listen on the **sprite** (`sprite.on(...)`) not the AnimationManager.

| Constant | String Value | Callback Parameters | Description |
|----------|-------------|---------------------|-------------|
| `ANIMATION_COMPLETE` | `'animationcomplete'` | `(animation, frame, gameObject, frameKey)` | Any animation on this sprite completes (non-looping, or after all repeats) |
| `ANIMATION_COMPLETE_KEY` | `'animationcomplete-'` | `(animation, frame, gameObject)` | Append the animation key: `ANIMATION_COMPLETE_KEY + 'walk'`. Fires only for that animation. |
| `ANIMATION_REPEAT` | `'animationrepeat'` | `(animation, frame, gameObject)` | Animation loops or repeats |
| `ANIMATION_RESTART` | `'animationrestart'` | `(animation, frame, gameObject)` | `play()` called on an already-playing animation |
| `ANIMATION_START` | `'animationstart'` | `(animation, frame, gameObject)` | Animation begins playing |
| `ANIMATION_STOP` | `'animationstop'` | `(animation, frame, gameObject)` | `stop()` called on the animation |
| `ANIMATION_UPDATE` | `'animationupdate'` | `(animation, frame, gameObject)` | Fires every time the displayed frame changes |

```typescript
// Best practice — use the key-specific event to avoid key checks
sprite.on(
  Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'player-attack',
  (anim: Phaser.Animations.Animation, frame: Phaser.Animations.AnimationFrame, gameObject: Phaser.GameObjects.Sprite) => {
    gameObject.play('player-idle');
  }
);

// Use once() for single-fire transitions
sprite.once(
  Phaser.Animations.Events.ANIMATION_COMPLETE_KEY + 'player-hurt',
  () => sprite.play('player-idle')
);
```

---

## Sprite Animation Controller Methods

On any `Phaser.GameObjects.Sprite` or `Phaser.Physics.Arcade.Sprite`:

| Method | Signature | Description |
|--------|-----------|-------------|
| `play` | `play(key: string \| AnimationConfig, ignoreIfPlaying?: boolean): this` | Play animation by key. Pass `true` as second arg to ignore call if already playing. |
| `playFromFrame` | `playFromFrame(key: string \| AnimationConfig, startFrame: number, ignoreIfPlaying?: boolean): this` | Play starting from a specific frame index. |
| `playReverse` | `playReverse(key: string \| AnimationConfig, ignoreIfPlaying?: boolean): this` | Play animation in reverse. |
| `chain` | `chain(key: string \| string[] \| AnimationConfig[]): this` | Queue animations to play in sequence after the current one completes. |
| `stop` | `stop(): this` | Stop playback, stay on current frame. |
| `stopAfterDelay` | `stopAfterDelay(delay: number): this` | Stop after `delay` ms. |
| `stopOnFrame` | `stopOnFrame(frame: AnimationFrame): this` | Stop when a specific frame is reached. |
| `stopOnRepeat` | `stopOnRepeat(): this` | Stop after the current repeat cycle completes. |

### Sprite `anims` Controller Properties

Access via `sprite.anims`:

| Property | Type | Description |
|----------|------|-------------|
| `isPlaying` | `boolean` | `true` if currently animating. |
| `isPaused` | `boolean` | `true` if paused. |
| `currentAnim` | `Animation \| null` | Currently loaded animation object. |
| `currentFrame` | `AnimationFrame \| null` | Currently displayed frame. |
| `frameRate` | `number` | Current frame rate (may differ from config during speed changes). |
| `duration` | `number` | Total animation duration in ms. |
| `msPerFrame` | `number` | Milliseconds per frame. |
| `skipMissedFrames` | `boolean` | Whether to skip frames when lagging. |
| `accumulator` | `number` | Internal frame time accumulator. |
| `nextTick` | `number` | Time until next frame advance. |
| `repeatCounter` | `number` | Current repeat count. |
| `forward` | `boolean` | `true` if playing forward, `false` if reversed. |

---

## TweenManager

Access via `this.tweens` inside any Scene.

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `add` | `add(config: TweenBuilderConfig \| TweenBuilderConfig[]): Tween` | Create and start a tween immediately. Returns the `Tween` instance. |
| `create` | `create(config: TweenBuilderConfig): Tween` | Create a tween without starting it. Call `tween.play()` manually. |
| `addCounter` | `addCounter(config: TweenBuilderConfig): Tween` | Tween a plain number (no game object). Useful for timers and value interpolation. |
| `timeline` | `timeline(config: TimelineBuilderConfig): Timeline` | Create a sequence of tweens with ordering and offsets. |
| `add` | `add(config: TweenChainBuilderConfig): TweenChain` | Create a chained sequence of tweens (alternative to timeline). |
| `killAll` | `killAll(): TweenManager` | Stop and remove all active tweens. |
| `killTweensOf` | `killTweensOf(target: object \| object[]): TweenManager` | Stop all tweens targeting the given object(s). |
| `pauseAll` | `pauseAll(): TweenManager` | Pause all active tweens. |
| `resumeAll` | `resumeAll(): TweenManager` | Resume all paused tweens. |
| `isTweening` | `isTweening(target: object): boolean` | Check if a target has an active tween. |
| `getTweensOf` | `getTweensOf(target: object, includePending?: boolean): Tween[]` | Get all tweens targeting this object. |
| `getAll` | `getAll(): Tween[]` | Get all active tweens. |
| `destroy` | `destroy(): void` | Destroy the TweenManager and all tweens. |

---

## TweenBuilderConfig Interface

`Phaser.Types.Tweens.TweenBuilderConfig`

```typescript
interface TweenBuilderConfig {
  targets:        any;                     // REQUIRED — object, array, or group
  
  // Property shorthands (can also use 'props' object)
  x?:             number | TweenPropConfig;
  y?:             number | TweenPropConfig;
  alpha?:         number | TweenPropConfig;
  scaleX?:        number | TweenPropConfig;
  scaleY?:        number | TweenPropConfig;
  scale?:         number | TweenPropConfig;
  angle?:         number | TweenPropConfig;
  rotation?:      number | TweenPropConfig;
  width?:         number | TweenPropConfig;
  height?:        number | TweenPropConfig;
  // ... any numeric property on the target object
  
  // Or use 'props' for multiple properties with individual configs:
  props?: {
    [property: string]: number | TweenPropConfig;
  };

  duration?:      number;                  // ms for one tween cycle (default: 1000)
  ease?:          string | Function;       // easing function name or custom function (default: 'Linear')
  easeParams?:    number[];                // parameters for configurable easings
  delay?:         number;                  // ms before first play (default: 0)
  repeat?:        number;                  // 0 = once, -1 = infinite (default: 0)
  repeatDelay?:   number;                  // ms between repeats (default: 0)
  yoyo?:          boolean;                 // reverse direction on repeat (default: false)
  hold?:          number;                  // ms to hold at end before yoyo reverse (default: 0)
  flipX?:         boolean;                 // flip sprite X on each yoyo (default: false)
  flipY?:         boolean;                 // flip sprite Y on each yoyo (default: false)
  offset?:        null | number | string;  // timeline offset (null = after previous)
  completeDelay?: number;                  // extra ms after last cycle before onComplete fires
  loop?:          number;                  // alias for repeat (-1 = infinite loop)
  loopDelay?:     number;                  // alias for repeatDelay
  paused?:        boolean;                 // start paused (default: false)
  useFrames?:     boolean;                 // use game frames instead of ms for duration
  callbackScope?: any;                     // `this` context for all callbacks
  
  // Callbacks
  onStart?:       TweenOnStartCallback;     // (tween, targets, param) => void
  onStartScope?:  any;
  onStartParams?: any[];
  
  onActive?:      TweenOnActiveCallback;    // fires when tween becomes active in queue
  
  onUpdate?:      TweenOnUpdateCallback;    // (tween, target, key, current, previous, param) => void
  onUpdateScope?: any;
  onUpdateParams?: any[];
  
  onRepeat?:      TweenOnRepeatCallback;    // fires on each repeat
  onRepeatScope?: any;
  onRepeatParams?: any[];
  
  onYoyo?:        TweenOnYoyoCallback;      // fires when yoyo reversal begins
  onYoyoScope?:   any;
  onYoyoParams?:  any[];
  
  onComplete?:    TweenOnCompleteCallback;  // (tween, targets, param) => void
  onCompleteScope?: any;
  onCompleteParams?: any[];
  
  onStop?:        TweenOnStopCallback;
  onLoop?:        TweenOnLoopCallback;
  
  persist?:       boolean;                 // keep tween after completion (don't auto-destroy)
}
```

### TweenPropConfig (per-property fine control)

```typescript
interface TweenPropConfig {
  value:     number | string;  // target value, or '+= / -=' relative string
  ease?:     string;           // override ease for this property only
  duration?: number;           // override duration for this property only
  delay?:    number;           // delay for this property within the tween
  yoyo?:     boolean;
  repeat?:   number;
  from?:     number;           // force a start value (overrides current)
}
```

---

## Tween Instance Methods

| Method | Description |
|--------|-------------|
| `play()` | Start a tween created with `create()` (not `add()`). |
| `pause()` | Pause this tween. |
| `resume()` | Resume this tween. |
| `stop(resetTo?: number)` | Stop the tween. Optionally reset targets to a normalized value (0–1). |
| `seek(toPosition: number)` | Jump to a position in the tween (0 = start, 1 = end). |
| `setTimeScale(value: number)` | Set time scale for this tween only. |
| `getTimeScale()` | Get this tween's time scale. |
| `isPlaying()` | Returns `true` if active and not paused. |
| `isPaused()` | Returns `true` if paused. |
| `hasTarget(target: object)` | Check if a target is part of this tween. |
| `updateTo(key: string, value: number, startToCurrent?: boolean)` | Update a target property during playback. |
| `complete(delay?: number)` | Force complete after optional delay. |
| `remove()` | Remove this tween from TweenManager. |
| `destroy()` | Destroy this tween and free resources. |

---

## TimelineBuilderConfig

`Phaser.Types.Tweens.TimelineBuilderConfig`

```typescript
interface TimelineBuilderConfig {
  tweens:     TweenBuilderConfig[];   // REQUIRED — ordered list of tween configs
  targets?:   any;                    // default targets for all tweens (overridden per-tween)
  totalDuration?: number;             // scale all tweens to fit this total duration
  ease?:      string;                 // default ease for all tweens
  easeParams?: number[];
  delay?:     number;
  loop?:      number;
  loopDelay?: number;
  yoyo?:      boolean;
  flipX?:     boolean;
  flipY?:     boolean;
  completeDelay?: number;
  paused?:    boolean;
  persist?:   boolean;
  callbackScope?: any;
  onStart?:   TweenOnStartCallback;
  onUpdate?:  TweenOnUpdateCallback;
  onLoop?:    TweenOnLoopCallback;
  onYoyo?:    TweenOnYoyoCallback;
  onComplete?: TweenOnCompleteCallback;
}
```

### Tween `offset` in Timelines

| Value | Behavior |
|-------|----------|
| `undefined` / `null` | Start after previous tween ends |
| `'-=200'` | Start 200ms before previous ends (overlap) |
| `'+=200'` | Start 200ms after previous ends (gap) |
| `500` (absolute number) | Start at 500ms from timeline start |
| `0` | Start at the very beginning of the timeline |

### Timeline Instance Methods

| Method | Description |
|--------|-------------|
| `play()` | Start the timeline if created with `paused: true`. |
| `pause()` | Pause all tweens in the timeline. |
| `resume()` | Resume all tweens. |
| `stop()` | Stop the timeline. |
| `destroy()` | Destroy the timeline and all its tweens. |
| `getTotalDuration()` | Get total calculated duration in ms. |

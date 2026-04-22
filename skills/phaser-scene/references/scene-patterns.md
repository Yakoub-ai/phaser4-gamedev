# Phaser 4 Scene Patterns — Detailed Reference

## Scene Manager API

```typescript
// In any scene:
this.scene.start('Key')                    // Stop current, start target
this.scene.start('Key', { data: 'value' }) // With data
this.scene.restart()                        // Restart current scene
this.scene.restart({ lives: 3 })           // Restart with new init data

this.scene.launch('HUDScene')              // Run in parallel (no stop)
this.scene.pause('GameScene')              // Pause (update stops, render continues)
this.scene.resume('GameScene')             // Resume a paused scene
this.scene.stop('HUDScene')               // Stop and destroy scene state
this.scene.sleep('GameScene')             // Like pause but render also stops
this.scene.wake('GameScene')              // Reverse of sleep

this.scene.switch('OtherScene')           // Sleep current, start other (fast swap)
this.scene.get('Key')                      // Get reference to another scene

// Check scene state
this.scene.isActive('GameScene')           // true if running
this.scene.isPaused('GameScene')           // true if paused
this.scene.isSleeping('GameScene')         // true if sleeping
```

## Scene Events

```typescript
// Scene lifecycle events (listen from another scene or plugin):
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.CREATE, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.START, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.READY, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.UPDATE, (time, delta) => {});
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.PAUSE, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.RESUME, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.SLEEP, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.WAKE, handler);
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.SHUTDOWN, handler); // before stop
this.scene.get('GameScene').events.on(Phaser.Scenes.Events.DESTROY, handler);
```

## Advanced Transition Pattern (with Fade)

```typescript
// Fade out → transition → fade in
export class TransitionMixin {
  static fadeToScene(scene: Phaser.Scene, targetKey: string, data?: object, duration = 500): void {
    scene.cameras.main.fadeOut(duration, 0, 0, 0, (_cam: Phaser.Cameras.Scene2D.Camera, progress: number) => {
      if (progress === 1) {
        scene.scene.start(targetKey, data);
      }
    });
  }
}

// Usage in any scene:
TransitionMixin.fadeToScene(this, 'GameScene', { level: 2 });
```

## Multiple Parallel Scenes Architecture

For complex games with overlapping layers:

```typescript
// In main.ts scene order matters for depth:
scene: [
  BootScene,
  PreloaderScene,
  BackgroundScene,   // Stars, parallax — always running
  GameScene,         // Main gameplay
  HUDScene,          // Health, score overlay
  PauseScene,        // Modal overlay (launched on demand)
  GameOverScene,
]

// Background scene launched at game start and never stopped:
// In MainMenuScene.create() or GameScene.create():
if (!this.scene.isActive('BackgroundScene')) {
  this.scene.launch('BackgroundScene');
}
```

## Scene Data Lifecycle

```typescript
// Data flows through init(data) when started with:
// this.scene.start('Target', { lives: 3, score: 500 })
// this.scene.restart({ checkpoint: 'area2' })

export class GameScene extends Phaser.Scene {
  private level!: number;
  private startScore!: number;

  init(data: { level?: number; score?: number }): void {
    // init() runs BEFORE preload()
    // Safe to set up state here
    this.level = data.level ?? 1;
    this.startScore = data.score ?? 0;
  }

  preload(): void {
    // Can use this.level to load level-specific assets
    this.load.tilemapTiledJSON(`level${this.level}`, `assets/tilemaps/level${this.level}.json`);
  }

  create(): void {
    // Use this.level and this.startScore
  }
}
```

## Registry Patterns

```typescript
// Type-safe registry wrapper
export class GameRegistry {
  private static scene: Phaser.Scene;

  static init(scene: Phaser.Scene): void {
    this.scene = scene;
    // Set defaults
    scene.registry.set('score', 0);
    scene.registry.set('lives', 3);
    scene.registry.set('level', 1);
    scene.registry.set('hiScore', localStorage.getItem('hiScore') ?? 0);
  }

  static get score(): number { return this.scene.registry.get('score') as number; }
  static set score(v: number) {
    this.scene.registry.set('score', v);
    if (v > (this.scene.registry.get('hiScore') as number)) {
      this.scene.registry.set('hiScore', v);
      localStorage.setItem('hiScore', String(v));
    }
  }

  static get lives(): number { return this.scene.registry.get('lives') as number; }
  static set lives(v: number) { this.scene.registry.set('lives', v); }
}

// Listen for any registry change:
scene.registry.events.on('changedata', (parent: Phaser.Scene, key: string, value: unknown) => {
  console.log(`Registry changed: ${key} = ${value}`);
});

// Listen for specific key:
scene.registry.events.on('changedata-score', (parent: Phaser.Scene, value: number) => {
  scoreText.setText(`Score: ${value}`);
});
```

## Responsive Sizing: Two Layers (iOS-safe)

Responsive Phaser games have TWO independent sizing layers, and fixing only one leaves the other broken:

1. **Canvas layer** — CSS scale mode, parent div sizing, safe-area insets. Set in `main.ts` / GameConfig + CSS.
2. **In-game element layer** — HUD positions, overlay `fillRect` dimensions, panel backdrop sizing. Set inside each scene's `create()`.

If your HUD positions are computed from module-level `GAME_WIDTH` / `GAME_HEIGHT` constants baked at import time, they will NOT update when the canvas grows (iOS rotation, Safari toolbar collapse, full-screen entry). The backdrop leaks off the right edge; the HUD drifts off-center.

**Correct pattern — live camera dimensions + resize listener:**

```typescript
export class LevelUpScene extends Phaser.Scene {
  private backdrop!: Phaser.GameObjects.Rectangle;

  create(): void {
    // READ FROM LIVE CAMERA, not from imported constants:
    const { width, height } = this.cameras.main;

    this.backdrop = this.add.rectangle(0, 0, width, height, 0x000000, 0.75)
      .setOrigin(0, 0);

    // React to canvas resize (orientation, full-screen, toolbar collapse):
    this.scale.on('resize', this.onResize, this);
  }

  private onResize(gameSize: Phaser.Structs.Size): void {
    this.backdrop.setSize(gameSize.width, gameSize.height);
    // ...reposition any other HUD elements that depend on viewport...
  }

  shutdown(): void {
    // CRITICAL: remove the listener so it doesn't accumulate across scene restarts.
    this.scale.off('resize', this.onResize, this);
  }
}
```

**Anti-pattern to recognize during code review:**

```typescript
// BAD — GAME_WIDTH is frozen at import time:
import { GAME_WIDTH, GAME_HEIGHT } from './constants';
this.backdrop = this.add.rectangle(0, 0, GAME_WIDTH, GAME_HEIGHT, 0x000000, 0.75);
```

Any overlay scene (PauseScene, LevelUpScene, SettingsScene, GameOverScene) that sizes its backdrop from `GAME_WIDTH` / `GAME_HEIGHT` imported constants will leak past the right edge as soon as the canvas grows — even once. Use the live-camera + resize-listener pattern above.

## Cross-Scene Input Initialization (Phaser 4 RC7)

For shared input layers (virtual joystick, global keyboard bindings, gamepad service) that span multiple gameplay scenes, listen on the **target scene's `READY` event** — NOT on the launcher scene's `CREATE`.

In RC7, the launcher's `CREATE` fires before the target scene's input plugins are fully attached. Calling `this.input.keyboard!.on(...)` from a `CREATE` listener is a silent no-op: the keyboard plugin is still initializing.

```typescript
// BEFORE (worked in RC6, fails silently in RC7):
this.scene.launch('InputScene');
const inputScene = this.scene.get('InputScene');
inputScene.events.on(Phaser.Scenes.Events.CREATE, () => {
  // keyboard plugin may not be ready yet — binds sometimes drop
  inputScene.input.keyboard!.on('keydown-ESC', this.openPauseMenu, this);
});

// AFTER (reliable in RC7):
this.scene.launch('InputScene');
const inputScene = this.scene.get('InputScene');
inputScene.events.once(Phaser.Scenes.Events.READY, () => {
  inputScene.input.keyboard!.on('keydown-ESC', this.openPauseMenu, this);
});
```

**Rule of thumb:** `CREATE` fires when the scene's objects start being built; `READY` fires when plugins are fully attached and input bindings are safe to register. For cross-scene wiring, always use `READY`.

See also `skills/phaser-migrate/references/rc6-to-rc7-changes.md` → section 7 for the full RC6/RC7 comparison.

## Scene Plugin Architecture

For shared functionality across scenes, use the Scene Plugin system:

```typescript
// Define a shared plugin (e.g., audio manager)
export class AudioPlugin extends Phaser.Plugins.ScenePlugin {
  private bgm?: Phaser.Sound.BaseSound;

  boot(): void {
    this.scene.events.on('shutdown', this.shutdown, this);
  }

  playBgm(key: string): void {
    this.bgm?.stop();
    this.bgm = this.scene.sound.add(key, { loop: true, volume: 0.5 });
    this.bgm.play();
  }

  stopBgm(): void { this.bgm?.stop(); }

  private shutdown(): void { this.bgm?.stop(); }
}

// Register in GameConfig:
const config: Phaser.Types.Core.GameConfig = {
  plugins: {
    scene: [{
      key: 'AudioPlugin',
      plugin: AudioPlugin,
      mapping: 'audio',  // access as this.audio in any scene
    }]
  }
};

// Use in any scene:
(this as any).audio.playBgm('level1-bgm');
```

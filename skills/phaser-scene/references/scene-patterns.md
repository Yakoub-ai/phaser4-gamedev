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

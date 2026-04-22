---
name: phaser-scene
description: This skill should be used when the user asks to "create a scene", "add a new scene", "make a menu scene", "create a game over screen", "add a level", "set up scene transitions", "create a pause screen", "add a preloader", "create a HUD overlay", or needs any Phaser 4 scene created, structured, or connected to other scenes.
version: 0.4.0
---

# Phaser 4 Scene Creation

Every Phaser 4 game is composed of Scene classes. Each scene is a self-contained unit with its own lifecycle, assets, and game objects.

## Scene Class Pattern

The canonical pattern for every scene:

```typescript
import Phaser from 'phaser';

export class MyScene extends Phaser.Scene {
  constructor() {
    super({ key: 'MyScene' });  // key MUST be unique across all scenes
  }

  // Called when scene starts, before preload. Receive data from previous scene.
  init(data?: Record<string, unknown>): void {
    // e.g., data.level, data.score from this.scene.start('MyScene', { level: 2 })
  }

  // Load assets used only by this scene (prefer PreloaderScene for shared assets)
  preload(): void { }

  // Build the scene: create game objects, physics, input, events
  create(): void { }

  // Called every frame. Keep lean — call helper methods
  update(time: number, delta: number): void { }
}
```

Register every scene in `main.ts` GameConfig:
```typescript
scene: [BootScene, PreloaderScene, MainMenuScene, GameScene, GameOverScene]
```

## Scene Type Patterns

### BootScene

Minimal. Loads only the assets needed for the loading bar, immediately transitions.

```typescript
export class BootScene extends Phaser.Scene {
  constructor() { super({ key: 'BootScene' }); }

  preload(): void {
    this.load.image('loading-bg', 'assets/images/loading-bg.png');
    this.load.image('loading-bar', 'assets/images/loading-bar.png');
  }

  create(): void {
    this.scene.start('PreloaderScene');
  }
}
```

### PreloaderScene

Shows a loading bar while loading ALL game assets. Set up global animations here too.

```typescript
export class PreloaderScene extends Phaser.Scene {
  constructor() { super({ key: 'PreloaderScene' }); }

  preload(): void {
    const { width, height } = this.scale;

    // Loading bar
    const bg = this.add.graphics();
    bg.fillStyle(0x111111, 0.8);
    bg.fillRect(width / 2 - 160, height / 2 - 25, 320, 50);

    const bar = this.add.graphics();
    this.load.on('progress', (value: number) => {
      bar.clear();
      bar.fillStyle(0x00ff88, 1);
      bar.fillRect(width / 2 - 150, height / 2 - 15, 300 * value, 30);
    });

    // ── Load all game assets here ──
    this.load.atlas('characters', 'assets/atlases/characters.png', 'assets/atlases/characters.json');
    this.load.audio('bgm', ['assets/audio/bgm.mp3', 'assets/audio/bgm.ogg']);
  }

  create(): void {
    // Create all animations here — available globally after this
    this.anims.create({
      key: 'player-idle',
      frames: this.anims.generateFrameNumbers('player', { start: 0, end: 3 }),
      frameRate: 8,
      repeat: -1,
    });

    this.scene.start('MainMenuScene');
  }
}
```

### MainMenuScene

Title screen. Handles start button, settings navigation.

```typescript
export class MainMenuScene extends Phaser.Scene {
  constructor() { super({ key: 'MainMenuScene' }); }

  create(): void {
    const { width, height } = this.scale;

    this.add.image(width / 2, height / 2, 'menu-bg');
    this.add.text(width / 2, height * 0.3, 'MY GAME', {
      fontSize: '64px',
      color: '#ffffff',
      fontFamily: 'Arial Black',
    }).setOrigin(0.5);

    const startBtn = this.add.text(width / 2, height * 0.6, 'PLAY', {
      fontSize: '32px',
      color: '#00ff88',
      backgroundColor: '#333',
      padding: { x: 20, y: 10 },
    }).setOrigin(0.5).setInteractive({ useHandCursor: true });

    startBtn.on('pointerover', () => startBtn.setStyle({ color: '#ffff00' }));
    startBtn.on('pointerout', () => startBtn.setStyle({ color: '#00ff88' }));
    startBtn.on('pointerdown', () => {
      this.cameras.main.fadeOut(500, 0, 0, 0, () => {
        this.scene.start('GameScene', { level: 1 });
      });
    });
  }
}
```

### GameOverScene

End state. Display score, offer restart.

```typescript
export class GameOverScene extends Phaser.Scene {
  constructor() { super({ key: 'GameOverScene' }); }

  init(data: { score: number }): void {
    this.registry.set('finalScore', data.score);
  }

  create(): void {
    const { width, height } = this.scale;
    const score = this.registry.get('finalScore') as number;

    this.add.rectangle(width / 2, height / 2, width, height, 0x000000, 0.7);
    this.add.text(width / 2, height * 0.35, 'GAME OVER', {
      fontSize: '56px', color: '#ff4444',
    }).setOrigin(0.5);
    this.add.text(width / 2, height * 0.5, `Score: ${score}`, {
      fontSize: '32px', color: '#ffffff',
    }).setOrigin(0.5);

    this.add.text(width / 2, height * 0.65, 'Play Again', {
      fontSize: '28px', color: '#00ff88',
    }).setOrigin(0.5).setInteractive({ useHandCursor: true })
      .on('pointerdown', () => this.scene.start('GameScene', { level: 1 }));
  }
}
```

### HUDScene (Parallel Overlay)

Runs simultaneously with GameScene via `this.scene.launch('HUDScene')`. Ideal for health bars, score, minimap.

```typescript
// In GameScene.create():
this.scene.launch('HUDScene');
// Pass events to HUD
this.events.on('scoreChanged', (score: number) => {/* HUD listens */});

// HUDScene.ts:
export class HUDScene extends Phaser.Scene {
  private scoreText!: Phaser.GameObjects.Text;

  constructor() { super({ key: 'HUDScene' }); }

  create(): void {
    this.scoreText = this.add.text(16, 16, 'Score: 0', {
      fontSize: '20px', color: '#ffffff',
    }).setScrollFactor(0);  // Fixed to camera

    const gameScene = this.scene.get('GameScene');
    gameScene.events.on('scoreChanged', (score: number) => {
      this.scoreText.setText(`Score: ${score}`);
    }, this);

    // Clean up when GameScene stops
    gameScene.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      gameScene.events.off('scoreChanged');
    }, this);
  }
}
```

### PauseScene (Modal Overlay)

Launched on top of GameScene, which is paused.

```typescript
// In GameScene — pause on Escape:
const esc = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.ESC);
esc.on('down', () => {
  this.scene.pause('GameScene');
  this.scene.launch('PauseScene');
});

// PauseScene.ts:
export class PauseScene extends Phaser.Scene {
  constructor() { super({ key: 'PauseScene' }); }

  create(): void {
    const { width, height } = this.scale;
    this.add.rectangle(width / 2, height / 2, width, height, 0x000000, 0.5);
    this.add.text(width / 2, height / 2 - 50, 'PAUSED', {
      fontSize: '48px', color: '#ffffff',
    }).setOrigin(0.5);

    this.add.text(width / 2, height / 2 + 40, 'Resume', {
      fontSize: '28px', color: '#00ff88',
    }).setOrigin(0.5).setInteractive({ useHandCursor: true })
      .on('pointerdown', () => {
        this.scene.resume('GameScene');
        this.scene.stop('PauseScene');
      });
  }
}
```

## Scene Transitions

```typescript
// Basic transition
this.scene.start('TargetScene');

// With data
this.scene.start('GameScene', { level: 2, score: 1500 });

// With fade
this.cameras.main.fadeOut(500, 0, 0, 0, () => {
  this.scene.start('NextScene');
});

// Parallel launch (both scenes run simultaneously)
this.scene.launch('HUDScene');

// Pause/resume
this.scene.pause('GameScene');
this.scene.resume('GameScene');

// Stop a scene entirely
this.scene.stop('HUDScene');

// Restart current scene
this.scene.restart();
this.scene.restart({ level: 1, score: 0 }); // with fresh data
```

## Cross-Scene Communication

```typescript
// 1. Registry (simple key-value, fires events on change)
this.registry.set('score', 0);
this.registry.get('score');
this.registry.events.on('changedata-score', (parent, value) => {});

// 2. Scene events (strongly typed messaging)
// Emitter scene:
this.events.emit('enemyKilled', { points: 100, x: enemy.x, y: enemy.y });
// Listener scene:
this.scene.get('GameScene').events.on('enemyKilled', (data: {points: number}) => {});

// 3. Direct scene reference (use sparingly — creates tight coupling)
const gameScene = this.scene.get('GameScene') as GameScene;
gameScene.addScore(100);
```

## Additional Resources

### Reference Files
- **`references/scene-patterns.md`** — Detailed patterns for every scene type, advanced transitions, scene manager patterns

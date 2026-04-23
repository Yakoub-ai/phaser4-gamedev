---
name: phaser-ui
description: This skill should be used when the user asks to "add health bar", "create menu", "UI elements", "dialog box", "inventory system", "create buttons", "HUD overlay", "score display", "minimap", "progress bar", "bitmap text", "interactive button", or "UI layout".
version: 0.4.0
---

# Phaser 4 UI Development

Phaser has no built-in UI toolkit. Build UI from game objects — Text, Graphics, Image, Container — or use a parallel HUDScene. The two fundamental approaches:

1. **Scroll-fixed objects**: Add game objects to the scene, call `.setScrollFactor(0)` so they stay fixed when the camera moves.
2. **Parallel HUDScene**: Launch a separate scene alongside the game scene. That scene's camera never moves, so everything in it is inherently fixed. Use this for complex UIs.

Always call `.setDepth(100)` (or higher) on UI elements so they render above game objects.

---

## Health Bar (Graphics-based)

```typescript
class HealthBar {
  private bar: Phaser.GameObjects.Graphics;
  private x: number;
  private y: number;
  private width = 200;
  private height = 20;
  private maxHealth: number;
  private health: number;

  constructor(scene: Phaser.Scene, x: number, y: number, maxHealth: number) {
    this.x = x;
    this.y = y;
    this.maxHealth = this.health = maxHealth;
    this.bar = scene.add.graphics().setScrollFactor(0).setDepth(100);
    this.draw();
  }

  setHealth(value: number): void {
    this.health = Phaser.Math.Clamp(value, 0, this.maxHealth);
    this.draw();
  }

  private draw(): void {
    this.bar.clear();
    // Background border
    this.bar.fillStyle(0x000000, 0.6);
    this.bar.fillRect(this.x - 2, this.y - 2, this.width + 4, this.height + 4);
    // Colored fill — green above 50%, yellow above 25%, red below
    const ratio = this.health / this.maxHealth;
    const color = ratio > 0.5 ? 0x00ff00 : ratio > 0.25 ? 0xffff00 : 0xff0000;
    this.bar.fillStyle(color, 1);
    this.bar.fillRect(this.x, this.y, this.width * ratio, this.height);
  }

  destroy(): void {
    this.bar.destroy();
  }
}
```

Use `setHealth(newValue)` every time the player takes damage or heals.

---

## Score and Text Display

```typescript
// In create():
this.scoreText = this.add.text(16, 16, 'Score: 0', {
  fontSize: '24px',
  color: '#ffffff',
  stroke: '#000000',
  strokeThickness: 3,
}).setScrollFactor(0).setDepth(100);

// When score changes:
this.scoreText.setText(`Score: ${score}`);
```

Position all HUD text relative to `this.scale.width` / `this.scale.height` for responsive layouts (see Responsive UI below).

---

## Interactive Buttons

### Method 1 — Text as button

```typescript
const btn = this.add.text(400, 300, 'PLAY', {
  fontSize: '32px',
  backgroundColor: '#4a4a8a',
  padding: { x: 20, y: 10 },
})
  .setOrigin(0.5)
  .setInteractive({ useHandCursor: true })
  .on('pointerover', () => btn.setStyle({ color: '#ffff00' }))
  .on('pointerout',  () => btn.setStyle({ color: '#ffffff' }))
  .on('pointerdown', () => btn.setScale(0.95))
  .on('pointerup',   () => {
    btn.setScale(1);
    this.scene.start('GameScene');
  });
```

### Method 2 — Image button with texture frame states

```typescript
const playBtn = this.add.image(400, 300, 'ui', 'btn-play-normal.png')
  .setInteractive({ useHandCursor: true });

playBtn.on('pointerover', () => playBtn.setFrame('btn-play-hover.png'));
playBtn.on('pointerout',  () => playBtn.setFrame('btn-play-normal.png'));
playBtn.on('pointerdown', () => playBtn.setFrame('btn-play-pressed.png'));
playBtn.on('pointerup',   () => {
  playBtn.setFrame('btn-play-normal.png');
  this.scene.start('GameScene');
});
```

---

## Dialog Box

```typescript
class DialogBox extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, text: string, onClose: () => void) {
    super(scene, scene.scale.width / 2, scene.scale.height / 2);
    scene.add.existing(this);
    this.setDepth(200).setScrollFactor(0);

    const bg = scene.add.graphics();
    bg.fillStyle(0x222244, 0.95);
    bg.fillRoundedRect(-200, -80, 400, 160, 16);

    const label = scene.add.text(0, -30, text, {
      fontSize: '20px',
      color: '#ffffff',
      wordWrap: { width: 360 },
      align: 'center',
    }).setOrigin(0.5);

    const closeBtn = scene.add.text(0, 50, 'OK', {
      fontSize: '20px',
      backgroundColor: '#4488aa',
      padding: { x: 20, y: 8 },
    })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerup', () => {
        this.destroy();
        onClose();
      });

    this.add([bg, label, closeBtn]);
  }
}

// Usage:
new DialogBox(this, 'You found a treasure chest!', () => {
  // Resume game logic after dialog closes
});
```

Animate the appearance by tweening scale from 0 to 1 — see `references/ui-patterns.md` for the animated version.

---

## Minimap (Graphics-based dot map)

A camera-based minimap requires WebGL and render textures. For most games, a dot-map on a `Graphics` object is simpler and works in both Canvas and WebGL:

```typescript
class MiniMap {
  private gfx: Phaser.GameObjects.Graphics;
  private mapX = 10;
  private mapY = 10;
  private mapW = 150;
  private mapH = 100;
  private worldW: number;
  private worldH: number;

  constructor(scene: Phaser.Scene, worldW: number, worldH: number) {
    this.worldW = worldW;
    this.worldH = worldH;
    this.gfx = scene.add.graphics().setScrollFactor(0).setDepth(100);
  }

  update(entities: Array<{ x: number; y: number; color: number }>): void {
    this.gfx.clear();
    // Background
    this.gfx.fillStyle(0x000000, 0.5);
    this.gfx.fillRect(this.mapX, this.mapY, this.mapW, this.mapH);
    // Border
    this.gfx.lineStyle(2, 0xffffff, 0.8);
    this.gfx.strokeRect(this.mapX, this.mapY, this.mapW, this.mapH);
    // Entities as colored dots
    for (const e of entities) {
      const mx = this.mapX + (e.x / this.worldW) * this.mapW;
      const my = this.mapY + (e.y / this.worldH) * this.mapH;
      this.gfx.fillStyle(e.color, 1);
      this.gfx.fillCircle(mx, my, 2);
    }
  }

  destroy(): void {
    this.gfx.destroy();
  }
}

// In GameScene.update():
this.miniMap.update([
  { x: this.player.x, y: this.player.y, color: 0x00ff00 },
  ...this.enemies.getChildren().map(e => ({ x: (e as Enemy).x, y: (e as Enemy).y, color: 0xff0000 })),
]);
```

---

## Generic Progress Bar

Reuse for health, XP, loading progress, stamina — any ratio metric:

```typescript
interface ProgressBarConfig {
  x: number;
  y: number;
  width?: number;
  height?: number;
  fillColor?: number;
  bgColor?: number;
  depth?: number;
}

class ProgressBar {
  private bar: Phaser.GameObjects.Graphics;
  private cfg: Required<ProgressBarConfig>;

  constructor(scene: Phaser.Scene, config: ProgressBarConfig) {
    this.cfg = {
      width: 200, height: 16,
      fillColor: 0x00aaff,
      bgColor: 0x333333,
      depth: 100,
      ...config,
    };
    this.bar = scene.add.graphics().setScrollFactor(0).setDepth(this.cfg.depth);
    this.setValue(1);
  }

  setValue(ratio: number): void {
    const { x, y, width, height, fillColor, bgColor } = this.cfg;
    const clamped = Phaser.Math.Clamp(ratio, 0, 1);
    this.bar.clear();
    this.bar.fillStyle(bgColor, 0.8);
    this.bar.fillRect(x, y, width, height);
    this.bar.fillStyle(fillColor, 1);
    this.bar.fillRect(x, y, width * clamped, height);
  }

  destroy(): void {
    this.bar.destroy();
  }
}

// Examples:
const xpBar   = new ProgressBar(scene, { x: 16, y: 50, fillColor: 0xaa00ff });
const loadBar = new ProgressBar(scene, { x: 160, y: 300, width: 320, height: 24, fillColor: 0x00ff88 });
xpBar.setValue(0.65);    // 65% XP
loadBar.setValue(value); // from load.on('progress', ...)
```

---

## BitmapText for Performance

`Phaser.GameObjects.Text` redraws to canvas every `setText` call. `BitmapText` swaps UV coordinates on a texture atlas — much cheaper for values that update every frame (score, frame counter, damage numbers).

```typescript
// Preload the font (in PreloaderScene):
this.load.bitmapFont('arcade', 'assets/fonts/arcade.png', 'assets/fonts/arcade.xml');

// Create:
const scoreText = this.add.bitmapText(16, 16, 'arcade', 'Score: 0', 32)
  .setScrollFactor(0)
  .setDepth(100);

// Update every frame with zero canvas overhead:
scoreText.setText(`Score: ${this.score}`);
```

Use `BitmapText` for: scores, timers, floating damage numbers, combo counters. Use `Text` for: long paragraphs, dialog text, anything using system fonts or custom CSS styles.

---

## DOM Overlay with `this.add.dom()`

For settings forms or chat inputs where native HTML inputs are needed:

```typescript
// Preload (PreloaderScene or scene preload):
this.load.html('settings-form', 'assets/html/settings.html');

// In create():
const domEl = this.add.dom(400, 300).createFromCache('settings-form');
domEl.addListener('click');
domEl.on('click', (event: Event) => {
  const target = event.target as HTMLElement;
  if (target.id === 'submit-btn') {
    const input = domEl.getChildByName('username') as HTMLInputElement;
    console.log('Username:', input.value);
    domEl.destroy();
  }
});
```

Enable DOM in game config:

```typescript
const config: Phaser.Types.Core.GameConfig = {
  // ...
  dom: { createContainer: true },
};
```

Caveat: DOM elements have z-index complications on mobile and in some browsers. Prefer Phaser game objects for all UI that doesn't need native input elements.

---

## Responsive UI with Scale Manager

> For the full canvas-plus-HUD two-layer responsive sizing rule (including the `100dvh` + live-camera pattern that avoids the iOS PWA landscape bug and the module-level `GAME_WIDTH` constant freeze), see `skills/phaser-scene/references/scene-patterns.md` → **Responsive Sizing: Two Layers**. Do not duplicate that content — it's the canonical explanation.

Never hardcode pixel positions for HUD elements. Use `this.scale.width` / `this.scale.height` and listen for resize:

```typescript
create(): void {
  const { width, height } = this.scale;

  this.scoreText = this.add.text(width * 0.02, height * 0.02, 'Score: 0', {
    fontSize: `${Math.round(height * 0.04)}px`,
    color: '#ffffff',
  }).setScrollFactor(0).setDepth(100);

  // Re-anchor on resize (e.g. when browser window resizes)
  this.scale.on('resize', (gameSize: Phaser.Structs.Size) => {
    this.scoreText.setPosition(gameSize.width * 0.02, gameSize.height * 0.02);
  });
}
```

---

## HUD as Parallel Scene (recommended for complex UIs)

For anything beyond a score text and health bar, move all UI into a dedicated `HUDScene`. Benefits: clean separation, no scroll-factor juggling, easier to pause/resume the game scene without affecting UI.

```typescript
// In GameScene.create():
this.scene.launch('HUDScene');

// Communicate via events:
this.events.emit('healthChanged', this.player.health);
this.events.emit('scoreChanged', this.score);
```

```typescript
export class HUDScene extends Phaser.Scene {
  private healthBar!: HealthBar;
  private scoreText!: Phaser.GameObjects.Text;

  constructor() { super({ key: 'HUDScene' }); }

  create(): void {
    this.healthBar = new HealthBar(this, 16, 16, 100);
    this.scoreText = this.add.text(16, 50, 'Score: 0', {
      fontSize: '20px', color: '#ffffff',
    }).setDepth(100);

    const game = this.scene.get('GameScene');
    game.events.on('healthChanged', (hp: number) => this.healthBar.setHealth(hp), this);
    game.events.on('scoreChanged',  (s: number)  => this.scoreText.setText(`Score: ${s}`), this);

    // Clean up listeners when GameScene shuts down
    game.events.once(Phaser.Scenes.Events.SHUTDOWN, () => {
      game.events.off('healthChanged');
      game.events.off('scoreChanged');
    }, this);
  }
}
```

See `phaser-scene` skill for the full HUDScene launch pattern and scene communication options.

---

## Additional Resources

### Reference Files
- **`references/ui-patterns.md`** — Production-ready component classes: animated HealthBar, Button class, animated DialogBox, FloatingText, Panel, InventoryGrid
- **`references/hit-test-and-depth.md`** — Phaser `topOnly` hit-test semantics, invisible-zone depth patterns, drag-overlay click-swallow diagnostic checklist. Read when buttons or interactive children silently stop responding.
- **`references/panel-rebuild-patterns.md`** — In-place content rebuild for panels (tab switches, purchases) without flicker, first-visit typewriter dialogue skip pattern, chrome-preserving `container.list.slice(base)` idiom. Read when panels flash closed and reopen on content change.

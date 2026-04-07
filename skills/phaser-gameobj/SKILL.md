---
name: phaser-gameobj
description: This skill should be used when the user asks to "add a sprite", "create a player", "add text to game", "create particles", "add a tilemap", "create a group", "add a container", "create game objects", "draw shapes", "add UI elements", "create a camera", "add depth", or needs to add any visual, interactive, or logical element to a Phaser 4 scene.
version: 0.1.0
---

# Phaser 4 Game Objects

Choose the right game object type for each use case. Every object is created with `this.add.*` (visual only) or `this.physics.add.*` (with Arcade Physics body).

## Object Type Reference

### Sprite — Animated, interactive, can have physics

```typescript
// Static display sprite (no physics)
const sprite = this.add.sprite(x, y, 'textureKey');
const sprite = this.add.sprite(x, y, 'atlas', 'frameName.png');  // atlas frame

// Physics sprite (dynamic body, affected by gravity/velocity)
const sprite = this.physics.add.sprite(x, y, 'textureKey');

// Configure physics body
(sprite.body as Phaser.Physics.Arcade.Body)
  .setSize(24, 32)           // hitbox size (smaller than visual for player)
  .setOffset(4, 8)           // offset from sprite origin
  .setMaxVelocity(300, 600); // cap velocity

// Common sprite settings
sprite.setOrigin(0.5, 0.5);  // pivot point (default: 0.5, 0.5 = center)
sprite.setScale(2);           // scale up
sprite.setAlpha(0.8);         // transparency
sprite.setDepth(10);          // render order (higher = on top)
sprite.setFlipX(true);        // mirror horizontally
sprite.setTint(0xff0000);     // tint red
sprite.clearTint();
```

### Image — Static visual, no animation

```typescript
const img = this.add.image(x, y, 'key');
const img = this.add.image(x, y, 'atlas', 'frame.png');

// Useful for: backgrounds, UI panels, static decorations
// Lighter than Sprite (no animation overhead)
img.setScrollFactor(0);  // Fixed to camera (for UI)
img.setScrollFactor(0.5); // Parallax at half speed
```

### Text — Dynamic text display

```typescript
const text = this.add.text(x, y, 'Score: 0', {
  fontSize: '24px',
  fontFamily: 'Arial, sans-serif',
  color: '#ffffff',
  stroke: '#000000',
  strokeThickness: 4,
  align: 'center',
  backgroundColor: '#333333',
  padding: { x: 8, y: 4 },
  wordWrap: { width: 400, useAdvancedWrap: true },
});

text.setText('Score: 100');  // update text
text.setScrollFactor(0);     // fixed to camera (HUD)
```

**BitmapText** — faster for many text objects (renders as texture):
```typescript
// Must load bitmap font first in preload:
this.load.bitmapFont('arcade', 'assets/fonts/arcade.png', 'assets/fonts/arcade.xml');

const bmpText = this.add.bitmapText(x, y, 'arcade', 'Score: 0', 32);
bmpText.setText('Score: 100');
```

### Graphics — Draw shapes programmatically

```typescript
const gfx = this.add.graphics();

// Filled shapes
gfx.fillStyle(0xff0000, 1.0);          // color, alpha
gfx.fillRect(x, y, width, height);
gfx.fillCircle(x, y, radius);
gfx.fillTriangle(x1,y1, x2,y2, x3,y3);

// Stroked shapes
gfx.lineStyle(2, 0xffffff, 1.0);       // lineWidth, color, alpha
gfx.strokeRect(x, y, width, height);
gfx.strokeCircle(x, y, radius);

// Paths
gfx.beginPath();
gfx.moveTo(x1, y1);
gfx.lineTo(x2, y2);
gfx.closePath();
gfx.strokePath();

gfx.clear();  // erase everything (call each frame if updating)
```

### Container — Group objects for relative positioning

```typescript
// Create a health bar from multiple objects
const healthBar = this.add.container(x, y);
const bg = this.add.graphics().fillStyle(0x333333).fillRect(0, 0, 100, 12);
const bar = this.add.graphics().fillStyle(0x00ff00).fillRect(0, 0, 100, 12);
const label = this.add.text(50, -14, 'HP', { fontSize: '10px' }).setOrigin(0.5);
healthBar.add([bg, bar, label]);

// All children move/rotate/scale with container
healthBar.setPosition(200, 50);
healthBar.setDepth(10);
// Note: Physics does NOT work on containers — physics lives on individual sprites
```

### Group — Manage a collection of objects

```typescript
// Static group (pool of objects created manually)
const stars = this.add.group();
for (let i = 0; i < 20; i++) {
  stars.add(this.add.sprite(
    Phaser.Math.Between(0, 800),
    Phaser.Math.Between(0, 600),
    'star'
  ));
}

// Physics group with automatic pooling
const bullets = this.physics.add.group({
  classType: Bullet,     // custom class extending Arcade.Sprite
  maxSize: 30,
  runChildUpdate: true,  // calls update() on active members
});

// Get a member from the pool
const bullet = bullets.get(x, y) as Bullet;
if (bullet) {
  bullet.setActive(true).setVisible(true);
  bullet.setVelocityY(-400);
}

// Static group (for tilemap-like platforms)
const platforms = this.physics.add.staticGroup();
platforms.create(400, 580, 'platform');
platforms.create(100, 400, 'platform');
```

### Particles — Visual effects

```typescript
// Phaser 4 particles API (same pattern as late v3)
const emitter = this.add.particles(0, 0, 'star', {
  speed: { min: 50, max: 150 },
  scale: { start: 0.5, end: 0 },
  blendMode: 'ADD',
  lifespan: 800,
  quantity: 5,
  frequency: 100,         // emit every 100ms
  maxParticles: 50,       // cap total particles (performance!)
  gravityY: 200,
  rotate: { min: 0, max: 360 },
});

// Follow a sprite
emitter.setPosition(player.x, player.y);

// One-shot explosion burst
this.add.particles(x, y, 'spark', {
  speed: { min: 100, max: 300 },
  lifespan: 600,
  quantity: 20,
  maxParticles: 20,
  scale: { start: 1, end: 0 },
  blendMode: 'ADD',
});
```

### TileSprite — Scrolling/repeating texture

```typescript
const bg = this.add.tileSprite(0, 0, 800, 600, 'bg-tiles');
bg.setOrigin(0, 0);

// Scroll in update():
bg.tilePositionX += 1;  // scroll right
bg.tilePositionY -= 0.5;

// NOTE: TileSprite does NOT support texture cropping in Phaser 4 (removed from v3)
```

## Depth and Camera

```typescript
// Depth (z-order)
background.setDepth(0);
ground.setDepth(1);
player.setDepth(2);
hud.setDepth(10);         // HUD elements always on top

// setScrollFactor controls parallax / HUD behavior
uiElement.setScrollFactor(0);    // Fixed to camera (HUD)
farBg.setScrollFactor(0.2);      // Slow parallax
nearBg.setScrollFactor(0.7);     // Fast parallax
gameObject.setScrollFactor(1);   // Default: moves with world
```

## Common Patterns

### Interactive Object (Clickable)

```typescript
const button = this.add.sprite(x, y, 'button-up');
button.setInteractive({ useHandCursor: true });  // pointer cursor on hover
button.on('pointerover', () => button.setTexture('button-hover'));
button.on('pointerout', () => button.setTexture('button-up'));
button.on('pointerdown', () => button.setTexture('button-down'));
button.on('pointerup', () => {
  button.setTexture('button-up');
  this.onButtonClick();
});
```

### Animated Sprite with State Machine

```typescript
// In update() — simple state-based animation
const body = this.player.body as Phaser.Physics.Arcade.Body;
const isGrounded = body.blocked.down;
const isMoving = Math.abs(body.velocity.x) > 10;

if (!isGrounded) {
  this.player.play('player-jump', true);
} else if (isMoving) {
  this.player.play('player-walk', true);
} else {
  this.player.play('player-idle', true);
}
```

### Floating Damage Numbers

```typescript
private showDamage(x: number, y: number, amount: number): void {
  const text = this.add.text(x, y, `-${amount}`, {
    fontSize: '20px',
    color: '#ff4444',
    stroke: '#000',
    strokeThickness: 3,
  }).setOrigin(0.5).setDepth(100);

  this.tweens.add({
    targets: text,
    y: y - 60,
    alpha: 0,
    duration: 900,
    ease: 'Quad.Out',
    onComplete: () => text.destroy(),
  });
}
```

## Phaser 4 Notes

- **`Geom.Point` is removed** — use `Phaser.Math.Vector2` for 2D coordinates
- **`Math.PI2` is removed** — use `Math.TAU` (π×2) or `Math.PI_OVER_2` (π/2)
- **`TileSprite` no longer supports texture cropping** — use a RenderTexture if needed
- **`DynamicTexture`/`RenderTexture`** — must call `.render()` after drawing operations

## Additional Resources

### Reference Files
- **`references/game-objects-api.md`** — Complete API quick reference for every object type, advanced usage, and performance tips

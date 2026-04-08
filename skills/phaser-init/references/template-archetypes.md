# Template Archetypes

Complete game archetype specifications for the phaser-coder agent. Each archetype defines scene graph, physics config, game objects, asset manifests, and file structure to generate a fully working game with placeholder assets.

---

## Platformer Archetype

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene + HUDScene (parallel)
                                                  ↓ (game over)
                                             GameOverScene → MainMenuScene
```

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 600 }, debug: false }
```

### Scene Responsibilities

- **BootScene:** Load loading bar image only, transition to PreloaderScene
- **PreloaderScene:** Load all assets, create all animations, go to MainMenuScene
- **MainMenuScene:** Title text, PLAY button, hi-score display
- **GameScene:** World creation, player + enemies + platforms + coins
- **HUDScene (parallel):** Health bar, score display, lives count
- **GameOverScene:** Shows final score, RESTART and MENU buttons

### Game Objects

#### Player (extends Phaser.Physics.Arcade.Sprite)

- **States:** idle, walking, jumping, falling, dead
- **Controls:** left/right (cursor keys or WASD), jump (Up/W/Space), can only jump when `body.blocked.down`
- **Variable jump height:** Store `jumpStart` time, limit to 400ms of upward velocity
- **Coyote time:** 150ms grace period after leaving a ledge
- **Animations:**
  - `player-idle`: frames 0–3, 8fps
  - `player-walk`: frames 4–11, 12fps
  - `player-jump`: frame 12, 1fps
  - `player-fall`: frame 13, 1fps
- **Properties:** `health=3`, `speed=200`, `jumpPower=480`
- **Events emitted:** `'damaged'`, `'died'`, `'scoreChanged'`

#### Platform (StaticGroup)

- Ground: 800×32
- Floating platforms: various sizes

#### Enemy (extends Phaser.Physics.Arcade.Sprite)

- **Patrol AI:** Moves left/right at 80px/s, reverses on wall collision or world edge
- **Stomp detection:** Player jumping on top kills enemy (check `player.body.velocity.y > 0`)
- **Side/below contact:** Damages player

#### Coin (StaticGroup)

- Spin animation
- Overlap with player gives score +10

#### Collectibles

- Star: +100 points
- Extra life item

### Collision Matrix

| Object A | Object B | Type | Effect |
|----------|----------|------|--------|
| player | platforms | collider | physics stop |
| enemies | platforms | collider | physics stop |
| player | enemies | overlap | stomp from above = kill enemy; side/below = damage player |
| player | coins | overlap | collect coin, +10 score |

### Input

Arrow keys + WASD + Space for jump.

### Asset Manifest (Placeholder Generation)

Generate all textures in `PreloaderScene.create()` before scene transition, using `Graphics.generateTexture()`:

```typescript
const gfx = this.add.graphics();

// Player placeholder (blue 32x48)
gfx.fillStyle(0x4488ff);
gfx.fillRect(0, 0, 32, 48);
gfx.generateTexture('player', 32, 48);
gfx.clear();

// Enemy placeholder (red 32x32)
gfx.fillStyle(0xff4444);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('enemy', 32, 32);
gfx.clear();

// Platform placeholder (brown 200x32)
gfx.fillStyle(0x886644);
gfx.fillRect(0, 0, 200, 32);
gfx.generateTexture('platform', 200, 32);
gfx.clear();

// Coin placeholder (yellow circle 20x20)
gfx.fillStyle(0xffdd00);
gfx.fillCircle(10, 10, 10);
gfx.generateTexture('coin', 20, 20);
gfx.clear();

gfx.destroy();
```

### State Management

`this.registry` stores `{ score, lives, level }`.

### File Structure

```
src/
├── main.ts
├── scenes/
│   ├── BootScene.ts
│   ├── PreloaderScene.ts
│   ├── MainMenuScene.ts
│   ├── GameScene.ts
│   ├── HUDScene.ts
│   └── GameOverScene.ts
└── objects/
    ├── Player.ts
    ├── Enemy.ts
    └── Coin.ts
```

---

## Top-Down RPG Archetype

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 0 }, debug: false }
```

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene
```

### Game Objects

#### Player (extends Phaser.Physics.Arcade.Sprite)

- **Movement:** 8-directional with cursor keys or WASD
- **Diagonal normalization:** Multiply velocity by 0.707 (1/√2) when moving diagonally to prevent faster diagonal movement
- **Speed:** 160px/s
- **Animations:** 4 directions × 3 frames each: `walk-down`, `walk-up`, `walk-left`, `walk-right`
- **Placeholder:** Colored rectangle with direction indicator

#### NPC

- Static sprite with interaction zone (overlap circle)
- Press E to interact
- Triggers `DialogBox` overlay

#### WorldObjects

- Trees, rocks as static physics bodies for collision

### Tilemap

Three-layer structure:
- **Ground layer:** Grass tiles, no collision
- **Walls layer:** Stone tiles, `setCollisionByProperty({ collides: true })`
- **Objects layer:** `PlayerSpawn` point, NPC positions, exit/entry points

### Camera

Follows player with world bounds set from tilemap dimensions.

### Asset Manifest (Placeholder Generation)

```typescript
// Placeholder tileset: 8 colored 16×16 tiles in a 128×16 sheet
// Player: 3×4 grid of 16×24 frames (12 animation frames total)
const gfx = this.add.graphics();

// Ground tile (green)
gfx.fillStyle(0x44aa44);
gfx.fillRect(0, 0, 16, 16);
gfx.generateTexture('ground-tile', 16, 16);
gfx.clear();

// Wall tile (grey)
gfx.fillStyle(0x888888);
gfx.fillRect(0, 0, 16, 16);
gfx.generateTexture('wall-tile', 16, 16);
gfx.clear();

// Player placeholder (blue 16x24)
gfx.fillStyle(0x4488ff);
gfx.fillRect(0, 0, 16, 24);
gfx.generateTexture('player', 16, 24);
gfx.clear();

// NPC placeholder (orange 16x24)
gfx.fillStyle(0xff8800);
gfx.fillRect(0, 0, 16, 24);
gfx.generateTexture('npc', 16, 24);
gfx.clear();

gfx.destroy();
```

### File Structure

```
src/
├── main.ts
├── scenes/
│   ├── BootScene.ts
│   ├── PreloaderScene.ts
│   ├── MainMenuScene.ts
│   └── GameScene.ts
└── objects/
    ├── Player.ts
    ├── NPC.ts
    └── DialogBox.ts
```

---

## Space Shooter Archetype

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 0 }, debug: false }
```

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene + HUDScene → GameOverScene
```

### Game Objects

#### Player Ship

- **Movement:** Mouse/pointer to aim, WASD to strafe, or arrow keys for 4-directional movement
- **Shooting:** Auto-fire or Space to shoot
- **Bounds:** `setCollideWorldBounds(true)`

#### Background

```typescript
this.add.tileSprite(0, 0, w, h, 'stars').setOrigin(0, 0);
// In update():
background.tilePositionY -= 2;
```

#### Bullets (Object Pool)

- `Bullet` class, `maxSize: 30`
- Fire rate: 250ms cooldown

#### Enemies

- Spawned from `time.addEvent` every 2s from top of screen
- Move downward at fixed speed

#### Enemy Waves

- Speed and spawn rate increase as score increases

#### Power-ups

- Triple shot
- Shield
- Speed boost
- Random drop on enemy death

#### Explosions

- Particle emitter triggered on destroy

### Score and Difficulty Scaling

Score increases per enemy killed. Difficulty scales at milestones: 100, 250, 500...

### Asset Manifest (Placeholder Generation)

```typescript
const gfx = this.add.graphics();

// Player ship: white triangle shape (32x48)
gfx.fillStyle(0xffffff);
gfx.fillTriangle(16, 0, 0, 48, 32, 48);
gfx.generateTexture('player-ship', 32, 48);
gfx.clear();

// Enemy: red inverted triangle (32x32)
gfx.fillStyle(0xff4444);
gfx.fillTriangle(16, 32, 0, 0, 32, 0);
gfx.generateTexture('enemy-ship', 32, 32);
gfx.clear();

// Bullet: yellow rectangle (4x12)
gfx.fillStyle(0xffff00);
gfx.fillRect(0, 0, 4, 12);
gfx.generateTexture('bullet', 4, 12);
gfx.clear();

// Stars background: random white dots on black (800x600)
gfx.fillStyle(0x000000);
gfx.fillRect(0, 0, 800, 600);
gfx.fillStyle(0xffffff);
for (let i = 0; i < 200; i++) {
  gfx.fillRect(
    Math.floor(Math.random() * 800),
    Math.floor(Math.random() * 600),
    1, 1
  );
}
gfx.generateTexture('stars', 800, 600);
gfx.clear();

gfx.destroy();
```

### File Structure

```
src/
├── main.ts
├── scenes/
│   ├── BootScene.ts
│   ├── PreloaderScene.ts
│   ├── MainMenuScene.ts
│   ├── GameScene.ts
│   ├── HUDScene.ts
│   └── GameOverScene.ts
└── objects/
    ├── PlayerShip.ts
    ├── EnemyShip.ts
    ├── Bullet.ts
    └── PowerUp.ts
```

---

## Match-3 Puzzle Archetype

### Physics Config

None needed (or `arcade: { gravity: { x: 0, y: 0 } }`).

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene → GameOverScene
```

### Core Logic

- **Grid:** 8×8 board of tile sprites, 7 tile types (different colors)
- **Swap:** Click tile, click adjacent tile to swap (visual tween swap)
- **Match detection:** Check horizontal (3+ in a row) and vertical (3+ in column) after each swap
- **No match:** Swap back (tween back to original positions)
- **Match found:** Remove matched tiles (fade out), drop tiles above, fill from top with new random tiles
- **Cascade:** After fill, check for new matches, repeat until board is stable

### Scoring

| Match Length | Points |
|-------------|--------|
| 3 tiles | 30 pts |
| 4 tiles | 100 pts |
| 5 tiles | 250 pts |

### Key Implementation Note

All grid logic lives in pure functions (not scene methods) for testability. The scene only handles rendering and input delegation.

### Asset Manifest (Placeholder Generation)

```typescript
const colors = [0xff4444, 0x4488ff, 0x44cc44, 0xffdd00, 0xaa44ff, 0xff8800, 0xffffff];
const names = ['tile-red', 'tile-blue', 'tile-green', 'tile-yellow', 'tile-purple', 'tile-orange', 'tile-white'];
const gfx = this.add.graphics();

colors.forEach((color, i) => {
  gfx.fillStyle(color);
  gfx.fillRoundedRect(2, 2, 60, 60, 8); // 64x64 with 2px padding and rounded corners
  gfx.generateTexture(names[i], 64, 64);
  gfx.clear();
});

gfx.destroy();
```

### File Structure

```
src/
├── main.ts
├── scenes/
│   ├── BootScene.ts
│   ├── PreloaderScene.ts
│   ├── MainMenuScene.ts
│   ├── GameScene.ts
│   └── GameOverScene.ts
└── logic/
    ├── grid.ts         // pure functions: createGrid, findMatches, dropTiles, fillGrid
    ├── scorer.ts       // pure functions: calculateScore, applyCombo
    └── types.ts        // TileType, GridCell, MatchResult interfaces
```

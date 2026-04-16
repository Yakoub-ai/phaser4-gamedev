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

---

## Tower Defense Archetype

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → LevelSelectScene → GameScene + HUDScene (parallel)
                                                                      ↓ (lives = 0)
                                                                 GameOverScene → LevelSelectScene
```

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 0 }, debug: false }
```

### Scene Responsibilities

- **BootScene:** Load loading bar image only, transition to PreloaderScene
- **PreloaderScene:** Load all assets, generate placeholder textures, go to MainMenuScene
- **MainMenuScene:** Title text, PLAY button, hi-score display
- **LevelSelectScene:** Level grid with star ratings, locked/unlocked states
- **GameScene:** Grid-based map, tower placement, enemy wave spawning, projectile management
- **HUDScene (parallel):** Currency display, lives counter, wave number, tower selection panel
- **GameOverScene:** Shows waves survived, final score, RETRY and MENU buttons

### Game Objects

#### Tower (extends Phaser.GameObjects.Sprite)

- **Placed on grid cells** via pointer click. Cannot place on path tiles or occupied cells.
- **Types:**
  - Arrow Tower: range=150, damage=5, fireRate=500ms, cost=25. Fast, single-target.
  - Cannon Tower: range=120, damage=20, fireRate=1500ms, cost=50. Slow, splash damage (hits enemies within 40px of target).
  - Ice Tower: range=130, damage=2, fireRate=800ms, cost=40. Slows enemy speed by 50% for 2 seconds.
- **Targeting:** Fires at nearest enemy within range. Spawns a Projectile from pool.
- **Upgrade:** Click existing tower to upgrade (1.5x damage, 1.2x range, costs 50% of base).

#### Enemy (extends Phaser.Physics.Arcade.Sprite)

- **Follows waypoint path:** Array of `{x, y}` points. Uses `Phaser.Math.MoveTowards()` to travel between waypoints.
- **Types:**
  - Fast: health=30, speed=120, reward=10. Low HP, high speed.
  - Tank: health=150, speed=50, reward=25. High HP, slow.
  - Swarm: health=10, speed=100, reward=5. Spawns in groups of 5.
- **On death:** Grant reward currency, increment score.
- **On reaching path end:** Lose 1 life, destroy enemy.

#### Projectile (object pooled)

- Fired by towers toward enemy position. Moves at 400px/s.
- Destroyed on impact with target or when off-screen.
- Pool: `maxSize: 50`, `classType: Projectile`, `runChildUpdate: true`.

#### WaveManager

- Spawns enemy waves with increasing difficulty.
- Wave N: enemy count = `5 + N * 2`, speed scales by `1 + N * 0.1`.
- 5-second delay between waves. Auto-start or manual start button.
- Wave composition: waves 1-3 Fast only, 4-6 mix Fast+Tank, 7+ all types including Swarm.

#### Grid

- 2D array (`boolean[][]`) tracking valid tower placement cells.
- Path cells marked as blocked. Tower-occupied cells marked as blocked.
- Visual: grid overlay shows valid cells on hover.

### Collision Matrix

| Object A | Object B | Type | Effect |
|----------|----------|------|--------|
| projectile | enemies | overlap | damage enemy, destroy projectile (splash for Cannon) |
| enemies | path end | position check | lose 1 life, destroy enemy |

### Input

Pointer click on grid cell to place selected tower. Tower selection buttons in HUD. Click existing tower to upgrade.

### Asset Manifest (Placeholder Generation)

```typescript
const gfx = this.add.graphics();

// Arrow tower (green square 32x32)
gfx.fillStyle(0x44cc44);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tower-arrow', 32, 32);
gfx.clear();

// Cannon tower (red square 32x32)
gfx.fillStyle(0xff4444);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tower-cannon', 32, 32);
gfx.clear();

// Ice tower (blue square 32x32)
gfx.fillStyle(0x44aaff);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tower-ice', 32, 32);
gfx.clear();

// Fast enemy (orange circle 20x20)
gfx.fillStyle(0xff8800);
gfx.fillCircle(10, 10, 10);
gfx.generateTexture('enemy-fast', 20, 20);
gfx.clear();

// Tank enemy (dark red circle 28x28)
gfx.fillStyle(0xaa2222);
gfx.fillCircle(14, 14, 14);
gfx.generateTexture('enemy-tank', 28, 28);
gfx.clear();

// Swarm enemy (yellow circle 12x12)
gfx.fillStyle(0xffdd00);
gfx.fillCircle(6, 6, 6);
gfx.generateTexture('enemy-swarm', 12, 12);
gfx.clear();

// Projectile (white rect 4x4)
gfx.fillStyle(0xffffff);
gfx.fillRect(0, 0, 4, 4);
gfx.generateTexture('projectile', 4, 4);
gfx.clear();

// Path tile (sandy 32x32)
gfx.fillStyle(0xccaa66);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tile-path', 32, 32);
gfx.clear();

// Grass tile (green 32x32)
gfx.fillStyle(0x44aa44);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tile-grass', 32, 32);
gfx.clear();

gfx.destroy();
```

### State Management

`this.registry` stores `{ currency: 100, lives: 20, wave: 0, score: 0 }`.

### File Structure

```
src/
├── main.ts
├── scenes/
│   ├── BootScene.ts
│   ├── PreloaderScene.ts
│   ├── MainMenuScene.ts
│   ├── LevelSelectScene.ts
│   ├── GameScene.ts
│   ├── HUDScene.ts
│   └── GameOverScene.ts
└── objects/
    ├── Tower.ts
    ├── Enemy.ts
    ├── Projectile.ts
    ├── WaveManager.ts
    └── Grid.ts
```

---

## Endless Runner Archetype

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene + HUDScene (parallel)
                                                  ↓ (hit obstacle)
                                             GameOverScene → MainMenuScene
```

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 600 }, debug: false }
```

### Scene Responsibilities

- **BootScene:** Load loading bar image only, transition to PreloaderScene
- **PreloaderScene:** Load all assets, generate placeholder textures, go to MainMenuScene
- **MainMenuScene:** Title text, PLAY button, hi-score display
- **GameScene:** Scrolling ground, player, obstacles, collectibles, parallax background
- **HUDScene (parallel):** Score display, hi-score display
- **GameOverScene:** Shows final score, hi-score, RETRY and MENU buttons

### Game Objects

#### Player (extends Phaser.Physics.Arcade.Sprite)

- **Auto-runs:** Player stays at x=100, world scrolls past. Player does NOT move horizontally.
- **States:** running, jumping, sliding, dead
- **Jump:** Tap/Up/Space key, only when `body.blocked.down`. Sets velocityY = -480.
- **Double jump:** One mid-air jump allowed. Track `jumpsRemaining` (resets to 2 on land).
- **Slide:** Swipe down/Down key. Shrinks hitbox from 32x48 to 32x24 for 500ms. Cannot jump while sliding.
- **Properties:** `speed=200` (initial scroll speed), `jumpsRemaining=2`

#### Ground (TileSprite)

- Full-width TileSprite at bottom of screen (800x32).
- In `update()`: `this.tilePositionX += speed * (delta / 1000)`.
- Gap obstacles are holes in the ground (kill zone below).

#### ObstacleSpawner

- Spawns obstacles from right edge using `this.time.addEvent()`.
- **Types:**
  - Crate (32x32): Jump over. Sits on ground.
  - Barrier (48x24): Slide under. Floats at head height.
  - Gap: 64px hole in ground. Must jump over.
- Spawn interval: starts at 2000ms, decreases by 50ms every 500 score points (min 800ms).
- Object-pooled group with `maxSize: 10`.

#### Collectible (object pooled)

- Coins spawned between obstacles at random heights.
- Overlap with player: +10 score, coin tween (scale pulse + fade).
- Pool: `maxSize: 20`.

#### Background (2 TileSprites)

- Back layer: sky/mountains, `tilePositionX += speed * 0.3 * (delta / 1000)`
- Front layer: trees/buildings, `tilePositionX += speed * 0.7 * (delta / 1000)`
- Creates parallax depth effect.

### Collision Matrix

| Object A | Object B | Type | Effect |
|----------|----------|------|--------|
| player | ground | collider | physics stop, reset jumpsRemaining |
| player | obstacles | overlap | game over (trigger dead state) |
| player | collectibles | overlap | collect, +10 score |

### Input

Up/Space/Tap to jump (also double-jump mid-air). Down/Swipe-down to slide. That's it — intentionally simple.

### Scoring

Score = `Math.floor(distanceTraveled / 10) + collectibleScore`. Distance increments by `speed * delta` each frame. Speed increases by 10 every 500 score points (cap at 2x initial speed).

### Asset Manifest (Placeholder Generation)

```typescript
const gfx = this.add.graphics();

// Player (green 32x48)
gfx.fillStyle(0x44cc44);
gfx.fillRect(0, 0, 32, 48);
gfx.generateTexture('player', 32, 48);
gfx.clear();

// Ground (brown 800x32)
gfx.fillStyle(0x886644);
gfx.fillRect(0, 0, 800, 32);
gfx.generateTexture('ground', 800, 32);
gfx.clear();

// Crate obstacle (red 32x32)
gfx.fillStyle(0xff4444);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('obstacle-crate', 32, 32);
gfx.clear();

// Barrier obstacle (orange 48x24)
gfx.fillStyle(0xff8800);
gfx.fillRect(0, 0, 48, 24);
gfx.generateTexture('obstacle-barrier', 48, 24);
gfx.clear();

// Coin (yellow circle 16x16)
gfx.fillStyle(0xffdd00);
gfx.fillCircle(8, 8, 8);
gfx.generateTexture('coin', 16, 16);
gfx.clear();

// Background back layer (dark blue sky 800x600)
gfx.fillStyle(0x1a1a3e);
gfx.fillRect(0, 0, 800, 600);
gfx.fillStyle(0x2a2a5e);
gfx.fillRect(0, 400, 800, 200);
gfx.generateTexture('bg-back', 800, 600);
gfx.clear();

// Background front layer (darker silhouettes 800x300)
gfx.fillStyle(0x112211);
gfx.fillRect(0, 0, 800, 300);
gfx.generateTexture('bg-front', 800, 300);
gfx.clear();

gfx.destroy();
```

### State Management

`this.registry` stores `{ score: 0, hiScore: 0, distance: 0 }`.

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
    ├── ObstacleSpawner.ts
    └── Collectible.ts
```

---

## Card Game Archetype (Memory Match)

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene → GameOverScene → MainMenuScene
```

### Physics Config

None needed (or `arcade: { gravity: { x: 0, y: 0 } }` — physics not used).

### Scene Responsibilities

- **BootScene:** Load loading bar image only, transition to PreloaderScene
- **PreloaderScene:** Generate placeholder card textures, go to MainMenuScene
- **MainMenuScene:** Title text, PLAY button, hi-score (fewest moves)
- **GameScene:** 4x4 card grid, flip interaction, match detection, scoring
- **GameOverScene:** Shows moves taken, time, star rating, PLAY AGAIN and MENU buttons

### Game Objects

#### Card (extends Phaser.GameObjects.Container)

- **Contains:** card back image, card face image, value text label
- **Properties:** `suit` (color index 0-7), `faceUp` (boolean), `matched` (boolean)
- **flip() method:** Tween `scaleX` from 1 → 0 (150ms), swap visible face/back at midpoint, then 0 → 1 (150ms). Plays flip SFX.
- **moveTo(x, y) method:** Tween position over 300ms with `Quad.Out` easing.
- **setInteractive()** on the container for click detection.

#### Deck

- Plain class. Creates 16 Card objects (8 pairs).
- **shuffle():** Fisher-Yates shuffle on the card array.
- **deal():** Arrange cards in 4x4 grid with 80px spacing, face-down. Stagger deal animation (50ms delay per card).

#### CardZone (Phaser.GameObjects.Zone)

- Optional drop target for drag-and-drop card game variants.
- **accepts(card):** Validation function for whether a card can be placed.

### Core Logic (Memory Match)

- 4x4 grid = 16 cards = 8 pairs, each pair shares a color/suit.
- **Turn flow:**
  1. Click first card → flip face-up
  2. Click second card → flip face-up
  3. If match (same suit) → both stay face-up, score +100, matched=true
  4. If no match → wait 1 second, flip both back face-down
  5. Increment moves counter after each pair attempt
- **Win condition:** All 8 pairs matched. Transition to GameOverScene.
- **Star rating:** 1 star (≤24 moves), 2 stars (≤18 moves), 3 stars (≤14 moves)

### Input

Pointer click on face-down cards. Ignore clicks on face-up or matched cards. Ignore clicks during flip animation (lock input for 300ms during flip).

### Asset Manifest (Placeholder Generation)

```typescript
const colors = [0xff4444, 0x4488ff, 0x44cc44, 0xffdd00, 0xaa44ff, 0xff8800, 0xff44aa, 0x44ffaa];
const names = ['card-0', 'card-1', 'card-2', 'card-3', 'card-4', 'card-5', 'card-6', 'card-7'];
const gfx = this.add.graphics();

// Card faces (colored rounded rects 64x80)
colors.forEach((color, i) => {
  gfx.fillStyle(0xffffff);
  gfx.fillRoundedRect(0, 0, 64, 80, 8);
  gfx.fillStyle(color);
  gfx.fillRoundedRect(8, 8, 48, 64, 4);
  gfx.generateTexture(names[i], 64, 80);
  gfx.clear();
});

// Card back (dark blue 64x80)
gfx.fillStyle(0x223366);
gfx.fillRoundedRect(0, 0, 64, 80, 8);
gfx.fillStyle(0x334488);
gfx.fillRoundedRect(8, 8, 48, 64, 4);
gfx.generateTexture('card-back', 64, 80);
gfx.clear();

gfx.destroy();
```

### State Management

`this.registry` stores `{ moves: 0, matchesFound: 0, totalPairs: 8, bestMoves: Infinity }`.

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
└── objects/
│   ├── Card.ts
│   ├── Deck.ts
│   └── CardZone.ts
└── logic/
    └── match-logic.ts    // pure functions: checkMatch, calculateStars, shuffleArray
```

---

## Fighting Game Archetype

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → CharacterSelectScene → GameScene + HUDScene (parallel)
                                                                          ↓ (round over)
                                                                     VictoryScene → MainMenuScene
```

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 800 }, debug: false }
```

### Scene Responsibilities

- **BootScene:** Load loading bar image only, transition to PreloaderScene
- **PreloaderScene:** Load all assets, create all animations, go to MainMenuScene
- **MainMenuScene:** Title text, VS FIGHT banner, PLAY button
- **CharacterSelectScene:** Fighter selection (P1 left side, P2 right side), READY button
- **GameScene:** Arena floor, two fighters, hitbox spawning, round logic
- **HUDScene (parallel):** Health bars for P1 and P2, round indicators, countdown timer
- **VictoryScene:** Shows winner text, round results, REMATCH and MENU buttons

### Game Objects

#### Fighter (extends Phaser.Physics.Arcade.Sprite)

- **States:** idle, walk, jump, attack, block, hurt, ko (state machine pattern)
- **Controls P1:** A/D move left/right, W jump, F punch, G kick. Block: hold direction away from opponent while grounded.
- **Controls P2:** Left/Right arrow move, Up arrow jump, L punch, K kick. Block: hold direction away from opponent while grounded.
- **Properties:** `health=100`, `attackDamage=10`, `speed=200`, `jumpPower=500`
- **Attack mechanic:** On punch/kick press, transition to attack state and spawn a temporary Hitbox zone offset in the facing direction. Hitbox is destroyed after 200ms.
- **Hurt state:** On receiving damage, flash red, brief knockback, 300ms invulnerability window.
- **KO state:** When health reaches 0, play KO animation (fall flat), emit `'ko'` event.
- **Events emitted:** `'attacked'`, `'damaged'`, `'ko'`

#### Hitbox (Phaser.GameObjects.Zone)

- Spawned during attack, positioned relative to fighter facing direction (offset +40px in front)
- Size: 24x48 overlap zone
- Destroyed automatically after 200ms via `this.scene.time.delayedCall(200, () => hitbox.destroy())`
- Tagged with owner reference to prevent self-hits

#### HealthBar (Phaser.GameObjects.Graphics)

- Per-fighter, drawn at top of screen
- P1: left-aligned (x=20), P2: right-aligned (x=width-220)
- Width 200px, height 20px
- Draws background (dark grey), then fill proportional to current health (P1 green, P2 red)
- Updates every frame via `update(currentHealth, maxHealth)` method

#### RoundManager

- Best of 3 rounds. Tracks `p1Wins`, `p2Wins`, `currentRound`.
- Round ends when either fighter's health reaches 0.
- 3-second countdown between rounds (large centered text: "3", "2", "1", "FIGHT!").
- Match ends when a player reaches 2 wins. Transitions to VictoryScene with winner data.

### Collision Matrix

| Object A | Object B | Type | Effect |
|----------|----------|------|--------|
| fighters | ground | collider | physics stop |
| p1-hitbox | p2 | overlap | apply damage to P2, trigger hurt state |
| p2-hitbox | p1 | overlap | apply damage to P1, trigger hurt state |
| p1 | p2 | collider | push apart, prevent overlap |

### Input

P1: A/D move, W jump, F punch, G kick. P2: Left/Right move, Up jump, L punch, K kick. Block: hold back direction (away from opponent) while grounded.

### Asset Manifest (Placeholder Generation)

Generate all textures in `PreloaderScene.create()` before scene transition, using `Graphics.generateTexture()`:

```typescript
const gfx = this.add.graphics();

// P1 Fighter placeholder (blue 32x64)
gfx.fillStyle(0x4488ff);
gfx.fillRect(0, 0, 32, 64);
gfx.generateTexture('fighter-p1', 32, 64);
gfx.clear();

// P2 Fighter placeholder (red 32x64)
gfx.fillStyle(0xff4444);
gfx.fillRect(0, 0, 32, 64);
gfx.generateTexture('fighter-p2', 32, 64);
gfx.clear();

// Hitbox placeholder (small red rect 24x48, semi-transparent)
gfx.fillStyle(0xff0000, 0.5);
gfx.fillRect(0, 0, 24, 48);
gfx.generateTexture('hitbox', 24, 48);
gfx.clear();

// Ground / arena floor (brown 800x32)
gfx.fillStyle(0x886644);
gfx.fillRect(0, 0, 800, 32);
gfx.generateTexture('ground', 800, 32);
gfx.clear();

// Arena background (dark purple gradient-like)
gfx.fillStyle(0x221133);
gfx.fillRect(0, 0, 800, 600);
gfx.fillStyle(0x331144);
gfx.fillRect(0, 400, 800, 200);
gfx.generateTexture('arena-bg', 800, 600);
gfx.clear();

gfx.destroy();
```

### State Management

`this.registry` stores `{ p1Wins: 0, p2Wins: 0, currentRound: 1 }`.

### File Structure

```
src/
├── main.ts
├── scenes/
│   ├── BootScene.ts
│   ├── PreloaderScene.ts
│   ├── MainMenuScene.ts
│   ├── CharacterSelectScene.ts
│   ├── GameScene.ts
│   ├── HUDScene.ts
│   └── VictoryScene.ts
└── objects/
    ├── Fighter.ts
    ├── Hitbox.ts
    ├── HealthBar.ts
    └── RoundManager.ts
```

---

## Racing Game Archetype

### Scene Graph

```
BootScene → PreloaderScene → MainMenuScene → GameScene + HUDScene (parallel)
                                                  ↓ (race finished)
                                             ResultsScene → MainMenuScene
```

### Physics Config

```typescript
arcade: { gravity: { x: 0, y: 0 }, debug: false }
```

### Scene Responsibilities

- **BootScene:** Load loading bar image only, transition to PreloaderScene
- **PreloaderScene:** Load all assets, generate placeholder textures, go to MainMenuScene
- **MainMenuScene:** Title text, track preview, START RACE button
- **GameScene:** Top-down track, player car, AI opponents, checkpoints, lap tracking
- **HUDScene (parallel):** Current lap, best lap time, position (1st/2nd/3rd), speedometer
- **ResultsScene:** Final standings, lap times, RACE AGAIN and MENU buttons

### Game Objects

#### Car (extends Phaser.Physics.Arcade.Sprite)

- **Movement:** Top-down, rotation-based steering. Car rotates and accelerates in the direction it faces.
- **Properties:** `maxSpeed=300`, `acceleration=200`, `turnRate=3` (radians/s), `drag=0.98`
- **Physics:** Movement uses `this.scene.physics.velocityFromRotation(this.rotation, currentSpeed, this.body.velocity)`. Each frame, speed is multiplied by `drag` when not accelerating.
- **Wall collision:** On collide with wall, speed is reduced by 50% and car bounces.

#### Track (Tilemap)

- Tile-based tilemap with three layers:
  - **Road layer:** Driveable surface (grey tiles), no collision
  - **Walls layer:** Barriers and boundaries (dark tiles), `setCollisionByExclusion([-1])`
  - **Decorations layer:** Grass, trees, curbs (visual only)

#### Checkpoint (Phaser.GameObjects.Zone array)

- Array of invisible rectangular zones placed around the track at key positions
- Must be hit in sequential order (checkpoint 0, then 1, then 2, etc.)
- Hitting all checkpoints in order completes one lap
- Prevents shortcut cheating by requiring ordered completion

#### LapCounter

- Tracks checkpoints per car
- **Properties:** `currentLap=0`, `totalLaps=3`, `checkpointsHit=[]`, `lapTimes=[]`
- Records `this.scene.time.now` at each lap completion for lap time tracking
- Emits `'lapComplete'` and `'raceFinished'` events

#### AIOpponent (extends Car)

- Follows a waypoint array (Phaser.Math.Vector2[]) with random offset (+-20px) for natural pathing
- Steers toward current waypoint, advances to next when within 40px
- Speed capped slightly below player max (`maxSpeed=270`)
- Rubber-banding: if too far behind leader, speed temporarily increases to 290

### Collision Matrix

| Object A | Object B | Type | Effect |
|----------|----------|------|--------|
| cars | walls | collider | bounce, reduce speed by 50% |
| player | checkpoints | overlap | register checkpoint hit, check lap completion |
| cars | cars | collider | push apart, both reduce speed |

### Input

Up/W accelerate, Down/S brake/reverse, Left/Right or A/D rotate car. Touch: left third of screen = steer left, right third = steer right, bottom center = brake, tap upper half = accelerate.

### Scoring

Lap time tracking per lap. Best lap time displayed on HUD. Final results show position (1st/2nd/3rd), total race time, and best lap time.

### Asset Manifest (Placeholder Generation)

Generate all textures in `PreloaderScene.create()` before scene transition, using `Graphics.generateTexture()`:

```typescript
const gfx = this.add.graphics();

// Player car placeholder (blue 16x24, with nose indicator)
gfx.fillStyle(0x4488ff);
gfx.fillRect(0, 0, 16, 24);
gfx.fillStyle(0xaaccff);
gfx.fillRect(4, 0, 8, 6);
gfx.generateTexture('car-player', 16, 24);
gfx.clear();

// AI car 1 placeholder (red 16x24)
gfx.fillStyle(0xff4444);
gfx.fillRect(0, 0, 16, 24);
gfx.fillStyle(0xffaaaa);
gfx.fillRect(4, 0, 8, 6);
gfx.generateTexture('car-ai1', 16, 24);
gfx.clear();

// AI car 2 placeholder (green 16x24)
gfx.fillStyle(0x44cc44);
gfx.fillRect(0, 0, 16, 24);
gfx.fillStyle(0xaaffaa);
gfx.fillRect(4, 0, 8, 6);
gfx.generateTexture('car-ai2', 16, 24);
gfx.clear();

// Road tile (grey 32x32)
gfx.fillStyle(0x666666);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tile-road', 32, 32);
gfx.clear();

// Wall tile (dark grey 32x32)
gfx.fillStyle(0x333333);
gfx.fillRect(0, 0, 32, 32);
gfx.lineStyle(1, 0x555555);
gfx.strokeRect(0, 0, 32, 32);
gfx.generateTexture('tile-wall', 32, 32);
gfx.clear();

// Grass tile (green 32x32)
gfx.fillStyle(0x44aa44);
gfx.fillRect(0, 0, 32, 32);
gfx.generateTexture('tile-grass', 32, 32);
gfx.clear();

// Checkpoint marker (yellow triangle 32x32)
gfx.fillStyle(0xffdd00);
gfx.fillTriangle(16, 0, 0, 32, 32, 32);
gfx.generateTexture('checkpoint', 32, 32);
gfx.clear();

gfx.destroy();
```

### State Management

`this.registry` stores `{ playerPosition: 1, currentLap: 0, totalLaps: 3, bestLapTime: 0, raceTime: 0 }`.

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
│   └── ResultsScene.ts
└── objects/
    ├── Car.ts
    ├── AIOpponent.ts
    ├── LapCounter.ts
    └── Checkpoint.ts
```

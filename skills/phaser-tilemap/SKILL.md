---
name: phaser-tilemap
description: This skill should be used when the user asks to "add tilemap", "create a level", "Tiled editor", "tile collision", "object layer", "create map", "tilemap not showing", "level design", "tile layer", "game map", "spawn point", "trigger zone", or "map collision".
version: 0.2.0
---

# Phaser 4 Tilemaps

Phaser 4 has first-class support for Tiled map files (JSON format). The recommended workflow is: design in Tiled → export JSON → load in Phaser → create layers → set up collision.

## Tiled Editor Workflow

Download Tiled for free at [mapeditor.org](https://www.mapeditor.org/).

### Creating a New Map

1. File → New → New Map
2. Set **Orientation** to Orthogonal (most 2D games) or Isometric (top-down RPG/strategy)
3. Set **Tile layer format** to CSV or Base64 — both work with Phaser
4. Set **Tile size** to match your tileset (common: 16x16, 32x32)
5. Set **Map size** in tiles (e.g. 40 wide × 23 tall for a 1280x736 map at 32px tiles)

### Adding a Tileset

1. In the Tilesets panel (bottom right), click the **+** button → New Tileset
2. Set **Name** — this exact name is used in `map.addTilesetImage()` as the first argument
3. Set **Type** to Based on Tileset Image
4. Browse to your PNG, set tile width/height to match
5. Margin and spacing: set these if your tileset has padding between tiles (often 0)

### Marking Collision Tiles

1. Select your tileset in the Tilesets panel
2. Click the wrench icon (**Edit Tileset**) to open the tileset editor
3. Select the tiles that should collide (click to select, Ctrl+click for multiple)
4. In the Properties panel (left side), click the **+** button to add a property
5. Set **Name** to `collides`, **Type** to `bool`, **Value** to `true`
6. Close the tileset editor

In Phaser, call `layer.setCollisionByProperty({ collides: true })` to activate these tiles.

### Layer Naming Conventions

Use consistent layer names — Phaser references them by string:

| Layer Name | Type | Purpose |
|---|---|---|
| `Background` | Tile Layer | Sky, distant scenery — no collision |
| `Ground` | Tile Layer | Main walkable surface — collision enabled |
| `Hazards` | Tile Layer | Spikes, lava — overlap (not collide) |
| `Foreground` | Tile Layer | Trees, arches that render in front of player |
| `Objects` | Object Layer | Spawn points, triggers, enemies |

### Object Layer Usage

Object Layers in Tiled let you place named points, rectangles, and polygons that Phaser can query.

**Named objects** (for unique things like player spawn):
1. Add Object Layer named `Objects`
2. Select the Rectangle tool, place an object on the map
3. In Properties, set **Name** to `PlayerSpawn`

**Typed objects** (for groups of the same kind, like enemies):
1. Place objects and set **Type** (Tiled 1.8: use **Class**) to `Enemy`
2. Add custom properties: click **+**, add `health` (int, 100), `patrol` (bool, true)

### Export Settings

1. File → Export As → JSON Map Files (`.json`)
2. In export options, enable **Embed tilesets** — this avoids external `.tsx` dependencies
3. Save to `public/assets/tilemaps/level1.json`
4. Place the tileset PNG at `public/assets/images/terrain.png`

---

## Loading Assets

```typescript
preload(): void {
  // Key must match first arg of map.addTilesetImage()
  this.load.tilemapTiledJSON('level1', 'assets/tilemaps/level1.json');

  // Key must match second arg of map.addTilesetImage()
  this.load.image('terrain', 'assets/images/terrain.png');
}
```

---

## Creating the Map and Layers

```typescript
private map!: Phaser.Tilemaps.Tilemap;
private groundLayer!: Phaser.Tilemaps.TilemapLayer;

create(): void {
  this.map = this.make.tilemap({ key: 'level1' });

  // First arg: tileset name as set in Tiled (must match exactly, case-sensitive)
  // Second arg: the this.load.image() key
  const tileset = this.map.addTilesetImage('terrain', 'terrain');

  // Decorative background — no collision
  const bgLayer = this.map.createLayer('Background', tileset!, 0, 0);

  // Main ground layer — collision enabled below
  this.groundLayer = this.map.createLayer('Ground', tileset!, 0, 0)!;

  // Foreground renders above the player
  const fgLayer = this.map.createLayer('Foreground', tileset!, 0, 0);
  fgLayer!.setDepth(10);  // player depth should be 1–9
}
```

**Common reason tilemap does not show:** the tileset name in `addTilesetImage` does not exactly match the name set in Tiled. Open the JSON file and check the `"name"` field inside `"tilesets"`.

---

## Collision

### By Property (recommended)

Uses the `collides: true` property set in Tiled's tileset editor:

```typescript
this.groundLayer.setCollisionByProperty({ collides: true });
this.physics.add.collider(this.player, this.groundLayer);
```

### By Tile Index Range

Collide tiles with GID (global ID) 1 through 10:

```typescript
this.groundLayer.setCollisionBetween(1, 10);
```

### By Exclusion

Collide all tiles except empty (-1) and a specific index:

```typescript
this.groundLayer.setCollisionByExclusion([-1, 0]);
```

### Debug Rendering

Visualize collision tiles during development:

```typescript
const debugGraphics = this.add.graphics();
this.groundLayer.renderDebug(debugGraphics, {
  tileColor: null,                                       // non-colliding tiles
  collidingTileColor: new Phaser.Display.Color(243, 134, 48, 128),  // orange
  faceColor: new Phaser.Display.Color(40, 39, 37, 255), // face outlines
});
```

---

## Multiple Layers

```typescript
create(): void {
  const tileset = this.map.addTilesetImage('terrain', 'terrain')!;

  const bgLayer    = this.map.createLayer('Background', tileset, 0, 0);  // depth 0 (default)
  const groundLayer = this.map.createLayer('Ground', tileset, 0, 0)!;    // depth 0 (default)
  const fgLayer    = this.map.createLayer('Foreground', tileset, 0, 0);

  fgLayer!.setDepth(10);          // renders above player

  groundLayer.setCollisionByProperty({ collides: true });

  // Player and enemies should have depth between 1 and 9
  this.player.setDepth(5);
}
```

---

## Object Layers

Read spawn points, triggers, and entity placements from Tiled's Object Layer:

```typescript
create(): void {
  // Find a single named object — returns the first match
  const spawnPoint = this.map.findObject('Objects', obj => obj.name === 'PlayerSpawn');
  this.player = this.physics.add.sprite(spawnPoint!.x!, spawnPoint!.y!, 'player');

  // Get all objects of a given type (Tiled "Class" field in 1.8+)
  const enemyObjects = this.map.filterObjects('Objects', obj => obj.type === 'Enemy');
  enemyObjects?.forEach(obj => {
    // Access custom properties as an array: obj.properties
    const props = this.parseProperties(obj.properties);
    this.spawnEnemy(obj.x!, obj.y!, props.health ?? 100);
  });

  // Find trigger zones (rectangles placed in Tiled)
  const triggers = this.map.filterObjects('Objects', obj => obj.type === 'Trigger');
  triggers?.forEach(obj => {
    const zone = this.add.zone(obj.x! + obj.width! / 2, obj.y! + obj.height! / 2, obj.width!, obj.height!);
    this.physics.world.enable(zone);
    this.physics.add.overlap(this.player, zone, () => {
      console.log(`Entered trigger: ${obj.name}`);
    });
  });
}

// Helper: convert Tiled properties array to plain object
private parseProperties(props?: { name: string; value: unknown }[]): Record<string, unknown> {
  if (!props) return {};
  return Object.fromEntries(props.map(p => [p.name, p.value]));
}
```

---

## Camera and World Bounds

Always set world bounds to the map size so the player cannot walk out of the map:

```typescript
create(): void {
  // Constrain physics bodies
  this.physics.world.setBounds(0, 0, this.map.widthInPixels, this.map.heightInPixels);

  // Constrain camera
  this.cameras.main.setBounds(0, 0, this.map.widthInPixels, this.map.heightInPixels);

  // Follow the player
  this.cameras.main.startFollow(this.player, true, 0.1, 0.1);  // lerp x/y = 0.1 for smooth follow
}
```

---

## Dynamic Tile Manipulation

Modify tiles at runtime (destructible terrain, switches, etc.):

```typescript
// Read a tile at a world position
const tile = this.groundLayer.getTileAtWorldXY(ptr.worldX, ptr.worldY);
if (tile) {
  console.log(`Tile index: ${tile.index}`);
}

// Place a tile at a world position
this.groundLayer.putTileAtWorldXY(5, ptr.worldX, ptr.worldY);

// Remove a tile (sets index to -1 / empty)
this.groundLayer.removeTileAtWorldXY(ptr.worldX, ptr.worldY);

// Convert between world and tile coordinates
const tileXY = this.groundLayer.worldToTileXY(worldX, worldY)!;
const worldXY = this.groundLayer.tileToWorldXY(tileXY.x, tileXY.y)!;
```

---

## Parallax Layers

Scroll a layer at a different speed than the camera to create depth:

```typescript
create(): void {
  const cloudLayer = this.map.createLayer('Clouds', tileset!, 0, 0);
  cloudLayer!.setScrollFactor(0.2);  // moves at 20% camera speed (furthest back)

  const hillLayer = this.map.createLayer('Hills', tileset!, 0, 0);
  hillLayer!.setScrollFactor(0.5);   // moves at 50% camera speed

  // Ground layer
  const groundLayer = this.map.createLayer('Ground', tileset!, 0, 0);
  groundLayer!.setScrollFactor(1);   // moves at 100% (default)
}
```

---

## Multiple Tilesets

A single layer can use tiles from multiple tilesets:

```typescript
create(): void {
  const tiles1 = this.map.addTilesetImage('tileset-a', 'tiles-a');
  const tiles2 = this.map.addTilesetImage('tileset-b', 'tiles-b');

  // Pass an array of tilesets — Phaser resolves tile GIDs automatically
  const layer = this.map.createLayer('Ground', [tiles1!, tiles2!], 0, 0);
}
```

---

## Additional Resources

### Reference Files
- **`references/tilemap-api.md`** — Complete API reference for Tilemap, TilemapLayer, Tileset, and MapData
- **`references/tiled-workflow.md`** — Detailed step-by-step Tiled Editor setup guide with common mistakes

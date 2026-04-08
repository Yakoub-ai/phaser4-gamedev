# Tiled Editor Workflow for Phaser 4

Step-by-step guide for creating maps in Tiled and importing them into Phaser 4. Tiled is free and available at mapeditor.org.

---

## Installation and First-Time Setup

1. Download Tiled from mapeditor.org (Windows, macOS, Linux)
2. Open Tiled. On the Welcome screen, optionally purchase a license to support development — the free version has all features needed for Phaser 4

### Recommended Tiled Preferences

Go to Edit → Preferences:
- **Interface**: Enable "Highlight current layer" to avoid editing the wrong layer
- **Interface**: Enable "Show tile collision shapes" while designing collision tiles

---

## Creating a New Map

1. File → New → New Map
2. Configure map settings:
   - **Orientation**: Orthogonal for side-scrollers, platformers, top-down games; Isometric for isometric RPGs/strategy games. Most Phaser 4 games use Orthogonal.
   - **Tile layer format**: CSV is human-readable; Base64 (zlib compressed) is smaller. Both work identically in Phaser 4. Use CSV while learning.
   - **Tile render order**: Right Down is standard. Phaser 4 supports all orders.
   - **Map size**: Fixed. Set tile size (e.g. 32x32) and map dimensions in tiles (e.g. 40 wide, 25 tall for a 1280x800 map). You can resize later under Map → Resize Map.
3. Click OK

---

## Setting Up a Tileset

### Image-Based Tileset (Recommended)

Use this for simplicity. The tileset PNG is self-contained in your Phaser project.

1. In the **Tilesets** panel (bottom right), click the **+** button → New Tileset
2. Set **Name** — this must exactly match the first argument you pass to `map.addTilesetImage()` in Phaser. Typos here cause the map to silently not render.
3. Set **Type** to "Based on Tileset Image"
4. Click **Browse** and select your tileset PNG
5. Set **Tile Width** and **Tile Height** to match the tiles in your PNG (common: 16, 32, or 48)
6. Set **Margin** to the empty border around the edges of the entire image (often 0)
7. Set **Spacing** to the gap between each tile in the image (often 0 or 1)
8. Click OK

The tileset now appears in the Tilesets panel with all tiles visible. Select a tile and paint with it on a Tile Layer.

### External TSX Tileset

TSX files are reusable across multiple maps. They are more complex and require you to bundle the `.tsx` file alongside the JSON — avoid these unless you have many maps sharing the same tileset. Stick with image-based tilesets.

---

## Setting Tile Properties for Collision

1. Open the tileset editor: in the Tilesets panel, click the wrench icon (**Edit Tileset**)
2. Click a tile you want to mark as solid (or Ctrl+click to select multiple)
3. In the **Properties** panel on the left, click the **+** (Add Property) button
4. Set:
   - **Name**: `collides`
   - **Type**: `bool`
   - **Value**: checked (true)
5. Repeat for all collision tiles
6. Close the tileset editor (Ctrl+W or click the X on the tileset editor tab)

In Phaser, activate these: `layer.setCollisionByProperty({ collides: true })`

You can define any property name. `collides` is a convention, not a reserved word.

---

## Layer Naming Conventions

Phaser references layers by the exact string name. Use these conventions for consistency:

### Tile Layers

| Layer Name | Purpose | Collision? |
|---|---|---|
| `Background` | Far background (sky, clouds, ocean) | No |
| `Ground` | Main walkable/solid surface | Yes |
| `Hazards` | Spikes, lava, water | Overlap only |
| `Platforms` | One-way platforms | Conditional collider |
| `Foreground` | Decor that renders in front of player | No |
| `Decorations` | Details rendered behind the player | No |

### Object Layers

| Layer Name | Purpose |
|---|---|
| `Objects` | Mixed objects: spawns, triggers, items |
| `Spawns` | Spawn points only (if you prefer separation) |
| `Triggers` | Zone/trigger rectangles |
| `Enemies` | Enemy placement |
| `Items` | Collectibles, pickups |

Layer order in Tiled's Layers panel determines render order — layers at the top of the panel render in front. In Phaser you can override this with `layer.setDepth()`.

---

## Painting Tiles

1. Select a Tile Layer in the Layers panel (click once to highlight it)
2. Select a tile or group of tiles in the Tilesets panel
3. Use these tools (toolbar or keyboard shortcuts):
   - **Stamp Brush (B)**: Paint individual tiles
   - **Eraser (E)**: Remove tiles
   - **Bucket Fill (F)**: Flood-fill a region
   - **Rectangle Fill (R)**: Fill a rectangular area
   - **Stamp (S)**: Pick up a region from the map and stamp it elsewhere

---

## Object Layer Usage

Object Layers let you place spawn points, triggers, and entity definitions that Phaser reads at runtime without rendering them.

### Adding Objects

1. Create an Object Layer: Layer → New Layer → Object Layer, name it `Objects`
2. Select the Object Layer in the Layers panel
3. Use the **Insert Rectangle** tool (key: R) for zone triggers
4. Use the **Insert Point** tool (key: P) for spawn points
5. Click on the canvas to place the object

### Naming an Object

1. Select the object with the selection tool (key: S)
2. In the Properties panel, set **Name** (e.g. `PlayerSpawn`)
3. In Phaser: `map.findObject('Objects', obj => obj.name === 'PlayerSpawn')`

### Setting an Object Type (Class)

Tiled 1.8 and newer uses "Class" instead of "Type" in the UI — the JSON field is still named `type` for compatibility.

1. Select an object
2. In Properties, set **Class** (or **Type** in older Tiled) to `Enemy`, `Coin`, `Checkpoint`, etc.
3. In Phaser: `map.filterObjects('Objects', obj => obj.type === 'Enemy')`

### Adding Custom Properties to Objects

1. Select an object
2. In Properties, click **+** to add a property
3. Common examples:
   - `health` (int): starting HP for an enemy
   - `patrol` (bool): whether an enemy walks back and forth
   - `speed` (float): movement speed
   - `message` (string): dialog text for an NPC
4. In Phaser: access via the `properties` array on the object

```typescript
// Convert Tiled's property array to a usable object
const props = Object.fromEntries(
  (obj.properties ?? []).map((p: { name: string; value: unknown }) => [p.name, p.value])
);
const health = props.health as number ?? 100;
```

---

## Exporting the Map

1. File → Export As
2. Select format: **JSON Map Files (*.json)**
3. In the export dialog, check these settings:
   - **Embed tilesets**: ON — this embeds tileset data into the JSON so Phaser does not need a separate `.tsx` file. If you forget this, Phaser may fail to load the tileset.
   - **Resolve object types and properties**: ON — ensures custom properties on objects are included
4. Save to `public/assets/tilemaps/level1.json`
5. Copy your tileset PNG to `public/assets/images/terrain.png`

Re-export after every Tiled edit. The JSON is the source of truth Phaser uses at runtime.

---

## Common Mistakes

### Tilemap shows a blank screen / tiles do not appear

- The name in `map.addTilesetImage('NAME', ...)` does not match the `name` field in the JSON under `tilesets`. Open the JSON, find `"tilesets": [{"name": "..."}]`, and copy that exact string.
- The `this.load.image()` key does not match the second argument of `addTilesetImage`.
- The layer name in `map.createLayer('NAME', ...)` does not match the Tiled layer name. Open the JSON and check `"layers": [{"name": "..."}]`.

### Collision tiles are not blocking the player

- Did not call `setCollisionByProperty({ collides: true })` (or another collision method) on the layer.
- The `collides` property was not saved — open the tileset editor again and check.
- Did not call `this.physics.add.collider(player, groundLayer)`.
- The layer variable is `null` — `createLayer` returns `null` when the layer name is not found. Add a null check.

### Object layer objects have no position

- For tile objects placed using a tile from a tileset, `obj.y` is the bottom of the tile, not the top. Adjust with `obj.y! - map.tileHeight`.
- For point objects, `obj.width` and `obj.height` are 0 — this is correct.

### Map renders at the wrong size

- Tile size mismatch: the PNG tile size does not match what was entered in Tiled's tileset settings. Reopen the tileset in Tiled and correct tile width/height.
- Wrong `tileWidth` / `tileHeight` in `addTilesetImage` override arguments.

### Tilesets export as external files

- In Export settings, "Embed tilesets" was not checked. Re-export with that option enabled.

### Map loads in development but not in production

- The JSON file path is case-sensitive on Linux servers. `Level1.json` and `level1.json` are different files. Use lowercase filenames consistently.
- The tileset PNG path inside the JSON is absolute or machine-specific. Use Tiled's Preferences → open relative tileset paths.

---

## Workflow Checklist for Each Level

1. Design map in Tiled — paint tiles, set collision properties, place objects
2. Export JSON with "Embed tilesets" enabled
3. Place JSON in `public/assets/tilemaps/`
4. Ensure tileset PNG is in `public/assets/images/`
5. In Phaser `preload()`: `load.tilemapTiledJSON` + `load.image`
6. In Phaser `create()`:
   - `make.tilemap`
   - `addTilesetImage` (name must match Tiled exactly)
   - `createLayer` for each layer (name must match Tiled exactly)
   - `setCollisionByProperty` on collision layers
   - `physics.add.collider(player, layer)`
   - `findObject` / `filterObjects` for spawn points and triggers
   - `physics.world.setBounds` + `cameras.main.setBounds` to map size

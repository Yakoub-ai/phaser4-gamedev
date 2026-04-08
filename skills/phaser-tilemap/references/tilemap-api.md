# Phaser 4 Tilemap API Reference

Complete reference for `Phaser.Tilemaps.Tilemap`, `Phaser.Tilemaps.TilemapLayer`, `Phaser.Tilemaps.Tileset`, and `Phaser.Tilemaps.MapData`.

---

## Tilemap (`Phaser.Tilemaps.Tilemap`)

Obtained via `this.make.tilemap({ key: 'mapKey' })`.

### Setup Methods

| Method | Signature | Description |
|---|---|---|
| `addTilesetImage` | `(tilesetName: string, key?: string, tileWidth?: number, tileHeight?: number, tileMargin?: number, tileSpacing?: number, gid?: number): Tileset \| null` | Register a tileset. `tilesetName` must exactly match the name set in Tiled. `key` is the `this.load.image()` key. Returns `null` if the name is not found in the map JSON — check for null before using. |
| `createLayer` | `(layerID: string \| number, tileset: Tileset \| Tileset[], x?: number, y?: number): TilemapLayer \| null` | Create a renderable layer from the map data. `layerID` must match the layer name in Tiled exactly. Returns `null` if the layer name is not found. |
| `createBlankLayer` | `(name: string, tileset: Tileset \| Tileset[], x?, y?, width?, height?, tileWidth?, tileHeight?): TilemapLayer \| null` | Create an empty layer not backed by Tiled data |

### Object Layer Methods

| Method | Signature | Description |
|---|---|---|
| `findObject` | `(objectLayer: string \| ObjectLayer, callback: FindCallback, context?): TiledObject \| null` | Find the first object where `callback` returns truthy |
| `filterObjects` | `(objectLayer: string \| ObjectLayer, callback: FindCallback, context?): TiledObject[] \| null` | Return all objects where `callback` returns truthy |
| `getObjectLayer` | `(name: string): ObjectLayer \| null` | Get an entire object layer by name |

### Tile Query Methods

| Method | Signature | Description |
|---|---|---|
| `getTileAt` | `(tileX, tileY, nonNull?, layer?): Tile \| null` | Get tile at tile coordinates |
| `getTileAtWorldXY` | `(worldX, worldY, nonNull?, camera?, layer?): Tile \| null` | Get tile at world coordinates |
| `findTile` | `(callback, context?, tileX?, tileY?, width?, height?, filteringOptions?, layer?): Tile \| null` | Find first tile matching callback |
| `filterTiles` | `(callback, context?, tileX?, tileY?, width?, height?, filteringOptions?, layer?): Tile[]` | Return all tiles matching callback |
| `hasTileAt` | `(tileX, tileY, layer?): boolean \| null` | Returns `true` if a non-empty tile exists at coordinates |
| `hasTileAtWorldXY` | `(worldX, worldY, camera?, layer?): boolean \| null` | Returns `true` if a non-empty tile exists at world position |

### Tile Modification Methods

| Method | Signature | Description |
|---|---|---|
| `putTileAt` | `(tile: number \| Tile, tileX, tileY, recalcFaces?, layer?): Tile \| null` | Place a tile at tile coordinates |
| `putTileAtWorldXY` | `(tile, worldX, worldY, recalcFaces?, camera?, layer?): Tile \| null` | Place a tile at world coordinates |
| `putTilesAt` | `(tile: number[][] \| string[][], tileX, tileY, recalcFaces?, layer?): Tilemap` | Place a 2D array of tiles |
| `removeTileAt` | `(tileX, tileY, replaceWithNull?, recalcFaces?, layer?): Tile \| null` | Remove tile at tile coordinates (sets to empty) |
| `removeTileAtWorldXY` | `(worldX, worldY, replaceWithNull?, recalcFaces?, camera?, layer?): Tile \| null` | Remove tile at world coordinates |
| `fill` | `(index, tileX?, tileY?, width?, height?, recalcFaces?, layer?): Tilemap` | Fill a region with a tile index |
| `shuffle` | `(tileX?, tileY?, width?, height?, layer?): Tilemap` | Shuffle tiles randomly in a region |
| `swapByIndex` | `(tileA, tileB, tileX?, tileY?, width?, height?, layer?): Tilemap` | Swap all occurrences of index A with index B |
| `copy` | `(srcTileX, srcTileY, width, height, destTileX, destTileY, recalcFaces?, srcLayer?, destLayer?): Tilemap` | Copy a region from one layer to another |
| `randomize` | `(tileX?, tileY?, width?, height?, indexes?, layer?): Tilemap` | Set tiles in a region to random values from an array |
| `replaceByIndex` | `(findIndex, newIndex, tileX?, tileY?, width?, height?, layer?): Tilemap` | Replace all tiles of one index with another |

### Coordinate Conversion Methods

| Method | Signature | Description |
|---|---|---|
| `worldToTileX` | `(worldX, snapToFloor?, camera?, layer?): number \| null` | Convert world X to tile X |
| `worldToTileY` | `(worldY, snapToFloor?, camera?, layer?): number \| null` | Convert world Y to tile Y |
| `worldToTileXY` | `(worldX, worldY, snapToFloor?, point?, camera?, layer?): Vector2 \| null` | Convert world XY to tile XY |
| `tileToWorldX` | `(tileX, camera?, layer?): number \| null` | Convert tile X to world X |
| `tileToWorldY` | `(tileY, camera?, layer?): number \| null` | Convert tile Y to world Y |
| `tileToWorldXY` | `(tileX, tileY, point?, camera?, layer?): Vector2 \| null` | Convert tile XY to world XY |

### Layer Management

| Method | Signature | Description |
|---|---|---|
| `setLayer` | `(layer: string \| number \| TilemapLayer): this` | Set the active layer for methods that accept a layer parameter |
| `getLayer` | `(layer?: string \| number \| TilemapLayer): LayerData \| null` | Get layer data by name or index |
| `getLayerIndex` | `(name: string): number` | Get the index of a layer by name (-1 if not found) |
| `getImageLayerNames` | `(): string[]` | List all image layer names |
| `getLayerNames` | `(): string[]` | List all tile layer names |
| `getObjectLayerNames` | `(): string[]` | List all object layer names |
| `getTilesetNames` | `(): string[]` | List all tileset names in the map |
| `destroyLayer` | `(layer: string \| number \| TilemapLayer): Tilemap` | Destroy and remove a layer |
| `removeLayer` | `(layer: string \| number \| TilemapLayer): Tilemap` | Remove a layer from the map without destroying it |
| `destroy` | `(): void` | Destroy the tilemap and all its layers |

### Tilemap Properties

| Property | Type | Description |
|---|---|---|
| `width` | `number` | Map width in tiles |
| `height` | `number` | Map height in tiles |
| `tileWidth` | `number` | Width of each tile in pixels |
| `tileHeight` | `number` | Height of each tile in pixels |
| `widthInPixels` | `number` | Total map width in pixels (`width * tileWidth`) |
| `heightInPixels` | `number` | Total map height in pixels (`height * tileHeight`) |
| `orientation` | `string` | `'orthogonal'`, `'isometric'`, `'staggered'`, `'hexagonal'` |
| `layers` | `LayerData[]` | All tile layers |
| `objects` | `ObjectLayer[]` | All object layers |
| `tilesets` | `Tileset[]` | All loaded tilesets |
| `currentLayerIndex` | `number` | Active layer index |
| `scene` | `Phaser.Scene` | The owning scene |

---

## TilemapLayer (`Phaser.Tilemaps.TilemapLayer`)

A TilemapLayer is both a renderable GameObject and a collision surface. Extends `Phaser.GameObjects.GameObject`.

### Collision Methods

| Method | Signature | Description |
|---|---|---|
| `setCollision` | `(indexes: number \| number[], collides?: boolean, recalcFaces?: boolean, updateLayer?: boolean): this` | Enable collision on specific tile indices |
| `setCollisionBetween` | `(start: number, stop: number, collides?: boolean, recalcFaces?: boolean): this` | Enable collision for a range of tile indices (inclusive) |
| `setCollisionByExclusion` | `(indexes: number[], collides?: boolean, recalcFaces?: boolean): this` | Enable collision on all tiles except those listed |
| `setCollisionByProperty` | `(properties: object, collides?: boolean, recalcFaces?: boolean): this` | Enable collision on tiles that have matching Tiled properties (e.g. `{ collides: true }`) |
| `setCollisionFromCollisionGroup` | `(collides?: boolean, recalcFaces?: boolean): this` | Use collision shapes from Tiled's per-tile collision objects |
| `setTileIndexCallback` | `(indexes, callback, callbackContext): this` | Run a callback when a physics body overlaps a tile of a given index |
| `setTileLocationCallback` | `(tileX, tileY, width, height, callback, callbackContext): this` | Run a callback when a physics body overlaps a region |
| `removeTileCollision` | `(tileIndex: number): this` | Remove collision from a single tile index |
| `recalculateFaces` | `(tileX, tileY, width, height): this` | Recalculate face flags after manual tile changes |

### Visual / Transform Methods

| Method | Signature | Description |
|---|---|---|
| `setDepth` | `(value: number): this` | Set render order (higher = in front) |
| `setScrollFactor` | `(x: number, y?: number): this` | Set parallax factor (1 = normal, 0 = fixed to camera) |
| `setAlpha` | `(value: number): this` | Set opacity (0–1) |
| `setTint` | `(tint: number): this` | Tint all tiles |
| `clearTint` | `(): this` | Remove tint |
| `setVisible` | `(visible: boolean): this` | Show or hide the layer |
| `setBlendMode` | `(value): this` | Set WebGL blend mode |
| `setRenderOrder` | `(renderOrder: number \| string): this` | Set tile render order within the layer (`right-down`, `right-up`, `left-down`, `left-up`) |
| `setPipeline` | `(pipeline): this` | Set WebGL render pipeline |

### Debug Methods

| Method | Signature | Description |
|---|---|---|
| `renderDebug` | `(graphics: Graphics, styleConfig: object): this` | Draw collision debug outlines onto a Graphics object |
| `renderDebugFull` | `(graphics: Graphics, styleConfig: object): this` | Draw debug outlines for all tiles, including non-colliding |

`renderDebug` style config:

```typescript
{
  tileColor: Phaser.Display.Color | null;         // non-colliding tile fill (null = skip)
  collidingTileColor: Phaser.Display.Color | null; // colliding tile fill
  faceColor: Phaser.Display.Color | null;          // edge lines for colliding faces
}
```

### Tile Query Methods (on layer)

| Method | Signature | Description |
|---|---|---|
| `getTileAt` | `(tileX, tileY, nonNull?): Tile \| null` | Get tile at tile coords |
| `getTileAtWorldXY` | `(worldX, worldY, nonNull?, camera?): Tile \| null` | Get tile at world coords |
| `putTileAt` | `(tile, tileX, tileY, recalcFaces?): Tile` | Place tile at tile coords |
| `putTileAtWorldXY` | `(tile, worldX, worldY, recalcFaces?, camera?): Tile` | Place tile at world coords |
| `removeTileAt` | `(tileX, tileY, replaceWithNull?, recalcFaces?): Tile \| null` | Remove tile at tile coords |
| `removeTileAtWorldXY` | `(worldX, worldY, replaceWithNull?, recalcFaces?, camera?): Tile \| null` | Remove tile at world coords |
| `worldToTileXY` | `(worldX, worldY, snapToFloor?, point?, camera?): Vector2` | Convert world to tile coordinates |
| `tileToWorldXY` | `(tileX, tileY, point?, camera?): Vector2` | Convert tile to world coordinates |

### TilemapLayer Properties

| Property | Type | Description |
|---|---|---|
| `tilemap` | `Tilemap` | Parent tilemap reference |
| `layer` | `LayerData` | The raw layer data |
| `tileset` | `Tileset[]` | Tilesets used by this layer |
| `cullPaddingX` / `cullPaddingY` | `number` | Extra tiles to render outside the camera (default 1) |
| `skipCull` | `boolean` | If `true`, render all tiles regardless of camera (useful for small maps) |
| `x` / `y` | `number` | Layer offset in world space |
| `width` / `height` | `number` | Layer dimensions in pixels |

---

## Tileset (`Phaser.Tilemaps.Tileset`)

Returned by `map.addTilesetImage()`.

| Property | Type | Description |
|---|---|---|
| `name` | `string` | Tileset name (matches Tiled) |
| `firstgid` | `number` | First global tile ID (GID) in this tileset |
| `tileWidth` | `number` | Width of each tile |
| `tileHeight` | `number` | Height of each tile |
| `tileMargin` | `number` | Margin around the entire image |
| `tileSpacing` | `number` | Spacing between tiles |
| `tileData` | `object` | Per-tile property data from Tiled |
| `image` | `Phaser.Textures.Texture` | The loaded texture |
| `total` | `number` | Total number of tiles in the tileset |
| `columns` | `number` | Number of tile columns |
| `rows` | `number` | Number of tile rows |

| Method | Signature | Description |
|---|---|---|
| `getTileData` | `(tileIndex: number): object \| null` | Get the Tiled properties for a tile index |
| `getTileProperties` | `(tileIndex: number): object \| null` | Alias for `getTileData` |
| `containsTileIndex` | `(tileIndex: number): boolean` | Check if the tileset contains a given global tile ID |

---

## Tile (`Phaser.Tilemaps.Tile`)

Individual tile instances returned by query methods.

| Property | Type | Description |
|---|---|---|
| `index` | `number` | Tile index within its tileset (-1 for empty) |
| `x` / `y` | `number` | Tile position in tile coordinates |
| `pixelX` / `pixelY` | `number` | Tile position in world pixels |
| `width` / `height` | `number` | Tile dimensions in pixels |
| `baseWidth` / `baseHeight` | `number` | Untransformed tile dimensions |
| `collides` | `boolean` | True if collision is enabled on this tile |
| `faceTop` / `faceBottom` / `faceLeft` / `faceRight` | `boolean` | Whether each face participates in collision |
| `collideLeft` / `collideRight` / `collideUp` / `collideDown` | `boolean` | Per-face collision flags |
| `properties` | `object` | Custom Tiled properties as a plain object |
| `tileset` | `Tileset \| null` | The tileset this tile belongs to |
| `alpha` | `number` | Per-tile alpha |
| `tint` | `number` | Per-tile tint color |
| `rotation` | `number` | Tile rotation in radians |
| `flipX` / `flipY` | `boolean` | Tile flip flags |
| `visible` | `boolean` | Whether this tile is rendered |
| `layer` | `LayerData` | The layer that owns this tile |

---

## MapData (`Phaser.Tilemaps.MapData`)

The raw parsed data from the Tiled JSON, available as `map.layers`, `map.tilesets`, etc. Most properties are accessed directly on the Tilemap.

| Property | Type | Description |
|---|---|---|
| `name` | `string` | Map name |
| `width` | `number` | Map width in tiles |
| `height` | `number` | Map height in tiles |
| `tileWidth` | `number` | Tile width in pixels |
| `tileHeight` | `number` | Tile height in pixels |
| `widthInPixels` | `number` | `width * tileWidth` |
| `heightInPixels` | `number` | `height * tileHeight` |
| `format` | `number` | Map format constant |
| `orientation` | `string` | Map orientation string |
| `renderOrder` | `string` | Tile render order |
| `version` | `string` | Tiled version string |
| `properties` | `object` | Map-level custom properties from Tiled |
| `layers` | `LayerData[]` | All tile and image layers |
| `objects` | `ObjectLayer[]` | All object layers |
| `tilesets` | `Tileset[]` | All tilesets |
| `infinite` | `boolean` | Whether the map uses Tiled's infinite map format |

---

## TiledObject (Object Layer Entries)

Objects from an Object Layer — returned by `findObject` and `filterObjects`.

| Property | Type | Description |
|---|---|---|
| `id` | `number` | Unique object ID |
| `name` | `string` | Object name set in Tiled |
| `type` | `string` | Object type / class set in Tiled |
| `x` | `number` | Left edge X in pixels |
| `y` | `number` | Top edge Y in pixels (note: for points this is the point; for tiles, it's the bottom) |
| `width` | `number` | Width in pixels (0 for points) |
| `height` | `number` | Height in pixels (0 for points) |
| `rotation` | `number` | Rotation in degrees |
| `visible` | `boolean` | Whether visible in Tiled |
| `properties` | `Array<{name, type, value}>` | Custom property array — convert to object with `Object.fromEntries(props.map(p => [p.name, p.value]))` |
| `gid` | `number \| undefined` | If placing a tile object, its global tile ID |
| `polyline` | `Vector2[] \| undefined` | Points for polyline objects |
| `polygon` | `Vector2[] \| undefined` | Points for polygon objects |
| `ellipse` | `boolean \| undefined` | True if the object is an ellipse |
| `text` | `object \| undefined` | Text content and settings if it is a text object |

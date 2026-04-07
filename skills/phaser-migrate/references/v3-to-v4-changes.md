# Phaser 3 → Phaser 4: Complete Breaking Changes Reference

## Installation Change

```bash
# Phaser 3:
npm install phaser

# Phaser 4:
npm install phaser@beta
```

Phaser 4 package is the same `phaser` package on npm, tagged as `beta`.

---

## Removed Classes and APIs

### 1. Phaser.Geom.Point — REMOVED

Replace all usage with `Phaser.Math.Vector2`.

| v3 | v4 |
|----|----|
| `new Phaser.Geom.Point(x, y)` | `new Phaser.Math.Vector2(x, y)` |
| `Phaser.Geom.Point.GetMagnitude(p)` | `v.length()` |
| `Phaser.Geom.Point.Clone(p)` | `v.clone()` |
| `Phaser.Geom.Point.SetMagnitude(p, n)` | `v.setLength(n)` |
| `Phaser.Geom.Point.Ceil(p)` | `v.ceil()` |
| `Phaser.Geom.Point.Floor(p)` | `v.floor()` |
| `Phaser.Geom.Point.Invert(p)` | `v.invert()` |
| `Phaser.Geom.Point.Negative(p)` | `v.negate()` |
| `Phaser.Geom.Point.Project(p, t, o)` | `v.project(target)` |
| `Phaser.Geom.Point.GetCentroid(arr)` | `Phaser.Math.GetCentroid(arr)` |
| `Phaser.Geom.Point.GetRectangleFromPoints(arr)` | `Phaser.Math.GetVec2Bounds(arr)` |

**Note:** All `Phaser.Geom.*` shape methods that previously returned `Point` now return `Vector2`.

---

### 2. Math Constants Changed

| v3 | v4 | Value |
|----|----|-|
| `Phaser.Math.PI2` | `Phaser.Math.TAU` | π × 2 = 6.283... |
| `Math.PI2` (shorthand) | `Math.TAU` | π × 2 |
| *(new in v4)* | `Phaser.Math.PI_OVER_2` | π / 2 = 1.5707... |

**Important:** In Phaser 3, `Math.PI2` was incorrectly set to just π (3.14...). In Phaser 4, `Math.TAU` is correctly π × 2.

---

### 3. Phaser.Structs — REMOVED

Replace with native JavaScript collections.

| v3 | v4 |
|----|----|
| `new Phaser.Structs.Map([])` | `new Map()` |
| `map.set(key, value)` | `map.set(key, value)` (same) |
| `map.get(key)` | `map.get(key)` (same) |
| `map.delete(key)` | `map.delete(key)` (same) |
| `map.getArray()` | `[...map.values()]` |
| `map.has(key)` | `map.has(key)` (same) |
| `map.size` | `map.size` (same) |
| `map.keys` | `[...map.keys()]` |
| `new Phaser.Structs.Set()` | `new Set()` |
| `set.set(value)` | `set.add(value)` |
| `set.delete(value)` | `set.delete(value)` (same) |
| `set.contains(value)` | `set.has(value)` |
| `set.getArray()` | `[...set.values()]` |

---

### 4. Create Namespace — REMOVED

`Phaser.Create.GenerateTexture` and all Create Palettes are removed entirely. There is no direct replacement.

```typescript
// v3 — no longer works:
const tex = Phaser.Create.GenerateTexture({ data: palette, pixelWidth: 2 });

// v4 alternatives:
// Option A: Use a pre-made image asset
this.load.image('key', 'assets/image.png');

// Option B: Draw with Graphics and convert to texture
const gfx = this.add.graphics();
gfx.fillStyle(0xff0000);
gfx.fillRect(0, 0, 16, 16);
gfx.generateTexture('red-square', 16, 16);
gfx.destroy();
```

---

### 5. Removed Plugins

**Camera3D Plugin** — removed. Phaser 4 is 2D only. No replacement.

**Layer3D Plugin** — removed along with Camera3D.

**Facebook Instant Games Plugin** — removed. Facebook discontinued Instant Games support. No replacement.

**Spine Plugin (bundled)** — no longer bundled or updated. Use the [official Esoteric Software Phaser plugin](https://esotericsoftware.com/spine-phaser) instead.

---

### 6. IE9 Build Entry Point — REMOVED

```typescript
// v3 (for IE9 compatibility):
import Phaser from 'phaser/src/phaser-ie9.js';

// v4:
import Phaser from 'phaser';  // only modern entry point
```

All legacy polyfills (Array.forEach, Array.isArray, requestAnimationFrame, etc.) have been removed. Phaser 4 requires a modern browser.

---

### 7. Removed Math Utilities

| Removed | Alternative |
|---------|-------------|
| `Phaser.Math.SinCosTableGenerator` | Manual implementation if needed |

---

## Behavioral Changes

### DynamicTexture and RenderTexture Require Explicit render()

In Phaser 3, drawing to a DynamicTexture/RenderTexture took effect immediately. In Phaser 4, you must call `.render()` to commit the drawing.

```typescript
// v3:
const tex = this.textures.addDynamicTexture('key', 200, 200);
tex.draw('source', 0, 0);
// Visible immediately

// v4:
const tex = this.textures.addDynamicTexture('key', 200, 200);
tex.draw('source', 0, 0);
tex.render();  // REQUIRED — without this, nothing appears
```

---

### TileSprite No Longer Supports Texture Cropping

`TileSprite.setCrop()` is no longer supported in Phaser 4. If you need a cropped scrolling texture, use a RenderTexture instead:

```typescript
// v3 (no longer works):
const ts = this.add.tileSprite(0, 0, 800, 600, 'bg');
ts.setCrop(0, 0, 400, 300);

// v4 alternative:
const rt = this.add.renderTexture(0, 0, 400, 300);
rt.draw('bg', 0, 0);
rt.render();
```

---

### Geometry Classes Return Vector2 Instead of Point

All methods on `Circle`, `Ellipse`, `Line`, `Rectangle`, `Triangle`, and `Polygon` that previously returned `Phaser.Geom.Point` now return `Phaser.Math.Vector2`.

```typescript
// v3:
const centroid: Phaser.Geom.Point = Phaser.Geom.Triangle.Centroid(triangle);

// v4:
const centroid: Phaser.Math.Vector2 = Phaser.Geom.Triangle.Centroid(triangle);
```

---

### Math.TAU Now Correct

In Phaser 3, `Phaser.Math.PI2` was incorrectly equal to `Math.PI` (3.14159...). In Phaser 4:
- `Math.TAU` = `Math.PI * 2` (6.28318... — the correct "2π")
- `Math.PI_OVER_2` = `Math.PI / 2` (1.5707... — "π/2")

If your code was using `Math.PI2` thinking it was 2π, it was actually getting π — the logic was wrong in v3. Phaser 4 fixes this.

---

## Renderer Changes (Phaser Beam)

The WebGL renderer has been completely rewritten as "Phaser Beam." The public API stays the same but internals changed:

- New `BatchHandlerQuad` and `BatchHandlerQuadSingle` render nodes replace the old batch system
- Each batch handler creates its own WebGL buffers (~5MB RAM/VRAM for a basic game vs 16MB+ before)
- Up to 16x faster filter/mask performance on mobile
- New `BaseFilterShader` for custom filter shaders
- `roundPixels` now uses GPU-side bias for better accuracy

**Action required:** If you wrote custom WebGL shaders or used `Phaser.Renderer.WebGL.*` internals directly, those APIs changed. Review the Phaser 4 shader guide for the new patterns.

---

## TypeScript Changes

If using TypeScript, update `tsconfig.json`:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "typeRoots": ["./node_modules/phaser/types"],
    "types": ["Phaser"]
  }
}
```

The `typeRoots` + `types` fields are required for Phaser 4's type definitions.

---

## Not Changed (Preserved API)

The following core systems work identically to Phaser 3:
- Scene lifecycle (`init`, `preload`, `create`, `update`)
- `this.add.*` game object factory
- `this.physics.add.*` arcade physics factory
- `this.load.*` asset loader
- `this.input.*` input manager
- `this.cameras.main.*` camera
- `this.tweens.*` tween manager
- `this.time.*` timer events
- `this.sound.*` audio manager
- `this.anims.*` animation manager
- `this.registry.*` cross-scene data store
- `this.scene.*` scene manager
- Scale manager (`Phaser.Scale.*`)
- Tilemaps (`this.make.tilemap`, etc.)
- Events (`this.events.*`, `this.game.events.*`)
- Groups and object pooling
- Arcade Physics bodies, colliders, overlaps

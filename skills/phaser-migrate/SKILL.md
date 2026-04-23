---
name: phaser-migrate
description: This skill should be used when the user asks to "migrate from Phaser 3", "upgrade to Phaser 4", "convert my v3 game", "Phaser 3 to 4 migration", "update Phaser version", "my Phaser 3 game broke after upgrading", "behavior changed after RC upgrade", "RC6 to RC7 migration", or has code that uses deprecated or removed Phaser 3 APIs or behavior that silently drifted between Phaser 4 RC releases.
version: 0.4.0
---

# Phaser 3 → Phaser 4 Migration

Migrating from Phaser 3 to Phaser 4 is mostly straightforward. The core public API is preserved. This skill covers every breaking change and how to fix it — AND also covers RC-to-RC behavioral drift within Phaser 4 (e.g., RC6 → RC7) where APIs silently changed semantics between RC releases.

## Step 1 — Update the Package

```bash
npm uninstall phaser
npm install phaser@beta
```

Verify installed version:
```bash
node -e "const p = require('phaser'); console.log(p.VERSION)"
```

Should print `4.0.0-rc.7` (or later RC).

## Step 2 — Scan for Breaking Changes

Run these grep searches to find every issue in your `src/` directory:

```bash
# 1. Point → Vector2
grep -rn "Geom\.Point\|new Phaser\.Geom\.Point\|Geom\.Point\." src/

# 2. Math.PI2 → Math.TAU
grep -rn "Math\.PI2\b" src/

# 3. Phaser.Structs
grep -rn "Phaser\.Structs\." src/

# 4. DynamicTexture / RenderTexture (check for missing .render())
grep -rn "DynamicTexture\|RenderTexture\|addDynamicTexture\|addRenderTexture" src/

# 5. Removed plugins
grep -rn "Camera3D\|Layer3D\|FacebookInstant\|SpinePlugin\|SpineFile" src/

# 6. TileSprite crop (setCrop on TileSprite — no longer supported)
grep -rn "tileSprite.*setCrop\|setCrop.*tileSprite" src/

# 7. Create.GenerateTexture (removed)
grep -rn "Create\.GenerateTexture\|Phaser\.Create\." src/

# 8. Spine (use official Esoteric plugin instead)
grep -rn "spine\|Spine" src/ -i

# 9. phaser-ie9 entry point
grep -rn "phaser-ie9" . 
```

## Step 3 — Apply Fixes

### Fix 1: Geom.Point → Vector2

`Phaser.Geom.Point` is completely removed. Use `Phaser.Math.Vector2`.

```typescript
// BEFORE (Phaser 3)
const point = new Phaser.Geom.Point(x, y);
point.x = 100;
const distance = Phaser.Geom.Point.GetMagnitude(point);
const clone = Phaser.Geom.Point.Clone(point);
Phaser.Geom.Point.SetMagnitude(point, 50);

// AFTER (Phaser 4)
const point = new Phaser.Math.Vector2(x, y);
point.x = 100;
const distance = point.length();
const clone = point.clone();
point.setLength(50);
```

**Full Point → Vector2 method mapping:**
| Phaser 3 (static) | Phaser 4 (instance) |
|---|---|
| `Point.GetMagnitude(pt)` | `pt.length()` |
| `Point.Clone(pt)` | `pt.clone()` |
| `Point.SetMagnitude(pt, n)` | `pt.setLength(n)` |
| `Point.Ceil(pt)` | `pt.ceil()` |
| `Point.Floor(pt)` | `pt.floor()` |
| `Point.Invert(pt)` | `pt.invert()` |
| `Point.Negative(pt)` | `pt.negate()` |
| `Point.Project(pt, target, out)` | `pt.project(target)` |
| `Point.GetCentroid(points)` | `Phaser.Math.GetCentroid(points)` |
| `Point.GetRectangleFromPoints(pts)` | `Phaser.Math.GetVec2Bounds(pts)` |

All Geometry classes (`Circle`, `Ellipse`, `Line`, `Rectangle`, `Triangle`, `Polygon`) now return `Vector2` instead of `Point` for point-related results.

### Fix 2: Math.PI2 → Math.TAU

```typescript
// BEFORE (Phaser 3) — NOTE: Math.PI2 was INCORRECTLY π in v3
const fullRotation = Math.PI2;  // was wrong!

// AFTER (Phaser 4)
const fullRotation = Math.TAU;       // Correct π×2
const halfRotation = Math.PI_OVER_2; // π/2 (new constant)
```

### Fix 3: Phaser.Structs → Native JS

```typescript
// BEFORE (Phaser 3)
const myMap = new Phaser.Structs.Map([]);
myMap.set('key', value);
myMap.get('key');
myMap.delete('key');
myMap.getArray();

const mySet = new Phaser.Structs.Set();
mySet.set(value);
mySet.delete(value);
mySet.contains(value);

// AFTER (Phaser 4)
const myMap = new Map<string, any>();
myMap.set('key', value);
myMap.get('key');
myMap.delete('key');
[...myMap.values()];

const mySet = new Set<any>();
mySet.add(value);
mySet.delete(value);
mySet.has(value);
```

### Fix 4: DynamicTexture / RenderTexture — Add render()

```typescript
// BEFORE (Phaser 3) — drawing happened immediately
const dynTex = this.textures.addDynamicTexture('key', 200, 200);
dynTex.draw('sprite', 0, 0);
// visible immediately

// AFTER (Phaser 4) — must call render() to commit drawing
const dynTex = this.textures.addDynamicTexture('key', 200, 200);
dynTex.draw('sprite', 0, 0);
dynTex.render();   // ← REQUIRED in v4
```

### Fix 5: Removed Plugins

**Camera3D** — no replacement. Phaser 4 is 2D only. If 3D is needed, use Three.js alongside Phaser.

**Layer3D** — no replacement. Removed with Camera3D.

**Facebook Instant Games** — removed. Facebook no longer supports this platform.

**Spine Plugin** (official v3/v4 Spine support) — use the official [Esoteric Software Phaser plugin](https://esotericsoftware.com/spine-phaser) instead. The Phaser bundled Spine plugin is no longer maintained.

### Fix 6: TileSprite Cropping

TileSprite no longer supports texture cropping in Phaser 4.

```typescript
// BEFORE (Phaser 3)
const ts = this.add.tileSprite(x, y, w, h, 'texture');
ts.setCrop(0, 0, 100, 100);  // no longer works in v4

// AFTER (Phaser 4) — use RenderTexture instead if cropping is needed
const rt = this.add.renderTexture(x, y, 100, 100);
rt.draw('texture', 0, 0);
rt.render();
```

### Fix 7: Create.GenerateTexture Removed

`Phaser.Create.GenerateTexture` and all Create Palettes are removed.

```typescript
// BEFORE (Phaser 3)
const texture = Phaser.Create.GenerateTexture({ data: palettes, pixelWidth: 2 });

// AFTER (Phaser 4) — use a pre-made image asset, or draw with Graphics
const gfx = this.add.graphics();
gfx.fillStyle(0xff0000);
gfx.fillRect(0, 0, 16, 16);
gfx.generateTexture('red-square', 16, 16);
gfx.destroy();
```

### Fix 8: Removed IE9 Entry Point

```typescript
// BEFORE — some projects imported the IE9-compatible build
import Phaser from 'phaser/src/phaser-ie9.js';

// AFTER — just use the standard import
import Phaser from 'phaser';
```

## Step 4 — Update TypeScript Config

If using TypeScript, ensure `tsconfig.json` is correct for v4:

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "typeRoots": ["./node_modules/phaser/types"],
    "types": ["Phaser"]
  }
}
```

## Step 5 — Verify and Test

```bash
# Type check — must pass with 0 errors
npx tsc --noEmit

# Start dev server and check browser console
npm run dev
```

Check in browser:
1. No console errors on startup
2. All scenes load correctly
3. Physics behaves the same as v3
4. Animations play correctly

## Quick Migration Checklist

- [ ] `npm install phaser@beta` run
- [ ] `tsconfig.json` updated with `typeRoots` + `types`
- [ ] All `Phaser.Geom.Point` replaced with `Phaser.Math.Vector2`
- [ ] All `Math.PI2` replaced with `Math.TAU`
- [ ] All `Phaser.Structs.Map/Set` replaced with native `Map`/`Set`
- [ ] All `DynamicTexture`/`RenderTexture` have `render()` calls after drawing
- [ ] Removed plugin references deleted (Camera3D, Layer3D, Facebook, old Spine)
- [ ] `TileSprite.setCrop()` calls replaced or removed
- [ ] `Phaser.Create.GenerateTexture` replaced with Graphics/textures
- [ ] `phaser-ie9` imports replaced with `phaser`
- [ ] `npx tsc --noEmit` passes
- [ ] Game runs in browser without console errors

## Additional Resources

### Reference Files
- **`references/v3-to-v4-changes.md`** — Complete changelog of all Phaser v3→v4 breaking changes, including renderer internals, deprecated APIs, and behavior differences
- **`references/rc6-to-rc7-changes.md`** — Behavioral drift between Phaser 4 RC releases (masks, animations, camera, tilemap, groups, scene events, scale manager). Read when upgrading RC versions OR when code that worked in an earlier RC silently misbehaves.

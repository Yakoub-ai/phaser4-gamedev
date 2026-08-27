---
name: phaser-migrate
description: This skill should be used when the user asks to "migrate from Phaser 3", "upgrade to Phaser 4", "convert my v3 game", "Phaser 3 to 4 migration", "update Phaser version", "my Phaser 3 game broke after upgrading", "behavior changed after upgrading Phaser 4", "upgrade Phaser 4.0 to 4.2", or has code that uses deprecated or removed Phaser 3 APIs or behavior that silently drifted between Phaser 4 RC releases.
version: 0.7.0
---

# Phaser 3 → Phaser 4 Migration

Migrating from Phaser 3 to Phaser 4 is mostly straightforward. The core public API is preserved. This skill covers every breaking change and how to fix it — AND also covers moving between Phaser 4 point releases (4.0 → 4.1 → 4.2), plus the runtime behaviour that compiles cleanly and still surprises you.

## Step 1 — Update the Package

```bash
npm uninstall phaser
npm install phaser
```

Verify installed version:
```bash
node -e "const p = require('phaser'); console.log(p.VERSION)"
```

Should print `4.2.1` (or later RC).

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

# 10. WebGL geometry masks (stencil-based masks changed in Phaser 4 — use scissor/viewport instead)
grep -rn "createGeometryMask\|createBitmapMask\|BitmapMask\|setMask\b\|clearMask\|setScissor" src/ 
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

### Fix 9: Masks → Camera Viewport or the Mask Filter

Phaser 4 removed the v3 masking classes. `BitmapMask` is gone entirely, and neither
`createGeometryMask()` nor `createBitmapMask()` exists on Game Objects. `GeometryMask`
survives as a class but only the (deprecated) Canvas renderer consumes it — under Beam
it does nothing.

```typescript
// BEFORE (Phaser 3) — geometry mask via stencil buffer
const shape = this.add.graphics().fillRect(x, y, w, h);
const mask = shape.createGeometryMask();   // removed in v4
targetSprite.setMask(mask);

// AFTER (Phaser 4), rectangular clip — give the content its own camera:
const clipCam = this.cameras.add(x, y, w, h);
clipCam.ignore(this.children.list.filter(c => c !== targetSprite));
this.cameras.main.ignore(targetSprite);

// AFTER (Phaser 4), arbitrary shape — the Mask filter:
targetSprite.enableFilters();                  // filters is null until you call this
targetSprite.filters!.internal.addMask(shape); // texture key or GameObject
targetSprite.filters!.internal.addMask(shape, true);  // inverted
```

There is **no `camera.setScissor()`** in Phaser 4 — that method does not exist on
`Phaser.Cameras.Scene2D.Camera`. Use `setViewport()`.

`Phaser.Actions.AddMaskShape()` is a convenience that creates a Shape and wires it up as
a mask in one call — it is the replacement for the v3 Circle FX.

## Step 4 — Update TypeScript Config

If using TypeScript, ensure `tsconfig.json` is correct for v4:

```json
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "skipLibCheck": true,
    "noEmit": true
  },
  "include": ["src"]
}
```

Phaser 4 publishes its types through the `exports` map in its own `package.json`, so a
modern resolver picks them up from a plain `import Phaser from 'phaser';` with no extra
config.

> **Delete `typeRoots: ["./node_modules/phaser/types"]` and `types: ["Phaser"]` if your v3
> tsconfig has them.** Against Phaser 4 that pair fails with
> `TS2688: Cannot find type definition file for 'Phaser'` — v4 ships one `types/phaser.d.ts`
> file, which is not a valid type-root package.

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

- [ ] `npm install phaser` run
- [ ] `tsconfig.json` v3-era `typeRoots` + `types: ["Phaser"]` removed; `moduleResolution` is `bundler`/`node16`
- [ ] All `Phaser.Geom.Point` replaced with `Phaser.Math.Vector2`
- [ ] All `Math.PI2` replaced with `Math.TAU`
- [ ] All `Phaser.Structs.Map/Set` replaced with native `Map`/`Set`
- [ ] All `DynamicTexture`/`RenderTexture` have `render()` calls after drawing
- [ ] Removed plugin references deleted (Camera3D, Layer3D, Facebook, old Spine)
- [ ] `TileSprite.setCrop()` calls replaced or removed
- [ ] `Phaser.Create.GenerateTexture` replaced with Graphics/textures
- [ ] `phaser-ie9` imports replaced with `phaser`
- [ ] WebGL masks (`createGeometryMask` / `createBitmapMask` / `BitmapMask`) replaced with a camera viewport or `filters.internal.addMask()`; no `camera.setScissor()` calls
- [ ] `npx tsc --noEmit` passes
- [ ] `node skills/phaser-playtest/scripts/playtest.mjs --project .` passes — a green `tsc` says nothing about whether the migrated game renders

## Additional Resources

### Reference Files
- **`references/v3-to-v4-changes.md`** — Complete changelog of all Phaser v3→v4 breaking changes, including renderer internals, deprecated APIs, and behavior differences
- **`references/runtime-gotchas.md`** — Behaviour that compiles cleanly and still surprises you: masking, animation state switches, camera follow, tilemap collision, `onFloor()` timing, cross-scene wiring, scale manager. Read when the compiler is happy but the game is not.
- **`references/v4-release-notes.md`** — What shipped in 4.0.0, 4.1.0, 4.2.0 and 4.2.1, and what to change when moving between them. Read when upgrading Phaser 4 point releases, or to find out whether a bug you are chasing is already fixed upstream.

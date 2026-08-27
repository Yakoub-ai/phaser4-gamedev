---
name: phaser-fx
description: This skill should be used when the user asks to "add a glow", "blur the background", "add a screen effect", "mask a sprite", "add post-processing", "shader effect", "add lighting", "flashlight cone", "vision cone", "normal maps", "make the screen flash", "color grading", "tint a sprite", "screen shake with effects", "damage flash", "hit flash", "vignette", "bloom", "convert my preFX/postFX code", "BitmapMask replacement", "custom shader", "SpriteGPULayer", "Mesh2D", "stencil mask", or any Phaser 4 visual effect, filter, mask, light or renderer question.
version: 0.7.0
---

# Phaser 4 Filters, Masks, Lights and the Beam Renderer

Phaser 4 replaced the v3 renderer wholesale. FX and masks — two separate, mutually
incompatible systems in v3 — are now one system called **Filters**, available on every
game object and every camera with no exceptions.

If you are converting v3 code, start at the conversion table at the bottom. If you are
writing new code, start here.

---

## The one rule that catches everyone

**Game objects need `enableFilters()` first. Cameras do not.**

```typescript
// Game object — filters is null until you enable it
sprite.enableFilters();
sprite.filters!.internal.addGlow(0xff00ff, 4, 0, 1);

// Camera — filters is always there
this.cameras.main.filters.external.addVignette(0.5, 0.5, 0.5, 0.5);
```

Calling `sprite.filters.internal.addBlur()` on a fresh sprite throws, because `filters`
is `null`. This is the single most common Phaser 4 effects error, and the message
(`Cannot read properties of null`) does not point at the cause.

---

## Internal vs external

Every filter list has two halves, and picking the wrong one is the second most common
mistake.

| | `filters.internal` | `filters.external` |
|---|---|---|
| Space | The object's own space | The rendering context, usually full screen |
| Moves with the object | Yes | No |
| Resolution | The object's size | Full canvas |
| Cost | Cheaper | More expensive |
| Use for | Glow on a sprite, masking a panel | Screen-wide colour grading, vignette |

```typescript
// A glow that follows the enemy: internal.
enemy.enableFilters();
enemy.filters!.internal.addGlow(0xff0000, 8, 0, 1);

// A full-screen red wash when the player is hurt: external, on the camera.
this.cameras.main.filters.external.addColorMatrix();
```

Some objects cannot define an internal space and fall back to external automatically:
objects with no width or height, and `Shape` objects whose stroke extends past their
reported bounds. If an internal filter on a shape behaves like a screen effect, that is
why.

---

## The filter catalogue

Every one is an `add*` call on `filters.internal` or `filters.external`:

| Filter | What it does |
|---|---|
| `addBlur(quality, x, y, strength)` | Gaussian blur |
| `addGlow(color, outerStrength, innerStrength, scale)` | Outline glow |
| `addShadow(x, y, decay, power, color, samples, intensity)` | Drop shadow |
| `addBokeh(radius, amount, contrast)` | Depth-of-field style blur |
| `addPixelate(amount)` | Pixelation |
| `addBlocky(amount)` | Blocky quantisation |
| `addVignette(x, y, radius, strength)` | Darkened edges |
| `addBarrel(amount)` | Pinch / expand lens distortion |
| `addDisplacement(texture, x, y)` | Displace by a texture — heat haze, water |
| `addColorMatrix()` | Colour grading (see below) |
| `addCombineColorMatrix()` | Blend two colour matrices |
| `addGradientMap(...)` | Remap luminance through a gradient |
| `addThreshold(...)` | Alpha/colour cutoff |
| `addQuantize(...)` | Reduce the colour count |
| `addMask(source, invert, viewCamera, viewTransform, scaleFactor)` | Masking |
| `addKey(...)` | Chroma key |
| `addBlend(...)` | Blend modes beyond WebGL's four native ones |
| `addTiltShift(...)` | Tilt-shift |
| `addPanoramaBlur(...)` | Panoramic blur |
| `addSampler(...)` | Sample from another texture |
| `addImageLight(...)` | Image-based lighting |
| `addNormalTools(...)` | Normal map manipulation |
| `addParallelFilters(...)` | Run two filter chains and combine them |
| `addCustom(...)` | Your own shader |

### ColorMatrix has a nested property

The colour methods sit on a `colorMatrix` sub-property, not on the filter:

```typescript
const cm = sprite.filters!.internal.addColorMatrix();
cm.colorMatrix.sepia();       // correct
cm.colorMatrix.grayscale();
cm.colorMatrix.night(0.3);
// cm.sepia();                // wrong — this was the v3 shape
```

### Composite effects live in Actions

Some v3 FX were rebuilt as Actions, because they need several filters working together:

```typescript
Phaser.Actions.AddEffectBloom(target);   // was the Bloom FX
Phaser.Actions.AddEffectShine(target);   // was the Shine FX
Phaser.Actions.AddMaskShape(target);     // was the Circle FX
```

---

## Masking

`BitmapMask` no longer exists. `createGeometryMask()` and `createBitmapMask()` are not
methods on game objects. `GeometryMask` survives as a class but only the deprecated
Canvas renderer uses it — under Beam it does nothing at all.

There are two replacements, and the choice is about shape:

### Rectangular clip → a camera viewport

Scroll panels, minimaps, split screen. Cheaper than a filter, and pixel-exact.

```typescript
const panelCam = this.cameras.add(x, y, width, height);
panelCam.setScroll(scrollX, scrollY);
panelCam.ignore(this.children.list.filter(c => c !== panelContent));
this.cameras.main.ignore(panelContent);
```

> There is **no `camera.setScissor()`** in Phaser 4. If you find that call in a guide,
> the method does not exist — use `setViewport()`.

### Any other shape → the Mask filter

```typescript
const shape = this.add.graphics();
shape.fillStyle(0xffffff).fillCircle(64, 64, 64);

content.enableFilters();
content.filters!.internal.addMask(shape);        // GameObject or texture key
content.filters!.internal.addMask(shape, true);  // inverted: hide inside, show outside
```

The mask source can be a texture key or a game object. Given an object, Phaser renders it
to a DynamicTexture and uses that — so animated masks work, and so do masks made from
filter output. `scaleFactor` trades mask precision against memory; if you set it, scale
the mask source to match.

### Stencils — persistent masking (4.2.0+)

For a mask that stays put across many objects and frames, a `Stencil` is cheaper than
re-running a mask filter. Unlike v3 stencil masks these are universal and persistent, and
accept anything that draws pixels as a source.

```typescript
const stencil = this.add.stencil();
stencil.add(this.add.circle(400, 300, 120, 0xffffff));
```

Modes: `addLayer`, `subtractLayer`, `clear`, `clearRegion`, with add and subtract each
invertible. `this.add.stencilreference()` re-renders an existing stencil with different
settings, which is how you reuse or remove stencil geometry.

Regular alpha does nothing inside a stencil, so alpha is controlled by
`stencilAlphaStrategy` instead (see below). If `stencilInvert` appears to do nothing, be
on 4.2.1 or later — it was broken by an alpha bug in 4.2.0.

---

## Tinting

Phaser 4 separated the tint *colour* from the tint *mode*. In v3 you set `tintFill = true`;
that property does not exist any more.

```typescript
sprite.setTint(0xff0000);
sprite.setTintMode(Phaser.TintModes.FILL);   // was tintFill = true
```

Modes: `MULTIPLY` (default), `FILL`, `ADD`, `SCREEN`, `OVERLAY`, `HARD_LIGHT`,
`MULTIPLY_TWO`.

`MULTIPLY_TWO` (4.2.0+) uses a **second** tint colour per corner, which makes gradient
tints possible without a shader — fire, ice, inversion:

```typescript
sprite.setTint(0xff2200).setTint2(0xffee00).setTintMode(Phaser.TintModes.MULTIPLY_TWO);
```

`Mesh2D` and `Tile` support a constant `tint2`. `TilemapGPULayer` does not support tinting
on tiles at all.

> **Shapes have no tint at all.** `Rectangle`, `Arc`, `Triangle` and the other `Shape`
> objects do not implement the Tint component — `setTint()` and `setTintMode()` are not
> methods on them, and the compiler will say so. Change `fillColor` instead:
> `rect.fillColor = 0xff0000`. This bites most often when prototyping with coloured
> rectangles and then wondering why the damage flash pattern does not compile.

**The damage flash**, which every action game needs:

```typescript
hit() {
  this.sprite.setTint(0xffffff).setTintMode(Phaser.TintModes.FILL);
  this.scene.time.delayedCall(80, () => this.sprite.clearTint());
}
```

Prefer this over a white-flash filter — it is one draw call and no framebuffer.

---

## Lighting

```typescript
this.lights.enable().setAmbientColor(0x333333);
const torch = this.lights.addLight(x, y, 200, 0xffaa33, 2);
```

Objects must opt into lighting; see `references/lighting.md` for the component and for
normal-map setup.

### Cone lights (4.2.0+)

Flashlights, vision cones, headlights, searchlights. They run through the same lighting
shader — no mask, no second camera, no rendering the scene twice:

```typescript
const beam = this.lights.addConeLight(
  x, y,
  300,        // radius
  0xffffff,   // colour
  2,          // intensity
  rotation,   // radians — the direction the cone points
  0.2,        // inner angle, radians
  0.6,        // outer angle, radians
);

beam.setConeRotation(Phaser.Math.Angle.Between(px, py, mx, my));
beam.setConeAngles(0.15, 0.5);
beam.disableCone();   // back to a normal point light
```

Any object already lit by Phaser lighting is lit by a cone light. That makes stealth
vision cones and torch mechanics far cheaper than the v3 approaches.

---

## Performance

Filters are framebuffer operations. Each one is a render pass, and passes are what cost.

- **Prefer tint over a filter** for flashes and colour changes. A tint is part of the
  batch; a filter is a separate pass.
- **Prefer one camera filter over N object filters.** Twenty enemies each with a glow is
  twenty extra passes. If they can share a screen-space effect, do that instead.
- **Internal beats external** where both work — internal renders at the object's size,
  external at full canvas.
- **Filters never render with mipmaps.** Do not expect mipmap-based softening from a
  filter output (4.1.0 fixed the opposite bug, where they incorrectly did).
- **Enable filters once, not per frame.** `enableFilters()` in `create()`, then adjust
  the controller's properties in `update()`. Calling `add*` every frame stacks filters
  until the frame budget is gone — an easy accidental leak, and it looks like a
  performance bug rather than a logic one.
- **Alpha strategies use `discard`,** which is inefficient by design. `dither` and
  `threshold` exist for effects and for stencils, not as a performance lever.

Verify any of this with the playtest harness rather than by eye — filter cost shows up as
a frame-rate cliff under load, which a single reading misses and a `sample` step catches:

```javascript
{ action: 'sample', expression: `game.loop.actualFps`,
  duration: 3000, interval: 100, expect: { stat: 'min', atLeast: 50 } }
```

> **Read headless FPS as a comparison, never as a number.** The harness runs WebGL through
> SwiftShader, and filters are precisely what software rendering is worst at: a scene with
> a glow, a vignette, a colour matrix and a lit particle emitter measures around 12–20fps
> headless while running at 60 on any real GPU. Compare a run against the previous run on
> the same machine; do not set an absolute threshold for a filter-heavy scene and do not
> report a headless number as the game's performance.

---

## Converting from Phaser 3

| v3 | v4 |
|---|---|
| `sprite.preFX.addGlow()` | `sprite.enableFilters(); sprite.filters!.internal.addGlow()` |
| `sprite.postFX.addBlur()` | `sprite.enableFilters(); sprite.filters!.external.addBlur()` |
| `camera.postFX.addVignette()` | `camera.filters.external.addVignette()` (no enable step) |
| `new BitmapMask(...)`, `setMask()` | `filters.internal.addMask(source)` |
| `createGeometryMask()` | A camera viewport, or `addMask()` |
| `sprite.tintFill = true` | `sprite.setTintMode(Phaser.TintModes.FILL)` |
| `setPipeline('X')` | Render nodes — `customRenderNodes`, `RenderConfig#renderNodes` |
| Bloom FX | `Phaser.Actions.AddEffectBloom()` |
| Shine FX | `Phaser.Actions.AddEffectShine()` |
| Circle FX | `Phaser.Actions.AddMaskShape()` |
| Gradient FX | the `Gradient` game object |
| `colorMatrixFilter.sepia()` | `filter.colorMatrix.sepia()` |
| `Mesh` / `Plane` | `Mesh2D` (4.2.0+) |

Run the migration grep before assuming your code is clean:

```bash
grep -rn "preFX\|postFX\|BitmapMask\|createGeometryMask\|tintFill\|setPipeline\|setScissor" src/
```

---

## Additional Resources

### Reference Files
- **`references/filters-api.md`** — Every filter with its full parameter list, worked
  examples, and the internal/external decision per effect.
- **`references/lighting.md`** — The lighting model, normal maps, cone lights, the
  `Lighting` component, and the performance envelope.
- **`references/renderer-and-shaders.md`** — Beam, render nodes, custom shaders,
  `Mesh2D`, `SpriteGPULayer`, `Stencil`, `CustomContext`, and alpha strategies.

### Related
- `skills/phaser-migrate/` — the full v3→v4 change list and the release notes
- `skills/phaser-particles/` — particle effects, which usually pair with these
- `skills/phaser-analyze/references/performance-playbook.md` — when effects cost frames

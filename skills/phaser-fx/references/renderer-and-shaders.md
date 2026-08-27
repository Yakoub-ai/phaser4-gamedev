# The Beam Renderer, Render Nodes and Custom Shaders

Phaser 4's renderer, and the game objects that reach into it. Read this when you need
behaviour Phaser does not expose as a property, when you are converting a v3 custom
pipeline, or when you need to draw more sprites than a normal display list can carry.

---

## Render nodes replaced pipelines

The v3 `Pipeline` system is gone. In v3 a pipeline often owned several responsibilities
and had to manage WebGL state itself, which is why enabling one FX could break an
unrelated mask. Phaser 4 splits rendering into **render nodes**, each handling exactly
one task, with WebGL state centralised.

You rarely touch them directly. When you do:

```typescript
// Per-object
gameObject.defaultRenderNodes    // what it normally uses
gameObject.customRenderNodes     // your overrides

// At boot, register your own
new Phaser.Game({ render: { renderNodes: { /* ... */ } } });
```

Every render node has a `run` method; some add a `batch` method that assembles state from
several sources before invoking `run`.

**Converting from v3:** there is no mechanical translation from a pipeline to a render
node. `setPipeline()` does not exist. Most v3 custom pipelines existed to do something
that is now a stock filter — check the filter catalogue in `filters-api.md` before
writing a render node.

---

## Custom shaders

Two routes, and they answer different questions.

### The `Shader` game object — a shader that *is* the object

```typescript
this.add.shader(key, x, y, width, height);
```

Use it for a shader-driven background, a procedural effect, a water plane. The shader
produces the pixels; there is no input image.

### `addCustom()` — a shader that *transforms* what is drawn

```typescript
sprite.enableFilters();
sprite.filters!.internal.addCustom(/* ... */);
```

Use it when you need to alter an existing image: your own colour grade, distortion, or
edge detection.

Two things to know before writing one:

- **GLSL loading changed in v4.** The v3 `.glsl` loader conventions do not carry over —
  check the current loader API rather than porting a v3 loading call.
- **Custom shaders must implement alpha strategy themselves.** Stock Phaser shaders
  handle it; yours will not unless you write it. If you do not want to, route the object
  through compositing with `filtersForceComposite` so a Phaser shader handles the alpha.

The bundled guide is worth reading in full before writing a shader:
`node_modules/phaser/docs/Phaser 4 Shader Guide/`. `Phaser 4 Rendering Concepts` and
`Phaser 4 Internal Space Guide` in the same folder explain the coordinate spaces that
filters and masks operate in, which is where most custom-shader confusion comes from.

---

## `Mesh2D` (4.2.0+)

Textured triangles that batch alongside regular sprites. This is the 2D replacement for
the removed v3 `Mesh` and `Plane`.

```typescript
const mesh = this.add.mesh2d(x, y, 'texture', vertices, indices);
```

Two rendering strategies, and the choice is about how often the topology changes:

**Quad-paired (default)** — precompute an optimized index list that pairs triangles into
quads, synthesizing degenerate triangles where a triangle has no edge-sharing partner:

```typescript
mesh.buildOrderedIndices(2);        // 0 fast, 1 medium, 2 high
mesh.setUseOrderedIndices(true);    // toggle without rebuilding
```

Pay the cost once. Correct for stable topology — a deformable banner, a rope, a
pre-built terrain strip.

**Raw triangles** — draw through the `BatchHandlerTri` render node (`gl.TRIANGLES`):

```typescript
mesh.setRenderAsTriangles(true);
```

Correct for topology that changes every frame and cannot be optimized into quads:
soft-body deformation, destructible terrain, procedural geometry.

`Mesh2D` supports constant `tint2`, so `MULTIPLY_TWO` gradient tints work on it.

---

## `SpriteGPULayer`

```typescript
const layer = this.add.spriteGPULayer('atlasKey', 10000);
```

A GPU-resident layer for very large numbers of sprites — bullet-hell projectiles, dense
particle-like swarms, tile decoration. The sprites live on the GPU rather than as
individual display-list objects, which is what makes the count possible.

Constraints worth knowing before designing around it:

- **WebGL only.** It has no `Mask` component — masking was a Canvas feature, and the
  object is WebGL-exclusive.
- It does not behave like a normal container of Sprites. If you need per-object input
  handling, physics bodies, or arbitrary per-object logic, use ordinary sprites in a
  Group and accept the lower ceiling.
- It reads the Phaser namespace correctly under ESM as of 4.2.0 — earlier versions
  crashed in module builds.

Reach for it when profiling shows draw calls are the bottleneck and the objects are
visually similar. Do not start here.

---

## `Stencil` and `StencilReference` (4.2.0+)

A container whose contents write to the stencil buffer — a fast, persistent way to mask
the canvas.

```typescript
const stencil = this.add.stencil();
stencil.add(maskShape);

const ref = this.add.stencilreference();   // re-render a Stencil with different settings
```

Modes: `addLayer`, `subtractLayer`, `clear`, `clearRegion`. Add and subtract can each be
inverted.

Unlike v3 stencil masks these are universal and persistent, and accept anything that
draws pixels as a source — sprites, animations, filter output.

Two behaviours to know:

- **Regular alpha does nothing inside a stencil.** Use `stencilAlphaStrategy` to control
  what happens to partly-transparent pixels.
- **On 4.2.0, `stencilInvert` silently did nothing** due to an alpha bug, and framebuffers
  did not clear stencil correctly. Both fixed in 4.2.1. If invert appears broken, check
  your version before debugging your code.

Since 4.2.0 the stencil test is enabled by default (`func: gl.EQUAL`, passing when the
buffer equals 0) — testing showed little performance cost from leaving it on. If you do
not need it at all, `render: { stencil: false }` in the game config skips creating the
buffer and saves the memory.

---

## `CustomContext` (4.2.0+)

```typescript
const ctx = this.add.customcontext();
```

A container that modifies the `DrawingContext` at render time. This is the escape hatch:
toggling stencil testing, selectively activating alpha strategies, freehand GL scissor
modification, colour write masks.

Advanced and easy to misuse. Reach for it only when you have established that no
property, filter or stencil expresses what you need.

---

## Alpha strategies (4.2.0+)

Lets shaders use GLSL `discard` instead of alpha blending:

| Strategy | Behaviour |
|---|---|
| `keep` | Alpha as normal (default) |
| `dither` | Dither to choose which pixels to discard |
| `threshold` | Discard every pixel below an alpha threshold |

Set a default in the game config with `render.alphaStrategy`, and override per object on
`Stencil` and `CustomContext`. `render.stencilAlphaStrategy` sets the default used inside
`Stencil` objects specifically.

`discard` is **inefficient**. This exists for effects and for stencil work — cutout
foliage that must not blend, hard-edged dissolves, stencil sources — not as a performance
optimisation. Most Phaser shaders handle alpha strategy; custom ones must implement it.

---

## Renderer facts that change how you build

- **The Canvas renderer is deprecated.** It still runs, but nothing new in v4 targets it:
  no filters, no stencils, no lighting, no `SpriteGPULayer`. Its historical advantage —
  27 blend modes against WebGL's four native ones — is now covered by the `Blend` filter.
  Use `Phaser.AUTO` and expect WebGL.
- **Texture coordinates use standard GL orientation** in v4 (Y=0 at the bottom for
  textures). This matters when you write shaders or hand-build UVs; it does not affect
  ordinary game code.
- **`Layer` became a true `GameObject` in 4.1.0.** Filters on layers did not work before
  that. If you avoided layers because of it, they are usable now.
- **`WebGLRenderer.genericVertexBuffer` and `genericVertexData` were removed**, freeing
  16MB of RAM and VRAM. Nothing to do unless you referenced them.
- **`Timestep.setFPSLimit(limit)`** changes the frame rate at runtime and updates the
  derived properties. Prefer it over assigning `fpsLimit` directly:

  ```typescript
  this.game.loop.setFPSLimit(30);   // battery-saver mode
  ```

---

## Checking renderer-level work

Renderer failures are quiet — a shader that fails to compile, a stencil that clears
nothing, a `SpriteGPULayer` that draws zero sprites all leave a running game with wrong
pixels and no console error.

```javascript
// playtest/renderer-check.mjs
export default [
  { name: 'running on WebGL, not the Canvas fallback', action: 'expect',
    expect: { expression: `game.renderer.type`, equals: 2 } },
  { name: 'frame budget survives the effect load', action: 'sample',
    expression: `game.loop.actualFps`, duration: 4000, interval: 100,
    expect: { stat: 'min', atLeast: 50 } },
  { name: 'rendered', action: 'screenshot' },
];
```

The harness reports the renderer type on every run and warns when a game falls back to
Canvas — which is the first thing to rule out when WebGL-only features do nothing at all.

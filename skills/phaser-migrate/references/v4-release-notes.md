# Phaser 4 Release Notes — 4.0.0 → 4.2.1

What actually shipped in each Phaser 4 release, and what you have to change when you
move between them. Sourced from the changelogs bundled inside the `phaser` npm package
(`node_modules/phaser/changelog/v4/`), which is the authoritative record and is worth
reading directly when a detail matters.

| Version | Codename | Released | Nature |
|---|---|---|---|
| 4.0.0 | Caladan | 10 Apr 2026 | First stable v4. New Beam renderer, Filters, render nodes. |
| 4.1.0 | Salusa | 30 Apr 2026 | `Layer` becomes a real GameObject; ESM export fixes. |
| 4.2.0 | Giedi | 19 Jun 2026 | `Mesh2D`, `Stencil`, `CustomContext`, cone lights, second tint. |
| 4.2.1 | Giedi | 9 Jul 2026 | Fix release. Stencil, ScaleManager, tween start-delay. |

**Install the current stable:**

```bash
npm install phaser
```

> **Do not install `phaser@beta`.** The `beta` dist-tag still points at `4.0.0-rc.7`,
> which is *older* than the current stable release. `npm install phaser` gives you the
> newest 4.x. Any guide that still says `phaser@beta` predates the 4.0.0 stable release
> and should be treated as stale on every other point too.

Check what you actually have:

```bash
node -p "require('phaser/package.json').version"
```

---

## 4.0.0 — Caladan (first stable)

The whole v3 renderer was replaced. If you are coming from v3, read
`v3-to-v4-changes.md` first — this section only covers what is specific to the stable
release.

Headline changes:

- **Pipelines → Render Nodes.** Each render node handles one rendering task. Game
  objects expose `defaultRenderNodes` / `customRenderNodes`; register your own via
  `RenderConfig#renderNodes` at boot.
- **FX and Masks unified into Filters.** One system, available on *any* game object
  and on cameras — v3's restrictions on which objects supported FX are gone.
- **Canvas renderer is deprecated.** It works, but nothing new in v4 targets it.
  Its one remaining advantage is the wider blend-mode set, which the `Blend` filter
  now reproduces under WebGL.
- **`Geom.Point` removed** — use `Vector2`.
- **`Math.PI2` removed** — use `Math.TAU`.
- **`Mesh` and `Plane` removed** (a 2D replacement arrived in 4.2.0 as `Mesh2D`).
- **Texture coordinates use standard GL orientation.**

### Filters replace both FX and masks

`filters` is `null` until you call `enableFilters()`. This is the single most common
"why is my filter throwing" mistake:

```typescript
sprite.enableFilters();
sprite.filters!.internal.addGlow(0xff00ff, 4, 0, 1);
sprite.filters!.external.addBlur(0, 2, 2, 1);
```

**Internal vs external:** internal filters run in the object's own space and move with
it. External filters run in the rendering context — usually full-screen, after the
camera transform. Objects with no definable internal space (no width/height, or `Shape`
objects whose stroke exceeds their reported bounds) fall back to external.

| v3 | v4 |
|---|---|
| `sprite.preFX.addGlow()` | `sprite.enableFilters(); sprite.filters!.internal.addGlow()` |
| `sprite.postFX.addBlur()` | `sprite.enableFilters(); sprite.filters!.external.addBlur()` |
| `new BitmapMask(...)` + `setMask()` | `filters.internal.addMask(source)` |
| `createGeometryMask()` (WebGL) | `filters.internal.addMask()`, or a camera viewport |
| Bloom FX | `Phaser.Actions.AddEffectBloom()` |
| Shine FX | `Phaser.Actions.AddEffectShine()` |
| Circle FX | `Phaser.Actions.AddMaskShape()` |
| Gradient FX | the `Gradient` game object |

`ColorMatrix` moved its colour methods onto a sub-property: call
`filter.colorMatrix.sepia()`, not `filter.sepia()`.

---

## 4.1.0 — Salusa

Small release, but it contains the fix that decides how you import Phaser.

- **`Layer` is now a true `GameObject`.** This fixed filters not working on layers,
  plus a set of smaller inconsistencies. If you avoided layers in 4.0.0 because
  filters misbehaved on them, they are usable now.
- **ESM build gained its default export.** `import Phaser from 'phaser'` works from
  4.1.0 onward. On 4.0.0 you needed `import * as Phaser from 'phaser'`. `Class` and
  `LOG_VERSION` exports were fixed in the same release.
- **`RenderConfig#mipmapRegeneration`** lets framebuffer-backed objects use mipmaps
  when the game is configured for them. Currently DynamicTextures only; filters never
  render with mipmaps. It costs a mipmap rebuild on every change — opt in deliberately.
- **Filter controllers: `getPadding()` → `getPaddingCeil()`.** If you wrote a custom
  render node that calls `getPadding()` on a filter controller, switch to
  `getPaddingCeil()` — fractional padding costs you quality.
- `Utils.Array.GetRandom` no longer returns `null` when only `startIndex` was given.

**Upgrade action:** if you are on 4.0.0, move to `import Phaser from 'phaser'` and drop
any `import * as` workaround.

---

## 4.2.0 — Giedi

The largest feature release since stable.

### `Mesh2D` — textured triangles that batch with sprites

```typescript
const mesh = this.add.mesh2d(x, y, 'texture', vertices, indices);
```

Two rendering strategies, and the choice matters for performance:

- **Quad-paired (default).** `buildOrderedIndices(strategy)` precomputes an optimized
  index list that arranges triangles into quad-forming pairs, synthesizing degenerate
  triangles where a triangle has no edge-sharing partner. Strategy is `0` (fast),
  `1` (medium), or `2` (high). You pay the cost once, so use it when topology is stable.
  Toggle with `useOrderedIndices` / `setUseOrderedIndices()` without rebuilding.
- **Raw triangles.** `setRenderAsTriangles(true)` draws through the `BatchHandlerTri`
  render node (`gl.TRIANGLES`). Use this for dynamic topology that cannot be optimized
  into quads — soft-body deformation, procedural terrain that changes per frame.

### `Stencil` — persistent, universal masking

A container whose contents write to the stencil buffer. Unlike v3 stencil masks, these
are persistent and accept *anything that draws pixels* as a source — sprites, filter
output, animated objects.

```typescript
const stencil = this.add.stencil();   // note: `stencilreference` for the re-render object
```

Operating modes: `addLayer`, `subtractLayer`, `clear`, `clearRegion`. Add and subtract
can each be inverted. `StencilReference` re-renders a target `Stencil` with different
settings, which is how you remove or reuse stencil geometry.

Because regular alpha does nothing inside a stencil, `stencilAlphaStrategy` controls
how alpha is handled there — see alpha strategies below.

### `CustomContext` — reach into the DrawingContext

```typescript
const ctx = this.add.customcontext();
```

An advanced container that modifies the `DrawingContext` at render time: toggling
stencil testing, selectively activating alpha strategies, freehand GL scissor
modification. Reach for it when you need renderer behaviour Phaser does not expose
as a property.

### Alpha strategies

New `render.alphaStrategy` game config option, plus per-object control on `Stencil`
and `CustomContext`. Lets shaders use GLSL `discard` instead of alpha:

| Strategy | Behaviour |
|---|---|
| `keep` | Use alpha as normal (default). |
| `dither` | Dither to choose which pixels to discard. |
| `threshold` | Discard every pixel below an alpha threshold. |

`discard` is inefficient — this exists for effects and for stencil work, not as a
general performance lever. Custom shaders must implement it themselves; or route
through compositing with `filtersForceComposite`.

Two related config options landed alongside it: `render.stencil` (disable stencil
buffer creation entirely and save memory) and `render.stencilAlphaStrategy`.

### Cone lights

Standard dynamic lights restricted to a directional cone — flashlights, lantern beams,
vision cones, headlights, searchlights. They run through the existing WebGL lighting
shader, so no mask, no second camera, no rendering the map twice. Any object that
already works with Phaser lighting can be lit by one.

```typescript
this.lights.enable();
const beam = this.lights.addConeLight(
  x, y, radius, 0xffffff, intensity,
  rotation,          // radians, cone direction
  innerAngle,        // radians
  outerAngle,        // radians
);

beam.setConeRotation(angle);
beam.setConeAngles(inner, outer);
beam.disableCone();
```

Properties: `coneEnabled`, `coneRotation`, `coneInnerAngle`, `coneOuterAngle`.
Methods: `setCone()`, `setConeRotation()`, `setConeAngles()`, `disableCone()`.
Full write-up in `node_modules/phaser/docs/Phaser 4 Cone Lights/`.

### Second tint colour

`TintModes.MULTIPLY_TWO` uses a secondary colour per corner, enabling effects like fire
gradients and inversion:

```typescript
sprite.setTint(0xff0000);
sprite.setTint2(0xffff00);   // topLeft, topRight, bottomLeft, bottomRight all optional
```

`Mesh2D` and `Tile` support a constant `tint2`. `TilemapGPULayer` does not support tinting
on tiles at all.

> This changed the shader encoding of tint mode: `inTintEffect` went from a `float` to a
> `vec4`, encoded as four uint8s instead of a float32. Only deep custom render-node code
> is affected.

### Runtime frame-rate control

```typescript
this.game.loop.setFPSLimit(30);
```

Use this rather than assigning `Timestep#fpsLimit` directly — the method updates the
derived properties too.

### Behavioural changes to watch

- `WebGLStencilParametersFactory` now defaults to `enabled: true` and `func: gl.EQUAL`
  (the stencil test passes when the buffer equals 0). Testing showed little performance
  cost from leaving the test on.
- `GameObjects.Components.Filters` adds its RenderStep just before the core render
  method, so other steps can run first.
- `SpriteGPULayer` lost its `Mask` component — it is a WebGL-only object and masking
  was a Canvas feature.

---

## 4.2.1 — Giedi (fixes)

Upgrade if any of these describe a bug you are chasing:

- **`ScaleManager` failed to resize to its parent container** (#7213). If you have a
  workaround for parent-sizing in your bootstrap, this is the release that removed the
  need for it.
- **Tweens with `startDelay` never left `START_DELAY`** for `ACTIVE` (#7093) — they got
  stuck in their initial state even after the delay elapsed.
- **`Stencil`'s `stencilInvert` option** did nothing, due to an alpha bug.
- **Framebuffers now clear stencil correctly** on use.
- **ESM build**: `CombineColorMatrix`, `ImageLight`, and `Texture` no longer reach for
  the global `Phaser` namespace inline, which broke under ESM.
- Docs: `AnimationManager.get()` return type corrected.

---

## Upgrading Within v4

```bash
npm install phaser@latest
node -p "require('phaser/package.json').version"
npx tsc --noEmit
node skills/phaser-playtest/scripts/playtest.mjs --project .
```

The last step is the one that matters. Point-release upgrades do not usually break
compilation — they change rendering and timing behaviour, which only a running game
reveals. Run the playtest before and after so you can attribute any change.

Version-specific actions:

| Moving from | Do this |
|---|---|
| Any `4.0.0-rc.*` | Reinstall from the `latest` tag, not `beta`. Re-verify masking and filter code. |
| 4.0.0 | Switch to `import Phaser from 'phaser'`. Re-check filters on `Layer` objects. |
| 4.1.0 | Review `getPadding()` → `getPaddingCeil()` in custom render nodes. Stencil test is now on by default. |
| 4.2.0 | Straight fix upgrade; no API changes. |

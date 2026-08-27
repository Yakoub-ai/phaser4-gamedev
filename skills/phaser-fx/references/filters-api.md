# Filters API Reference

Every filter available on `filters.internal` and `filters.external` in Phaser 4.2.1,
with real signatures taken from the shipped type definitions.

```typescript
// Game object — must enable first
sprite.enableFilters();
sprite.filters!.internal.addGlow(0xff00ff, 4, 0, 1);

// Camera — filters is always present
this.cameras.main.filters.external.addVignette(0.5, 0.5, 0.5, 0.5);
```

Every `add*` call **returns the filter controller**. Keep it if you plan to animate the
effect — that is how you change it later without adding a second filter.

```typescript
const glow = enemy.filters!.internal.addGlow(0xff0000, 0, 0, 1);
this.tweens.add({ targets: glow, outerStrength: 8, duration: 200, yoyo: true });
```

---

## Blur and depth

```typescript
addBlur(quality?, x?, y?, strength?, color?, steps?)
addBokeh(radius?, amount?, contrast?)
addTiltShift(radius?, amount?, contrast?, blurX?, blurY?, strength?)
addPanoramaBlur(config)
```

`addBlur` quality is a preset level; `x` and `y` are per-axis blur amounts, so
`addBlur(0, 4, 0, 1)` gives a horizontal-only motion blur.

```typescript
// Blur the gameplay behind a pause menu — camera-level, one pass.
this.cameras.main.filters.external.addBlur(1, 3, 3, 1);
```

`addBokeh` and `addTiltShift` both return a `Bokeh` controller — tilt-shift is a
configured bokeh, not a separate shader.

## Glow, shadow and outline

```typescript
addGlow(color?, outerStrength?, innerStrength?, scale?, knockout?, quality?, distance?)
addShadow(x?, y?, decay?, power?, color?, samples?, intensity?)
```

```typescript
// Pickup highlight that pulses.
const glow = coin.filters!.internal.addGlow(0xffdd00, 4, 0, 1);
this.tweens.add({ targets: glow, outerStrength: 8, duration: 600,
                  yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });
```

`knockout: true` keeps only the glow and discards the object — useful for silhouette
effects.

## Colour

```typescript
addColorMatrix()
addCombineColorMatrix(texture?)
addGradientMap(config?)
addQuantize(config?)
addThreshold(edge1?, edge2?, invert?)
addKey(config?)
```

`ColorMatrix` nests its methods on a `colorMatrix` property — this is a change from v3
and is easy to miss:

```typescript
const cm = this.cameras.main.filters.external.addColorMatrix();
cm.colorMatrix.grayscale();      // death screen
cm.colorMatrix.sepia();          // flashback
cm.colorMatrix.night(0.4);       // night level
cm.colorMatrix.brightness(1.2);
cm.colorMatrix.saturate(0.5);
```

To fade to grayscale on death, animate the matrix's own alpha rather than adding and
removing the filter every frame:

```typescript
const cm = this.cameras.main.filters.external.addColorMatrix();
cm.colorMatrix.grayscale(0);
this.tweens.addCounter({ from: 0, to: 1, duration: 800,
  onUpdate: t => cm.colorMatrix.grayscale(t.getValue()) });
```

`addThreshold` takes per-channel arrays as well as scalars, which is how you build
colour-keyed cutouts without a custom shader.

## Distortion

```typescript
addBarrel(amount?)
addDisplacement(texture?, x?, y?)
addPixelate(amount?)
addBlocky(config?)
addWipe(wipeWidth?, direction?, axis?, reveal?, wipeTexture?)
```

```typescript
// Heat haze over a lava level — needs a noise texture loaded as 'noise'.
this.cameras.main.filters.external.addDisplacement('noise', 0.02, 0.02);

// CRT-ish lens curve.
this.cameras.main.filters.external.addBarrel(1.08);
```

`addWipe` is a scene-transition primitive: `reveal` flips it between hiding and
revealing, so the same filter drives both halves of a transition.

## Masking

```typescript
addMask(mask?, invert?, viewCamera?, viewTransform?, scaleFactor?)
```

| Parameter | Meaning |
|---|---|
| `mask` | Texture key, or a GameObject (rendered to a DynamicTexture for you) |
| `invert` | `true` hides where the mask is opaque instead of showing |
| `viewCamera` | Camera used when rendering a GameObject mask; defaults to `main` |
| `viewTransform` | `'local'` uses the object's own transform, `'world'` accounts for `parentContainer`. Default `'world'` |
| `scaleFactor` | Shrinks the mask texture to save memory. Scale the mask source to match |

```typescript
// Spotlight reveal that follows the player.
const hole = this.add.graphics().fillStyle(0xffffff).fillCircle(0, 0, 150);
darkness.enableFilters();
darkness.filters!.internal.addMask(hole, true);   // inverted: dark everywhere but the circle
```

Because a mask source can be any drawing object, animated and filtered masks work — a
mask made from a particle emitter or from another filter's output is legal.

## Blending and compositing

```typescript
addBlend(texture?, blendMode?, amount?, color?)
addParallelFilters()
addSampler(callback, region?)
```

WebGL natively supports only `NORMAL`, `ADD`, `MULTIPLY` and `SCREEN`. `addBlend`
reconstructs the wider Canvas blend-mode set under WebGL — this is the reason the Canvas
renderer's one remaining advantage no longer matters.

`addParallelFilters` runs two chains over the same input and combines them. That is how
composite effects like bloom are built, and it is what `Phaser.Actions.AddEffectBloom()`
uses internally.

`addSampler` reads pixels back with a callback. It is a stall — do not call it per frame.

## Lighting filters

```typescript
addImageLight(config)
addNormalTools(config)
```

Image-based lighting and normal-map manipulation. See `lighting.md`.

## Custom shaders

```typescript
addCustom(...)
```

See `renderer-and-shaders.md`. A custom shader must implement alpha strategy handling
itself; alternatively route it through compositing with `filtersForceComposite` so a
Phaser shader handles it.

---

## Composite effects via Actions

```typescript
Phaser.Actions.AddEffectBloom(target);
Phaser.Actions.AddEffectShine(target);
Phaser.Actions.AddMaskShape(target);
```

These build several filters at once, which is why they are Actions rather than single
`add*` calls. They accept a camera or a game object.

---

## Removing filters

```typescript
sprite.filters!.internal.remove(controller);
sprite.filters!.internal.clear();
sprite.filters!.internal.getActive();     // what is currently running
```

`clear()` is the one to reach for after a transition effect finishes. Leaving a
finished filter attached keeps its framebuffer pass running forever, which reads as a
mysterious constant frame cost rather than as a leak.

---

## Common recipes

**Damage flash** — do *not* use a filter:

```typescript
sprite.setTint(0xffffff).setTintMode(Phaser.TintModes.FILL);
this.time.delayedCall(80, () => sprite.clearTint());
```

A tint stays inside the sprite batch. A white-flash filter costs a full render pass for
80 milliseconds of effect.

**Pause-menu backdrop:**

```typescript
const blur = this.cameras.main.filters.external.addBlur(1, 4, 4, 1);
// on resume:
this.cameras.main.filters.external.remove(blur);
```

**Underwater level:**

```typescript
const cam = this.cameras.main.filters.external;
cam.addDisplacement('caustics', 0.01, 0.01);
const cm = cam.addColorMatrix();
cm.colorMatrix.night(0.2);
```

**Screen-wide hit feedback**, cheaper than a filter — flash a full-screen rectangle:

```typescript
const flash = this.add.rectangle(0, 0, w, h, 0xff0000, 0.4)
  .setOrigin(0).setScrollFactor(0).setDepth(9999);
this.tweens.add({ targets: flash, alpha: 0, duration: 150,
                  onComplete: () => flash.destroy() });
```

Reach for a filter when you need to transform what is *already drawn*. When you only need
to draw something on top, drawing something on top is faster.

---

## Verifying an effect actually renders

A filter that silently fails still type-checks. Prove it with pixels:

```javascript
// playtest/fx-check.mjs
export default [
  { name: 'glow is attached', action: 'expect',
    expect: { expression: `scene('GameScene').player.filters.internal.getActive().length`, atLeast: 1 } },
  { name: 'effects do not cost the frame budget', action: 'sample',
    expression: `game.loop.actualFps`, duration: 3000, interval: 100,
    expect: { stat: 'min', atLeast: 50 } },
  { name: 'with-effects', action: 'screenshot' },
];
```

The frame-rate sample is the important half. Filters are the most common cause of a
frame-rate cliff in an otherwise healthy Phaser 4 game, and the cliff appears only under
load — which a single reading misses and a `sample` catches.

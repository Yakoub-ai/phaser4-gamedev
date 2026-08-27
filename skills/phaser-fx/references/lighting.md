# Lighting in Phaser 4

Dynamic 2D lighting: point lights, cone lights, normal maps, and the performance envelope.
Signatures verified against 4.2.1.

---

## Setup

Three things must all be true or nothing lights up:

```typescript
// 1. The lights manager is enabled for the scene
this.lights.enable().setAmbientColor(0x333333);

// 2. At least one light exists
this.lights.addLight(400, 300, 200, 0xffaa33, 2);

// 3. Each object opts in
this.add.image(x, y, 'wall').setLighting(true);
```

Step 3 is the one people miss. Objects are **not** lit by default; an object without
`setLighting(true)` renders at full brightness and looks wrong next to lit neighbours.

> **From Phaser 3:** `setPipeline('Light2D')` is gone along with the whole pipeline
> system. `setLighting(true)` is its replacement.

**Ambient colour is your floor.** `0x000000` means unlit areas are pure black — dramatic,
and often unplayable. `0x333333` keeps geometry readable. Set it before tuning individual
lights, because every light reads differently against a different floor.

---

## Point lights

```typescript
addLight(x?, y?, radius?, rgb?, intensity?, z?)
```

```typescript
const torch = this.lights.addLight(x, y, 200, 0xffaa33, 2);

// Lights are plain objects — tween them like anything else.
this.tweens.add({ targets: torch, intensity: 2.4, duration: 400,
                  yoyo: true, repeat: -1, ease: 'Sine.easeInOut' });

// Follow the player
this.events.on('update', () => torch.setPosition(player.x, player.y));

this.lights.removeLight(torch);
```

`Light` extends `Geom.Circle`, so `x`, `y` and `radius` behave as you would expect and
`Phaser.Geom` helpers work on it.

### `Light` vs the `PointLight` game object

Two different things with confusingly similar names:

| | `lights.addLight()` | `this.add.pointlight()` |
|---|---|---|
| What it is | A light in the lighting system | A game object that draws a glow |
| Affects other objects | Yes, those with `setLighting(true)` | No |
| Respects normal maps | Yes | No |
| Sits in the display list | No | Yes — has depth, blend mode, scroll factor |
| Use for | Actual illumination | A visible glow: a bulb, a magic orb, a muzzle flash |

They pair well: a `PointLight` for the visible bloom, a `Light` at the same position for
the illumination it casts.

---

## Cone lights (4.2.0+)

Lights restricted to a directional cone: flashlights, lantern beams, vision cones,
headlights, searchlights. They run through the same WebGL lighting shader, so there is
no mask, no second camera, and no rendering the scene twice.

```typescript
addConeLight(x?, y?, radius?, rgb?, intensity?, rotation?, innerAngle?, outerAngle?, z?)
```

```typescript
const flashlight = this.lights.addConeLight(
  player.x, player.y,
  400,         // radius
  0xffffee,    // colour
  3,           // intensity
  0,           // rotation, radians
  0.15,        // inner angle, radians — full brightness within this
  0.5,         // outer angle, radians — falls off to nothing by here
);
```

Aim it at the pointer each frame:

```typescript
update() {
  const p = this.input.activePointer;
  this.flashlight.setPosition(this.player.x, this.player.y);
  this.flashlight.setConeRotation(
    Phaser.Math.Angle.Between(this.player.x, this.player.y, p.worldX, p.worldY));
}
```

Properties and methods:

| | |
|---|---|
| `coneEnabled` | Whether the cone restriction is active |
| `coneRotation` | Direction, radians |
| `coneInnerAngle` | Full-brightness half-angle, radians |
| `coneOuterAngle` | Falloff half-angle, radians |
| `setCone()` | Turn a normal light into a cone light |
| `setConeRotation(r)` | |
| `setConeAngles(inner, outer)` | |
| `disableCone()` | Back to an ordinary point light |

**Inner and outer control the edge.** Equal values give a hard-edged spotlight; a wide gap
gives a soft beam. For a stealth vision cone the hard edge is usually correct — players
need to know exactly where the boundary is.

A flickering torch is `intensity` plus a small `coneOuterAngle` wobble; do not tween the
position, which reads as the light physically shaking rather than flickering.

Full write-up ships with the package at
`node_modules/phaser/docs/Phaser 4 Cone Lights/Phaser 4 Cone Lights.md`.

---

## Normal maps

Normal maps are what make lighting look like lighting rather than a coloured circle
overlay. Without one, a lit sprite is uniformly brightened; with one, the light rakes
across its surface detail.

```typescript
// Loading an image with its normal map
this.load.image({ key: 'wall', url: 'wall.png', normalMap: 'wall_n.png' });

// Atlases can declare `normalMap` per texture entry too.
```

Then light it as usual — the normal map is picked up automatically by objects with
`setLighting(true)`.

Practical notes:

- Normal maps must match their diffuse texture in dimensions and orientation.
- A normal map doubles the texture memory for that asset. Apply them to surfaces the
  player looks at — walls, floors, large props — not to every 16×16 particle.
- Tools: Sprite Illuminator, Laigter (free), or Blender bakes for pre-rendered art.
- `addNormalTools()` (a filter) manipulates normals at runtime — flipping, scaling,
  rotating — which is how you reuse one normal map across mirrored sprites.

---

## Performance

Lighting cost scales with **lights × lit pixels**, not with the number of objects.

- **`maxLights` is fixed at boot.** Set it in the game config; it cannot be changed at
  runtime. Read the current value from `this.lights.maxLights`, and the live count from
  `getLightCount()`.
- **Exceeding the maximum silently drops lights.** They do not error — the farthest ones
  simply stop rendering, which looks like a bug in your light placement. Check
  `getLightCount()` against `maxLights` when lights "randomly" fail to appear.
- **Cull off-screen lights.** A light outside the camera still counts against the budget.
  Remove lights for rooms the player is not in rather than leaving them all live.
- **Ambient light is free.** Raising it and using fewer dynamic lights is almost always
  the right trade on mobile.
- **Cone lights cost the same as point lights.** The cone is a shader-side restriction,
  not an extra pass — so a vision cone is far cheaper than the v3 approaches that used
  masks or a second camera.

---

## Verifying lighting works

Lighting failures are silent and type-check cleanly. Every one of these is a real
outcome: the manager was never enabled, no object opted in, ambient was left at black, or
the light count exceeded the maximum.

```javascript
// playtest/lighting-check.mjs
export default [
  { name: 'lights manager is active', action: 'expect',
    expect: { expression: `scene('GameScene').lights.active`, equals: true } },
  { name: 'lights exist and are within budget', action: 'expect',
    expect: { expression: `scene('GameScene').lights.getLightCount()`, atLeast: 1 } },
  { name: 'not over the light budget', action: 'expect',
    expect: { expression: `scene('GameScene').lights.getLightCount() <= scene('GameScene').lights.maxLights`,
              equals: true } },
  { name: 'lit-scene', action: 'screenshot' },
];
```

The screenshot matters here more than usual. The harness's blank-canvas check treats a
scene showing only its background colour as blank — which is exactly what a scene lit to
`0x000000` ambient with no working lights produces. If that check fails on a lighting
scene, suspect the lighting before suspecting the scene.

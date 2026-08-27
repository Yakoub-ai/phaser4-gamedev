# Particle Recipes

Ready configs for the effects games actually need, with the reasoning behind the numbers
so you can adapt rather than copy. All verified against the Phaser 4.2.1
`ParticleEmitterConfig` type.

Every one assumes a small soft-edged texture (a 32×32 radial gradient blob covers most of
these). Sharp-edged textures read as debris; soft ones read as light and smoke.

---

## Explosion

```typescript
this.add.particles(0, 0, 'flare', {
  speed: { min: 200, max: 400 },
  angle: { min: 0, max: 360 },
  scale: { start: 1.2, end: 0 },
  alpha: { start: 1, end: 0 },
  lifespan: { min: 300, max: 600 },
  blendMode: 'ADD',
  quantity: 30,
  maxParticles: 60,
  emitting: false,
});

// explosion.explode(30, x, y);
```

The `lifespan` range is what stops it looking like a single expanding ring — particles
dying at different times give the ragged edge a real explosion has. High initial speed
with `scale` collapsing to 0 does the rest.

For debris rather than fire, drop `blendMode`, add `gravityY: 600`, and use a chunky
texture.

## Fire

```typescript
this.add.particles(x, y, 'flame', {
  speed: { min: 20, max: 60 },
  angle: { min: 260, max: 280 },        // upward, narrow cone
  scale: { start: 0.8, end: 0 },
  alpha: { start: 0.9, end: 0 },
  tint: [0xffdd00, 0xff8800, 0xff2200],
  lifespan: { min: 600, max: 1000 },
  frequency: 30,
  quantity: 1,
  blendMode: 'ADD',
  maxParticles: 60,
});
```

Angles in Phaser are degrees with 0 pointing right, so **270 is straight up**. The narrow
260–280 cone is what makes it read as a flame rather than a spray.

The three-colour `tint` array picks per particle, which gives the colour variation fire
has without any per-particle code.

## Smoke

```typescript
this.add.particles(x, y, 'smoke', {
  speed: { min: 10, max: 30 },
  angle: { min: 250, max: 290 },
  scale: { start: 0.3, end: 1.5 },      // grows, unlike almost everything else
  alpha: { start: 0.4, end: 0 },
  tint: 0x333333,
  lifespan: 3000,
  frequency: 200,
  quantity: 1,
  maxParticles: 20,
});
```

Smoke is the exception to shrinking particles: it **expands** as it dissipates. Low alpha
at the start matters too — smoke that begins opaque looks like a solid object.

Long lifespan with a slow frequency keeps the count low despite the 3-second life.

## Rain

```typescript
this.add.particles(0, 0, 'raindrop', {
  x: { min: 0, max: 800 },
  y: -20,
  speedY: { min: 400, max: 600 },
  speedX: { min: -40, max: -20 },       // slight slant reads as wind
  scale: { start: 1, end: 1 },
  alpha: 0.5,
  lifespan: 2000,
  frequency: 20,
  quantity: 2,
  maxParticles: 200,
});
```

Add a death zone at ground level so drops stop rather than continuing past the screen:

```typescript
rain.addDeathZone({
  type: 'onEnter',
  source: new Phaser.Geom.Rectangle(0, 580, 800, 40),
});
```

Pair it with a short-lived splash burst at the same y for a noticeably better effect than
either alone.

## Snow

```typescript
this.add.particles(0, 0, 'snowflake', {
  x: { min: 0, max: 800 },
  y: -20,
  speedY: { min: 30, max: 80 },
  speedX: { min: -20, max: 20 },
  scale: { min: 0.2, max: 0.6 },        // varied size = depth
  alpha: { min: 0.4, max: 0.9 },
  rotate: { start: 0, end: 360 },
  lifespan: 8000,
  frequency: 200,
  maxParticles: 100,
});
```

Varying scale *and* alpha together is what creates the sense of depth — small faint flakes
read as distant. Fixed values for either flatten it.

## Hit sparks

```typescript
this.add.particles(0, 0, 'spark', {
  speed: { min: 100, max: 250 },
  angle: { min: 0, max: 360 },
  scale: { start: 0.5, end: 0 },
  lifespan: 250,
  blendMode: 'ADD',
  quantity: 8,
  maxParticles: 40,
  emitting: false,
});
```

Short and sharp. Anything above ~300ms stops reading as an impact and starts reading as
an effect. Eight particles is enough — impact sparks are about timing, not volume.

For a directional hit, narrow the angle around the impact normal:

```typescript
sparks.setEmitterAngle({ min: normalDeg - 40, max: normalDeg + 40 });
sparks.explode(8, x, y);
```

## Blood

```typescript
this.add.particles(0, 0, 'blood', {
  speed: { min: 80, max: 200 },
  angle: { min: 0, max: 360 },
  scale: { start: 0.6, end: 0.1 },
  alpha: { start: 1, end: 0.6 },
  tint: [0xaa0000, 0x880000],
  gravityY: 800,
  lifespan: 600,
  quantity: 12,
  maxParticles: 40,
  bounce: 0.3,
  emitting: false,
});
```

High gravity and a bounce are what separate this from a generic burst. No `blendMode` —
additive blending makes it glow, which is wrong.

## Magic / heal

```typescript
this.add.particles(0, 0, 'sparkle', {
  speed: { min: 20, max: 50 },
  angle: { min: 250, max: 290 },
  scale: { start: 0, end: 0.6 },        // fades IN
  alpha: { start: 0, end: 1 },
  tint: [0x66ffcc, 0x66ccff, 0xffffff],
  lifespan: 1200,
  frequency: 60,
  blendMode: 'ADD',
  maxParticles: 40,
});
```

Reversed `scale` and `alpha` — growing and brightening rather than fading — is what makes
this read as gathering energy rather than dissipation. Combine with an emit zone on a
circle edge for a summoning ring.

## Dust trail

```typescript
this.add.particles(0, 0, 'dust', {
  speed: { min: 10, max: 40 },
  angle: { min: 200, max: 340 },
  scale: { start: 0.4, end: 0 },
  alpha: { start: 0.5, end: 0 },
  tint: 0xccbb99,
  lifespan: 500,
  frequency: 80,
  maxParticles: 30,
  emitting: false,
});

// While running on the ground:
dust.startFollow(player, 0, 16);   // at the feet
dust.start();
// Airborne:
dust.stop();
```

Gate the emitter on the actual state (`body.blocked.down && Math.abs(vx) > threshold`)
rather than running it always. A dust trail that continues mid-jump is a bug players
notice immediately.

## Muzzle flash

```typescript
this.add.particles(0, 0, 'flash', {
  speed: { min: 200, max: 400 },
  scale: { start: 0.6, end: 0 },
  lifespan: 120,
  blendMode: 'ADD',
  quantity: 6,
  maxParticles: 20,
  emitting: false,
});

flash.setEmitterAngle({ min: aimDeg - 15, max: aimDeg + 15 });
flash.explode(6, muzzleX, muzzleY);
```

120ms. A muzzle flash the player can consciously see is too long.

## Confetti

```typescript
this.add.particles(0, 0, 'confetti', {
  x: { min: 0, max: 800 },
  y: -20,
  speedY: { min: 100, max: 300 },
  speedX: { min: -100, max: 100 },
  rotate: { start: 0, end: 720 },
  scale: { min: 0.3, max: 0.7 },
  tint: [0xff0055, 0xffdd00, 0x00ddff, 0x66ff66, 0xff88cc],
  lifespan: 4000,
  frequency: 30,
  quantity: 3,
  gravityY: 150,
  maxParticles: 150,
  stopAfter: 300,                       // celebrates, then stops on its own
});
```

`stopAfter` is the useful part: the emitter retires itself after 300 particles with no
cleanup logic to forget. It is the right tool for any one-shot celebration.

## Projectile trail

```typescript
const trail = this.add.particles(0, 0, 'glow', {
  speed: 0,                             // stay where they are born
  scale: { start: 0.5, end: 0 },
  alpha: { start: 0.8, end: 0 },
  lifespan: 300,
  frequency: 15,
  blendMode: 'ADD',
  maxParticles: 30,
});
trail.startFollow(bullet);
```

`speed: 0` is the trick: particles are dropped at the bullet's position and stay there
while the bullet moves on, so the trail draws itself. `startFollow` rather than manual
positioning is what keeps it continuous at high speeds.

**Destroy the trail with the bullet**, or you leak an emitter per shot:

```typescript
bullet.on('destroy', () => { trail.stop(); this.time.delayedCall(400, () => trail.destroy()); });
```

The delay lets the last particles live out their lifespan instead of vanishing mid-air.

---

## Tuning notes

**Angles are degrees, 0 is right, 270 is up.** The most common particle bug after a
missing `start()` is an effect firing sideways because someone assumed 0 was up.

**`{ min, max }` on `lifespan` beats a single value** for anything explosive. Uniform
lifespans produce a visible synchronised death that reads as artificial.

**`blendMode: 'ADD'` for anything that emits light** — fire, magic, sparks, energy — and
never for anything physical: smoke, blood, dust, debris. Additive blending on a physical
material is the single most common reason a particle effect looks cheap.

**Fade in for gathering, fade out for dissipating.** Reversing `scale`/`alpha` from
`{start: 1, end: 0}` to `{start: 0, end: 1}` is the whole difference between an effect
that reads as energy building and one that reads as an explosion.

**Then check it under load.** Every config here sets `maxParticles`, but the number that
matters is the total across all emitters running at once. Sample it during the busiest
moment in the game, not at rest:

```javascript
{ action: 'sample', expression: `game.loop.actualFps`,
  duration: 5000, interval: 100, expect: { stat: 'min', atLeast: 50 } }
```

# Phaser 4 Easing Reference

Easing functions control the rate of change over the duration of a tween. The right easing function transforms a mechanical interpolation into something that feels physical and intentional.

## How to Read This Reference

Each easing has three variants unless noted:
- `Ease.In` — starts slow, ends fast (accelerates)
- `Ease.Out` — starts fast, ends slow (decelerates)
- `Ease.InOut` — slow start, fast middle, slow end (symmetric)

Pass the string name to the `ease` property in any tween config:

```typescript
this.tweens.add({ targets: sprite, y: 300, duration: 500, ease: 'Back.Out' });
```

---

## All Built-In Easing Functions

### Linear

| String | Effect |
|--------|--------|
| `'Linear'` | Constant speed, no acceleration. |

Mathematically: `f(t) = t`

**Use for:** progress bars, health bar drains, scrolling text, mechanical/robotic movement. Avoid for anything organic — it looks unnatural in isolation.

---

### Quadratic (Quad)

| String | Effect |
|--------|--------|
| `'Quad.In'` | Slow start, accelerates. |
| `'Quad.Out'` | Fast start, decelerates smoothly. |
| `'Quad.InOut'` | Symmetric slow-fast-slow. |

**Use for:**
- `Quad.Out` — the most natural-feeling general-purpose ease. Use it for almost any object movement: characters stopping, items falling into place, UI panels sliding in.
- `Quad.In` — objects winding up or falling from rest. Throwing animations, gravity before peak velocity.
- `Quad.InOut` — camera pans, smooth transitions where start and end symmetry matters.

---

### Cubic

| String | Effect |
|--------|--------|
| `'Cubic.In'` | Accelerates more aggressively than Quad. |
| `'Cubic.Out'` | Decelerates more sharply than Quad. |
| `'Cubic.InOut'` | More pronounced S-curve than Quad.InOut. |

**Use for:** Fast UI animations where Quad feels too gentle. Cubic.Out gives a snappier deceleration on short durations (< 300ms).

---

### Quartic (Quart)

| String | Effect |
|--------|--------|
| `'Quart.In'` | Very slow start, sudden end. |
| `'Quart.Out'` | Very fast start, gradual stop. |
| `'Quart.InOut'` | Near-instant start and stop with a flat fast middle. |

**Use for:** Flash/impact animations where you want the object to arrive suddenly. Damage numbers, hit reactions.

---

### Quintic (Quint)

| String | Effect |
|--------|--------|
| `'Quint.In'` | Extreme slow start. |
| `'Quint.Out'` | Extreme fast start, long deceleration tail. |
| `'Quint.InOut'` | Very flat fast middle, aggressive ends. |

**Use for:** Same scenarios as Quart but more extreme. Use sparingly — on longer durations it can feel like the animation is frozen at the start or end.

---

### Sine

| String | Effect |
|--------|--------|
| `'Sine.In'` | Gentle acceleration following a sine curve. |
| `'Sine.Out'` | Gentle deceleration. |
| `'Sine.InOut'` | Very smooth S-curve. |

**Use for:** Breathing animations, ambient floating/bobbing, subtle hover effects. The gentlest curve family — good when you want motion that is barely noticeable but present. Also good for continuous yoyo animations where abrupt direction reversal would look jarring.

---

### Exponential (Expo)

| String | Effect |
|--------|--------|
| `'Expo.In'` | Nearly no movement for most of duration, then instant snap to end. |
| `'Expo.Out'` | Instant burst, then very long deceleration tail. |
| `'Expo.InOut'` | Two-phase: instant burst at the midpoint. |

**Use for:** `Expo.Out` works well for notification popups or tooltip slides where you want immediate presence with a long settling tail. Feels "snappy" on short durations (< 200ms).

---

### Circular (Circ)

| String | Effect |
|--------|--------|
| `'Circ.In'` | Slow start, very fast finish. |
| `'Circ.Out'` | Very fast start, sudden stop. |
| `'Circ.InOut'` | Follows a circular arc (fast middle, abrupt ends). |

**Use for:** Pendulum and arc-based movement. `Circ.Out` gives a sharp stop that can convey a hard landing or collision impact.

---

### Back

| String | Effect |
|--------|--------|
| `'Back.In'` | Pulls back slightly before moving forward (anticipation). |
| `'Back.Out'` | Overshoots the target then settles back. |
| `'Back.InOut'` | Both pull-back on start and overshoot on end. |

The overshoot amount is controlled by `easeParams`:

```typescript
// Default overshoot is 1.70158. Higher = more overshoot.
this.tweens.add({ targets: panel, y: 200, ease: 'Back.Out', easeParams: [3] });
```

**Use for:**
- `Back.Out` — UI elements sliding into view (dialog boxes, menus, buttons), collectible pop-ins, icon animations. The overshoot communicates energy and makes the destination feel like it was "reached".
- `Back.In` — preparing to launch a projectile, character crouch before jump (if done as a tween rather than animation).

---

### Bounce

| String | Effect |
|--------|--------|
| `'Bounce.In'` | Bounces at the start before committing to the movement. |
| `'Bounce.Out'` | Object arrives and bounces at the destination. |
| `'Bounce.InOut'` | Bounces at both start and end. |

**Use for:**
- `Bounce.Out` — objects hitting the ground, dropping items, characters landing after a jump, error feedback (dialog box shaking to indicate invalid input). The bounce simulates physical impact.
- Avoid `Bounce.InOut` in most cases — it looks strange for non-physical scenarios.

---

### Elastic

| String | Effect |
|--------|--------|
| `'Elastic.In'` | Oscillates backward before springing forward. |
| `'Elastic.Out'` | Springs past target, oscillates, settles. |
| `'Elastic.InOut'` | Spring oscillation centered on midpoint. |

Control amplitude and period:

```typescript
// easeParams[0] = amplitude (default: 1), easeParams[1] = period (default: 0.3)
// Smaller period = faster oscillation
this.tweens.add({ targets: icon, scaleX: 1, ease: 'Elastic.Out', easeParams: [1, 0.4] });
```

**Use for:**
- `Elastic.Out` — comic or playful UI effects, achievement popups, spring-loaded UI elements, rubber-band snapping. The oscillation conveys physical springiness.
- Not appropriate for anything that should feel weighty or serious.

---

### Stepped

```typescript
// Steps to discrete positions
this.tweens.add({ targets: sprite, x: 400, ease: 'Stepped', easeParams: [5] });
// easeParams[0] = number of steps
```

**Use for:** Retro/pixel-art animations where you want snapping between discrete positions rather than smooth interpolation. Progress bar with discrete segments.

---

## Quick Selection Guide

| Goal | Recommended Ease |
|------|-----------------|
| Natural object movement (most cases) | `Quad.Out` |
| Object sliding to a stop | `Quad.Out` or `Cubic.Out` |
| Object speeding up (launching) | `Quad.In` |
| Camera pan | `Quad.InOut` |
| UI panel slide in | `Back.Out` |
| Popup / dialog appear | `Back.Out` |
| Object hitting ground | `Bounce.Out` |
| Springy/comic UI element | `Elastic.Out` |
| Fade in / fade out | `Linear` or `Sine.InOut` |
| Health bar draining | `Linear` |
| Ambient floating / bobbing | `Sine.InOut` (yoyo) |
| Snappy notification | `Expo.Out` |
| Error shake | `Bounce.Out` or custom |
| Mechanical / robotic | `Linear` |

---

## Code Examples

### 1. Coin Pickup (Scale + Fade)

A coin collected by the player scales up and fades out, conveying satisfying collection feedback.

```typescript
private collectCoin(coin: Phaser.Physics.Arcade.Sprite): void {
  coin.disableBody(true, false);   // disable physics, keep visible

  this.tweens.add({
    targets:  coin,
    scaleX:   1.6,
    scaleY:   1.6,
    alpha:    0,
    y:        coin.y - 20,         // drift slightly upward
    duration: 400,
    ease:     'Quad.Out',
    onComplete: () => coin.destroy(),
  });

  // Score text pop
  const txt = this.add.text(coin.x, coin.y - 10, '+10', {
    fontSize: '20px', color: '#ffcc00',
  }).setOrigin(0.5);

  this.tweens.add({
    targets:  txt,
    y:        txt.y - 40,
    alpha:    0,
    duration: 700,
    ease:     'Quad.Out',
    onComplete: () => txt.destroy(),
  });
}
```

---

### 2. Damage Number Float Up

Floating combat text rises and fades for readable damage feedback.

```typescript
private showDamage(x: number, y: number, amount: number): void {
  const dmgText = this.add.text(x, y, `-${amount}`, {
    fontSize: '24px',
    color:    '#ff4444',
    stroke:   '#000000',
    strokeThickness: 3,
  }).setOrigin(0.5).setDepth(10);

  this.tweens.add({
    targets:  dmgText,
    y:        y - 60,
    alpha:    0,
    scaleX:   1.4,
    scaleY:   1.4,
    duration: 900,
    ease:     'Quart.Out',    // fast rise, long float
    delay:    100,            // tiny delay so it appears after the hit flash
    onComplete: () => dmgText.destroy(),
  });
}
```

---

### 3. Screen Shake Alternative (Tween-Based Camera Shake)

A tween-driven camera nudge for hits or explosions. Alternative to `this.cameras.main.shake()` when you want more control over the feel.

```typescript
private screenPunch(intensity: number = 8, duration: number = 300): void {
  const cam = this.cameras.main;
  const origX = cam.scrollX;
  const origY = cam.scrollY;

  this.tweens.timeline({
    tweens: [
      { targets: cam, scrollX: origX + intensity, scrollY: origY - intensity * 0.5, duration: duration * 0.15, ease: 'Linear' },
      { targets: cam, scrollX: origX - intensity * 0.7, scrollY: origY + intensity * 0.3, duration: duration * 0.2, ease: 'Linear' },
      { targets: cam, scrollX: origX + intensity * 0.4, scrollY: origY - intensity * 0.2, duration: duration * 0.2, ease: 'Linear' },
      { targets: cam, scrollX: origX - intensity * 0.2, scrollY: origY + intensity * 0.1, duration: duration * 0.2, ease: 'Linear' },
      { targets: cam, scrollX: origX,                   scrollY: origY,                   duration: duration * 0.25, ease: 'Quad.Out' },
    ],
  });
}
```

---

### 4. Menu Item Slide In (Staggered)

Each menu item slides in from the right with a small delay between items, using `Back.Out` for the overshoot that gives UI elements a sense of weight.

```typescript
create(): void {
  const menuItems = ['Play', 'Options', 'Credits', 'Quit'];
  const startX = this.scale.width + 200;   // off-screen right

  menuItems.forEach((label, i) => {
    const targetX = this.scale.width / 2;
    const y = 250 + i * 70;

    const btn = this.add.text(startX, y, label, {
      fontSize: '32px', color: '#ffffff',
    }).setOrigin(0.5).setInteractive();

    this.tweens.add({
      targets:  btn,
      x:        targetX,
      duration: 500,
      ease:     'Back.Out',
      delay:    i * 80,         // stagger by 80ms per item
    });
  });
}
```

---

### 5. Health Bar Drain

Smooth health bar update with a fast-drain red background bar trailing behind the green current health. The red bar uses `Linear` for a measured, readable drain.

```typescript
private updateHealthBar(currentHp: number, maxHp: number): void {
  const targetWidth = (currentHp / maxHp) * this.barMaxWidth;

  // Snap green bar to new value immediately (or tween it slightly)
  this.tweens.add({
    targets:  this.greenBar,
    displayWidth: targetWidth,
    duration: 150,
    ease:     'Quad.Out',
  });

  // Delay red (damage) bar so it lingers then drains smoothly
  this.tweens.killTweensOf(this.redBar);
  this.tweens.add({
    targets:  this.redBar,
    displayWidth: targetWidth,
    duration: 600,
    ease:     'Linear',
    delay:    350,             // wait for green bar to snap, then drain
  });
}
```

Setup for the health bar:

```typescript
create(): void {
  this.barMaxWidth = 200;

  // Red (damage trail) bar behind green bar
  this.redBar = this.add.rectangle(20, 20, this.barMaxWidth, 16, 0xcc2222)
    .setOrigin(0, 0.5);
  // Green (current hp) bar on top
  this.greenBar = this.add.rectangle(20, 20, this.barMaxWidth, 16, 0x22cc44)
    .setOrigin(0, 0.5);
}
```

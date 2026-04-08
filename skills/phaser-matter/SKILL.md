---
name: phaser-matter
description: This skill should be used when the user asks to "Matter physics", "realistic physics", "polygon collision", "joints", "constraints", "complex physics shapes", "Matter.js", "ragdoll", "hinge joint", "compound body", "physics sensor", etc.
version: 0.2.0
---

# Phaser 4 Matter Physics

Matter.js is Phaser's second built-in physics engine. Use it when Arcade Physics can't meet your needs — specifically for non-rectangular collision shapes, real physics constraints, or ragdoll-style simulations.

## Arcade vs Matter — When to Use Which

**Arcade Physics** (default choice):
- AABB collision only: rectangles and circles
- Simple hitboxes, excellent performance
- `body.blocked.down` for ground detection
- Covers 95% of 2D games

**Matter Physics** (when you need it):
- Convex polygon shapes and complex concave bodies
- Compound bodies (multiple shapes welded together)
- Realistic constraints: hinges, springs, distance rods
- Ragdoll physics and destructible objects
- Sensor zones with physics-accurate collision events

**Rule:** Default to Arcade. Switch to Matter only when you need non-rectangular collision shapes or real joints.

## Enabling Matter Physics

```typescript
// In GameConfig:
const config: Phaser.Types.Core.GameConfig = {
  physics: {
    default: 'matter',
    matter: {
      gravity: { x: 0, y: 1 },  // normalized: 1 = earth-like downward pull
      debug: false,               // true renders wireframes — essential during development
    },
  },
};
```

Set `debug: true` during development. Matter's wireframe overlay shows exactly what shape each body has, which offsets are applied, and where constraints attach.

## Creating Bodies

### Rectangle (default)

```typescript
// matter.add.image creates a MatterImage (static by default if you call .setStatic)
const box = this.matter.add.image(x, y, 'box');
```

### Circle

```typescript
const ball = this.matter.add.image(x, y, 'ball').setCircle(radius);
// Optional: pass options as second arg to setCircle
const ball2 = this.matter.add.image(x, y, 'ball').setCircle(32, { restitution: 0.8 });
```

### Convex Polygon

```typescript
const hex = this.matter.add.image(x, y, 'hex')
  .setBody({ type: 'polygon', sides: 6, radius: 30 });
```

### Custom Vertices (fromVertices)

```typescript
// Vertices defined as array of {x,y} relative to body center
const verts = [{ x: 0, y: -30 }, { x: 20, y: 10 }, { x: -20, y: 10 }];
const arrow = this.matter.add.image(x, y, 'arrow')
  .setBody({ type: 'fromVertices', verts: verts });
```

Note: Matter decomposes concave polygons into convex parts automatically via `poly-decomp`. Ensure your vertices are wound consistently (clockwise or counter-clockwise).

### Compound Body (multiple shapes as one body)

```typescript
// Use matter.bodies to build parts, then merge into a compound
const Body    = (this.matter as any).body as typeof MatterJS.Body;
const Bodies  = (this.matter as any).bodies as typeof MatterJS.Bodies;

const torso  = Bodies.rectangle(x, y, 30, 50);
const head   = Bodies.circle(x, y - 40, 15);
const compound = Body.create({ parts: [torso, head] });

const player = this.matter.add.image(x, y, 'player').setExistingBody(compound);
```

### Static Body (immovable)

```typescript
const ground = this.matter.add.image(x, y, 'ground').setStatic(true);
// Or create a static rectangle directly:
this.matter.add.rectangle(x, y, width, height, { isStatic: true });
```

## Body Properties

All property setters return the MatterGameObject for chaining.

```typescript
const body = this.matter.add.image(x, y, 'crate');

body.setFriction(0.1);        // surface friction: 0 = ice, 1 = very sticky
body.setFrictionAir(0.05);    // air resistance / velocity damping per step
body.setFrictionStatic(0.5);  // static friction (resistance to starting motion)
body.setRestitution(0.8);     // bounciness: 0 = no bounce, 1 = perfect elastic
body.setMass(5);              // kilograms — affects momentum transfer
body.setDensity(0.002);       // alternative to setMass; mass derived from area
body.setIgnoreGravity(true);  // float independent of world gravity
body.setFixedRotation();      // prevent rotation (essential for player characters!)
body.setSensor(true);         // passes through objects but still fires collision events
body.setVelocity(vx, vy);     // teleport velocity (px/frame, not px/sec like Arcade)
body.setAngularVelocity(0.1); // spin speed in radians per step
```

**Critical for platform games:** Always call `setFixedRotation()` on your player body. Without it, the capsule-shaped body rolls and tips over on contact with surfaces.

**Air friction guideline:** `0.01` = floaty/space, `0.05` = normal, `0.15` = heavy/sluggish.

## Applying Forces

```typescript
// Apply force at body center (world coordinates)
// Force is a vector in Matter units (very small numbers — tune empirically)
this.matter.applyForce(body.body as MatterJS.Body, { x: 0.01, y: -0.05 });

// Apply force at an offset point (creates torque)
this.matter.applyForceFromPosition(body.body as MatterJS.Body,
  { x: body.x + 10, y: body.y },
  { x: 0, y: -0.03 }
);
```

For impulse-style movement (jump, knockback), set velocity directly rather than applying force:

```typescript
body.setVelocity(0, -10); // instant upward jump
```

## Collision Detection

Matter uses a global collision event on the world, not per-body callbacks.

```typescript
// collisionstart fires once when two bodies begin touching
this.matter.world.on(
  'collisionstart',
  (event: Phaser.Physics.Matter.Events.CollisionStartEvent) => {
    event.pairs.forEach(pair => {
      const { bodyA, bodyB } = pair;
      const objA = bodyA.gameObject as Phaser.Physics.Matter.Image | null;
      const objB = bodyB.gameObject as Phaser.Physics.Matter.Image | null;
      if (objA && objB) {
        // Both bodies have Phaser game objects attached
        console.log('Collision:', objA.texture.key, 'hit', objB.texture.key);
      }
    });
  }
);

// collisionactive fires every step while bodies remain touching
this.matter.world.on('collisionactive', (event) => { /* ... */ });

// collisionend fires once when bodies separate
this.matter.world.on('collisionend', (event) => { /* ... */ });
```

Compound bodies: each part is a separate Matter body. `bodyA.gameObject` will be `null` for sub-parts; only the compound root body has the `gameObject` reference.

## Collision Filtering (Categories and Masks)

Control which objects collide with which using bitmask categories.

```typescript
// Define categories as powers of 2 (bitmask flags)
const CAT_PLAYER = 0x0001;
const CAT_ENEMY  = 0x0002;
const CAT_BULLET = 0x0004;
const CAT_WALL   = 0x0008;
const CAT_PICKUP = 0x0010;

// Player: collides with enemies and walls; own bullets pass through
player.setCollisionCategory(CAT_PLAYER);
player.setCollidesWith([CAT_ENEMY, CAT_WALL]);

// Enemy: collides with player, walls, and bullets
enemy.setCollisionCategory(CAT_ENEMY);
enemy.setCollidesWith([CAT_PLAYER, CAT_BULLET, CAT_WALL]);

// Bullet: hits enemies and walls, not the player who fired it
bullet.setCollisionCategory(CAT_BULLET);
bullet.setCollidesWith([CAT_ENEMY, CAT_WALL]);

// Pickup (coin/health): only player can collect it
pickup.setCollisionCategory(CAT_PICKUP);
pickup.setCollidesWith([CAT_PLAYER]);
```

Maximum 32 categories per world. Use the collision filter `group` property for objects that should never collide with each other regardless of masks (e.g., all enemy bodies in a group share a negative group ID to skip self-collision).

## Sensors (Trigger Zones)

Sensors detect overlaps without applying physics response — useful for checkpoints, damage zones, aggro radii.

```typescript
// Sensor rectangle (static)
const zone = this.matter.add.rectangle(x, y, width, height, {
  isSensor: true,
  isStatic: true,
  label: 'checkpoint-zone',  // label helps identify bodies in collision events
});

// Detect entries
this.matter.world.on('collisionstart', (event) => {
  event.pairs.forEach(pair => {
    const labels = [pair.bodyA.label, pair.bodyB.label];
    if (labels.includes('checkpoint-zone')) {
      const other = pair.bodyA.label === 'checkpoint-zone' ? pair.bodyB : pair.bodyA;
      if (other.gameObject) {
        // Player entered the zone
      }
    }
  });
});
```

## Constraints (Joints)

Constraints connect two bodies (or a body to a fixed world point) with a rod, spring, or hinge.

```typescript
// Distance constraint — rigid rod between two bodies
const rod = this.matter.add.constraint(
  bodyA.body as MatterJS.Body,
  bodyB.body as MatterJS.Body,
  100,    // target length (pixels)
  0.9     // stiffness: 1 = perfectly rigid, 0.01 = very springy
);

// Spring constraint — same but low stiffness
const spring = this.matter.add.constraint(
  bodyA.body as MatterJS.Body,
  bodyB.body as MatterJS.Body,
  80,     // rest length
  0.02    // stiffness (spring-like)
  // Note: damping defaults to 0; set options.damping to prevent oscillation
);

// Pin constraint — hinge a body to a fixed world point
const hinge = this.matter.add.worldConstraint(
  pendulum.body as MatterJS.Body,
  0,     // length 0 = pivot at the anchor point
  1,     // stiffness
  {
    pointA: { x: 400, y: 100 },  // fixed world position
    pointB: { x: 0, y: -40 },    // offset on the body (pivot attachment)
  }
);
```

### Constraint Options

```typescript
interface MatterConstraintConfig {
  bodyA?: MatterJS.Body;
  bodyB?: MatterJS.Body;
  pointA?: { x: number; y: number };  // attachment offset on bodyA
  pointB?: { x: number; y: number };  // attachment offset on bodyB
  length?: number;       // rest length; null = current distance
  stiffness?: number;    // 0.01–1
  damping?: number;      // 0–1, reduces oscillation; 0.1 is a good starting point
  label?: string;
}
```

## Removing Bodies and Constraints

```typescript
// Destroy a Matter game object (removes body from world automatically)
sprite.destroy();

// Remove a constraint
this.matter.world.removeConstraint(rod);

// Remove a raw MatterJS body (not a game object)
this.matter.world.remove(rawBody);
```

## Platform Games with Matter

Matter platformers need extra care because `body.blocked.down` does not exist in Matter — use collision events instead.

```typescript
class Player extends Phaser.Physics.Matter.Sprite {
  private onGround = false;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene.matter.world, x, y, 'player');
    scene.add.existing(this);
    this.setFixedRotation();        // prevent capsule rolling
    this.setFrictionAir(0.05);
    this.setCollisionCategory(0x0001);

    // Track ground contact via sensor at feet
    const sensor = (scene.matter as any).bodies.rectangle(0, 20, 20, 4, { isSensor: true });
    const compound = (scene.matter as any).body.create({
      parts: [this.body, sensor],
    });
    this.setExistingBody(compound, true);

    scene.matter.world.on('collisionstart', (ev: any) => {
      ev.pairs.forEach((p: any) => {
        if (p.bodyA === sensor || p.bodyB === sensor) this.onGround = true;
      });
    });
    scene.matter.world.on('collisionend', (ev: any) => {
      ev.pairs.forEach((p: any) => {
        if (p.bodyA === sensor || p.bodyB === sensor) this.onGround = false;
      });
    });
  }

  jump(): void {
    if (this.onGround) this.setVelocityY(-10);
  }
}
```

## World Configuration

```typescript
// Pause/resume simulation
this.matter.world.pause();
this.matter.world.resume();

// Change gravity at runtime
this.matter.world.setGravity(0, 2);  // doubled gravity
this.matter.world.setGravity(0, 0);  // zero-g

// Run one manual step (useful for deterministic replays)
this.matter.world.step(16.666);  // ms per step

// Set world bounds (creates static boundary bodies)
this.matter.world.setBounds(0, 0, worldWidth, worldHeight);
```

## Debug Rendering

```typescript
// Enable debug wireframes in config (recommended during development):
matter: { debug: true }

// Or toggle at runtime:
this.matter.world.drawDebug = !this.matter.world.drawDebug;
// Re-create the debug renderer if toggling on after init:
this.matter.world.createDebugGraphic();
```

## Additional Resources

### Reference Files
- **`references/matter-api.md`** — Complete MatterPhysics plugin methods, MatterGameObject mixin, MatterJS.Body statics, constraint options, collision event structure, CollisionFilter interface

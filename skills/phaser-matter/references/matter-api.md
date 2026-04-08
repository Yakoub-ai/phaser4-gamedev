# Matter Physics API Reference

Complete API reference for Phaser 4's Matter Physics integration.

---

## MatterPhysics Plugin (`this.matter`)

Accessed via `this.matter` inside any scene. The plugin wraps the MatterJS engine and exposes factory methods and world control.

### Factory Methods — `this.matter.add`

#### Images and Sprites

```typescript
// Create a MatterImage (static by default; pass options to configure body)
this.matter.add.image(x: number, y: number, key: string, frame?: string | number, options?: MatterBodyConfig): Phaser.Physics.Matter.Image

// Create a MatterSprite (like MatterImage, but supports animations)
this.matter.add.sprite(x: number, y: number, key: string, frame?: string | number, options?: MatterBodyConfig): Phaser.Physics.Matter.Sprite
```

#### Primitive Shapes (raw MatterJS bodies — no Phaser game object)

```typescript
this.matter.add.rectangle(x: number, y: number, width: number, height: number, options?: MatterBodyConfig): MatterJS.BodyType

this.matter.add.circle(x: number, y: number, radius: number, options?: MatterBodyConfig, maxSides?: number): MatterJS.BodyType

this.matter.add.polygon(x: number, y: number, sides: number, radius: number, options?: MatterBodyConfig): MatterJS.BodyType

this.matter.add.trapezoid(x: number, y: number, width: number, height: number, slope: number, options?: MatterBodyConfig): MatterJS.BodyType

// Create body from vertices array
this.matter.add.fromVertices(x: number, y: number, vertexSets: MatterJS.Vector[] | string, options?: MatterBodyConfig, flagInternal?: boolean, removeCollinear?: number, minimumArea?: number): MatterJS.BodyType

// Attach an existing MatterJS body to a Phaser game object
this.matter.add.gameObject(gameObject: Phaser.GameObjects.GameObject, options?: MatterBodyConfig | MatterJS.BodyType): Phaser.Physics.Matter.Image | Phaser.Physics.Matter.Sprite
```

#### Constraints

```typescript
// Constraint between two bodies
this.matter.add.constraint(
  bodyA: MatterJS.BodyType,
  bodyB: MatterJS.BodyType,
  length?: number,        // rest length; undefined = current distance
  stiffness?: number,     // 0.01–1; default 1
  options?: Partial<MatterConstraintConfig>
): MatterJS.ConstraintType

// Constraint pinning a body to a fixed world point
this.matter.add.worldConstraint(
  body: MatterJS.BodyType,
  length?: number,
  stiffness?: number,
  options?: Partial<MatterConstraintConfig>
): MatterJS.ConstraintType

// Spring (same as constraint but typically low stiffness + damping)
this.matter.add.spring(
  bodyA: MatterJS.BodyType,
  bodyB: MatterJS.BodyType,
  length?: number,
  stiffness?: number,
  options?: Partial<MatterConstraintConfig>
): MatterJS.ConstraintType

// Pointer constraint — connect mouse/pointer to a body
this.matter.add.pointerConstraint(options?: object): MatterJS.ConstraintType
```

#### Joints (alias helpers)

```typescript
this.matter.add.joint(bodyA, bodyB, length, stiffness, options)   // alias for constraint
this.matter.add.pin(bodyA, bodyB, options)                         // stiff short constraint (hinge)
```

### Force Methods

```typescript
// Apply a force to a body at its center
this.matter.applyForce(body: MatterJS.BodyType, force: MatterJS.Vector): void

// Apply a force at a specific world position (creates torque if offset from center)
this.matter.applyForceFromPosition(body: MatterJS.BodyType, position: MatterJS.Vector, force: MatterJS.Vector): void

// Apply force from local angle (degrees) at given speed
this.matter.applyForceFromAngle(body: MatterJS.BodyType, speed: number, angle: number): void
```

### Removal

```typescript
this.matter.world.remove(body: MatterJS.BodyType | MatterJS.ConstraintType, deep?: boolean): void
this.matter.world.removeConstraint(constraint: MatterJS.ConstraintType, deep?: boolean): void
```

---

## World Control (`this.matter.world`)

```typescript
// Pause / resume physics simulation
this.matter.world.pause(): this
this.matter.world.resume(): this

// Change world gravity
this.matter.world.setGravity(x?: number, y?: number, scale?: number): this

// Set world bounds (creates static boundary bodies)
this.matter.world.setBounds(x?: number, y?: number, width?: number, height?: number, thickness?: number, left?: boolean, right?: boolean, top?: boolean, bottom?: boolean): this

// Step the simulation manually (useful for replays/deterministic simulations)
this.matter.world.step(delta?: number): void

// Debug rendering
this.matter.world.drawDebug: boolean
this.matter.world.createDebugGraphic(): Phaser.GameObjects.Graphics
this.matter.world.debugGraphic: Phaser.GameObjects.Graphics

// Events
this.matter.world.on('collisionstart', callback)
this.matter.world.on('collisionactive', callback)
this.matter.world.on('collisionend', callback)
this.matter.world.on('beforeupdate', callback)
this.matter.world.on('afterupdate', callback)
```

---

## MatterGameObject Mixin Methods

These methods are mixed into both `Phaser.Physics.Matter.Image` and `Phaser.Physics.Matter.Sprite`. All return `this` for chaining.

### Body Shape

```typescript
setRectangle(width: number, height: number, options?: MatterBodyConfig): this
setCircle(radius: number, options?: MatterBodyConfig): this
setPolygon(radius: number, sides: number, options?: MatterBodyConfig): this
setTrapezoid(width: number, height: number, slope: number, options?: MatterBodyConfig): this
setExistingBody(body: MatterJS.BodyType, addToWorld?: boolean): this
setBody(config: string | MatterBodyConfig, options?: MatterBodyConfig): this
```

### Body Properties

```typescript
setBounce(value: number): this               // 0–1; alias for setRestitution
setCollisionCategory(value: number): this    // bitmask category (power of 2)
setCollidesWith(categories: number | number[]): this  // bitmask mask
setCollisionGroup(value: number): this       // positive = always collide; negative = never collide
setDensity(value: number): this
setFriction(value: number, air?: number, fstatic?: number): this
setFrictionAir(value: number): this
setFrictionStatic(value: number): this
setIgnoreGravity(value: boolean): this
setMass(value: number): this
setRestitution(value: number): this
setSensor(value: boolean): this
setSlop(value: number): this                 // collision slop tolerance (default 0.05)
setStatic(value: boolean): this
setFixedRotation(): this                     // prevents angular velocity
setAngularVelocity(value: number): this
setVelocity(x: number, y?: number): this
setVelocityX(x: number): this
setVelocityY(y: number): this
```

### Body Information

```typescript
readonly isSensor(): boolean
readonly isStatic(): boolean
```

---

## MatterJS.Body Static Methods

Access via the raw MatterJS API (available through `Phaser.Physics.Matter.Matter.Body`).

```typescript
const { Body } = Phaser.Physics.Matter.Matter;

// Teleport
Body.setPosition(body: MatterJS.BodyType, position: MatterJS.Vector): void
Body.setAngle(body: MatterJS.BodyType, angle: number): void   // radians

// Velocity
Body.setVelocity(body: MatterJS.BodyType, velocity: MatterJS.Vector): void
Body.setAngularVelocity(body: MatterJS.BodyType, velocity: number): void

// Mass
Body.setMass(body: MatterJS.BodyType, mass: number): void
Body.setDensity(body: MatterJS.BodyType, density: number): void

// Apply force
Body.applyForce(body: MatterJS.BodyType, position: MatterJS.Vector, force: MatterJS.Vector): void

// Scale
Body.scale(body: MatterJS.BodyType, scaleX: number, scaleY: number, point?: MatterJS.Vector): void

// Translate
Body.translate(body: MatterJS.BodyType, translation: MatterJS.Vector): void

// Rotate
Body.rotate(body: MatterJS.BodyType, rotation: number, point?: MatterJS.Vector): void

// Create compound body from parts
Body.create(options: { parts: MatterJS.BodyType[]; [key: string]: any }): MatterJS.BodyType
```

---

## MatterJS.Bodies Static Methods (Shape Factories)

```typescript
const { Bodies } = Phaser.Physics.Matter.Matter;

Bodies.rectangle(x: number, y: number, width: number, height: number, options?: MatterBodyConfig): MatterJS.BodyType

Bodies.circle(x: number, y: number, radius: number, options?: MatterBodyConfig, maxSides?: number): MatterJS.BodyType

Bodies.polygon(x: number, y: number, sides: number, radius: number, options?: MatterBodyConfig): MatterJS.BodyType

Bodies.trapezoid(x: number, y: number, width: number, height: number, slope: number, options?: MatterBodyConfig): MatterJS.BodyType

Bodies.fromVertices(x: number, y: number, vertexSets: MatterJS.Vector[] | MatterJS.Vector[][], options?: MatterBodyConfig, flagInternal?: boolean, removeCollinear?: number, minimumArea?: number): MatterJS.BodyType
```

---

## MatterBodyConfig Interface

Options object passed to most body creation methods.

```typescript
interface MatterBodyConfig {
  // Identity
  label?: string;           // debug name, useful for identifying bodies in collision events

  // Physics properties
  isStatic?: boolean;       // immovable; default false
  isSensor?: boolean;       // no physics response but fires collision events; default false
  restitution?: number;     // bounciness 0–1; default 0
  friction?: number;        // surface friction 0–1; default 0.1
  frictionAir?: number;     // air damping 0–1; default 0.01
  frictionStatic?: number;  // static friction 0–1; default 0.5
  mass?: number;            // kg
  density?: number;         // mass per area (overrides mass if set)
  slop?: number;            // collision tolerance; default 0.05
  timeScale?: number;       // local time multiplier; 1 = normal, 0.5 = slow motion

  // Initial state
  angle?: number;           // initial angle in radians
  velocity?: { x: number; y: number };
  angularVelocity?: number;

  // Collision filtering
  collisionFilter?: CollisionFilter;

  // Constraint attachments (advanced)
  plugin?: object;
}
```

---

## CollisionFilter Interface

```typescript
interface CollisionFilter {
  category?: number;  // bitmask — which category this body belongs to (power of 2, 1–2^31)
  mask?: number;      // bitmask — which categories this body collides with
  group?: number;     // positive: always collide with same group; negative: never collide
}

// Example:
const filter: CollisionFilter = {
  category: 0x0002,           // this body is category 2
  mask: 0x0001 | 0x0008,     // collides with categories 1 and 8
  group: 0,                   // no group override
};
```

**Group rules:**
- If `group > 0` and both bodies share the same positive group: they always collide (overrides mask)
- If `group < 0` and both bodies share the same negative group: they never collide (overrides mask)
- If `group === 0` or groups differ: category/mask rules apply normally

---

## MatterConstraintConfig Interface

```typescript
interface MatterConstraintConfig {
  label?: string;

  // Bodies to connect (at least one required)
  bodyA?: MatterJS.BodyType;
  bodyB?: MatterJS.BodyType;

  // Attachment points (local offsets on each body)
  pointA?: { x: number; y: number };  // offset from bodyA center; default { x:0, y:0 }
  pointB?: { x: number; y: number };  // offset from bodyB center; default { x:0, y:0 }

  // Constraint behavior
  length?: number;       // rest/target length in px; undefined = current distance at creation
  stiffness?: number;    // 0.001–1; higher = stiffer; default 1 (rigid)
  damping?: number;      // 0–1; reduces oscillation; 0 = no damping, 0.1 = light damping
  angularStiffness?: number;  // 0–1; resist rotation at attachment points

  // Rendering (debug only)
  render?: {
    visible?: boolean;
    lineWidth?: number;
    strokeStyle?: string;
    type?: 'line' | 'pin' | 'spring';
    anchors?: boolean;
  };
}
```

**Stiffness guidelines:**
- `1.0` — rigid rod (no stretch)
- `0.1–0.5` — stiff spring (bouncy but controlled)
- `0.01–0.05` — soft spring (slow oscillation)
- `0.001` — very loose (rubber band)

---

## Collision Event Structure

```typescript
// Event type emitted by this.matter.world:
// 'collisionstart' | 'collisionactive' | 'collisionend'

interface CollisionEvent {
  pairs: CollisionPair[];
  timestamp: number;   // engine timestamp in ms
  source: MatterJS.Engine;
  name: string;
}

interface CollisionPair {
  bodyA: MatterJS.BodyType;
  bodyB: MatterJS.BodyType;
  activeContacts: Contact[];
  separation: number;
  isActive: boolean;
  isSensor: boolean;        // true if either body is a sensor
  timeCreated: number;
  timeUpdated: number;
  collision: {
    depth: number;
    normal: { x: number; y: number };
    tangent: { x: number; y: number };
    supports: MatterJS.Vector[];
    parentA: MatterJS.BodyType;
    parentB: MatterJS.BodyType;
  };
}
```

### Accessing Phaser Game Objects from Collision

```typescript
this.matter.world.on('collisionstart', (event: any) => {
  for (const pair of event.pairs) {
    const { bodyA, bodyB } = pair;

    // bodyA.gameObject is the Phaser sprite/image, or null for raw bodies
    const goA = bodyA.gameObject as Phaser.Physics.Matter.Image | null;
    const goB = bodyB.gameObject as Phaser.Physics.Matter.Image | null;

    // For compound bodies, sub-parts have no gameObject — use parent
    const parentA = bodyA.parent?.gameObject ?? bodyA.gameObject;

    // Check by label (set in MatterBodyConfig)
    if (bodyA.label === 'player' || bodyB.label === 'player') {
      const playerBody = bodyA.label === 'player' ? bodyA : bodyB;
      const otherBody  = bodyA.label === 'player' ? bodyB : bodyA;
      // Handle player collision
    }
  }
});
```

---

## Phaser.Physics.Matter.Matter (Raw MatterJS Engine)

The raw MatterJS library is exposed at `Phaser.Physics.Matter.Matter`. This gives access to all static MatterJS utilities:

```typescript
const Matter = Phaser.Physics.Matter.Matter;

Matter.Body        // Body manipulation statics
Matter.Bodies      // Shape factory statics
Matter.Constraint  // Constraint statics
Matter.Composite   // Composite/world management
Matter.Events      // Event binding (lower-level than Phaser's event system)
Matter.Vector      // 2D vector math utilities
Matter.Vertices    // Vertex manipulation utilities
Matter.Query       // Spatial queries (point, ray, region)
Matter.Resolver    // Collision resolution
Matter.SAT         // Separating Axis Theorem utilities

// Vector utilities
Matter.Vector.add(a, b)        // → {x, y}
Matter.Vector.sub(a, b)
Matter.Vector.mult(v, scalar)
Matter.Vector.div(v, scalar)
Matter.Vector.dot(a, b)
Matter.Vector.cross(a, b)
Matter.Vector.normalise(v)
Matter.Vector.magnitude(v)
Matter.Vector.angle(a, b)      // angle from a to b in radians
Matter.Vector.rotate(v, angle)

// Query utilities
Matter.Query.point(bodies: MatterJS.BodyType[], point: MatterJS.Vector): MatterJS.BodyType[]
Matter.Query.region(bodies: MatterJS.BodyType[], bounds: MatterJS.Bounds): MatterJS.BodyType[]
Matter.Query.ray(bodies: MatterJS.BodyType[], startPoint: MatterJS.Vector, endPoint: MatterJS.Vector, rayWidth?: number): MatterJS.BodyType[]
```

---

## Common Patterns

### Check if Body Belongs to a Specific Sprite

```typescript
function bodiesMatch(body: MatterJS.BodyType, sprite: Phaser.Physics.Matter.Image): boolean {
  return body === (sprite.body as unknown as MatterJS.BodyType) ||
    body.gameObject === sprite ||
    body.parent?.gameObject === sprite;
}
```

### Remove Constraint After One Use (e.g., one-shot rope)

```typescript
const joint = this.matter.add.constraint(a.body, b.body, 50, 0.5);
this.matter.world.once('afterupdate', () => {
  this.matter.world.removeConstraint(joint);
});
```

### Raycast

```typescript
const start = { x: this.player.x, y: this.player.y };
const end   = { x: this.player.x, y: this.player.y + 200 };
const allBodies = this.matter.world.getAllBodies();
const hits = Phaser.Physics.Matter.Matter.Query.ray(allBodies, start, end, 1);
const onGround = hits.some(b => b.isStatic);
```

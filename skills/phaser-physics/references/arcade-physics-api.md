# Phaser 4 Arcade Physics API Reference

## ArcadeBody Properties

Access via `sprite.body as Phaser.Physics.Arcade.Body`.

```typescript
const body = sprite.body as Phaser.Physics.Arcade.Body;

// Position / Geometry
body.x; body.y;                // top-left of body (may differ from sprite due to offset)
body.width; body.height;
body.halfWidth; body.halfHeight;
body.center;                   // Vector2 center of body
body.setSize(w, h, center?);   // resize body; center=true auto-centers on sprite
body.setOffset(x, y);          // offset from sprite's top-left corner
body.reset(x, y);              // move body AND sprite to position

// Velocity (pixels/second)
body.velocity;                 // Vector2
body.setVelocity(vx, vy);
body.setVelocityX(vx);
body.setVelocityY(vy);
body.maxVelocity;              // Vector2 — cap velocity magnitude
body.setMaxVelocity(mx, my);
body.setMaxVelocityX(mx);
body.setMaxVelocityY(my);

// Acceleration (pixels/second²)
body.acceleration;             // Vector2
body.setAcceleration(ax, ay);
body.setAccelerationX(ax);
body.setAccelerationY(ay);

// Drag (deceleration applied each frame when no acceleration)
body.drag;                     // Vector2
body.setDrag(dx, dy);
body.setDragX(dx);
body.setDragY(dy);
body.useDamping;               // if true, drag is multiplied (0-1) not subtracted
body.setDamping(true);         // enable damping mode

// Gravity
body.gravity;                  // Vector2 — ADDED to world gravity for this body
body.setGravity(gx, gy);       // additional gravity on top of world gravity
body.setGravityX(gx);
body.setGravityY(gy);
body.allowGravity;             // if false, gravity is ignored entirely
body.setAllowGravity(false);

// Bounce (coefficient of restitution, 0-1)
body.bounce;                   // Vector2
body.setBounce(bx, by);
body.setBounceX(bx);
body.setBounceY(by);
body.worldBounce;              // separate bounce for world bounds

// Friction (velocity transfer on contact with moving platform)
body.friction;                 // Vector2 (0-1)
body.setFriction(fx, fy);
body.setFrictionX(fx);
body.setFrictionY(fy);

// Collision Flags
body.immovable;                // if true, body won't move when hit
body.setImmovable(true);
body.collideWorldBounds;       // stop at world bounds
body.setCollideWorldBounds(true);
body.onWorldBounds;            // emit worldbounds event when hitting world bounds
body.setOnWorldBounds(true);

// Blocking flags (read-only after physics step)
body.blocked.up;               // touching top of world/solid
body.blocked.down;             // on the ground (touching something below)
body.blocked.left;
body.blocked.right;
body.blocked.none;             // no blocking in any direction

body.touching.up;              // touching another body's top
body.touching.down;
body.touching.left;
body.touching.right;
body.touching.none;

// State
body.enable;                   // if false, body is skipped by physics
body.setEnable(true);
body.moves;                    // if false, body never moves (faster static simulation)
body.debugShowBody;
body.debugShowVelocity;
body.debugBodyColor;

// Speed (read-only)
body.speed;                    // current magnitude of velocity
body.prevVelocity;             // velocity from previous frame
body.deltaAbsX();              // absolute horizontal movement this frame
body.deltaAbsY();
```

## StaticBody Properties

```typescript
const body = sprite.body as Phaser.Physics.Arcade.StaticBody;

body.x; body.y;
body.width; body.height;
body.setSize(w, h, center?);
body.setOffset(x, y);
body.reset(x, y);              // IMPORTANT: must call reset() after moving a static body
body.refreshBody();            // alternative to reset — refresh position from parent
```

## ArcadePhysics World Methods

```typescript
this.physics.world.gravity;    // Vector2 — global gravity
this.physics.world.bounds;     // Phaser.Geom.Rectangle

this.physics.world.setBounds(x, y, w, h, checkLeft?, checkRight?, checkUp?, checkDown?);
this.physics.world.pause();
this.physics.world.resume();
this.physics.world.timeScale;  // slow motion (0.5) or fast forward (2)

// Overlap test (no callback, returns bool)
this.physics.world.overlap(obj1, obj2);

// Collide test (no callback, returns bool)
this.physics.world.collide(obj1, obj2);

// Separation (manually resolve overlap)
this.physics.world.separate(body1, body2);
```

## Utility Functions

```typescript
// Move a game object toward a target point at given speed
// Returns the angle (radians)
this.physics.moveTo(gameObject, x, y, speed, maxTime?);

// Set velocity from angle (degrees, 0=right, 90=down)
const vel = new Phaser.Math.Vector2();
this.physics.velocityFromAngle(angle, speed, vel);
// Apply: body.setVelocity(vel.x, vel.y)

// Set velocity from rotation (radians)
this.physics.velocityFromRotation(rotation, speed, vel);

// Overlap between arcade body and geometry
this.physics.overlap(body, geometry);

// Closest point on a body to a coordinate
Phaser.Physics.Arcade.GetOverlapX(body1, body2, separate?, bias?);
Phaser.Physics.Arcade.GetOverlapY(body1, body2, separate?, bias?);
```

## Advanced Patterns

### Moving Platforms

```typescript
// Moving platform that carries the player
export class MovingPlatform extends Phaser.Physics.Arcade.Image {
  private direction: number = 1;
  private speed: number = 100;
  private minX: number;
  private maxX: number;

  constructor(scene: Phaser.Scene, x: number, y: number, minX: number, maxX: number) {
    super(scene, x, y, 'platform');
    this.minX = minX;
    this.maxX = maxX;
    scene.physics.add.existing(this, false); // false = dynamic
    (this.body as Phaser.Physics.Arcade.Body).setImmovable(true).setAllowGravity(false);
    this.setVelocityX(this.speed);
  }

  update(): void {
    if (this.x >= this.maxX) { this.direction = -1; this.setVelocityX(-this.speed); }
    if (this.x <= this.minX) { this.direction = 1;  this.setVelocityX(this.speed); }
  }
}

// In GameScene: set player friction to transfer platform velocity
this.physics.add.collider(player, movingPlatforms, () => {
  if ((player.body as Phaser.Physics.Arcade.Body).blocked.down) {
    player.setVelocityX(player.body.velocity.x + movingPlatform.body.velocity.x);
  }
});
```

### Knockback

```typescript
private applyKnockback(
  target: Phaser.Physics.Arcade.Sprite,
  source: Phaser.Physics.Arcade.Sprite,
  force: number = 300
): void {
  const angle = Phaser.Math.Angle.Between(source.x, source.y, target.x, target.y);
  const body = target.body as Phaser.Physics.Arcade.Body;
  body.setVelocity(
    Math.cos(angle) * force,
    Math.sin(angle) * force - 100  // slight upward bias
  );
}
```

### Tilemap Collision with Arcade Physics

```typescript
// In create():
const map = this.make.tilemap({ key: 'level1' });
const tileset = map.addTilesetImage('tiles', 'tiles-image');
const groundLayer = map.createLayer('Ground', tileset!, 0, 0)!;
const hazardLayer = map.createLayer('Hazards', tileset!, 0, 0)!;

// Set collision by Tiled property
groundLayer.setCollisionByProperty({ collides: true });

// Or by tile index range
groundLayer.setCollisionBetween(1, 50);

// Or by specific indices
groundLayer.setCollision([1, 2, 5, 7]);

// Add collider with player
this.physics.add.collider(this.player, groundLayer);

// Add overlap with hazards
this.physics.add.overlap(this.player, hazardLayer, (player) => {
  this.playerDeath();
});

// Set world bounds to tilemap size
const { widthInPixels, heightInPixels } = map;
this.physics.world.setBounds(0, 0, widthInPixels, heightInPixels);
this.cameras.main.setBounds(0, 0, widthInPixels, heightInPixels);
```

### Group-to-Group Collisions

```typescript
// Bullets vs Enemies
this.physics.add.overlap(
  this.bullets,
  this.enemies,
  (bulletObj, enemyObj) => {
    const bullet = bulletObj as Bullet;
    const enemy = enemyObj as Enemy;
    bullet.setActive(false).setVisible(false);
    enemy.takeDamage(bullet.damage);
  },
  undefined,
  this
);

// Player vs Enemy group (all enemies collide with each other too)
this.physics.add.collider(this.enemies, this.enemies);  // enemies don't overlap each other
this.physics.add.collider(this.player, this.enemies, this.playerHit, undefined, this);
```

### Physics World Events

```typescript
// When a body hits world bounds
this.player.setCollideWorldBounds(true);
this.player.body.onWorldBounds = true;
this.physics.world.on(
  Phaser.Physics.Arcade.Events.WORLD_BOUNDS,
  (body: Phaser.Physics.Arcade.Body, up: boolean, down: boolean, left: boolean, right: boolean) => {
    if (body.gameObject === this.player) {
      if (down) this.playerFell();
    }
  }
);

// Fall into death zone (y exceeds level height)
// In update():
if (this.player.y > this.physics.world.bounds.height + 100) {
  this.playerDeath();
}
```

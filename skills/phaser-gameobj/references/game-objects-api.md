# Phaser 4 Game Objects API Quick Reference

## GameObject Base Properties (all objects share these)

```typescript
// Position
obj.x = 100;                   obj.y = 200;
obj.setPosition(x, y);
obj.setX(100);                 obj.setY(200);

// Origin (pivot/anchor point, 0=top-left, 0.5=center, 1=bottom-right)
obj.setOrigin(0.5, 0.5);       // center (default for most objects)
obj.setOrigin(0, 0);           // top-left
obj.originX;                   obj.originY;

// Size
obj.width;                     obj.height;
obj.setDisplaySize(w, h);      // scale to exact pixel size
obj.displayWidth;              obj.displayHeight;

// Scale
obj.setScale(2);               // uniform scale
obj.setScale(sx, sy);          // non-uniform
obj.scaleX;                    obj.scaleY;

// Rotation (radians)
obj.setRotation(angle);        // radians
obj.rotation;
obj.setAngle(degrees);         // degrees convenience
obj.angle;

// Flip
obj.setFlipX(true);
obj.setFlipY(false);
obj.flipX;                     obj.flipY;

// Depth (z-order — higher = rendered on top)
obj.setDepth(10);
obj.depth;

// Alpha (transparency, 0=invisible, 1=opaque)
obj.setAlpha(0.8);
obj.alpha;

// Visibility
obj.setVisible(true);
obj.visible;

// Active (if false, update() is not called)
obj.setActive(true);
obj.active;

// Scroll factor (0=fixed to camera/HUD, 1=default world scroll)
obj.setScrollFactor(0);        // HUD element
obj.setScrollFactor(0.3);      // parallax

// Tint
obj.setTint(0xff0000);         // red tint
obj.setTintFill(0xff0000);     // full color fill
obj.clearTint();
obj.tintTopLeft;               obj.tintTopRight;
obj.tintBottomLeft;            obj.tintBottomRight;

// Blend modes
obj.setBlendMode(Phaser.BlendModes.ADD);
obj.setBlendMode(Phaser.BlendModes.MULTIPLY);
obj.setBlendMode(Phaser.BlendModes.SCREEN);

// Name (for findByName queries)
obj.setName('player');
obj.name;

// Data store (per-object key-value)
obj.setData('health', 100);
obj.getData('health');         // 100
obj.data.values.health;        // direct access

// Destroy
obj.destroy();
obj.on(Phaser.GameObjects.Events.DESTROY, handler);
```

## Sprite-Specific API

```typescript
const sprite = this.add.sprite(x, y, 'texture');
const sprite = this.add.sprite(x, y, 'atlas', 'frame-name.png');

// Texture
sprite.setTexture('newTexture');
sprite.setTexture('atlas', 'frame-name.png');
sprite.setFrame(0);            // frame number (spritesheet)
sprite.setFrame('run_01.png'); // frame name (atlas)
sprite.texture.key;
sprite.frame.name;

// Animations
sprite.play('anim-key');
sprite.play('anim-key', true); // ignore if already playing
sprite.play({ key: 'walk', repeat: 2, repeatDelay: 100 });
sprite.stop();
sprite.anims.currentAnim?.key;
sprite.anims.isPlaying;
sprite.anims.currentFrame?.index;

// Animation events
sprite.on(Phaser.Animations.Events.ANIMATION_START, handler);
sprite.on(Phaser.Animations.Events.ANIMATION_COMPLETE, handler);
sprite.on(Phaser.Animations.Events.ANIMATION_REPEAT, handler);
// Key-specific complete:
sprite.on(`${Phaser.Animations.Events.ANIMATION_COMPLETE_KEY}walk`, handler);
```

## Text API

```typescript
const text = this.add.text(x, y, 'content', style);

// Style options (subset):
const style: Phaser.Types.GameObjects.Text.TextStyle = {
  fontSize: '24px',
  fontFamily: 'Arial, sans-serif',
  fontStyle: 'bold',           // 'normal' | 'bold' | 'italic' | 'bold italic'
  color: '#ffffff',
  stroke: '#000000',
  strokeThickness: 4,
  shadow: { offsetX: 2, offsetY: 2, color: '#000000', blur: 4, stroke: true, fill: true },
  align: 'center',             // 'left' | 'center' | 'right' | 'justify'
  fixedWidth: 400,             // wrap text at this width
  fixedHeight: 200,            // fixed height (clips content)
  backgroundColor: '#333333',
  padding: { x: 10, y: 5 },
  lineSpacing: 6,
  wordWrap: { width: 400, useAdvancedWrap: true },
  maxLines: 3,
};

// Update
text.setText('New text');
text.setText(['Line 1', 'Line 2', 'Line 3']);
text.appendText(' more text');

// Measured size
text.width;                    // actual rendered width
text.height;
text.getBounds().width;        // bounds with origin offset
```

## Graphics API

```typescript
const gfx = this.add.graphics();

// Styles (must set before drawing)
gfx.fillStyle(0xff0000, 1.0);          // RGB hex, alpha 0-1
gfx.lineStyle(2, 0xffffff, 1.0);       // width, color, alpha

// Filled primitives
gfx.fillRect(x, y, w, h);
gfx.fillRoundedRect(x, y, w, h, radius);
gfx.fillCircle(x, y, radius);
gfx.fillEllipse(x, y, w, h);
gfx.fillTriangle(x1, y1, x2, y2, x3, y3);
gfx.fillPoints([{ x, y }, ...], closeShape);

// Stroked primitives
gfx.strokeRect(x, y, w, h);
gfx.strokeRoundedRect(x, y, w, h, radius);
gfx.strokeCircle(x, y, radius);
gfx.strokeEllipse(x, y, w, h);
gfx.strokeTriangle(x1, y1, x2, y2, x3, y3);

// Paths
gfx.beginPath();
gfx.moveTo(x, y);
gfx.lineTo(x2, y2);
gfx.arc(x, y, radius, startAngle, endAngle, anticlockwise);
gfx.quadraticCurveTo(cx, cy, x, y);
gfx.bezierCurveTo(cx1, cy1, cx2, cy2, x, y);
gfx.closePath();
gfx.fillPath();
gfx.strokePath();

// Gradients
gfx.fillGradientStyle(
  topLeft, topRight, bottomLeft, bottomRight, // color values
  alphaTopLeft, alphaTopRight, alphaBottomLeft, alphaBottomRight
);

// Utility
gfx.clear();                   // erase all drawing
gfx.generateTexture('key', width, height);  // convert to reusable texture

// Alpha on specific areas
gfx.setAlpha(0.5);
```

## Container API

```typescript
const container = this.add.container(x, y);
const container = this.add.container(x, y, [child1, child2]);

// Add children
container.add(sprite);
container.add([sprite, text, graphics]);
container.addAt(sprite, 0);    // add at specific index

// Remove children
container.remove(sprite);
container.remove(sprite, true); // true = also destroy the child
container.removeAll(true);

// Access children
container.list;                // array of children
container.getAt(0);
container.getByName('child-name');
container.count;

// Physics on container itself — NOT supported
// For physics, use individual sprites. Container is visual grouping only.

// Bounds
container.getBounds();         // Phaser.Geom.Rectangle
container.width;               // sum of children bounds
container.height;
```

## Group API

```typescript
// Static display group
const group = this.add.group();
group.add(sprite);
group.create(x, y, 'texture');
group.createMultiple({ key: 'star', repeat: 9, setXY: { x: 100, stepX: 70, y: 400 } });

// Physics group
const physGroup = this.physics.add.group();
const physGroup = this.physics.add.staticGroup();

// Pool group
const pool = this.physics.add.group({
  classType: MySprite,
  maxSize: 50,
  runChildUpdate: true,     // calls update() on active members
  createCallback: (item) => { (item as MySprite).init(); },
  removeCallback: (item) => { (item as MySprite).cleanup(); },
});

// Get from pool (returns inactive member or creates new if under maxSize)
const item = pool.get(x, y) as MySprite;  // null if pool is full
if (item) { item.setActive(true).setVisible(true); }

// Return to pool
item.setActive(false).setVisible(false);

// Group queries
group.getChildren();           // all members
group.getActive();             // active only
group.getFirst(active, value, key, compare);
group.countActive();
group.isFull();

// Apply to all
group.setDepth(10, 1);         // value, step
group.setXY(x, y, stepX, stepY);
```

## Camera API

```typescript
const cam = this.cameras.main;

// Follow
cam.startFollow(target);
cam.startFollow(target, roundPx, lerpX, lerpY);  // lerp 0=instant, 1=delayed
cam.stopFollow();

// Bounds (prevent camera from showing outside world)
cam.setBounds(x, y, width, height);

// Zoom
cam.setZoom(2);                // 2x zoom
cam.zoom;

// Effects
cam.fadeIn(duration, r, g, b, callback);
cam.fadeOut(duration, r, g, b, callback);
cam.flash(duration, r, g, b, force, callback);
cam.shake(duration, intensity, force, callback);
cam.pan(x, y, duration, ease, force, callback);
cam.zoomTo(zoom, duration, ease, force, callback);
cam.rotateTo(radians, shortestPath, duration, ease, force, callback);

// World → screen coordinate conversion
cam.getWorldPoint(screenX, screenY, out);  // → world coords
cam.worldView;                              // Rectangle of visible world
```

## Particles (Phaser 4)

```typescript
// Create emitter
const emitter = this.add.particles(x, y, 'texture', {
  speed: { min: 50, max: 200 },
  scale: { start: 0.8, end: 0 },
  alpha: { start: 1, end: 0 },
  lifespan: { min: 500, max: 1000 },
  gravityY: 200,
  rotate: { min: 0, max: 360 },
  blendMode: Phaser.BlendModes.ADD,
  frequency: 100,          // ms between emissions
  quantity: 3,             // particles per emission
  maxParticles: 100,       // pool limit (IMPORTANT for performance)
  tint: [0xff0000, 0xff8800, 0xffff00],  // random tint from array
});

// From atlas frame
const emitter = this.add.particles(x, y, 'atlas', {
  frame: ['spark1.png', 'spark2.png', 'spark3.png'],  // random frame
  // ...
});

// Control
emitter.start();
emitter.stop();
emitter.setPosition(x, y);    // move emitter
emitter.explode(count, x, y); // one-shot burst

// Deathzone — kill particles in/out of shape
emitter.addDeathZone({
  type: 'onEnter',
  source: new Phaser.Geom.Rectangle(0, 600, 800, 100),
});

// Follow a game object
emitter.setParticleSpeed(50);
// Or use follow:
emitter.startFollow(sprite, xOffset, yOffset);
emitter.stopFollow();
```

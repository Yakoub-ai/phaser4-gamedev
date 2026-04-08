---
name: phaser-input
description: This skill should be used when the user asks to "handle input", "keyboard controls", "mouse click", "touch controls", "gamepad support", "drag and drop", "virtual joystick", "WASD movement", "detect click", "pointer events", "keyboard shortcut", or "input manager".
version: 0.2.0
---

# Phaser 4 Input

Phaser 4's Input system supports keyboard, mouse/pointer, touch, and gamepad. All input is accessed through `this.input` inside a Scene.

## Keyboard Input

### Cursor Keys

Create a cursor key set to track arrow keys, space, and shift in one call:

```typescript
private cursors!: Phaser.Types.Input.Keyboard.CursorKeys;

create(): void {
  this.cursors = this.input.keyboard!.createCursorKeys();
}

update(): void {
  if (this.cursors.left.isDown) { /* move left */ }
  if (this.cursors.right.isDown) { /* move right */ }
  if (this.cursors.up.isDown) { /* move up / jump */ }
  if (this.cursors.down.isDown) { /* move down / crouch */ }
  if (this.cursors.space.isDown) { /* fire / action */ }
  if (this.cursors.shift.isDown) { /* sprint / modifier */ }
}
```

### WASD Keys

Use `addKeys` to bind arbitrary keys by name:

```typescript
private wasd!: { up: Phaser.Input.Keyboard.Key; left: Phaser.Input.Keyboard.Key; down: Phaser.Input.Keyboard.Key; right: Phaser.Input.Keyboard.Key };

create(): void {
  this.wasd = this.input.keyboard!.addKeys({ up: 'W', left: 'A', down: 'S', right: 'D' }) as typeof this.wasd;
}

update(): void {
  if (this.wasd.left.isDown) { /* strafe left */ }
  if (this.wasd.right.isDown) { /* strafe right */ }
}
```

### Single Key

Bind a single key using `KeyCodes`:

```typescript
private spaceKey!: Phaser.Input.Keyboard.Key;
private shiftKey!: Phaser.Input.Keyboard.Key;

create(): void {
  this.spaceKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.SPACE);
  this.shiftKey = this.input.keyboard!.addKey(Phaser.Input.Keyboard.KeyCodes.SHIFT);
}
```

### isDown vs JustDown vs JustUp

| Method | Behavior |
|---|---|
| `key.isDown` | `true` every frame the key is held |
| `Phaser.Input.Keyboard.JustDown(key)` | `true` on the single frame the key is first pressed |
| `Phaser.Input.Keyboard.JustUp(key)` | `true` on the single frame the key is released |

```typescript
update(): void {
  // Continuous — fires every frame while held
  if (this.cursors.left.isDown) {
    this.player.setVelocityX(-200);
  }

  // One-shot — fires once per key press
  if (Phaser.Input.Keyboard.JustDown(this.spaceKey)) {
    this.fireBullet();
  }

  // Release — fires once per key release
  if (Phaser.Input.Keyboard.JustUp(this.shiftKey)) {
    this.stopSprint();
  }
}
```

### Key Combos (Konami Code, Cheat Codes)

```typescript
create(): void {
  // Konami: Up Up Down Down Left Right Left Right A B
  const combo = this.input.keyboard!.createCombo(
    [38, 38, 40, 40, 37, 39, 37, 39, 65, 66],
    { resetOnMatch: true }
  );

  this.input.keyboard!.on('keycombomatch', (combo: Phaser.Input.Keyboard.KeyCombo) => {
    console.log('Konami code entered!');
    this.activateCheatMode();
  });
}
```

### Disabling Browser Default Keys

Prevent the browser from intercepting arrow keys (page scroll) and other keys:

```typescript
create(): void {
  // Disable global capture — let browser handle keys normally
  this.input.keyboard!.disableGlobalCapture();

  // Enable global capture — Phaser intercepts keys before the browser
  this.input.keyboard!.enableGlobalCapture();

  // Capture only specific keys (recommended approach)
  this.input.keyboard!.addCapture([
    Phaser.Input.Keyboard.KeyCodes.UP,
    Phaser.Input.Keyboard.KeyCodes.DOWN,
    Phaser.Input.Keyboard.KeyCodes.LEFT,
    Phaser.Input.Keyboard.KeyCodes.RIGHT,
    Phaser.Input.Keyboard.KeyCodes.SPACE,
  ]);
}
```

---

## Pointer / Mouse Input

### Global Pointer Events

Listen on `this.input` for events anywhere in the game canvas:

```typescript
create(): void {
  this.input.on('pointerdown', (ptr: Phaser.Input.Pointer) => {
    console.log(`Clicked at canvas: ${ptr.x}, ${ptr.y}`);
    console.log(`World position: ${ptr.worldX}, ${ptr.worldY}`);
    console.log(`Left button: ${ptr.leftButtonDown()}`);
    console.log(`Right button: ${ptr.rightButtonDown()}`);
  });

  this.input.on('pointermove', (ptr: Phaser.Input.Pointer) => {
    // ptr.velocity.x / ptr.velocity.y for movement delta
  });

  this.input.on('pointerup', (ptr: Phaser.Input.Pointer) => {
    // handle release
  });
}
```

Use `ptr.worldX` / `ptr.worldY` when the camera has moved — these give the world-space position rather than screen-space.

### Making Sprites Interactive

Call `setInteractive()` before listening to pointer events on a specific object:

```typescript
create(): void {
  const button = this.add.image(400, 300, 'button');
  button.setInteractive({ useHandCursor: true });  // shows pointer cursor on hover

  button.on('pointerdown', () => {
    this.scene.start('GameScene');
  });

  button.on('pointerover', () => {
    button.setTint(0xcccccc);  // lighten on hover
  });

  button.on('pointerout', () => {
    button.clearTint();
  });
}
```

### Drag and Drop

Enable dragging on a game object:

```typescript
create(): void {
  const card = this.add.image(200, 200, 'card');
  card.setInteractive();
  this.input.setDraggable(card);

  this.input.on('dragstart', (ptr: Phaser.Input.Pointer, obj: Phaser.GameObjects.Image) => {
    obj.setTint(0x88ff88);
  });

  this.input.on('drag', (ptr: Phaser.Input.Pointer, obj: Phaser.GameObjects.Image, dragX: number, dragY: number) => {
    obj.setPosition(dragX, dragY);
  });

  this.input.on('dragend', (ptr: Phaser.Input.Pointer, obj: Phaser.GameObjects.Image) => {
    obj.clearTint();
  });
}
```

### Input Zones

Use a Zone as an invisible interactive area (useful for UI hit areas):

```typescript
create(): void {
  const zone = this.add.zone(400, 300, 200, 100).setInteractive();
  zone.on('pointerdown', () => {
    console.log('Zone was clicked');
  });
}
```

### Right-Click (Context Menu)

Prevent the browser context menu from appearing on right-click:

```typescript
create(): void {
  this.input.mouse!.disableContextMenu();

  this.input.on('pointerdown', (ptr: Phaser.Input.Pointer) => {
    if (ptr.rightButtonDown()) {
      console.log('Right click at', ptr.worldX, ptr.worldY);
    }
  });
}
```

### Stop Event Propagation

Prevent a click on a game object from also firing the global `pointerdown` handler:

```typescript
button.on('pointerdown', (
  ptr: Phaser.Input.Pointer,
  localX: number,
  localY: number,
  event: Phaser.Types.Input.EventData
) => {
  event.stopPropagation();
  this.handleButtonClick();
});
```

---

## Touch Input

Touch events share the same pointer API — `pointerdown`, `pointermove`, `pointerup` fire on touch devices automatically.

### Multi-Touch

Add extra pointer slots (default is 2 total; expand for more fingers):

```typescript
create(): void {
  // Support up to 4 simultaneous touches
  this.input.addPointer(2);  // adds 2 more (total becomes 4)

  // Access individual touch pointers
  // this.input.pointer1  — first touch
  // this.input.pointer2  — second touch
  // this.input.pointer3  — third touch
}
```

### Swipe Detection

Phaser has no built-in swipe API. Track the start position manually:

```typescript
private swipeStart = { x: 0, y: 0 };
private readonly SWIPE_THRESHOLD = 50; // pixels

create(): void {
  this.input.on('pointerdown', (ptr: Phaser.Input.Pointer) => {
    this.swipeStart = { x: ptr.x, y: ptr.y };
  });

  this.input.on('pointerup', (ptr: Phaser.Input.Pointer) => {
    const dx = ptr.x - this.swipeStart.x;
    const dy = ptr.y - this.swipeStart.y;

    if (Math.abs(dx) > this.SWIPE_THRESHOLD || Math.abs(dy) > this.SWIPE_THRESHOLD) {
      if (Math.abs(dx) > Math.abs(dy)) {
        console.log(dx > 0 ? 'Swipe Right' : 'Swipe Left');
      } else {
        console.log(dy > 0 ? 'Swipe Down' : 'Swipe Up');
      }
    }
  });
}
```

### Preventing Browser Gestures

```typescript
create(): void {
  // Prevent pinch-zoom, browser swipe navigation, pull-to-refresh
  this.input.mouse!.disableContextMenu();
  // In your HTML, also add to the canvas element:
  // style="touch-action: none;"
  // Or in Phaser config: input: { activePointers: 3 }
}
```

---

## Gamepad Input

The Gamepad plugin is included by default in Phaser 4. Access it via `this.input.gamepad`.

### Connection

```typescript
create(): void {
  this.input.gamepad!.on('connected', (pad: Phaser.Input.Gamepad.Gamepad) => {
    console.log(`Gamepad connected: ${pad.id}`);
  });

  this.input.gamepad!.on('disconnected', (pad: Phaser.Input.Gamepad.Gamepad) => {
    console.log(`Gamepad disconnected`);
  });
}
```

### Reading Buttons

```typescript
update(): void {
  const pad = this.input.gamepad!.pad1;
  if (!pad) return;

  // Face buttons
  if (pad.A) { this.jump(); }
  if (pad.B) { this.dodge(); }
  if (pad.X) { this.attack(); }
  if (pad.Y) { this.interact(); }

  // Shoulder / trigger buttons
  if (pad.L1) { /* left bumper */ }
  if (pad.R1) { /* right bumper */ }
  if (pad.L2) { /* left trigger (analog, 0–1) */ }
  if (pad.R2) { /* right trigger (analog, 0–1) */ }

  // D-pad
  if (pad.up)    { /* d-pad up */ }
  if (pad.down)  { /* d-pad down */ }
  if (pad.left)  { /* d-pad left */ }
  if (pad.right) { /* d-pad right */ }
}
```

### Analog Sticks

Values range from -1 to 1 on each axis. Apply a dead zone to prevent drift:

```typescript
private readonly DEAD_ZONE = 0.1;

update(): void {
  const pad = this.input.gamepad!.pad1;
  if (!pad) return;

  let lx = pad.leftStick.x;
  let ly = pad.leftStick.y;
  let rx = pad.rightStick.x;
  let ry = pad.rightStick.y;

  // Apply dead zone
  if (Math.abs(lx) < this.DEAD_ZONE) lx = 0;
  if (Math.abs(ly) < this.DEAD_ZONE) ly = 0;
  if (Math.abs(rx) < this.DEAD_ZONE) rx = 0;
  if (Math.abs(ry) < this.DEAD_ZONE) ry = 0;

  this.player.setVelocity(lx * 300, ly * 300);

  // Aim with right stick
  if (rx !== 0 || ry !== 0) {
    const angle = Math.atan2(ry, rx) * (180 / Math.PI);
    this.player.setAngle(angle);
  }
}
```

---

## Virtual Joystick (Mobile)

Phaser 4 has no built-in virtual joystick. For mobile games, implement a pointer-based joystick or use the reference implementation.

See `references/virtual-joystick.md` for a complete, production-ready TypeScript class that renders a base circle and thumb and exposes normalized `direction.x` / `direction.y` values.

Usage pattern:

```typescript
private joystick!: VirtualJoystick;

create(): void {
  this.joystick = new VirtualJoystick(this, 120, this.scale.height - 120);
}

update(): void {
  if (this.joystick.isActive) {
    this.player.setVelocity(
      this.joystick.direction.x * 200,
      this.joystick.direction.y * 200
    );
  } else {
    this.player.setVelocity(0, 0);
  }
}
```

---

## Additional Resources

### Reference Files
- **`references/input-api.md`** — Complete API reference for InputPlugin, KeyboardPlugin, Key, Pointer, Gamepad, and all input events
- **`references/virtual-joystick.md`** — Full TypeScript virtual joystick implementation for mobile games

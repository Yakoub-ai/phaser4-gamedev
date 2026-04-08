# Virtual Joystick — Complete TypeScript Implementation

Phaser 4 has no built-in virtual joystick. This file provides a production-ready implementation using `Phaser.GameObjects.Graphics` and the pointer event system.

## How It Works

- A base circle renders the joystick background (fixed position)
- A thumb circle renders the movable knob
- On `pointerdown` near the base, the joystick activates
- On `pointermove`, the thumb follows the pointer, clamped to the base radius
- On `pointerup`, the thumb resets to center and `isActive` becomes `false`
- `direction.x` and `direction.y` are normalized to the -1 to 1 range

---

## VirtualJoystick Class

```typescript
// src/ui/VirtualJoystick.ts

export class VirtualJoystick {
  private scene: Phaser.Scene;
  private baseGraphic: Phaser.GameObjects.Graphics;
  private thumbGraphic: Phaser.GameObjects.Graphics;

  private baseX: number;
  private baseY: number;
  private readonly baseRadius: number;
  private readonly thumbRadius: number;

  private pointerId: number | null = null;

  public direction: Phaser.Math.Vector2;
  public isActive: boolean = false;

  /**
   * @param scene     The scene to attach to
   * @param x         Center X of the joystick base (screen coordinates)
   * @param y         Center Y of the joystick base (screen coordinates)
   * @param baseRadius  Radius of the outer ring (default 60)
   * @param thumbRadius Radius of the inner knob (default 28)
   */
  constructor(
    scene: Phaser.Scene,
    x: number,
    y: number,
    baseRadius = 60,
    thumbRadius = 28
  ) {
    this.scene = scene;
    this.baseX = x;
    this.baseY = y;
    this.baseRadius = baseRadius;
    this.thumbRadius = thumbRadius;
    this.direction = new Phaser.Math.Vector2(0, 0);

    // Create graphics objects — setScrollFactor(0) keeps them fixed to the camera
    this.baseGraphic = scene.add.graphics().setScrollFactor(0).setDepth(100);
    this.thumbGraphic = scene.add.graphics().setScrollFactor(0).setDepth(101);

    this.drawBase();
    this.drawThumb(x, y);

    this.bindEvents();
  }

  // ─── Drawing ─────────────────────────────────────────────────────────────────

  private drawBase(): void {
    this.baseGraphic.clear();
    this.baseGraphic.fillStyle(0x000000, 0.3);
    this.baseGraphic.fillCircle(this.baseX, this.baseY, this.baseRadius);
    this.baseGraphic.lineStyle(3, 0xffffff, 0.5);
    this.baseGraphic.strokeCircle(this.baseX, this.baseY, this.baseRadius);
  }

  private drawThumb(x: number, y: number): void {
    this.thumbGraphic.clear();
    this.thumbGraphic.fillStyle(0xffffff, 0.8);
    this.thumbGraphic.fillCircle(x, y, this.thumbRadius);
  }

  // ─── Event Binding ───────────────────────────────────────────────────────────

  private bindEvents(): void {
    this.scene.input.on('pointerdown', this.onPointerDown, this);
    this.scene.input.on('pointermove', this.onPointerMove, this);
    this.scene.input.on('pointerup', this.onPointerUp, this);
    this.scene.input.on('pointerupoutside', this.onPointerUp, this);
  }

  private onPointerDown(pointer: Phaser.Input.Pointer): void {
    // Already tracking a pointer
    if (this.pointerId !== null) return;

    // Only activate if touch is within the base circle
    const dist = Phaser.Math.Distance.Between(pointer.x, pointer.y, this.baseX, this.baseY);
    if (dist <= this.baseRadius) {
      this.pointerId = pointer.id;
      this.isActive = true;
      this.updateDirection(pointer.x, pointer.y);
    }
  }

  private onPointerMove(pointer: Phaser.Input.Pointer): void {
    if (!this.isActive || pointer.id !== this.pointerId) return;
    this.updateDirection(pointer.x, pointer.y);
  }

  private onPointerUp(pointer: Phaser.Input.Pointer): void {
    if (pointer.id !== this.pointerId) return;
    this.reset();
  }

  // ─── Direction Calculation ───────────────────────────────────────────────────

  private updateDirection(px: number, py: number): void {
    const dx = px - this.baseX;
    const dy = py - this.baseY;
    const dist = Math.sqrt(dx * dx + dy * dy);

    // Clamp thumb to base radius
    const clampedDist = Math.min(dist, this.baseRadius);
    const angle = Math.atan2(dy, dx);
    const thumbX = this.baseX + Math.cos(angle) * clampedDist;
    const thumbY = this.baseY + Math.sin(angle) * clampedDist;

    this.drawThumb(thumbX, thumbY);

    // Normalize direction to -1 .. 1
    if (dist > 0) {
      this.direction.set(
        (dx / dist) * (clampedDist / this.baseRadius),
        (dy / dist) * (clampedDist / this.baseRadius)
      );
    } else {
      this.direction.set(0, 0);
    }
  }

  private reset(): void {
    this.pointerId = null;
    this.isActive = false;
    this.direction.set(0, 0);
    this.drawThumb(this.baseX, this.baseY);
  }

  // ─── Public API ──────────────────────────────────────────────────────────────

  /** Reposition the joystick on screen (e.g. when screen resizes) */
  setPosition(x: number, y: number): void {
    this.baseX = x;
    this.baseY = y;
    this.drawBase();
    if (!this.isActive) {
      this.drawThumb(x, y);
    }
  }

  /** Show or hide the joystick */
  setVisible(visible: boolean): void {
    this.baseGraphic.setVisible(visible);
    this.thumbGraphic.setVisible(visible);
  }

  /** Remove event listeners and destroy graphics */
  destroy(): void {
    this.scene.input.off('pointerdown', this.onPointerDown, this);
    this.scene.input.off('pointermove', this.onPointerMove, this);
    this.scene.input.off('pointerup', this.onPointerUp, this);
    this.scene.input.off('pointerupoutside', this.onPointerUp, this);
    this.baseGraphic.destroy();
    this.thumbGraphic.destroy();
  }
}
```

---

## Optional: Floating Joystick (appears at touch position)

Modify `onPointerDown` to reposition the base to where the player touches — popular in mobile games:

```typescript
private onPointerDown(pointer: Phaser.Input.Pointer): void {
  if (this.pointerId !== null) return;

  // Only activate in the left half of the screen
  if (pointer.x > this.scene.scale.width / 2) return;

  // Move base to touch position
  this.baseX = pointer.x;
  this.baseY = pointer.y;
  this.drawBase();
  this.drawThumb(this.baseX, this.baseY);

  this.pointerId = pointer.id;
  this.isActive = true;
  this.updateDirection(pointer.x, pointer.y);
}
```

---

## Usage in a GameScene

```typescript
// src/scenes/GameScene.ts
import { VirtualJoystick } from '../ui/VirtualJoystick';

export class GameScene extends Phaser.Scene {
  private player!: Phaser.Physics.Arcade.Sprite;
  private joystick!: VirtualJoystick;

  private readonly PLAYER_SPEED = 200;

  create(): void {
    // Place joystick in the lower-left corner with padding
    const joyX = 120;
    const joyY = this.scale.height - 120;
    this.joystick = new VirtualJoystick(this, joyX, joyY);

    this.player = this.physics.add.sprite(
      this.scale.width / 2,
      this.scale.height / 2,
      'player'
    );
    this.player.setCollideWorldBounds(true);
  }

  update(): void {
    if (this.joystick.isActive) {
      this.player.setVelocity(
        this.joystick.direction.x * this.PLAYER_SPEED,
        this.joystick.direction.y * this.PLAYER_SPEED
      );

      // Face the direction of movement
      if (this.joystick.direction.x < -0.1) {
        this.player.flipX = true;
      } else if (this.joystick.direction.x > 0.1) {
        this.player.flipX = false;
      }
    } else {
      this.player.setVelocity(0, 0);
    }
  }

  // Clean up when scene shuts down
  shutdown(): void {
    this.joystick.destroy();
  }
}
```

---

## Combining Joystick with Keyboard (Desktop + Mobile)

Support both input methods simultaneously:

```typescript
update(): void {
  const cursors = this.cursors; // created in create() via createCursorKeys()
  let vx = 0;
  let vy = 0;

  // Keyboard takes priority
  if (cursors.left.isDown) {
    vx = -this.PLAYER_SPEED;
  } else if (cursors.right.isDown) {
    vx = this.PLAYER_SPEED;
  }

  if (cursors.up.isDown) {
    vy = -this.PLAYER_SPEED;
  } else if (cursors.down.isDown) {
    vy = this.PLAYER_SPEED;
  }

  // Fall back to joystick if no keyboard input
  if (vx === 0 && vy === 0 && this.joystick.isActive) {
    vx = this.joystick.direction.x * this.PLAYER_SPEED;
    vy = this.joystick.direction.y * this.PLAYER_SPEED;
  }

  // Normalize diagonal movement
  if (vx !== 0 && vy !== 0) {
    vx *= 0.707;
    vy *= 0.707;
  }

  this.player.setVelocity(vx, vy);
}
```

---

## Notes

- The joystick uses `setScrollFactor(0)` so it stays fixed to the screen as the camera moves.
- `pointer.id` tracking ensures that multi-touch inputs do not interfere — a second finger can be used for a fire button while the joystick tracks the first finger.
- Call `this.input.addPointer(1)` in `create()` if you need simultaneous joystick + action button support.
- For higher quality visuals, replace the `Graphics` circles with `Image` or `Sprite` objects using pre-rendered joystick assets.

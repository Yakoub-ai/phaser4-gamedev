# Mobile Patterns Reference

Complete TypeScript implementations for Phaser 4 mobile development.

---

## 1. Full Responsive GameConfig (Scale.RESIZE Mode)

```typescript
// main.ts — responsive configuration that adapts to any screen size

import Phaser from 'phaser';
import { GameScene } from './scenes/GameScene';
import { UIScene }   from './scenes/UIScene';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,         // WebGL with Canvas fallback
  parent: 'game-container',  // Mount into <div id="game-container">

  scale: {
    mode: Phaser.Scale.RESIZE,           // Canvas matches window exactly
    autoCenter: Phaser.Scale.CENTER_BOTH,
    // No fixed width/height — window dimensions used automatically
  },

  backgroundColor: '#000000',

  pixelArt: false,     // set true for pixel-art games (disables antialiasing)
  roundPixels: false,  // set true alongside pixelArt

  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 0 }, debug: false },
  },

  scene: [GameScene, UIScene],
};

export default new Phaser.Game(config);
```

```typescript
// GameScene.ts — dynamic layout responding to resize events

export class GameScene extends Phaser.Scene {
  private scoreText!: Phaser.GameObjects.Text;
  private pauseBtn!: Phaser.GameObjects.Image;

  constructor() { super({ key: 'GameScene' }); }

  create(): void {
    const { width, height } = this.scale;
    this.buildUI(width, height);

    // Re-layout when window resizes (orientation change, virtual keyboard, etc.)
    this.scale.on('resize', (size: Phaser.Structs.Size) => {
      this.cameras.main.setSize(size.width, size.height);
      this.buildUI(size.width, size.height);
    });
  }

  private buildUI(w: number, h: number): void {
    // Destroy existing UI objects before re-creating
    this.scoreText?.destroy();
    this.pauseBtn?.destroy();

    const fontSize = Math.round(h * 0.05);  // 5% of screen height

    this.scoreText = this.add.text(w * 0.05, h * 0.04, 'Score: 0', {
      fontSize: `${fontSize}px`,
      color: '#ffffff',
      fontFamily: 'Arial, sans-serif',
    });

    this.pauseBtn = this.add.image(w - 48, 48, 'btn-pause')
      .setInteractive({ useHandCursor: true })
      .setDisplaySize(64, 64)  // minimum 44×44 tap target
      .on('pointerdown', () => this.scene.pause());
  }
}
```

---

## 2. VirtualGamepad Class

Left-side joystick for movement, right-side buttons for actions. Positioned responsively.

```typescript
// VirtualGamepad.ts

interface JoystickState {
  active: boolean;
  x: number;         // -1 to 1 (left/right)
  y: number;         // -1 to 1 (up/down)
  angle: number;     // degrees
  distance: number;  // 0 to 1 (normalized)
}

export class VirtualGamepad {
  private scene: Phaser.Scene;

  // Joystick elements
  private joystickBase!: Phaser.GameObjects.Image;
  private joystickThumb!: Phaser.GameObjects.Image;
  private joystickRadius = 60;
  private joystickCenter = { x: 0, y: 0 };
  private joystickPointerId: number | null = null;

  // Action buttons
  private btnA!: Phaser.GameObjects.Image;
  private btnB!: Phaser.GameObjects.Image;

  // Public state
  joystick: JoystickState = { active: false, x: 0, y: 0, angle: 0, distance: 0 };
  buttonA = false;
  buttonB = false;

  constructor(scene: Phaser.Scene) {
    this.scene = scene;
    this.create();

    // Re-layout on resize
    scene.scale.on('resize', (size: Phaser.Structs.Size) => {
      this.layout(size.width, size.height);
    });
  }

  private create(): void {
    const { width, height } = this.scene.scale;

    // Joystick base (left side)
    this.joystickBase = this.scene.add
      .image(0, 0, 'joystick-base')
      .setAlpha(0.6)
      .setScrollFactor(0)
      .setDepth(100);

    // Joystick thumb
    this.joystickThumb = this.scene.add
      .image(0, 0, 'joystick-thumb')
      .setAlpha(0.8)
      .setScrollFactor(0)
      .setDepth(101);

    // Action buttons (right side)
    this.btnA = this.scene.add
      .image(0, 0, 'btn-a')
      .setAlpha(0.7)
      .setScrollFactor(0)
      .setDepth(100)
      .setInteractive()
      .on('pointerdown', () => { this.buttonA = true; this.btnA.setAlpha(1); })
      .on('pointerup',   () => { this.buttonA = false; this.btnA.setAlpha(0.7); })
      .on('pointerout',  () => { this.buttonA = false; this.btnA.setAlpha(0.7); });

    this.btnB = this.scene.add
      .image(0, 0, 'btn-b')
      .setAlpha(0.7)
      .setScrollFactor(0)
      .setDepth(100)
      .setInteractive()
      .on('pointerdown', () => { this.buttonB = true; this.btnB.setAlpha(1); })
      .on('pointerup',   () => { this.buttonB = false; this.btnB.setAlpha(0.7); })
      .on('pointerout',  () => { this.buttonB = false; this.btnB.setAlpha(0.7); });

    // Joystick touch handling via scene input
    this.scene.input.on('pointerdown', (pointer: Phaser.Input.Pointer) => {
      if (pointer.x < width * 0.45) this.startJoystick(pointer);  // left half = joystick
    });
    this.scene.input.on('pointermove', (pointer: Phaser.Input.Pointer) => {
      if (pointer.id === this.joystickPointerId) this.moveJoystick(pointer);
    });
    this.scene.input.on('pointerup', (pointer: Phaser.Input.Pointer) => {
      if (pointer.id === this.joystickPointerId) this.stopJoystick();
    });

    this.layout(width, height);
  }

  private layout(w: number, h: number): void {
    const btnSize = Math.round(Math.min(w, h) * 0.12);
    this.joystickRadius = btnSize * 0.8;

    // Joystick: bottom-left quadrant
    const jx = w * 0.15;
    const jy = h * 0.80;
    this.joystickCenter = { x: jx, y: jy };
    this.joystickBase.setPosition(jx, jy).setDisplaySize(btnSize * 2.5, btnSize * 2.5);
    this.joystickThumb.setPosition(jx, jy).setDisplaySize(btnSize, btnSize);

    // Buttons: bottom-right
    this.btnA.setPosition(w * 0.88, h * 0.80).setDisplaySize(btnSize, btnSize);
    this.btnB.setPosition(w * 0.78, h * 0.88).setDisplaySize(btnSize, btnSize);
  }

  private startJoystick(pointer: Phaser.Input.Pointer): void {
    this.joystickPointerId = pointer.id;
    this.joystick.active = true;
    this.joystickCenter = { x: pointer.x, y: pointer.y };
    this.joystickBase.setPosition(pointer.x, pointer.y).setVisible(true);
    this.joystickThumb.setPosition(pointer.x, pointer.y);
  }

  private moveJoystick(pointer: Phaser.Input.Pointer): void {
    const dx = pointer.x - this.joystickCenter.x;
    const dy = pointer.y - this.joystickCenter.y;
    const dist = Math.sqrt(dx * dx + dy * dy);
    const clamped = Math.min(dist, this.joystickRadius);
    const ratio = clamped / this.joystickRadius;
    const angle = Math.atan2(dy, dx);

    this.joystick.x = Math.cos(angle) * ratio;
    this.joystick.y = Math.sin(angle) * ratio;
    this.joystick.angle = angle * (180 / Math.PI);
    this.joystick.distance = ratio;

    this.joystickThumb.setPosition(
      this.joystickCenter.x + Math.cos(angle) * clamped,
      this.joystickCenter.y + Math.sin(angle) * clamped,
    );
  }

  private stopJoystick(): void {
    this.joystickPointerId = null;
    this.joystick = { active: false, x: 0, y: 0, angle: 0, distance: 0 };
    this.joystickThumb.setPosition(this.joystickCenter.x, this.joystickCenter.y);
  }

  /** Call in scene's update() to apply movement to a physics body. */
  applyToSprite(sprite: Phaser.Physics.Arcade.Sprite, speed = 250): void {
    if (this.joystick.active) {
      sprite.setVelocity(
        this.joystick.x * speed,
        this.joystick.y * speed,
      );
    } else {
      sprite.setVelocity(0, 0);
    }
  }

  destroy(): void {
    this.joystickBase.destroy();
    this.joystickThumb.destroy();
    this.btnA.destroy();
    this.btnB.destroy();
  }
}
```

**Usage:**
```typescript
// In GameScene.create():
const isMobile = this.sys.game.device.os.android || this.sys.game.device.os.iOS;
if (isMobile) {
  this.gamepad = new VirtualGamepad(this);
}

// In GameScene.update():
if (this.gamepad) {
  this.gamepad.applyToSprite(this.player, 250);
  if (this.gamepad.buttonA) this.player.jump();
}
```

---

## 3. OrientationGuard

Shows a "Please rotate your device" overlay when a landscape-required game is viewed in portrait.

```typescript
// OrientationGuard.ts

export class OrientationGuard {
  private overlay: Phaser.GameObjects.Container | null = null;
  private readonly scene: Phaser.Scene;
  private readonly requiredOrientation: 'landscape' | 'portrait';

  constructor(scene: Phaser.Scene, required: 'landscape' | 'portrait' = 'landscape') {
    this.scene = scene;
    this.requiredOrientation = required;
    this.check();

    scene.scale.on('orientationchange', () => this.check());
    scene.scale.on('resize', () => this.check());
  }

  private check(): void {
    const { width, height } = this.scene.scale;
    const isLandscape = width > height;
    const needsOverlay =
      (this.requiredOrientation === 'landscape' && !isLandscape) ||
      (this.requiredOrientation === 'portrait'  &&  isLandscape);

    if (needsOverlay) {
      this.showOverlay();
    } else {
      this.hideOverlay();
    }
  }

  private showOverlay(): void {
    if (this.overlay) return;  // Already showing

    const { width, height } = this.scene.scale;

    const bg = this.scene.add.rectangle(0, 0, width * 2, height * 2, 0x000000, 0.9);

    const icon = this.scene.add.text(0, -60, '↻', {
      fontSize: '80px',
      color: '#ffffff',
    }).setOrigin(0.5);

    const msg = this.scene.add.text(0, 40, 'Rotate your device', {
      fontSize: '24px',
      color: '#ffffff',
      fontFamily: 'Arial, sans-serif',
    }).setOrigin(0.5);

    const sub = this.scene.add.text(0, 80, 'This game requires landscape mode', {
      fontSize: '16px',
      color: '#aaaaaa',
      fontFamily: 'Arial, sans-serif',
    }).setOrigin(0.5);

    this.overlay = this.scene.add.container(width / 2, height / 2, [bg, icon, msg, sub]);
    this.overlay.setDepth(9999);
    this.overlay.setScrollFactor(0);

    // Pause game logic while overlay is showing
    this.scene.physics.pause();
  }

  private hideOverlay(): void {
    if (!this.overlay) return;
    this.overlay.destroy();
    this.overlay = null;
    this.scene.physics.resume();
  }

  destroy(): void {
    this.overlay?.destroy();
    this.scene.scale.off('orientationchange');
  }
}
```

**Usage:**
```typescript
// In GameScene.create():
this.orientationGuard = new OrientationGuard(this, 'landscape');
```

---

## 4. MobileAudioUnlock

```typescript
// MobileAudioUnlock.ts

export class MobileAudioUnlock {
  /**
   * Show a "Tap to Start" overlay if audio is locked.
   * Calls onUnlocked() once the player taps and audio is ready.
   * No-ops immediately if audio is already unlocked.
   */
  static setup(scene: Phaser.Scene, onUnlocked: () => void): void {
    if (!scene.sound.locked) {
      onUnlocked();
      return;
    }

    const { width, height } = scene.scale;

    const overlay = scene.add.container(0, 0).setDepth(9998).setScrollFactor(0);

    const bg = scene.add
      .rectangle(width / 2, height / 2, width, height, 0x000000, 0.85)
      .setInteractive();  // Make the whole overlay tappable

    const logo = scene.add.text(width / 2, height * 0.35, '🎮', {
      fontSize: '72px',
    }).setOrigin(0.5);

    const title = scene.add.text(width / 2, height * 0.52, 'TAP TO START', {
      fontSize: `${Math.round(height * 0.07)}px`,
      color: '#ffffff',
      fontFamily: 'Arial Black, sans-serif',
      fontStyle: 'bold',
    }).setOrigin(0.5);

    const hint = scene.add.text(width / 2, height * 0.65, 'Tap anywhere to continue', {
      fontSize: `${Math.round(height * 0.03)}px`,
      color: '#888888',
      fontFamily: 'Arial, sans-serif',
    }).setOrigin(0.5);

    // Pulsing animation on the title
    scene.tweens.add({
      targets: title,
      alpha: 0.4,
      duration: 800,
      ease: 'Sine.easeInOut',
      yoyo: true,
      repeat: -1,
    });

    overlay.add([bg, logo, title, hint]);

    // Phaser fires UNLOCKED once the AudioContext resumes (on first tap)
    scene.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
      overlay.destroy();
      onUnlocked();
    });
  }
}
```

**Usage:**
```typescript
create(): void {
  this.bgMusic = this.sound.add('music-main', { loop: true, volume: 0.6 });

  MobileAudioUnlock.setup(this, () => {
    this.bgMusic.play();
    this.startGame();
  });
}
```

---

## 5. DeviceCapabilities Detection

```typescript
// DeviceCapabilities.ts

export type ScreenCategory = 'small-phone' | 'phone' | 'tablet' | 'desktop';

export interface DeviceCapabilities {
  isMobile: boolean;
  isTablet: boolean;
  isDesktop: boolean;
  hasTouch: boolean;
  isIOS: boolean;
  isAndroid: boolean;
  screenCategory: ScreenCategory;
  pixelRatio: number;
  screenWidth: number;
  screenHeight: number;
  isLandscape: boolean;
  maxTextureSize: number;
}

export function getDeviceCapabilities(scene: Phaser.Scene): DeviceCapabilities {
  const device = scene.sys.game.device;
  const w = window.screen.width  * window.devicePixelRatio;
  const h = window.screen.height * window.devicePixelRatio;
  const shortSide = Math.min(w, h);

  const isMobile = device.os.android || device.os.iOS;
  const isTablet = isMobile && Math.min(window.innerWidth, window.innerHeight) > 600;

  let screenCategory: ScreenCategory;
  if (!isMobile)           screenCategory = 'desktop';
  else if (isTablet)       screenCategory = 'tablet';
  else if (shortSide < 400) screenCategory = 'small-phone';
  else                     screenCategory = 'phone';

  // Max texture size from WebGL renderer
  const renderer = scene.sys.game.renderer as Phaser.Renderer.WebGL.WebGLRenderer | null;
  const maxTextureSize = renderer?.gl
    ? renderer.gl.getParameter(renderer.gl.MAX_TEXTURE_SIZE) as number
    : 4096;

  return {
    isMobile,
    isTablet,
    isDesktop: !isMobile,
    hasTouch: device.input.touch,
    isIOS: device.os.iOS,
    isAndroid: device.os.android,
    screenCategory,
    pixelRatio: window.devicePixelRatio,
    screenWidth: window.innerWidth,
    screenHeight: window.innerHeight,
    isLandscape: window.innerWidth > window.innerHeight,
    maxTextureSize,
  };
}

// Usage:
// const caps = getDeviceCapabilities(this);
// if (caps.isMobile) this.createVirtualControls();
// if (caps.maxTextureSize < 2048) this.useSmallTextures();
// if (caps.screenCategory === 'small-phone') this.scaleFontDown();
```

---

## 6. Capacitor Native Plugin Integration

Access native device features (haptics, orientation lock) via Capacitor plugins when deployed as a native app.

```typescript
// native-bridge.ts
// Wraps Capacitor plugins with web fallbacks so the same code runs in browser and native.

// Install: npm install @capacitor/haptics @capacitor/screen-orientation @capacitor/device

type HapticStyle = 'light' | 'medium' | 'heavy';

export class NativeBridge {
  private static isNative = typeof (window as any).Capacitor !== 'undefined';

  /**
   * Trigger haptic feedback (vibration).
   * No-op in browser — only fires on iOS/Android via Capacitor.
   */
  static async vibrate(style: HapticStyle = 'medium'): Promise<void> {
    if (!NativeBridge.isNative) return;
    try {
      const { Haptics, ImpactStyle } = await import('@capacitor/haptics');
      const styleMap: Record<HapticStyle, typeof ImpactStyle[keyof typeof ImpactStyle]> = {
        light: ImpactStyle.Light,
        medium: ImpactStyle.Medium,
        heavy: ImpactStyle.Heavy,
      };
      await Haptics.impact({ style: styleMap[style] });
    } catch {
      // Haptics not available — ignore
    }
  }

  /**
   * Lock screen orientation. Browser fallback uses screen.orientation.lock().
   */
  static async lockOrientation(orientation: 'landscape' | 'portrait'): Promise<void> {
    if (NativeBridge.isNative) {
      try {
        const { ScreenOrientation } = await import('@capacitor/screen-orientation');
        await ScreenOrientation.lock({ orientation: `${orientation}-primary` as OrientationType });
      } catch { /* ignore */ }
    } else {
      try {
        await screen.orientation?.lock?.(orientation as OrientationLockType);
      } catch { /* browser may not support this */ }
    }
  }

  /**
   * Get device info.
   */
  static async getDeviceInfo(): Promise<{ platform: string; model: string; osVersion: string }> {
    if (NativeBridge.isNative) {
      try {
        const { Device } = await import('@capacitor/device');
        const info = await Device.getInfo();
        return { platform: info.platform, model: info.model, osVersion: info.osVersion };
      } catch { /* ignore */ }
    }
    return { platform: 'web', model: navigator.userAgent, osVersion: 'unknown' };
  }
}

// Usage in Phaser scene:
// On player hit:
// await NativeBridge.vibrate('light');
//
// On game over:
// await NativeBridge.vibrate('heavy');
//
// On game start:
// await NativeBridge.lockOrientation('landscape');
```

---

## Texture Loading for Mobile

```typescript
// preload() — load different atlas sizes based on device capability
preload(): void {
  const caps = getDeviceCapabilities(this);

  if (caps.maxTextureSize >= 2048 && !caps.isMobile) {
    // High-res desktop atlas
    this.load.atlas('game-sprites', 'assets/atlas-2048.png', 'assets/atlas-2048.json');
  } else {
    // Mobile-safe atlas
    this.load.atlas('game-sprites', 'assets/atlas-1024.png', 'assets/atlas-1024.json');
  }
}
```

---

## Quick Reference: Common Mobile Issues

| Issue | Cause | Fix |
|---|---|---|
| Game scrolls/pans on mobile | Browser intercepting touch events | `addEventListener('touchmove', e => e.preventDefault(), { passive: false })` |
| Audio silent on iOS | AudioContext not unlocked | Use `MobileAudioUnlock` or check `this.sound.locked` |
| Game too small on phone | Missing viewport meta tag | Add `<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">` |
| Blurry sprites on retina | Default canvas pixel ratio | Phaser handles this automatically; ensure `pixelArt: false` is not overriding |
| FPS drops on Android | Too many draw calls | Use texture atlases; limit particles; reduce dynamic physics bodies |
| Double-tap zooms in | Browser gesture | Add double-tap prevention listener |
| Landscape lock not working | Browser restriction on orientation lock | Must trigger from user gesture; use Capacitor for reliable lock |
| Context menu appears on long press | Browser default behavior | `document.addEventListener('contextmenu', e => e.preventDefault())` |

---
name: phaser-mobile
description: This skill should be used when the user asks to "mobile game", "responsive game", "touch controls", "deploy to phone", "Capacitor", "PWA game", "scale manager", "orientation", "iOS game", "Android game", "full screen game", "mobile performance", etc.
version: 0.4.0
---

# Phaser 4 Mobile & Responsive

This guide covers Scale Manager configuration, touch controls, browser gesture prevention, mobile performance, Capacitor deployment, and PWA setup.

## Scale Manager Configuration

The Scale Manager controls how Phaser maps its internal resolution to the screen.

```typescript
// In GameConfig:
const config: Phaser.Types.Core.GameConfig = {
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
    width: 800,
    height: 600,
  },
};
```

### Scale Modes

| Mode | Behavior | Use case |
|---|---|---|
| `Phaser.Scale.FIT` | Letterboxed, preserves aspect ratio | Fixed-resolution games (most common) |
| `Phaser.Scale.ENVELOP` | Fills screen, may crop edges | Backgrounds, casual games |
| `Phaser.Scale.RESIZE` | Canvas resizes to exact window size | Adaptive UI games (complex) |
| `Phaser.Scale.NONE` | No scaling, original pixel size | Desktop-only games |

**FIT** is correct for most games. The canvas scales to fit the container while preserving your aspect ratio, adding letterbox bars if needed.

**RESIZE** gives you a fluid canvas but requires all UI and layout code to respond to size changes. Use it only when you genuinely need the game to fill every device shape.

### RESIZE Mode with Dynamic Layout

```typescript
// GameConfig for RESIZE:
scale: {
  mode: Phaser.Scale.RESIZE,
  autoCenter: Phaser.Scale.CENTER_BOTH,
  // No fixed width/height — canvas matches window
}

// In the scene:
create(): void {
  this.layoutUI(this.scale.width, this.scale.height);

  // Re-layout whenever window resizes (orientation change, keyboard appearing, etc.)
  this.scale.on('resize', (size: Phaser.Structs.Size) => {
    this.cameras.main.setSize(size.width, size.height);
    this.layoutUI(size.width, size.height);
  });
}

private layoutUI(w: number, h: number): void {
  this.scoreText?.setPosition(w * 0.05, h * 0.05);
  this.healthBar?.setPosition(w * 0.5, h * 0.95);
  this.pauseBtn?.setPosition(w - 40, 40);
}
```

## Touch Controls

Phaser pointer events work on mobile automatically — `pointerdown`, `pointerup`, `pointermove` all fire for touch.

**Tap target minimum:** 44×44 logical pixels. Smaller targets cause missed taps on mobile.

```typescript
// Simple tap interaction (works on both mouse and touch)
const btn = this.add.image(x, y, 'button')
  .setInteractive()
  .on('pointerdown', () => this.handleTap())
  .on('pointerover', () => btn.setTint(0xdddddd))
  .on('pointerout',  () => btn.clearTint());
```

For directional control on mobile, see `references/mobile-patterns.md` — `VirtualGamepad` class.

## Responsive Layout

Position UI elements as fractions of screen dimensions so they work on any resolution.

```typescript
create(): void {
  const { width, height } = this.scale;

  // Top-left HUD
  this.scoreText = this.add.text(width * 0.05, height * 0.05, 'Score: 0', {
    fontSize: `${Math.round(height * 0.05)}px`,
    color: '#ffffff',
  });

  // Bottom-center action button
  this.actionBtn = this.add.image(width * 0.5, height * 0.9, 'btn-action')
    .setInteractive()
    .setDisplaySize(width * 0.15, width * 0.15); // square button, proportional to width
}
```

**Font size tip:** Scale font sizes to `height * 0.04–0.06`. Fixed pixel sizes look enormous on small screens.

## Preventing Browser Gestures

Mobile browsers intercept touch events for zoom, scroll, and context menus. Prevent these for a native-feeling game.

```typescript
// In your game's index.html or a boot script (not inside Phaser scenes):

// Prevent pinch-to-zoom and scroll
document.addEventListener('touchmove', (e) => e.preventDefault(), { passive: false });

// Prevent double-tap zoom on iOS
let lastTap = 0;
document.addEventListener('touchend', (e) => {
  const now = Date.now();
  if (now - lastTap < 300) e.preventDefault();
  lastTap = now;
});

// Prevent right-click / long-press context menu
document.addEventListener('contextmenu', (e) => e.preventDefault());
```

```typescript
// Inside a Phaser scene:
// Disable right-click context menu on the canvas
this.input.mouse?.disableContextMenu();
```

```typescript
// Lock to landscape orientation (for most action games)
// Must be triggered from a user interaction (button press), not on load
async lockOrientation(): Promise<void> {
  try {
    await screen.orientation?.lock?.('landscape-primary');
  } catch {
    // Not supported on all browsers/platforms — fail silently
  }
}
```

## Mobile Audio Unlock

iOS and Android block audio playback until the user interacts with the page. Phaser handles this automatically by listening for the first pointer/key event and resuming `AudioContext` at that moment.

For games that play audio immediately on load (opening jingle, ambient sound), show a "Tap to Start" overlay:

```typescript
create(): void {
  this.bgMusic = this.sound.add('music-main', { loop: true, volume: 0.6 });

  if (this.sound.locked) {
    // Show overlay — audio will unlock when user taps
    const overlay = this.add.rectangle(
      this.scale.width / 2, this.scale.height / 2,
      this.scale.width, this.scale.height,
      0x000000, 0.75
    ).setInteractive().setDepth(100);

    this.add.text(
      this.scale.width / 2, this.scale.height / 2,
      'TAP TO START', { fontSize: '32px', color: '#ffffff' }
    ).setOrigin(0.5).setDepth(101);

    this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
      overlay.destroy();
      this.bgMusic.play();
    });
  } else {
    this.bgMusic.play();
  }
}
```

## Device Detection

```typescript
create(): void {
  const device = this.sys.game.device;
  const isMobile = device.os.android || device.os.iOS;
  const isTablet = isMobile && Math.min(window.innerWidth, window.innerHeight) > 600;
  const hasTouch = device.input.touch;

  if (isMobile) {
    this.createVirtualControls();
  } else {
    // Show keyboard hint for desktop
    this.add.text(16, this.scale.height - 30, 'WASD / Arrow Keys to move', {
      fontSize: '14px', color: '#aaaaaa',
    });
  }
}

private createVirtualControls(): void {
  // See references/mobile-patterns.md for VirtualGamepad class
}
```

Other useful device flags:
- `device.os.windows`, `device.os.macOS`, `device.os.linux`
- `device.browser.chrome`, `device.browser.safari`, `device.browser.firefox`
- `device.features.webGL` — WebGL support check

## Performance on Mobile

Mobile GPUs and CPUs are significantly weaker than desktop. Apply these constraints to maintain 60fps on mid-range devices.

**Textures:**
- Maximum atlas size: 2048×2048 px. Prefer 1024×1024 for compatibility with older devices.
- Use texture atlases — minimizes GPU state switches between draw calls.
- Reduce total unique textures: fewer unique textures = fewer draw calls.

**Physics:**
- Fewer dynamic bodies = better FPS. Target under 50 simultaneous dynamic bodies on mobile.
- Disable physics on objects that are off-screen.

**Particles:**
- Set `maxParticles` on all emitters. Hard limit: 50–100 particles max on mobile.
- Use simple particle textures (single-color squares/circles) — complex textures cost more.

**Camera effects:**
- `camera.shake()` and rapid `camera.zoom` are GPU-heavy. Use sparingly.
- Simple screen flash (`camera.flash()`) is fine.

**Pixel art games:**
```typescript
const config: Phaser.Types.Core.GameConfig = {
  pixelArt: true,       // disables antialiasing — required for crisp pixel art
  roundPixels: true,    // prevents sub-pixel rendering artifacts
  // These two together are a free performance win for pixel-art games
};
```

**FPS monitoring in debug builds:**
```typescript
// Show FPS counter during development
create(): void {
  if (import.meta.env.DEV) {
    this.add.text(4, 4, '', { fontSize: '12px', color: '#00ff00' })
      .setDepth(999)
      .setScrollFactor(0);
    // Update in update():
    // fpsText.setText(`FPS: ${Math.round(this.game.loop.actualFps)}`);
  }
}
```

Target 60fps. If you can't sustain 60, accept 30fps with `physics.arcade.fps: 30` and `this.game.loop.targetFps = 30` — choppy 45fps is worse than smooth 30fps.

## Capacitor Deployment (iOS / Android)

Capacitor wraps your web build in a native WebView, giving you a real app store binary.

```bash
# Install Capacitor
npm install @capacitor/core @capacitor/cli @capacitor/ios @capacitor/android

# Initialize (run once)
npx cap init "My Game" com.mygame.app --web-dir=dist

# Build the web project
npm run build

# Add native platforms (run once)
npx cap add ios
npx cap add android

# Sync web build into native projects
npx cap sync

# Open in Xcode (requires macOS + Xcode)
npx cap open ios

# Open in Android Studio
npx cap open android
```

After `cap open ios`, set your Team in Xcode's Signing & Capabilities tab, then build to device or simulator.

### Capacitor Config (capacitor.config.ts)

```typescript
import { CapacitorConfig } from '@capacitor/cli';

const config: CapacitorConfig = {
  appId: 'com.mygame.app',
  appName: 'My Game',
  webDir: 'dist',
  server: {
    androidScheme: 'https',
  },
  plugins: {
    SplashScreen: {
      launchShowDuration: 0,  // Hide splash immediately for games with their own loading screen
    },
  },
};

export default config;
```

### Native Features via Capacitor Plugins

```typescript
import { Haptics, ImpactStyle } from '@capacitor/haptics';
import { ScreenOrientation } from '@capacitor/screen-orientation';

// Vibration on hit
await Haptics.impact({ style: ImpactStyle.Medium });

// Lock orientation (native — more reliable than screen.orientation.lock on mobile)
await ScreenOrientation.lock({ orientation: 'landscape' });
```

## PWA Setup

Turn your game into an installable Progressive Web App with two files.

```json
// public/manifest.json
{
  "name": "My Game",
  "short_name": "MyGame",
  "description": "An awesome Phaser 4 game",
  "display": "fullscreen",
  "orientation": "landscape",
  "background_color": "#000000",
  "theme_color": "#000000",
  "start_url": "./index.html",
  "icons": [
    { "src": "icons/icon-192.png", "sizes": "192x192", "type": "image/png" },
    { "src": "icons/icon-512.png", "sizes": "512x512", "type": "image/png" },
    { "src": "icons/icon-512.png", "sizes": "512x512", "type": "image/png", "purpose": "maskable" }
  ]
}
```

```html
<!-- In index.html <head>: -->
<link rel="manifest" href="./manifest.json">
<meta name="apple-mobile-web-app-capable" content="yes">
<meta name="apple-mobile-web-app-status-bar-style" content="black-translucent">
<meta name="theme-color" content="#000000">
<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
```

For full PWA with offline support, add a service worker (Vite's `vite-plugin-pwa` handles this automatically).

```bash
npm install -D vite-plugin-pwa
```

```typescript
// vite.config.ts
import { VitePWA } from 'vite-plugin-pwa';

export default {
  plugins: [
    VitePWA({
      registerType: 'autoUpdate',
      manifest: false, // use your own public/manifest.json
      workbox: {
        globPatterns: ['**/*.{js,css,html,png,ogg,mp3,json}'],
      },
    }),
  ],
};
```

## Device-Specific Profiles

See `references/device-profiles.md` for complete profiles with gotchas and recommended configs.

### Quick Decision Matrix

| Decision | iOS Safari | Android Chrome | Desktop | Capacitor | PWA |
|----------|-----------|---------------|---------|-----------|-----|
| Audio format priority | mp3 (ogg unsupported) | mp3+ogg | any | mp3+ogg | mp3+ogg |
| Max atlas size | 2048x2048 | 2048x2048 (low-end) | 4096+ | 2048x2048 | 2048x2048 |
| Orientation lock | Capacitor only | Fullscreen API | N/A | Native plugin | manifest.json |
| Virtual controls | Required | Required | Optional | Required | Required |
| Haptic feedback | No | No | No | Yes (plugin) | No |
| Offline support | Limited (50MB) | Yes | N/A | Built-in | Service worker |
| Install prompt | Add to Home Screen | Install banner | N/A | App Store | Browser prompt |

### Choosing Your Primary Platform

- **Web-only (itch.io, portfolio):** Desktop-first config, FIT scale mode, 800x600 or 1280x720
- **Mobile-first:** FIT scale mode, 640x360 landscape or 360x640 portrait, virtual controls
- **Cross-platform:** FIT scale mode, detect device at runtime, adapt controls and asset quality
- **Native app (App Store / Play Store):** Capacitor + platform-specific optimizations

## Additional Resources

### Reference Files
- **`references/mobile-patterns.md`** — Full responsive GameConfig, VirtualGamepad class (joystick + buttons), OrientationGuard overlay, MobileAudioUnlock component, DeviceCapabilities detection, Capacitor native plugin integration
- **`references/device-profiles.md`** — Device-specific optimization profiles for iOS Safari, Android Chrome, Desktop, Capacitor (iOS/Android), and PWA with recommended GameConfig per target

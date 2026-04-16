# Device-Specific Optimization Profiles

Comprehensive profiles for each target platform, including texture limits, audio requirements, gotchas, and recommended GameConfig settings.

## iOS Safari Profile

- **Max texture:** 4096x4096 (prefer 2048 for older iPads/iPhones)
- **Audio:** mp3 REQUIRED — Safari does NOT support ogg. Always provide mp3 as first format.
- **AudioContext unlock:** mandatory on first user gesture (Phaser handles automatically, but show "Tap to Start" if audio needed immediately)
- **Orientation lock:** `screen.orientation.lock()` NOT supported in Safari — use Capacitor `@capacitor/screen-orientation` plugin for native
- **Safe area insets:** account for notch with `env(safe-area-inset-top)` etc. in CSS
- **WebGL:** full Phaser Beam support
- **Touch:** up to 5 simultaneous touch points
- **Gotcha:** `100vh` includes Safari toolbar — use `window.innerHeight` instead for accurate viewport height
- **Gotcha:** iOS 16.4+ required for PWA push notifications
- **Performance target:** 60fps on iPhone 12+, accept 30fps on iPhone 8/SE

## Android Chrome Profile

- **Max texture:** varies (2048 on low-end Snapdragon 400-series, 4096+ on flagship)
- **Audio:** mp3 AND ogg both supported — provide both for best compatibility
- **AudioContext unlock:** mandatory on first user gesture
- **Orientation lock:** `screen.orientation.lock()` works from fullscreen mode
- **WebGL:** full support but watch for WebGL context loss on low-memory devices (handle with `game.events.on('contextlost')`)
- **Touch:** up to 10 simultaneous touch points
- **Gotcha:** hardware Back button triggers `popstate` event — handle or prevent to avoid accidental navigation
- **Gotcha:** some older Android WebViews don't support ES2020 — check your Capacitor minimum SDK version
- **Performance baseline:** test on Snapdragon 600-series (mid-range 2022) as floor device

## Desktop Browsers (Chrome/Firefox/Safari/Edge)

- **Max texture:** 8192+ (effectively unlimited for 2D Phaser games)
- **Audio:** all formats supported on all modern browsers
- **No audio unlock** typically needed (desktop users have interacted by the time they navigate to the game)
- **Keyboard + mouse** is primary input
- **Gamepad support** via Gamepad API (works in all major browsers)
- **Performance:** rarely a concern for 2D Phaser games on desktop
- **Resolution:** design for 1920x1080, Phaser.Scale.FIT handles the rest
- **Gotcha:** Safari has stricter autoplay policies than Chrome

## Capacitor iOS (Native)

Inherits all iOS Safari constraints PLUS:

- **Haptics** via `@capacitor/haptics` (ImpactStyle.Light/Medium/Heavy)
- **Reliable orientation lock** via `@capacitor/screen-orientation`
- **Splash screen control** via `@capacitor/splash-screen` (set `launchShowDuration: 0` for games with own loading screen)
- **App Store requirements:** no external code loading (all JS must be bundled), privacy manifest required since iOS 17
- **Minimum deployment target:** iOS 14+ recommended

## Capacitor Android (Native)

Inherits all Android Chrome constraints PLUS:

- **Haptics** via `@capacitor/haptics`
- **Reliable orientation lock** via `@capacitor/screen-orientation`
- **Google Play requirements:** target API level 34+, privacy policy required, content rating questionnaire
- **Minimum SDK:** API 22 (Android 5.1) recommended

## PWA Profile

- **Service worker** required for installability
- **`manifest.json` with icons:** 192x192 and 512x512 (plus maskable variant)
- **Offline:** cache all game assets in service worker (Workbox via `vite-plugin-pwa`)
- **Update strategy:** `registerType: 'autoUpdate'` recommended for games
- **Display:** `"fullscreen"` for game-like experience (no browser chrome)
- **Orientation:** set in `manifest.json` — `"orientation": "landscape"` or `"portrait"`
- **Gotcha:** iOS PWAs have limited cache (50MB max), keep total assets under 40MB

## Recommended GameConfig Per Target

### Mobile-first (phone + tablet)

```typescript
const config: Phaser.Types.Core.GameConfig = {
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  width: 360, height: 640,   // portrait
  // OR width: 640, height: 360  // landscape
  pixelArt: true,  // if pixel art style — free performance win
  roundPixels: true,
};
```

### Desktop-first (with mobile fallback)

```typescript
const config: Phaser.Types.Core.GameConfig = {
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  width: 800, height: 600,
  // OR width: 1280, height: 720 for widescreen
};
```

### Cross-platform adaptive

```typescript
const isMobile = /android|iphone|ipad|ipod/i.test(navigator.userAgent);
const config: Phaser.Types.Core.GameConfig = {
  scale: { mode: Phaser.Scale.FIT, autoCenter: Phaser.Scale.CENTER_BOTH },
  width: isMobile ? 640 : 1280,
  height: isMobile ? 360 : 720,
};
// In-game: use device detection for:
// - Atlas resolution (1024 vs 2048)
// - Enable/disable particle effects on low-end
// - Show/hide virtual controls
// - Adjust physics body count limits
```

---
name: phaser-audio
description: This skill should be used when the user asks to "add sound", "play music", "audio not working", "add background music", "sound effects", "mute button", "audio sprite", "game audio", "play sound effect", or "music won't play".
version: 0.2.0
---

# Phaser 4 Audio

Phaser 4 wraps the Web Audio API for all audio playback. Know when each audio backend applies and follow the loading/playback patterns below to avoid the most common audio bugs.

## Web Audio vs HTML5 Audio

Phaser uses **Web Audio** by default on every browser that supports it (all modern browsers). Web Audio runs audio processing on a dedicated thread, supports spatial audio, effects chains, precise scheduling, and is never subject to the single-track limit that plagues HTML5 Audio.

HTML5 Audio is the automatic fallback when `AudioContext` is unavailable — typically older Android WebViews and some edge-case browser configurations. You rarely target it intentionally. If you must force it:

```typescript
const config: Phaser.Types.Core.GameConfig = {
  audio: {
    disableWebAudio: true,   // force HTML5 Audio fallback
  },
};
```

**Never force HTML5 Audio unless you have a specific compatibility requirement.** Its limitations — single concurrent track, no detune/rate, no spatial positioning — will constrain your design.

## Loading Audio: Always Provide mp3 AND ogg

Browsers do not agree on a single audio codec. Safari and iOS require **mp3**. Firefox prefers **ogg/vorbis**. Chrome accepts both. Provide both formats and let Phaser pick the one the browser supports:

```typescript
// preload()
preload(): void {
  // ALWAYS provide both formats as an array — mp3 first, ogg second
  this.load.audio('music-main', ['assets/audio/main.mp3', 'assets/audio/main.ogg']);
  this.load.audio('sfx-jump',   ['assets/audio/jump.mp3',  'assets/audio/jump.ogg']);
  this.load.audio('sfx-coin',   ['assets/audio/coin.mp3',  'assets/audio/coin.ogg']);
  this.load.audio('sfx-hurt',   ['assets/audio/hurt.mp3',  'assets/audio/hurt.ogg']);
}
```

Never load a single format. A game that works perfectly on your Chrome dev machine will be completely silent on Safari/iOS if you only ship `.ogg`.

## Adding and Playing Sounds

### `this.sound.add()` — Full Control

Use `add()` when you need a reference to control the sound (pause, resume, seek, adjust volume, listen for events):

```typescript
create(): void {
  const music = this.sound.add('music-main', {
    loop: true,
    volume: 0.6,
  });
  music.play();
  this.music = music;
}
```

### `this.sound.play()` — One-Shot Fire-and-Forget

Use the manager's `play()` for sounds you fire once and never need to reference again. Phaser manages the lifetime automatically:

```typescript
// In update() or an event handler:
this.sound.play('sfx-coin', { volume: 0.9 });
this.sound.play('sfx-jump', { volume: 1.0, rate: 1.1 });
```

**Rule of thumb:** Background music → `add()`. One-shot SFX → `sound.play()`.

## SoundConfig Options

Pass a `SoundConfig` object as the second argument to `add()` or as the second argument to `play()`:

```typescript
const config: Phaser.Types.Sound.SoundConfig = {
  loop:   false,   // boolean — loop the sound (default: false)
  volume: 1,       // number 0–1 — per-sound volume (default: 1)
  rate:   1,       // number — playback speed multiplier (default: 1; 2 = double speed)
  detune: 0,       // number — cents offset from base pitch (default: 0; 100 = 1 semitone)
  seek:   0,       // number — start position in seconds (default: 0)
  delay:  0,       // number — seconds to wait before playing (default: 0)
};
```

## Background Music

Background music loops continuously, needs volume control, and must be stopped on scene shutdown.

```typescript
// --- In PreloaderScene.preload() ---
this.load.audio('music-game', ['assets/audio/game.mp3', 'assets/audio/game.ogg']);
this.load.audio('music-menu', ['assets/audio/menu.mp3', 'assets/audio/menu.ogg']);

// --- In GameScene.create() ---
this.bgMusic = this.sound.add('music-game', { loop: true, volume: 0.5 });
this.bgMusic.play();

// Adjust volume at runtime
this.bgMusic.setVolume(0.3);

// Pause/resume (e.g. on pause screen)
this.bgMusic.pause();
this.bgMusic.resume();

// Stop (e.g. on scene shutdown)
this.bgMusic.stop();
```

## SFX Pattern: One-Shot Sounds

For sound effects that fire and forget — coin pickups, gunshots, UI clicks — use `this.sound.play()` directly. Do not store a reference:

```typescript
// In any scene method or event handler:
this.sound.play('sfx-coin',  { volume: 0.9 });
this.sound.play('sfx-jump',  { volume: 1.0, rate: 1.05 });
this.sound.play('sfx-death', { volume: 0.8, detune: -200 });
```

Phaser creates an internal instance, plays it to completion, then destroys it. Zero cleanup required.

## Sound Pooling for Rapid SFX

If a sound fires many times per second (gunshots, footsteps, rapid UI feedback), a single instance causes audible cutoff — each new `play()` call restarts the same sound from the beginning.

Pre-create a pool of instances and round-robin through them:

```typescript
create(): void {
  // Create a pool of 5 gunshot sounds
  this.gunshotPool = [];
  for (let i = 0; i < 5; i++) {
    this.gunshotPool.push(this.sound.add('sfx-gunshot', { volume: 0.8 }));
  }
  this.poolIndex = 0;
}

private fireGunshot(): void {
  const snd = this.gunshotPool[this.poolIndex];
  // Stop any currently playing instance at this slot, then play fresh
  if (snd.isPlaying) snd.stop();
  snd.play();
  this.poolIndex = (this.poolIndex + 1) % this.gunshotPool.length;
}
```

Pool size guideline: match the maximum overlapping instances you expect. For footsteps, 3–4 is usually sufficient.

## Audio Sprites

Audio sprites pack multiple short sounds into a single audio file with a JSON marker file. This reduces HTTP requests and is ideal for mobile where audio loading is slow.

### Loading

```typescript
// preload()
this.load.audioSprite(
  'sfx-pack',                         // key
  'assets/audio/sfx-pack.json',       // JSON with marker definitions
  ['assets/audio/sfx-pack.mp3', 'assets/audio/sfx-pack.ogg']  // audio files
);
```

### Playing

```typescript
// this.sound.playAudioSprite(key, markerName, config?)
this.sound.playAudioSprite('sfx-pack', 'coin');
this.sound.playAudioSprite('sfx-pack', 'jump', { volume: 0.8 });
this.sound.playAudioSprite('sfx-pack', 'hurt', { rate: 1.2 });
```

### JSON Format

```json
{
  "resources": ["sfx-pack.mp3", "sfx-pack.ogg"],
  "spritemap": {
    "coin":  { "start": 0.0,  "end": 0.4,  "loop": false },
    "jump":  { "start": 0.5,  "end": 0.85, "loop": false },
    "hurt":  { "start": 1.0,  "end": 1.6,  "loop": false },
    "music": { "start": 2.0,  "end": 34.0, "loop": true  }
  }
}
```

See `references/audio-api.md` for the full AudioSprite JSON schema.

## Volume Management

```typescript
// Global volume (affects all sounds)
this.sound.volume = 0.5;          // set
const vol = this.sound.volume;    // get

// Per-sound volume
music.setVolume(0.4);
const soundVol = music.volume;

// Mute/unmute everything
this.sound.mute = true;           // mute all
this.sound.mute = false;          // unmute all

// Check if global mute is on
const isMuted = this.sound.mute;
```

### Mute Button Pattern

```typescript
create(): void {
  const muteBtn = this.add.image(750, 30, 'btn-mute').setInteractive();
  muteBtn.on('pointerdown', () => {
    this.sound.mute = !this.sound.mute;
    muteBtn.setTexture(this.sound.mute ? 'btn-unmute' : 'btn-mute');
  });
}
```

## Mobile Audio Unlock

Mobile browsers and some desktop browsers block audio playback until the user interacts with the page. This is enforced at the browser level — there is no workaround.

**Phaser handles this automatically.** It listens for the first `pointerdown` or `keydown` event and resumes the `AudioContext` at that moment. All sounds queued before that point will begin playing immediately after unlock.

Check if audio is locked:

```typescript
if (this.sound.locked) {
  // AudioContext has not yet been unlocked
  // Show a "tap to start" overlay
}

// Listen for the unlock event
this.sound.on(Phaser.Sound.Events.UNLOCKED, () => {
  // Now safe to play audio
  this.bgMusic.play();
});
```

**Best practice for audio-critical games:** Show a full-screen "Tap to Start" overlay. When the player taps it, dismiss it. Phaser's internal unlock fires at the same time, so audio starts on the next `play()` call.

```typescript
create(): void {
  this.bgMusic = this.sound.add('music-main', { loop: true, volume: 0.6 });

  if (this.sound.locked) {
    const overlay = this.add.rectangle(400, 300, 800, 600, 0x000000, 0.7)
      .setInteractive();
    const label = this.add.text(400, 300, 'TAP TO START', {
      fontSize: '32px', color: '#ffffff',
    }).setOrigin(0.5);

    this.sound.once(Phaser.Sound.Events.UNLOCKED, () => {
      overlay.destroy();
      label.destroy();
      this.bgMusic.play();
    });
  } else {
    this.bgMusic.play();
  }
}
```

## Crossfading Music Between Scenes

Abrupt music cuts sound amateurish. Fade out the old track in the outgoing scene, fade in the new track in the incoming scene.

```typescript
// --- In OutgoingScene.shutdown() ---
shutdown(): void {
  if (this.bgMusic?.isPlaying) {
    this.tweens.add({
      targets: this.bgMusic,
      volume:  0,
      duration: 500,
      onComplete: () => this.bgMusic.stop(),
    });
  }
}

// --- In IncomingScene.create() ---
create(): void {
  this.bgMusic = this.sound.add('music-new', { loop: true, volume: 0 });
  this.bgMusic.play();
  this.tweens.add({
    targets:  this.bgMusic,
    volume:   0.6,
    duration: 800,
    ease:     'Linear',
  });
}
```

Note: `this.tweens` can tween any numeric property on any object, including `sound.volume`. No special audio tween API is needed.

## Stopping Sounds on Scene Shutdown

Always clean up audio when a scene shuts down. Otherwise sounds from a previous scene continue playing indefinitely.

```typescript
// Stop all sounds owned by the SoundManager (global — affects all scenes)
this.sound.stopAll();

// Stop only a specific sound
this.bgMusic.stop();

// Preferred pattern in shutdown():
shutdown(): void {
  // If music belongs to this scene only
  this.bgMusic?.stop();
  // If this is a top-level scene and you want to silence everything:
  // this.sound.stopAll();
}
```

Use `stopAll()` only at the top-level game exit or between completely unrelated game states. For scene transitions, stop only the specific sounds the current scene owns.

## Additional Resources

### Reference Files
- **`references/audio-api.md`** — Complete SoundManager, BaseSound, and WebAudioSound API reference, all events, SoundConfig fields, AudioSprite JSON schema

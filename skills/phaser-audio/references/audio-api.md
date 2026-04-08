# Phaser 4 Audio API Reference

## SoundManager

Access via `this.sound` inside any Scene.

### Methods

| Method | Signature | Description |
|--------|-----------|-------------|
| `add` | `add(key: string, config?: SoundConfig): BaseSound` | Create and register a sound instance. Returns a `WebAudioSound` or `HTML5AudioSound`. |
| `play` | `play(key: string, extra?: SoundConfig \| SoundMarker): boolean` | Create a one-shot sound, play it, and auto-destroy on completion. Returns `true` if successful. |
| `playAudioSprite` | `playAudioSprite(key: string, spriteName: string, config?: SoundConfig): boolean` | Play a named marker from an audio sprite. |
| `stopAll` | `stopAll(): this` | Stop all sounds currently playing. Fires `STOP_ALL` event. |
| `pauseAll` | `pauseAll(): this` | Pause all playing sounds. Fires `PAUSE_ALL` event. |
| `resumeAll` | `resumeAll(): this` | Resume all paused sounds. Fires `RESUME_ALL` event. |
| `removeAll` | `removeAll(): this` | Stop and remove all sound instances from the manager. |
| `remove` | `remove(sound: BaseSound): boolean` | Remove a specific sound instance. Returns `true` if found and removed. |
| `get` | `get(key: string): BaseSound \| null` | Get the first sound instance with this key, or `null`. |
| `getAll` | `getAll(key?: string): BaseSound[]` | Get all sounds, or all with a specific key if provided. |
| `setVolume` | `setVolume(value: number): this` | Set global volume (0–1). Alias for `volume` setter. |
| `setRate` | `setRate(value: number): this` | Set global playback rate. |
| `setDetune` | `setDetune(value: number): this` | Set global detune in cents. |
| `setMute` | `setMute(value: boolean): this` | Set global mute state. |
| `unlock` | `unlock(): void` | Attempt to unlock the AudioContext immediately (called internally on first user interaction). |
| `destroy` | `destroy(): void` | Destroy the SoundManager and all sounds. Called automatically on game destroy. |

### Properties

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `volume` | `number` | `1` | Global volume multiplier (0–1). Multiplied with per-sound volume. |
| `mute` | `boolean` | `false` | Global mute toggle. Does not stop sounds, only silences output. |
| `rate` | `number` | `1` | Global playback rate multiplier. |
| `detune` | `number` | `0` | Global detune in cents. |
| `locked` | `boolean` | `true` (mobile) | `true` if AudioContext has not yet been unlocked by user interaction. |
| `sounds` | `BaseSound[]` | `[]` | Internal array of all registered sound instances. Read-only. |

---

## SoundConfig Interface

`Phaser.Types.Sound.SoundConfig`

```typescript
interface SoundConfig {
  mute?:   boolean;  // default: false — mute this instance only
  volume?: number;   // default: 1    — per-instance volume (0–1)
  rate?:   number;   // default: 1    — playback speed (0.5 = half, 2 = double)
  detune?: number;   // default: 0    — pitch shift in cents (100 = 1 semitone up)
  seek?:   number;   // default: 0    — start position in seconds
  loop?:   boolean;  // default: false — loop the sound when it reaches the end
  delay?:  number;   // default: 0    — seconds to delay before starting playback
}
```

### Notes
- `rate` and `detune` both affect pitch. `rate: 2` doubles speed and raises pitch one octave. `detune` provides fine pitch control without speed change (Web Audio only).
- `seek` positions the playhead without playing; combine with `play()` to start mid-file.
- `delay` is a scheduling delay from the moment `play()` is called.

---

## BaseSoundManager Events

`Phaser.Sound.Events`

| Event Constant | String Value | Payload | Fires When |
|---------------|-------------|---------|-----------|
| `ADD` | `'add'` | `(soundManager, sound)` | A sound is added via `sound.add()` |
| `DESTROY` | `'destroy'` | `(soundManager)` | SoundManager is destroyed |
| `GLOBAL_DETUNE` | `'rate'` | `(soundManager, detune)` | Global detune changes |
| `GLOBAL_MUTE` | `'mute'` | `(soundManager, mute)` | Global mute toggles |
| `GLOBAL_RATE` | `'rate'` | `(soundManager, rate)` | Global rate changes |
| `GLOBAL_VOLUME` | `'volume'` | `(soundManager, volume)` | Global volume changes |
| `LOCK` | `'lock'` | `(soundManager)` | AudioContext becomes locked |
| `PAUSE_ALL` | `'pauseall'` | `(soundManager)` | `pauseAll()` is called |
| `RESUME_ALL` | `'resumeall'` | `(soundManager)` | `resumeAll()` is called |
| `STOP_ALL` | `'stopall'` | `(soundManager)` | `stopAll()` is called |
| `UNLOCK` | `'unlock'` | `(soundManager)` | AudioContext successfully unlocked by user interaction |

Listen on the SoundManager:

```typescript
this.sound.on(Phaser.Sound.Events.UNLOCK, () => {
  console.log('Audio unlocked — safe to play');
});

this.sound.on(Phaser.Sound.Events.GLOBAL_VOLUME, (mgr, vol) => {
  this.updateVolumeSlider(vol);
});
```

---

## BaseSound Methods

Individual sound instances returned by `this.sound.add()`.

| Method | Signature | Description |
|--------|-----------|-------------|
| `play` | `play(markerName?: string, config?: SoundConfig): boolean` | Play the sound (or a marker). Returns `true` if successful. |
| `pause` | `pause(): boolean` | Pause playback. Returns `true` if was playing. |
| `resume` | `resume(): boolean` | Resume from paused position. Returns `true` if was paused. |
| `stop` | `stop(): boolean` | Stop playback and return to seek 0. Returns `true` if was playing/paused. |
| `setVolume` | `setVolume(value: number): this` | Set per-sound volume (0–1). |
| `setRate` | `setRate(value: number): this` | Set playback rate. |
| `setDetune` | `setDetune(value: number): this` | Set detune in cents. |
| `setMute` | `setMute(value: boolean): this` | Mute/unmute this sound instance only. |
| `setLoop` | `setLoop(value: boolean): this` | Enable or disable looping. |
| `setSeek` | `setSeek(value: number): this` | Move playhead to `value` seconds. |
| `addMarker` | `addMarker(marker: SoundMarker): boolean` | Add a named time region to this sound. |
| `removeMarker` | `removeMarker(markerName: string): SoundMarker \| null` | Remove a named marker. |
| `destroy` | `destroy(): void` | Stop sound, remove from manager, free resources. |

### BaseSound Properties

| Property | Type | Description |
|----------|------|-------------|
| `key` | `string` | The asset key this sound was created with. |
| `isPlaying` | `boolean` | `true` if currently playing (not paused, not stopped). |
| `isPaused` | `boolean` | `true` if paused. |
| `volume` | `number` | Current per-instance volume (0–1). |
| `rate` | `number` | Current playback rate. |
| `detune` | `number` | Current detune in cents. |
| `mute` | `boolean` | Whether this instance is muted. |
| `loop` | `boolean` | Whether looping is enabled. |
| `seek` | `number` | Current playhead position in seconds (read-only during playback). |
| `duration` | `number` | Total duration in seconds. |
| `totalDuration` | `number` | Duration including any seek offset. |
| `markers` | `Record<string, SoundMarker>` | All registered markers on this sound. |
| `currentMarker` | `SoundMarker` | Currently playing marker, or the base marker. |

### BaseSound Events

Listen on the individual sound instance:

| Event Constant | String Value | Fires When |
|---------------|-------------|-----------|
| `Phaser.Sound.Events.PLAY` | `'play'` | `play()` is called successfully |
| `Phaser.Sound.Events.PAUSE` | `'pause'` | `pause()` is called |
| `Phaser.Sound.Events.RESUME` | `'resume'` | `resume()` is called |
| `Phaser.Sound.Events.STOP` | `'stop'` | `stop()` is called |
| `Phaser.Sound.Events.COMPLETE` | `'complete'` | Non-looping sound reaches the end |
| `Phaser.Sound.Events.LOOP` | `'loop'` | Looping sound restarts |
| `Phaser.Sound.Events.MUTE` | `'mute'` | Mute state changes |
| `Phaser.Sound.Events.VOLUME` | `'volume'` | Volume changes |
| `Phaser.Sound.Events.RATE` | `'rate'` | Rate changes |
| `Phaser.Sound.Events.DETUNE` | `'detune'` | Detune changes |
| `Phaser.Sound.Events.SEEK` | `'seek'` | `setSeek()` is called |
| `Phaser.Sound.Events.LOOP` | `'loop'` | Sound loops |
| `Phaser.Sound.Events.DESTROY` | `'destroy'` | Sound is destroyed |

---

## AudioSprite JSON Format

The JSON file loaded via `this.load.audioSprite()` must match this schema:

```json
{
  "resources": [
    "sfx-pack.mp3",
    "sfx-pack.ogg"
  ],
  "spritemap": {
    "markerName": {
      "start": 0.0,
      "end":   0.4,
      "loop":  false
    },
    "coin":  { "start": 0.0,  "end": 0.35, "loop": false },
    "jump":  { "start": 0.5,  "end": 0.85, "loop": false },
    "hurt":  { "start": 1.0,  "end": 1.6,  "loop": false },
    "die":   { "start": 1.8,  "end": 2.8,  "loop": false },
    "music": { "start": 3.0,  "end": 35.0, "loop": true  }
  }
}
```

### Field Definitions

| Field | Type | Description |
|-------|------|-------------|
| `resources` | `string[]` | Audio file paths (relative to the JSON). Phaser picks the first supported format. |
| `spritemap` | `object` | Map of marker names to their time regions. |
| `spritemap[name].start` | `number` | Start time in seconds (inclusive). |
| `spritemap[name].end` | `number` | End time in seconds (exclusive). |
| `spritemap[name].loop` | `boolean` | Whether this marker loops. |

### Tool Recommendation

Use **Audiosprite** (`npm install -g audiosprite`) to generate sprite packs and JSON from individual files:

```bash
audiosprite --format howle2 --output sfx-pack coin.wav jump.wav hurt.wav die.wav
```

---

## WebAudioSound vs HTML5AudioSound

| Feature | WebAudioSound | HTML5AudioSound |
|---------|--------------|-----------------|
| **Backend** | Web Audio API (`AudioContext`) | `<audio>` element |
| **Multiple concurrent instances** | Unlimited | 1 per key (browser-dependent) |
| **`detune` support** | Yes | No |
| **`rate` support** | Yes | Limited (browser quirks) |
| **Spatial audio (future)** | Yes | No |
| **Seek precision** | Sample-accurate | Approximate |
| **Memory model** | Decoded PCM in memory | Streamed or decoded per browser |
| **Mobile unlock** | Required (AudioContext) | Required (`<audio>` autoplay policy) |
| **CPU cost** | Low (off main thread) | Moderate (browser-managed) |
| **When used** | Default on all modern browsers | Automatic fallback only |

### Checking Which is Active

```typescript
// Returns 'WebAudio' or 'HTML5Audio' or 'NoAudio'
if (this.sound instanceof Phaser.Sound.WebAudioSoundManager) {
  // Web Audio is active
  const ctx = (this.sound as Phaser.Sound.WebAudioSoundManager).context;
}
if (this.sound instanceof Phaser.Sound.HTML5AudioSoundManager) {
  // HTML5 Audio fallback is active
}
```

### WebAudioSound-Specific Access

```typescript
const snd = this.sound.add('music') as Phaser.Sound.WebAudioSound;
// Access to raw Web Audio nodes (advanced use):
snd.source;        // AudioBufferSourceNode
snd.gainNode;      // GainNode
```

Do not rely on `source` or `gainNode` across `play()/stop()` cycles — they are recreated on each play.

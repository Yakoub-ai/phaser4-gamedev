---
name: phaser-saveload
description: This skill should be used when the user asks to "save game", "load game", "persist progress", "save state", "local storage", "save slot", "auto-save", "high score", "save settings", "save data", etc.
version: 0.2.0
---

# Phaser 4 Save & Load

Phaser has no built-in save system. Persist game state with `localStorage` (simple, synchronous, always available) or IndexedDB (async, larger payloads). This guide covers both, plus migration, multi-slot saves, and auto-save patterns.

## What to Save vs. What to Reconstruct

**Save this:**
- Player progress: current level, score, inventory, currency
- Flags: tutorials seen, areas unlocked, achievements earned
- Settings: volume levels, fullscreen preference, accessibility options
- Meta: last saved timestamp, save version number, total play time

**Reconstruct from saved data (do not serialize directly):**
- Scene state — restart the scene and re-apply saved data in `create()`
- Entity positions — save only meaningful state (e.g., `bossDefeated: true`), not raw coordinates
- Physics bodies — never serializable; recreate them from saved config

**Never save these:**
- `Phaser.GameObjects.*` instances (Sprites, Images, Text, etc.)
- `Phaser.Physics.*` bodies or worlds
- Scene references or anything with circular references

## localStorage — Simple Save

`localStorage` is synchronous, string-only, and limited to ~5 MB. It is the correct choice for game saves.

```typescript
// Save
localStorage.setItem('game-save', JSON.stringify(saveData));

// Load
const raw = localStorage.getItem('game-save');
const saveData: SaveData | null = raw ? JSON.parse(raw) : null;

// Delete
localStorage.removeItem('game-save');

// Check if a save exists
const hasSave = localStorage.getItem('game-save') !== null;
```

Always `JSON.parse` inside a `try/catch`. Corrupted or outdated save data will throw, and the game must recover gracefully.

## SaveData Interface

Define a typed interface for your save data. Every field needs a default.

```typescript
interface SaveData {
  version: number;           // increment when save schema changes
  level: number;             // current level index (1-based)
  score: number;             // current run score
  hiScore: number;           // all-time high score
  totalPlayTime: number;     // total seconds played
  settings: {
    musicVolume: number;     // 0–1
    sfxVolume: number;       // 0–1
    fullscreen: boolean;
  };
  unlockedLevels: number[];  // array of unlocked level indices
  flags: Record<string, boolean>; // flexible flags: tutorials, events, etc.
  lastSaved: number;         // Date.now() timestamp
}

const DEFAULT_SAVE: SaveData = {
  version: 1,
  level: 1,
  score: 0,
  hiScore: 0,
  totalPlayTime: 0,
  settings: { musicVolume: 0.7, sfxVolume: 1.0, fullscreen: false },
  unlockedLevels: [1],
  flags: {},
  lastSaved: 0,
};
```

## SaveManager Class

A static SaveManager centralizes all save/load logic and handles versioning.

```typescript
const SAVE_KEY = 'my-game-v1';

class SaveManager {
  /** Load save data. Returns DEFAULT_SAVE if none exists or data is corrupt. */
  static load(): SaveData {
    try {
      const raw = localStorage.getItem(SAVE_KEY);
      if (!raw) return { ...DEFAULT_SAVE };
      const data = JSON.parse(raw) as SaveData;
      return SaveManager.migrate(data);
    } catch {
      console.warn('SaveManager: failed to parse save data, using defaults');
      return { ...DEFAULT_SAVE };
    }
  }

  /** Merge partial update into existing save and write to localStorage. */
  static save(partial: Partial<SaveData>): void {
    const current = SaveManager.load();
    const updated: SaveData = { ...current, ...partial, lastSaved: Date.now() };
    // Always update hi-score
    if ((partial.score ?? 0) > current.hiScore) {
      updated.hiScore = partial.score!;
    }
    localStorage.setItem(SAVE_KEY, JSON.stringify(updated));
  }

  /** Delete all saved data. */
  static delete(): void {
    localStorage.removeItem(SAVE_KEY);
  }

  /** Check whether a save exists. */
  static exists(): boolean {
    return localStorage.getItem(SAVE_KEY) !== null;
  }

  /** Migrate old save formats to the current version. */
  static migrate(data: SaveData): SaveData {
    let d = { ...data };

    // v1 → v2: added `flags` field
    if (d.version < 2) {
      d.flags = {};
      d.version = 2;
    }
    // v2 → v3: added `totalPlayTime`
    if (d.version < 3) {
      d.totalPlayTime = 0;
      d.version = 3;
    }
    // Always ensure all required fields have defaults (defensive merge)
    return { ...DEFAULT_SAVE, ...d };
  }
}
```

## Multi-Slot Saves

```typescript
type SlotId = 1 | 2 | 3;

class SlotSaveManager {
  private static key(slot: SlotId): string {
    return `my-game-slot-${slot}`;
  }

  static load(slot: SlotId): SaveData {
    try {
      const raw = localStorage.getItem(SlotSaveManager.key(slot));
      if (!raw) return { ...DEFAULT_SAVE };
      return SaveManager.migrate(JSON.parse(raw) as SaveData);
    } catch {
      return { ...DEFAULT_SAVE };
    }
  }

  static save(slot: SlotId, partial: Partial<SaveData>): void {
    const current = SlotSaveManager.load(slot);
    const updated = { ...current, ...partial, lastSaved: Date.now() };
    localStorage.setItem(SlotSaveManager.key(slot), JSON.stringify(updated));
  }

  static delete(slot: SlotId): void {
    localStorage.removeItem(SlotSaveManager.key(slot));
  }

  /** Get metadata for all slots (for save select screen). */
  static listSlots(): Array<{ slot: SlotId; data: SaveData | null }> {
    return ([1, 2, 3] as SlotId[]).map(slot => ({
      slot,
      data: localStorage.getItem(SlotSaveManager.key(slot))
        ? SlotSaveManager.load(slot)
        : null,
    }));
  }
}
```

## Auto-Save Pattern

Auto-save on meaningful game events: level complete, checkpoint reached, scene shutdown, and on a timer.

```typescript
class GameScene extends Phaser.Scene {
  private currentLevel = 1;
  private lastAutoSave = 0;

  create(): void {
    // Auto-save on scene shutdown (handles Alt+F4, tab close, etc.)
    this.events.on(Phaser.Scenes.Events.SHUTDOWN, () => this.autoSave());
    this.events.on(Phaser.Scenes.Events.PAUSE, () => this.autoSave());

    // Periodic auto-save every 5 minutes
    this.time.addEvent({
      delay: 300_000,
      callback: this.autoSave,
      callbackScope: this,
      loop: true,
    });
  }

  private autoSave(): void {
    SaveManager.save({
      level: this.currentLevel,
      score: this.registry.get('score') as number,
      totalPlayTime: (this.registry.get('totalPlayTime') as number) +
        Math.floor((Date.now() - this.lastAutoSave) / 1000),
    });
    this.lastAutoSave = Date.now();
  }

  private onLevelComplete(): void {
    this.currentLevel++;
    SaveManager.save({
      level: this.currentLevel,
      unlockedLevels: [...(SaveManager.load().unlockedLevels), this.currentLevel],
    });
    // Also save immediately on meaningful event
    this.autoSave();
  }
}
```

## Registry + SaveManager Integration

Use Phaser's `this.registry` as the in-memory runtime state, and SaveManager as the persistent store. Sync at startup and shutdown.

```typescript
// --- In BootScene or GameScene.create() ---
// Load save → populate registry
const save = SaveManager.load();
this.registry.set('score', save.score);
this.registry.set('hiScore', save.hiScore);
this.registry.set('level', save.level);
this.registry.set('musicVolume', save.settings.musicVolume);
this.registry.set('sfxVolume', save.settings.sfxVolume);

// Apply settings immediately
this.sound.volume = save.settings.musicVolume;

// --- On game over / scene end ---
// Read registry → save
SaveManager.save({
  score: this.registry.get('score') as number,
  level: this.registry.get('level') as number,
});
```

**Why use registry as intermediary?**
Phaser's registry is shared across scenes (accessible via `this.registry` everywhere). It avoids reading `localStorage` on every frame and ensures all scenes see the same live state.

## Settings: Separate from Game Progress

Keep settings (volume, fullscreen) in their own localStorage key so you can reset game progress without losing settings.

```typescript
const SETTINGS_KEY = 'my-game-settings';

interface GameSettings {
  musicVolume: number;
  sfxVolume: number;
  fullscreen: boolean;
}

const DEFAULT_SETTINGS: GameSettings = {
  musicVolume: 0.7,
  sfxVolume: 1.0,
  fullscreen: false,
};

class SettingsManager {
  static load(): GameSettings {
    try {
      const raw = localStorage.getItem(SETTINGS_KEY);
      return raw ? { ...DEFAULT_SETTINGS, ...JSON.parse(raw) } : { ...DEFAULT_SETTINGS };
    } catch {
      return { ...DEFAULT_SETTINGS };
    }
  }

  static save(settings: Partial<GameSettings>): void {
    const current = SettingsManager.load();
    localStorage.setItem(SETTINGS_KEY, JSON.stringify({ ...current, ...settings }));
  }
}
```

## Hi-Score Table

Store an array of score entries. Keep only the top N entries, sorted descending.

```typescript
interface ScoreEntry {
  name: string;
  score: number;
  date: string;   // ISO string
}

const HISCORE_KEY = 'my-game-hiscores';
const MAX_ENTRIES = 10;

class HiScoreManager {
  static load(): ScoreEntry[] {
    try {
      const raw = localStorage.getItem(HISCORE_KEY);
      return raw ? JSON.parse(raw) as ScoreEntry[] : [];
    } catch {
      return [];
    }
  }

  static submit(name: string, score: number): ScoreEntry[] {
    const entries = HiScoreManager.load();
    entries.push({ name, score, date: new Date().toISOString() });
    const sorted = entries
      .sort((a, b) => b.score - a.score)
      .slice(0, MAX_ENTRIES);
    localStorage.setItem(HISCORE_KEY, JSON.stringify(sorted));
    return sorted;
  }

  static isHighScore(score: number): boolean {
    const entries = HiScoreManager.load();
    if (entries.length < MAX_ENTRIES) return true;
    return score > (entries[MAX_ENTRIES - 1]?.score ?? 0);
  }
}
```

## Save Data Versioning

Always include a `version` field and a `migrate()` function. This prevents old saves from breaking on new releases.

- Never remove fields from a save — mark them deprecated and stop using them
- Never change the type of a field — add a new field instead
- When adding a new required field, provide a default in `migrate()`
- Store `version` as an integer, increment it when the schema changes

## Cloud Save Architecture (Outline)

Cloud saves require a backend. Phaser provides no cloud save API.

**Pattern:**
1. On save: `POST /api/save` with session token + `JSON.stringify(saveData)` as body
2. On load: `GET /api/save` with session token → parse response body
3. Offline fallback: if fetch fails, fall back to `localStorage`
4. Conflict resolution: compare `lastSaved` timestamps; use the most recent

**Conflict resolution note:** "last write wins" is simple and correct for most single-player games. For co-op or cross-device play with simultaneous edits, a merge strategy is required.

## Additional Resources

### Reference Files
- **`references/save-patterns.md`** — Full TypeScript SaveManager with generics, SettingsManager, HiScoreManager, save migration system, basic obfuscation (btoa/atob), IndexedDB pattern for large data

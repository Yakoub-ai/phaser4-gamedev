# Save & Load Patterns Reference

Complete TypeScript implementations for game save/load patterns in Phaser 4.

---

## 1. Generic SaveManager with Full TypeScript

A typed, versioned save manager using generics so it works with any save data shape.

```typescript
// save-manager.ts

const CURRENT_VERSION = 3;

export interface SaveData {
  version: number;
  level: number;
  score: number;
  hiScore: number;
  totalPlayTime: number;   // seconds
  settings: GameSettings;
  unlockedLevels: number[];
  flags: Record<string, boolean>;
  inventory: InventoryItem[];
  lastSaved: number;       // Date.now()
}

export interface GameSettings {
  musicVolume: number;     // 0–1
  sfxVolume: number;       // 0–1
  fullscreen: boolean;
  language: string;
}

export interface InventoryItem {
  id: string;
  quantity: number;
}

const DEFAULT_SAVE: SaveData = {
  version: CURRENT_VERSION,
  level: 1,
  score: 0,
  hiScore: 0,
  totalPlayTime: 0,
  settings: {
    musicVolume: 0.7,
    sfxVolume: 1.0,
    fullscreen: false,
    language: 'en',
  },
  unlockedLevels: [1],
  flags: {},
  inventory: [],
  lastSaved: 0,
};

export class SaveManager {
  private static readonly KEY = 'phaser-game-save';

  /** Load save. Returns a deep copy of DEFAULT_SAVE if no save exists or parse fails. */
  static load(): SaveData {
    try {
      const raw = localStorage.getItem(SaveManager.KEY);
      if (!raw) return SaveManager.defaultSave();
      const parsed = JSON.parse(raw) as Partial<SaveData>;
      return SaveManager.migrate(parsed);
    } catch (err) {
      console.warn('[SaveManager] Load failed, using defaults:', err);
      return SaveManager.defaultSave();
    }
  }

  /** Merge a partial update into the existing save and persist. */
  static save(partial: Partial<SaveData>): SaveData {
    const current = SaveManager.load();
    const updated: SaveData = {
      ...current,
      ...partial,
      // Always update hi-score if new score is higher
      hiScore: Math.max(current.hiScore, partial.score ?? 0, partial.hiScore ?? 0),
      lastSaved: Date.now(),
      version: CURRENT_VERSION,
    };
    try {
      localStorage.setItem(SaveManager.KEY, JSON.stringify(updated));
    } catch (err) {
      console.error('[SaveManager] Save failed (storage full?):', err);
    }
    return updated;
  }

  /** Replace entire save data (used for cloud sync or slot restore). */
  static overwrite(data: SaveData): void {
    localStorage.setItem(SaveManager.KEY, JSON.stringify({ ...data, lastSaved: Date.now() }));
  }

  /** Delete save data. */
  static delete(): void {
    localStorage.removeItem(SaveManager.KEY);
  }

  /** Returns true if a save exists. */
  static exists(): boolean {
    return localStorage.getItem(SaveManager.KEY) !== null;
  }

  /** Returns the number of bytes the save data occupies in localStorage. */
  static sizeBytes(): number {
    const raw = localStorage.getItem(SaveManager.KEY) ?? '';
    return new TextEncoder().encode(raw).byteLength;
  }

  /** Export save as a base64 string (for clipboard share or backup). */
  static export(): string {
    return btoa(localStorage.getItem(SaveManager.KEY) ?? '{}');
  }

  /** Import save from a base64 string. Validates before applying. */
  static import(encoded: string): boolean {
    try {
      const json = atob(encoded);
      const data = JSON.parse(json) as Partial<SaveData>;
      if (typeof data.version !== 'number') return false;  // basic validation
      SaveManager.overwrite(SaveManager.migrate(data));
      return true;
    } catch {
      return false;
    }
  }

  private static defaultSave(): SaveData {
    return JSON.parse(JSON.stringify(DEFAULT_SAVE)) as SaveData;
  }

  private static migrate(data: Partial<SaveData>): SaveData {
    // Start with defaults, overlay saved data
    let d: SaveData = { ...SaveManager.defaultSave(), ...data };

    // v1 → v2: Added `flags` field
    if (d.version < 2) {
      d.flags = {};
      d.version = 2;
    }

    // v2 → v3: Added `inventory` and `totalPlayTime`
    if (d.version < 3) {
      d.inventory = [];
      d.totalPlayTime = 0;
      d.version = 3;
    }

    // Always ensure nested objects are fully populated with defaults
    d.settings = { ...DEFAULT_SAVE.settings, ...(d.settings ?? {}) };

    return d;
  }
}
```

---

## 2. SettingsManager (Separate from Game Progress)

Keep settings in their own key so clearing game progress doesn't reset volume/controls.

```typescript
// settings-manager.ts

export interface GameSettings {
  musicVolume: number;   // 0–1
  sfxVolume: number;     // 0–1
  fullscreen: boolean;
  language: string;
  colorblindMode: boolean;
  showFPS: boolean;
}

const SETTINGS_KEY = 'phaser-game-settings';

const DEFAULT_SETTINGS: GameSettings = {
  musicVolume: 0.7,
  sfxVolume: 1.0,
  fullscreen: false,
  language: 'en',
  colorblindMode: false,
  showFPS: false,
};

export class SettingsManager {
  static load(): GameSettings {
    try {
      const raw = localStorage.getItem(SETTINGS_KEY);
      if (!raw) return { ...DEFAULT_SETTINGS };
      // Defensive merge: new fields get defaults, old fields are preserved
      return { ...DEFAULT_SETTINGS, ...JSON.parse(raw) };
    } catch {
      return { ...DEFAULT_SETTINGS };
    }
  }

  static save(partial: Partial<GameSettings>): GameSettings {
    const updated = { ...SettingsManager.load(), ...partial };
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(updated));
    return updated;
  }

  static reset(): void {
    localStorage.setItem(SETTINGS_KEY, JSON.stringify(DEFAULT_SETTINGS));
  }

  /** Apply settings to a running Phaser scene immediately. */
  static apply(scene: Phaser.Scene, settings: GameSettings): void {
    scene.sound.volume = settings.musicVolume;
    if (settings.fullscreen && !scene.scale.isFullscreen) {
      scene.scale.startFullscreen();
    } else if (!settings.fullscreen && scene.scale.isFullscreen) {
      scene.scale.stopFullscreen();
    }
  }
}
```

---

## 3. Hi-Score Table

```typescript
// hi-score-manager.ts

export interface ScoreEntry {
  name: string;
  score: number;
  level: number;
  date: string;   // ISO 8601 date string
}

const HISCORE_KEY = 'phaser-game-hiscores';
const MAX_ENTRIES = 10;

export class HiScoreManager {
  /** Get all hi-score entries, sorted descending. */
  static load(): ScoreEntry[] {
    try {
      const raw = localStorage.getItem(HISCORE_KEY);
      if (!raw) return [];
      const entries = JSON.parse(raw) as ScoreEntry[];
      return entries.sort((a, b) => b.score - a.score);
    } catch {
      return [];
    }
  }

  /**
   * Submit a new score. Returns the updated sorted list.
   * Does NOT check qualification first — call isQualifying() before prompting for name.
   */
  static submit(name: string, score: number, level: number): ScoreEntry[] {
    const entries = HiScoreManager.load();
    entries.push({ name: name.slice(0, 12).toUpperCase(), score, level, date: new Date().toISOString() });

    const sorted = entries
      .sort((a, b) => b.score - a.score)
      .slice(0, MAX_ENTRIES);

    localStorage.setItem(HISCORE_KEY, JSON.stringify(sorted));
    return sorted;
  }

  /** Returns true if score would appear in the top-N list. */
  static isQualifying(score: number): boolean {
    const entries = HiScoreManager.load();
    if (entries.length < MAX_ENTRIES) return true;
    return score > (entries[MAX_ENTRIES - 1]?.score ?? 0);
  }

  /** Returns the rank (1-based) of a score, or null if not qualifying. */
  static getRank(score: number): number | null {
    if (!HiScoreManager.isQualifying(score)) return null;
    const entries = HiScoreManager.load();
    const rank = entries.filter(e => e.score > score).length + 1;
    return Math.min(rank, MAX_ENTRIES);
  }

  static clear(): void {
    localStorage.removeItem(HISCORE_KEY);
  }
}
```

---

## 4. Save Data Migration System

```typescript
// migration.ts

type Migrator = (data: Record<string, unknown>) => Record<string, unknown>;

// Each entry migrates FROM that version TO the next
const MIGRATIONS: Record<number, Migrator> = {
  1: (data) => ({
    ...data,
    version: 2,
    flags: {},               // Added in v2
  }),
  2: (data) => ({
    ...data,
    version: 3,
    inventory: [],           // Added in v3
    totalPlayTime: 0,
  }),
  3: (data) => ({
    ...data,
    version: 4,
    settings: {
      ...(data.settings as object ?? {}),
      colorblindMode: false, // Added in v4
    },
  }),
};

const LATEST_VERSION = Math.max(...Object.keys(MIGRATIONS).map(Number)) + 1;

export function migrate<T extends { version: number }>(data: Partial<T>): T {
  let d = { ...data } as Record<string, unknown>;
  let version = (d.version as number) ?? 1;

  while (version < LATEST_VERSION) {
    const migrator = MIGRATIONS[version];
    if (!migrator) {
      console.warn(`[migrate] No migrator for version ${version}, skipping`);
      break;
    }
    d = migrator(d);
    version = d.version as number;
  }

  return d as T;
}
```

---

## 5. Basic Save Obfuscation (btoa / atob)

Not real encryption — just stops casual players from editing saves with browser DevTools. For competitive or monetized games, validate save state on a server instead.

```typescript
// obfuscated-save.ts

const SALT = 'my-game-2024-xk9q'; // Change per game — just makes the output unique

export class ObfuscatedSaveManager {
  private static readonly KEY = 'phaser-game-data';

  static save(data: object): void {
    const json = JSON.stringify(data);
    const salted = `${SALT}::${json}`;
    // btoa handles ASCII; use a proper base64 encoder for Unicode data
    const encoded = btoa(unescape(encodeURIComponent(salted)));
    localStorage.setItem(ObfuscatedSaveManager.KEY, encoded);
  }

  static load<T extends object>(): T | null {
    try {
      const raw = localStorage.getItem(ObfuscatedSaveManager.KEY);
      if (!raw) return null;
      const decoded = decodeURIComponent(escape(atob(raw)));
      const prefix = `${SALT}::`;
      if (!decoded.startsWith(prefix)) return null;  // Tamper detection
      return JSON.parse(decoded.slice(prefix.length)) as T;
    } catch {
      return null;
    }
  }

  static delete(): void {
    localStorage.removeItem(ObfuscatedSaveManager.KEY);
  }
}
```

**Limitations:** `btoa`/`atob` is not encryption. Anyone with Chrome DevTools and a few minutes can decode it. Use it to raise the barrier for casual tampering, not for protecting anything valuable.

---

## 6. IndexedDB Pattern (Large Save Data)

Use IndexedDB for save data exceeding a few KB — screenshots, replay recordings, large level editor projects. It is async, with no hard size limit (browser-managed quota).

```typescript
// indexed-db-save.ts

const DB_NAME = 'phaser-game-db';
const DB_VERSION = 1;
const STORE_NAME = 'saves';

function openDB(): Promise<IDBDatabase> {
  return new Promise((resolve, reject) => {
    const request = indexedDB.open(DB_NAME, DB_VERSION);

    request.onupgradeneeded = (event) => {
      const db = (event.target as IDBOpenDBRequest).result;
      if (!db.objectStoreNames.contains(STORE_NAME)) {
        db.createObjectStore(STORE_NAME);
      }
    };

    request.onsuccess = () => resolve(request.result);
    request.onerror   = () => reject(request.error);
  });
}

export async function idbSave(key: string, data: unknown): Promise<void> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx    = db.transaction(STORE_NAME, 'readwrite');
    const store = tx.objectStore(STORE_NAME);
    const req   = store.put(data, key);
    req.onsuccess = () => resolve();
    req.onerror   = () => reject(req.error);
  });
}

export async function idbLoad<T>(key: string): Promise<T | undefined> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx    = db.transaction(STORE_NAME, 'readonly');
    const store = tx.objectStore(STORE_NAME);
    const req   = store.get(key);
    req.onsuccess = () => resolve(req.result as T | undefined);
    req.onerror   = () => reject(req.error);
  });
}

export async function idbDelete(key: string): Promise<void> {
  const db = await openDB();
  return new Promise((resolve, reject) => {
    const tx    = db.transaction(STORE_NAME, 'readwrite');
    const store = tx.objectStore(STORE_NAME);
    const req   = store.delete(key);
    req.onsuccess = () => resolve();
    req.onerror   = () => reject(req.error);
  });
}

// Usage example:
// await idbSave('replay-level-1', replayData);
// const replay = await idbLoad<ReplayData>('replay-level-1');

// Save a canvas screenshot as a blob:
async function saveScreenshot(canvas: HTMLCanvasElement, key: string): Promise<void> {
  const blob = await new Promise<Blob>((resolve) =>
    canvas.toBlob(b => resolve(b!), 'image/webp', 0.8)
  );
  await idbSave(key, blob);
}

async function loadScreenshot(key: string): Promise<string | null> {
  const blob = await idbLoad<Blob>(key);
  if (!blob) return null;
  return URL.createObjectURL(blob);  // Use as <img src> — call URL.revokeObjectURL() when done
}
```

---

## Usage Summary

| Scenario | Solution |
|---|---|
| Simple game progress (level, score) | `SaveManager` (localStorage) |
| Settings (volume, controls) | `SettingsManager` (separate key) |
| Top scores display | `HiScoreManager` |
| Schema changed after release | `migrate()` function in SaveManager |
| Casual tamper prevention | `ObfuscatedSaveManager` |
| Replay recordings, screenshots | `idbSave` / `idbLoad` (IndexedDB) |
| Cross-device / competitive | Server-side save with session auth |

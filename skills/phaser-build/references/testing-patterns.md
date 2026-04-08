# Phaser 4 Testing Patterns

Testing a Phaser game requires different approaches for different layers: pure game logic can be unit-tested, rendering behavior needs visual/manual testing, and performance needs profiling.

---

## 1. Unit Testing Game Logic

The key insight: **move logic out of scenes into pure functions or plain classes**. Phaser scenes mix rendering, physics, and logic — unit testing them directly requires mocking the entire Phaser runtime.

### What to Extract

```typescript
// BAD — logic trapped inside scene, untestable without Phaser
class GameScene extends Phaser.Scene {
  private score = 0;
  collectCoin(): void {
    this.score += 10;
    if (this.score > this.registry.get('hiScore')) {
      this.registry.set('hiScore', this.score);
    }
    this.scoreText.setText(`Score: ${this.score}`);
  }
}

// GOOD — logic extracted to pure functions
export function calculateScore(current: number, points: number): number {
  return current + points;
}
export function isNewHiScore(score: number, hiScore: number): boolean {
  return score > hiScore;
}
// Scene only handles the rendering update
class GameScene extends Phaser.Scene {
  private score = 0;
  collectCoin(): void {
    this.score = calculateScore(this.score, 10);
    if (isNewHiScore(this.score, this.registry.get('hiScore'))) {
      this.registry.set('hiScore', this.score);
    }
    this.scoreText.setText(`Score: ${this.score}`);
  }
}
```

### What's Easily Testable

- Score calculations, combo multipliers
- Collision outcome logic (damage calculations, effect triggers)
- Save data serialization/deserialization
- Enemy AI state machine transitions
- Level generation algorithms
- Grid logic (match-3, inventory management)
- Input to movement vector calculations

---

## 2. Vitest Setup for Phaser Projects

[Vitest](https://vitest.dev) works well for Phaser projects since it uses Vite (same as the game build).

### Install

```bash
npm install -D vitest
```

### `vite.config.ts` — add test config

```typescript
import { defineConfig } from 'vite';

export default defineConfig({
  test: {
    environment: 'node',  // use 'jsdom' if you need DOM APIs
    globals: true,
  },
  // existing config...
});
```

### `package.json` — add test script

```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "test": "vitest run",
    "test:watch": "vitest"
  }
}
```

### Example Test File: `src/utils/score.test.ts`

```typescript
import { describe, it, expect } from 'vitest';
import { calculateScore, isNewHiScore } from './score';

describe('calculateScore', () => {
  it('adds points to current score', () => {
    expect(calculateScore(0, 10)).toBe(10);
    expect(calculateScore(100, 50)).toBe(150);
  });
});

describe('isNewHiScore', () => {
  it('returns true when score exceeds hi-score', () => {
    expect(isNewHiScore(150, 100)).toBe(true);
  });
  it('returns false when score is less than hi-score', () => {
    expect(isNewHiScore(50, 100)).toBe(false);
  });
  it('returns false when equal', () => {
    expect(isNewHiScore(100, 100)).toBe(false);
  });
});
```

---

## 3. Mocking Phaser Objects in Unit Tests

When logic is in a class that uses Phaser (but you still want to test it), create lightweight mocks:

```typescript
// src/objects/Player.test.ts
import { describe, it, expect, vi } from 'vitest';

// Mock the Phaser module before imports that use it
vi.mock('phaser', () => ({
  default: {
    Physics: {
      Arcade: {
        Sprite: class MockSprite {
          x = 0; y = 0;
          body = { velocity: { x: 0, y: 0 }, blocked: { down: true }, enable: true };
          setVelocityX = vi.fn().mockReturnThis();
          setVelocityY = vi.fn().mockReturnThis();
          play = vi.fn().mockReturnThis();
        }
      }
    }
  }
}));

import { Player } from './Player';

describe('Player jump logic', () => {
  it('applies jump velocity when grounded', () => {
    const mockScene = {} as any;
    const player = new Player(mockScene, 0, 0);
    player.jump();
    expect(player.setVelocityY).toHaveBeenCalledWith(-480);
  });
});
```

**Tip:** Prefer extracting logic into plain TypeScript files that don't import Phaser at all. Mocking Phaser is brittle and maintenance-heavy.

---

## 4. Save System Testing

Save/load logic is easy to test since it's pure data manipulation:

```typescript
// src/managers/SaveManager.test.ts
import { describe, it, expect, beforeEach } from 'vitest';
import { SaveManager } from './SaveManager';

// Mock localStorage
const localStorageMock = (() => {
  let store: Record<string, string> = {};
  return {
    getItem: (k: string) => store[k] ?? null,
    setItem: (k: string, v: string) => { store[k] = v; },
    removeItem: (k: string) => { delete store[k]; },
    clear: () => { store = {}; },
  };
})();
Object.defineProperty(globalThis, 'localStorage', { value: localStorageMock });

describe('SaveManager', () => {
  beforeEach(() => localStorageMock.clear());

  it('returns default save when nothing stored', () => {
    const save = SaveManager.load();
    expect(save.score).toBe(0);
    expect(save.level).toBe(1);
  });

  it('saves and loads data', () => {
    SaveManager.save({ score: 500, level: 3 });
    const save = SaveManager.load();
    expect(save.score).toBe(500);
    expect(save.level).toBe(3);
  });

  it('handles corrupt data gracefully', () => {
    localStorage.setItem('game-save', 'not-json');
    const save = SaveManager.load();
    expect(save.score).toBe(0); // falls back to defaults
  });
});
```

---

## 5. Visual Regression Testing with Playwright

For visual testing (does the game render correctly?), use [Playwright](https://playwright.dev):

### Install

```bash
npm install -D @playwright/test
npx playwright install chromium
```

### `playwright.config.ts`

```typescript
import { defineConfig } from '@playwright/test';

export default defineConfig({
  testDir: './tests/visual',
  use: {
    baseURL: 'http://localhost:5173',
    screenshot: 'only-on-failure',
  },
  webServer: {
    command: 'npm run dev',
    port: 5173,
    reuseExistingServer: true,
  },
});
```

### Example Visual Test: `tests/visual/game.spec.ts`

```typescript
import { test, expect } from '@playwright/test';

test('game renders without errors', async ({ page }) => {
  // Capture console errors
  const errors: string[] = [];
  page.on('console', msg => { if (msg.type() === 'error') errors.push(msg.text()); });

  await page.goto('/');
  await page.waitForTimeout(2000); // wait for Phaser to initialize

  // No JavaScript errors
  expect(errors).toHaveLength(0);

  // Canvas is visible
  const canvas = page.locator('canvas');
  await expect(canvas).toBeVisible();

  // Screenshot comparison (first run creates baseline)
  await expect(canvas).toHaveScreenshot('main-menu.png');
});

test('clicking play starts the game', async ({ page }) => {
  await page.goto('/');
  await page.waitForTimeout(1000);
  await page.locator('canvas').click({ position: { x: 400, y: 350 } }); // click Play button area
  await page.waitForTimeout(500);
  await expect(page.locator('canvas')).toHaveScreenshot('game-started.png');
});
```

### Run Visual Tests

```bash
npx playwright test                  # run all tests
npx playwright test --update-snapshots  # update baseline screenshots
npx playwright show-report           # view HTML report
```

---

## 6. Performance Benchmarking

### In-Game FPS Logger

Add a debug FPS overlay during development:

```typescript
// In any scene's create():
if (import.meta.env.DEV) {
  const fpsText = this.add.text(10, 10, '', {
    fontSize: '12px', color: '#00ff00', backgroundColor: '#000000'
  }).setDepth(9999).setScrollFactor(0);

  this.time.addEvent({
    delay: 500,
    callback: () => fpsText.setText(`FPS: ${Math.round(this.game.loop.actualFps)}`),
    loop: true,
  });
}
```

### Performance Budget Targets

| Metric | Target | Warning Threshold |
|--------|--------|-------------------|
| FPS (desktop) | 60 | < 55 |
| FPS (mobile) | 60 | < 30 |
| Physics bodies | < 200 | > 300 |
| Active tweens | < 50 | > 100 |
| Draw calls/frame | < 30 | > 50 |
| Bundle size (gzipped) | < 3MB | > 5MB |
| Largest texture | < 1024×1024 | > 2048×2048 |

### Profiling with Chrome DevTools

1. Open game at `http://localhost:5173`
2. Chrome DevTools → Performance tab → Record
3. Play for 30 seconds, stop recording
4. Look for: long frames (red bars), garbage collection spikes (memory tab), large scripting time

Common culprits:
- Creating many small objects each frame (object pooling fixes this)
- Large `update()` loops without early-exit conditions
- Uncapped particle emitters
- Tweens not destroyed after completion

---

## 7. Manual Testing Checklist

Before shipping, run through this manually:

### Core Gameplay
- [ ] Game starts without console errors
- [ ] All scenes transition correctly
- [ ] Player controls respond as expected
- [ ] Collision detection works (no falling through floors, no phantom hits)
- [ ] Score/lives/HUD update correctly
- [ ] Game over triggers at the right conditions
- [ ] Restart/menu navigation works

### Audio
- [ ] Background music plays and loops correctly
- [ ] Sound effects fire at the right moments
- [ ] Audio works on mobile (after first tap)
- [ ] Mute/volume controls work

### Performance
- [ ] Runs at 60fps on target hardware
- [ ] No frame drops during heavy action (explosions, many enemies)
- [ ] No memory leaks (play for 5 minutes, check memory in DevTools)
- [ ] Physics debug is OFF (`arcade: { debug: false }`)

### Platform
- [ ] Works in Chrome, Firefox, Safari
- [ ] Works on mobile (iOS Safari, Android Chrome)
- [ ] Controls work: keyboard (desktop), touch (mobile)
- [ ] Responsive scaling works at different screen sizes

### Build
- [ ] `npx tsc --noEmit` passes (zero TypeScript errors)
- [ ] `npm run build` succeeds
- [ ] Built game runs from `dist/` directory
- [ ] No 404 errors for assets

# Phaser 4 Project Templates

Complete file listings for different project setups.

## Template 1: TypeScript + Vite (Recommended)

### `index.html`

```html
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0" />
  <title>My Phaser 4 Game</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { background: #000; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    #game-container { }
  </style>
</head>
<body>
  <div id="game-container"></div>
  <script type="module" src="/src/main.ts"></script>
</body>
</html>
```

### `package.json`

```json
{
  "name": "my-phaser-game",
  "version": "0.1.0",
  "private": true,
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview",
    "typecheck": "tsc --noEmit"
  },
  "dependencies": {
    "phaser": "beta"
  },
  "devDependencies": {
    "typescript": "^5.0.0",
    "vite": "^5.0.0",
    "@types/node": "^20.0.0"
  }
}
```

### `tsconfig.json`

```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "noUnusedLocals": true,
    "noUnusedParameters": true,
    "noImplicitReturns": true,
    "skipLibCheck": true,
    "typeRoots": ["./node_modules/phaser/types"],
    "types": ["Phaser"]
  },
  "include": ["src"]
}
```

### `vite.config.ts`

```typescript
import { defineConfig } from 'vite';

export default defineConfig({
  base: './',
  build: {
    outDir: 'dist',
    assetsDir: 'assets',
    rollupOptions: {
      output: {
        manualChunks: {
          phaser: ['phaser'],
        },
      },
    },
  },
  server: {
    port: 5173,
    open: true,
  },
});
```

### `src/main.ts`

```typescript
import Phaser from 'phaser';
import { BootScene } from './scenes/BootScene';
import { PreloaderScene } from './scenes/PreloaderScene';
import { GameScene } from './scenes/GameScene';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  parent: 'game-container',
  backgroundColor: '#1d1d2b',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 300 },
      debug: true,
    },
  },
  scene: [BootScene, PreloaderScene, GameScene],
};

export default new Phaser.Game(config);
```

### `src/scenes/BootScene.ts`

```typescript
import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload(): void {
    // Load only assets needed for the loading screen
    // (tiny images like a logo or loading bar graphic)
  }

  create(): void {
    this.scene.start('PreloaderScene');
  }
}
```

### `src/scenes/PreloaderScene.ts`

```typescript
import Phaser from 'phaser';

export class PreloaderScene extends Phaser.Scene {
  constructor() {
    super({ key: 'PreloaderScene' });
  }

  preload(): void {
    const { width, height } = this.scale;

    // Loading bar background
    const bg = this.add.graphics();
    bg.fillStyle(0x222222, 0.8);
    bg.fillRect(width / 2 - 160, height / 2 - 25, 320, 50);

    // Loading bar fill
    const bar = this.add.graphics();
    this.load.on('progress', (value: number) => {
      bar.clear();
      bar.fillStyle(0x00ff88, 1);
      bar.fillRect(width / 2 - 150, height / 2 - 15, 300 * value, 30);
    });

    this.add.text(width / 2, height / 2 + 40, 'Loading...', {
      fontSize: '16px',
      color: '#aaaaaa',
    }).setOrigin(0.5);

    // ── Load ALL game assets here ──
    // this.load.image('sky', 'assets/images/sky.png');
    // this.load.spritesheet('player', 'assets/spritesheets/player.png', { frameWidth: 32, frameHeight: 48 });
    // this.load.atlas('ui', 'assets/atlases/ui.png', 'assets/atlases/ui.json');
    // this.load.audio('bgm', ['assets/audio/bgm.mp3', 'assets/audio/bgm.ogg']);
    // this.load.tilemapTiledJSON('level1', 'assets/tilemaps/level1.json');
  }

  create(): void {
    // Create all animations here after assets are loaded
    // this.anims.create({ key: 'player-idle', ... });

    this.scene.start('GameScene');
  }
}
```

### `src/scenes/GameScene.ts`

```typescript
import Phaser from 'phaser';

export class GameScene extends Phaser.Scene {
  constructor() {
    super({ key: 'GameScene' });
  }

  create(): void {
    const { width, height } = this.scale;

    // Placeholder: colored rectangle as "ground"
    const ground = this.add.rectangle(width / 2, height - 20, width, 40, 0x44aa44);
    this.physics.add.existing(ground, true); // true = static body

    this.add.text(width / 2, height / 2, 'Phaser 4 Game!', {
      fontSize: '32px',
      color: '#ffffff',
    }).setOrigin(0.5);
  }

  update(_time: number, _delta: number): void {
    // Game loop
  }
}
```

---

## Template 2: JavaScript + Vite

Same structure but with `.js` files and no `tsconfig.json`:

### `src/main.js`

```javascript
import Phaser from 'phaser';
import { BootScene } from './scenes/BootScene.js';
import { GameScene } from './scenes/GameScene.js';

const config = {
  type: Phaser.AUTO,
  width: 800,
  height: 600,
  parent: 'game-container',
  backgroundColor: '#1d1d2b',
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
  physics: {
    default: 'arcade',
    arcade: { gravity: { y: 300 }, debug: true },
  },
  scene: [BootScene, GameScene],
};

export default new Phaser.Game(config);
```

`package.json` scripts: `"dev": "vite"` (no `tsc` step needed)

---

## Template 3: HTML-only (No Bundler)

For quick prototyping. Uses an import map or CDN.

```html
<!DOCTYPE html>
<html>
<head>
  <title>Phaser 4 Game</title>
  <script>
    // Import map for bare module specifiers
  </script>
</head>
<body>
  <script type="importmap">
  {
    "imports": {
      "phaser": "https://cdn.jsdelivr.net/npm/phaser@beta/dist/phaser.esm.min.js"
    }
  }
  </script>
  <script type="module">
    import Phaser from 'phaser';

    const config = {
      type: Phaser.AUTO,
      width: 800,
      height: 600,
      backgroundColor: '#1d1d2b',
      scene: {
        create() {
          this.add.text(400, 300, 'Hello Phaser 4!', {
            fontSize: '32px',
            color: '#ffffff',
          }).setOrigin(0.5);
        }
      }
    };

    new Phaser.Game(config);
  </script>
</body>
</html>
```

**Note:** CDN URL may change as v4 stabilizes. Always check the latest stable version on npm.

---

## `.gitignore`

```
node_modules/
dist/
.DS_Store
*.local
```

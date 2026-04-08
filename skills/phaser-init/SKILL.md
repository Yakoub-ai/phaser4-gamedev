---
name: phaser-init
description: This skill should be used when the user asks to "create a Phaser game", "initialize a Phaser 4 project", "scaffold a Phaser project", "set up a new game", "start a Phaser project", "bootstrap a game", "npm create phaser", or wants to start a Phaser 4 project from scratch.
version: 0.1.0
---

# Phaser 4 Project Initialization

Scaffold a new Phaser 4 (v4.0.0-rc.7) project with TypeScript and Vite.

## Quick Scaffold (Recommended)

Use the official scaffolder for the fastest setup:

```bash
npm create @phaserjs/game@latest
```

This interactive CLI supports React, Vue, Angular, Svelte, Next.js, SolidJS, and plain TypeScript.
For beginners: choose **TypeScript + Vite** when prompted.

After scaffolding, it installs `phaser@beta` automatically. Run:

```bash
cd my-game
npm install
npm run dev
```

## Manual Scaffold

Use this when the user needs a custom setup or wants to understand each piece.

### Step 1 — Create Project

```bash
mkdir my-game && cd my-game
npm init -y
npm install phaser@beta
npm install -D typescript vite @types/node
```

### Step 2 — Directory Structure

Create this layout:

```
my-game/
├── index.html
├── package.json
├── tsconfig.json
├── vite.config.ts
├── public/
│   └── assets/
│       ├── images/
│       ├── spritesheets/
│       ├── atlases/
│       ├── audio/
│       └── tilemaps/
└── src/
    ├── main.ts
    └── scenes/
        ├── BootScene.ts
        ├── PreloaderScene.ts
        └── GameScene.ts
```

### Step 3 — Configuration Files

Generate these files exactly as shown in `examples/`:

- **`examples/game-config.ts`** — Complete `main.ts` with GameConfig
- **`examples/boot-scene.ts`** — BootScene starter template
- **`examples/vite-config.ts`** — Vite configuration for Phaser 4

Key configuration points:

**`package.json` scripts:**
```json
{
  "scripts": {
    "dev": "vite",
    "build": "tsc && vite build",
    "preview": "vite preview"
  }
}
```

**`tsconfig.json` critical fields:**
```json
{
  "compilerOptions": {
    "target": "ES2020",
    "lib": ["ES2020", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "moduleResolution": "bundler",
    "strict": true,
    "typeRoots": ["./node_modules/phaser/types"],
    "types": ["Phaser"]
  }
}
```

The `typeRoots` and `types` fields are required for Phaser's TypeScript types to work.

### Step 4 — Verify Installation

```bash
npm run dev
```

Expected: browser opens at `http://localhost:5173` showing a dark canvas (or whatever background color was set). If it shows a blank page, check the browser console for errors.

## What to Do After Scaffolding

1. Replace `GameScene.ts` with actual game logic (use phaser-coder agent)
2. Add assets to `public/assets/`
3. Design the full scene flow (use phaser-architect agent)
4. Set `arcade: { debug: false }` when done debugging

## Common Setup Mistakes

- **Assets not loading:** In Vite, assets must be in `public/`. Do NOT import them via `import`. Reference as `'assets/image.png'` (relative to server root).
- **TypeScript errors on `Phaser.*`:** Missing `typeRoots`/`types` in tsconfig. See Step 3.
- **`phaser` not found:** Run `npm install phaser@beta` (not `npm install phaser` — that installs Phaser 3).
- **Black screen:** Check browser console for 404 errors or JS errors.

## Additional Resources

### Example Files

Working templates in `examples/`:
- **`examples/game-config.ts`** — Complete main.ts with scene registration
- **`examples/boot-scene.ts`** — BootScene with minimal asset loading
- **`examples/vite-config.ts`** — Vite config for Phaser 4

### Reference Files

- **`references/project-templates.md`** — Complete file listings for TypeScript+Vite, JavaScript+Vite, and HTML-only setups
- **`references/template-archetypes.md`** — Full archetype specs for platformer, top-down RPG, space shooter, and match-3 puzzle games

## Template Archetypes

When the user wants a specific type of game rather than a blank scaffold, generate a complete working game from an archetype. The phaser-coder agent uses the archetype specs to produce all files.

Available archetypes (use with `/phaser-new [template]` or trigger the phaser-coder agent):

| Archetype | Command | Core Features |
|-----------|---------|--------------|
| `platformer` | `/phaser-new platformer` | Gravity, jump, platforms, enemies, coins, lives system |
| `topdown` | `/phaser-new topdown` | Zero gravity, 8-dir movement, tilemap world, NPC dialog |
| `shooter` | `/phaser-new shooter` | Scrolling BG, bullet pooling, enemy waves, power-ups |
| `puzzle` | `/phaser-new puzzle` | Match-3 grid, tile swapping, cascade matching, score |

All archetypes generate with placeholder assets (solid-color rectangles/circles via `Graphics.generateTexture()`) so the game runs immediately without real art. Replace with real assets when ready.

**Archetype specifications:** `references/template-archetypes.md`

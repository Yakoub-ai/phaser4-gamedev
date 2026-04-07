# phaser4-gamedev

A Claude Code plugin that makes building [Phaser 4](https://phaser.io) web games fast and easy. It ships **4 specialized agents** and **6 slash-command skills** that encode deep Phaser 4 (v4.0.0-rc.4) knowledge — so you can build any 2D web game without needing to memorize the API.

## Features

- **4 Agents** — specialized subagents for architecture, coding, debugging, and asset management
- **6 Skills** — slash commands for scaffolding, scenes, game objects, physics, building, and v3 migration
- **Phaser 4 Beam renderer knowledge** — the new WebGL renderer, shader system, and performance improvements
- **All v3→v4 breaking changes encoded** — `Geom.Point`, `Math.PI2`, `Structs`, `DynamicTexture.render()`, removed plugins
- **TypeScript-first** — all examples and templates use TypeScript with correct tsconfig for Phaser 4

---

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated

### Method 1: Interactive (recommended)

Inside a Claude Code session, run these two slash commands:

```
/plugin marketplace add Yakoub-ai/phaser4-gamedev
/plugin install phaser4-gamedev@Yakoub-ai
```

When prompted, choose your preferred scope:

| Scope | Settings file | When to use |
|---|---|---|
| **User** | `~/.claude/settings.json` | Personal use across all projects |
| **Project** | `.claude/settings.json` | Share with your team (commit this file) |
| **Local** | `.claude/settings.local.json` | Personal override in a shared repo |

If Claude Code was already running, reload the plugin:

```
/reload-plugins
```

---

### Method 2: Manual `settings.json` configuration

Add two entries to your settings file directly.

**User scope** (`~/.claude/settings.json`) — active in all your projects:

```json
{
  "extraKnownMarketplaces": {
    "Yakoub-ai": {
      "source": {
        "source": "github",
        "repo": "Yakoub-ai/phaser4-gamedev"
      }
    }
  },
  "enabledPlugins": {
    "phaser4-gamedev@Yakoub-ai": true
  }
}
```

**Project scope** (`.claude/settings.json` in your game repo) — loads automatically for everyone who opens the project:

```json
{
  "extraKnownMarketplaces": {
    "Yakoub-ai": {
      "source": {
        "source": "github",
        "repo": "Yakoub-ai/phaser4-gamedev"
      }
    }
  },
  "enabledPlugins": {
    "phaser4-gamedev@Yakoub-ai": true
  }
}
```

Then start (or restart) Claude Code — the plugin loads automatically.

---

### Verify the installation

```
/plugin list
```

You should see `phaser4-gamedev` in the list. Test a skill:

```
/phaser-init
```

---

## Agents

Agents are autonomous subagents that Claude Code launches automatically based on your request. You never need to call them by name.

### `phaser-architect`

Designs game architecture before you start coding.

**Triggers:** "design a game", "plan scene flow", "structure my Phaser project", "what scenes do I need?"

**Produces:**
- ASCII scene flow diagram
- Complete `Phaser.Types.Core.GameConfig` TypeScript config
- Module directory structure (`src/scenes/`, `objects/`, `managers/`)
- State management plan (Registry, events, direct refs)
- Asset pipeline strategy

---

### `phaser-coder`

Writes all Phaser 4 game code. This is the primary coding agent.

**Triggers:** "add a player", "implement movement", "create game logic", "add enemies", "implement scoring", "create animations"

**Knows:**
- Full scene lifecycle (`init` / `preload` / `create` / `update`)
- Arcade Physics sprites, groups, colliders, overlaps
- Input (keyboard, pointer, gamepad), animations, tweens, audio, tilemaps
- Object pooling for bullets/enemies
- HUD and parallel scene patterns
- All Phaser 4 TypeScript types

---

### `phaser-debugger`

Diagnoses and fixes Phaser 4 issues systematically.

**Triggers:** "black screen", "sprite not showing", "physics not working", "collision not detected", "game crashes", "error in console"

**Diagnoses:**
- Black screen (missing scenes, 404 assets, canvas sizing)
- Invisible sprites (position, alpha, depth, key mismatch)
- Physics failures (wrong creation method, missing collider)
- Animation failures (key mismatch, wrong frame dimensions)
- Performance problems (object pooling, particle caps, static groups)
- All v3→v4 migration errors

---

### `phaser-asset-advisor`

Guides asset loading, packing, and optimization.

**Triggers:** "sprite sheets", "texture atlases", "loading assets", "tile maps", "audio formats", "game loads slowly"

**Covers:**
- Spritesheet vs atlas vs individual images
- Texture atlas creation (free-tex-packer, TexturePacker)
- Audio: mp3+ogg pairs, audio sprites, Web Audio
- Tiled editor workflow (JSON export, collision properties)
- PreloaderScene with progress bar
- Asset size budgets and optimization

---

## Skills (Slash Commands)

### `/phaser-init` — Scaffold a New Project

```
"create a Phaser 4 game" / "scaffold a Phaser project" / "set up a new game"
```

Scaffolds a complete Phaser 4 project with TypeScript + Vite:

```bash
npm create @phaserjs/game@latest   # official scaffolder (recommended)
# or manual: creates package.json, tsconfig.json, vite.config.ts,
#            index.html, src/main.ts, src/scenes/{Boot,Preloader,Game}Scene.ts
```

Includes `examples/` with ready-to-copy templates:
- `game-config.ts` — complete GameConfig with all options annotated
- `boot-scene.ts` — minimal BootScene starter
- `vite-config.ts` — Vite config with `base: './'` for itch.io deployment

---

### `/phaser-scene` — Create Scenes

```
"create a scene" / "add a menu scene" / "create a pause screen" / "set up scene transitions"
```

Generates any scene type with correct patterns:

| Scene Type | Pattern Used |
|---|---|
| BootScene | Minimal, fast, hands off to Preloader |
| PreloaderScene | Loading bar with `this.load.on('progress')` |
| MainMenuScene | Interactive buttons with hover states |
| GameOverScene | `init(data)` to receive final score |
| HUDScene | Parallel via `this.scene.launch()`, event-driven |
| PauseScene | Modal overlay with `this.scene.pause('GameScene')` |

Covers scene transitions, cross-scene communication (Registry, events, direct refs), and data passing via `this.scene.start('Key', { data })`.

---

### `/phaser-gameobj` — Add Game Objects

```
"add a sprite" / "create a player" / "add text" / "create particles" / "add a tilemap"
```

Covers every game object type:

- **Sprites** — static and physics-enabled, atlas frames, animations
- **Images** — backgrounds, parallax with `setScrollFactor()`
- **Text / BitmapText** — styled text, HUD labels, floating damage numbers
- **Graphics** — draw shapes, health bars, debug overlays
- **Containers** — group objects for relative positioning
- **Groups** — static and physics groups, object pooling
- **Particles** — emitters with `maxParticles` cap for performance
- **TileSprites** — scrolling backgrounds

---

### `/phaser-physics` — Set Up Physics

```
"add physics" / "set up collisions" / "create a platformer" / "top-down movement" / "detect overlaps"
```

Full Arcade Physics coverage with **genre recipes**:

- **Platformer** — gravity, jump (`blocked.down`), variable jump height, coyote time
- **Top-down** — no gravity, 8-directional, diagonal normalization
- **Space shooter** — velocity-based, angle firing with `velocityFromAngle()`
- **Object pooling** — bullet groups with `classType`, `maxSize`, `runChildUpdate`

---

### `/phaser-build` — Build and Deploy

```
"build my game" / "run my Phaser game" / "deploy to itch.io" / "fix build errors"
```

Covers:
- Dev server (`npm run dev`), production build (`npm run build`)
- TypeScript errors: `input.keyboard!`, body casting, scene casting
- Common issues: 404 assets (must be in `public/`), missing `phaser@beta`
- Deployment to itch.io, GitHub Pages, Netlify/Vercel, Capacitor (iOS/Android)
- Includes `scripts/validate-project.sh` — automated health check

---

### `/phaser-migrate` — Migrate from Phaser 3

```
"migrate from Phaser 3" / "upgrade to Phaser 4" / "my v3 game broke after upgrading"
```

Scans your `src/` directory for every breaking change and applies fixes:

| v3 (removed) | v4 (use instead) |
|---|---|
| `Phaser.Geom.Point` | `Phaser.Math.Vector2` |
| `Math.PI2` | `Math.TAU` (correctly π×2) |
| `Phaser.Structs.Map/Set` | Native JS `Map` / `Set` |
| `DynamicTexture.draw()` | `.draw()` + `.render()` |
| `TileSprite.setCrop()` | `RenderTexture` |
| Camera3D, Layer3D | No replacement (2D only) |
| Facebook plugin | Removed |
| Bundled Spine plugin | Official Esoteric Software plugin |

---

## Phaser 4 Key Facts

| Topic | Value |
|---|---|
| Install | `npm install phaser@beta` |
| Latest version | v4.0.0-rc.4 |
| Scaffold | `npm create @phaserjs/game@latest` |
| Renderer | "Phaser Beam" (new WebGL, up to 16x faster filters on mobile) |
| TypeScript types | `typeRoots: ["./node_modules/phaser/types"]`, `types: ["Phaser"]` |
| Core API vs v3 | Mostly identical (scenes, physics, input, audio, cameras) |

---

## Validation

Validate the plugin structure:

```bash
bash scripts/validate-plugin.sh
```

Validate a Phaser 4 project:

```bash
bash skills/phaser-build/scripts/validate-project.sh /path/to/your/game
```

---

## Plugin Structure

```
phaser4-gamedev/
├── .claude-plugin/
│   └── plugin.json
├── agents/
│   ├── phaser-architect.md
│   ├── phaser-coder.md
│   ├── phaser-debugger.md
│   └── phaser-asset-advisor.md
├── skills/
│   ├── phaser-init/       SKILL.md + references/ + examples/
│   ├── phaser-scene/      SKILL.md + references/
│   ├── phaser-gameobj/    SKILL.md + references/
│   ├── phaser-physics/    SKILL.md + references/
│   ├── phaser-build/      SKILL.md + scripts/
│   └── phaser-migrate/    SKILL.md + references/
└── scripts/
    └── validate-plugin.sh
```

---

## License

MIT

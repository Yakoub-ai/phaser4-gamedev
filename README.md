# phaser4-gamedev

A Claude Code plugin that makes building [Phaser 4](https://phaser.io) web games fast and easy. It ships **4 specialized agents**, **16 slash-command skills**, **6 commands**, and **2 hooks** that encode deep Phaser 4 (v4.0.0-rc.7) knowledge — so you can build any 2D web game without needing to memorize the API.

## Features

- **4 Agents** — specialized subagents for architecture, coding, debugging, and asset management
- **16 Skills** — slash commands covering the full game development lifecycle
- **6 Commands** — `/phaser-new`, `/phaser-run`, `/phaser-validate`, `/phaser-build`, `/phaser-gdd`, `/phaser-analyze`
- **2 Hooks** — PreToolUse v3 API guard (catches deprecated APIs before code is saved) + SessionStart Phaser project detector
- **9 Game Archetypes** — platformer, top-down RPG, space shooter, match-3 puzzle, tower defense, endless runner, card game, fighting game, racing — full specs with `/phaser-new`
- **Game Design Documents** — generate comprehensive 12-section GDDs with `/phaser-gdd`
- **Project Analysis** — analyze existing projects for architecture, performance, and code quality with `/phaser-analyze`
- **Device Profiles** — platform-specific optimization guides for iOS, Android, desktop, Capacitor, and PWA
- **Asset Sourcing** — guides for finding free assets, creation tools, and placeholder-to-production workflows
- **Phaser 4 Beam renderer knowledge** — the new WebGL renderer, shader system, and performance improvements
- **All v3→v4 breaking changes encoded** — `Geom.Point`, `Math.PI2`, `Structs`, `DynamicTexture.render()`, removed plugins
- **TypeScript-first** — all examples and templates use TypeScript with correct tsconfig for Phaser 4

---

## Installation

### Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated

### Optional: Context7 MCP Server

The plugin's agents reference [Context7](https://github.com/upstash/context7) for live Phaser 4 API verification. While agents work without it (they have extensive built-in Phaser 4 knowledge), installing Context7 enables real-time API lookups for edge cases during the RC phase.

### Method 1: Interactive (recommended)

Inside a Claude Code session, run these two slash commands:

```
/plugin marketplace add Yakoub-ai/phaser4-gamedev
/plugin install phaser4-gamedev@phaser4-gamedev
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
    "phaser4-gamedev": {
      "source": {
        "source": "github",
        "repo": "Yakoub-ai/phaser4-gamedev"
      }
    }
  },
  "enabledPlugins": {
    "phaser4-gamedev@phaser4-gamedev": true
  }
}
```

**Project scope** (`.claude/settings.json` in your game repo) — loads automatically for everyone who opens the project:

```json
{
  "extraKnownMarketplaces": {
    "phaser4-gamedev": {
      "source": {
        "source": "github",
        "repo": "Yakoub-ai/phaser4-gamedev"
      }
    }
  },
  "enabledPlugins": {
    "phaser4-gamedev@phaser4-gamedev": true
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

## Skills (16 Slash Commands)

### Core Skills

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

### Game Systems

### `/phaser-audio` — Audio System

```
"add sound effects" / "play background music" / "set up audio" / "audio not playing on mobile"
```

Covers Web Audio vs HTML5, loading mp3+ogg pairs, sound pooling, audio sprites, volume management, mute buttons, mobile audio unlock, crossfading between scenes, and cleanup on shutdown.

---

### `/phaser-animation` — Animations and Tweens

```
"animate a sprite" / "add walk cycle" / "tween a button" / "create particle effects"
```

Covers spritesheet and atlas-based animations, character state machines, animation chaining and events, tweens (fade, scale, slide, bounce), easing functions, tween timelines, and particle animations.

---

### `/phaser-input` — Input Handling

```
"add keyboard controls" / "handle mouse clicks" / "add gamepad support" / "detect touch input"
```

Covers keyboard (cursors, WASD, combos), pointer/mouse (drag-and-drop, input zones), multi-touch (swipe detection), gamepad (analog sticks with dead zones), and virtual joystick patterns.

---

### `/phaser-tilemap` — Tilemaps

```
"add a tilemap" / "set up Tiled" / "tile collision" / "parallax layers"
```

Full Tiled Editor workflow — creating maps, tilesets, collision properties, layer naming conventions, object layers (spawn points, triggers), camera/world bounds, dynamic tile manipulation, and parallax.

---

### `/phaser-ui` — User Interface

```
"add a health bar" / "create buttons" / "build a dialog box" / "add a minimap"
```

Covers health bars (Graphics-based), score/text displays, interactive buttons, dialog boxes (Container-based), minimap, progress bars, BitmapText for performance, DOM overlay, responsive scaling, and HUD-as-parallel-scene pattern.

---

### Advanced Features

### `/phaser-matter` — Matter.js Physics

```
"use Matter physics" / "polygon collision" / "add constraints" / "create sensors"
```

Covers Arcade vs Matter decision guide, body types (rectangle, circle, polygon, compound, static), forces, collision filtering with categories/bitmasks, sensors/trigger zones, constraints (distance, spring, pin/hinge), and debug rendering.

---

### `/phaser-saveload` — Save and Load

```
"save the game" / "load game state" / "add auto-save" / "multiple save slots"
```

Covers what to save vs reconstruct, localStorage patterns, typed SaveData with defaults, SaveManager class, multi-slot saves, auto-save (event + periodic), Registry integration, settings storage, hi-score tables, save data versioning, and cloud save architecture.

---

### `/phaser-mobile` — Mobile Deployment

```
"deploy to mobile" / "responsive scaling" / "touch controls" / "make a PWA"
```

Covers Scale Manager modes (FIT/ENVELOP/RESIZE), touch controls and responsive layout, preventing browser gestures, mobile audio unlock, device detection, performance guidelines, Capacitor deployment (iOS/Android), and PWA setup (manifest, service worker). Includes device-specific profiles for iOS Safari, Android Chrome, desktop, Capacitor, and PWA.

---

### `/phaser-gdd` — Game Design Document

```
"write a game design document" / "create a GDD" / "design my game" / "plan game progression"
```

Generates a comprehensive 12-section Game Design Document: game overview, core loop, mechanics deep dive, progression system, level/world design, characters & entities, UI/UX wireframes, art direction, audio design plan, technical requirements, platform targets, and monetization/release plan. Includes example GDD templates for platformer, puzzle, and RPG genres.

---

### `/phaser-analyze` — Project Analysis

```
"analyze my game" / "review my Phaser project" / "audit project health" / "find bottlenecks"
```

5-phase analysis for existing Phaser projects: discovery (file/scene/LOC counts), architecture assessment (A-F grade), performance audit (pooling, particles, static groups), API correctness (v3 scan, TypeScript strictness), and best practice check (lifecycle, cleanup, debug flags). Produces a structured report with improvement roadmap and quick wins. Includes automated `analyze-project.sh` script.

---

## Commands

| Command | Description |
|---|---|
| `/phaser-new [template]` | Scaffold a new game — optionally from an archetype (`platformer`, `topdown`, `shooter`, `puzzle`, `towerdefense`, `runner`, `cardgame`, `fighting`, `racing`) |
| `/phaser-run` | Start the dev server |
| `/phaser-validate` | Run the project health check (structure, runtime, smoke tests, deploy checklist) |
| `/phaser-build` | Production build and deployment prep |
| `/phaser-gdd [genre]` | Generate a comprehensive 12-section Game Design Document |
| `/phaser-analyze` | Analyze an existing project for architecture, performance, and code quality |

---

## Hooks

| Hook | Event | Purpose |
|---|---|---|
| **v3 API Guard** | PreToolUse (Write/Edit) | Catches deprecated Phaser 3 APIs (`Geom.Point`, `Math.PI2`, `Structs.Map`, etc.) before code is saved |
| **Project Detector** | SessionStart | Detects Phaser projects, shows available agents/commands/skills |

---

## Phaser 4 Key Facts

| Topic | Value |
|---|---|
| Install | `npm install phaser@beta` |
| Latest version | v4.0.0-rc.7 |
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
│   ├── plugin.json
│   └── marketplace.json
├── agents/
│   ├── phaser-architect.md      (opus)
│   ├── phaser-coder.md          (sonnet)
│   ├── phaser-debugger.md       (opus)
│   └── phaser-asset-advisor.md  (sonnet)
├── commands/
│   ├── phaser-new.md
│   ├── phaser-run.md
│   ├── phaser-validate.md
│   ├── phaser-build.md
│   ├── phaser-gdd.md
│   └── phaser-analyze.md
├── hooks/
│   ├── hooks.json
│   └── scripts/
│       ├── check-v3-api.sh
│       └── detect-phaser.sh
├── skills/
│   ├── phaser-init/         scaffolding + 9 game archetypes
│   ├── phaser-scene/        scene creation and transitions
│   ├── phaser-gameobj/      sprites, text, particles, containers
│   ├── phaser-physics/      Arcade Physics + multiplayer patterns
│   ├── phaser-build/        build, deploy, validate + testing patterns
│   ├── phaser-migrate/      v3 → v4 migration
│   ├── phaser-audio/        Web Audio, audio sprites, mobile unlock
│   ├── phaser-animation/    spritesheets, tweens, state machines
│   ├── phaser-input/        keyboard, mouse, touch, gamepad
│   ├── phaser-tilemap/      Tiled workflow, layers, collision
│   ├── phaser-ui/           health bars, buttons, dialogs, HUD
│   ├── phaser-matter/       Matter.js physics, constraints, sensors
│   ├── phaser-saveload/     save/load, auto-save, versioning
│   ├── phaser-mobile/       Scale Manager, Capacitor, PWA, device profiles
│   ├── phaser-gdd/          Game Design Document generation
│   └── phaser-analyze/      brownfield project analysis + automated script
└── scripts/
    └── validate-plugin.sh
```

---

## License

MIT

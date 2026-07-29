# phaser4-gamedev

A portable agent-skills package and Claude Code plugin that makes building [Phaser 4](https://phaser.io) web games fast and easy. It ships **21 portable skills**, **5 Claude Code subagents**, **7 Claude slash commands**, and **2 Claude hooks** that encode deep Phaser 4 (v4.0.0-rc.7) knowledge — so you can build any 2D web game without needing to memorize the API.

It covers the whole loop, not just the coding part:

```
/phaser-gdd ──► /phaser-new ──► phaser-coder ──► /phaser-playtest ──► /phaser-build
   plan            scaffold        implement       VERIFY RUNNING         ship
     │                                 ▲                  │
     │                                 └──── fix ─────────┘
     └── acceptance criteria ─────────────────► playtest scenarios
```

The step most toolkits skip is `/phaser-playtest`. `tsc --noEmit` proves your code
*compiles*; it says nothing about whether the game *runs*. A mistyped asset path, a
scene left out of `scene: []`, a throw partway through `create()` — all type-check
perfectly and all ship a black screen. The playtest harness boots the real game in
headless Chromium, drives real input, and reports what actually happened.

## Features

- **21 Portable Skills** — installable with `npx skills add` for Codex, Claude Code, Cursor, OpenCode, and other compatible coding agents
- **5 Claude Code Agents** — specialized subagents for architecture, coding, debugging, asset management, and playtesting
- **7 Claude Commands** — `/phaser-new`, `/phaser-run`, `/phaser-playtest`, `/phaser-validate`, `/phaser-build`, `/phaser-gdd`, `/phaser-analyze`
- **Headless Playtest Harness** — a real, runnable Playwright script that boots the game, catches black screens, asset 404s, uncaught exceptions and FPS collapse, drives scripted input, and asserts on live game state
- **2 Claude Hooks** — PreToolUse v3 API guard (catches deprecated APIs before code is saved) + SessionStart Phaser project detector
- **9 Game Archetypes** — platformer, top-down RPG, space shooter, match-3 puzzle, tower defense, endless runner, card game, fighting game, racing — full specs with `/phaser-new`
- **Game Design Documents** — generate comprehensive 13-section GDDs with `/phaser-gdd`
- **Project Analysis** — analyze existing projects for architecture, performance, and code quality with `/phaser-analyze`
- **Device Profiles** — platform-specific optimization guides for iOS, Android, desktop, Capacitor, and PWA
- **Asset Sourcing** — guides for finding free assets, creation tools, and placeholder-to-production workflows
- **Phaser 4 Beam renderer knowledge** — the new WebGL renderer, shader system, and performance improvements
- **All v3→v4 breaking changes encoded** — `Geom.Point`, `Math.PI2`, `Structs`, `DynamicTexture.render()`, removed plugins
- **TypeScript-first** — all examples and templates use TypeScript with correct tsconfig for Phaser 4

---

## Installation

Choose the install path based on what you want:

| Install path | Best for | Installs |
|---|---|---|
| **skills.sh / `npx skills`** | Codex, Cursor, OpenCode, Claude Code standalone skills, and other Agent Skills-compatible tools | Portable `skills/*/SKILL.md` only |
| **Claude Code plugin** | Claude Code users who want the full plugin experience | Skills, Claude subagents, slash commands, and hooks |

The portable skills and Claude plugin can coexist. Use the skills.sh path for cross-agent portability; use the Claude Code plugin path when you specifically want Claude Code commands, agents, and hooks.

### skills.sh / Agent Skills

This repository is compatible with the open Agent Skills CLI that powers [skills.sh](https://skills.sh). The CLI discovers every `SKILL.md` under `skills/`, so the Phaser toolkit can be installed directly into Codex or any supported coding agent.

List the available skills:

```bash
npx skills add Yakoub-ai/phaser4-gamedev --list
```

Install all Phaser skills into Codex globally:

```bash
npx skills add Yakoub-ai/phaser4-gamedev --skill '*' --agent codex --global
```

Install all Phaser skills into Claude Code as standalone Agent Skills:

```bash
npx skills add Yakoub-ai/phaser4-gamedev --skill '*' --agent claude-code --global
```

Install all Phaser skills into every supported agent:

```bash
npx skills add Yakoub-ai/phaser4-gamedev --all
```

Restart your coding agent after installing so it reloads its skills directory. For Codex global installs, the target skills directory is `~/.codex/skills/`.

The portable skills include the original lifecycle skills plus portable equivalents of the Claude subagents:

- `phaser-architect`
- `phaser-coder`
- `phaser-debugger`
- `phaser-asset-advisor`

`phaser-playtest` is the portable equivalent of the `phaser-playtester` subagent — the harness is a plain Node script, so it works from any agent (or from your own terminal and CI) with no Claude Code dependency.

The repository also includes `.codex-plugin/plugin.json` with `skills: "./skills/"` for Codex plugin discovery.

To make this repository discoverable/installable through skills.sh-compatible tooling, keep the `skills/<skill-name>/SKILL.md` structure valid and publish the repository. There is no `skills.sh` file to edit in this repo; users install from the GitHub repo with `npx skills add Yakoub-ai/phaser4-gamedev`.

### Claude Code plugin

Use this path when you want the complete Claude Code integration: plugin-scoped skills, subagents, slash commands, and hooks.

#### Prerequisites

- [Claude Code](https://claude.ai/code) CLI installed and authenticated

#### Recommended: Playwright (for `/phaser-playtest`)

The playtest harness needs a browser. Install it once per game project:

```bash
npm install -D playwright && npx playwright install chromium
```

Without it, everything else still works — you just lose runtime verification, which is
the part that catches black screens.

#### Optional: Context7 MCP Server

The agents verify Phaser 4 APIs against `node_modules/phaser/types/phaser.d.ts` in your
project first — that is the exact signature for your installed version and cannot be out
of date. [Context7](https://github.com/upstash/context7) is an optional addition that
supplies the prose and examples type definitions lack, which is useful during the RC
phase. The agents' `tools` allowlists already grant the Context7 MCP tools, so it works
as soon as the server is configured.

#### Method 1: Interactive (recommended)

Inside a Claude Code session, run these two slash commands:

```
/plugin marketplace add Yakoub-ai/phaser4-gamedev
/plugin install phaser4-gamedev@phaser4-gamedev
```

When prompted, choose your preferred scope. Claude Code plugin scopes map to these settings files:

| Scope | Settings file | When to use |
|---|---|---|
| **User** | `~/.claude/settings.json` | Personal use across all projects |
| **Project** | `.claude/settings.json` | Share with your team (commit this file) |
| **Local** | `.claude/settings.local.json` | Personal override in a shared repo |

Restart Claude Code after installing so the plugin is loaded from Claude's plugin cache.

#### Method 2: Manual Claude Code settings

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

#### Method 3: Claude Code CLI

Claude Code also supports non-interactive plugin management from the shell:

```bash
claude plugin marketplace add Yakoub-ai/phaser4-gamedev
claude plugin install phaser4-gamedev@phaser4-gamedev --scope user
```

Use `--scope project` instead of `--scope user` when you want to write the plugin install to `.claude/settings.json` for a shared repository.

---

#### Verify the installation

```
/plugin
```

You should see `phaser4-gamedev` in the installed plugins list. Then verify the Claude Code plugin features you need:

- Run `/help` and confirm the Phaser slash commands are present.
- Check `/agents` for the Phaser subagents.
- Test a command such as `/phaser-new` or `/phaser-gdd`.

---

## Claude Code Agents

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

### `phaser-playtester`

Verifies the game actually runs. Owns runtime verification the way phaser-coder owns implementation.

**Triggers:** "playtest my game", "does it actually work", "verify the game runs", "smoke test", "write a playtest scenario", "check FPS", "screenshot the game"

**Does:**
- Boots the game in headless Chromium and reports what really happened
- Catches black screens, asset 404s (including files the dev server masks as `200 text/html`), uncaught exceptions, dead scenes, FPS collapse
- Drives scripted input — keys, clicks, touch — and asserts on live `Phaser.Game` state
- Turns GDD acceptance criteria into regression scenarios
- States plainly what it could *not* verify (audio audibility, real-device perf, whether the game is fun)

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

## Skills

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

### `/phaser-playtest` — Verify the Game Actually Runs

```
"playtest my game" / "does my game actually work" / "test it in a browser" / "smoke test"
```

Runs the game in headless Chromium and reports what really happens:

```bash
node skills/phaser-playtest/scripts/playtest.mjs --project .
```

```
[PASS] page loads — HTTP 200
[PASS] canvas created — 800x600
[PASS] Phaser game instance found — window.__PHASER_GAME__
[INFO] renderer — WEBGL (Phaser 4.0.0 RC7)
[PASS] active scenes — GameScene(43 objects)
[PASS] frame rate — median 60 fps, 5th pct 59 fps (91 frames)
[PASS] canvas renders content — 333 distinct colours, 5.6% non-background
[FAIL] all assets load — HTTP 200 but served as text/html — file is missing
       and the dev server returned index.html instead  /assets/player.png
```

Checks the page loads, the canvas exists and is **not blank**, Phaser booted, scenes
are active and holding display objects, frame rate holds, and every asset loaded — plus
console errors, uncaught exceptions, and failed requests. Writes `.playtest/report.json`
and PNG screenshots. Exits non-zero on failure, so it drops straight into CI.

Scenarios drive real input and assert on live state:

```javascript
export default [
  { name: 'walk right', action: 'key', key: 'ArrowRight', duration: 600 },
  { name: 'player advanced', action: 'expect',
    expect: { expression: `game.scene.getScene('GameScene').player.x > 400`, equals: true } },
  { name: 'attack lands', action: 'press', key: 'Space',
    expect: { expression: `game.registry.get('enemyHp')`, atMost: 90 } },
];
```

`--mode build` tests the production bundle (where `base`-path and tree-shaking bugs
live). `--device iphone` tests a mobile viewport. Requires
`npm install -D playwright && npx playwright install chromium`.

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

Generates a comprehensive 13-section Game Design Document: game overview, core loop, mechanics deep dive, progression system, level/world design, characters & entities, UI/UX wireframes, art direction, audio design plan, technical requirements, platform targets, monetization/release plan, and machine-checkable acceptance criteria. Includes example GDD templates for platformer, puzzle, and RPG genres.

---

### `/phaser-analyze` — Project Analysis

```
"analyze my game" / "review my Phaser project" / "audit project health" / "find bottlenecks"
```

5-phase analysis for existing Phaser projects: discovery (file/scene/LOC counts), architecture assessment (A-F grade), performance audit (pooling, particles, static groups), API correctness (v3 scan, TypeScript strictness), and best practice check (lifecycle, cleanup, debug flags). Produces a structured report with improvement roadmap and quick wins. Includes automated `analyze-project.sh` script.

---

## Claude Code Commands

| Command | Description |
|---|---|
| `/phaser-new [template]` | Scaffold a new game — optionally from an archetype (`platformer`, `topdown`, `shooter`, `puzzle`, `towerdefense`, `runner`, `cardgame`, `fighting`, `racing`) |
| `/phaser-run` | Start the dev server and verify the game boots |
| `/phaser-playtest [dev\|build\|mobile]` | Run the game headless and verify it actually works |
| `/phaser-validate` | Run the project health check (structure, runtime, smoke tests, deploy checklist) |
| `/phaser-build` | Production build and deployment prep |
| `/phaser-gdd [genre]` | Generate a comprehensive 13-section Game Design Document |
| `/phaser-analyze` | Analyze an existing project for architecture, performance, and code quality |

---

## Claude Code Hooks

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

Validate a Phaser 4 project's structure:

```bash
bash skills/phaser-build/scripts/validate-project.sh /path/to/your/game
```

Verify a Phaser 4 project actually runs:

```bash
node skills/phaser-playtest/scripts/playtest.mjs --project /path/to/your/game
```

---

## Plugin Structure

```
phaser4-gamedev/
├── .claude-plugin/
│   ├── plugin.json
│   └── marketplace.json
├── .codex-plugin/
│   └── plugin.json
├── agents/
│   ├── phaser-architect.md      (opus)
│   ├── phaser-coder.md          (sonnet)
│   ├── phaser-debugger.md       (opus)
│   ├── phaser-asset-advisor.md  (sonnet)
│   └── phaser-playtester.md     (sonnet)
├── commands/
│   ├── phaser-new.md
│   ├── phaser-run.md
│   ├── phaser-playtest.md
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
│   ├── phaser-architect/    portable architecture planning skill
│   ├── phaser-coder/        portable implementation skill
│   ├── phaser-debugger/     portable debugging skill
│   ├── phaser-asset-advisor/ portable asset pipeline skill
│   ├── phaser-scene/        scene creation and transitions
│   ├── phaser-gameobj/      sprites, text, particles, containers
│   ├── phaser-physics/      Arcade Physics + multiplayer patterns
│   ├── phaser-playtest/     headless runtime verification harness + scenarios
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

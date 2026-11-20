---
name: phaser-init
description: This skill should be used when the user asks to "create a Phaser game", "initialize a Phaser 4 project", "scaffold a Phaser project", "set up a new game", "start a Phaser project", "bootstrap a game", "npm create phaser", or wants to start a Phaser 4 project from scratch.
version: 0.8.0
---

# Phaser 4 Project Initialization

Create a Phaser 4 (v4.2.1) + TypeScript + Vite project that is verified to boot, play,
and build before any game code is written.

## Scaffold

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-init/scripts/scaffold.mjs" <dir> [options]
```

| Option | Default | Use |
|---|---|---|
| `--physics arcade\|matter\|none` | `arcade` | See the table below |
| `--width N --height N` | `1280 720` | Design resolution; `Scale.FIT` handles the rest |
| `--pixel-art` | off | Crisp nearest-neighbour scaling |
| `--title TEXT` | from dir name | Menu and `<title>` text |
| `--name NAME` | from dir name | npm package name |
| `--no-ci` | CI on | Skip the GitHub Actions workflows |
| `--no-install` | install on | Skip `npm install` |

It is deterministic and non-interactive: no prompts, no remote templates, nothing
downloaded but the pinned npm dependencies. It refuses to overwrite an existing file, so
it is safe to run in a directory that already holds `docs/GDD.md` or a `.git/`.

Then prove it works:

```bash
cd <dir> && npm run verify     # tsc + vitest + production-build playtest
```

If Playwright reports a missing browser, run `npx playwright install chromium` once
(or pass `--browser /path/to/chromium` to the harness when one is already installed).

### What you get

```
index.html                  no inline script; CSP injected at build time
vite.config.ts              base './', CSP plugin, no source maps in production
tsconfig.json               strict, moduleResolution bundler, types: [vite/client]
src/main.ts                 GameConfig + the __PHASER_GAME__ test hook (dev/playtest only)
src/scenes/                 Boot → Preloader → MainMenu → Game → GameOver (keys = class names)
src/logic/score.ts          pure rules, no Phaser import — unit-testable
tests/score.test.ts         Vitest
playtest/smoke.mjs          menu → play → move → score → game over, as assertions
tools/playtest.mjs          the playtest harness, vendored so CI needs no plugin
public/assets/              everything Phaser loads at runtime
.github/workflows/          ci.yml (verify every push/PR), deploy-pages.yml (on tag)
.github/dependabot.yml      weekly npm, monthly actions updates
```

The starter loop (move with arrows / WASD / touch, collect, beat the clock) exists to
prove input, rendering, scene flow and storage all work. Replace it — keep the shape.

| Script | Does |
|---|---|
| `npm run dev` | Dev server with hot reload |
| `npm run build` | `tsc --noEmit && vite build` → `dist/` |
| `npm test` | Vitest unit tests |
| `npm run playtest` | Every scenario in `playtest/` against the dev server |
| `npm run playtest:build` | Same, against the minified production bundle |
| `npm run verify` | typecheck + test + `playtest:build` — the gate CI runs |

## Choosing options for any game

Pick from the game's needs, not its genre label. When a GDD exists, decide from Sections 3
(mechanics), 10 (technical requirements) and 11 (platform targets).

**Physics**

| The game needs | Use |
|---|---|
| Grid, turn, card, puzzle, narrative, idle/clicker, rhythm, menus only | `none` — tweens and grid logic; no physics cost |
| Platforming, top-down movement, bullets, overlaps, many fast bodies | `arcade` — AABB/circle, cheapest, the default |
| Rotation-accurate collisions, stacking, joints, ragdolls, pinball, physics puzzles | `matter` — see the `phaser-matter` skill |

Arcade and Matter can coexist (enable both in `physics`) when one mechanic genuinely
needs rigid bodies; start with one.

**Resolution**

| Style | Size |
|---|---|
| HD / vector / UI-heavy | `1280x720` (default) |
| Pixel art | `640x360`, `480x270` or `320x180` with `--pixel-art` (integer-scales to 1080p) |
| Mobile portrait | `720x1280` — also read the `phaser-mobile` skill |
| Square / puzzle | `1080x1080` |

## After scaffolding

- **Known genre** → the phaser-coder agent builds the archetype from
  `references/template-archetypes.md` on top of this scaffold (scene keys match).
- **Anything else** → the GDD-driven path: phaser-architect writes
  `docs/ARCHITECTURE.md` from `docs/GDD.md`, then `/phaser-dev` builds and verifies it
  one phase at a time. This is the path for games no archetype describes.
- Each feature gets a scenario in `playtest/`; it stays as a regression test.
- Real assets go in `public/assets/` and load by relative path
  (`this.load.image('player', 'assets/player.png')`). Reuse the placeholder's texture key
  and nothing else changes. See `references/asset-sourcing-guide.md`.

## Other setups

**React / Vue / Svelte / Angular / Next.js shell.** The official `npm create
@phaserjs/game@latest` CLI generates these. It is interactive and fetches its templates
from GitHub at run time, so the user runs it themselves rather than Claude. Afterwards,
bring the project up to this plugin's gate: add the `__PHASER_GAME__` line next to
`new Phaser.Game(...)`, add `"types": ["vite/client"]` to tsconfig, copy
`skills/phaser-playtest/scripts/playtest.mjs` to `tools/`, and add a smoke scenario.

**Existing project.** Do not scaffold over it. Add the same four items above, then run
`/phaser-validate`.

## Common setup mistakes

- **Assets 404 / black screen:** runtime assets belong in `public/`, referenced by
  relative path. Never `import` a file Phaser loads by URL.
- **`TS2688: Cannot find type definition file for 'Phaser'`:** a v3-era tsconfig with
  `typeRoots`/`types: ["Phaser"]`. Delete both; Phaser 4 ships types via its `exports` map.
- **`TS2339: Property 'env' does not exist on type 'ImportMeta'`:** add
  `"types": ["vite/client"]`.
- **Installed an old version:** never `phaser@beta` — that tag still points at
  `4.0.0-rc.7`. Use `npm install phaser@latest`.
- **`terser not found` on build:** Vite 8 minifies with Oxc by default; remove
  `minify: 'terser'` rather than installing terser.
- **State carries over after restarting a scene:** scene instances are reused. Reset
  fields in `create()` (or `init()`), not in field initialisers.

## Template Archetypes

Complete game specs layered onto the scaffold by the phaser-coder agent:

| Archetype | Core features | Physics |
|---|---|---|
| `platformer` | Gravity, jump, platforms, enemies, coins, lives | arcade |
| `topdown` | 8-dir movement, tilemap world, NPC dialog | arcade |
| `shooter` | Scrolling BG, bullet pooling, enemy waves, power-ups | arcade |
| `puzzle` | Match-3 grid, swapping, cascades, score | none |
| `towerdefense` | Grid placement, waves, economy, projectile pooling | arcade |
| `runner` | Auto-scroll, jump/slide, procedural obstacles, parallax | arcade |
| `cardgame` | Memory match, flip animations, move scoring | none |
| `fighting` | State-machine fighters, 2-player local, hitboxes, rounds | arcade |
| `racing` | Rotation steering, checkpoints, AI opponents | arcade |

**Specs:** `references/template-archetypes.md`

## Additional Resources

- **`scripts/scaffold.mjs`** — the scaffolder (`--help` for options)
- **`template/`** — the exact files it writes; read these instead of guessing a config
- **`references/template-archetypes.md`** — archetype specs
- **`references/asset-sourcing-guide.md`** — free asset sources and licensing

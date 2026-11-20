---
description: Scaffold a new Phaser 4 game project, verified to boot, play and build
argument-hint: [template] — custom (from docs/GDD.md), blank, platformer, topdown, shooter, puzzle, towerdefense, runner, cardgame, fighting, racing
---

Create a new Phaser 4 project and prove it runs before handing it over.

Interpret $ARGUMENTS as the template. If none was given: use `custom` when
`docs/GDD.md` exists, otherwise ask what game they want to make (one question; offer the
archetypes and "something else" — never force a genre onto an idea that doesn't fit one).

## Process

1. **Pick the directory.** Use the current directory if it holds nothing but `docs/`,
   `.git/` or other non-project files; otherwise ask for a subdirectory name. The
   scaffolder refuses to overwrite files — if it lists conflicts, report them and stop;
   never delete the user's files to make room.

2. **Decide the options** using the tables in the `phaser-init` skill ("Choosing options
   for any game"):
   - `custom` → read `docs/GDD.md` Sections 3, 10 and 11 and pick physics, resolution and
     pixel-art from what the mechanics and platforms actually need.
   - An archetype → its physics column in the `phaser-init` skill.
   - `blank` → defaults.
   State the choice and why in one line each.

3. **Scaffold:**
   ```bash
   node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-init/scripts/scaffold.mjs" <dir> --title "<title>" [--physics …] [--width … --height …] [--pixel-art]
   ```
   Do not use `npm create @phaserjs/game` — it is interactive and fetches remote
   templates at run time. If the user wants a React/Vue/Svelte shell, follow "Other
   setups" in the `phaser-init` skill instead.

4. **Verify the base before building on it:**
   ```bash
   cd <dir> && npm run verify
   ```
   If Playwright has no browser, run `npx playwright install chromium` (say so first)
   and re-run. A scaffold that fails `verify` is a bug to report, not to build on.

5. **Build the game layer:**
   - **Archetype** → delegate to the phaser-coder agent with the archetype's section of
     `skills/phaser-init/references/template-archetypes.md`. It replaces the starter
     `GameScene` and adds a `playtest/<archetype>.mjs` scenario for the archetype's core
     loop. Run `npm run verify` again afterwards.
   - **custom** → if `docs/ARCHITECTURE.md` is missing, delegate to the phaser-architect
     agent to write it from the GDD. Then tell the user to run `/phaser-dev` — do not
     implement every phase in one pass.
   - **blank** → stop here.

6. **Report:** the directory, the options chosen, the `verify` result with pass counts
   (never call a failing run working), and the next step — `npm run dev` to play,
   `/phaser-dev` to build the next phase.

## Templates

| Template | Builds |
|---|---|
| `custom` | Anything: driven by `docs/GDD.md` → `docs/ARCHITECTURE.md` → `/phaser-dev` |
| `blank` | The verified starter only |
| `platformer` · `topdown` · `shooter` · `puzzle` · `towerdefense` · `runner` · `cardgame` · `fighting` · `racing` | A complete archetype — see the `phaser-init` skill |

No GDD yet and the idea is fuzzy? `/phaser-brainstorm` first, then `/phaser-gdd`.

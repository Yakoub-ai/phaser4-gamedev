---
description: Scaffold a new Phaser 4 game project
argument-hint: [template] — platformer, topdown, shooter, puzzle, towerdefense, runner, cardgame, fighting, racing, or blank (default)
---

Create a new Phaser 4 game project. The optional argument specifies the game template archetype.

If an argument was provided ($ARGUMENTS), treat it as the desired game template type (platformer, topdown, shooter, puzzle, or blank). If no argument was provided, ask the user which template they want before proceeding.

## Process

1. **Determine template type** — from $ARGUMENTS or by asking the user.

2. **Check for existing project** — Look for an existing `package.json` in the current directory. If found, warn the user that scaffolding here will add files to an existing project, and confirm before proceeding.

3. **Run the official scaffolder** for a blank project, OR delegate to the phaser-coder agent for a template archetype:

   **For `blank` template:**
   Run the official scaffolder and guide the user through it:
   ```bash
   npm create @phaserjs/game@latest
   ```
   Then follow the setup steps from the phaser-init skill.

   **For `platformer`, `topdown`, `shooter`, or `puzzle`:**
   - First run `npm create @phaserjs/game@latest` to scaffold the base project (TypeScript+Vite).
   - Then use the phaser-coder agent to generate all game-specific files according to the archetype in `skills/phaser-init/references/template-archetypes.md`.
   - Generate placeholder assets using `Phaser.GameObjects.Graphics` + `generateTexture()` so the game works immediately without real art.

4. **After scaffolding**, tell the user:
   - How to start the dev server (`npm run dev`)
   - What to customize first
   - Which agents and skills are available to help

## Available Templates

| Template | Description |
|----------|-------------|
| `blank` | Minimal scaffold: Boot, Preloader, MainMenu, Game scenes only |
| `platformer` | Side-scrolling platformer with player, enemies, platforms, collectibles |
| `topdown` | Top-down RPG with tilemap world, 8-dir movement, NPC interaction |
| `shooter` | Space shooter with scrolling background, bullet pooling, enemy waves |
| `puzzle` | Match-3 grid puzzle with tile swapping, matching, cascade logic |
| `towerdefense` | Grid-based tower defense with enemy waves, tower types, economy system |
| `runner` | Endless runner with auto-scrolling, jump/slide mechanics, increasing difficulty |
| `cardgame` | Card-based memory match game with flip animations, scoring |
| `fighting` | 2-player local fighting game with state machine fighters, round system |
| `racing` | Top-down racing with rotation steering, checkpoints, AI opponents |

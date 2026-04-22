# CLAUDE.md — phaser4-gamedev Plugin

## Repo Structure

```
agents/          — 4 specialized subagent definitions (Markdown with YAML frontmatter)
                   phaser-architect, phaser-coder, phaser-debugger, phaser-asset-advisor
commands/        — Slash command definitions (6 commands)
                   phaser-new, phaser-run, phaser-validate, phaser-build, phaser-gdd, phaser-analyze
skills/          — Each skill has SKILL.md + references/ + optional examples/ and scripts/
                   16 skills: phaser-init, phaser-scene, phaser-gameobj, phaser-physics,
                   phaser-audio, phaser-animation, phaser-input, phaser-tilemap,
                   phaser-ui, phaser-build, phaser-migrate, phaser-matter,
                   phaser-saveload, phaser-mobile, phaser-gdd, phaser-analyze
hooks/           — SessionStart detector + PreToolUse v3 API guard
                   hooks.json defines hook configuration; scripts/ contains detect-phaser.sh
.claude-plugin/  — plugin.json + marketplace.json
                   Plugin metadata, versioning, and marketplace listing
scripts/         — Validation and utility scripts
```

## Conventions

### Skills
- Every skill lives in `skills/<skill-name>/` with a `SKILL.md` file at its root.
- SKILL.md frontmatter (YAML) must include:
  - `name` — the skill identifier
  - `description` — must start with "This skill should be used when"
  - `version` — semantic version string
- Each skill directory contains a `references/` subdirectory for reference material.
- Optional subdirectories: `examples/` for worked examples, `scripts/` for automation.

### Agents
- Agent definitions live in `agents/<agent-name>.md`.
- Frontmatter must include: `name`, `description` (with example blocks), `model`, `color`, `tools`.

### Commands
- Command definitions live in `commands/<command-name>.md`.
- Frontmatter must include: `description`.
- Optional frontmatter: `argument-hint`.

### Code Standards
- All code examples use TypeScript.
- All examples use Phaser 4 APIs only — never reference v3 removed APIs.
- Reference files go in the `references/` subdirectory within each skill.
- Shell scripts must be bash, use `set -euo pipefail`, and use colored output helpers.

## Development Discipline (CRITICAL)

### TypeScript Gate
Always run `npx tsc --noEmit` after code changes. Never push code with TypeScript compilation errors.

### 2-Attempt Pivot Rule
When fixing game mechanics (enemy AI, physics, collisions), propose the approach first and get approval before implementing. If an approach fails twice, STOP and propose 2-3 completely different alternative approaches rather than iterating on the same broken approach.

### Investigation-First
Before writing any fix code, read the relevant source files, check Phaser docs/patterns, and explain:
1. What is causing the bug
2. Why it is happening
3. Your proposed fix approach

Wait for approval before implementing.

### Parallel Agent Discipline
When using parallel agents for multi-phase implementation, define shared types/interfaces file BEFORE spawning agents. Verify all agents use consistent property names, imports, and type interfaces before merging work. Run a full build check after integration.

### Clean Commits
Only include files that were actually changed for the current task. Do not mix unrelated changes into commits.

### Test-Driven Complex Fixes
For complex game mechanics (AI, physics, collisions), write a failing test first, then iterate against the test autonomously.

## Prompting Discipline

These patterns consistently produce first-try-correct Claude output on Phaser 4 work. Apply them by default. They matter more than prompt length.

- **Paste exact error text verbatim** — console errors and stack traces as the browser shows them. The exact string usually points at the API surface that changed.
- **Include full stack traces** even on minified builds. Function names still resolve; line numbers may be opaque but the call chain is enough to pinpoint a null-guard or mis-ordered lifecycle hook.
- **Batch related symptoms into one prompt.** When multiple playtest reports might share a root cause, list them together. Single symptoms invite patch-one-site fixes; grouped symptoms surface the common cause.
- **Describe root cause, not symptom.** "The enemy AI's stuck-detection uses `body.velocity` which returns zero when pushing against a wall" produces a different search than "enemies sometimes get stuck." If you don't know the root cause, say so explicitly and ask for diagnosis — do not guess.
- **Device posture for mobile bugs** — browser and version, iOS vs Android, Safari tab vs PWA vs Capacitor, orientation, touch vs mouse. Most "mobile bugs" are specific-platform bugs indistinguishable without this.
- **Name acceptance criteria concretely.** For animation work: list the specific states (`idle`, `walk`, `attack`, `death`, `dodge`). For balance work: list the numbers (`HP 2500 → 1400`). Mood words ("make it feel better") produce cosmetic tweaks, not mechanics.
- **State visual contracts explicitly** — "50% background color, 50% foreground, readable on all backgrounds" rather than "make the asset visible." Without an explicit contract, Claude will pick one that looks good in one context.
- **Paste observed values for platform bugs** — exact `env(safe-area-inset-*)` values for iOS PWA layout bugs, exact `game.loop.actualFps` reading for performance bugs, exact heap-size deltas for leak bugs. Numbers anchor diagnosis; adjectives don't.
- **Reproduction step for AI / physics bugs** — the minimal game-state setup that triggers the issue. Claude cannot play the game; a concrete step is the closest thing to a test.
- **Phased roadmap before opening chat on non-trivial work** — writing the planned phases (interfaces first, data shapes second, build order third) into the prompt cuts iteration significantly. Discovering constraints mid-session produces tangled code.
- **"Ask clarifying questions before proceeding if anything is unclear"** at the top of ambiguous prompts signals that clarification is preferred over guessing. Without it, Claude often produces a confident wrong answer.
- **After substantial changes, run `npx tsc --noEmit` before handing back.** Treat TypeScript compilation as a pre-flight check, not an afterthought.

## Validation

Run the plugin structure validator:

```bash
bash scripts/validate-plugin.sh
```

This checks all agents, commands, skills, and hooks for structural correctness.

## Key Phaser 4 Facts

- **Install:** `npm install phaser@beta`
- **Version:** v4.0.0-rc.7
- **Renderer:** Phaser Beam (WebGL)
- **Types:** Configure `typeRoots` + `types: ["Phaser"]` in tsconfig.json

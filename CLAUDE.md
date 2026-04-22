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

## Development Discipline (CRITICAL -- from 32 sessions of real friction)

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

## Prompting Discipline (from 32 sessions of real friction)

These are patterns that consistently produced sharp, landing-on-first-try Claude output in the shipping roguelike. When a prompt conforms to these, the result is targeted; when it doesn't, the result is generic advice that may miss the real problem. Apply these by default — they matter more than prompt length.

- **Paste exact error text** — console warnings and stack traces verbatim, not paraphrased. The error string itself points at the API surface that changed.
- **Include full stack traces even on minified builds** — function names still resolve even when line numbers are opaque. A stack trace to a minified builder file plus the source of the calling function is enough for Claude to pinpoint the null-guard that's needed.
- **Batch playtester feedback into ONE prompt** — root causes surface when all symptoms are listed together. In the reference project, an off-axis world-wrap calculation was only visible when "enemies disappear going west" AND "enemies disappear going south" were named in the same prompt. Reported individually, Claude patched the wrong axis.
- **Describe root cause, not symptom** — "race condition between kill-chain multiplier and movement speed stat when both trigger on the same frame" produces a different search than "speed feels wrong."
- **Device posture for mobile bugs** — "holding the phone vertically in PWA mode" is enough context to anchor iOS-specific root causes. A "mobile bug" without posture is a grab-bag.
- **Name specific states in animation acceptance criteria** — `idle | walk | attack | death | dodge`, not "make it feel better." Concrete state lists produce state-machine code; mood words produce cosmetic tweaks.
- **Stat deltas as concrete numbers** — "HP 2500 → 1400, cooldown 1600 → 2400 ms" not "make it weaker." Numbers produce configs; adjectives produce guesses.
- **State visual contracts explicitly** — "50% ground color, 50% grass, visible on all biomes" not "make the ramp readable." If you do not specify the contract, Claude will pick ONE that looks good in the first biome.
- **"ASK ME QUESTIONS IF ANYTHING IS UNCLEAR" at the top of ambiguous prompts** — signals that clarification is preferred over guessing. Claude will ask exactly the question that would have saved an iteration round-trip.
- **Paste observed CSS values for iOS PWA bugs** — "`env(safe-area-inset-top)` returns 0 in landscape PWA" points directly at the failure mode. "iOS layout is broken" points at nothing.
- **Reproduction step for AI / physics bugs** — "stand at the base of the north cliff and let enemies chase you." Claude cannot play the game; a concrete step is the closest thing to a test.
- **Phased roadmap BEFORE opening the chat** — writing an explicit 3- or 4-phase plan into the prompt (interfaces first, data shapes second, build order third) cuts iteration in half. Discovering constraints mid-session produces tangled code.

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

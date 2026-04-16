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

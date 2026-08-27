# CLAUDE.md — phaser4-gamedev Plugin

## Repo Structure

```
agents/          — 5 specialized subagent definitions (Markdown with YAML frontmatter)
                   phaser-architect, phaser-coder, phaser-debugger,
                   phaser-asset-advisor, phaser-playtester
commands/        — Slash command definitions (7 commands)
                   phaser-new, phaser-run, phaser-playtest, phaser-validate,
                   phaser-build, phaser-gdd, phaser-analyze
skills/          — Each skill has SKILL.md + references/ + optional examples/ and scripts/
                   21 skills: 16 lifecycle/system skills (phaser-init, phaser-scene,
                   phaser-gameobj, phaser-physics, phaser-audio, phaser-animation,
                   phaser-input, phaser-tilemap, phaser-ui, phaser-build, phaser-migrate,
                   phaser-matter, phaser-saveload, phaser-mobile, phaser-gdd,
                   phaser-analyze), phaser-playtest (runtime verification), and 4
                   portable mirrors of the subagents (phaser-architect, phaser-coder,
                   phaser-debugger, phaser-asset-advisor)
hooks/           — SessionStart detector + PreToolUse v3 API guard
                   hooks.json defines hook configuration; scripts/ contains detect-phaser.sh
.claude-plugin/  — plugin.json + marketplace.json
                   Plugin metadata, versioning, and marketplace listing
.codex-plugin/   — plugin.json for Codex / skills.sh discovery
scripts/         — Validation and utility scripts
```

## The Workflow This Plugin Encodes

```
/phaser-gdd ──► /phaser-new ──► phaser-coder ──► /phaser-playtest ──► /phaser-build
   plan            scaffold        implement        VERIFY RUNNING        ship
     │                                 ▲                  │
     │                                 └──── fix ─────────┘
     └── acceptance criteria ─────────────────► playtest scenarios
```

The gate that matters is `/phaser-playtest`. Every other step can succeed on a game
that shows a black screen; this is the only one that cannot.

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

### Runtime Gate (CRITICAL — a passing compile is not a working game)
`tsc` proves the code compiles. It says nothing about whether the game runs. Asset path
typos, a scene missing from `scene: []`, a throw partway through `create()`, objects
placed off-camera — every one of these type-checks cleanly and ships a black screen.

After any change touching scene lifecycle, asset loading, physics, or rendering, run:

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" --project .
```

Rules:
- **Never report a feature complete without having run the game.** If you did not run
  it, say so explicitly rather than implying it works.
- A green `tsc` plus a failing playtest means the work is **not** done.
- Every scaffolded project gets `if (import.meta.env.DEV) (window as any).__PHASER_GAME__ = game;`
  next to `new Phaser.Game(config)`. Dev-only, one line, and it unlocks every state assertion.
  It requires `"types": ["vite/client"]` in tsconfig — without it the line fails `tsc --noEmit`.
- Before any deploy, run `--mode build`. That is where base-path and bundling failures appear.
- Headless FPS is software-rendered: treat it as a regression signal between runs, not
  a real-device measurement.

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

For mechanics that only manifest at runtime, the failing test is a **playtest scenario**
(`skills/phaser-playtest/`) rather than a unit test: drive the input that triggers the
bug, assert on the state that should result, watch it fail, then fix. Extract pure logic
into plain modules and unit-test that with Vitest where the logic is separable — see
`skills/phaser-build/references/testing-patterns.md`.

### Acceptance Criteria Are the Contract
GDD Section 13 and the architect's per-phase exit conditions must be observable and
numeric ("enemy dies in 3 hits", not "combat feels good"). Each automatable criterion
becomes a playtest assertion. Criteria that genuinely need a human — difficulty feel,
art readability, audio mix — must be labelled as such rather than given a fake metric.

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

It discovers agents, commands, and skills from disk (no hardcoded lists to drift) and
checks: JSON manifests parse; **the version matches across all manifests and all 21
skills**; agent and skill frontmatter is complete and `name` matches the directory;
every agent that mentions Context7 actually grants the MCP tools in its `tools`
allowlist; portable skill mirrors match their agent definitions; shell and JS scripts
parse; every `${CLAUDE_PLUGIN_ROOT}` and cross-skill file reference resolves; and the
SessionStart hook runs against a fixture.

Verify a Phaser project builds and runs:

```bash
bash skills/phaser-build/scripts/validate-project.sh /path/to/game   # structure
node skills/phaser-playtest/scripts/playtest.mjs --project /path/to/game   # runtime
```

## Key Phaser 4 Facts

- **Install:** `npm install phaser`
- **Version:** v4.2.1
- **Renderer:** Phaser Beam (WebGL)
- **Types:** Shipped via Phaser's `exports` map. Use `moduleResolution: "bundler"` + `import Phaser from 'phaser'`. Never set `typeRoots`/`types: ["Phaser"]` — that v3 recipe fails on v4 with `TS2688`.

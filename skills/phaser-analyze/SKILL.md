---
name: phaser-analyze
description: This skill should be used when the user asks to "analyze my game", "review my Phaser project", "audit project health", "find bottlenecks", "refactor my game", "improve my code", "optimize my project", "what's wrong with my game", "code review Phaser", or "assess architecture".
version: 0.4.0
---

# Phaser 4 Brownfield Project Analysis

Perform a comprehensive analysis of an existing Phaser 4 project to assess architecture quality, identify performance risks, flag API correctness issues, and produce a prioritized improvement roadmap.

## Analysis Process

Follow all five phases in order. Do not skip phases — each builds on the previous.

### Phase 1 — Discovery

Gather raw facts about the project before making any judgments.

- Read `package.json` for dependencies and Phaser version
- Glob for all `.ts`/`.js` files in `src/`
- Read `main.ts` for `GameConfig`
- Identify all scenes: `grep "extends Phaser.Scene"` across `src/`
- Map scene graph: `grep` for `this.scene.start`, `this.scene.launch`, `this.scene.stop`
- Identify all custom game objects: `grep "extends Phaser.Physics"` or `grep "extends Phaser.GameObjects"`
- Count total source files and lines of code

### Phase 2 — Architecture Assessment

Evaluate the structural quality of the codebase.

- **Scene count and organization** — Are scenes in `src/scenes/`? Are there too many or too few for the game's complexity?
- **State management pattern** — Registry vs globals vs module state. Search for `window.`, module-level `let`/`var` declarations.
- **Asset loading strategy** — Centralized `PreloaderScene` vs scattered `preload()` methods across scenes.
- **Code organization** — Does the project follow `scenes/`, `objects/`, `managers/` conventions?
- **Cross-scene coupling analysis** — Direct references vs event bus vs Registry. Search for `this.registry`, `this.events.emit`, `this.scene.get`.

Rate the architecture **A through F** based on findings:
- **A** — Clean separation, centralized loading, event-driven communication
- **B** — Minor organizational gaps, mostly well-structured
- **C** — Some coupling issues, mixed patterns, functional but messy
- **D** — Significant structural problems, globals, scattered loading
- **F** — No discernible architecture, everything in one file or deeply entangled

### Phase 3 — Performance Audit

Identify runtime performance risks.

- **Object pooling:** Search for `classType`/`maxSize` in group declarations. Flag physics groups created with `this.physics.add.group()` that lack `maxSize` — these leak objects.
- **Particle emitter caps:** Search for particle emitters missing `maxParticles`. Uncapped emitters can spike frame time.
- **Static vs dynamic groups:** Check if platforms, walls, and other immovable bodies use `staticGroup()` (correct) vs `group()` (wastes physics cycles).
- **Update loop weight:** Read each scene's `update()` method. Flag complex logic, object allocations (`new`), or heavy iteration inside `update()`.
- **Texture atlas usage:** Count individual `this.load.image()` calls vs `this.load.atlas()` calls. More than 15 individual image loads is a red flag — should be packed into atlases.
- **Physics body count:** Estimate total active physics bodies from group declarations and individual `this.physics.add.*` calls.

### Phase 4 — API Correctness

Check for deprecated, removed, or misused APIs.

- **v3 API scan:** Search for removed APIs — `Geom.Point`, `Math.PI2`, `Phaser.Structs`, `Camera3D`, `Layer3D`, `FacebookInstant`, `Create.GenerateTexture`, `TileSprite.setCrop`.
- **TypeScript strictness:** Grep for `as any`, `@ts-ignore`, untyped function parameters. These hide real bugs.
- **Asset key consistency:** Cross-reference `this.load.*` keys with `this.add.*`/`this.physics.add.*` keys. Mismatched keys cause silent texture-missing errors.
- **Scene key registration:** Verify all scene classes appear in the `GameConfig` scene array in `main.ts`.
- **Physics body creation:** Flag `this.add.sprite()` calls that should be `this.physics.add.sprite()` (sprites expected to have physics but created without a body).
- **DynamicTexture/RenderTexture:** Check for missing `.render()` calls after drawing operations.

### Phase 5 — Best Practice Check

Verify the project follows Phaser 4 best practices.

- **Lifecycle discipline:** `preload()` should only load assets, `create()` should only build the scene, `update()` should be lean (no asset loading, no object creation).
- **Cleanup on shutdown:** Scenes should clean up — look for `this.events.off`, `this.sound.stopAll()`, timer destruction, `this.events.on('shutdown', ...)`.
- **Camera bounds:** Camera bounds should match world or tilemap bounds. Search for `this.cameras.main.setBounds` and compare with world/map dimensions.
- **Input keyboard null assertions:** `this.input.keyboard` can be null in Phaser 4. Check for `this.input.keyboard!` or proper null guards.
- **Physics debug flag:** `debug: true` in physics config should be `false` for production. Flag if present.
- **Console statements:** Count `console.log`/`console.warn`/`console.error` calls. These should be gated behind `import.meta.env.DEV` or removed for production.

## Output Format

Produce a structured report with these sections:

1. **Project Summary** — File count, scene count, lines of code, estimated complexity (small/medium/large).
2. **Architecture Score** — Letter grade (A/B/C/D/F) with rationale for the rating.
3. **Performance Risks** — Ordered by severity (critical/high/medium/low) with a concrete fix suggestion for each.
4. **Code Quality Issues** — With `file:line` references where possible.
5. **Improvement Roadmap** — Prioritized refactoring steps, ordered by impact vs effort.
6. **Quick Wins** — 3-5 changes that can be made immediately for noticeable improvement.

## Related Skills

- Use `/phaser-migrate` to fix any Phaser v3 API issues found in Phase 4.
- Use `/phaser-physics` for implementing object pooling and fixing physics group issues from Phase 3.
- Use the phaser-debugger agent for investigating runtime performance issues flagged in Phase 3.

## Reference Files

- **`references/analysis-checklist.md`** — Complete checklist with grep patterns, severity ratings, and fix references for all checks.
- **`references/performance-playbook.md`** — Nine-phase performance playbook from a shipped roguelike: measurement-first prompting, per-frame allocations, registry throttling, audio lazy-load, VFX pooling, spatial grid, atlas packing, event throttling, AI tick-skip with real delta, tween cleanup. Read when FPS is below target or memory grows during gameplay.

## Automated Pre-scan

Before starting the manual deep review, run the automated analysis script:

```bash
bash "${CLAUDE_PLUGIN_ROOT}/skills/phaser-analyze/scripts/analyze-project.sh"
```

This provides baseline metrics and flags obvious issues. Use the script output as a starting point, then perform the full 5-phase analysis by reading actual source files.

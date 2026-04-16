# Phaser 4 Analysis Checklist

Complete reference table for all automated and manual checks performed during project analysis. Each row includes the grep/glob pattern to run, what the result means, severity, and how to fix it.

## Phase 2 — Architecture Assessment

| Check Name | Pattern | What It Means | Severity | Fix Reference |
|---|---|---|---|---|
| Module Global State | `grep -rn "^let \|^var " src/` | Mutable module-level globals bypass scene lifecycle and persist across scene restarts | HIGH | Use `this.registry`, `this.data`, or scene-scoped variables instead |
| Window Globals | `grep -rn "window\." src/` | Attaching state to `window` creates hidden coupling and prevents garbage collection | HIGH | Move to `this.registry.set()` / `this.registry.get()` or a dedicated state manager |
| Scattered Preload | `grep -rln "preload()" src/ \| grep -v -i preloader` | Multiple scenes loading their own assets causes redundant network requests and race conditions | MEDIUM | Centralize all asset loading in a single `PreloaderScene` |
| Missing Scene Directory | `find src/ -name "*Scene*" -not -path "src/scenes/*"` | Scene files outside `src/scenes/` breaks standard project conventions | LOW | Move all scene files to `src/scenes/` |
| Cross-Scene Direct Access | `grep -rn "this.scene.get(" src/` | Directly accessing another scene's internals creates tight coupling | MEDIUM | Use `this.events.emit()` / `this.events.on()` or `this.registry` for cross-scene communication |
| Single File Game | `find src/ -name "*.ts" -o -name "*.js" \| wc -l` (result = 1) | Entire game in one file — unmaintainable beyond prototypes | HIGH | Split into separate scene files, extract game objects to `src/objects/`, managers to `src/managers/` |
| No Manager Layer | `ls src/managers/ 2>/dev/null \| wc -l` (result = 0) | No dedicated manager classes for audio, score, input, etc. | LOW | Extract cross-cutting concerns into manager classes in `src/managers/` |

## Phase 3 — Performance Audit

| Check Name | Pattern | What It Means | Severity | Fix Reference |
|---|---|---|---|---|
| Missing Object Pool | `grep -rn "this.physics.add.group" src/ \| grep -v maxSize` | Physics groups without `maxSize` leak objects — destroyed bodies are never reused | MEDIUM | Add `maxSize` and `classType` to all physics groups — see `/phaser-physics` |
| Uncapped Particle Emitter | `grep -rn "addEmitter\|createEmitter\|add.particles" src/ \| grep -v maxParticles` | Particle emitters without `maxParticles` can spawn unlimited particles, spiking frame time | MEDIUM | Add `maxParticles` to all emitter configs |
| Dynamic Group for Static Bodies | `grep -rn "this.physics.add.group" src/ \| grep -iE "platform\|wall\|ground\|floor\|boundary"` | Platforms/walls using dynamic groups waste physics cycles on immovable bodies | HIGH | Replace `this.physics.add.group()` with `this.physics.add.staticGroup()` for non-moving bodies |
| Allocations in Update | `grep -A 20 "update(" src/**/*.ts \| grep "new "` | Creating objects inside `update()` causes garbage collection spikes every frame | HIGH | Pre-allocate in `create()` and reuse; use object pools for bullets/particles |
| Too Many Individual Images | `grep -c "this.load.image(" src/**/*.ts` (result > 15) | Many individual image loads means many HTTP requests and texture swaps | MEDIUM | Pack sprites into texture atlases using TexturePacker or free-tex-packer, use `this.load.atlas()` |
| Missing Static Group | `grep -rn "this.physics.add.group" src/ \| grep -v static` cross-reference with `setImmovable(true)` | Groups that are manually set immovable should be `staticGroup` instead | MEDIUM | Use `this.physics.add.staticGroup()` — it is both faster and semantically correct |
| Heavy Update Loop | Manual: read each `update()` method, check for nested loops, array searches, string operations | Complex `update()` logic runs 60 times/second and dominates frame budget | HIGH | Move heavy computation to events, timers, or `time.addEvent()` intervals |
| Estimated Physics Bodies | `grep -c "this.physics.add\.\|physics.add.group\|physics.add.staticGroup" src/**/*.ts` | High body count (>200) causes physics step slowdowns | MEDIUM | Reduce active bodies with pooling, spatial partitioning, or disabling off-screen bodies |

## Phase 4 — API Correctness

| Check Name | Pattern | What It Means | Severity | Fix Reference |
|---|---|---|---|---|
| Geom.Point (removed v4) | `grep -rn "Geom\.Point\|new Phaser\.Geom\.Point" src/` | `Phaser.Geom.Point` removed in v4 | HIGH | Replace with `Phaser.Math.Vector2` — see `/phaser-migrate` |
| Math.PI2 (removed v4) | `grep -rn "Math\.PI2" src/` | `Math.PI2` removed in v4 | HIGH | Replace with `Math.TAU` — see `/phaser-migrate` |
| Phaser.Structs (removed v4) | `grep -rn "Phaser\.Structs" src/` | `Phaser.Structs` namespace removed in v4 | HIGH | Use native `Map` and `Set` — see `/phaser-migrate` |
| Camera3D / Layer3D | `grep -rn "Camera3D\|Layer3D" src/` | 3D plugins removed in v4 | HIGH | Remove — use a 3D engine if needed, or fake depth with sorting |
| FacebookInstant | `grep -rn "FacebookInstant" src/` | Facebook Instant Games plugin removed in v4 | HIGH | Remove — use the Facebook SDK directly if needed |
| GenerateTexture (removed v4) | `grep -rn "Create\.GenerateTexture\|Phaser\.Create" src/` | `Phaser.Create.GenerateTexture` removed in v4 | MEDIUM | Use `Graphics.generateTexture()` instead — see `/phaser-migrate` |
| TileSprite.setCrop | `grep -rn "\.setCrop(" src/` | `TileSprite.setCrop()` removed in v4 | MEDIUM | Use `setFrame()` or adjust `tilePositionX/Y` instead |
| TypeScript `as any` | `grep -rn "as any" src/` | Type escape hatch hides real type errors | MEDIUM | Add proper types; use `as unknown as TargetType` only as last resort |
| TypeScript `@ts-ignore` | `grep -rn "@ts-ignore\|@ts-expect-error" src/` | Suppressed type errors may hide real bugs | MEDIUM | Fix the underlying type issue; if unavoidable, use `@ts-expect-error` with explanation |
| Unregistered Scene | Compare `grep -rn "extends Phaser.Scene" src/` with scene array in `main.ts` | Scene class exists but is not in `GameConfig.scene` — it will never load | HIGH | Add the scene class to the `scene` array in `GameConfig` |
| Missing Physics Body | `grep -rn "this.add.sprite\|this.add.image" src/` near collider/overlap calls | Sprites created without physics that are used in colliders silently fail | HIGH | Use `this.physics.add.sprite()` for anything that needs collisions |
| DynamicTexture Missing render() | `grep -rn "addDynamicTexture\|addRenderTexture" src/` then check for `.render()` | DynamicTexture drawing is not visible until `.render()` is called | MEDIUM | Call `.render()` after all draw operations complete |

## Phase 5 — Best Practice Check

| Check Name | Pattern | What It Means | Severity | Fix Reference |
|---|---|---|---|---|
| Loading in create() | `grep -A 30 "create(" src/**/*.ts \| grep "this.load\."` | Asset loading in `create()` instead of `preload()` causes race conditions | HIGH | Move all `this.load.*` calls to `preload()` or a dedicated PreloaderScene |
| Object Creation in update() | `grep -A 30 "update(" src/**/*.ts \| grep "this.add\.\|this.physics.add\."` | Creating game objects in `update()` leaks objects every frame | HIGH | Pre-create in `create()` and reuse; use object pools for dynamic spawning |
| Missing Shutdown Cleanup | `grep -rL "shutdown\|events.off\|events.once.*shutdown" src/scenes/` | Scenes without shutdown handlers leak event listeners and timers on restart | MEDIUM | Add `this.events.on('shutdown', this.cleanup, this)` to each scene |
| Missing Event Cleanup | `grep -rn "this.events.on\|this.input.on" src/ \| grep -v ".off\|.once"` | Event listeners registered with `.on()` but never removed with `.off()` | MEDIUM | Use `.once()` for one-shot events, or pair every `.on()` with `.off()` in shutdown |
| Camera Bounds Mismatch | `grep -rn "setBounds\|cameras.main" src/` | Camera bounds not set or mismatched with world bounds causes rendering issues | LOW | Set `this.cameras.main.setBounds(0, 0, map.widthInPixels, map.heightInPixels)` |
| Keyboard Null Check | `grep -rn "this.input.keyboard[^!?]" src/` | `this.input.keyboard` can be null in Phaser 4 if keyboard input is disabled | MEDIUM | Use `this.input.keyboard!` with assertion or guard with `if (this.input.keyboard)` |
| Physics Debug Enabled | `grep -rn "debug:\s*true" src/ \| grep -iE "arcade\|matter\|physics"` | Physics debug rendering left on tanks FPS in production | LOW | Set `debug: false` or gate behind `import.meta.env.DEV` |
| Console Statements | `grep -rn "console\.\(log\|warn\|error\)" src/` | Unguarded console output clutters production builds | LOW | Remove or gate behind `if (import.meta.env.DEV)` |
| Hardcoded Dimensions | `grep -rn "width: [0-9]\|height: [0-9]" src/ \| grep -v config\|Config` | Hardcoded pixel dimensions break on different screen sizes | LOW | Use `this.scale.width` / `this.scale.height` or relative positioning |

## Scoring Guide

Calculate the architecture score based on Phase 2-5 findings:

| Grade | Criteria |
|---|---|
| **A** | 0 HIGH issues, <= 2 MEDIUM issues, clean separation, centralized loading, event-driven |
| **B** | 0 HIGH issues, <= 5 MEDIUM issues, mostly well-structured with minor gaps |
| **C** | 1-2 HIGH issues, functional but disorganized, mixed patterns |
| **D** | 3+ HIGH issues, significant structural problems, globals, scattered loading |
| **F** | No architecture, single-file game, pervasive anti-patterns |

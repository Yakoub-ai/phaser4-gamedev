---
name: phaser-gdd
description: This skill should be used when the user asks to "write a game design document", "create a GDD", "design my game", "document game mechanics", "plan game progression", "define core loop", "art direction", "audio design plan", "monetization strategy", "game concept document", "plan my game before coding", or wants to produce a structured design document for a Phaser 4 game before writing any code.
version: 0.4.0
---

# Phaser 4 Game Design Document Generator

Generate a comprehensive Game Design Document (GDD) for a Phaser 4 game. The GDD captures every design decision — mechanics, art, audio, progression, technical constraints — in a single Markdown file so the entire team (or solo dev) has a shared reference before any code is written.

## GDD Structure (12 Sections)

Every generated GDD must include all 12 sections below. If the user has not specified details for a section, provide sensible defaults based on the genre and scope, and mark assumptions with `<!-- ASSUMPTION -->` so they are easy to find and revise.

---

### Section 1 — Game Overview

Establish the identity of the game at a glance.

Include:
- **Title** — Working title (can be placeholder).
- **Tagline** — One punchy sentence that sells the hook.
- **Genre** — Primary genre and any sub-genres (e.g., "roguelike platformer").
- **Target Audience** — Age range, player profile, casual vs. hardcore.
- **Elevator Pitch** — Exactly 2 sentences: what the player does and why it is fun.
- **Unique Selling Points (USPs)** — 3-5 bullet points that differentiate the game.
- **Comparable Titles** — 2-3 existing games the user or audience would recognize, with a brief note on what is borrowed and what is different.

---

### Section 2 — Core Game Loop

Define the repeatable cycle that keeps the player engaged.

Include:
- **30-Second Loop** — The smallest atomic action cycle (e.g., jump-land-collect).
- **5-Minute Loop** — A medium arc such as completing a level or a wave.
- **Session Loop** — What a full play session looks like (15-30 min for casual, 60+ for hardcore).

Present each loop as an **ASCII flow diagram**:

```
[Action] --> [Feedback] --> [Reward] --> [Decision] --+
   ^                                                  |
   +--------------------------------------------------+
```

- **Win Condition** — What the player must achieve to "beat" the game or level.
- **Lose Condition** — What causes failure and what happens next (restart level, lose life, game over).

---

### Section 3 — Mechanics Deep Dive

Detail every interactive system the player touches.

Include:
- **Primary Mechanics** — The 1-3 core verbs (e.g., jump, shoot, match). For each: input, physics behavior, edge cases.
- **Secondary Mechanics** — Supporting systems (e.g., inventory, crafting, dialogue). Describe how they feed back into the core loop.
- **Control Scheme** — Map inputs per platform:

| Action | Keyboard | Touch | Gamepad |
|--------|----------|-------|---------|
| Move   | WASD / Arrows | Virtual joystick | Left stick |
| Jump   | Space    | Tap right side | A button |

---

### Section 4 — Progression System

Describe how difficulty, content, and rewards evolve over time.

Include:
- **Difficulty Curve** — Describe the intended ramp (linear, exponential, sawtooth). Reference specific milestones.
- **Unlock Sequence** — What new abilities, levels, or items the player earns and when.
- **Scoring System** — How score is calculated, combo multipliers, leaderboards if any.
- **Replayability Hooks** — What brings the player back (new game+, daily challenges, procedural generation).
- **Estimated Play Time** — Time to first completion and time to 100% completion.

---

### Section 5 — Level / World Design

Plan the spatial structure of the game.

Include:
- **Level Count** — Total number of levels, worlds, or zones.
- **Themes** — Visual and mechanical theme per world (e.g., "World 2 — Ice Caves: slippery surfaces, breakable walls").
- **Flow Maps** — ASCII diagram showing level progression and branching:

```
[Level 1] --> [Level 2] --> [Level 3]
                  |
                  +--> [Bonus Level A]
```

- **Difficulty Scaling** — How enemy count, speed, puzzle complexity, or time pressure increases per level.

---

### Section 6 — Characters & Entities

Catalog every game object with gameplay-relevant detail.

Include:
- **Player Character** — Base stats (speed, health, jump height), abilities, state machine (idle, run, jump, hurt, dead).
- **Enemy Types** — Table format:

| Enemy | HP | Speed | Behavior | Attack | Drop |
|-------|----|-------|----------|--------|------|
| Slime | 1  | 40px/s | Patrol left-right | Contact damage | Coin (50%) |

- **NPCs** — Role, dialogue triggers, quest associations.
- **Collectibles & Power-ups** — Effect, duration, rarity, visual indicator.

---

### Section 7 — UI/UX Wireframes

Define every screen the player sees.

Include:
- **HUD Layout** — ASCII wireframe of the in-game overlay:

```
+---------------------------------------+
| [Lives: x3]          [Score: 00000]   |
|                                       |
|                                       |
|              GAME AREA                |
|                                       |
|                                       |
| [Item1] [Item2] [Item3]    [Pause]   |
+---------------------------------------+
```

- **Menu Flow Diagram** — ASCII showing navigation between screens:

```
[Title Screen] --> [Main Menu] --> [Play] --> [Level Select] --> [Game]
                       |                                           |
                       +--> [Settings]                     [Pause Menu]
                       +--> [Credits]                          |
                                                         [Game Over] --> [Main Menu]
```

- **Screen Mockups** — Brief description of each unique screen (title, main menu, settings, game over, win).
- **Accessibility Considerations** — Color-blind modes, font size options, remappable controls, screen reader hints.

---

### Section 8 — Art Direction

Establish the visual identity and asset pipeline.

Include:
- **Visual Style** — Describe in 1-2 sentences (e.g., "16-bit pixel art with modern lighting effects").
- **Color Palette** — 5-8 hex codes with role labels:

| Role       | Hex     | Usage                  |
|------------|---------|------------------------|
| Primary    | #3A86FF | Player, UI highlights  |
| Secondary  | #FF006E | Enemies, danger        |
| Background | #1B1B2F | Sky, menus             |

- **Resolution & Scaling** — Game resolution (e.g., 800x600), scale mode (Phaser `FIT`, `RESIZE`, etc.), pixel-perfect flag.
- **Animation Guidelines** — Frame counts, FPS per animation type (idle: 4 frames @ 8fps, run: 6 frames @ 12fps).
- **Asset List with Specs** — Table of every required asset:

| Asset | Type | Size | Frames | Format |
|-------|------|------|--------|--------|
| player_idle | Spritesheet | 32x32 | 4 | PNG |
| background_forest | Static | 800x600 | 1 | PNG |

---

### Section 9 — Audio Design Plan

Define the soundscape.

Include:
- **Music Mood per Scene** — Table mapping each scene/level to a musical mood and tempo:

| Scene | Mood | Tempo | Loop? |
|-------|------|-------|-------|
| Main Menu | Mysterious, inviting | 90 BPM | Yes |
| Level 1 | Upbeat, adventurous | 120 BPM | Yes |
| Boss Fight | Intense, urgent | 150 BPM | Yes |
| Game Over | Somber, reflective | 70 BPM | No |

- **SFX List** — Action-to-sound mapping:

| Action | Sound Description | Priority |
|--------|-------------------|----------|
| Player jump | Short airy whoosh | High |
| Coin collect | Bright chime ascending | High |
| Enemy hit | Soft thud + squish | Medium |

- **Format Requirements** — All audio must be provided in both **MP3** and **OGG** for cross-browser compatibility. Phaser will select the best format at runtime.
- **Volume Hierarchy** — Define relative volume levels: Music (0.4), SFX (0.7), UI sounds (0.5). Describe how they interact (SFX duck music briefly on major events).

---

### Section 10 — Technical Requirements

Pin down the Phaser-specific technical decisions.

Include:
- **Phaser Version** — `phaser@beta` (v4.0.0-rc.7) unless the user specifies otherwise.
- **Physics Engine** — Choose one and justify:
  - **Arcade** — Simple AABB, best for platformers and shooters. Low CPU cost.
  - **Matter.js** — Full rigid-body physics. Use for games needing rotation, joints, or complex collision shapes.
  - **None** — For puzzle or card games with no physics simulation.
- **Performance Budgets** — Target frame rate (60 FPS), max draw calls per frame, max simultaneous particles, texture atlas size limits.
- **Browser/Device Targets** — Minimum browser versions, mobile device tier (e.g., "must run at 30+ FPS on 2020-era mid-range Android").

---

### Section 11 — Platform Targets & Device Profiles

Specify where the game will run and how input differs.

Include:
- **Primary Platforms** — Desktop browser, mobile browser, PWA, Electron, Capacitor/Cordova.
- **Input per Platform**:

| Platform | Primary Input | Secondary Input |
|----------|--------------|-----------------|
| Desktop  | Keyboard + Mouse | Gamepad |
| Mobile   | Touch | Gyroscope (optional) |
| Tablet   | Touch | Bluetooth gamepad |

- **Deployment Method** — How the game is built and distributed (static hosting, itch.io, app store via Capacitor, etc.).

---

### Section 12 — Monetization & Release Plan (Optional)

Include this section only if the user wants to discuss business aspects. Mark it optional in the output.

Include:
- **Business Model** — Free, premium, freemium, ad-supported, or donation-ware.
- **Milestones** — Key dates or phases:

| Milestone | Target Date | Deliverable |
|-----------|-------------|-------------|
| Prototype | Week 2 | Core loop playable |
| Alpha | Week 6 | All levels blocked out |
| Beta | Week 10 | Feature-complete, playtesting |
| Launch | Week 14 | Polished, deployed |

- **Distribution** — Where the game will be published (itch.io, GitHub Pages, Steam, app stores).

---

## Post-GDD Workflow

Once the GDD is finalized, guide the user to the next steps:

1. **Scaffold the project** — Use `/phaser-new` to generate the base project structure matching the GDD's technical requirements.
2. **Design the architecture** — Use the **phaser-architect** skill/agent to translate the GDD into a technical architecture: scene graph, class hierarchy, data flow, and system decomposition.
3. **Start implementing** — Use the **phaser-coder** skill/agent to begin coding scenes, mechanics, and entities as specified in the GDD.

Remind the user: the GDD is a living document. Update it as the game evolves during development.

---

## Output Format

The generated GDD must be a **single Markdown document** with:
- A top-level `# Game Design Document: [Title]` heading.
- Each of the 12 sections as `## Section N — Name` headings.
- **ASCII diagrams** for all flow charts, wireframes, and level maps (no external image dependencies).
- Tables for structured data (enemies, assets, audio, controls).
- `<!-- ASSUMPTION -->` comments next to any detail the generator inferred rather than received from the user.

Save the document to `docs/GDD.md` in the project root. If no project directory exists, print the full GDD inline in the chat.

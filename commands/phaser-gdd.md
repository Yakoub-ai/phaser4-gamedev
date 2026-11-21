---
description: Generate a comprehensive Game Design Document
argument-hint: [genre] — platformer, topdown, shooter, puzzle, towerdefense, runner, cardgame, fighting, racing, or custom
---

Create a comprehensive Game Design Document (GDD) for a Phaser 4 game. The optional argument specifies the game genre to tailor the document.

If an argument was provided ($ARGUMENTS), treat it as the desired game genre. If no argument was provided, ask the user what kind of game they want to design before proceeding.

## Process

1. **Determine genre** — from $ARGUMENTS or by asking the user. Named genres get tailored defaults: `platformer`, `topdown`, `shooter`, `puzzle`, `towerdefense`, `runner`, `cardgame`, `fighting`, `racing`. Anything else — a hybrid, a narrative game, a sim, an idle game, a physics toy — is `custom`: ask the user to describe it in their own words and design from that rather than forcing the nearest genre.

2. **Gather requirements** — Ask the user 3-5 focused questions to fill in the most impactful design decisions before generating. Tailor questions to the genre, but always cover:
   - **Target platform** — Desktop browser, mobile, or both?
   - **Visual style** — Pixel art, hand-drawn, minimalist, 3D-rendered sprites, etc.?
   - **Multiplayer** — Single-player only, local co-op, or online?
   - **Scope** — Small (1-2 week jam), medium (1-2 months), or large (3+ months)?
   - **Monetization** — Free, premium, ads, or undecided?

   Do NOT ask all five if the answers are obvious from context. Skip questions the user has already answered. Keep the conversation moving.

3. **Generate the GDD** — Use the **phaser-gdd** skill's 13-section structure to produce the full document. Fill every section with genre-appropriate content. Mark any assumptions with `<!-- ASSUMPTION -->` so the user can easily find and revise them.

4. **Save the document** — Write the GDD to `docs/GDD.md` in the project root. Create the `docs/` directory if it does not exist. If there is no project directory (e.g., the user is just exploring), print the full GDD inline in the chat instead.

5. **Suggest next steps** — After generating the GDD, recommend:
   - Review and revise any `<!-- ASSUMPTION -->` markers.
   - Run `/phaser-new custom` to scaffold a verified project configured from the GDD (or `/phaser-new <archetype>` if the game is a close fit for one).
   - The **phaser-architect** agent then writes `docs/ARCHITECTURE.md` — phases with observable exit conditions taken from Section 13.
   - Run `/phaser-dev` to build and verify one phase at a time.

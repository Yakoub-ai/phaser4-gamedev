# Scope Calibration

Hour estimates for the systems games actually contain, so a scope conversation can be
arithmetic instead of optimism.

**All figures assume a competent developer working with an AI assistant, and include the
debugging and playtesting each system needs — not just the time to write it.** They are
generous where people are typically wrong and stingy where people over-plan.

---

## Systems, by hours

### Core

| System | Hours | Notes |
|---|---|---|
| Project scaffold, config, build | 1–2 | `/phaser-new` collapses this |
| Player movement, feel-tuned | 8–20 | The range *is* the point: "works" is 8, "feels good" is 20 |
| Basic collision and physics | 4–8 | Arcade. Matter is 3–4× |
| Camera follow, bounds, deadzone | 2–4 | |
| One enemy type with simple AI | 4–8 | Per type, and the second is not much cheaper |
| Combat: damage, health, death | 6–12 | Effects and feedback are most of it |
| One level, hand-built | 2–6 | Per level, once tooling exists |
| Tilemap pipeline with Tiled | 6–12 | One-off; makes each level cheaper |

### Structure

| System | Hours | Notes |
|---|---|---|
| Menu, settings, credits | 6–12 | Routinely underestimated by half |
| Pause that actually works | 2–4 | Pausing physics, audio, timers, input |
| Scene transitions | 2–4 | |
| Save/load | 6–15 | 6 for a score, 15 for full state with versioning |
| HUD | 4–8 | |
| Inventory | 12–25 | UI is most of it, not the data |
| Dialogue system | 10–20 | More if branching |
| Tutorial or onboarding | 8–16 | Hard to do well, and the first thing every player meets |

### Content and polish

| System | Hours | Notes |
|---|---|---|
| Audio: SFX + music integration | 6–12 | Wiring, not sourcing |
| Particles and juice | 8–16 | Highest return per hour in the whole table |
| Balancing | 10–30 | Never finished, only stopped |
| Mobile: touch, responsive, testing | 12–30 | Real devices, real surprises |
| Accessibility: remap, colourblind, text size | 8–16 | Cheaper if planned, expensive if retrofitted |
| Release: store page, screenshots, build | 4–10 | See `skills/phaser-release/` |
| Bug-fixing across the project | 20–30% of total | Not a line item — a multiplier |

---

## Worked scopes

### Weekend jam — 16–20 hours

```
Scaffold                      1
One mechanic, tuned           8
One enemy                     3
Three levels or endless       3
Sound effects                 2
Menu + game over              2
                            ───
                             19
```

No save, no settings, no music, no tutorial. The mechanic gets the hours because it is
the only thing anyone will remember.

### Two weeks — 60–80 hours

```
Scaffold + architecture        3
Player, tuned                 15
Two enemy types                8
Combat + feedback             10
Eight levels                  12
Menu, pause, game over        10
Save (level progress)          6
Audio                          6
Juice                          8
Bugs                          15
                             ───
                             93
```

93 against a 70-hour budget. This is what the third-of-a-project overrun looks like in
practice, and the resolution is to cut to six levels and one enemy type — *before*
starting, not in the final week.

### Two months — 250–320 hours

```
Architecture + scaffold        8
Player, fully tuned           25
Four enemy types + boss       35
Combat, upgrades              30
Twenty levels                 40
Full menu suite               20
Save with versioning          15
Tilemap pipeline              12
Audio                         15
Particles, juice              16
Mobile support                25
Balancing                     25
Release                        8
Bugs (25%)                    69
                             ───
                            343
```

At 20 hours a week that is 17 weeks, not 8. The honest options are: halve the content
(20 levels → 10, 4 enemies → 2), drop mobile, or accept four months.

Showing this arithmetic is more persuasive than any amount of "that sounds ambitious",
because it names *which* lines are the problem.

---

## Multipliers people forget

| Factor | Multiplier |
|---|---|
| First game ever | ×2 |
| First time with this genre | ×1.5 |
| Multiplayer | ×2.5 on the whole project, not just netcode |
| Procedural generation | ×1.5 on level content, plus a debugging tail |
| Mobile as well as desktop | ×1.3 overall |
| Making your own art | +40–100% of total |
| Making your own music | +20–40% |
| Console or store release | +40–120 hours of certification and paperwork |

Multiplayer earns its number: every bug becomes two bugs (client and sync), you need
infrastructure, and playtesting requires two people. Unless multiplayer *is* the hook, it
is the first cut.

---

## The cut list, in order

When a project runs long, cut in this order. It is arranged so each cut costs the least
possible amount of what makes the game worth playing:

1. **Content volume** — 20 levels → 10. Almost free; nobody counts.
2. **Enemy and item variety** — 4 types → 2, made better.
3. **Secondary systems** — crafting, achievements, collectibles.
4. **Procedural generation** → hand-built. Faster *and* better at small scale.
5. **Story and cutscenes** → a paragraph on the title screen.
6. **Platforms** — desktop only; mobile later or never.
7. **Multiplayer** — should have gone first.
8. **Polish** — cut last, and reluctantly. Juice is what makes the rest feel finished.

**Never cut:** the hook, working save/load (if progress exists), an ending, or the
tutorial. A game that loses progress or has no ending reads as broken regardless of how
good the rest is.

---

## Signals a project is going to be abandoned

Worth naming early, because they are all recoverable at week three and none at month
four:

- **The core mechanic still is not fun after prototyping.** No amount of content fixes
  this. Change the mechanic or change projects.
- **The scope grew after work started.** Features added mid-project are the single most
  common cause of abandonment. Write the feature down, do not build it.
- **The engineering became more interesting than the game.** A beautiful ECS with no game
  attached is a common and very enjoyable way to not ship.
- **No playable build exists after a third of the timeline.** Something is wrong with the
  order of work — get to playable, then extend.
- **Nobody outside the project has played it.** Feedback delayed is design debt, and it
  compounds. Get it in front of someone at the prototype stage; see
  `skills/phaser-feedback/`.

The general remedy is the same in every case: get to a **finishable** version, finish it,
and then decide whether to extend. A finished small game teaches more than an abandoned
large one, and it is the only one that produces players.

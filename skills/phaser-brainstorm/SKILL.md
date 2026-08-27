---
name: phaser-brainstorm
description: This skill should be used when the user asks to "brainstorm a game idea", "help me come up with a game", "I want to make a game but don't know what", "is this game idea any good", "what should I build", "refine my game concept", "scope this idea down", "what genre fits", "help me pick a game to build", "turn this idea into something buildable", or arrives with a vague concept that needs shaping before a GDD can be written.
version: 0.7.0
---

# Brainstorming a Phaser 4 Game

The step before the design document. A GDD answers *how the game works*; this answers
*what game is worth working on, and can this person finish it*.

Most abandoned game projects were not badly built. They were badly scoped — the idea was
never sized against the time and skills available, and the failure was baked in before
the first line of code.

---

## Start with what is actually fixed

Ask these four before generating a single idea. They eliminate more possibilities than
any amount of ideation, and it is cheaper to eliminate now:

| Question | Why it decides things |
|---|---|
| **How much time?** A weekend, a month, a year? | The single strongest constraint. A weekend game and a year game are different *kinds* of thing, not different sizes of the same thing. |
| **Who is this for?** A jam, a portfolio, a paying audience, yourself? | A portfolio piece optimises for a striking 30 seconds. A commercial game optimises for hour twenty. |
| **What can you make or get?** Art, audio, both, neither? | If nobody can draw, the game has to be one where that does not matter — and that is a real design constraint, not a limitation to apologise for. |
| **What have you finished before?** | The best predictor of what someone will finish next. First game and fifth game deserve different advice. |

Do not skip to ideas because the user seems keen. An idea generated without these is a
coin flip, and enthusiasm for the wrong-sized project is exactly how the next six months
get spent.

---

## Then find the hook

A game concept needs one sentence that makes someone want to play it. Not a genre — a
genre is a shelf, not an idea.

| Not a hook | A hook |
|---|---|
| "A platformer" | "A platformer where you can only move when the music plays" |
| "A tower defence game" | "A tower defence game where the towers are the enemies you killed" |
| "An RPG" | "An RPG where every party member remembers how you treated them" |

The test: **can you describe it in one sentence that contains a verb nobody expects?**
If the sentence is a genre plus adjectives, keep going.

Ways to find one that work more often than "think harder":

- **Invert a convention.** What does every game in this genre take for granted? A
  platformer assumes you control when to jump. A stealth game assumes you want to be
  unseen.
- **Take one mechanic somewhere else.** Deck-building in a racing game. Tower placement
  in a dating sim.
- **Start from a constraint.** One button. One screen. No losing. No text.
- **Start from a feeling.** "Being slightly late for everything." "Tidying up." Then find
  the mechanic that produces it.
- **Start from what you can actually make.** If the only art you can produce is
  silhouettes, a game about shadows is not a compromise — it is a concept with its art
  direction already solved.

---

## Size it honestly

This is the step that decides whether the game ships. Be concrete and be unwelcome about
it, because the alternative is being wrong in six months.

| Scope | Realistic for | Content |
|---|---|---|
| **Weekend / jam** | One mechanic, executed cleanly | 1 scene type, 1–2 enemies, 3–5 levels or endless |
| **1–2 weeks** | One mechanic plus progression | Menu, gameplay, game-over, 8–12 levels, save |
| **1–2 months** | A small complete game | 3–4 mechanics, 20+ levels or procedural, audio, polish |
| **3–6 months** | A commercial small game | Full progression, content variety, tutorial, settings, releases |
| **A year+** | Do not start here | — |

Multiply every estimate by three. Not as a joke — that is roughly the observed ratio
between what game developers estimate and what they measure, and it holds across
experience levels.

**Where the time actually goes.** People estimate the core mechanic and forget the rest:

| Work | Share of the project |
|---|---|
| Core mechanic | 20% |
| Menus, settings, saves, pause, transitions | 25% |
| Content — levels, enemies, balancing | 30% |
| Audio, juice, polish | 15% |
| Bugs, platform issues, release | 10% |

A "simple platformer" with the core mechanic done is 20% finished, not nearly finished.
This table is the single most useful thing to show someone who thinks they are close.

### Cutting to fit

When the idea does not fit the time, cut **content**, not the **hook**. A game with one
brilliant mechanic and four levels is finished. A game with five mechanics half-built is
not a game.

| Cut this | Keep this |
|---|---|
| Number of levels, enemies, weapons | The one thing that makes it interesting |
| Multiplayer | Feel and responsiveness |
| Story, cutscenes, voice | The core loop |
| Procedural generation | Working save/load |
| Multiple endings | An ending |

Multiplayer deserves its own warning: it does not add a feature, it multiplies the whole
project. Netcode, sync, lobbies, and every bug becoming two bugs. Unless multiplayer *is*
the hook, cut it.

---

## Pressure-test before committing

Six questions. Weak answers here are cheap to discover now and expensive to discover in
month three.

1. **What does the player do, moment to moment?** If the answer takes a paragraph, the
   loop is not clear yet. "Jump between platforms while the floor collapses" is clear.
2. **Why is the second minute more interesting than the first?** No answer means no
   progression, and the game is a toy — fine for a jam, fatal for anything longer.
3. **What does the player get wrong, and how do they learn?** A game with no failure state
   has no tension; one with unteachable failure is just unfair.
4. **What is the smallest version that proves the idea works?** That is your prototype, and
   it should take days, not weeks.
5. **What could kill this?** Name the technical risk now. "I don't know if I can make the
   physics feel right" is a thing to prototype first, not to discover in week six.
6. **Would you play it?** Not "would it sell". If the honest answer is no, six months with
   it will be worse than it sounds.

---

## Does it suit Phaser 4?

Phaser is a 2D WebGL engine. It is excellent at some things and the wrong choice for
others, and it is kinder to say so at this stage.

**Strong fit:** platformers, top-down action, puzzles, tower defence, shooters, card and
board games, roguelikes, endless runners, visual novels, tile-based anything, and any 2D
game intended to run in a browser.

**Workable with effort:** physics-heavy sandboxes (Matter is capable but demanding),
large open worlds (needs chunking and culling), rhythm games (browser audio latency is
the real problem, not Phaser), real-time multiplayer (Phaser is client-only; the server
is a separate project).

**Wrong tool:** 3D. Phaser 4's renderer is 2D — proper 3D is planned but not here. Use
Three.js or Babylon. Also text-only games, where a web framework is simpler.

**What Phaser 4 specifically brings:** the Beam renderer handles far more on-screen than
v3 did; filters apply to any object; `SpriteGPULayer` makes bullet-hell counts realistic;
cone lights make stealth vision cones cheap. If the idea leans on lighting, effects, or
sheer sprite count, v4 has changed what is affordable — see `skills/phaser-fx/`.

---

## What to produce

End with something the user can act on, not a list of options:

1. **The concept**, in one sentence with the hook visible.
2. **The scope call**, with the time budget and what was cut to fit.
3. **The prototype**, described concretely: what it contains, what it proves, how long it
   should take. Days.
4. **The named risk** — the one thing most likely to sink it, and how the prototype tests
   it.
5. **The next step:** `/phaser-gdd` to write the design document, or `/phaser-new` to
   scaffold and prototype immediately.

If the user brought several ideas, **recommend one** and say why. A ranked list is a way
of avoiding the decision, and the decision is what they came for.

---

## Prototype before designing

For anything longer than a jam, build the prototype **before** writing the GDD. A design
document for a mechanic nobody has felt yet is fiction — you will write three pages about
a jump that turns out to feel wrong.

The prototype answers one question: **does the core mechanic feel good?** Coloured
rectangles are fine. No menu, no art, no audio, no save.

```bash
/phaser-new              # scaffold
# build the one mechanic
/phaser-playtest         # verify it actually runs
```

Then play it. If it is not fun with rectangles, art will not save it — and finding that
out in three days instead of three months is the single highest-value thing this whole
step produces.

---

## Additional Resources

### Reference Files
- **`references/ideation-prompts.md`** — Structured generators for when the user is
  stuck: constraint prompts, mechanic inversions, genre mashups, and the questions that
  pull a vague feeling into a concrete mechanic.
- **`references/scope-calibration.md`** — Worked scope breakdowns for real game shapes,
  with hour estimates by system, and the cut-list order when a project runs long.

### Related
- `skills/phaser-gdd/` — the next step: turning an agreed concept into a design document
- `skills/phaser-init/references/template-archetypes.md` — nine ready archetypes, useful
  both as starting points and as a sense of what each genre actually contains
- `skills/phaser-architect/` — technical architecture, once the design exists

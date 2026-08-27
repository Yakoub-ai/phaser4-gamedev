# Ideation Prompts

Generators for when the user is stuck, or when the first three ideas were all genres with
adjectives. Use these to produce *specific* concepts, then take the strongest through the
pressure test in `SKILL.md`.

Working rule: **generate concrete, judge afterwards.** "A puzzle game with an interesting
twist" is not an idea, it is a placeholder. "A sokoban where the boxes push back" is an
idea — it can be argued with, prototyped, or rejected.

---

## Constraint prompts

Constraints produce better ideas than open questions, because a constraint forces a
decision that open exploration defers indefinitely.

| Constraint | What it forces |
|---|---|
| **One button** | Everything is timing and context. Rhythm, endless runners, one-tap fighters. |
| **One screen, no scrolling** | The whole game state is visible. Strategy, arcade, puzzles. |
| **You cannot lose** | Tension has to come from somewhere else — decay, drift, moral cost. |
| **No text** | The design must teach itself. Universally shippable, and much harder. |
| **You control the world, not the character** | Lemmings, god games, level-as-player. |
| **The player is the antagonist** | Inverts every genre it touches. |
| **One life, permanent consequences** | Every decision becomes heavy. Small scope, high tension. |
| **Two things move together** | Couples the controls. Enormous depth from one rule. |
| **The map is the timer** | Space and time become one resource. |
| **Everything you do is undoable** | Turns failure into a mechanic rather than a punishment. |

Pick a constraint the user did *not* pick, and ask what game it implies. The friction is
the point.

---

## Mechanic inversions

Take a convention the genre never questions and reverse it.

| Genre | Assumption | Inverted |
|---|---|---|
| Platformer | You choose when to jump | Jumping is automatic; you choose when to *stop* |
| Platformer | Gravity pulls down | You rotate gravity; the level does not move |
| Stealth | You want to be unseen | You must be seen by exactly one guard |
| Tower defence | Towers are static, enemies move | Towers walk; the enemies are the terrain |
| Racing | Fastest wins | You must finish in an exact time |
| RPG | You get stronger | You get weaker, and must plan around it |
| Shooter | Bullets damage enemies | Bullets are your only platform |
| Puzzle | You solve the puzzle | You build the puzzle for someone else |
| Card game | You draw from a deck | The deck is the level, and it is finite |
| Survival | Gather resources to live | Resources actively want to be used up |

The good ones survive a follow-up question: *what does the second minute look like?* An
inversion that is interesting once and then routine is a jam entry, not a game.

---

## Mashups

Take a mechanic from one genre and the structure of another. Most produce nothing; the
occasional one is a whole game.

```
[mechanic]  in  [genre]
```

- Deck-building **in** a racing game — your cards are manoeuvres, and the deck is your car
- Tower placement **in** a rhythm game — towers fire on the beat
- Farming **in** a bullet hell — what you plant becomes your ammunition
- Typing **in** a dungeon crawler — spells are words, and the dungeon is a vocabulary
- Cooking **in** a puzzle game — recipes as constraint satisfaction
- Route planning **in** a horror game — you can see the monster's path, not your own
- Physics stacking **in** a strategy game — your base can collapse
- Time-loop **in** a management game — the same day, better each run

Ask: **which half is the hook?** A mashup where both halves are ordinary is two ordinary
games sharing a codebase.

---

## Feeling-first

Sometimes the user knows the feeling they want, not the mechanic. Work forward from it —
this route produces the most distinctive games and the hardest ones to scope.

| Feeling | Mechanical shapes that produce it |
|---|---|
| Momentum, flow | No stopping, speed as a resource, chained actions |
| Dread | Limited information, irreversible choices, an approaching thing |
| Cosiness | No fail state, gentle pace, accumulation, tidiness |
| Cleverness | Information the player can deduce; no hidden rules |
| Panic | More demands than actions; forced triage |
| Loneliness | Empty space, slow travel, absent NPCs |
| Mastery | High skill ceiling, deterministic rules, instant restart |
| Loss | Something that cannot be recovered, and the game continues |

The question that turns a feeling into a game: **what would the player have to do for that
feeling to be theirs rather than described to them?** Dread is not achieved by telling the
player something is coming; it is achieved by making them decide whether to spend the last
of a resource before it arrives.

---

## Working from available assets

Legitimate, and often the fastest route to a finished game. Instead of designing and then
hunting for art:

1. Browse what is actually available — Kenney, itch.io asset packs, OpenGameArt (see
   `skills/phaser-init/references/asset-sourcing-guide.md`).
2. Find a set with more personality than the average.
3. Ask what game *that* set implies.

A cohesive art set that already exists removes the largest risk in a solo project. Games
built this way do not look cheap; games built from a mismatched grab-bag do.

The same logic applies to a deliberate no-art approach: shapes and colour, one font,
strong palette. That is a valid art direction, not a fallback, and it has shipped many
successful games.

---

## Questions that unstick a vague idea

When the user has something but cannot articulate it:

- "Describe the screenshot you want on the store page."
- "What is the player doing in the ten seconds before they die?"
- "What would make someone send a clip of this to a friend?"
- "What is the moment you are building everything else to support?"
- "What is in this game that is not in the game it most resembles?"
- "If you had to cut it to one mechanic, which one survives?"
- "What is the most annoying part of the games you like? What if that was the point?"

The screenshot question is the most reliable. If they can describe it, the game has a
visual identity and a core moment. If they cannot, the concept is still a genre.

---

## Rejecting an idea well

Sometimes the honest answer is that the idea will not work as scoped. Say so, and say why
in terms of what it would take rather than what is wrong with it:

> "As described this is a 6–9 month project — the procedural dungeon generation and the
> crafting system are each about a month on their own, before content. If you have three
> weeks, the version that fits is the dungeon crawl with hand-built floors and no
> crafting. That keeps the part that is interesting."

Three things make this land: a **specific** estimate, the **reason**, and an alternative
that **keeps the hook**. "That's too ambitious" on its own is discouraging and, worse,
unactionable.

The one thing not to do is agree to a plan you think will fail. The user gets six months
of evidence that you were right, and they would rather have had the sentence.

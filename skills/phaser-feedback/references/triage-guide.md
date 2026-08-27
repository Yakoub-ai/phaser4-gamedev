# Triage Guide

Classifying player feedback before acting on it, and ordering what survives.

Getting this wrong is not a small cost. A tuning complaint worked as a defect sends you
hunting a bug that does not exist; a defect worked as tuning gets a number changed while
the actual break stays in. Both end with the reporter's problem still there.

---

## The four kinds

### Defect — the game does something it should not

Test: **can you state what should have happened instead, in terms the game could check?**
If yes, it is a defect.

- "I fell through the platform" → it should have landed on it
- "The score kept going up after I died" → it should have stopped
- "The shop let me buy with no gold" → it should have refused

**Route:** failing scenario → fix → verify. You decide; no user input required beyond
the report itself.

### Tuning — the game does exactly what it was told, and it feels wrong

Test: **would the fix be a number?** If yes, it is tuning.

- "The jump feels floaty" → gravity, jump velocity
- "The boss is impossible" → HP, damage, attack rate
- "Enemies come too fast" → spawn interval
- "The dash is useless" → distance, cooldown, i-frames

**Route:** get a numeric target from the user, change the value, verify the new number
holds, then ask the reporter whether it is what they meant.

The trap is that tuning reports read like defects. "The boss is impossible" sounds like
something is broken. Nothing is broken — the fight is doing what the config says, and
somebody has to decide what it should say instead. That somebody is not you.

**Never invent the target.** "I made the boss easier" is not a fix; it is a change in an
arbitrary direction. Ask: *how many attempts should this take? how long should the fight
run? how many hits should it survive?* Then the change is verifiable and the follow-up
conversation is about a number instead of a feeling.

### Design — the game works as designed, and the design is unwanted

Test: **does fixing it mean changing what the game is?** Then it is design.

- "Why is there no save system"
- "I hate that dying resets the whole level"
- "There should be a map"

**Route:** this is a GDD conversation, not a code one. Take it to
`skills/phaser-gdd/` and the user's roadmap. Implementing a design change because one
player asked for it is how scope dies.

Note that a design complaint and a tuning complaint can hide in the same sentence. "Dying
resets the level and that's brutal" might be *checkpoint frequency* (tuning) or *the
whole death model* (design). Ask which.

### Unactionable — not enough to work with

Test: **can you get from this sentence to a repro?** If not, it is unactionable *until*
you ask.

- "the shop is broken"
- "it lags"
- "doesn't work on mobile"

**Route:** one specific question back. Not "can you give more detail" — a question they
can answer in one line:

| Vague | Ask |
|---|---|
| "the shop is broken" | "What did you click, and what happened instead of buying?" |
| "it lags" | "Where — a particular room, or after playing a while? And what device?" |
| "doesn't work on mobile" | "Which phone and browser? Does it fail to load, or load and misbehave?" |
| "the controls are bad" | "Which control, and what did you expect it to do?" |

Ask, then park it. Do not guess. A guessed repro that passes tells you nothing, and a
guessed fix aimed at the wrong thing is worse than no fix — it consumes the credibility
you will need when you ask them to test the next build.

---

## The fifth category: taste

Some feedback is genuinely unresolvable by testing and should be labelled rather than
processed:

- "the art style doesn't do it for me"
- "the music is annoying"
- "it's not fun"

These are real signal — especially when several people say the same thing — but no
scenario settles them, and no metric substitutes for the judgement. Record them, count
them, surface the count to the user, and let a human decide. Assigning a fake numeric
target ("increase fun by 20%") is worse than leaving it open.

The one thing worth doing: if three separate people say "it's not fun" and all three
describe the same moment, that moment is a design problem with a location. That is
actionable even though the sentiment is not.

---

## Worked classifications

Real feedback is messier than the categories. Some worked cases:

> **"I keep dying at the same spot and it's not my fault"**

Ambiguous, and the ambiguity matters. Either a defect (a hitbox that extends past the
sprite, a trap that fires with no tell) or tuning (the jump is genuinely too tight).
**Reproduce first** — a scenario that performs the jump correctly and still dies proves
defect; one that succeeds proves tuning. This is a case where the repro *is* the triage.

> **"the game froze when I opened the menu the second time"**

Defect, and the word "second" is the whole report. Something is not being cleaned up
between opens. Scenario: `repeat` the open/close twice, assert the menu is interactive
on the second. Note the shape — "the second time" is a state-accumulation claim.

> **"it's way too hard but also kind of boring"**

Two items, and they pull in opposite directions, which is itself information: difficulty
is probably not the problem — pacing or feedback is. Split into two entries, both
tuning/design, and surface the tension to the user rather than resolving it yourself.

> **"performance is bad on my old phone"**

Unactionable until you have the device, and then likely tuning (particle counts, texture
sizes) rather than a defect. Route it through `skills/phaser-analyze/` before assuming
anything. Do not start optimising on a headless FPS number — that number is software
rendered and says nothing about their phone.

> **"the enemies stopped spawning after wave 12"**

Defect, with an exact reproduction key. Use `eval` to jump to wave 12 rather than
playing twelve waves. If the game cannot be put into that state directly, that is the
first thing to fix — see `skills/phaser-playtest/references/instrumenting-games.md`.

---

## Prioritising what survives triage

Once classified, order by **how many players hit it × how bad it is when they do**, and
only then by how hard it is to fix.

| Priority | Shape |
|---|---|
| 1 | Blocks play for anyone — crash, softlock, progress loss, unloadable build |
| 2 | Blocks play for some — platform-specific breakage, a mode that fails |
| 3 | Degrades play broadly — a mechanic that misfires often, bad performance |
| 4 | Degrades play narrowly — an edge case, a cosmetic defect |
| 5 | Tuning with a clear target |
| 6 | Tuning without a target yet, design requests, taste |

Two rules that override the table:

**Progress loss outranks everything, including crashes.** A crash costs a session; a
corrupted save costs the player's entire relationship with the game. Anything touching
save data goes first.

**Frequency beats severity more often than people expect.** A minor annoyance that every
single player hits in the first two minutes does more damage than a softlock in an
optional area, because the first one is why nobody reaches the optional area.

If several reports grouped to one root cause in Step 3, the group inherits the highest
priority in it — and fixing it once closes all of them, which usually makes it the
cheapest item on the list as well as the most valuable.

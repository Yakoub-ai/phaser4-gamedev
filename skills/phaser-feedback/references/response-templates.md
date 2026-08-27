# Responding to Reporters

Closing the loop. The reply is not a courtesy — it is what determines whether this person
reports anything again, and whether the next report is useful enough to act on.

---

## What a reply has to carry

Three things, and most replies drop two of them:

1. **What you fixed** — and enough of the cause that they can tell you understood, not
   just that you changed something.
2. **What you changed and want checked** — every tuning change is a guess until the
   person who complained tries it.
3. **What you still need** — the unactionable items, as specific questions.

Only the first is usually written. Dropping the second means never finding out whether
the tuning landed. Dropping the third means the reporter reads silence as "ignored" and
stops writing, which costs more than any single bug.

---

## Structure

Reply **per item, in their words**. Do not merge their four complaints into one
paragraph about what you did this week — they will not be able to find their own report
in it.

```
> "sometimes i just fall through the platform"

Fixed. Falling fast enough carried you through thin platforms between physics
steps. Fast falls land properly now.

> "the jump feels floaty"

Changed — you reach the top of a jump in 0.35s now instead of 0.6s. Does that
match what you meant, or do you want it snappier still?

> "the boss is impossible"

Not changed yet, because I could go several ways. Roughly how many attempts
would have felt fair? I can move its health, its damage, or how fast it attacks.

> "the shop is broken"

I couldn't reproduce this one. What did you click, and what happened instead of
buying?
```

Quoting them back does real work: they can see each point was read, and they answer the
questions inline because the question is attached to the thing they said.

---

## Register

Write to the person who wrote to you. A player who said "it feels floaty" does not want
`PLAYER_GRAVITY_Y`.

| Instead of | Write |
|---|---|
| "Fixed tunneling in the arcade physics step" | "Falling fast no longer drops you through platforms" |
| "Reduced `PLAYER_GRAVITY_Y` from 1200 to 900" | "Jumps are snappier — you reach the top in 0.35s instead of 0.6s" |
| "Added a null guard in `ShopScene.purchase()`" | "Buying with a full inventory no longer breaks the shop" |
| "Cannot reproduce" | "I couldn't get this to happen — what did you click?" |

"Cannot reproduce" as a closing line is the fastest way to end a reporting
relationship. It reads as *I don't believe you*. Say what you tried, then ask for the
missing piece: "I tried buying with a full inventory and with no gold, and both worked —
what were you holding when it broke?"

For technically-inclined reporters, one line of cause is welcome. For everyone else it
is noise. When in doubt, lead with the experience and put the mechanism in a
parenthetical they can skip.

---

## Player-facing changelog

Different job from the reply: the reply is to one person, the changelog is to everyone
who might reinstall. Group by what it means to a player, not by subsystem.

```markdown
## 0.4.2

**Fixed**
- Falling fast no longer drops you through platforms
- The shop no longer breaks when your inventory is full
- Enemies stop spawning correctly at the end of wave 12

**Changed**
- Jumps are snappier — you reach the top faster
- The second boss has less health; it should take about six hits now

**Known issues**
- Music sometimes doesn't restart after alt-tabbing on Firefox
```

A **Known issues** section is worth more than it costs. It converts "this game is buggy"
into "they know, and they're on it", and it stops you receiving the same report eleven
more times.

Credit reporters by name or handle when they agreed to it. It costs one line and it is
the single most effective thing for getting a second report out of someone.

---

## Asking for the missing piece

The quality of the next report is set by how you ask for this one. Closed questions get
answered; open ones get ignored.

| Weak | Strong |
|---|---|
| "Can you give me more detail?" | "What did you click right before it froze?" |
| "What device?" | "iPhone or Android, and did you open it in Safari/Chrome or add it to your home screen?" |
| "Can you reproduce it?" | "Does it happen every time you open the shop, or only sometimes?" |
| "Any console errors?" | "If you're on desktop: F12, Console tab, screenshot anything red." |

That last distinction matters more than the others: **every time** versus **sometimes**
changes how you reproduce it. It is worth asking explicitly, every time, because
reporters rarely volunteer it.

If you can, give them a build with the report path built in — a key that copies the
current game state to the clipboard turns a paragraph of prose into something you can
paste straight into an `eval` step.

---

## After they confirm

When a reporter says a fix worked, two things are left:

1. **The scenario stays.** `playtest/repro-*.mjs` is committed and runs from now on.
   That is what stops the bug returning in three months when someone refactors the
   physics step.
2. **Note what class of bug it was.** Three tunnelling reports in two months is not three
   bugs; it is one architectural problem with your collision step, and it deserves a
   different kind of fix than a fourth patch.

If they say it did *not* work, resist re-fixing immediately. Ask what they saw this time.
A fix that resolves your repro but not their experience means your repro was not
capturing their situation — and that is worth knowing before you write a second fix
aimed at the same wrong target.

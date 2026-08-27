# Store Presence

The page where people decide whether to play. For a web game it usually moves the play
count more than any single feature, and it is the part developers most often treat as an
afterthought.

---

## What people actually do

They watch the GIF, read one line, and decide. Everything else on the page is for the
minority who already decided yes.

That ordering sets the priorities:

| Asset | Effort worth spending |
|---|---|
| Animated capture (GIF or short video) | The most. It is the decision. |
| One-line description | High. It is the only text most people read. |
| Screenshots | Medium. Four different things, not four angles on one. |
| Long description | Low. For people already interested. |
| Tags | Medium — they decide *who arrives*, which is upstream of everything. |

---

## The animated capture

**Show play, not presentation.** Starting on a title screen wastes the seconds that
decide. Start on motion.

- **Under 10 seconds.** GIFs loop; a long one never shows its good part twice.
- **Loop cleanly.** Start and end on similar framing so the seam does not read as a stutter.
- **Show the hook.** If the game's idea is that gravity rotates, rotate gravity in the
  first two seconds.
- **No cursor, no fumbling, no UI overlays** that will not exist for the player.

Capture it with a playtest scenario, so it is repeatable and clean:

```javascript
// playtest/showcase.mjs — plays the best 10 seconds, identically every time
export default [
  { action: 'scene', key: 'GameScene', data: { level: 3 }, settle: 600 },
  { action: 'hold', keys: ['ArrowRight'], duration: 900 },
  { action: 'press', key: 'Space' },
  { action: 'hold', keys: ['ArrowRight', 'Space'], duration: 1200 },
  { action: 'press', key: 'ShiftLeft' },
  { action: 'wait', ms: 1500 },
];
```

```bash
node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs" \
  --project . --scenario playtest/showcase.mjs --video --mode build
```

The video lands in `.playtest/video/`. Convert to GIF with ffmpeg:

```bash
ffmpeg -i input.webm -vf "fps=20,scale=600:-1:flags=lanczos,split[s0][s1];\
[s0]palettegen[p];[s1][p]paletteuse" -loop 0 output.gif
```

Re-running one command after an art change is what makes this worth setting up — most
store GIFs are stale because re-recording by hand is tedious.

---

## The one-line description

Your hook from brainstorming, stated as what the player *does*.

| Weak | Strong |
|---|---|
| "An exciting platformer adventure!" | "A platformer where you can only move while the music plays" |
| "Test your skills in this challenging game" | "Defend your base with towers built from the enemies you killed" |
| "A fun puzzle game with 50 levels" | "A sokoban where the boxes push back" |

Two failure modes, both common: **adjectives instead of verbs** ("exciting", "challenging",
"fun" — every game claims these, so they carry no information), and **genre without hook**
("a platformer" tells them the shelf, not the game).

Test it: does the sentence contain something a competing game could not also say? If not,
it is not describing your game yet.

---

## Screenshots

Four to six, each showing something *different*: a different mechanic, a different area, a
different visual mode. Four screenshots of the same room say the game has one room, even
when it does not.

- Capture at the game's native resolution — no upscaling
- No debug overlays, no FPS counters, no placeholder text
- Include one that shows the UI in a real state (health low, inventory full), not empty
- If there is a striking moment, lead with it

`{ action: 'screenshot', name: '...' }` steps in a scenario give you consistent captures
that regenerate on demand, same as the GIF.

---

## The long description

For the people already interested. Keep it structured and skimmable:

```markdown
[One-line hook]

[Two or three sentences: what you do, why it is interesting]

**Controls**
- Arrow keys / WASD — move
- Space — jump
- Shift — dash

**Features**
- 20 hand-built levels
- Original soundtrack
- Roughly 30 minutes to finish

[Credits and asset attributions]
```

**State the length.** "About 30 minutes" gets a short game a warmer reception than the
same game unlabelled, because expectation mismatch is what produces disappointment. A
20-minute game presented as 20 minutes is complete; presented as nothing in particular, it
reads as unfinished.

**Put controls on the page and on the title screen.** Web-game players will not go
hunting, and a player who cannot work out the controls is indistinguishable from a player
who does not like the game.

---

## Tags

Tags decide who arrives, which determines your reviews before anyone plays.

- **Be accurate over aspirational.** Tagging a short arcade game "roguelike" brings
  roguelike players, who will correctly report that it is not one.
- **Use the platform's real vocabulary** — browse the tags that actually have traffic
  rather than inventing your own.
- **Include the obvious ones.** `platformer`, `pixel-art`, `singleplayer`, `html5`.
  Specific-only tagging is a common way to be invisible.
- **Genre plus mood plus visual style** is usually the right spread.

---

## Platform notes

### itch.io

The default home for a Phaser game. Free, no gatekeeping, an audience that browses.

- Cover image **630×500** — it is the thumbnail everywhere on the site
- Embed dimensions must match your game exactly, or you get scrollbars or letterboxing
- Enable the fullscreen button
- Devlogs surface on followers' feeds — a genuine, free distribution channel
- Price "name your own price" with a zero minimum if you want both reach and tips

### Newgrounds

Larger casual audience, more forgiving of short games, rougher feedback. Medals and
scoreboards drive real engagement if the game suits them.

### Poki / CrazyGames

Commercial web-game portals. Real revenue share, but they impose requirements: specific
loading behaviour, ad integration points, mobile support, session-length targets. Read
their SDK docs *before* building if this is the target — retrofitting is expensive.

### Mobile stores

A different project, not a deployment step. Store listing, icons at every size, age
rating, privacy policy, review cycles, and a rejection loop measured in days. Budget
40–120 hours beyond the game itself. See `skills/phaser-mobile/`.

---

## After the page is up

- **Post where the audience already is**, not just where you are: genre subreddits, the
  Phaser Discord, `#screenshotsaturday`, jam communities. One good post in a place that
  cares beats five in places that do not.
- **Lead with the GIF everywhere.** It is the only asset that works identically on every
  platform.
- **Update the page when the game updates.** A stale GIF showing old art actively
  undersells a game that has improved.
- **Keep a known-issues section.** It converts "this is buggy" into "they know and they
  are on it", and it stops you receiving the same report a dozen times.
- **Reply to comments.** A developer visibly present in the comments gets more feedback,
  and better feedback, than one who is not. That feedback is the input to
  `skills/phaser-feedback/`, which is where the next version comes from.

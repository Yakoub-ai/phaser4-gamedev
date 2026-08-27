# Release Checklist

The full gate, in the order it should be run. Everything here has ended somebody's launch.

Substitute `PT` for
`node "${CLAUDE_PLUGIN_ROOT}/skills/phaser-playtest/scripts/playtest.mjs"` throughout.

---

## Two weeks out — content lock

- [ ] Feature freeze. New features from here go on a list for the next release, not into
      this build. Every launch-day disaster has a feature added in the final week at its
      root.
- [ ] All content in place — levels, enemies, audio, art. Placeholders identified.
- [ ] Full playthrough by the developer, start to finish, in one sitting
- [ ] Full playthrough by someone else, unassisted and unexplained
- [ ] Balance pass against the acceptance criteria in GDD Section 13
- [ ] Known-issues list written; each item marked ship / fix / cut

---

## One week out — the technical gate

### Builds and runs

- [ ] `npx tsc --noEmit` — clean
- [ ] `npm run build` — succeeds with no warnings you have not read
- [ ] `PT --project . --mode build` — passes
- [ ] Every `playtest/*.mjs` scenario passes **in build mode**
- [ ] `PT --project . --mode build --device iphone` — if claiming mobile
- [ ] `PT --project . --mode build --device android` — if claiming mobile
- [ ] `PT --project . --scenario playtest/long-session.mjs --heap` — no runaway growth

### Build output

- [ ] `base` in `vite.config.ts` matches the deploy target (`'./'` for itch.io; the repo
      path for GitHub Pages). Wrong `base` 404s every asset and is the most common
      launch-day failure.
- [ ] Bundle size checked. Over ~10MB, web players on mobile data leave before it loads.
- [ ] No source maps in production unless you intend them
- [ ] `console.log` removed or gated behind `import.meta.env.DEV`
- [ ] Physics debug rendering off — `debug: false`
- [ ] Dev-only globals and cheat keys gated behind `import.meta.env.DEV`
- [ ] No `.playtest/`, `node_modules/` or source in the deployed artifact

### Content and correctness

- [ ] Every asset licence permits commercial or public use, whichever applies
- [ ] Attribution present where required, and where it is not required but decent
- [ ] No placeholder art, text, or audio still visible
- [ ] Audio levels consistent between scenes; nothing peaks
- [ ] Text checked for typos — including the title screen, which everyone sees

### Player-facing

- [ ] Controls shown in-game, not only on the store page
- [ ] Pause works: physics, audio, timers and input all actually stop
- [ ] Mute, or at least a volume control. Web players expect this and leave without it.
- [ ] Save/load survives a reload, a browser restart, and a version bump
- [ ] Game can be completed — the ending is reachable and does not soft-lock
- [ ] Loading state visible during the preload; a blank screen reads as broken
- [ ] Version number visible somewhere

---

## Launch day

**Before announcing:**

- [ ] Final `PT --project . --mode build` against the **deployed URL**:
      `PT --url https://your-game-url --mode build`
- [ ] Loaded on a device that has never seen the game — no cache, no localStorage
- [ ] Loaded on a phone, on mobile data
- [ ] Store page complete: GIF, screenshots, description, controls, tags
- [ ] Feedback path live and being watched — comments, Discord, email, or a form
- [ ] Previous build kept, and rollback rehearsed
- [ ] In-game state-copy key working, if you added one

**After announcing:**

- [ ] Watch the first loads. Does it work for people who are not you?
- [ ] Watch for first-minute drop-off — that is onboarding, not difficulty
- [ ] Reply to the first reports quickly, even if only to acknowledge
- [ ] Log every report; do not triage in real time under pressure

---

## Per-platform

### itch.io

- [ ] Zip the **contents** of `dist/` — `index.html` at the zip root, not inside a folder
- [ ] "This file will be played in the browser" ticked
- [ ] Viewport dimensions match the game
- [ ] Fullscreen button enabled
- [ ] `base: './'`
- [ ] Tags accurate — wrong tags bring players who leave bad reviews
- [ ] Cover image at 630×500

### GitHub Pages

- [ ] `base: '/repo-name/'`
- [ ] Deploy workflow succeeds and publishes `dist/`
- [ ] Custom domain resolves, if used
- [ ] Verified on the live URL, not just locally — path bugs only appear there

### Netlify / Vercel

- [ ] Build command and output directory set
- [ ] SPA redirect rules only if you actually route; they can mask 404s otherwise
- [ ] Preview deploy checked before promoting

### Mobile (Capacitor)

- [ ] `npx cap sync` after every web build
- [ ] Icons and splash screens at every required size
- [ ] Safe-area insets handled — notches and home indicators
- [ ] Orientation lock matches the design
- [ ] Tested on a real device; the simulator is not Safari
- [ ] Store metadata, age rating, privacy policy
- [ ] Back-button behaviour on Android

---

## Post-launch, first week

- [ ] Triage everything through `/phaser-feedback` rather than fixing ad hoc
- [ ] Each reproduced bug leaves a `playtest/repro-*.mjs` behind
- [ ] Patch releases run the **full** gate again — patches under pressure break things
- [ ] Player-facing changelog for each patch
- [ ] Reporters told when their issue is fixed
- [ ] Known-issues list public, and kept current

---

## The rollback

Have this written down before you need it, because you will be reading it while people
are watching:

1. Redeploy the previous build (keep it — do not rely on rebuilding from a tag under
   pressure).
2. Verify against the live URL: `PT --url https://your-game-url --mode build`.
3. Say something. "Rolled back while I fix a loading bug, back shortly" costs you nothing
   and buys the goodwill you will want in an hour.
4. Reproduce the failure locally, with a scenario, before attempting a forward fix.

Fixing forward under pressure is how a bad launch day becomes a bad launch week.

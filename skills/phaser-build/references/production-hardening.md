# Production Hardening

A browser game is a public, static bundle that runs untrusted on the player's machine.
Hardening it is mostly about not publishing what you didn't mean to, not loading what you
didn't mean to, and not trusting what the client tells you. Projects from `/phaser-new`
have every default below already; this file explains them and what to change when the
game grows.

`bash skills/phaser-build/scripts/validate-project.sh .` checks most of this statically;
`npm run playtest:build` checks the CSP at runtime.

---

## 1. Nothing secret in the bundle

- **Every `VITE_*` variable is inlined into the shipped JavaScript.** It is configuration,
  never a credential. API secrets, signing keys, admin tokens and database passwords do
  not belong in a client game at all — they go behind a server you control.
- Public identifiers are fine (an analytics site ID, a public leaderboard read key).
  Name them so: `VITE_ANALYTICS_SITE_ID`, not `VITE_API_KEY`.
- `.env*` files stay out of git (the template's `.gitignore` covers this). Commit an
  `.env.example` with placeholder values instead.
- `build.sourcemap: false` (the default). Source maps publish your original source. If
  you need them for error reporting, use `'hidden'` and upload them privately.

## 2. Content-Security-Policy

The template injects a CSP `<meta>` tag at build time — a meta tag because itch.io and
GitHub Pages cannot set response headers. The policy only allows the game's own origin
plus `data:`/`blob:` (Phaser uses both for generated textures and decoded audio):

```
default-src 'self'; script-src 'self'; style-src 'self' 'unsafe-inline';
img-src 'self' data: blob:; media-src 'self' data: blob:; font-src 'self' data:;
connect-src 'self' data: blob:; worker-src 'self' blob:; object-src 'none';
base-uri 'self'; form-action 'none'
```

It is build-only because Vite's dev server needs inline styles and a websocket. Chromium
logs every violation as a console error, so `npm run playtest:build` fails on one —
the policy is tested, not just declared.

**Loosen one directive, for one host, when a feature needs it:**

| Feature | Add |
|---|---|
| Online leaderboard / backend at `api.example.com` | `connect-src https://api.example.com` (and `wss://…` for websockets) |
| Google Fonts | `style-src https://fonts.googleapis.com` and `font-src https://fonts.gstatic.com` |
| Assets from a CDN | that origin in `img-src` / `media-src` / `connect-src` |
| Ad or analytics SDK | the origins its documentation lists — and nothing broader |

Never add `'unsafe-eval'` or a bare `https:`; either one undoes the policy. A meta CSP
cannot set `frame-ancestors` — use a response header for that (below).

## 3. Response headers (hosts that allow them)

Netlify and Cloudflare Pages read `public/_headers` (Vite copies it into `dist/`):

```
/*
  X-Content-Type-Options: nosniff
  Referrer-Policy: strict-origin-when-cross-origin
  Permissions-Policy: camera=(), microphone=(), geolocation=()
  Strict-Transport-Security: max-age=31536000; includeSubDomains

/assets/*
  Cache-Control: public, max-age=31536000, immutable
```

Vercel takes the same values in `vercel.json` → `headers`. Add
`Content-Security-Policy: frame-ancestors 'self' https://itch.io https://*.itch.zone`
only if you want to restrict who may embed the game; omit `X-Frame-Options: DENY` if the
game is meant to be embedded anywhere. `/assets/*` files are content-hashed, so
caching them forever is safe; `index.html` must stay revalidated.

## 4. Supply chain

- Commit `package-lock.json`; CI uses `npm ci` so builds use exactly what you tested.
- `npm audit --omit=dev --audit-level=high` runs in CI. Only runtime dependencies reach
  players; dev-tool advisories are worth reading but rarely block a release.
- GitHub Actions are pinned to full commit SHAs, with the tag in a comment. Dependabot
  (`.github/dependabot.yml`) proposes updates; review them like any other change.
- Workflows default to `permissions: contents: read`; only the Pages deploy job gets
  `pages: write` + `id-token: write`. Checkout uses `persist-credentials: false`.
- Load nothing from a CDN at run time unless you must. If you must, pin the exact
  version and add `integrity="sha384-…"` + `crossorigin="anonymous"`.

## 5. Never trust the client

Anything in the browser can be read and changed by the player: memory, `localStorage`,
network requests, the game clock.

- Offline single-player: that is fine. A player cheating at their own game is playing it.
- **Leaderboards, rewards, purchases, multiplayer:** the server is the authority. Validate
  every submission server-side (plausible score for the time played, rate limits, signed
  sessions). Obfuscating the client only delays a determined player.
- Treat `localStorage` data as untrusted input on load: parse defensively, validate
  shape and ranges, fall back to defaults. The template's best-score read shows the
  pattern; `skills/phaser-saveload/` covers versioned saves.
- Never render player-supplied text (names, chat) with `innerHTML` or a DOM element
  built from strings. Phaser `Text` objects are safe.

## 6. Ship the build you tested — cleanly

- `npm run playtest:build` builds with `VITE_PLAYTEST=true` so scenarios can reach the
  game. Run a plain `npm run build` right before packaging; the template's deploy job does.
- The deployed artifact is `dist/` only — no `.playtest/`, `node_modules/`, `.env` or source.
- `arcade.debug` / `matter.debug` are `false`, and console output and cheat keys are gated
  behind `import.meta.env.DEV`.

## 7. Privacy

- `localStorage` for saves and settings needs no consent banner on its own.
- Analytics, ads or anything that identifies a player across sessions brings consent and
  privacy-policy obligations (GDPR, COPPA for children's games). Decide before adding the
  SDK, not after launch.

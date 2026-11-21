import { defineConfig, type Plugin } from 'vite';

// Content-Security-Policy for the shipped build. Injected as a <meta> tag because the
// common game hosts (itch.io, GitHub Pages) do not let you set response headers.
// Build-only: Vite's dev server needs inline styles and a websocket that this forbids.
// `npm run playtest:build` fails on any CSP violation, so loosen a directive only for
// a host you actually load from (e.g. add it to connect-src for an online leaderboard).
const CSP = [
  "default-src 'self'",
  "script-src 'self'",
  "style-src 'self' 'unsafe-inline'",
  "img-src 'self' data: blob:",
  "media-src 'self' data: blob:",
  "font-src 'self' data:",
  "connect-src 'self' data: blob:",
  "worker-src 'self' blob:",
  "object-src 'none'",
  "base-uri 'self'",
  "form-action 'none'",
].join('; ');

function contentSecurityPolicy(): Plugin {
  return {
    name: 'content-security-policy',
    apply: 'build',
    transformIndexHtml: () => [
      { tag: 'meta', attrs: { 'http-equiv': 'Content-Security-Policy', content: CSP }, injectTo: 'head-prepend' },
    ],
  };
}

export default defineConfig({
  // Relative base works on itch.io, GitHub Pages sub-paths, Netlify and Capacitor alike.
  base: './',
  plugins: [contentSecurityPolicy()],
  build: {
    target: 'es2022',
    sourcemap: false,
    // Phaser alone is ~1.2 MB minified; don't warn about the engine itself.
    chunkSizeWarningLimit: 2000,
    rolldownOptions: {
      output: {
        // Phaser in its own chunk: its hash only changes when Phaser is upgraded, so
        // returning players keep it cached across your patches.
        codeSplitting: { groups: [{ name: 'phaser', test: /node_modules[\\/]phaser/ }] },
      },
    },
  },
});

#!/usr/bin/env node
/**
 * playtest.mjs — headless runtime verification for Phaser 4 games.
 *
 * Boots the game in Chromium, captures the failures that TypeScript cannot see
 * (asset 404s, black screens, runtime exceptions, dead scenes, FPS collapse),
 * optionally drives a scripted play session, and reports machine-readable results.
 *
 * Usage:
 *   node playtest.mjs [options]
 *
 * Options:
 *   --project DIR      Project root (default: cwd)
 *   --url URL          Test an already-running server instead of starting one
 *   --mode dev|build   dev = `npm run dev`; build = `npm run build` + `npm run preview`
 *                      (default: dev). build mode catches base-path and bundling bugs.
 *   --scenario FILE    .mjs module default-exporting an array of steps
 *   --out DIR          Artifact directory (default: <project>/.playtest)
 *   --settle MS        Wait after load before probing (default: 3000)
 *   --timeout MS       Server startup timeout (default: 90000)
 *   --viewport WxH     Viewport size (default: 1280x720)
 *   --device NAME      Mobile preset: iphone | android  (overrides --viewport)
 *   --fail-on-warn     Treat console warnings as failures
 *   --json             Print only the JSON report to stdout
 *   --headed           Run with a visible browser
 *   --repeat N         Run the scenario N times and report the flake rate.
 *                      This is how you pin down "it only happens sometimes".
 *   --seed N           Seed Math.random so a run is reproducible.
 *   --heap             Measure JS heap growth across the session (leak hunting).
 *   --video            Record video of the session into --out.
 *   --trace            Write a Playwright trace into --out (open with `npx playwright show-trace`).
 *   --slowmo MS        Delay between input actions, for watching a repro in --headed.
 *   --browser PATH     Use a specific Chromium binary instead of Playwright's own
 *                      download. Also read from PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH.
 *
 * Exit codes: 0 = all checks passed, 1 = check failures, 2 = harness error.
 */

import { spawn } from 'node:child_process';
import { createRequire } from 'node:module';
import { pathToFileURL } from 'node:url';
import fs from 'node:fs';
import path from 'node:path';
import net from 'node:net';

// ── CLI parsing ───────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const opts = {
    project: process.cwd(),
    url: null,
    mode: 'dev',
    scenario: null,
    out: null,
    settle: 3000,
    timeout: 90000,
    viewport: '1280x720',
    device: null,
    failOnWarn: false,
    json: false,
    headed: false,
    repeat: 1,
    seed: null,
    heap: false,
    video: false,
    trace: false,
    slowmo: 0,
    browser: process.env.PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH || null,
  };
  const flags = {
    '--project': 'project', '--url': 'url', '--mode': 'mode', '--scenario': 'scenario',
    '--out': 'out', '--settle': 'settle', '--timeout': 'timeout',
    '--viewport': 'viewport', '--device': 'device',
    '--repeat': 'repeat', '--seed': 'seed', '--slowmo': 'slowmo', '--browser': 'browser',
  };
  for (let i = 2; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--fail-on-warn') opts.failOnWarn = true;
    else if (a === '--json') opts.json = true;
    else if (a === '--headed') opts.headed = true;
    else if (a === '--heap') opts.heap = true;
    else if (a === '--video') opts.video = true;
    else if (a === '--trace') opts.trace = true;
    else if (a === '--help' || a === '-h') { console.log(HELP); process.exit(0); }
    else if (flags[a]) opts[flags[a]] = argv[++i];
    else throw new Error(`Unknown option: ${a}`);
  }
  opts.project = path.resolve(opts.project);
  opts.settle = Number(opts.settle);
  opts.timeout = Number(opts.timeout);
  opts.repeat = Math.max(1, Number(opts.repeat));
  opts.slowmo = Math.max(0, Number(opts.slowmo));
  if (opts.seed !== null) opts.seed = Number(opts.seed);
  opts.out = opts.out ? path.resolve(opts.out) : path.join(opts.project, '.playtest');
  if (!['dev', 'build'].includes(opts.mode)) throw new Error(`--mode must be dev or build`);
  if (opts.repeat > 1 && !opts.scenario) throw new Error('--repeat needs a --scenario to repeat');
  return opts;
}

const HELP = `playtest.mjs — headless runtime verification for Phaser 4 games
See references/playtest-harness.md for the full option and scenario reference.`;

const DEVICES = {
  iphone: { width: 390, height: 844, dpr: 3, mobile: true,
    ua: 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/17.0 Mobile/15E148 Safari/604.1' },
  android: { width: 412, height: 915, dpr: 2.6, mobile: true,
    ua: 'Mozilla/5.0 (Linux; Android 14; Pixel 8) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/120.0.0.0 Mobile Safari/537.36' },
};

// ── Output helpers ────────────────────────────────────────────────────────────

const C = { red: '\x1b[0;31m', yellow: '\x1b[1;33m', green: '\x1b[0;32m', cyan: '\x1b[0;36m', dim: '\x1b[2m', off: '\x1b[0m' };
let QUIET = false;
const log = (m = '') => { if (!QUIET) console.log(m); };
const checks = [];
// When a scenario is being repeated, records are diverted into a per-run buffer so
// each attempt can be judged on its own before the runs are aggregated.
let CAPTURE = null;
function record(name, status, detail, data) {
  const entry = { name, status, detail, ...(data ? { data } : {}) };
  if (CAPTURE) { CAPTURE.push(entry); return entry; }
  checks.push(entry);
  if (QUIET) return entry;
  const badge = status === 'pass' ? `${C.green}[PASS]${C.off}`
    : status === 'fail' ? `${C.red}[FAIL]${C.off}`
    : status === 'warn' ? `${C.yellow}[WARN]${C.off}` : `${C.cyan}[INFO]${C.off}`;
  console.log(`${badge} ${name}${detail ? ` — ${detail}` : ''}`);
  return entry;
}

// ── Playwright resolution ─────────────────────────────────────────────────────

async function loadChromium(projectDir) {
  const candidates = ['playwright', '@playwright/test', 'playwright-core'];
  const requireFrom = createRequire(path.join(projectDir, 'package.json'));
  for (const name of candidates) {
    for (const resolver of [() => requireFrom.resolve(name), () => createRequire(import.meta.url).resolve(name)]) {
      try {
        const mod = await import(pathToFileURL(resolver()).href);
        const chromium = (mod.chromium || mod.default?.chromium);
        if (chromium) return chromium;
      } catch { /* try next */ }
    }
  }
  throw new Error(
    'Playwright not found. Install it in the project:\n' +
    '  npm install -D playwright\n' +
    '  npx playwright install chromium\n' +
    'If the machine already has a Chromium, point at it instead:\n' +
    '  --browser /path/to/chrome   (or set PLAYWRIGHT_CHROMIUM_EXECUTABLE_PATH)'
  );
}

// ── Dev server management ─────────────────────────────────────────────────────

function portOpen(port, host = '127.0.0.1') {
  return new Promise((resolve) => {
    const sock = net.connect({ port, host });
    const done = (v) => { sock.destroy(); resolve(v); };
    sock.setTimeout(500);
    sock.on('connect', () => done(true));
    sock.on('error', () => done(false));
    sock.on('timeout', () => done(false));
  });
}

const URL_RE = /(https?:\/\/(?:localhost|127\.0\.0\.1|\[::1\]):(\d+)\/?[^\s\x1b]*)/i;

async function runOnce(cmd, args, cwd, label) {
  log(`${C.dim}$ ${cmd} ${args.join(' ')}${C.off}`);
  return new Promise((resolve, reject) => {
    const p = spawn(cmd, args, { cwd, stdio: ['ignore', 'pipe', 'pipe'], shell: process.platform === 'win32' });
    let out = '';
    p.stdout.on('data', (d) => { out += d; });
    p.stderr.on('data', (d) => { out += d; });
    p.on('error', reject);
    p.on('exit', (code) => code === 0 ? resolve(out) : reject(new Error(`${label} failed (exit ${code}):\n${out.slice(-4000)}`)));
  });
}

async function startServer(opts) {
  const script = opts.mode === 'build' ? 'preview' : 'dev';
  const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';

  if (opts.mode === 'build') {
    await runOnce(npm, ['run', 'build'], opts.project, 'npm run build');
    record('production build', 'pass', 'npm run build succeeded');
  }

  log(`${C.dim}$ npm run ${script}${C.off}`);
  const proc = spawn(npm, ['run', script], {
    cwd: opts.project,
    stdio: ['ignore', 'pipe', 'pipe'],
    detached: process.platform !== 'win32',
    shell: process.platform === 'win32',
  });

  let buffer = '';
  const url = await new Promise((resolve, reject) => {
    const timer = setTimeout(() => reject(new Error(
      `Server did not report a URL within ${opts.timeout}ms.\nOutput:\n${buffer.slice(-2000)}`)), opts.timeout);
    const scan = (d) => {
      buffer += d.toString();
      const m = buffer.match(URL_RE);
      if (m) { clearTimeout(timer); resolve(m[1].replace(/\/$/, '')); }
    };
    proc.stdout.on('data', scan);
    proc.stderr.on('data', scan);
    proc.on('exit', (code) => { clearTimeout(timer); reject(new Error(`Server exited early (code ${code}):\n${buffer.slice(-2000)}`)); });
    proc.on('error', reject);
  });

  // Wait for the socket to actually accept connections.
  const port = Number(new URL(url).port);
  for (let i = 0; i < 60 && !(await portOpen(port)); i++) await new Promise((r) => setTimeout(r, 250));

  return { url, stop: () => stopServer(proc) };
}

function stopServer(proc) {
  if (!proc || proc.exitCode !== null) return;
  try {
    if (process.platform !== 'win32' && proc.pid) process.kill(-proc.pid, 'SIGTERM');
    else proc.kill('SIGTERM');
  } catch { /* already gone */ }
}

/**
 * The installed Phaser version, read from disk.
 *
 * It cannot be read reliably from the running page: under an ESM bundle there is no
 * global `Phaser`, and `game.config.gameVersion` is the *game's* version string (empty
 * unless the developer set it), not Phaser's. node_modules is the source of truth.
 */
function installedPhaserVersion(projectDir) {
  try {
    const req = createRequire(path.join(projectDir, 'package.json'));
    return req('phaser/package.json').version;
  } catch {
    return null;
  }
}

// ── Page-side probes ──────────────────────────────────────────────────────────

/**
 * Locate the Phaser.Game instance. Games built with a bundler keep `game` in
 * module scope, so it is only reachable if the project exposes it (see
 * references/instrumenting-games.md). We scan the usual handles and then fall
 * back to a shallow sweep of window own-properties.
 */
const FIND_GAME = `(() => {
  const looksLikeGame = (o) => !!o && typeof o === 'object'
    && o.scene && o.loop && o.renderer && o.config && typeof o.isBooted === 'boolean';
  const named = ['__PHASER_GAME__', 'game', 'phaserGame', '__game'];
  for (const k of named) { try { if (looksLikeGame(window[k])) { window.__playtestGame = window[k]; return k; } } catch {} }
  for (const k of Object.getOwnPropertyNames(window)) {
    let v; try { v = window[k]; } catch { continue; }
    if (looksLikeGame(v)) { window.__playtestGame = v; return k; }
  }
  return null;
})()`;

const PROBE_STATE = `(() => {
  const g = window.__playtestGame;
  if (!g) return null;
  const scenes = g.scene.getScenes(true).map((s) => {
    let bodies = 0;
    try { bodies = (s.physics?.world?.bodies?.size ?? 0) + (s.physics?.world?.staticBodies?.size ?? 0); } catch {}
    return {
      key: s.scene.key,
      displayList: s.children ? s.children.length : 0,
      bodies,
      tweens: (() => { try { return s.tweens.getTweens().length; } catch { return 0; } })(),
    };
  });
  return {
    phaserVersion: window.Phaser?.VERSION || g.config?.gameVersion || 'unknown',
    renderType: g.renderer?.type === 1 ? 'CANVAS' : g.renderer?.type === 2 ? 'WEBGL' : String(g.renderer?.type ?? 'unknown'),
    isBooted: g.isBooted,
    isPaused: g.loop?.paused ?? false,
    activeScenes: scenes,
    totalScenes: g.scene.scenes.length,
    textureKeys: (() => { try { return g.textures.getTextureKeys().length; } catch { return -1; } })(),
    soundsPlaying: (() => { try { return g.sound.sounds.filter((s) => s.isPlaying).length; } catch { return -1; } })(),
  };
})()`;

const SAMPLE_FPS = (ms) => `(async () => {
  const g = window.__playtestGame;
  if (!g) return null;
  const samples = [];
  const end = performance.now() + ${ms};
  while (performance.now() < end) {
    await new Promise((r) => requestAnimationFrame(r));
    samples.push(g.loop.actualFps);
  }
  samples.sort((a, b) => a - b);
  const at = (p) => samples[Math.min(samples.length - 1, Math.floor(samples.length * p))] ?? 0;
  return { samples: samples.length, min: Math.round(at(0)), p5: Math.round(at(0.05)), median: Math.round(at(0.5)) };
})()`;

/** Screenshot the canvas, decode it back inside the page, and measure colour spread. */
async function analyzeCanvas(page, canvas) {
  const png = await canvas.screenshot({ type: 'png' });
  return page.evaluate(async (dataUrl) => {
    const img = new Image();
    await new Promise((res, rej) => { img.onload = res; img.onerror = () => rej(new Error('decode failed')); img.src = dataUrl; });
    const W = Math.max(1, Math.min(img.width, 320));
    const H = Math.max(1, Math.min(img.height, 180));
    const c = document.createElement('canvas');
    c.width = W; c.height = H;
    const ctx = c.getContext('2d', { willReadFrequently: true });
    ctx.drawImage(img, 0, 0, W, H);
    const d = ctx.getImageData(0, 0, W, H).data;
    const counts = new Map();
    for (let i = 0; i < d.length; i += 4) {
      const key = ((d[i] >> 4) << 8) | ((d[i + 1] >> 4) << 4) | (d[i + 2] >> 4);
      counts.set(key, (counts.get(key) ?? 0) + 1);
    }
    let modal = 0;
    for (const v of counts.values()) if (v > modal) modal = v;
    const total = W * H;
    return {
      width: img.width, height: img.height,
      uniqueColors: counts.size,
      coverage: Number((1 - modal / total).toFixed(4)),
    };
  }, `data:image/png;base64,${png.toString('base64')}`);
}

// ── Scenario execution ────────────────────────────────────────────────────────

/**
 * Evaluate an expression inside the page with `game` bound to the running
 * Phaser.Game, and `scene(key)` available as a shorthand for the common case of
 * reaching into a specific scene.
 */
function pageExpr(expression) {
  return `(() => {
    const game = window.__playtestGame;
    const scene = (k) => game.scene.getScene(k);
    return (${expression});
  })()`;
}

function stats(series) {
  const nums = series.filter((v) => typeof v === 'number' && Number.isFinite(v));
  if (!nums.length) return { samples: series.length, numeric: 0 };
  const mean = nums.reduce((a, b) => a + b, 0) / nums.length;
  const variance = nums.reduce((a, b) => a + (b - mean) ** 2, 0) / nums.length;
  const sorted = [...nums].sort((a, b) => a - b);
  const round = (n) => Number(n.toFixed(4));
  return {
    samples: series.length,
    numeric: nums.length,
    min: round(sorted[0]),
    max: round(sorted[sorted.length - 1]),
    range: round(sorted[sorted.length - 1] - sorted[0]),
    mean: round(mean),
    stddev: round(Math.sqrt(variance)),
    first: round(nums[0]),
    last: round(nums[nums.length - 1]),
    delta: round(nums[nums.length - 1] - nums[0]),
  };
}

/**
 * Assert one expectation. `value` may be supplied directly (for `sample` steps,
 * whose expectation reads a computed statistic rather than a live expression).
 */
async function assertExpectation(page, step, label, precomputed) {
  const e = step.expect;
  if (!e) return true;

  let value, subject;
  if (precomputed !== undefined) {
    const stat = e.stat ?? 'last';
    value = precomputed[stat];
    subject = `${label}: ${stat}`;
  } else {
    value = await page.evaluate(pageExpr(e.expression));
    subject = `${label}: ${e.expression}`;
  }

  let ok = true, want = '';
  if ('equals' in e)        { ok = JSON.stringify(value) === JSON.stringify(e.equals); want = `=== ${JSON.stringify(e.equals)}`; }
  else if ('notEquals' in e){ ok = JSON.stringify(value) !== JSON.stringify(e.notEquals); want = `!== ${JSON.stringify(e.notEquals)}`; }
  else if ('atLeast' in e)  { ok = Number(value) >= e.atLeast; want = `>= ${e.atLeast}`; }
  else if ('atMost' in e)   { ok = Number(value) <= e.atMost; want = `<= ${e.atMost}`; }
  else if ('above' in e)    { ok = Number(value) > e.above; want = `> ${e.above}`; }
  else if ('below' in e)    { ok = Number(value) < e.below; want = `< ${e.below}`; }
  else if ('within' in e)   { ok = Math.abs(Number(value) - e.within.of) <= e.within.tolerance;
                              want = `within ${e.within.tolerance} of ${e.within.of}`; }
  else if ('oneOf' in e)    { ok = e.oneOf.some((c) => JSON.stringify(c) === JSON.stringify(value));
                              want = `one of ${JSON.stringify(e.oneOf)}`; }
  else if ('contains' in e) { ok = value != null && (Array.isArray(value)
                                ? value.some((v) => JSON.stringify(v) === JSON.stringify(e.contains))
                                : String(value).includes(String(e.contains)));
                              want = `contains ${JSON.stringify(e.contains)}`; }
  else                      { ok = !!value; want = 'truthy'; }

  record(`${subject} ${want}`, ok ? 'pass' : 'fail', `got ${JSON.stringify(value)}`);
  return ok;
}

async function canvasPoint(canvas, x, y) {
  const box = await canvas.boundingBox();
  if (!box) throw new Error('canvas has no bounding box');
  return { x: box.x + (x ?? box.width / 2), y: box.y + (y ?? box.height / 2) };
}

function shotPath(outDir, index, name) {
  return path.join(outDir, `${String(index).padStart(2, '0')}-${(name || 'shot').replace(/\W+/g, '-')}.png`);
}

/**
 * Execute a list of scenario steps. Returns the number of failed assertions.
 *
 * `ctx` carries { page, canvas, outDir, slowmo, counter, prefix }. `counter` is a
 * shared mutable index so screenshots stay uniquely named across nested `repeat`
 * blocks, and `prefix` labels steps with their repeat iteration.
 */
async function runSteps(ctx, steps) {
  const { page, canvas, outDir } = ctx;
  let failures = 0;

  for (const [i, step] of steps.entries()) {
    const label = (ctx.prefix ?? '') + (step.name || `step ${i + 1} (${step.action})`);
    let precomputed;

    switch (step.action) {
      case 'wait':
        await page.waitForTimeout(step.ms ?? 500);
        break;

      case 'key':
        await page.keyboard.down(step.key);
        await page.waitForTimeout(step.duration ?? 200);
        await page.keyboard.up(step.key);
        break;

      case 'press':
        await page.keyboard.press(step.key);
        break;

      // Several keys held together. Diagonal movement, run+jump, strafe+fire —
      // a large share of "the controls feel wrong" reports live in these combinations
      // and never reproduce with one key at a time.
      case 'hold': {
        const keys = step.keys ?? [step.key];
        for (const k of keys) await page.keyboard.down(k);
        await page.waitForTimeout(step.duration ?? 300);
        for (const k of [...keys].reverse()) await page.keyboard.up(k);
        break;
      }

      case 'click': {
        const pt = await canvasPoint(canvas, step.x, step.y);
        await page.mouse.click(pt.x, pt.y, { button: step.button ?? 'left', clickCount: step.count ?? 1 });
        break;
      }

      case 'move': {
        const pt = await canvasPoint(canvas, step.x, step.y);
        await page.mouse.move(pt.x, pt.y, { steps: step.steps ?? 10 });
        break;
      }

      // Pointer down, glide, release. Drag-and-drop, card play, swipe gestures and
      // virtual joysticks all need the intermediate move events — a click alone
      // never reproduces them.
      case 'drag': {
        const from = await canvasPoint(canvas, step.from?.x, step.from?.y);
        const to = await canvasPoint(canvas, step.to?.x, step.to?.y);
        await page.mouse.move(from.x, from.y);
        await page.mouse.down();
        await page.mouse.move(to.x, to.y, { steps: step.steps ?? 20 });
        if (step.hold) await page.waitForTimeout(step.hold);
        await page.mouse.up();
        break;
      }

      case 'tap': {
        const pt = await canvasPoint(canvas, step.x, step.y);
        try {
          await page.touchscreen.tap(pt.x, pt.y);
        } catch (err) {
          throw new Error(`'tap' needs a touch-enabled context — run with --device iphone or --device android (${err.message})`);
        }
        break;
      }

      case 'wheel':
        await page.mouse.wheel(step.dx ?? 0, step.dy ?? 0);
        break;

      // Jump straight into the state a player described, instead of playing up to it.
      case 'scene':
        await page.evaluate(pageExpr(
          `game.scene.start(${JSON.stringify(step.key)}, ${JSON.stringify(step.data ?? {})}), true`));
        await page.waitForTimeout(step.settle ?? 500);
        break;

      // Arbitrary setup: give the player 1 HP, spawn the boss, fill the inventory.
      // This is what turns "the boss softlocks when you kill it mid-dash" into a test.
      case 'eval':
        await page.evaluate(pageExpr(`(() => { ${step.code} })(), true`));
        break;

      // Poll until true. "The enemy should die within 5 seconds" is a timing claim,
      // and a fixed wait either flakes or wastes time.
      case 'waitFor': {
        const timeout = step.timeout ?? 5000;
        const poll = step.poll ?? 100;
        const started = Date.now();
        let met = false;
        while (Date.now() - started < timeout) {
          if (await page.evaluate(pageExpr(step.expression))) { met = true; break; }
          await page.waitForTimeout(poll);
        }
        const elapsed = Date.now() - started;
        record(`${label}: ${step.expression} within ${timeout}ms`, met ? 'pass' : 'fail',
          met ? `met after ${elapsed}ms` : `never became true (waited ${elapsed}ms)`);
        if (!met) failures++;
        break;
      }

      // Watch a value over time. "Enemies sometimes get stuck" is a claim about
      // variance, not a single reading: sample x over 3s and assert the range moved.
      case 'sample': {
        const duration = step.duration ?? 2000;
        const interval = step.interval ?? 100;
        const series = [];
        const started = Date.now();
        while (Date.now() - started < duration) {
          series.push(await page.evaluate(pageExpr(step.expression)));
          await page.waitForTimeout(interval);
        }
        precomputed = stats(series);
        if (step.series) precomputed.series = series;
        record(`${label}: sampled ${step.expression}`, 'info',
          `n=${precomputed.samples} min=${precomputed.min} max=${precomputed.max} ` +
          `mean=${precomputed.mean} stddev=${precomputed.stddev} range=${precomputed.range}`,
          precomputed);
        break;
      }

      case 'screenshot': {
        const file = shotPath(outDir, ctx.counter.n++, step.name);
        await canvas.screenshot({ path: file });
        record(label, 'info', path.relative(process.cwd(), file));
        break;
      }

      // Run a block of steps N times. Button mashing, repeated waves, and any
      // "it breaks on the third try" report.
      case 'repeat': {
        const times = step.times ?? 2;
        for (let r = 1; r <= times; r++) {
          failures += await runSteps({ ...ctx, prefix: `${label} ${r}/${times} › ` }, step.steps ?? []);
        }
        break;
      }

      case 'expect':
        break; // assertion only

      default:
        throw new Error(`Unknown scenario action: ${step.action}`);
    }

    if (step.expect) {
      const ok = await assertExpectation(page, step, label, precomputed);
      if (!ok) {
        failures++;
        // A failing assertion is exactly when you want to see the screen.
        try {
          await canvas.screenshot({ path: shotPath(outDir, ctx.counter.n++, `FAIL-${step.name || step.action}`) });
        } catch { /* canvas may be gone */ }
      }
    } else if (!['screenshot', 'sample', 'waitFor'].includes(step.action)) {
      record(label, 'info', 'executed');
    }

    if (ctx.slowmo) await page.waitForTimeout(ctx.slowmo);
  }

  return failures;
}

async function runScenario(page, canvas, steps, outDir, slowmo = 0) {
  return runSteps({ page, canvas, outDir, slowmo, counter: { n: 1 } }, steps);
}

// ── Main ──────────────────────────────────────────────────────────────────────

async function main() {
  const opts = parseArgs(process.argv);
  QUIET = opts.json;

  if (!fs.existsSync(path.join(opts.project, 'package.json')) && !opts.url) {
    throw new Error(`No package.json in ${opts.project}. Pass --project DIR or --url URL.`);
  }
  fs.mkdirSync(opts.out, { recursive: true });

  const chromium = await loadChromium(opts.project);

  let server = null;
  let url = opts.url;
  if (!url) {
    server = await startServer(opts);
    url = server.url;
  }
  log(`\n${C.cyan}=== Phaser 4 Playtest ===${C.off}`);
  log(`URL:     ${url}`);
  log(`Mode:    ${opts.mode}${opts.device ? ` (device: ${opts.device})` : ''}`);
  if (opts.repeat > 1) log(`Repeat:  ${opts.repeat} runs (flake detection)`);
  if (opts.seed !== null) log(`Seed:    ${opts.seed}`);
  log('');

  const device = opts.device ? DEVICES[opts.device] : null;
  if (opts.device && !device) throw new Error(`Unknown --device '${opts.device}'. Use: ${Object.keys(DEVICES).join(', ')}`);
  const [vw, vh] = opts.viewport.split('x').map(Number);

  const launchArgs = [
    '--use-gl=swiftshader', '--enable-unsafe-swiftshader',
    '--disable-dev-shm-usage', '--autoplay-policy=no-user-gesture-required',
  ];
  if (opts.heap) launchArgs.push('--enable-precise-memory-info');

  // Playwright refuses to launch when the installed package expects a browser
  // revision the machine does not have — common on CI images that ship their own
  // Chromium. Point at it rather than re-downloading hundreds of megabytes.
  if (opts.browser && !fs.existsSync(opts.browser)) {
    throw new Error(`--browser path does not exist: ${opts.browser}`);
  }
  const browser = await chromium.launch({
    headless: !opts.headed,
    args: launchArgs,
    ...(opts.browser ? { executablePath: opts.browser } : {}),
  });
  if (opts.browser) record('browser', 'info', opts.browser);
  const context = await browser.newContext({
    viewport: device ? { width: device.width, height: device.height } : { width: vw, height: vh },
    deviceScaleFactor: device?.dpr ?? 1,
    isMobile: device?.mobile ?? false,
    hasTouch: device?.mobile ?? false,
    userAgent: device?.ua,
    ...(opts.video ? { recordVideo: { dir: path.join(opts.out, 'video') } } : {}),
  });
  if (opts.trace) {
    await context.tracing.start({ screenshots: true, snapshots: true }).catch(() => {});
  }
  const page = await context.newPage();

  // Determinism. A player reporting "sometimes the wave spawns inside a wall" is
  // describing an RNG path, and an unseeded repro is a coin flip. This replaces
  // Math.random before any page script runs, so Phaser's own RNG inherits it too
  // unless the game seeds Phaser explicitly via `seed` in its game config.
  if (opts.seed !== null) {
    await page.addInitScript((seed) => {
      let a = seed >>> 0;
      Math.random = () => {
        a |= 0; a = (a + 0x6D2B79F5) | 0;
        let t = Math.imul(a ^ (a >>> 15), 1 | a);
        t = (t + Math.imul(t ^ (t >>> 7), 61 | t)) ^ t;
        return ((t ^ (t >>> 14)) >>> 0) / 4294967296;
      };
    }, opts.seed);
    record('deterministic seed', 'info', `Math.random seeded with ${opts.seed}`);
  }

  // ── Collectors ──────────────────────────────────────────────────────────────
  const consoleErrors = [], consoleWarnings = [], pageErrors = [], failedRequests = [];
  // Headless Chromium's software renderer emits GPU driver chatter that has nothing
  // to do with the game. Filtering it keeps --fail-on-warn usable in CI.
  const isRendererNoise = (t) => /GL Driver Message|GPU stall due to ReadPixels|Automatic fallback to software WebGL|SwiftShader/i.test(t);
  // A missing favicon logs a console 404 in every browser. It is not a game failure,
  // and letting it fail the run would mark a perfectly healthy scaffold as broken.
  const isIgnorableRequestNoise = (entry) =>
    /favicon/i.test(entry.location?.url || '') || /favicon/i.test(entry.text);
  page.on('console', (msg) => {
    const entry = { text: msg.text(), location: msg.location() };
    if (isRendererNoise(entry.text)) return;
    if (isIgnorableRequestNoise(entry)) return;
    if (msg.type() === 'error') consoleErrors.push(entry);
    else if (msg.type() === 'warning') consoleWarnings.push(entry);
  });
  page.on('pageerror', (err) => pageErrors.push({ message: err.message, stack: (err.stack || '').split('\n').slice(0, 6).join('\n') }));
  page.on('requestfailed', (req) => failedRequests.push({ url: req.url(), reason: req.failure()?.errorText ?? 'unknown' }));

  // A plain status check is not enough. Vite and most SPA dev servers answer a
  // missing `assets/foo.png` with `200 text/html` (the index.html fallback), so the
  // request looks fine and Phaser fails later with an opaque "Failed to process
  // file". Treat an asset URL served as HTML as the 404 it really is.
  const ASSET_RE = /\.(png|jpe?g|webp|gif|svg|bmp|mp3|ogg|wav|m4a|json|atlas|xml|glsl|frag|vert|ttf|woff2?|fnt|csv|tmx|tsx)(\?.*)?$/i;
  page.on('response', (res) => {
    const url = res.url();
    if (res.status() >= 400) { failedRequests.push({ url, reason: `HTTP ${res.status()}` }); return; }
    const type = (res.headers()['content-type'] || '').toLowerCase();
    if (ASSET_RE.test(new URL(url).pathname) && type.includes('text/html')) {
      failedRequests.push({ url, reason: `HTTP ${res.status()} but served as text/html — file is missing and the dev server returned index.html instead` });
    }
  });

  let report = { url, mode: opts.mode, startedAt: new Date().toISOString() };

  try {
    // ── 1. Load ───────────────────────────────────────────────────────────────
    const resp = await page.goto(url, { waitUntil: 'load', timeout: 60000 });
    record('page loads', resp && resp.ok() ? 'pass' : 'fail', `HTTP ${resp?.status() ?? 'no response'}`);

    // ── 2. Canvas present ─────────────────────────────────────────────────────
    let canvas = null;
    try {
      await page.waitForSelector('canvas', { timeout: 15000, state: 'attached' });
      canvas = await page.$('canvas');
      const size = await canvas.evaluate((c) => ({ w: c.width, h: c.height }));
      record('canvas created', size.w > 0 && size.h > 0 ? 'pass' : 'fail', `${size.w}x${size.h}`);
      report.canvasSize = size;
    } catch {
      record('canvas created', 'fail', 'no <canvas> appeared within 15s — Phaser never booted');
    }

    // Focus the canvas so keyboard input is delivered, and satisfy audio unlock.
    if (canvas) { try { await canvas.click({ position: { x: 5, y: 5 } }); } catch { /* non-fatal */ } }

    // Let the game settle into its first real scene.
    await page.waitForTimeout(opts.settle);

    // ── 3. Phaser instance + scene state ──────────────────────────────────────
    const handle = await page.evaluate(FIND_GAME);
    if (handle) {
      record('Phaser game instance found', 'pass', `window.${handle}`);
      const state = await page.evaluate(PROBE_STATE);
      report.state = state;
      const pkgVersion = installedPhaserVersion(opts.project);
      report.phaserVersion = pkgVersion ?? state.phaserVersion;
      record('renderer', 'info',
        `${state.renderType}${pkgVersion ? ` (Phaser ${pkgVersion})` : ''}`);
      if (pkgVersion && /-(rc|beta|alpha)/.test(pkgVersion)) {
        record('Phaser release', 'warn',
          `${pkgVersion} is a pre-release. Phaser 4 is stable — run \`npm install phaser@latest\`. ` +
          `The \`beta\` dist-tag still points at 4.0.0-rc.7 and is older than stable.`);
      }
      // Canvas still renders, but nothing added in v4 targets it.
      if (state.renderType === 'CANVAS') {
        record('renderer backend', 'warn',
          'running on the deprecated Canvas renderer — filters, stencils and lights are WebGL-only. ' +
          'Check for `type: Phaser.CANVAS` in the game config, or a WebGL context failure earlier in the log.');
      }
      record('game booted', state.isBooted ? 'pass' : 'fail', `isBooted=${state.isBooted}`);

      const active = state.activeScenes;
      record('active scenes', active.length > 0 ? 'pass' : 'fail',
        active.length ? active.map((s) => `${s.key}(${s.displayList} objects)`).join(', ') : 'no scene is running');

      const empty = active.filter((s) => s.displayList === 0);
      if (empty.length) {
        record('scenes render content', 'warn', `${empty.map((s) => s.key).join(', ')} have an empty display list`);
      } else if (active.length) {
        record('scenes render content', 'pass', `${active.reduce((n, s) => n + s.displayList, 0)} display objects total`);
      }

      const fps = await page.evaluate(SAMPLE_FPS(1500));
      report.fps = fps;
      if (fps && fps.samples > 5) {
        const status = fps.p5 >= 50 ? 'pass' : fps.p5 >= 30 ? 'warn' : 'fail';
        record('frame rate', status, `median ${fps.median} fps, 5th pct ${fps.p5} fps (${fps.samples} frames)`);
      } else {
        record('frame rate', 'fail', 'game loop produced no frames — the update loop is stalled');
      }
    } else {
      record('Phaser game instance found', 'warn',
        'not exposed on window — deep checks skipped. Add `if (import.meta.env.DEV) (window as any).__PHASER_GAME__ = game;` ' +
        'next to `new Phaser.Game(config)`. See references/instrumenting-games.md');
    }

    // ── 4. Something is actually drawn ────────────────────────────────────────
    if (canvas) {
      const pix = await analyzeCanvas(page, canvas);
      report.pixels = pix;
      const blank = pix.uniqueColors <= 2 || pix.coverage < 0.005;
      record('canvas renders content', blank ? 'fail' : 'pass',
        blank
          ? `blank/near-blank screen (${pix.uniqueColors} distinct colours, ${(pix.coverage * 100).toFixed(2)}% non-background)`
          : `${pix.uniqueColors} distinct colours, ${(pix.coverage * 100).toFixed(1)}% non-background`);
      await canvas.screenshot({ path: path.join(opts.out, '00-boot.png') });
    }

    // ── 5. Scenario ───────────────────────────────────────────────────────────
    const readHeap = () => page.evaluate(
      '(() => (performance.memory ? performance.memory.usedJSHeapSize : null))()');
    let heapBefore = null;
    if (opts.heap) {
      heapBefore = await readHeap();
      record('heap baseline', heapBefore == null ? 'warn' : 'info',
        heapBefore == null ? 'performance.memory unavailable — heap check skipped'
                           : `${(heapBefore / 1048576).toFixed(1)} MB after boot`);
    }

    if (opts.scenario) {
      const file = path.resolve(opts.scenario);
      const mod = await import(pathToFileURL(file).href);
      const steps = mod.default;
      if (!Array.isArray(steps)) throw new Error(`${file} must default-export an array of steps`);

      if (opts.repeat === 1) {
        log(`\n${C.cyan}--- scenario: ${path.basename(file)} (${steps.length} steps) ---${C.off}`);
        await runScenario(page, canvas, steps, opts.out, opts.slowmo);
      } else {
        // Flake hunting. Player reports of the form "it happens sometimes" are the
        // hardest to act on, because one green run proves nothing. Run the same
        // scenario from a fresh page load N times and report how many held up.
        log(`\n${C.cyan}--- scenario: ${path.basename(file)} × ${opts.repeat} runs ---${C.off}`);
        const runs = [];
        for (let r = 1; r <= opts.repeat; r++) {
          if (r > 1) {
            await page.reload({ waitUntil: 'load', timeout: 60000 });
            try { await page.waitForSelector('canvas', { timeout: 15000, state: 'attached' }); } catch { /* reported below */ }
            canvas = await page.$('canvas');
            if (canvas) { try { await canvas.click({ position: { x: 5, y: 5 } }); } catch { /* non-fatal */ } }
            await page.waitForTimeout(opts.settle);
            await page.evaluate(FIND_GAME);
          }
          const buffer = [];
          CAPTURE = buffer;
          let failures = 0;
          try {
            failures = await runScenario(page, canvas, steps, path.join(opts.out, `run-${r}`), opts.slowmo);
          } catch (err) {
            buffer.push({ name: `run ${r} threw`, status: 'fail', detail: err.message });
            failures++;
          } finally {
            CAPTURE = null;
          }
          fs.mkdirSync(path.join(opts.out, `run-${r}`), { recursive: true });
          runs.push({ run: r, failures, checks: buffer });
          log(`  run ${r}/${opts.repeat}: ${failures ? `${C.red}${failures} failed assertion(s)${C.off}` : `${C.green}clean${C.off}`}`);
        }
        report.runs = runs;

        const bad = runs.filter((r) => r.failures > 0);
        // Name the assertions that failed at least once, with how often. An
        // assertion that fails 3 times in 10 is the intermittent bug; one that
        // fails 10 in 10 is simply broken, and they want different fixes.
        const tally = new Map();
        for (const r of bad) {
          for (const c of r.checks.filter((c) => c.status === 'fail')) {
            tally.set(c.name, (tally.get(c.name) ?? 0) + 1);
          }
        }
        const worst = [...tally.entries()].sort((a, b) => b[1] - a[1])
          .slice(0, 5).map(([name, n]) => `${name} (${n}/${opts.repeat})`);

        if (!bad.length) {
          record('scenario stability', 'pass', `${opts.repeat}/${opts.repeat} runs clean`);
        } else if (bad.length === opts.repeat) {
          record('scenario stability', 'fail',
            `failed in all ${opts.repeat} runs — consistent, not intermittent: ${worst.join('; ')}`);
        } else {
          record('scenario stability', 'fail',
            `INTERMITTENT — failed in ${bad.length}/${opts.repeat} runs: ${worst.join('; ')}`);
        }
      }
    }

    if (opts.heap && heapBefore != null) {
      const heapAfter = await readHeap();
      const growthMb = (heapAfter - heapBefore) / 1048576;
      report.heap = { before: heapBefore, after: heapAfter, growthBytes: heapAfter - heapBefore };
      // Heap growth across a session is the fingerprint of listeners or objects that
      // survive a scene restart. The threshold is a smell test, not a proof.
      record('heap growth', growthMb > 50 ? 'warn' : 'pass',
        `${growthMb >= 0 ? '+' : ''}${growthMb.toFixed(1)} MB over the session ` +
        `(${(heapBefore / 1048576).toFixed(1)} → ${(heapAfter / 1048576).toFixed(1)} MB)` +
        (growthMb > 50 ? ' — check for listeners or objects surviving scene restarts' : ''));
    }

    // ── 6. Error surfaces (checked last so scenario errors are included) ──────
    log('');
    record('no uncaught exceptions', pageErrors.length === 0 ? 'pass' : 'fail',
      pageErrors.length ? pageErrors.map((e) => e.message).join(' | ') : 'none');
    record('no console errors', consoleErrors.length === 0 ? 'pass' : 'fail',
      consoleErrors.length ? consoleErrors.slice(0, 5).map((e) => e.text).join(' | ') : 'none');

    // Asset 404s are the single most common cause of an invisible-sprite bug.
    const assets404 = failedRequests.filter((r) => !/favicon/i.test(r.url));
    record('all assets load', assets404.length === 0 ? 'pass' : 'fail',
      assets404.length ? assets404.slice(0, 8).map((r) => `${r.reason} ${r.url}`).join(' | ') : 'no failed requests');

    if (consoleWarnings.length) {
      record('console warnings', opts.failOnWarn ? 'fail' : 'warn',
        consoleWarnings.slice(0, 5).map((w) => w.text).join(' | '));
    }

    report.pageErrors = pageErrors;
    report.consoleErrors = consoleErrors;
    report.consoleWarnings = consoleWarnings;
    report.failedRequests = assets404;
  } finally {
    if (opts.trace) {
      await context.tracing.stop({ path: path.join(opts.out, 'trace.zip') }).catch(() => {});
    }
    const videoPath = opts.video ? await page.video()?.path().catch(() => null) : null;
    await context.close().catch(() => {});
    await browser.close().catch(() => {});
    if (server) server.stop();
    if (opts.trace) log(`${C.dim}trace: npx playwright show-trace ${path.join(opts.out, 'trace.zip')}${C.off}`);
    if (videoPath) log(`${C.dim}video: ${videoPath}${C.off}`);
  }

  // ── Report ──────────────────────────────────────────────────────────────────
  const failed = checks.filter((c) => c.status === 'fail');
  const warned = checks.filter((c) => c.status === 'warn');
  report.checks = checks;
  report.summary = { passed: checks.filter((c) => c.status === 'pass').length, failed: failed.length, warnings: warned.length };
  report.finishedAt = new Date().toISOString();

  const reportPath = path.join(opts.out, 'report.json');
  fs.writeFileSync(reportPath, JSON.stringify(report, null, 2));

  if (opts.json) {
    console.log(JSON.stringify(report, null, 2));
  } else {
    log('\n==================================');
    log(`${report.summary.passed} passed, ${failed.length} failed, ${warned.length} warning(s)`);
    log(`Artifacts: ${path.relative(process.cwd(), opts.out)}/  (report.json + screenshots)`);
    if (failed.length) {
      log(`\n${C.red}Failures:${C.off}`);
      for (const f of failed) log(`  • ${f.name} — ${f.detail}`);
    }
    log('');
  }

  process.exit(failed.length ? 1 : 0);
}

main().catch((err) => {
  console.error(`\n${C.red}[HARNESS ERROR]${C.off} ${err.message}`);
  process.exit(2);
});

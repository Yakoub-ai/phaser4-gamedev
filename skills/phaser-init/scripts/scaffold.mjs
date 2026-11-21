#!/usr/bin/env node
/**
 * scaffold.mjs — create a verified Phaser 4 + TypeScript + Vite project.
 *
 * Deterministic and non-interactive: no prompts, no remote templates. The only network
 * access is `npm install` (skip it with --no-install). Refuses to overwrite any file.
 *
 * Usage:
 *   node scaffold.mjs <dir> [options]
 *
 * Options:
 *   --name NAME        npm package name (default: directory name, normalised)
 *   --title TEXT       Display title (default: derived from the name)
 *   --width N          Game width in px (default: 1280)
 *   --height N         Game height in px (default: 720)
 *   --physics KIND     arcade | matter | none (default: arcade)
 *   --pixel-art        Crisp scaling for pixel art (pixelArt: true)
 *   --no-ci            Skip the GitHub Actions workflows
 *   --no-install       Skip `npm install`
 *
 * Exit codes: 0 = created, 1 = refused (bad option or file conflict), 2 = install failed.
 */

import fs from 'node:fs';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { fileURLToPath } from 'node:url';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const TEMPLATE = path.resolve(HERE, '../template');
const HARNESS = path.resolve(HERE, '../../phaser-playtest/scripts/playtest.mjs');

const C = process.stdout.isTTY
  ? { red: '\x1b[31m', green: '\x1b[32m', yellow: '\x1b[33m', cyan: '\x1b[36m', dim: '\x1b[2m', off: '\x1b[0m' }
  : { red: '', green: '', yellow: '', cyan: '', dim: '', off: '' };
const fail = (msg) => { console.error(`${C.red}✗${C.off} ${msg}`); process.exit(1); };

// ── Options ───────────────────────────────────────────────────────────────────

function parseArgs(argv) {
  const o = { dir: null, name: null, title: null, width: 1280, height: 720, physics: 'arcade', pixelArt: false, ci: true, install: true };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    const val = () => { const v = argv[++i]; if (v === undefined) fail(`${a} needs a value`); return v; };
    if (a === '--name') o.name = val();
    else if (a === '--title') o.title = val();
    else if (a === '--width') o.width = Number(val());
    else if (a === '--height') o.height = Number(val());
    else if (a === '--physics') o.physics = val();
    else if (a === '--pixel-art') o.pixelArt = true;
    else if (a === '--no-ci') o.ci = false;
    else if (a === '--no-install') o.install = false;
    else if (a === '-h' || a === '--help') { console.log(fs.readFileSync(fileURLToPath(import.meta.url), 'utf8').split('*/')[0]); process.exit(0); }
    else if (a.startsWith('-')) fail(`unknown option ${a}`);
    else if (o.dir) fail(`unexpected argument ${a}`);
    else o.dir = a;
  }
  if (!o.dir) fail('usage: node scaffold.mjs <dir> [--physics arcade|matter|none] [--width N --height N] [--pixel-art]');
  o.dir = path.resolve(o.dir);
  o.name ??= path.basename(o.dir).toLowerCase().replace(/[^a-z0-9._-]+/g, '-').replace(/^[._-]+|[-]+$/g, '') || 'phaser-game';
  if (!/^[a-z0-9][a-z0-9._-]{0,213}$/.test(o.name)) fail(`invalid npm package name "${o.name}" (lowercase letters, digits, . _ - only)`);
  o.title ??= o.name.split(/[-._]+/).filter(Boolean).map((w) => w[0].toUpperCase() + w.slice(1)).join(' ');
  if (o.title.length > 80 || /[\u0000-\u001f]/.test(o.title)) fail('title must be at most 80 printable characters');
  for (const k of ['width', 'height']) if (!Number.isInteger(o[k]) || o[k] < 64 || o[k] > 8192) fail(`--${k} must be an integer between 64 and 8192`);
  if (!['arcade', 'matter', 'none'].includes(o.physics)) fail('--physics must be arcade, matter or none');
  return o;
}

const PHYSICS = {
  arcade: "  physics: {\n    default: 'arcade',\n    arcade: { gravity: { x: 0, y: 0 }, debug: false },\n  },\n",
  matter: "  physics: {\n    default: 'matter',\n    matter: { gravity: { x: 0, y: 1 }, debug: false },\n  },\n",
  none: '',
};

const relOrAbs = (p) => { const r = path.relative(process.cwd(), p); return !r ? '.' : r.startsWith('..') ? p : r; };
const escapeHtml =(s) => s.replace(/[&<>"']/g, (c) => ({ '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' })[c]);

// ── Plan the files ────────────────────────────────────────────────────────────

function walk(dir, base = dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((e) => {
    const full = path.join(dir, e.name);
    return e.isDirectory() ? walk(full, base) : [path.relative(base, full)];
  });
}

function plan(o) {
  const vars = {
    '{{NAME}}': o.name,
    '{{TITLE}}': escapeHtml(o.title),
    '{{TITLE_JS}}': JSON.stringify(o.title),
    '{{WIDTH}}': String(o.width),
    '{{HEIGHT}}': String(o.height),
    '{{PIXEL_ART}}': String(o.pixelArt),
    '{{PHYSICS}}': PHYSICS[o.physics],
  };
  const files = walk(TEMPLATE)
    .filter((rel) => o.ci || !rel.startsWith('.github'))
    .map((rel) => {
      let content = fs.readFileSync(path.join(TEMPLATE, rel), 'utf8');
      for (const [k, v] of Object.entries(vars)) content = content.split(k).join(v);
      const left = content.match(/\{\{[A-Z_]+\}\}/);
      if (left) fail(`template bug: unresolved ${left[0]} in ${rel}`);
      return { rel: rel === 'gitignore' ? '.gitignore' : rel, content };
    });
  // The harness is copied in so `npm run playtest` and CI work without the plugin.
  files.push({ rel: 'tools/playtest.mjs', content: fs.readFileSync(HARNESS, 'utf8') });
  return files;
}

// ── Main ──────────────────────────────────────────────────────────────────────

const o = parseArgs(process.argv.slice(2));
const files = plan(o);

const conflicts = files.filter((f) => fs.existsSync(path.join(o.dir, f.rel))).map((f) => f.rel);
if (conflicts.length) {
  fail(`refusing to overwrite existing files in ${o.dir}:\n  ${conflicts.join('\n  ')}\n` +
       'Scaffold into an empty directory, or move these aside first.');
}

for (const f of files) {
  const dest = path.join(o.dir, f.rel);
  fs.mkdirSync(path.dirname(dest), { recursive: true });
  fs.writeFileSync(dest, f.content);
}
console.log(`${C.green}✓${C.off} created ${files.length} files in ${o.dir}`);
console.log(`${C.dim}  ${o.title} · ${o.width}x${o.height} · physics: ${o.physics}${o.pixelArt ? ' · pixel art' : ''}${o.ci ? ' · CI' : ''}${C.off}`);

if (o.install) {
  console.log(`${C.cyan}→${C.off} npm install`);
  const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
  const r = spawnSync(npm, ['install', '--no-fund'], { cwd: o.dir, stdio: 'inherit', shell: process.platform === 'win32' });
  if (r.status !== 0) {
    console.error(`${C.red}✗${C.off} npm install failed — files are in place; fix the error and re-run npm install.`);
    process.exit(2);
  }
}

console.log(`
${C.green}Next:${C.off}
  cd ${relOrAbs(o.dir)}${o.install ? '' : '\n  npm install'}
  npm run dev              # play it
  npm run verify           # typecheck + unit tests + production-build playtest
`);

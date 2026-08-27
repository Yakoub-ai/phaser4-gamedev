/**
 * Example playtest scenario.
 *
 * Run with:
 *   node playtest.mjs --scenario examples/scenario.example.mjs
 *
 * Steps execute in order. Every `expression` and every `eval` `code` block runs inside
 * the page, with two bindings available:
 *
 *   game        the running Phaser.Game instance
 *   scene(key)  shorthand for game.scene.getScene(key)
 *
 * Actions:
 *   { action: 'wait',       ms }
 *   { action: 'key',        key, duration }         hold one key, then release
 *   { action: 'press',      key }                   single tap
 *   { action: 'hold',       keys: [], duration }    several keys at once (diagonals)
 *   { action: 'click',      x, y, button, count }   canvas-relative pixels
 *   { action: 'move',       x, y, steps }           pointer move, no click
 *   { action: 'drag',       from, to, steps, hold } press, glide, release
 *   { action: 'tap',        x, y }                  touch — needs --device
 *   { action: 'wheel',      dx, dy }
 *   { action: 'eval',       code }                  put the game into a given state
 *   { action: 'scene',      key, data, settle }     jump straight to a scene
 *   { action: 'waitFor',    expression, timeout }   poll until true
 *   { action: 'sample',     expression, duration, interval }   watch a value over time
 *   { action: 'repeat',     times, steps: [] }      run a block N times
 *   { action: 'screenshot', name }
 *   { action: 'expect' }                            assertion only, no interaction
 *
 * Assertions (any step may carry one):
 *   expect: { expression, equals }                  strict deep-equality
 *   expect: { expression, notEquals }
 *   expect: { expression, atLeast }                 >=
 *   expect: { expression, atMost }                  <=
 *   expect: { expression, above }                   >  (strict)
 *   expect: { expression, below }                   <  (strict)
 *   expect: { expression, within: { of, tolerance } }   use this for float positions
 *   expect: { expression, oneOf: [...] }
 *   expect: { expression, contains }                substring or array membership
 *   expect: { expression }                          truthy
 *
 * On a `sample` step, the expectation reads a statistic instead of an expression:
 *   expect: { stat: 'range', atLeast: 32 }
 *   stats: min max range mean stddev first last delta samples numeric
 */

export default [
  {
    name: 'game reaches GameScene',
    action: 'expect',
    expect: { expression: `game.scene.isActive('GameScene')`, equals: true },
  },
  {
    name: 'player exists at spawn',
    action: 'expect',
    expect: { expression: `scene('GameScene').player.x`, atLeast: 1 },
  },
  {
    name: 'hold right arrow',
    action: 'key',
    key: 'ArrowRight',
    duration: 600,
  },
  {
    name: 'player moved right',
    action: 'expect',
    expect: { expression: `scene('GameScene').player.x`, above: 400 },
  },
  {
    // Diagonals are their own input path. Plenty of "the controls feel wrong"
    // reports only reproduce with two keys held together.
    name: 'diagonal movement works',
    action: 'hold',
    keys: ['ArrowRight', 'ArrowUp'],
    duration: 500,
    expect: { expression: `scene('GameScene').player.y`, below: 300 },
  },
  {
    name: 'clicking scores points',
    action: 'click',
    x: 200,
    y: 200,
    expect: { expression: `scene('GameScene').score`, atLeast: 10 },
  },
  {
    // Skip the twenty minutes of play a report describes and set the state directly.
    name: 'set up the reported boss state',
    action: 'eval',
    code: `
      const s = scene('GameScene');
      s.player.hp = 1;
      s.spawnBoss();
    `,
  },
  {
    name: 'boss dies within 8s of the attack combo',
    action: 'repeat',
    times: 12,
    steps: [{ action: 'press', key: 'Space' }],
  },
  {
    name: 'boss actually died',
    action: 'waitFor',
    expression: `scene('GameScene').boss.hp <= 0`,
    timeout: 8000,
  },
  {
    // "Enemies sometimes get stuck" is a claim about variance over time,
    // which a single reading can neither confirm nor deny.
    name: 'enemy keeps moving, never wedges on a corner',
    action: 'sample',
    expression: `scene('GameScene').enemies[0].x`,
    duration: 4000,
    interval: 100,
    expect: { stat: 'range', atLeast: 32 },
  },
  {
    name: 'after-input',
    action: 'screenshot',
  },
  {
    name: 'frame rate holds up under input',
    action: 'expect',
    expect: { expression: `game.loop.actualFps`, atLeast: 30 },
  },
];

/**
 * Example playtest scenario.
 *
 * Run with:
 *   node playtest.mjs --scenario examples/scenario.example.mjs
 *
 * Each step is executed in order. `expect` assertions are evaluated in the page,
 * where `game` is bound to the running Phaser.Game instance.
 *
 * Actions:
 *   { action: 'wait',       ms }
 *   { action: 'key',        key, duration }   hold a key down, then release
 *   { action: 'press',      key }             single tap
 *   { action: 'click',      x, y }            canvas-relative pixel coordinates
 *   { action: 'screenshot', name }
 *   { action: 'expect' }                      assertion only, no interaction
 *
 * Assertions (any step may carry one):
 *   expect: { expression, equals }    strict deep-equality
 *   expect: { expression, atLeast }   numeric >=
 *   expect: { expression, atMost }    numeric <=
 *   expect: { expression }            truthy
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
    expect: { expression: `game.scene.getScene('GameScene').player.x`, atLeast: 1 },
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
    expect: { expression: `game.scene.getScene('GameScene').player.x > 400`, equals: true },
  },
  {
    name: 'clicking scores points',
    action: 'click',
    x: 200,
    y: 200,
    expect: { expression: `game.scene.getScene('GameScene').score`, atLeast: 10 },
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

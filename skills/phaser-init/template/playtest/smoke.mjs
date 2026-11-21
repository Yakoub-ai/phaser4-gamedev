// Smoke scenario: the full loop works, end to end. Run with `npm run playtest`
// (dev) or `npm run playtest:build` (production bundle). Add one scenario file per
// feature, turning each acceptance criterion into an `expect`.
export default [
  {
    name: 'reaches the main menu',
    action: 'waitFor',
    expression: `game.scene.isActive('MainMenuScene')`,
    timeout: 10000,
  },
  { name: 'start the game', action: 'press', key: 'Space' },
  {
    name: 'game scene is running',
    action: 'waitFor',
    expression: `game.scene.isActive('GameScene')`,
    timeout: 5000,
  },
  {
    name: 'player moves right when → is held',
    action: 'eval',
    code: `window.__startX = scene('GameScene').player.x`,
  },
  { name: 'hold right', action: 'key', key: 'ArrowRight', duration: 400 },
  {
    name: 'player moved right',
    action: 'expect',
    expect: { expression: `scene('GameScene').player.x - window.__startX`, above: 20 },
  },
  {
    name: 'collecting a pickup scores points',
    action: 'eval',
    code: `const s = scene('GameScene'); s.pickup.setPosition(s.player.x, s.player.y);`,
  },
  { name: 'let a frame run', action: 'wait', ms: 200 },
  {
    name: 'score increased',
    action: 'expect',
    expect: { expression: `scene('GameScene').score`, atLeast: 10 },
  },
  {
    name: 'round ends when the clock runs out',
    action: 'eval',
    code: `scene('GameScene').timeLeft = 1`,
  },
  {
    name: 'game over is shown',
    action: 'waitFor',
    expression: `game.scene.isActive('GameOverScene')`,
    timeout: 3000,
  },
  { name: 'game-over', action: 'screenshot' },
];

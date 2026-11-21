import Phaser from 'phaser';
import './style.css';
import { BootScene } from './scenes/BootScene';
import { PreloaderScene } from './scenes/PreloaderScene';
import { MainMenuScene } from './scenes/MainMenuScene';
import { GameScene } from './scenes/GameScene';
import { GameOverScene } from './scenes/GameOverScene';

const config: Phaser.Types.Core.GameConfig = {
  type: Phaser.AUTO,
  parent: 'game-container',
  width: {{WIDTH}},
  height: {{HEIGHT}},
  backgroundColor: '#1d1d2b',
  pixelArt: {{PIXEL_ART}},
  scale: {
    mode: Phaser.Scale.FIT,
    autoCenter: Phaser.Scale.CENTER_BOTH,
  },
{{PHYSICS}}  scene: [BootScene, PreloaderScene, MainMenuScene, GameScene, GameOverScene],
};

const game = new Phaser.Game(config);

// Exposes the game to the playtest harness. Present in dev and in playtest builds
// (VITE_PLAYTEST is set only by the harness); absent from the bundle you ship.
if (import.meta.env.DEV || import.meta.env.VITE_PLAYTEST === 'true') {
  (window as unknown as { __PHASER_GAME__: Phaser.Game }).__PHASER_GAME__ = game;
}

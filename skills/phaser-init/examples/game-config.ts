// src/main.ts — Complete Phaser 4 GameConfig with TypeScript
import Phaser from 'phaser';
import { BootScene } from './scenes/BootScene';
import { PreloaderScene } from './scenes/PreloaderScene';
import { MainMenuScene } from './scenes/MainMenuScene';
import { GameScene } from './scenes/GameScene';
import { HUDScene } from './scenes/HUDScene';
import { GameOverScene } from './scenes/GameOverScene';

const config: Phaser.Types.Core.GameConfig = {
  // Renderer: AUTO uses Phaser Beam WebGL, falls back to Canvas
  // WEBGL: force WebGL only (fail if unavailable)
  // CANVAS: force Canvas (slower, no shaders/filters)
  type: Phaser.AUTO,

  // Canvas dimensions
  width: 800,
  height: 600,

  // DOM element to inject canvas into (must have matching id in HTML)
  parent: 'game-container',

  // Background color (shown before first scene renders)
  backgroundColor: '#1d1d2b',

  // For pixel art games: prevents anti-aliasing
  // pixelArt: true,
  // roundPixels: true,

  // Responsive scaling
  scale: {
    mode: Phaser.Scale.FIT,            // Scale to fit container, maintain aspect ratio
    autoCenter: Phaser.Scale.CENTER_BOTH, // Center horizontally and vertically
    // For pixel art: use Phaser.Scale.ZOOM_2X or INTEGER_ROUND
  },

  // Arcade physics (fast AABB simulation)
  physics: {
    default: 'arcade',
    arcade: {
      gravity: { x: 0, y: 300 },  // World gravity (pixels/second²)
      debug: true,                  // Show body outlines (set false for production!)
      // fps: 60,                   // Physics FPS (default matches game FPS)
      // timeScale: 1,              // Slow motion: 0.5, fast forward: 2
    },
  },

  // Scenes: loaded in order, first one starts automatically
  scene: [BootScene, PreloaderScene, MainMenuScene, GameScene, HUDScene, GameOverScene],
};

// Create and export the game instance
export default new Phaser.Game(config);

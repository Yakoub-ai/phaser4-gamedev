// src/scenes/BootScene.ts — Minimal first scene
// Purpose: Load ONLY the assets needed for the loading bar, then hand off to PreloaderScene.
// Keep this as small/fast as possible so the game appears to "start" immediately.
import Phaser from 'phaser';

export class BootScene extends Phaser.Scene {
  constructor() {
    super({ key: 'BootScene' });
  }

  preload(): void {
    // Only load what the PreloaderScene's UI needs:
    // - A loading bar background image (or skip and draw with Graphics)
    // - A logo or splash image (optional)

    // Example (comment out if not needed):
    // this.load.image('loading-bar-bg', 'assets/ui/loading-bar-bg.png');
    // this.load.image('loading-bar-fill', 'assets/ui/loading-bar-fill.png');
  }

  create(): void {
    // Immediately transition to PreloaderScene
    // The real asset loading happens there
    this.scene.start('PreloaderScene');
  }
}

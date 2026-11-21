import Phaser from 'phaser';

/** Loads only what the loading screen itself needs, then hands off. Keep it tiny. */
export class BootScene extends Phaser.Scene {
  constructor() {
    super('BootScene');
  }

  create(): void {
    this.scene.start('PreloaderScene');
  }
}

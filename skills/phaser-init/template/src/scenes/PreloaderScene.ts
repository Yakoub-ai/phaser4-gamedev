import Phaser from 'phaser';

/** Loads every asset with a progress bar, then builds placeholder textures. */
export class PreloaderScene extends Phaser.Scene {
  constructor() {
    super('PreloaderScene');
  }

  preload(): void {
    const { width, height } = this.scale;
    const barWidth = width * 0.5;
    this.add.rectangle(width / 2, height / 2, barWidth + 4, 24).setStrokeStyle(2, 0xffffff);
    const bar = this.add.rectangle(width / 2 - barWidth / 2, height / 2, 0, 18, 0xffffff).setOrigin(0, 0.5);
    this.load.on('progress', (p: number) => { bar.width = barWidth * p; });

    // Real assets go in public/assets/ and load by relative path, e.g.:
    // this.load.image('player', 'assets/player.png');
  }

  create(): void {
    // Placeholder art so the game runs before any real assets exist.
    // Replace each texture key with a real asset of the same key.
    this.makeRect('player', 32, 32, 0x4fc3f7);
    this.makeRect('pickup', 16, 16, 0xffd54f);
    this.scene.start('MainMenuScene');
  }

  private makeRect(key: string, w: number, h: number, color: number): void {
    if (this.textures.exists(key)) return;
    const g = this.add.graphics();
    g.fillStyle(color, 1).fillRect(0, 0, w, h);
    g.generateTexture(key, w, h);
    g.destroy();
  }
}

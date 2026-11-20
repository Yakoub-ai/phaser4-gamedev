import Phaser from 'phaser';

export class MainMenuScene extends Phaser.Scene {
  constructor() {
    super('MainMenuScene');
  }

  create(): void {
    const { width, height } = this.scale;
    this.add.text(width / 2, height * 0.35, {{TITLE_JS}}, { fontFamily: 'sans-serif', fontSize: '48px', color: '#ffffff' })
      .setOrigin(0.5);

    const play = this.add.text(width / 2, height * 0.6, 'PLAY', { fontFamily: 'sans-serif', fontSize: '32px', color: '#ffd54f' })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true });

    const start = () => this.scene.start('GameScene');
    play.once('pointerdown', start);
    this.input.keyboard?.once('keydown-SPACE', start);
    this.input.keyboard?.once('keydown-ENTER', start);
  }
}

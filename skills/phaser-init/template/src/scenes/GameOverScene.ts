import Phaser from 'phaser';
import { isBetterScore } from '../logic/score';

const BEST_KEY = '{{NAME}}:best';

export class GameOverScene extends Phaser.Scene {
  best: number | null = null;

  constructor() {
    super('GameOverScene');
  }

  create(data: { score?: number }): void {
    const score = data.score ?? 0;
    this.best = readBest();
    if (isBetterScore(score, this.best)) {
      this.best = score;
      writeBest(score);
    }

    const { width, height } = this.scale;
    const style = { fontFamily: 'sans-serif', fontSize: '32px', color: '#ffffff' };
    this.add.text(width / 2, height * 0.35, 'GAME OVER', { ...style, fontSize: '48px' }).setOrigin(0.5);
    this.add.text(width / 2, height * 0.5, `Score: ${score}   Best: ${this.best}`, style).setOrigin(0.5);
    this.add.text(width / 2, height * 0.68, 'Click or press SPACE', { ...style, fontSize: '20px', color: '#ffd54f' })
      .setOrigin(0.5);

    const back = () => this.scene.start('MainMenuScene');
    this.input.once('pointerdown', back);
    this.input.keyboard?.once('keydown-SPACE', back);
  }
}

// localStorage throws in some private modes and sandboxed iframes: never let that crash the game.
function readBest(): number | null {
  try {
    const raw = localStorage.getItem(BEST_KEY);
    const n = raw === null ? NaN : Number(raw);
    return Number.isFinite(n) ? n : null;
  } catch {
    return null;
  }
}

function writeBest(score: number): void {
  try {
    localStorage.setItem(BEST_KEY, String(score));
  } catch {
    /* storage unavailable — best score just won't persist */
  }
}

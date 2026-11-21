import Phaser from 'phaser';
import { addScore, PICKUP_POINTS, ROUND_SECONDS } from '../logic/score';

const PLAYER_SPEED = 240; // px per second

/**
 * Starter loop: move (arrows / WASD / hold pointer), collect pickups, beat the clock.
 * Replace it with your game. Fields are public so playtest scenarios can assert on them.
 */
export class GameScene extends Phaser.Scene {
  player!: Phaser.GameObjects.Image;
  pickup!: Phaser.GameObjects.Image;
  score = 0;
  timeLeft = ROUND_SECONDS;

  private cursors?: Phaser.Types.Input.Keyboard.CursorKeys;
  private wasd?: Record<'W' | 'A' | 'S' | 'D', Phaser.Input.Keyboard.Key>;
  private scoreText!: Phaser.GameObjects.Text;
  private timerText!: Phaser.GameObjects.Text;

  constructor() {
    super('GameScene');
  }

  create(): void {
    // Scene instances are reused across restarts: reset state here, not in field initialisers.
    this.score = 0;
    this.timeLeft = ROUND_SECONDS;

    const { width, height } = this.scale;
    this.player = this.add.image(width / 2, height / 2, 'player');
    this.pickup = this.add.image(0, 0, 'pickup');
    this.placePickup();

    this.cursors = this.input.keyboard?.createCursorKeys();
    this.wasd = this.input.keyboard?.addKeys('W,A,S,D') as GameScene['wasd'];

    const style = { fontFamily: 'sans-serif', fontSize: '24px', color: '#ffffff' };
    this.scoreText = this.add.text(16, 16, '', style);
    this.timerText = this.add.text(width - 16, 16, '', style).setOrigin(1, 0);
    this.refreshHud();

    this.time.addEvent({
      delay: 1000,
      loop: true,
      callback: () => {
        this.timeLeft -= 1;
        this.refreshHud();
        if (this.timeLeft <= 0) this.scene.start('GameOverScene', { score: this.score });
      },
    });
  }

  update(_time: number, delta: number): void {
    const dir = this.readInput();
    const step = (PLAYER_SPEED * delta) / 1000;
    const { width, height } = this.scale;
    this.player.x = Phaser.Math.Clamp(this.player.x + dir.x * step, 0, width);
    this.player.y = Phaser.Math.Clamp(this.player.y + dir.y * step, 0, height);

    if (Phaser.Geom.Intersects.RectangleToRectangle(this.player.getBounds(), this.pickup.getBounds())) {
      this.score = addScore(this.score, PICKUP_POINTS);
      this.refreshHud();
      this.placePickup();
    }
  }

  private readInput(): Phaser.Math.Vector2 {
    const dir = new Phaser.Math.Vector2(0, 0);
    const k = this.cursors;
    const w = this.wasd;
    if (k?.left.isDown || w?.A.isDown) dir.x -= 1;
    if (k?.right.isDown || w?.D.isDown) dir.x += 1;
    if (k?.up.isDown || w?.W.isDown) dir.y -= 1;
    if (k?.down.isDown || w?.S.isDown) dir.y += 1;

    // Touch / mouse: move toward a held pointer.
    const p = this.input.activePointer;
    if (dir.lengthSq() === 0 && p.isDown) {
      dir.set(p.worldX - this.player.x, p.worldY - this.player.y);
      if (dir.length() < 4) dir.set(0, 0);
    }
    return dir.normalize();
  }

  private placePickup(): void {
    const { width, height } = this.scale;
    this.pickup.setPosition(Phaser.Math.Between(32, width - 32), Phaser.Math.Between(64, height - 32));
  }

  private refreshHud(): void {
    this.scoreText.setText(`Score: ${this.score}`);
    this.timerText.setText(`Time: ${this.timeLeft}`);
  }
}

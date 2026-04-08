# Phaser 4 UI Patterns — Detailed Reference

Production-ready component classes. Each is self-contained and can be dropped into any Phaser 4 project.

---

## 1. HealthBar — Animated with Color Transitions

Features: green→yellow→red color transitions, animated bar-width tween on damage, `takeDamage` and `heal` helpers.

```typescript
interface HealthBarConfig {
  x: number;
  y: number;
  width?: number;
  height?: number;
  maxHealth: number;
  depth?: number;
}

class HealthBar {
  private bar: Phaser.GameObjects.Graphics;
  private scene: Phaser.Scene;
  private x: number;
  private y: number;
  private width: number;
  private height: number;
  private maxHealth: number;
  private health: number;
  /** Displayed ratio — tweened separately from this.health for animation */
  private displayRatio: number;
  private tween?: Phaser.Tweens.Tween;

  constructor(scene: Phaser.Scene, config: HealthBarConfig) {
    this.scene = scene;
    this.x = config.x;
    this.y = config.y;
    this.width = config.width ?? 200;
    this.height = config.height ?? 20;
    this.maxHealth = config.maxHealth;
    this.health = config.maxHealth;
    this.displayRatio = 1;

    this.bar = scene.add.graphics()
      .setScrollFactor(0)
      .setDepth(config.depth ?? 100);

    this.draw();
  }

  get currentHealth(): number {
    return this.health;
  }

  setHealth(value: number): void {
    const clamped = Phaser.Math.Clamp(value, 0, this.maxHealth);
    const targetRatio = clamped / this.maxHealth;
    this.health = clamped;

    // Cancel any in-progress tween
    this.tween?.stop();

    // Tween the display ratio for a smooth bar-shrink effect
    this.tween = this.scene.tweens.add({
      targets: this,
      displayRatio: targetRatio,
      duration: 300,
      ease: 'Sine.easeOut',
      onUpdate: () => this.draw(),
    });
  }

  takeDamage(amount: number): void {
    this.setHealth(this.health - amount);
  }

  heal(amount: number): void {
    this.setHealth(this.health + amount);
  }

  private draw(): void {
    this.bar.clear();

    // Dark border/background
    this.bar.fillStyle(0x000000, 0.6);
    this.bar.fillRect(this.x - 2, this.y - 2, this.width + 4, this.height + 4);

    // Gray empty track
    this.bar.fillStyle(0x444444, 0.8);
    this.bar.fillRect(this.x, this.y, this.width, this.height);

    // Colored fill
    const r = this.displayRatio;
    const color = r > 0.5 ? 0x00cc44 : r > 0.25 ? 0xffcc00 : 0xff2222;
    this.bar.fillStyle(color, 1);
    this.bar.fillRect(this.x, this.y, Math.max(0, this.width * r), this.height);
  }

  setPosition(x: number, y: number): void {
    this.x = x;
    this.y = y;
    this.draw();
  }

  destroy(): void {
    this.tween?.stop();
    this.bar.destroy();
  }
}

// Usage:
const hp = new HealthBar(this, { x: 16, y: 16, maxHealth: 100 });
hp.takeDamage(35);   // bar animates from full to 65%
hp.heal(10);         // bar animates up to 75%
hp.setHealth(0);     // bar animates to empty (red)
```

---

## 2. Button — Container-based with Hover/Active/Disabled States

Extends `Phaser.GameObjects.Container`. Wraps a background (Graphics or Image) and a Text label. Emits a `'click'` event. Accepts a typed `ButtonConfig`.

```typescript
interface ButtonConfig {
  x: number;
  y: number;
  label: string;
  width?: number;
  height?: number;
  fontSize?: string;
  /** Fill color for normal state */
  colorNormal?: number;
  /** Fill color when hovered */
  colorHover?: number;
  /** Fill color when pressed */
  colorActive?: number;
  depth?: number;
  disabled?: boolean;
}

class Button extends Phaser.GameObjects.Container {
  private bg: Phaser.GameObjects.Graphics;
  private label: Phaser.GameObjects.Text;
  private config: Required<ButtonConfig>;
  private _disabled: boolean;

  constructor(scene: Phaser.Scene, config: ButtonConfig) {
    super(scene, config.x, config.y);
    scene.add.existing(this);

    this.config = {
      width: 200,
      height: 50,
      fontSize: '24px',
      colorNormal: 0x3355aa,
      colorHover: 0x4477cc,
      colorActive: 0x223388,
      depth: 100,
      disabled: false,
      ...config,
    };

    this._disabled = this.config.disabled;

    this.bg = scene.add.graphics();
    this.label = scene.add.text(0, 0, config.label, {
      fontSize: this.config.fontSize,
      color: '#ffffff',
    }).setOrigin(0.5);

    this.add([this.bg, this.label]);
    this.setDepth(this.config.depth);
    this.setScrollFactor(0);
    this.drawBg(this.config.colorNormal);

    if (!this._disabled) {
      this.setInteractive(
        new Phaser.Geom.Rectangle(
          -this.config.width / 2,
          -this.config.height / 2,
          this.config.width,
          this.config.height,
        ),
        Phaser.Geom.Rectangle.Contains,
      );
      this.bindEvents();
    } else {
      this.drawBg(0x555555);
      this.label.setStyle({ color: '#999999' });
    }
  }

  private drawBg(color: number, alpha = 1): void {
    const { width, height } = this.config;
    this.bg.clear();
    this.bg.fillStyle(color, alpha);
    this.bg.fillRoundedRect(-width / 2, -height / 2, width, height, 10);
    this.bg.lineStyle(2, 0xffffff, 0.3);
    this.bg.strokeRoundedRect(-width / 2, -height / 2, width, height, 10);
  }

  private bindEvents(): void {
    this
      .on('pointerover', () => {
        this.drawBg(this.config.colorHover);
        this.scene.input.setDefaultCursor('pointer');
      })
      .on('pointerout', () => {
        this.drawBg(this.config.colorNormal);
        this.scene.input.setDefaultCursor('default');
        this.setScale(1);
      })
      .on('pointerdown', () => {
        this.drawBg(this.config.colorActive);
        this.setScale(0.96);
      })
      .on('pointerup', () => {
        this.drawBg(this.config.colorHover);
        this.setScale(1);
        this.emit('click');
      });
  }

  setDisabled(disabled: boolean): void {
    this._disabled = disabled;
    if (disabled) {
      this.disableInteractive();
      this.drawBg(0x555555);
      this.label.setStyle({ color: '#999999' });
    } else {
      this.setInteractive(
        new Phaser.Geom.Rectangle(
          -this.config.width / 2,
          -this.config.height / 2,
          this.config.width,
          this.config.height,
        ),
        Phaser.Geom.Rectangle.Contains,
      );
      this.drawBg(this.config.colorNormal);
      this.label.setStyle({ color: '#ffffff' });
    }
  }

  setText(text: string): void {
    this.label.setText(text);
  }
}

// Usage:
const playBtn = new Button(this, {
  x: 400, y: 300, label: 'PLAY', width: 180, height: 54,
});
playBtn.on('click', () => this.scene.start('GameScene'));

const lockedBtn = new Button(this, {
  x: 400, y: 380, label: 'LOCKED', disabled: true,
});
// Later:
lockedBtn.setDisabled(false);
```

---

## 3. DialogBox — Animated Appear/Disappear

Optional title, message body, up to two buttons (OK / Cancel pattern). Scales in from 0 on open, scales out on close.

```typescript
interface DialogConfig {
  message: string;
  title?: string;
  okLabel?: string;
  cancelLabel?: string;
  onOk?: () => void;
  onCancel?: () => void;
  width?: number;
  height?: number;
  depth?: number;
}

class DialogBox extends Phaser.GameObjects.Container {
  constructor(scene: Phaser.Scene, config: DialogConfig) {
    const cx = scene.scale.width / 2;
    const cy = scene.scale.height / 2;
    super(scene, cx, cy);
    scene.add.existing(this);

    const w = config.width ?? 420;
    const h = config.height ?? 220;
    const depth = config.depth ?? 200;
    const hasCancel = !!config.cancelLabel;

    this.setDepth(depth).setScrollFactor(0).setScale(0); // start collapsed

    // Semi-transparent screen overlay
    const overlay = scene.add.rectangle(0, 0, scene.scale.width * 2, scene.scale.height * 2, 0x000000, 0.45)
      .setInteractive(); // blocks clicks behind dialog
    this.add(overlay);

    // Panel background
    const panel = scene.add.graphics();
    panel.fillStyle(0x1a1a3a, 0.97);
    panel.fillRoundedRect(-w / 2, -h / 2, w, h, 14);
    panel.lineStyle(2, 0x5566bb, 1);
    panel.strokeRoundedRect(-w / 2, -h / 2, w, h, 14);
    this.add(panel);

    let textOffsetY = 10;

    // Optional title
    if (config.title) {
      const titleText = scene.add.text(0, -h / 2 + 30, config.title, {
        fontSize: '22px',
        color: '#aaccff',
        fontStyle: 'bold',
      }).setOrigin(0.5);
      this.add(titleText);
      textOffsetY = 20;
    }

    // Message
    const msgText = scene.add.text(0, -20 + (config.title ? 0 : -10), config.message, {
      fontSize: '18px',
      color: '#ffffff',
      wordWrap: { width: w - 60 },
      align: 'center',
    }).setOrigin(0.5);
    this.add(msgText);

    // Buttons
    const btnY = h / 2 - 40;
    const okX = hasCancel ? 70 : 0;

    const okBtn = scene.add.text(okX, btnY, config.okLabel ?? 'OK', {
      fontSize: '18px',
      backgroundColor: '#3366aa',
      padding: { x: 24, y: 8 },
    })
      .setOrigin(0.5)
      .setInteractive({ useHandCursor: true })
      .on('pointerover', () => okBtn.setStyle({ backgroundColor: '#4488cc' }))
      .on('pointerout',  () => okBtn.setStyle({ backgroundColor: '#3366aa' }))
      .on('pointerup',   () => this.close(() => config.onOk?.()));
    this.add(okBtn);

    if (hasCancel) {
      const cancelBtn = scene.add.text(-70, btnY, config.cancelLabel!, {
        fontSize: '18px',
        backgroundColor: '#663333',
        padding: { x: 24, y: 8 },
      })
        .setOrigin(0.5)
        .setInteractive({ useHandCursor: true })
        .on('pointerover', () => cancelBtn.setStyle({ backgroundColor: '#884444' }))
        .on('pointerout',  () => cancelBtn.setStyle({ backgroundColor: '#663333' }))
        .on('pointerup',   () => this.close(() => config.onCancel?.()));
      this.add(cancelBtn);
    }

    // Animate in
    scene.tweens.add({
      targets: this,
      scale: 1,
      duration: 200,
      ease: 'Back.easeOut',
    });
  }

  private close(callback?: () => void): void {
    this.scene.tweens.add({
      targets: this,
      scale: 0,
      duration: 150,
      ease: 'Back.easeIn',
      onComplete: () => {
        this.destroy();
        callback?.();
      },
    });
  }
}

// Usage:
new DialogBox(this, {
  title: 'Quit Game?',
  message: 'Your progress will not be saved.',
  okLabel: 'Quit',
  cancelLabel: 'Cancel',
  onOk: () => this.scene.start('MainMenuScene'),
});

new DialogBox(this, {
  message: 'Level complete! You earned 500 XP.',
  onOk: () => this.scene.start('NextLevelScene'),
});
```

---

## 4. FloatingText — Damage Numbers and Pickup Notifications

Creates a BitmapText (or fallback Text) at a world position, tweens it upward while fading out, then destroys itself. Use for damage numbers, XP gains, item pickups, combo text.

```typescript
interface FloatingTextConfig {
  x: number;
  y: number;
  text: string;
  color?: string;
  fontSize?: string;
  /** Use BitmapText if a font key is provided, else Phaser.GameObjects.Text */
  bitmapFont?: string;
  bitmapFontSize?: number;
  duration?: number;
  riseDistance?: number;
  depth?: number;
}

function spawnFloatingText(scene: Phaser.Scene, config: FloatingTextConfig): void {
  const duration = config.duration ?? 900;
  const rise = config.riseDistance ?? 60;
  const depth = config.depth ?? 150;

  let obj: Phaser.GameObjects.Text | Phaser.GameObjects.BitmapText;

  if (config.bitmapFont) {
    obj = scene.add.bitmapText(
      config.x, config.y,
      config.bitmapFont,
      config.text,
      config.bitmapFontSize ?? 28,
    );
  } else {
    obj = scene.add.text(config.x, config.y, config.text, {
      fontSize: config.fontSize ?? '22px',
      color: config.color ?? '#ffffff',
      stroke: '#000000',
      strokeThickness: 3,
    }).setOrigin(0.5);
  }

  obj.setDepth(depth);

  // Small horizontal drift for variety
  const driftX = Phaser.Math.Between(-20, 20);

  scene.tweens.add({
    targets: obj,
    x: obj.x + driftX,
    y: obj.y - rise,
    alpha: 0,
    scaleX: 1.3,
    scaleY: 1.3,
    duration,
    ease: 'Sine.easeOut',
    onComplete: () => obj.destroy(),
  });
}

// Convenience wrappers:
function showDamage(scene: Phaser.Scene, x: number, y: number, amount: number): void {
  spawnFloatingText(scene, {
    x, y,
    text: `-${amount}`,
    color: '#ff4444',
    fontSize: '28px',
  });
}

function showHeal(scene: Phaser.Scene, x: number, y: number, amount: number): void {
  spawnFloatingText(scene, {
    x, y,
    text: `+${amount}`,
    color: '#44ff88',
    fontSize: '24px',
  });
}

function showPickup(scene: Phaser.Scene, x: number, y: number, label: string): void {
  spawnFloatingText(scene, {
    x, y,
    text: label,
    color: '#ffdd44',
    fontSize: '20px',
    riseDistance: 80,
    duration: 1200,
  });
}

// Usage:
showDamage(this, enemy.x, enemy.y - 20, 47);
showHeal(this, player.x, player.y - 20, 25);
showPickup(this, coin.x, coin.y, '+50 Gold');
```

---

## 5. Panel (Nine-Slice Simulation via Graphics)

Phaser 4 does not have built-in nine-slice support. Use a `Graphics`-based rounded rectangle for UI panel backgrounds. Pair with a `Container` to group child elements.

```typescript
interface PanelConfig {
  x: number;
  y: number;
  width: number;
  height: number;
  fillColor?: number;
  fillAlpha?: number;
  borderColor?: number;
  borderWidth?: number;
  radius?: number;
  depth?: number;
  scrollFactor?: number;
}

class Panel extends Phaser.GameObjects.Container {
  private bg: Phaser.GameObjects.Graphics;
  readonly panelWidth: number;
  readonly panelHeight: number;

  constructor(scene: Phaser.Scene, config: PanelConfig) {
    super(scene, config.x, config.y);
    scene.add.existing(this);

    this.panelWidth = config.width;
    this.panelHeight = config.height;

    const fillColor  = config.fillColor  ?? 0x111122;
    const fillAlpha  = config.fillAlpha  ?? 0.92;
    const borderColor = config.borderColor ?? 0x4455aa;
    const borderWidth = config.borderWidth ?? 2;
    const radius     = config.radius     ?? 12;

    this.bg = scene.add.graphics();
    this.bg.fillStyle(fillColor, fillAlpha);
    this.bg.fillRoundedRect(
      -config.width / 2, -config.height / 2,
      config.width, config.height, radius,
    );
    this.bg.lineStyle(borderWidth, borderColor, 1);
    this.bg.strokeRoundedRect(
      -config.width / 2, -config.height / 2,
      config.width, config.height, radius,
    );

    this.add(this.bg);
    this.setDepth(config.depth ?? 100);
    this.setScrollFactor(config.scrollFactor ?? 0);
  }

  /** Add a title text to the top of the panel */
  addTitle(text: string, style?: Phaser.Types.GameObjects.Text.TextStyle): this {
    const title = this.scene.add.text(0, -this.panelHeight / 2 + 24, text, {
      fontSize: '20px',
      color: '#aabbff',
      ...style,
    }).setOrigin(0.5);
    this.add(title);
    return this;
  }

  /** Add a horizontal divider line below the title */
  addDivider(yOffset = -this.panelHeight / 2 + 46): this {
    const line = this.scene.add.graphics();
    line.lineStyle(1, 0x445588, 0.7);
    line.lineBetween(-this.panelWidth / 2 + 12, yOffset, this.panelWidth / 2 - 12, yOffset);
    this.add(line);
    return this;
  }
}

// Usage:
const settingsPanel = new Panel(this, { x: 400, y: 300, width: 380, height: 260 })
  .addTitle('Settings')
  .addDivider();

// Add children relative to panel center:
const volumeLabel = this.add.text(-160, -40, 'Volume', { fontSize: '18px', color: '#ffffff' });
settingsPanel.add(volumeLabel);
```

---

## 6. InventoryGrid — Slot-based Container

A `Container`-based inventory grid. Displays item slots as `Graphics` rectangles, accepts item texture keys, highlights the selected slot, and emits a `'slotSelected'` event with the slot index.

```typescript
interface InventoryItem {
  textureKey: string;
  frameKey?: string | number;
  quantity?: number;
}

interface InventoryGridConfig {
  x: number;
  y: number;
  cols: number;
  rows: number;
  slotSize?: number;
  padding?: number;
  depth?: number;
}

class InventoryGrid extends Phaser.GameObjects.Container {
  private slots: Phaser.GameObjects.Graphics[] = [];
  private itemImages: (Phaser.GameObjects.Image | null)[] = [];
  private quantityLabels: (Phaser.GameObjects.Text | null)[] = [];
  private selectedIndex = -1;
  private items: (InventoryItem | null)[];
  private cfg: Required<InventoryGridConfig>;

  constructor(scene: Phaser.Scene, config: InventoryGridConfig) {
    super(scene, config.x, config.y);
    scene.add.existing(this);

    this.cfg = {
      slotSize: 56,
      padding: 6,
      depth: 100,
      ...config,
    };

    const total = config.cols * config.rows;
    this.items = new Array(total).fill(null);

    this.setDepth(this.cfg.depth).setScrollFactor(0);
    this.buildGrid();
  }

  private buildGrid(): void {
    const { cols, rows, slotSize, padding } = this.cfg;
    const step = slotSize + padding;
    const totalW = cols * step - padding;
    const totalH = rows * step - padding;
    const startX = -totalW / 2 + slotSize / 2;
    const startY = -totalH / 2 + slotSize / 2;

    for (let row = 0; row < rows; row++) {
      for (let col = 0; col < cols; col++) {
        const idx = row * cols + col;
        const sx = startX + col * step;
        const sy = startY + row * step;

        const slot = this.scene.add.graphics();
        this.drawSlot(slot, sx, sy, false);
        slot.setInteractive(
          new Phaser.Geom.Rectangle(sx - slotSize / 2, sy - slotSize / 2, slotSize, slotSize),
          Phaser.Geom.Rectangle.Contains,
        );
        slot.on('pointerup', () => this.selectSlot(idx));
        slot.on('pointerover', () => {
          if (this.selectedIndex !== idx) this.drawSlot(slot, sx, sy, false, true);
        });
        slot.on('pointerout', () => {
          if (this.selectedIndex !== idx) this.drawSlot(slot, sx, sy, false, false);
        });

        this.slots.push(slot);
        this.itemImages.push(null);
        this.quantityLabels.push(null);
        this.add(slot);
      }
    }
  }

  private drawSlot(
    gfx: Phaser.GameObjects.Graphics,
    x: number, y: number,
    selected: boolean,
    hovered = false,
  ): void {
    const s = this.cfg.slotSize;
    gfx.clear();
    const bg = selected ? 0x3355bb : hovered ? 0x2a2a4a : 0x1a1a2e;
    const border = selected ? 0x88aaff : 0x334466;
    gfx.fillStyle(bg, 0.9);
    gfx.fillRoundedRect(x - s / 2, y - s / 2, s, s, 6);
    gfx.lineStyle(selected ? 2 : 1, border, 1);
    gfx.strokeRoundedRect(x - s / 2, y - s / 2, s, s, 6);
  }

  private slotPosition(index: number): { x: number; y: number } {
    const { cols, slotSize, padding } = this.cfg;
    const step = slotSize + padding;
    const totalW = cols * step - padding;
    const totalH = (Math.ceil(this.items.length / cols)) * step - padding;
    const startX = -totalW / 2 + slotSize / 2;
    const startY = -totalH / 2 + slotSize / 2;
    const col = index % cols;
    const row = Math.floor(index / cols);
    return { x: startX + col * step, y: startY + row * step };
  }

  selectSlot(index: number): void {
    // Deselect previous
    if (this.selectedIndex >= 0 && this.selectedIndex < this.slots.length) {
      const prev = this.slots[this.selectedIndex];
      const pos = this.slotPosition(this.selectedIndex);
      this.drawSlot(prev, pos.x, pos.y, false);
    }

    this.selectedIndex = index;
    const slot = this.slots[index];
    const pos = this.slotPosition(index);
    this.drawSlot(slot, pos.x, pos.y, true);

    this.emit('slotSelected', index, this.items[index]);
  }

  setItem(index: number, item: InventoryItem | null): void {
    if (index < 0 || index >= this.items.length) return;

    this.items[index] = item;

    // Remove existing image/label
    this.itemImages[index]?.destroy();
    this.quantityLabels[index]?.destroy();
    this.itemImages[index] = null;
    this.quantityLabels[index] = null;

    if (!item) return;

    const pos = this.slotPosition(index);
    const img = this.scene.add.image(pos.x, pos.y, item.textureKey, item.frameKey);
    const scale = (this.cfg.slotSize * 0.72) / Math.max(img.width, img.height);
    img.setScale(scale);
    this.itemImages[index] = img;
    this.add(img);

    if (item.quantity !== undefined && item.quantity > 1) {
      const s = this.cfg.slotSize;
      const label = this.scene.add.text(
        pos.x + s / 2 - 4,
        pos.y + s / 2 - 4,
        String(item.quantity),
        { fontSize: '13px', color: '#ffffff', stroke: '#000000', strokeThickness: 2 },
      ).setOrigin(1, 1);
      this.quantityLabels[index] = label;
      this.add(label);
    }
  }

  getItem(index: number): InventoryItem | null {
    return this.items[index] ?? null;
  }

  getSelectedItem(): InventoryItem | null {
    return this.selectedIndex >= 0 ? this.items[this.selectedIndex] ?? null : null;
  }

  /** Swap two item slots */
  swapItems(indexA: number, indexB: number): void {
    const tmp = this.items[indexA];
    this.setItem(indexA, this.items[indexB]);
    this.setItem(indexB, tmp);
  }
}

// Usage:
const inventory = new InventoryGrid(this, {
  x: 400, y: 300, cols: 5, rows: 4, slotSize: 60,
});

inventory.setItem(0, { textureKey: 'items', frameKey: 'sword.png', quantity: 1 });
inventory.setItem(1, { textureKey: 'items', frameKey: 'potion.png', quantity: 5 });

inventory.on('slotSelected', (index: number, item: InventoryItem | null) => {
  if (item) {
    console.log(`Selected slot ${index}: ${item.textureKey}`);
    // Show item tooltip, equip item, etc.
  }
});
```

# Phaser 4 Panel Rebuild Patterns

## The "flash close then reopen" anti-pattern

**Symptom:** A UI panel visibly flickers closed then reopens itself every time the user switches tabs, buys an upgrade, or triggers any content refresh inside the panel.

**Root cause:** The update logic tears down and recreates the ENTIRE panel:
```typescript
// BAD — entire panel gets destroyed and rebuilt (visible flicker):
onTabSwitch(newTab: string): void {
  this.closePanel();
  this.scene.time.delayedCall(180, () => {
    this.openPanel(newTab);
  });
}
```

Every 180 ms `delayedCall` of this shape is a visible flicker to the user. The fix is **content-only rebuild** — destroy only the children that belong to the content region, keep the chrome (backdrop, title, close button, gold counter) alive across rebuilds.

## In-place content rebuild (Phaser Container)

```typescript
export class ShopPanel extends Phaser.GameObjects.Container {
  private contentBaseLength = 0;  // length of container.list AFTER chrome is built

  create(): void {
    // 1. Build chrome once (backdrop, title, close X, gold counter):
    this.buildChrome();

    // 2. Snapshot container.length so we know which children are "chrome" vs "content":
    this.contentBaseLength = this.length;

    // 3. Build the initial tab content (indexed >= contentBaseLength):
    this.buildContent(this.currentTab);
  }

  switchTab(newTab: string): void {
    // Destroy ONLY the content children (indices >= contentBaseLength):
    const contentChildren = this.list.slice(this.contentBaseLength);
    contentChildren.forEach((child) => child.destroy());

    // Build new content in place — chrome stays alive, no flicker:
    this.currentTab = newTab;
    this.buildContent(newTab);
  }

  private buildChrome(): void {
    const bg = this.scene.add.rectangle(/* ... */);
    const title = this.scene.add.text(/* ... */);
    const closeBtn = this.scene.add.image(/* ... */).setInteractive();
    const goldCounter = this.scene.add.text(/* ... */);
    this.add([bg, title, closeBtn, goldCounter]);
  }

  private buildContent(tab: string): void {
    // Build tab-specific content and add to this container.
    // These children will be destroyed on the next switchTab() call.
    const rows = this.scene.getItemsForTab(tab).map((item) => this.makeItemRow(item));
    this.add(rows);
  }
}
```

The `slice(contentBaseLength)` idiom is load-bearing: it ONLY destroys children added after the snapshot. Title, backdrop, close button — all preserved across any number of content rebuilds.

## First-visit dialogue skip with a module-scope Set

Typewriter dialogue that replays its three-line intro every single time the player talks to the same NPC is friction. Solution: a module-scope `Set<string>` of NPC IDs whose intro dialogue has been seen this session.

```typescript
// At the top of HubScene.ts (module scope — persists across scene restarts
// within the same page load):
const seenNPCDialogues = new Set<string>();

export class HubScene extends Phaser.Scene {
  interactWithNPC(npcId: string): void {
    if (seenNPCDialogues.has(npcId)) {
      // Fast path — skip intro, go straight to the shop/menu:
      this.openNPCPanel(npcId);
      return;
    }

    seenNPCDialogues.add(npcId);
    this.playTypewriterDialogue(npcId, () => this.openNPCPanel(npcId));
  }
}
```

This Set is NOT persisted to localStorage — the first-visit dialogue plays once per page load, not once ever. If you want a stronger "seen forever" behavior, serialize to localStorage with a session-invalidation key.

## Worked example: HubDialoguePanel with tab switch + purchase

```typescript
export class HubDialoguePanel extends Phaser.GameObjects.Container {
  private contentBaseLength = 0;
  private currentTab: 'weapons' | 'stats' | 'mysteries' = 'weapons';
  private goldText!: Phaser.GameObjects.Text;

  constructor(scene: Phaser.Scene, x: number, y: number) {
    super(scene, x, y);
    scene.add.existing(this);

    // Chrome (permanent):
    const bg = scene.add.rectangle(0, 0, 640, 400, 0x1a1a24, 0.95).setOrigin(0, 0);
    const title = scene.add.text(320, 20, 'Merchant', { fontSize: '24px', color: '#fff' })
      .setOrigin(0.5, 0);
    this.goldText = scene.add.text(620, 20, 'Gold: 0', { fontSize: '16px', color: '#ffd700' })
      .setOrigin(1, 0);
    const tabBar = scene.add.container(0, 60);
    this.buildTabs(tabBar);

    this.add([bg, title, this.goldText, tabBar]);
    this.contentBaseLength = this.length;

    this.buildContent(this.currentTab);
  }

  switchTab(newTab: typeof this.currentTab): void {
    if (newTab === this.currentTab) return;
    this.currentTab = newTab;
    this.rebuildContent();
  }

  onPurchase(itemId: string, newGold: number): void {
    this.goldText.setText(`Gold: ${newGold}`);
    this.rebuildContent();  // refresh the item list (owned/unowned states)
  }

  private rebuildContent(): void {
    this.list.slice(this.contentBaseLength).forEach((c) => c.destroy());
    this.buildContent(this.currentTab);
  }

  private buildContent(tab: typeof this.currentTab): void {
    // tab-specific children added here; destroyed on next rebuildContent().
  }

  private buildTabs(tabBar: Phaser.GameObjects.Container): void {
    // ...
  }
}
```

The panel never flash-closes. Gold text and title are never destroyed. Only the content region flips on tab switch or purchase.

## Cross-references

- `agents/phaser-debugger.md` → "UI Flash / Close+Reopen Anti-pattern" diagnostic category.
- `skills/phaser-ui/references/hit-test-and-depth.md` — for drag-overlay click-swallow bugs that often co-occur with panel rebuild problems.

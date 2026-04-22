# Phaser 4 UI Hit-Test and Depth Patterns

## The core rule: Phaser input uses topOnly by default

Phaser's input manager defaults to `topOnly = true`, meaning pointer events route to the **highest-depth interactive game object** at a given point. A full-viewport invisible "dismiss zone" added on top of your UI to catch outside-the-panel clicks will silently steal every click — including clicks on buttons, tabs, and interactive text nested beneath it.

## Symptom

- Buttons that used to work stopped responding after adding a "click anywhere to dismiss" overlay.
- Arrow buttons and toggles in a settings panel silently ignore taps/clicks.
- Drag-to-scroll "blocking zones" on a guide panel make every interactive child underneath non-interactive.

The guide in the shipped game hit this exact bug: a GuideScroll drag-overlay at the default depth sat above every interactive child. Phaser's topOnly routing sent every pointer event to the invisible overlay, never to the buttons.

## Pattern A — Negative depth (invisible dismiss zones)

For a full-viewport invisible zone that catches outside-the-panel clicks WITHOUT intercepting the panel's own interactive children:

```typescript
const dismissZone = this.add.rectangle(0, 0, cam.width, cam.height, 0x000000, 0.001)
  .setOrigin(0, 0)
  .setInteractive();

// CRITICAL — push the dismiss zone BELOW normal game-object depth so it is
// hit-tested LAST, not first. Phaser's topOnly routing means any positive-depth
// interactive child above this zone still receives pointer events first.
dismissZone.setDepth(-9999);

dismissZone.on('pointerdown', () => { this.closePanel(); });
```

Only use Pattern A when the dismiss zone MUST be behind the panel's own interactive elements.

## Pattern B — Scoped `setTopOnly(false)` on an overlay scene

If you genuinely want every overlapping interactive to receive the event (e.g., a drag gesture should also update a panel button's hover state):

```typescript
// In an overlay scene's create():
this.input.setTopOnly(false);
```

Scope this narrowly — turning `topOnly` off globally cascades into surprising consequences (your own UI starts firing double events). Do it only in the scene that needs it.

## Pattern C — Open/close gate (destroy zone on open)

Sometimes the cleanest fix is: don't have the dismiss zone while the panel is open. The panel's own background rectangle catches clicks; the dismiss zone only exists while the panel is closed waiting to be opened.

```typescript
openPanel(): void {
  if (this.dismissZone) {
    this.dismissZone.destroy();
    this.dismissZone = undefined;
  }
  this.panel.setVisible(true);
}

closePanel(): void {
  this.panel.setVisible(false);
  this.dismissZone = this.add.rectangle(/* ... */)
    .setInteractive()
    .on('pointerdown', () => this.openPanel());
}
```

## Drag-overlay debug checklist

When an interactive child silently ignores clicks/taps:

1. **Depth audit** — grep the parent container and any nearby children for `.setDepth(`. Note every depth value in the overlay tree.
2. **Ask:** is there any invisible `.setInteractive()` zone at a higher depth than the broken child?
3. **`removeInteractive()` on dismiss** — if using Pattern C, make sure the dismiss zone is either destroyed or has `removeInteractive()` called before the panel opens.
4. **`blockOnDrag` on tweens** — if a drag gesture is mid-flight, interactive children may be temporarily blocked. Verify the pointer-up handler actually fires `dragend`.
5. **Test on TOUCH, not just mouse** — Phaser's pointer unification is excellent, but some overlay bugs only reproduce under real touch events. Use Chrome DevTools device emulation or a real device.

## Related references

- `skills/phaser-ui/references/ui-patterns.md` — component classes (HealthBar, Button, DialogBox, Panel, InventoryGrid).
- `skills/phaser-ui/references/panel-rebuild-patterns.md` — in-place content rebuild without flicker, for panels that update dynamically.
- `agents/phaser-debugger.md` → "Drag Overlay Swallows Clicks" diagnostic category.

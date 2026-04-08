# Phaser 4 Input API Reference

Complete reference for `Phaser.Input.InputPlugin`, `Phaser.Input.Keyboard.KeyboardPlugin`, `Phaser.Input.Keyboard.Key`, `Phaser.Input.Pointer`, `Phaser.Input.Gamepad.Gamepad`, and all input events.

---

## InputPlugin (`this.input`)

The InputPlugin is available on every Scene as `this.input`.

### Event Methods

| Method | Description |
|---|---|
| `on(event, callback, context?)` | Register a persistent event listener |
| `once(event, callback, context?)` | Register a one-time event listener |
| `off(event, callback?, context?, once?)` | Remove an event listener |
| `emit(event, ...args)` | Emit a custom event |
| `removeAllListeners(event?)` | Remove all listeners for an event, or all listeners |

### Pointer Methods

| Method | Signature | Description |
|---|---|---|
| `addPointer` | `(quantity?: number): Phaser.Input.Pointer[]` | Add extra pointer slots for multi-touch. Default adds 1. |
| `setDraggable` | `(gameObjects: GameObject \| GameObject[], value?: boolean): this` | Enable or disable drag on one or more game objects |
| `setHitArea` | `(gameObjects, hitArea, hitAreaCallback)` | Set a custom hit area shape on game objects |
| `setPollAlways` | `(): this` | Poll input every frame regardless of movement |
| `setPollOnMove` | `(): this` | Only poll input when the pointer moves (default) |
| `setPollRate` | `(value: number): this` | Set minimum ms between polls |
| `enable` | `(gameObject, hitArea?, callback?): this` | Enable input on a game object |
| `disable` | `(gameObject): this` | Disable input on a game object without removing listeners |
| `clear` | `(gameObject, skipQueue?: boolean): GameObject` | Remove input from a game object entirely |
| `hitTestPointer` | `(pointer): GameObject[]` | Return all game objects under the given pointer |

### Properties

| Property | Type | Description |
|---|---|---|
| `keyboard` | `Phaser.Input.Keyboard.KeyboardPlugin \| null` | The keyboard plugin; `null` if keyboard disabled in config |
| `mouse` | `Phaser.Input.Mouse.MouseManager \| null` | Mouse manager |
| `gamepad` | `Phaser.Input.Gamepad.GamepadPlugin \| null` | Gamepad plugin; `null` if not enabled |
| `pointer1` – `pointer10` | `Phaser.Input.Pointer` | Individual pointer slots for multi-touch |
| `activePointer` | `Phaser.Input.Pointer` | The most recently active pointer |
| `x` / `y` | `number` | Position of the active pointer |
| `isOver` | `boolean` | Whether the active pointer is over the game canvas |
| `dragDistanceThreshold` | `number` | Pixels to move before a drag starts (default 0) |
| `dragTimeThreshold` | `number` | Ms to hold before a drag starts (default 0) |

---

## KeyboardPlugin (`this.input.keyboard`)

### Methods

| Method | Signature | Description |
|---|---|---|
| `addKey` | `(key: string \| number \| Key \| KeyCodes, enableCapture?: boolean, emitOnRepeat?: boolean): Key` | Add a single key. Returns a `Key` object. |
| `addKeys` | `(keys: string \| object, enableCapture?: boolean, emitOnRepeat?: boolean): object` | Add multiple keys. Pass an object map or comma-separated string like `'W,A,S,D'`. Returns same-shaped object with `Key` values. |
| `removeKey` | `(key: string \| number \| Key, destroy?: boolean, removeCapture?: boolean): this` | Remove a single key |
| `removeAllKeys` | `(destroy?: boolean, removeCapture?: boolean): this` | Remove all keys |
| `createCursorKeys` | `(): CursorKeys` | Returns `{ up, down, left, right, space, shift }` as `Key` objects |
| `createCombo` | `(keyCodes: number[], config?: KeyComboConfig): KeyCombo` | Create a key sequence combo |
| `addCapture` | `(keyCode: string \| number \| number[] \| object): this` | Prevent browser from receiving these key events |
| `removeCapture` | `(keyCode: string \| number \| number[]): this` | Stop capturing specific keys |
| `clearCaptures` | `(): this` | Remove all key captures |
| `enableGlobalCapture` | `(): this` | Capture all key events globally |
| `disableGlobalCapture` | `(): this` | Stop capturing key events globally |
| `checkDown` | `(key: Key, duration?: number): boolean` | Returns `true` if key is held for at least `duration` ms |
| `resetKeys` | `(): this` | Reset the state of all keys |

### KeyComboConfig

```typescript
interface KeyComboConfig {
  resetOnMatch?: boolean;  // reset after a successful match (default false)
  deleteOnMatch?: boolean; // destroy combo after match (default false)
  maxKeyDelay?: number;    // max ms between each key press (default 0 = no limit)
  resetOnWrongKey?: boolean; // reset if wrong key pressed (default true)
}
```

---

## Key (`Phaser.Input.Keyboard.Key`)

A Key object is returned by `addKey()` or found inside `addKeys()` and `createCursorKeys()`.

### Properties

| Property | Type | Description |
|---|---|---|
| `isDown` | `boolean` | `true` while the key is held down |
| `isUp` | `boolean` | `true` while the key is not pressed |
| `enabled` | `boolean` | Set to `false` to disable this key without removing it |
| `keyCode` | `number` | The key code (see `Phaser.Input.Keyboard.KeyCodes`) |
| `duration` | `number` | Milliseconds the key has been held since last press |
| `timeDown` | `number` | `Date.now()` timestamp of last key-down event |
| `timeUp` | `number` | `Date.now()` timestamp of last key-up event |
| `repeats` | `number` | Number of times the key has fired a key-down event (including repeat) |
| `altKey` | `boolean` | Whether Alt was held when this key was pressed |
| `ctrlKey` | `boolean` | Whether Ctrl was held when this key was pressed |
| `shiftKey` | `boolean` | Whether Shift was held when this key was pressed |
| `metaKey` | `boolean` | Whether Meta/Cmd was held when this key was pressed |
| `location` | `number` | Key location (standard, left, right, numpad) |
| `emitOnRepeat` | `boolean` | If `true`, emits `down` event on OS key-repeat |

### Key Static Methods

| Method | Description |
|---|---|
| `Phaser.Input.Keyboard.JustDown(key)` | `true` on the first frame the key is pressed |
| `Phaser.Input.Keyboard.JustUp(key)` | `true` on the first frame the key is released |
| `Phaser.Input.Keyboard.DownDuration(key, duration)` | `true` if key is down and held for at most `duration` ms |
| `Phaser.Input.Keyboard.UpDuration(key, duration)` | `true` if key was released within the last `duration` ms |

### Common KeyCodes

```
Phaser.Input.Keyboard.KeyCodes.UP / DOWN / LEFT / RIGHT
Phaser.Input.Keyboard.KeyCodes.W / A / S / D
Phaser.Input.Keyboard.KeyCodes.SPACE
Phaser.Input.Keyboard.KeyCodes.SHIFT / CTRL / ALT
Phaser.Input.Keyboard.KeyCodes.ENTER / ESC / TAB / BACKSPACE
Phaser.Input.Keyboard.KeyCodes.ZERO through NINE
Phaser.Input.Keyboard.KeyCodes.A through Z
Phaser.Input.Keyboard.KeyCodes.F1 through F12
Phaser.Input.Keyboard.KeyCodes.NUMPAD_ZERO through NUMPAD_NINE
Phaser.Input.Keyboard.KeyCodes.PLUS / MINUS / COMMA / PERIOD
Phaser.Input.Keyboard.KeyCodes.PAGE_UP / PAGE_DOWN / HOME / END
Phaser.Input.Keyboard.KeyCodes.INSERT / DELETE
Phaser.Input.Keyboard.KeyCodes.PAUSE / PRINT_SCREEN
```

---

## Pointer (`Phaser.Input.Pointer`)

A Pointer represents a mouse cursor or a single touch point.

### Position Properties

| Property | Type | Description |
|---|---|---|
| `x` / `y` | `number` | Canvas position (screen-space) |
| `worldX` / `worldY` | `number` | World-space position accounting for camera |
| `prevPosition.x` / `.y` | `Phaser.Math.Vector2` | Position during the previous frame |
| `velocity.x` / `.y` | `number` | Movement delta in pixels (updated on move) |
| `angle` | `number` | Angle of movement in radians |
| `distance` | `number` | Total distance moved since last pointerdown |
| `moveTime` | `number` | Timestamp of the last pointer move |
| `downX` / `downY` | `number` | Position where the pointer was pressed down |
| `downTime` | `number` | Timestamp when the pointer went down |
| `upX` / `upY` | `number` | Position where the pointer was released |
| `upTime` | `number` | Timestamp when the pointer was released |

### State Properties

| Property | Type | Description |
|---|---|---|
| `isDown` | `boolean` | `true` while any button is held |
| `active` | `boolean` | `true` if this pointer slot is in use |
| `locked` | `boolean` | `true` if mouse is pointer-locked |
| `id` | `number` | Unique identifier for this pointer |
| `event` | `MouseEvent \| TouchEvent` | The raw browser event |
| `buttons` | `number` | Bitmask of currently held mouse buttons |
| `primaryDown` | `boolean` | `true` if primary (left) button is held |

### Button Methods

| Method | Returns | Description |
|---|---|---|
| `leftButtonDown()` | `boolean` | Left mouse button held |
| `rightButtonDown()` | `boolean` | Right mouse button held |
| `middleButtonDown()` | `boolean` | Middle mouse button held |
| `backButtonDown()` | `boolean` | Browser back button held |
| `forwardButtonDown()` | `boolean` | Browser forward button held |
| `leftButtonReleased()` | `boolean` | Left button just released this frame |
| `rightButtonReleased()` | `boolean` | Right button just released this frame |
| `middleButtonReleased()` | `boolean` | Middle button just released this frame |
| `noButtonDown()` | `boolean` | No buttons are held |
| `positionToCamera(camera, output?)` | `Vector2` | Convert pointer to world coordinates for a specific camera |

---

## Gamepad (`Phaser.Input.Gamepad.Gamepad`)

Access via `this.input.gamepad!.pad1` through `pad4`, or via the `connected` event.

### Button Properties (boolean)

| Property | Standard Mapping |
|---|---|
| `A` | Button 0 — Cross (PS) / A (Xbox) |
| `B` | Button 1 — Circle (PS) / B (Xbox) |
| `X` | Button 2 — Square (PS) / X (Xbox) |
| `Y` | Button 3 — Triangle (PS) / Y (Xbox) |
| `L1` | Button 4 — L1 / LB |
| `R1` | Button 5 — R1 / RB |
| `L2` | Button 6 — L2 / LT (analog, 0–1) |
| `R2` | Button 7 — R2 / RT (analog, 0–1) |
| `back` / `select` | Button 8 |
| `start` | Button 9 |
| `L3` | Button 10 — Left stick click |
| `R3` | Button 11 — Right stick click |
| `up` | Button 12 — D-pad up |
| `down` | Button 13 — D-pad down |
| `left` | Button 14 — D-pad left |
| `right` | Button 15 — D-pad right |

### Analog Properties

| Property | Type | Description |
|---|---|---|
| `leftStick.x` | `number` | Left stick horizontal (-1 to 1) |
| `leftStick.y` | `number` | Left stick vertical (-1 to 1) |
| `rightStick.x` | `number` | Right stick horizontal (-1 to 1) |
| `rightStick.y` | `number` | Right stick vertical (-1 to 1) |

### Gamepad Methods

| Method | Description |
|---|---|
| `getAxisValue(index)` | Get raw axis value (-1 to 1) by index |
| `getAxisTotal()` | Total number of axes |
| `isButtonDown(index)` | Check if button at index is pressed |
| `isButtonValue(index, threshold)` | Check if button analog value exceeds threshold |
| `getButtonTotal()` | Total number of buttons |
| `setAxisThreshold(value)` | Set axis dead zone threshold (default 0.05) |

### Gamepad Info Properties

| Property | Type | Description |
|---|---|---|
| `id` | `string` | Browser-provided controller ID string |
| `index` | `number` | Slot index (0–3) |
| `connected` | `boolean` | Whether controller is currently connected |
| `timestamp` | `number` | Timestamp of last update |
| `axes` | `Axis[]` | Raw axis array |
| `buttons` | `Button[]` | Raw button array |

---

## Input Events Reference

### Global Input Events (on `this.input`)

| Event | Callback Arguments | Description |
|---|---|---|
| `pointerdown` | `(pointer, currentlyOver[])` | Any pointer button pressed |
| `pointerup` | `(pointer, currentlyOver[])` | Any pointer button released |
| `pointermove` | `(pointer, currentlyOver[])` | Pointer moved |
| `pointerover` | `(pointer, justOver[])` | Pointer entered a game object's hit area |
| `pointerout` | `(pointer, justOut[])` | Pointer left a game object's hit area |
| `gameobjectdown` | `(pointer, gameObject, event)` | Pointer pressed on any interactive object |
| `gameobjectup` | `(pointer, gameObject, event)` | Pointer released on any interactive object |
| `gameobjectmove` | `(pointer, gameObject, event)` | Pointer moved over any interactive object |
| `gameobjectover` | `(pointer, gameObject, event)` | Pointer entered any interactive object |
| `gameobjectout` | `(pointer, gameObject, event)` | Pointer exited any interactive object |
| `dragstart` | `(pointer, gameObject)` | Drag started on a draggable object |
| `drag` | `(pointer, gameObject, dragX, dragY)` | Object being dragged |
| `dragend` | `(pointer, gameObject, dropped)` | Drag ended |
| `drop` | `(pointer, gameObject, dropZone)` | Draggable dropped into a drop zone |
| `dragenter` | `(pointer, gameObject, dropZone)` | Draggable entered a drop zone |
| `dragleave` | `(pointer, gameObject, dropZone)` | Draggable left a drop zone |
| `dragover` | `(pointer, gameObject, dropZone)` | Draggable moves over a drop zone |
| `wheel` | `(pointer, currentlyOver[], dx, dy, dz, event)` | Mouse wheel scrolled |

### Game Object Pointer Events (on individual objects after `setInteractive()`)

| Event | Callback Arguments | Description |
|---|---|---|
| `pointerdown` | `(pointer, localX, localY, event)` | Pointer pressed on this object |
| `pointerup` | `(pointer, localX, localY, event)` | Pointer released on this object |
| `pointermove` | `(pointer, localX, localY, event)` | Pointer moved over this object |
| `pointerover` | `(pointer, localX, localY, event)` | Pointer entered this object |
| `pointerout` | `(pointer, event)` | Pointer exited this object |
| `wheel` | `(pointer, dx, dy, dz, event)` | Mouse wheel over this object |

### Keyboard Events (on `this.input.keyboard`)

| Event | Callback Arguments | Description |
|---|---|---|
| `keydown` | `(event: KeyboardEvent)` | Any key pressed |
| `keydown-${KEY}` | `(event: KeyboardEvent)` | Specific key pressed (e.g. `keydown-SPACE`) |
| `keyup` | `(event: KeyboardEvent)` | Any key released |
| `keyup-${KEY}` | `(event: KeyboardEvent)` | Specific key released |
| `keycombomatch` | `(combo: KeyCombo)` | Key combo sequence completed |

### Gamepad Events (on `this.input.gamepad`)

| Event | Callback Arguments | Description |
|---|---|---|
| `connected` | `(pad: Gamepad, event)` | Gamepad connected |
| `disconnected` | `(pad: Gamepad, event)` | Gamepad disconnected |
| `down` | `(pad, button, value, event)` | Button pressed |
| `up` | `(pad, button, value, event)` | Button released |

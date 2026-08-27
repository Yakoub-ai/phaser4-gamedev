#!/usr/bin/env bash
# Phaser v3 API Guard — PreToolUse hook
# Scans content being written for removed Phaser v3 APIs and warns before saving.
# Reads tool input from stdin (Claude Code provides it as JSON).

# Read the full tool input JSON from stdin
TOOL_INPUT=$(cat)

# Extract the file path and content from the JSON (handles Write and Edit tools)
FILE_PATH=$(echo "$TOOL_INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
# Write tool uses 'file_path', Edit tool uses 'file_path'
print(data.get('file_path', ''))
" 2>/dev/null)

# Only check TypeScript and JavaScript files
if [[ ! "$FILE_PATH" =~ \.(ts|tsx|js|jsx)$ ]]; then
  exit 0
fi

# Extract the content being written
CONTENT=$(echo "$TOOL_INPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
# Write uses 'content', Edit uses 'new_string'
print(data.get('content', data.get('new_string', '')))
" 2>/dev/null)

if [ -z "$CONTENT" ]; then
  exit 0
fi

WARNINGS=()

# Check for removed v3 APIs
if echo "$CONTENT" | grep -q "Phaser\.Geom\.Point\|new Phaser\.Geom\.Point"; then
  WARNINGS+=("⚠️  Phaser v3 API detected: Phaser.Geom.Point\n   → Use Phaser.Math.Vector2 instead\n   → pt.length() replaces GetMagnitude(), pt.clone() replaces Clone()")
fi

if echo "$CONTENT" | grep -qE "Math\.PI2\b"; then
  WARNINGS+=("⚠️  Phaser v3 API detected: Math.PI2\n   → Use Math.TAU (= π×2) or Math.PI_OVER_2 (= π/2)")
fi

if echo "$CONTENT" | grep -q "Phaser\.Structs\.Map\|Phaser\.Structs\.Set"; then
  WARNINGS+=("⚠️  Phaser v3 API detected: Phaser.Structs.Map/Set\n   → Use native JavaScript Map / Set instead")
fi

if echo "$CONTENT" | grep -q "Camera3D\|Layer3D"; then
  WARNINGS+=("⚠️  Phaser v3 API detected: Camera3D / Layer3D\n   → These plugins are removed in Phaser 4. Phaser 4 is 2D only.")
fi

if echo "$CONTENT" | grep -q "FacebookInstant"; then
  WARNINGS+=("⚠️  Phaser v3 API detected: FacebookInstant\n   → Facebook Instant Games plugin removed in Phaser 4.")
fi

if echo "$CONTENT" | grep -q "Phaser\.Create\.GenerateTexture\|Create\.GenerateTexture"; then
  WARNINGS+=("⚠️  Phaser v3 API detected: Create.GenerateTexture\n   → Use Graphics.generateTexture() instead:\n   const gfx = this.add.graphics(); gfx.fillRect(0,0,w,h); gfx.generateTexture('key', w, h); gfx.destroy();")
fi

if echo "$CONTENT" | grep -qE "\.setCrop\("; then
  # Only warn if it looks like it might be on a TileSprite
  if echo "$CONTENT" | grep -q "tileSprite\|TileSprite\|add\.tileSprite"; then
    WARNINGS+=("⚠️  Phaser v3 API detected: TileSprite.setCrop()\n   → TileSprite cropping is not supported in Phaser 4. Use RenderTexture instead.")
  fi
fi

# ─── Phaser 4 runtime-gotcha detections ─────────────────────────────────────
# Heuristics for call shapes that compile cleanly and misbehave at runtime.
# All warn-only — do NOT block the write (exit 0 below preserves that).

if echo "$CONTENT" | grep -qE "createGeometryMask\(|setMask\(.*createGeometryMask"; then
  WARNINGS+=("⚠️  Removed Phaser 3 API: geometry/bitmap mask\n   → createGeometryMask() and createBitmapMask() do not exist in Phaser 4, and BitmapMask was removed entirely.\n   → Rectangular clip: give the content its own camera and use camera.setViewport(x, y, w, h). There is no camera.setScissor() in v4.\n   → Arbitrary shape: obj.enableFilters(); obj.filters.internal.addMask(source)\n   → See skills/phaser-migrate/references/runtime-gotchas.md section 1.")
fi

if echo "$CONTENT" | grep -qE "setCollisionByProperty\([^,)]+,\s*true\)"; then
  WARNINGS+=("⚠️  Implicit setCollisionByProperty arguments\n   → Signature is (properties, collides?, recalculateFaces?, layer?). Pass recalculateFaces explicitly, or players snag on seams between solid tiles.\n   → layer.setCollisionByProperty({ collides: true }, true, true)\n   → See skills/phaser-migrate/references/runtime-gotchas.md section 5.")
fi

if echo "$CONTENT" | grep -qE "^export const (GAME_WIDTH|GAME_HEIGHT)\b"; then
  WARNINGS+=("⚠️  Architectural anti-pattern: module-level size constant\n   → GAME_WIDTH / GAME_HEIGHT constants freeze at import time and leak off the right edge when the canvas grows (iOS rotation, Safari toolbar collapse, orientation unlock).\n   → Use this.cameras.main.width/height inside create() + this.scale.on('resize', ...) listener.\n   → See skills/phaser-scene/references/scene-patterns.md → Responsive Sizing: Two Layers.")
fi

if echo "$CONTENT" | grep -qE "\.onFloor\(\)"; then
  WARNINGS+=("⚠️  body.onFloor() can resolve a frame late\n   → onFloor() comes from the tile/world pass and may land a step after blocked.down. For jump-landed detection prefer: body.blocked.down || body.onFloor()\n   → A single dropped frame here is 16ms of eaten jump input at 60fps.\n   → See skills/phaser-migrate/references/runtime-gotchas.md section 6.")
fi

# Multi-line heuristic: close+delayedCall+open pattern (UI flash anti-pattern)
if echo "$CONTENT" | grep -qzE "close[A-Za-z_]*Panel[^}]*delayedCall[^}]*open[A-Za-z_]*Panel" 2>/dev/null; then
  WARNINGS+=("⚠️  UI flash anti-pattern: close+delayedCall+open detected\n   → Visible panel flicker. Replace with in-place content rebuild: snapshot container.length before content build, slice container.list after, destroy only content-region children so chrome stays alive.\n   → See skills/phaser-ui/references/panel-rebuild-patterns.md.")
fi

# Report warnings
if [ ${#WARNINGS[@]} -gt 0 ]; then
  echo ""
  echo "🚨 PHASER 4 API WARNING — ${FILE_PATH}"
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  for warning in "${WARNINGS[@]}"; do
    echo -e "$warning"
    echo ""
  done
  echo "Run /phaser-migrate for a full migration guide."
  echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
  echo ""
  # Exit 0 — warn but don't block the write
fi

exit 0

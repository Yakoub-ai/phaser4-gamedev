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

# ─── RC6 → RC7 behavioral drift detections ──────────────────────────────────
# These are heuristics for patterns that silently broke between Phaser 4 RC releases.
# All warn-only — do NOT block the write (exit 0 below preserves that).

if echo "$CONTENT" | grep -qE "createGeometryMask\(|setMask\(.*createGeometryMask"; then
  WARNINGS+=("⚠️  Phaser 4 RC7 drift: geometry mask detected\n   → Geometry masks for rectangular clipping broke in RC7. Use Camera scissor instead (\`camera.setScissor(x,y,w,h)\`).\n   → Alpha and bitmap masks are still valid; only rectangular geometry masks are affected.\n   → See skills/phaser-migrate/references/rc6-to-rc7-changes.md section 1.")
fi

if echo "$CONTENT" | grep -qE "setCollisionByProperty\([^,)]+,\s*true\)"; then
  WARNINGS+=("⚠️  Phaser 4 RC7 drift: setCollisionByProperty two-arg form\n   → The second-arg boolean polarity changed in RC7. Re-verify against current node_modules/phaser/types/.\n   → See skills/phaser-migrate/references/rc6-to-rc7-changes.md section 6.")
fi

if echo "$CONTENT" | grep -qE "^export const (GAME_WIDTH|GAME_HEIGHT)\b"; then
  WARNINGS+=("⚠️  Architectural anti-pattern: module-level size constant\n   → GAME_WIDTH / GAME_HEIGHT constants freeze at import time and leak off the right edge when the canvas grows (iOS rotation, Safari toolbar collapse, orientation unlock).\n   → Use this.cameras.main.width/height inside create() + this.scale.on('resize', ...) listener.\n   → See skills/phaser-scene/references/scene-patterns.md → Responsive Sizing: Two Layers.")
fi

if echo "$CONTENT" | grep -qE "\.onFloor\(\)"; then
  WARNINGS+=("⚠️  Phaser 4 RC7 drift: body.onFloor() timing changed\n   → body.onFloor() returns true one physics step later in RC7. For jump-landed detection prefer: body.blocked.down || body.onFloor()\n   → See skills/phaser-migrate/references/rc6-to-rc7-changes.md section 6.")
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

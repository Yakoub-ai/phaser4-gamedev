#!/usr/bin/env bash
# Phaser Project Detector — SessionStart hook
# Checks if the current project uses Phaser and prints a context message.

PACKAGE_JSON="$(pwd)/package.json"

if [ ! -f "$PACKAGE_JSON" ]; then
  exit 0
fi

# Check if phaser is a dependency
if grep -q '"phaser"' "$PACKAGE_JSON" 2>/dev/null; then
  # Get the version if possible
  PHASER_VERSION=$(python3 -c "
import json
try:
    with open('$PACKAGE_JSON') as f:
        pkg = json.load(f)
    deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
    print(deps.get('phaser', 'unknown'))
except:
    print('unknown')
" 2>/dev/null)

  echo ""
  echo "🎮 Phaser project detected (${PHASER_VERSION})"
  echo "   Agents: phaser-architect, phaser-coder, phaser-debugger, phaser-asset-advisor"
  echo "   Commands: /phaser-new, /phaser-run, /phaser-validate, /phaser-build"
  echo "   Skills: /phaser-init, /phaser-scene, /phaser-gameobj, /phaser-physics,"
  echo "           /phaser-audio, /phaser-animation, /phaser-input, /phaser-tilemap,"
  echo "           /phaser-ui, /phaser-build, /phaser-migrate"
  echo ""
fi

exit 0

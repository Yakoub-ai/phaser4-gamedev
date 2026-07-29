#!/usr/bin/env bash
# Phaser Project Detector — SessionStart hook
# Detects a Phaser project and prints what the toolkit offers.
# Lists are discovered from the plugin directory rather than hardcoded, so they
# cannot drift out of date as skills and commands are added.

PACKAGE_JSON="$(pwd)/package.json"
[ -f "$PACKAGE_JSON" ] || exit 0

grep -q '"phaser"' "$PACKAGE_JSON" 2>/dev/null || exit 0

PHASER_VERSION=$(python3 -c "
import json
try:
    with open('$PACKAGE_JSON') as f:
        pkg = json.load(f)
    deps = {**pkg.get('dependencies', {}), **pkg.get('devDependencies', {})}
    print(deps.get('phaser', 'unknown'))
except Exception:
    print('unknown')
" 2>/dev/null)

ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)}"

# Wrap a space-separated list to a readable width with a hanging indent.
wrap_list() {
  printf '%s' "$1" | tr ' ' '\n' | awk -v indent="$2" '
    BEGIN { line = "" }
    {
      cand = (line == "" ? $0 : line ", " $0)
      if (length(cand) > 66) { print indent line ","; line = $0 }
      else { line = cand }
    }
    END { if (line != "") print indent line }
  '
}

AGENTS=""
for f in "$ROOT"/agents/*.md; do
  [ -e "$f" ] || break
  AGENTS="$AGENTS $(basename "$f" .md)"
done

COMMANDS=""
for f in "$ROOT"/commands/*.md; do
  [ -e "$f" ] || break
  COMMANDS="$COMMANDS /$(basename "$f" .md)"
done

SKILLS=""
for d in "$ROOT"/skills/*/; do
  [ -d "$d" ] || break
  SKILLS="$SKILLS $(basename "$d")"
done

echo ""
echo "🎮 Phaser project detected (${PHASER_VERSION})"
echo ""
echo "   Agents:"
wrap_list "${AGENTS# }" "     "
echo "   Commands:"
wrap_list "${COMMANDS# }" "     "
echo "   Skills:"
wrap_list "${SKILLS# }" "     "
echo ""
echo "   Workflow: /phaser-gdd → /phaser-new → build → /phaser-playtest → /phaser-build"
echo "   Verify at runtime, not just at compile time: /phaser-playtest runs the game headless."
echo ""

exit 0

#!/usr/bin/env bash
# validate-plugin.sh — Validate phaser4-gamedev plugin structure
# Usage: bash scripts/validate-plugin.sh
# Run from anywhere; resolves the plugin root from its own location.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

error() { echo -e "${RED}[ERROR]${NC} $1"; ERRORS=$((ERRORS + 1)); }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1";  WARNINGS=$((WARNINGS + 1)); }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
info()  { echo -e "${CYAN}[CHECK]${NC} $1"; }

# Extract a top-level YAML frontmatter scalar. Handles `key: value` in the block
# between the first two `---` lines only, so body text cannot produce false hits.
frontmatter() {
  awk -v key="$2" '
    NR == 1 && $0 == "---" { inside = 1; next }
    inside && $0 == "---"  { exit }
    inside {
      if (index($0, key ":") == 1) { sub("^" key ": *", ""); gsub(/^["\x27]|["\x27]$/, ""); print; exit }
    }
  ' "$1"
}

has_frontmatter_key() {
  [[ -n "$(frontmatter "$1" "$2")" ]]
}

echo ""
echo "=== phaser4-gamedev Plugin Validator ==="
echo "Plugin root: $PLUGIN_DIR"
echo ""

# ── Manifests ─────────────────────────────────────────────────────────────────
info "Plugin manifests..."

VERSION=""
for manifest in ".claude-plugin/plugin.json" ".claude-plugin/marketplace.json" ".codex-plugin/plugin.json"; do
  path="$PLUGIN_DIR/$manifest"
  if [[ ! -f "$path" ]]; then
    error "$manifest missing"
    continue
  fi
  if ! node -e "JSON.parse(require('fs').readFileSync('$path','utf8'))" 2>/dev/null; then
    error "$manifest is not valid JSON"
    continue
  fi
  ok "$manifest is valid JSON"
done

if [[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
  NAME=$(node -pe "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/.claude-plugin/plugin.json','utf8')).name" 2>/dev/null || echo "")
  VERSION=$(node -pe "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/.claude-plugin/plugin.json','utf8')).version" 2>/dev/null || echo "")
  [[ "$NAME" == "phaser4-gamedev" ]] && ok "Plugin name: $NAME" || error "Plugin name mismatch: expected 'phaser4-gamedev', got '$NAME'"
  [[ -n "$VERSION" ]] && ok "Plugin version: $VERSION" || error "plugin.json has no version"
fi

if [[ -f "$PLUGIN_DIR/.codex-plugin/plugin.json" ]]; then
  CODEX_SKILLS=$(node -pe "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/.codex-plugin/plugin.json','utf8')).skills" 2>/dev/null || echo "")
  [[ "$CODEX_SKILLS" == "./skills/" ]] && ok "Codex plugin skills path: $CODEX_SKILLS" \
    || error "Codex plugin skills path mismatch: expected './skills/', got '$CODEX_SKILLS'"
fi

# Version consistency — this is what silently drifted before. Check every source.
if [[ -n "$VERSION" ]]; then
  MISMATCH=0
  for f in ".codex-plugin/plugin.json"; do
    V=$(node -pe "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/$f','utf8')).version" 2>/dev/null || echo "")
    [[ "$V" == "$VERSION" ]] || { error "$f version '$V' != plugin.json version '$VERSION'"; MISMATCH=1; }
  done
  MV=$(node -pe "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/.claude-plugin/marketplace.json','utf8')).metadata.version" 2>/dev/null || echo "")
  [[ "$MV" == "$VERSION" ]] || { error "marketplace.json metadata.version '$MV' != '$VERSION'"; MISMATCH=1; }
  PV=$(node -pe "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/.claude-plugin/marketplace.json','utf8')).plugins[0].version" 2>/dev/null || echo "")
  [[ "$PV" == "$VERSION" ]] || { error "marketplace.json plugins[0].version '$PV' != '$VERSION'"; MISMATCH=1; }

  for skill_md in "$PLUGIN_DIR"/skills/*/SKILL.md; do
    SV=$(frontmatter "$skill_md" "version")
    if [[ "$SV" != "$VERSION" ]]; then
      error "skills/$(basename "$(dirname "$skill_md")")/SKILL.md version '$SV' != '$VERSION'"
      MISMATCH=1
    fi
  done
  [[ "$MISMATCH" -eq 0 ]] && ok "All manifests and skills agree on version $VERSION"
fi
echo ""

# ── Agents ────────────────────────────────────────────────────────────────────
info "Agents..."
AGENT_COUNT=0
for agent_path in "$PLUGIN_DIR"/agents/*.md; do
  [[ -e "$agent_path" ]] || { error "agents/ contains no agent definitions"; break; }
  agent="$(basename "$agent_path")"
  AGENT_COUNT=$((AGENT_COUNT + 1))
  MISSING=""
  for key in name description model color tools; do
    has_frontmatter_key "$agent_path" "$key" || MISSING="$MISSING $key"
  done
  # `description` is a YAML block scalar in these agents, so the value is on
  # following lines — presence of the key is what matters.
  if grep -q "^description:" "$agent_path"; then MISSING="${MISSING/ description/}"; fi
  if [[ -n "$MISSING" ]]; then
    error "agents/$agent missing frontmatter:$MISSING"
    continue
  fi
  NAME=$(frontmatter "$agent_path" "name")
  [[ "$NAME" == "${agent%.md}" ]] || warn "agents/$agent has name '$NAME' but filename '${agent%.md}'"

  grep -q "<example>" "$agent_path" || warn "agents/$agent has no <example> blocks in its description"

  # An explicit `tools:` list is an allowlist. An agent told to use Context7 but
  # not granted the MCP tools cannot follow that instruction.
  if grep -q "Context7\|query-docs" "$agent_path" && ! grep -q "mcp__context7__" "$agent_path"; then
    error "agents/$agent references Context7 but its tools allowlist does not grant mcp__context7__* — the instruction is unreachable"
  fi

  WORD_COUNT=$(wc -w < "$agent_path")
  ok "agents/$agent ($WORD_COUNT words)"
done
echo ""

# ── Agent / portable-skill mirrors ────────────────────────────────────────────
info "Agent mirrors (portable skills)..."
for agent_path in "$PLUGIN_DIR"/agents/*.md; do
  agent="$(basename "$agent_path" .md)"
  mirror="$PLUGIN_DIR/skills/$agent/references/agent-guidance.md"
  if [[ -f "$mirror" ]]; then
    if diff -q "$agent_path" "$mirror" >/dev/null 2>&1; then
      ok "skills/$agent/references/agent-guidance.md matches agents/$agent.md"
    else
      warn "skills/$agent/references/agent-guidance.md has drifted from agents/$agent.md"
    fi
  fi
done
echo ""

# ── Commands ──────────────────────────────────────────────────────────────────
info "Commands..."
if [[ -d "$PLUGIN_DIR/commands" ]]; then
  CMD_COUNT=0
  for cmd_path in "$PLUGIN_DIR"/commands/*.md; do
    [[ -e "$cmd_path" ]] || { error "commands/ contains no command definitions"; break; }
    cmd="$(basename "$cmd_path")"
    CMD_COUNT=$((CMD_COUNT + 1))
    if has_frontmatter_key "$cmd_path" "description"; then
      ok "commands/$cmd"
    else
      error "commands/$cmd missing required 'description' frontmatter"
    fi
  done
else
  error "commands/ directory missing"
fi
echo ""

# ── Hooks ─────────────────────────────────────────────────────────────────────
info "Hooks..."
if [[ -f "$PLUGIN_DIR/hooks/hooks.json" ]]; then
  if node -e "JSON.parse(require('fs').readFileSync('$PLUGIN_DIR/hooks/hooks.json','utf8'))" 2>/dev/null; then
    ok "hooks/hooks.json is valid JSON"
  else
    error "hooks/hooks.json is not valid JSON"
  fi
  for event in PreToolUse SessionStart; do
    grep -q "$event" "$PLUGIN_DIR/hooks/hooks.json" && ok "  $event hook configured" || warn "  no $event hook in hooks.json"
  done
else
  error "hooks/hooks.json missing"
fi

for hook in check-v3-api.sh detect-phaser.sh; do
  hpath="$PLUGIN_DIR/hooks/scripts/$hook"
  if [[ -f "$hpath" ]]; then
    if bash -n "$hpath" 2>/dev/null; then ok "hooks/scripts/$hook (syntax OK)"; else error "hooks/scripts/$hook has a bash syntax error"; fi
  else
    error "hooks/scripts/$hook missing"
  fi
done
echo ""

# ── Skills ────────────────────────────────────────────────────────────────────
info "Skills..."
SKILL_COUNT=0
for skill_dir in "$PLUGIN_DIR"/skills/*/; do
  skill="$(basename "$skill_dir")"
  SKILL_COUNT=$((SKILL_COUNT + 1))
  SKILL_MD="$skill_dir/SKILL.md"

  if [[ ! -f "$SKILL_MD" ]]; then
    error "skills/$skill/SKILL.md missing"
    continue
  fi

  MISSING=""
  for key in name description version; do
    has_frontmatter_key "$SKILL_MD" "$key" || MISSING="$MISSING $key"
  done
  if [[ -n "$MISSING" ]]; then
    error "skills/$skill/SKILL.md missing frontmatter:$MISSING"
    continue
  fi

  SNAME=$(frontmatter "$SKILL_MD" "name")
  [[ "$SNAME" == "$skill" ]] || error "skills/$skill/SKILL.md declares name '$SNAME' but lives in '$skill/'"

  if ! grep -q "^description: This skill should be used when" "$SKILL_MD"; then
    error "skills/$skill/SKILL.md description must start with 'This skill should be used when'"
    continue
  fi

  WORD_COUNT=$(wc -w < "$SKILL_MD")
  if [[ "$WORD_COUNT" -gt 5000 ]]; then
    warn "skills/$skill/SKILL.md is $WORD_COUNT words (>5000 — move content into references/)"
  else
    ok "skills/$skill/SKILL.md ($WORD_COUNT words)"
  fi

  # Referenced subdirectories must exist. Only *self-relative* mentions count —
  # a pointer at another skill's `skills/<other>/scripts/...` is checked by the
  # cross-reference pass below, not by this one.
  for sub in references examples scripts; do
    if grep -oE '(^|[^/[:alnum:]_-])'"$sub"'/' "$SKILL_MD" | grep -qv 'skills/'; then
      if [[ -d "$skill_dir/$sub" ]]; then
        COUNT=$(find "$skill_dir/$sub" -maxdepth 1 -type f | wc -l | tr -d ' ')
        [[ "$COUNT" -gt 0 ]] && ok "  skills/$skill/$sub/ ($COUNT file(s))" || error "  skills/$skill/$sub/ exists but is empty"
      else
        error "skills/$skill/SKILL.md references $sub/ but the directory doesn't exist"
      fi
    fi
  done
done
echo ""

# ── Scripts ───────────────────────────────────────────────────────────────────
info "Scripts..."
while IFS= read -r script; do
  rel="${script#"$PLUGIN_DIR"/}"
  case "$script" in
    *.sh)
      if bash -n "$script" 2>/dev/null; then
        [[ -x "$script" ]] && ok "$rel (syntax OK, executable)" \
          || warn "$rel is not executable. Run: chmod +x $rel"
      else
        error "$rel has a bash syntax error"
      fi
      ;;
    *.mjs|*.js)
      if node --check "$script" 2>/dev/null; then
        ok "$rel (syntax OK)"
      else
        error "$rel has a JavaScript syntax error"
      fi
      ;;
  esac
done < <(find "$PLUGIN_DIR/skills" "$PLUGIN_DIR/scripts" -type f \( -name "*.sh" -o -name "*.mjs" -o -name "*.js" \) 2>/dev/null | sort)
echo ""

# ── Cross-references ──────────────────────────────────────────────────────────
info "Cross-references..."
# Every ${CLAUDE_PLUGIN_ROOT}/... path named in a command or agent must exist,
# otherwise the instruction points at nothing at runtime.
BROKEN=0
while IFS= read -r ref; do
  target="$PLUGIN_DIR/${ref}"
  if [[ ! -e "$target" ]]; then
    error "broken \${CLAUDE_PLUGIN_ROOT} reference: $ref"
    BROKEN=$((BROKEN + 1))
  fi
done < <(grep -rhoE '\$\{CLAUDE_PLUGIN_ROOT\}/[A-Za-z0-9_./-]+' \
           "$PLUGIN_DIR/commands" "$PLUGIN_DIR/agents" "$PLUGIN_DIR/skills" 2>/dev/null \
         | sed 's|${CLAUDE_PLUGIN_ROOT}/||' | sort -u)
[[ "$BROKEN" -eq 0 ]] && ok "all \${CLAUDE_PLUGIN_ROOT} references resolve"

# The SessionStart hook advertises the toolkit. It discovers agents/commands/skills
# from disk, so verify it actually runs and reports the real counts rather than
# checking a hardcoded list that would drift again.
DETECT="$PLUGIN_DIR/hooks/scripts/detect-phaser.sh"
if [[ -f "$DETECT" ]]; then
  TMPDIR_TEST=$(mktemp -d)
  echo '{"dependencies":{"phaser":"4.2.1"}}' > "$TMPDIR_TEST/package.json"
  HOOK_OUT=$(cd "$TMPDIR_TEST" && CLAUDE_PLUGIN_ROOT="$PLUGIN_DIR" bash "$DETECT" 2>&1 || true)
  rm -rf "$TMPDIR_TEST"
  if grep -q "Phaser project detected" <<< "$HOOK_OUT"; then
    for probe in phaser-playtest phaser-coder phaser-init; do
      grep -q -- "$probe" <<< "$HOOK_OUT" || warn "detect-phaser.sh output does not list '$probe'"
    done
    ok "detect-phaser.sh runs and lists the toolkit"
  else
    error "detect-phaser.sh did not detect a Phaser project in a fixture that has one"
  fi
fi
echo ""

# ── Content accuracy ──────────────────────────────────────────────────────────
info "Phaser 4 API accuracy checks..."
check_mentions() {
  if grep -rqi -- "$1" "$PLUGIN_DIR/agents/" "$PLUGIN_DIR/skills/" 2>/dev/null; then ok "$2"; else warn "$2 — NOT FOUND"; fi
}
check_mentions "phaser" "Correct Phaser 4 install command (phaser) is referenced"
check_mentions "Math\.TAU" "Math.TAU (v4 replacement for Math.PI2) is referenced"
check_mentions "Vector2" "Vector2 (v4 replacement for Geom.Point) is referenced"
check_mentions "Beam" "Phaser Beam renderer is mentioned"

# Every `skills/<name>/<sub>/<file>` path cited in prose must resolve. These
# cross-skill pointers are how a skill hands off to deeper reference material;
# a stale one sends the agent to a file that isn't there.
DEADLINKS=0
while IFS= read -r ref; do
  [[ -e "$PLUGIN_DIR/$ref" ]] || { error "broken cross-reference: $ref"; DEADLINKS=$((DEADLINKS + 1)); }
done < <(grep -rhoE 'skills/[a-z0-9-]+/(references|examples|scripts)/[A-Za-z0-9_.-]+' \
           "$PLUGIN_DIR/skills" "$PLUGIN_DIR/agents" "$PLUGIN_DIR/commands" "$PLUGIN_DIR/CLAUDE.md" 2>/dev/null | sort -u)
[[ "$DEADLINKS" -eq 0 ]] && ok "all cross-skill file references resolve"
echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "=================================="
echo "Agents: $AGENT_COUNT   Skills: $SKILL_COUNT   Commands: ${CMD_COUNT:-0}   Version: ${VERSION:-unknown}"
echo ""
if [[ "$ERRORS" -eq 0 && "$WARNINGS" -eq 0 ]]; then
  echo -e "${GREEN}Plugin validation passed! All checks OK.${NC}"
elif [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${YELLOW}$WARNINGS warning(s) — plugin is functional but review warnings.${NC}"
else
  echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s) — fix errors before publishing.${NC}"
fi
echo ""

exit "$ERRORS"

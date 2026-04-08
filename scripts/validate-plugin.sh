#!/usr/bin/env bash
# validate-plugin.sh — Validate phaser4-gamedev plugin structure
# Usage: bash scripts/validate-plugin.sh
# Run from the phaser4-gamedev/ directory.

set -euo pipefail

PLUGIN_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

error() { echo -e "${RED}[ERROR]${NC} $1"; ((ERRORS++)); }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1";  ((WARNINGS++)); }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
info()  { echo -e "${CYAN}[CHECK]${NC} $1"; }

echo ""
echo "=== phaser4-gamedev Plugin Validator ==="
echo "Plugin root: $PLUGIN_DIR"
echo ""

# ── Manifest ──────────────────────────────────────────────────────────────────
info "Plugin manifest..."
if [[ -f "$PLUGIN_DIR/.claude-plugin/plugin.json" ]]; then
  ok ".claude-plugin/plugin.json exists"
  NAME=$(node -e "console.log(require('$PLUGIN_DIR/.claude-plugin/plugin.json').name)" 2>/dev/null || echo "")
  if [[ "$NAME" == "phaser4-gamedev" ]]; then
    ok "Plugin name: $NAME"
  else
    error "Plugin name mismatch: expected 'phaser4-gamedev', got '$NAME'"
  fi
else
  error ".claude-plugin/plugin.json missing"
fi
echo ""

# ── Agents ────────────────────────────────────────────────────────────────────
info "Agents..."
REQUIRED_AGENTS=("phaser-architect.md" "phaser-coder.md" "phaser-debugger.md" "phaser-asset-advisor.md")
for agent in "${REQUIRED_AGENTS[@]}"; do
  if [[ -f "$PLUGIN_DIR/agents/$agent" ]]; then
    # Check frontmatter has required fields
    if grep -q "^name:" "$PLUGIN_DIR/agents/$agent" && \
       grep -q "^description:" "$PLUGIN_DIR/agents/$agent" && \
       grep -q "^model:" "$PLUGIN_DIR/agents/$agent" && \
       grep -q "^color:" "$PLUGIN_DIR/agents/$agent"; then
      # Check description has at least one <example>
      if grep -q "<example>" "$PLUGIN_DIR/agents/$agent"; then
        WORD_COUNT=$(wc -w < "$PLUGIN_DIR/agents/$agent")
        ok "agents/$agent ($WORD_COUNT words, has examples)"
      else
        warn "agents/$agent missing <example> blocks in description"
      fi
    else
      error "agents/$agent missing required frontmatter fields (name/description/model/color)"
    fi
    # Verify that v4 replacements are actually mentioned (Vector2, Math.TAU)
    if grep -q "Vector2\|Math\.TAU\|v4\|Phaser 4" "$PLUGIN_DIR/agents/$agent" 2>/dev/null; then
      ok "agents/$agent references Phaser 4 patterns (Vector2/TAU)"
    else
      warn "agents/$agent may not reference key Phaser 4 patterns"
    fi
  else
    error "agents/$agent missing"
  fi
done
echo ""

# ── Commands ──────────────────────────────────────────────────────────────────
info "Commands..."
REQUIRED_COMMANDS=("phaser-new.md" "phaser-run.md" "phaser-validate.md" "phaser-build.md")
if [[ -d "$PLUGIN_DIR/commands" ]]; then
  for cmd in "${REQUIRED_COMMANDS[@]}"; do
    if [[ -f "$PLUGIN_DIR/commands/$cmd" ]]; then
      ok "commands/$cmd"
    else
      error "commands/$cmd missing"
    fi
  done
else
  error "commands/ directory missing"
fi
echo ""

# ── Hooks ─────────────────────────────────────────────────────────────────────
info "Hooks..."
if [[ -f "$PLUGIN_DIR/hooks/hooks.json" ]]; then
  ok "hooks/hooks.json exists"
  if grep -q "PreToolUse" "$PLUGIN_DIR/hooks/hooks.json"; then
    ok "  PreToolUse hook configured"
  else
    warn "  No PreToolUse hook found in hooks.json"
  fi
  if grep -q "SessionStart" "$PLUGIN_DIR/hooks/hooks.json"; then
    ok "  SessionStart hook configured"
  else
    warn "  No SessionStart hook found in hooks.json"
  fi
else
  error "hooks/hooks.json missing"
fi
if [[ -f "$PLUGIN_DIR/hooks/scripts/check-v3-api.sh" ]]; then
  ok "hooks/scripts/check-v3-api.sh exists"
else
  error "hooks/scripts/check-v3-api.sh missing"
fi
if [[ -f "$PLUGIN_DIR/hooks/scripts/detect-phaser.sh" ]]; then
  ok "hooks/scripts/detect-phaser.sh exists"
else
  error "hooks/scripts/detect-phaser.sh missing"
fi
echo ""

# ── Skills ────────────────────────────────────────────────────────────────────
info "Skills..."
REQUIRED_SKILLS=("phaser-init" "phaser-scene" "phaser-gameobj" "phaser-physics" "phaser-build" "phaser-migrate" "phaser-audio" "phaser-animation" "phaser-input" "phaser-tilemap" "phaser-ui" "phaser-matter" "phaser-saveload" "phaser-mobile")
for skill in "${REQUIRED_SKILLS[@]}"; do
  SKILL_DIR="$PLUGIN_DIR/skills/$skill"
  if [[ -d "$SKILL_DIR" ]]; then
    if [[ -f "$SKILL_DIR/SKILL.md" ]]; then
      # Check frontmatter
      if grep -q "^name:" "$SKILL_DIR/SKILL.md" && grep -q "^description:" "$SKILL_DIR/SKILL.md"; then
        # Check third-person description
        if grep -q "This skill should be used when" "$SKILL_DIR/SKILL.md"; then
          # Count words in SKILL.md
          WORD_COUNT=$(wc -w < "$SKILL_DIR/SKILL.md")
          if [[ "$WORD_COUNT" -gt 5000 ]]; then
            warn "skills/$skill/SKILL.md is $WORD_COUNT words (>5000 — consider moving content to references/)"
          else
            ok "skills/$skill/SKILL.md ($WORD_COUNT words, third-person description)"
          fi
        else
          error "skills/$skill/SKILL.md description must start with 'This skill should be used when'"
        fi
      else
        error "skills/$skill/SKILL.md missing name or description frontmatter"
      fi

      # Check references dir if mentioned in SKILL.md
      if grep -q "references/" "$SKILL_DIR/SKILL.md"; then
        if [[ -d "$SKILL_DIR/references" ]]; then
          REF_COUNT=$(ls "$SKILL_DIR/references/"*.md 2>/dev/null | wc -l)
          ok "skills/$skill/references/ ($REF_COUNT file(s))"
        else
          error "skills/$skill/SKILL.md references references/ directory but it doesn't exist"
        fi
      fi

      # Check examples dir if mentioned
      if grep -q "examples/" "$SKILL_DIR/SKILL.md"; then
        if [[ -d "$SKILL_DIR/examples" ]]; then
          EX_COUNT=$(ls "$SKILL_DIR/examples/" 2>/dev/null | wc -l)
          ok "skills/$skill/examples/ ($EX_COUNT file(s))"
        else
          warn "skills/$skill/SKILL.md mentions examples/ but directory doesn't exist"
        fi
      fi

      # Check scripts dir if mentioned
      if grep -q "scripts/" "$SKILL_DIR/SKILL.md"; then
        if [[ -d "$SKILL_DIR/scripts" ]]; then
          SC_COUNT=$(ls "$SKILL_DIR/scripts/" 2>/dev/null | wc -l)
          ok "skills/$skill/scripts/ ($SC_COUNT file(s))"
        else
          error "skills/$skill/SKILL.md mentions scripts/ directory but it doesn't exist"
        fi
      fi
    else
      error "skills/$skill/SKILL.md missing"
    fi
  else
    error "skills/$skill/ directory missing"
  fi
done
echo ""

# ── Scripts ───────────────────────────────────────────────────────────────────
info "Scripts..."
if [[ -f "$PLUGIN_DIR/skills/phaser-build/scripts/validate-project.sh" ]]; then
  if [[ -x "$PLUGIN_DIR/skills/phaser-build/scripts/validate-project.sh" ]]; then
    ok "validate-project.sh exists and is executable"
  else
    warn "validate-project.sh exists but is not executable. Run: chmod +x skills/phaser-build/scripts/validate-project.sh"
  fi
else
  error "skills/phaser-build/scripts/validate-project.sh missing"
fi
echo ""

# ── Content Accuracy Check ────────────────────────────────────────────────────
info "Phaser 4 API accuracy checks..."

# Ensure Phaser 4 key facts are mentioned
if grep -rq "phaser@beta\|4\.0\.0-rc" "$PLUGIN_DIR/skills/" 2>/dev/null; then
  ok "Skills reference correct Phaser 4 install command (phaser@beta)"
else
  warn "Skills may not reference phaser@beta install command"
fi

if grep -rq "Math\.TAU" "$PLUGIN_DIR/agents/" "$PLUGIN_DIR/skills/" 2>/dev/null; then
  ok "Math.TAU (v4 replacement for Math.PI2) is referenced"
else
  warn "Math.TAU not found in agents/skills — check migration content"
fi

if grep -rq "Vector2\|Phaser\.Math\.Vector2" "$PLUGIN_DIR/agents/" "$PLUGIN_DIR/skills/" 2>/dev/null; then
  ok "Vector2 (v4 replacement for Geom.Point) is referenced"
else
  warn "Vector2 not found in agents/skills — check migration content"
fi

if grep -rq "Phaser Beam\|phaser.*beam\|beam.*renderer" "$PLUGIN_DIR/agents/" "$PLUGIN_DIR/skills/" 2>/dev/null -i; then
  ok "Phaser Beam renderer is mentioned"
else
  warn "Phaser Beam renderer not mentioned — consider adding to architect agent"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "=================================="
echo "Agents: 4 required"
echo "Skills: 14 required (6 original + 8 new)"
echo "Commands: 4 required"
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

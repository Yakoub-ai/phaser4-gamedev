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

# ── Scaffold ──────────────────────────────────────────────────────────────────
# /phaser-new depends on this producing a correct project. Run it for real (without
# npm install, so this stays offline and fast) and check what it wrote.
info "Scaffold..."
SCAFFOLD="$PLUGIN_DIR/skills/phaser-init/scripts/scaffold.mjs"
TEMPLATE_DIR="$PLUGIN_DIR/skills/phaser-init/template"
if [[ -f "$SCAFFOLD" && -d "$TEMPLATE_DIR" ]]; then
  SC_TMP=$(mktemp -d)
  if node "$SCAFFOLD" "$SC_TMP/game" --title "Validator's <Test>" --no-install >/dev/null 2>&1; then
    ok "scaffold.mjs creates a project"
    for f in package.json tsconfig.json vite.config.ts index.html .gitignore src/main.ts \
             src/scenes/GameScene.ts tests/score.test.ts playtest/smoke.mjs tools/playtest.mjs \
             .github/workflows/ci.yml .github/workflows/deploy-pages.yml; do
      [[ -f "$SC_TMP/game/$f" ]] || error "scaffold did not write $f"
    done
    LEFT=$(grep -rlE '\{\{[A-Z_]+\}\}' "$SC_TMP/game" 2>/dev/null || true)
    [[ -z "$LEFT" ]] && ok "no unresolved template placeholders" || error "unresolved placeholders in: ${LEFT//$SC_TMP\/game\//}"
    cmp -s "$SC_TMP/game/tools/playtest.mjs" "$PLUGIN_DIR/skills/phaser-playtest/scripts/playtest.mjs" \
      && ok "vendored tools/playtest.mjs matches the harness" || error "vendored tools/playtest.mjs differs from the harness"
    if node "$SCAFFOLD" "$SC_TMP/game" --no-install >/dev/null 2>&1; then
      error "scaffold.mjs overwrote an existing project instead of refusing"
    else
      ok "scaffold.mjs refuses to overwrite existing files"
    fi
  else
    error "scaffold.mjs failed: $(node "$SCAFFOLD" "$SC_TMP/game2" --no-install 2>&1 | tail -1)"
  fi
  rm -rf "$SC_TMP"

  # Pinned to a stable Phaser 4 release, never a pre-release tag.
  PHASER_RANGE=$(node -pe "require('$TEMPLATE_DIR/package.json').dependencies.phaser" 2>/dev/null || echo "")
  if [[ "$PHASER_RANGE" =~ ^\^?4\.[0-9]+\.[0-9]+$ ]]; then ok "template pins phaser $PHASER_RANGE"; else error "template phaser range '$PHASER_RANGE' is not a stable 4.x release"; fi

  # The test hook must survive the harness's build mode, or build-mode scenarios go blind.
  grep -q "VITE_PLAYTEST === 'true'" "$TEMPLATE_DIR/src/main.ts" \
    && ok "template exposes __PHASER_GAME__ to playtest builds" || error "template main.ts does not gate __PHASER_GAME__ on VITE_PLAYTEST"
  grep -q "Content-Security-Policy" "$TEMPLATE_DIR/vite.config.ts" \
    && ok "template injects a Content-Security-Policy" || error "template vite.config.ts has no Content-Security-Policy"

  # Supply chain: every action pinned to a full commit SHA.
  UNPINNED=$(grep -rhE '^\s*(-\s*)?uses:' "$TEMPLATE_DIR/.github/workflows" 2>/dev/null | grep -vE '@[0-9a-f]{40}( |$)' || true)
  [[ -z "$UNPINNED" ]] && ok "template workflow actions are pinned to commit SHAs" || error "unpinned actions in template workflows:$(printf '\n        %s' $UNPINNED)"
else
  error "skills/phaser-init/scripts/scaffold.mjs or template/ is missing"
fi
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
check_mentions "Math\.TAU" "Math.TAU (v4 replacement for Math.PI2) is referenced"
check_mentions "Vector2" "Vector2 (v4 replacement for Geom.Point) is referenced"
check_mentions "Beam" "Phaser Beam renderer is mentioned"
check_mentions "enableFilters" "enableFilters() (required before GameObject filters) is referenced"
check_mentions "filters\.internal" "The Filters system (v4 replacement for FX and masks) is referenced"

# Regression guards. Each of these was wrong in a shipped version of this plugin and
# would silently mislead every project that followed it.
#
# These APIs are legitimately *named* in migration docs ("createBitmapMask() was
# removed"), so a bare grep would flag the correct content too. Flag only lines that
# mention one without any marker saying it is gone — i.e. an actual recommendation.
# A mention is *not* a recommendation when the line either negates it (case-insensitive)
# or is structurally an audit/conversion artifact:
#   - a `grep -rn '...'` line is a migration audit command, listing what to search FOR
#   - a markdown table row `| old API | new API |` is a conversion table
NEGATION='remove|rather than|removed|no longer|not exist|does not|do not|don.t|never|instead|replaced|was |were |v3|phaser 3|gone|deprecated|not a method|not methods|\bno\b|not\b|avoid|stale|older than|neither|nor '
guard_not_recommended() {
  local needle="$1" label="$2" hits
  hits=$(grep -rInI -- "$needle" \
           "$PLUGIN_DIR/agents/" "$PLUGIN_DIR/skills/" "$PLUGIN_DIR/commands/" \
           "$PLUGIN_DIR/hooks/" "$PLUGIN_DIR/README.md" "$PLUGIN_DIR/CLAUDE.md" 2>/dev/null \
         | grep -viE "$NEGATION" \
         | grep -vE 'grep -[a-zA-Z]*n' \
         | grep -vE '^[^:]+:[0-9]+:\s*\|.*\|.*\|' || true)
  if [[ -n "$hits" ]]; then
    error "$label"
    while IFS= read -r line; do echo "        ${line#"$PLUGIN_DIR"/}"; done <<< "$hits"
  else
    ok "$label"
  fi
}

# `phaser@beta` resolves to 4.0.0-rc.7, older than `latest`. Recommending it is a downgrade.
guard_not_recommended "npm install phaser@beta" "'npm install phaser@beta' is not recommended anywhere (that tag is older than stable)"
# The v3 type recipe hard-fails on v4 with TS2688.
guard_not_recommended 'types": \["Phaser"\]' "the v3 typeRoots/types:[\"Phaser\"] recipe is not recommended (it fails on v4 with TS2688)"
# These do not exist in Phaser 4 at all.
guard_not_recommended "setScissor" "camera.setScissor() is not recommended (no such method in v4)"
guard_not_recommended "createBitmapMask\|createGeometryMask" "createBitmapMask/createGeometryMask are not recommended (removed in v4)"
guard_not_recommended "tintFill" "tintFill is not recommended (use setTintMode in v4)"
guard_not_recommended '"phaser": "beta"' "no package.json example pins phaser to the beta tag"
# Vite 8 (Rolldown/Oxc): terser is not bundled, and manualChunks lost its object form.
guard_not_recommended "minify: 'terser'" "minify: 'terser' is not recommended (Vite 8 build fails without terser)"
guard_not_recommended "manualChunks: {" "the manualChunks object form is not recommended (unsupported in Vite 8)"
# A DEV-only hook disappears in the harness's build mode, blinding every build-mode scenario.
guard_not_recommended "import.meta.env.DEV) (window as any).__PHASER_GAME__" "the __PHASER_GAME__ hook is never taught as DEV-only (it must include VITE_PLAYTEST)"
guard_not_recommended "still in release candidate" "Phaser 4 is not described as a release candidate (stable since 4.0.0)"
guard_not_recommended "peaceiris/actions-gh-pages" "GitHub Pages deploys use the official Pages actions"

# Every `skills/<name>/<sub>/<file>` path cited in prose must resolve. These
# cross-skill pointers are how a skill hands off to deeper reference material;
# a stale one sends the agent to a file that isn't there.
DEADLINKS=0
while IFS= read -r ref; do
  [[ -e "$PLUGIN_DIR/$ref" ]] || { error "broken cross-reference: $ref"; DEADLINKS=$((DEADLINKS + 1)); }
done < <(grep -rhoE 'skills/[a-z0-9-]+/(references|examples|scripts|template)/[A-Za-z0-9_.-]+' \
           "$PLUGIN_DIR/skills" "$PLUGIN_DIR/agents" "$PLUGIN_DIR/commands" "$PLUGIN_DIR/CLAUDE.md" 2>/dev/null | sort -u)
[[ "$DEADLINKS" -eq 0 ]] && ok "all cross-skill file references resolve"
echo ""

# ── Advertised counts ─────────────────────────────────────────────────────────
# Manifest descriptions quote "N skills, N commands, N agents"; they drifted before.
info "Advertised counts..."
COUNTS_OK=1
for manifest in .claude-plugin/plugin.json .claude-plugin/marketplace.json README.md; do
  text=$(cat "$PLUGIN_DIR/$manifest")
  for pair in "skills:$SKILL_COUNT" "commands:$CMD_COUNT" "agents:$AGENT_COUNT"; do
    noun="${pair%%:*}"; want="${pair##*:}"
    while IFS= read -r got; do
      [[ -z "$got" ]] && continue
      [[ "$got" == "$want" ]] || { error "$manifest says $got $noun, disk has $want"; COUNTS_OK=0; }
    done < <(grep -oiE "\b[0-9]+ (portable |claude (code )?|claude slash )?(\*\*)?$noun\b" <<< "$text" | grep -oE '^[0-9]+' | sort -u)
  done
done
[[ "$COUNTS_OK" -eq 1 ]] && ok "advertised skill/command/agent counts match disk"
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

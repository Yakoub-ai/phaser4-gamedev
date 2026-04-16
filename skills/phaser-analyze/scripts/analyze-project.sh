#!/usr/bin/env bash
# analyze-project.sh — Phaser 4 brownfield project analysis
# Usage: bash analyze-project.sh [project-dir]
# If no arg given, uses current directory.

set -euo pipefail

PROJECT_DIR="${1:-.}"
ERRORS=0
WARNINGS=0

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

error() { echo -e "${RED}[ERROR]${NC} $1"; ((ERRORS++)); }
warn()  { echo -e "${YELLOW}[WARN]${NC} $1";  ((WARNINGS++)); }
ok()    { echo -e "${GREEN}[OK]${NC} $1"; }
info()  { echo -e "${CYAN}[INFO]${NC} $1"; }

echo ""
echo "=== Phaser 4 Project Analyzer ==="
echo "Analyzing: $PROJECT_DIR"
echo ""

SRC_DIR="$PROJECT_DIR/src"

# ── 0. Verify this is a Phaser project ───────────────────────────────────────
if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
  error "No package.json found. Is this a Phaser project?"
  echo ""
  echo "=================================="
  echo -e "${RED}Cannot analyze — not a valid project directory.${NC}"
  exit 1
fi

if ! grep -q '"phaser"' "$PROJECT_DIR/package.json" 2>/dev/null; then
  error "No phaser dependency in package.json. Is this a Phaser project?"
  echo ""
  echo "=================================="
  echo -e "${RED}Cannot analyze — phaser not found in dependencies.${NC}"
  exit 1
fi

if [[ ! -d "$SRC_DIR" ]]; then
  error "No src/ directory found."
  echo ""
  echo "=================================="
  echo -e "${RED}Cannot analyze — no source directory.${NC}"
  exit 1
fi

# ── 1. Discovery — Gather project metrics ────────────────────────────────────
info "Phase 1: Discovery"
echo ""

# Count source files
TS_FILES=$(find "$SRC_DIR" -name "*.ts" 2>/dev/null | wc -l)
JS_FILES=$(find "$SRC_DIR" -name "*.js" 2>/dev/null | wc -l)
TOTAL_FILES=$((TS_FILES + JS_FILES))
info "Source files: $TOTAL_FILES ($TS_FILES .ts, $JS_FILES .js)"

# Count lines of code
if [[ "$TOTAL_FILES" -gt 0 ]]; then
  TOTAL_LOC=$(find "$SRC_DIR" \( -name "*.ts" -o -name "*.js" \) -exec cat {} + 2>/dev/null | wc -l)
  info "Lines of code: $TOTAL_LOC"
else
  TOTAL_LOC=0
  warn "No source files found in src/"
fi

# Count scenes
SCENE_COUNT=$(find "$SRC_DIR" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | xargs grep -l "extends Phaser\.Scene" 2>/dev/null | wc -l)
info "Scene count: $SCENE_COUNT"

# Count custom game objects
GAMEOBJECT_COUNT=$(find "$SRC_DIR" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | xargs grep -l "extends Phaser\.GameObjects\.\|extends Phaser\.Physics\." 2>/dev/null | wc -l)
info "Custom game object classes: $GAMEOBJECT_COUNT"

# Estimate complexity
if [[ "$TOTAL_LOC" -lt 500 ]]; then
  COMPLEXITY="small"
elif [[ "$TOTAL_LOC" -lt 2000 ]]; then
  COMPLEXITY="medium"
else
  COMPLEXITY="large"
fi
info "Estimated complexity: $COMPLEXITY"

echo ""

# ── 2. Architecture — Structural checks ──────────────────────────────────────
info "Phase 2: Architecture Assessment"
echo ""

ARCH_ISSUES=0

# Check for module-global mutable state
GLOBAL_STATE=$(grep -rn "^let \|^var " "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
if [[ "$GLOBAL_STATE" -gt 0 ]]; then
  warn "Found $GLOBAL_STATE module-global mutable declaration(s) (let/var at top level)"
  grep -rn "^let \|^var " "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | head -5
  ((ARCH_ISSUES++))
else
  ok "No module-global mutable state found"
fi

# Check for window globals
WINDOW_GLOBALS=$(grep -rn "window\." "$SRC_DIR" 2>/dev/null | grep -v "node_modules\|addEventListener\|innerWidth\|innerHeight\|devicePixelRatio" | wc -l)
if [[ "$WINDOW_GLOBALS" -gt 0 ]]; then
  warn "Found $WINDOW_GLOBALS window.* usage(s) (potential global state)"
  grep -rn "window\." "$SRC_DIR" 2>/dev/null | grep -v "node_modules\|addEventListener\|innerWidth\|innerHeight\|devicePixelRatio" | head -5
  ((ARCH_ISSUES++))
else
  ok "No window.* global state found"
fi

# Check for scattered preload
PRELOAD_FILES=$(find "$SRC_DIR" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | xargs grep -l "preload()" 2>/dev/null | wc -l)
if [[ "$PRELOAD_FILES" -gt 2 ]]; then
  warn "Asset loading scattered across $PRELOAD_FILES files. Consider centralizing in a PreloaderScene"
  ((ARCH_ISSUES++))
elif [[ "$PRELOAD_FILES" -gt 0 ]]; then
  ok "Asset loading in $PRELOAD_FILES file(s)"
fi

# Check for scenes directory convention
if [[ -d "$SRC_DIR/scenes" ]]; then
  ok "src/scenes/ directory exists"
else
  if [[ "$SCENE_COUNT" -gt 0 ]]; then
    warn "Scene files not in src/scenes/ directory"
    ((ARCH_ISSUES++))
  fi
fi

echo ""

# ── 3. Performance — Runtime risk checks ─────────────────────────────────────
info "Phase 3: Performance Audit"
echo ""

PERF_ISSUES=0

# Check for physics groups without maxSize (object pooling)
GROUPS_TOTAL=$(grep -rn "this\.physics\.add\.group" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
GROUPS_POOLED=$(grep -rn "this\.physics\.add\.group" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | grep "maxSize" | wc -l)
GROUPS_UNPOOLED=$((GROUPS_TOTAL - GROUPS_POOLED))
if [[ "$GROUPS_UNPOOLED" -gt 0 ]]; then
  warn "Found $GROUPS_UNPOOLED physics group(s) without maxSize (no object pooling)"
  grep -rn "this\.physics\.add\.group" "$SRC_DIR" 2>/dev/null | grep -v "node_modules\|maxSize" | head -5
  ((PERF_ISSUES++))
elif [[ "$GROUPS_TOTAL" -gt 0 ]]; then
  ok "All $GROUPS_TOTAL physics group(s) have maxSize (pooling enabled)"
fi

# Check for particle emitters without maxParticles
EMITTER_TOTAL=$(grep -rn "addEmitter\|createEmitter\|add\.particles" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
EMITTER_CAPPED=$(grep -rn "addEmitter\|createEmitter\|add\.particles" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | grep "maxParticles" | wc -l)
EMITTER_UNCAPPED=$((EMITTER_TOTAL - EMITTER_CAPPED))
if [[ "$EMITTER_UNCAPPED" -gt 0 ]]; then
  warn "Found $EMITTER_UNCAPPED particle emitter(s) without maxParticles cap"
  grep -rn "addEmitter\|createEmitter\|add\.particles" "$SRC_DIR" 2>/dev/null | grep -v "node_modules\|maxParticles" | head -5
  ((PERF_ISSUES++))
elif [[ "$EMITTER_TOTAL" -gt 0 ]]; then
  ok "All $EMITTER_TOTAL particle emitter(s) have maxParticles cap"
fi

# Check for dynamic groups used for static bodies
STATIC_CANDIDATES=$(grep -rn "this\.physics\.add\.group" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | grep -iE "platform|wall|ground|floor|boundary|tile" | grep -v "staticGroup" | wc -l)
if [[ "$STATIC_CANDIDATES" -gt 0 ]]; then
  warn "Found $STATIC_CANDIDATES physics group(s) for likely static bodies (platforms/walls) — should be staticGroup"
  grep -rn "this\.physics\.add\.group" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | grep -iE "platform|wall|ground|floor|boundary|tile" | grep -v "staticGroup" | head -5
  ((PERF_ISSUES++))
else
  ok "No dynamic groups detected for static-body candidates"
fi

# Check texture atlas usage
IMAGE_LOADS=$(grep -rn "this\.load\.image(" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
ATLAS_LOADS=$(grep -rn "this\.load\.atlas(" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
if [[ "$IMAGE_LOADS" -gt 15 ]]; then
  warn "Found $IMAGE_LOADS individual image loads vs $ATLAS_LOADS atlas loads. Consider packing into texture atlases"
  ((PERF_ISSUES++))
elif [[ "$IMAGE_LOADS" -gt 0 ]]; then
  ok "Asset loading: $IMAGE_LOADS individual images, $ATLAS_LOADS atlases"
fi

echo ""

# ── 4. API Correctness ───────────────────────────────────────────────────────
info "Phase 4: API Correctness"
echo ""

API_ISSUES=0

# Check for v3 removed APIs
V3_PATTERNS=("Geom\.Point" "Math\.PI2" "Phaser\.Structs" "Camera3D" "Layer3D" "FacebookInstant" "Create\.GenerateTexture" "TileSprite\.setCrop")
V3_NAMES=("Geom.Point" "Math.PI2" "Phaser.Structs" "Camera3D" "Layer3D" "FacebookInstant" "Create.GenerateTexture" "TileSprite.setCrop")

for i in "${!V3_PATTERNS[@]}"; do
  COUNT=$(grep -rn "${V3_PATTERNS[$i]}" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
  if [[ "$COUNT" -gt 0 ]]; then
    error "Found $COUNT use(s) of ${V3_NAMES[$i]} (removed in Phaser 4)"
    grep -rn "${V3_PATTERNS[$i]}" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | head -3
    ((API_ISSUES++))
  fi
done

if [[ "$API_ISSUES" -eq 0 ]]; then
  ok "No removed Phaser 3 APIs detected"
fi

# Check TypeScript escape hatches
AS_ANY_COUNT=$(grep -rn "as any" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
if [[ "$AS_ANY_COUNT" -gt 5 ]]; then
  warn "Found $AS_ANY_COUNT 'as any' casts — excessive type escaping hides bugs"
  ((API_ISSUES++))
elif [[ "$AS_ANY_COUNT" -gt 0 ]]; then
  info "Found $AS_ANY_COUNT 'as any' cast(s)"
fi

TS_IGNORE_COUNT=$(grep -rn "@ts-ignore\|@ts-expect-error" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | wc -l)
if [[ "$TS_IGNORE_COUNT" -gt 0 ]]; then
  warn "Found $TS_IGNORE_COUNT @ts-ignore/@ts-expect-error directive(s)"
  grep -rn "@ts-ignore\|@ts-expect-error" "$SRC_DIR" 2>/dev/null | grep -v "node_modules" | head -5
  ((API_ISSUES++))
fi

echo ""

# ── 5. Best Practices ────────────────────────────────────────────────────────
info "Phase 5: Best Practice Check"
echo ""

BP_ISSUES=0

# Check for event listener cleanup
SCENES_WITH_ON=$(find "$SRC_DIR" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | xargs grep -l "this\.events\.on\|this\.input\.on" 2>/dev/null | wc -l)
SCENES_WITH_OFF=$(find "$SRC_DIR" \( -name "*.ts" -o -name "*.js" \) 2>/dev/null | xargs grep -l "this\.events\.off\|shutdown\|this\.events\.once.*shutdown" 2>/dev/null | wc -l)
if [[ "$SCENES_WITH_ON" -gt 0 && "$SCENES_WITH_OFF" -eq 0 ]]; then
  warn "Found $SCENES_WITH_ON file(s) registering event listeners but none with cleanup (events.off or shutdown handler)"
  ((BP_ISSUES++))
elif [[ "$SCENES_WITH_ON" -gt "$SCENES_WITH_OFF" ]]; then
  warn "Some files register event listeners without cleanup ($SCENES_WITH_ON with .on, $SCENES_WITH_OFF with cleanup)"
  ((BP_ISSUES++))
elif [[ "$SCENES_WITH_ON" -gt 0 ]]; then
  ok "Event listeners have corresponding cleanup"
fi

# Check for console statements
CONSOLE_COUNT=$(grep -rn "console\.\(log\|warn\|error\)" "$SRC_DIR" 2>/dev/null | grep -v "node_modules\|import\.meta\.env" | wc -l)
if [[ "$CONSOLE_COUNT" -gt 5 ]]; then
  warn "Found $CONSOLE_COUNT unguarded console statement(s) — gate behind import.meta.env.DEV"
  ((BP_ISSUES++))
elif [[ "$CONSOLE_COUNT" -gt 0 ]]; then
  info "Found $CONSOLE_COUNT console statement(s)"
fi

# Check for physics debug enabled
DEBUG_PHYSICS=$(grep -rn "debug:\s*true" "$SRC_DIR" 2>/dev/null | grep -iE "arcade|matter|physics" | wc -l)
if [[ "$DEBUG_PHYSICS" -gt 0 ]]; then
  warn "Physics debug: true found in $DEBUG_PHYSICS place(s) — disable for production"
  grep -rn "debug:\s*true" "$SRC_DIR" 2>/dev/null | grep -iE "arcade|matter|physics" | head -3
  ((BP_ISSUES++))
else
  ok "No physics debug mode left enabled"
fi

echo ""

# ── Summary ──────────────────────────────────────────────────────────────────
echo "=================================="
echo "        ANALYSIS SUMMARY"
echo "=================================="
echo ""
info "Project: $TOTAL_FILES files, $TOTAL_LOC LOC, $SCENE_COUNT scene(s), $COMPLEXITY complexity"
echo ""

# Calculate score
TOTAL_ISSUES=$((ARCH_ISSUES + PERF_ISSUES + API_ISSUES + BP_ISSUES))

if [[ "$ERRORS" -gt 0 ]]; then
  if [[ "$ERRORS" -ge 3 ]]; then
    GRADE="D"
  else
    GRADE="C"
  fi
elif [[ "$WARNINGS" -gt 5 ]]; then
  GRADE="C"
elif [[ "$WARNINGS" -gt 2 ]]; then
  GRADE="B"
else
  GRADE="A"
fi

echo -e "Architecture issues:  $ARCH_ISSUES"
echo -e "Performance issues:   $PERF_ISSUES"
echo -e "API issues:           $API_ISSUES"
echo -e "Best practice issues: $BP_ISSUES"
echo ""

if [[ "$GRADE" == "A" ]]; then
  echo -e "${GREEN}Grade: $GRADE — Project is well-structured${NC}"
elif [[ "$GRADE" == "B" ]]; then
  echo -e "${GREEN}Grade: $GRADE — Mostly good, minor improvements suggested${NC}"
elif [[ "$GRADE" == "C" ]]; then
  echo -e "${YELLOW}Grade: $GRADE — Functional but needs attention${NC}"
else
  echo -e "${RED}Grade: $GRADE — Significant issues found, refactoring recommended${NC}"
fi

echo ""
echo -e "Total: ${RED}$ERRORS error(s)${NC}, ${YELLOW}$WARNINGS warning(s)${NC}"
echo ""

if [[ "$ERRORS" -gt 0 ]]; then
  echo "Run /phaser-migrate to fix Phaser v3 API issues."
fi
if [[ "$PERF_ISSUES" -gt 0 ]]; then
  echo "Run /phaser-physics to fix pooling and physics group issues."
fi
echo "Run the phaser-analyze skill for a full deep-dive code review."
echo ""

exit 0

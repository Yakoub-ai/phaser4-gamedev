#!/usr/bin/env bash
# validate-project.sh — Phaser 4 project health check
# Usage: bash validate-project.sh [project-dir]
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
echo "=== Phaser 4 Project Validator ==="
echo "Checking: $PROJECT_DIR"
echo ""

# ── 1. package.json checks ────────────────────────────────────────────────────
info "Checking package.json..."

if [[ ! -f "$PROJECT_DIR/package.json" ]]; then
  error "package.json not found. Run: npm init -y && npm install phaser@beta"
else
  # Check phaser dependency
  if grep -q '"phaser"' "$PROJECT_DIR/package.json"; then
    PHASER_VER=$(node -e "const p=require('$PROJECT_DIR/package.json'); console.log(p.dependencies?.phaser||p.devDependencies?.phaser||'not found')" 2>/dev/null || echo "not found")
    if echo "$PHASER_VER" | grep -qE "^4|beta|rc"; then
      ok "Phaser dependency: $PHASER_VER"
    else
      warn "Phaser version may not be v4: '$PHASER_VER'. Run: npm install phaser@beta"
    fi
  else
    error "No phaser dependency in package.json. Run: npm install phaser@beta"
  fi

  # Check for dev script
  if grep -q '"dev"' "$PROJECT_DIR/package.json"; then
    ok "Dev script found"
  else
    warn "No 'dev' script in package.json. Add: \"dev\": \"vite\""
  fi

  # Check for build script
  if grep -q '"build"' "$PROJECT_DIR/package.json"; then
    ok "Build script found"
  else
    warn "No 'build' script in package.json. Add: \"build\": \"tsc && vite build\""
  fi
fi

echo ""

# ── 2. node_modules check ─────────────────────────────────────────────────────
info "Checking node_modules..."

if [[ ! -d "$PROJECT_DIR/node_modules/phaser" ]]; then
  error "node_modules/phaser not found. Run: npm install"
else
  # Check installed Phaser version
  if [[ -f "$PROJECT_DIR/node_modules/phaser/package.json" ]]; then
    INSTALLED_VER=$(node -e "console.log(require('$PROJECT_DIR/node_modules/phaser/package.json').version)" 2>/dev/null || echo "unknown")
    if echo "$INSTALLED_VER" | grep -qE "^4"; then
      ok "Phaser $INSTALLED_VER installed"
    else
      warn "Installed Phaser is $INSTALLED_VER — expected 4.x. Run: npm install phaser@beta"
    fi
  fi
fi

echo ""

# ── 3. TypeScript config ──────────────────────────────────────────────────────
info "Checking TypeScript config..."

if [[ -f "$PROJECT_DIR/tsconfig.json" ]]; then
  if grep -q "typeRoots" "$PROJECT_DIR/tsconfig.json"; then
    ok "tsconfig.json has typeRoots"
  else
    error "tsconfig.json missing typeRoots. Add: \"typeRoots\": [\"./node_modules/phaser/types\"]"
  fi

  if grep -q '"Phaser"' "$PROJECT_DIR/tsconfig.json"; then
    ok "tsconfig.json has Phaser in types"
  else
    error "tsconfig.json missing types. Add: \"types\": [\"Phaser\"]"
  fi
else
  info "No tsconfig.json (JavaScript project — that's fine)"
fi

echo ""

# ── 4. Source files check ─────────────────────────────────────────────────────
info "Checking source files..."

SRC_DIR="$PROJECT_DIR/src"
if [[ -d "$SRC_DIR" ]]; then
  ok "src/ directory exists"

  if [[ -f "$SRC_DIR/main.ts" ]] || [[ -f "$SRC_DIR/main.js" ]]; then
    ok "main entry file found"
  else
    warn "No src/main.ts or src/main.js found"
  fi

  SCENE_COUNT=$(find "$SRC_DIR" -name "*.ts" -o -name "*.js" 2>/dev/null | xargs grep -l "extends Phaser.Scene" 2>/dev/null | wc -l)
  if [[ "$SCENE_COUNT" -gt 0 ]]; then
    ok "$SCENE_COUNT scene file(s) found"
  else
    warn "No files found with 'extends Phaser.Scene'. Is this a new project?"
  fi
else
  warn "No src/ directory found"
fi

echo ""

# ── 5. Phaser 3 deprecated API scan ──────────────────────────────────────────
if [[ -d "$SRC_DIR" ]]; then
  info "Scanning for removed Phaser 3 APIs..."

  # Check Geom.Point usage
  POINT_COUNT=$(grep -rn "Geom\.Point\|new Phaser\.Geom\.Point" "$SRC_DIR" 2>/dev/null | wc -l)
  if [[ "$POINT_COUNT" -gt 0 ]]; then
    error "Found $POINT_COUNT use(s) of Phaser.Geom.Point (removed in v4). Replace with Phaser.Math.Vector2"
    grep -rn "Geom\.Point" "$SRC_DIR" 2>/dev/null | head -5
  else
    ok "No Geom.Point usage found"
  fi

  # Check Math.PI2
  PI2_COUNT=$(grep -rn "Math\.PI2\b" "$SRC_DIR" 2>/dev/null | wc -l)
  if [[ "$PI2_COUNT" -gt 0 ]]; then
    error "Found $PI2_COUNT use(s) of Math.PI2 (removed in v4). Replace with Math.TAU"
    grep -rn "Math\.PI2" "$SRC_DIR" 2>/dev/null | head -5
  else
    ok "No Math.PI2 usage found"
  fi

  # Check Structs
  STRUCTS_COUNT=$(grep -rn "Phaser\.Structs\." "$SRC_DIR" 2>/dev/null | wc -l)
  if [[ "$STRUCTS_COUNT" -gt 0 ]]; then
    error "Found $STRUCTS_COUNT use(s) of Phaser.Structs (removed in v4). Use native Map/Set"
    grep -rn "Phaser\.Structs\." "$SRC_DIR" 2>/dev/null | head -5
  else
    ok "No Phaser.Structs usage found"
  fi

  # Check removed plugins
  PLUGIN_COUNT=$(grep -rn "Camera3D\|Layer3D\|FacebookInstant\|SpinePlugin\|SpineFile" "$SRC_DIR" 2>/dev/null | wc -l)
  if [[ "$PLUGIN_COUNT" -gt 0 ]]; then
    error "Found $PLUGIN_COUNT use(s) of removed plugins (Camera3D/Layer3D/Facebook/Spine)"
    grep -rn "Camera3D\|Layer3D\|FacebookInstant\|SpinePlugin" "$SRC_DIR" 2>/dev/null | head -5
  else
    ok "No removed plugin usage found"
  fi

  # Check DynamicTexture/RenderTexture for missing render()
  DYN_TEX_COUNT=$(grep -rn "addDynamicTexture\|addRenderTexture" "$SRC_DIR" 2>/dev/null | wc -l)
  if [[ "$DYN_TEX_COUNT" -gt 0 ]]; then
    warn "Found $DYN_TEX_COUNT DynamicTexture/RenderTexture creation(s). Ensure .render() is called after drawing."
  fi

  echo ""
fi

# ── 6. Vite config check ──────────────────────────────────────────────────────
info "Checking Vite config..."

if [[ -f "$PROJECT_DIR/vite.config.ts" ]] || [[ -f "$PROJECT_DIR/vite.config.js" ]]; then
  if grep -q "base:" "$PROJECT_DIR/vite.config.ts" 2>/dev/null || grep -q "base:" "$PROJECT_DIR/vite.config.js" 2>/dev/null; then
    ok "vite.config has base setting (good for deployment)"
  else
    warn "vite.config missing 'base' setting. Add base: './' for itch.io/subdirectory hosting"
  fi
else
  warn "No vite.config found. Create vite.config.ts for production builds"
fi

echo ""

# ── 7. Public assets ──────────────────────────────────────────────────────────
info "Checking public assets..."
if [[ -d "$PROJECT_DIR/public" ]]; then
  ok "public/ directory exists (Vite will serve these as-is)"
else
  warn "No public/ directory. Create public/assets/ and put game assets there"
fi

echo ""

# ── Summary ───────────────────────────────────────────────────────────────────
echo "=================================="
if [[ "$ERRORS" -eq 0 && "$WARNINGS" -eq 0 ]]; then
  echo -e "${GREEN}All checks passed! Project looks good.${NC}"
elif [[ "$ERRORS" -eq 0 ]]; then
  echo -e "${YELLOW}$WARNINGS warning(s). Project can build but review warnings.${NC}"
else
  echo -e "${RED}$ERRORS error(s), $WARNINGS warning(s). Fix errors before building.${NC}"
fi
echo ""

exit "$ERRORS"

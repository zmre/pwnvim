#!/usr/bin/env bash
# pwnvim configuration validation script
# Run this to check for errors before committing

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ERRORS=0
WARNINGS=0

info() {
  echo -e "${BLUE}[INFO]${NC} $1"
}

success() {
  echo -e "${GREEN}[PASS]${NC} $1"
}

warn() {
  echo -e "${YELLOW}[WARN]${NC} $1"
  ((WARNINGS++)) || true
}

error() {
  echo -e "${RED}[FAIL]${NC} $1"
  ((ERRORS++)) || true
}

section() {
  echo ""
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
  echo -e "${BLUE}  $1${NC}"
  echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# ============================================================================
# Step 1: Lua Linting with luacheck
# ============================================================================
section "Lua Linting (luacheck)"

if command -v luacheck &> /dev/null; then
  if luacheck . --no-color 2>&1; then
    success "All Lua files pass linting"
  else
    error "Lua linting failed"
  fi
else
  warn "luacheck not found, skipping lint check"
fi

# ============================================================================
# Step 2: Neovim Startup Test
# ============================================================================
section "Neovim Startup Test"

NVIM_CMD="${NVIM_CMD:-nvim}"

if ! command -v "$NVIM_CMD" &> /dev/null; then
  error "nvim not found in PATH"
else
  # Test normal startup
  info "Testing normal startup..."
  STARTUP_OUTPUT=$(mktemp)
  if $NVIM_CMD --headless \
    -c "lua vim.defer_fn(function() print('STARTUP_OK') vim.cmd('qa!') end, 100)" \
    2>&1 | tee "$STARTUP_OUTPUT" | grep -q "STARTUP_OK"; then

    # Check for errors in output
    if grep -iE "^E[0-9]+:|error|exception" "$STARTUP_OUTPUT" | grep -v "STARTUP_OK" > /dev/null 2>&1; then
      error "Errors detected during startup:"
      grep -iE "^E[0-9]+:|error|exception" "$STARTUP_OUTPUT" | head -10
    else
      success "Normal startup completed without errors"
    fi
  else
    error "Neovim startup failed or timed out"
    cat "$STARTUP_OUTPUT"
  fi
  rm -f "$STARTUP_OUTPUT"

  # Test SimpleUI startup
  info "Testing SimpleUI startup..."
  STARTUP_OUTPUT=$(mktemp)
  if SIMPLEUI=1 $NVIM_CMD --headless \
    -c "lua vim.defer_fn(function() print('STARTUP_OK') vim.cmd('qa!') end, 100)" \
    2>&1 | tee "$STARTUP_OUTPUT" | grep -q "STARTUP_OK"; then

    if grep -iE "^E[0-9]+:|error|exception" "$STARTUP_OUTPUT" | grep -v "STARTUP_OK" > /dev/null 2>&1; then
      error "Errors detected during SimpleUI startup:"
      grep -iE "^E[0-9]+:|error|exception" "$STARTUP_OUTPUT" | head -10
    else
      success "SimpleUI startup completed without errors"
    fi
  else
    error "SimpleUI startup failed or timed out"
    cat "$STARTUP_OUTPUT"
  fi
  rm -f "$STARTUP_OUTPUT"
fi

# ============================================================================
# Step 3: Plugin Loading Verification
# ============================================================================
section "Plugin Loading Verification"

PLUGIN_CHECK=$(mktemp)
cat > "$PLUGIN_CHECK" << 'EOF'
-- Defer the check to run after full initialization
vim.defer_fn(function()
  local failed = {}
  local passed = {}

  local function check_require(name, mod)
    local ok = pcall(require, mod)
    if ok then
      table.insert(passed, name)
    else
      table.insert(failed, name)
    end
  end

  local function check_global(name, global_name)
    if _G[global_name] ~= nil then
      table.insert(passed, name)
    else
      table.insert(failed, name)
    end
  end

  -- Check core plugins
  -- Note: snacks.nvim is validated by startup test (creates Snacks global on init)
  check_require("which-key", "which-key")
  check_require("treesitter", "nvim-treesitter")
  check_require("gitsigns", "gitsigns")
  check_require("lualine", "lualine")
  check_require("blink.cmp", "blink.cmp")
  check_require("oil", "oil")
  check_require("conform", "conform")
  check_require("nvim-lint", "lint")
  check_require("trouble", "trouble")
  check_require("flash", "flash")

  -- Output results
  print("PLUGIN_RESULTS_START")
  print("PASSED:" .. table.concat(passed, ","))
  print("FAILED:" .. table.concat(failed, ","))
  print("PLUGIN_RESULTS_END")

  vim.cmd("qa!")
end, 100)
EOF

PLUGIN_OUTPUT=$(mktemp)
$NVIM_CMD --headless -c "luafile $PLUGIN_CHECK" 2>&1 | tee "$PLUGIN_OUTPUT"

if grep -q "PLUGIN_RESULTS_START" "$PLUGIN_OUTPUT"; then
  # Extract results using portable sed (handles concatenated output from headless mode)
  # The output may be: PLUGIN_RESULTS_STARTPASSED:a,b,cFAILED:PLUGIN_RESULTS_END
  RAW_OUTPUT=$(cat "$PLUGIN_OUTPUT" | tr -d '\n')
  PASSED=$(echo "$RAW_OUTPUT" | sed 's/.*PASSED:\([^F]*\)FAILED:.*/\1/' | sed 's/,$//')
  FAILED=$(echo "$RAW_OUTPUT" | sed 's/.*FAILED:\([^P]*\)PLUGIN_RESULTS_END.*/\1/' | sed 's/,$//')

  if [ -n "$PASSED" ]; then
    success "Plugins loaded: $PASSED"
  fi

  # Check if FAILED contains actual plugin names (not empty or just whitespace)
  FAILED_CLEAN=$(echo "$FAILED" | tr -d ' \n')
  if [ -n "$FAILED_CLEAN" ]; then
    error "Plugins failed to load: $FAILED"
  else
    success "No plugin loading failures"
  fi
else
  error "Plugin check script failed to run"
fi

rm -f "$PLUGIN_CHECK" "$PLUGIN_OUTPUT"

# ============================================================================
# Step 4: Checkhealth Parsing
# ============================================================================
section "Checkhealth Analysis"

HEALTH_OUTPUT=$(mktemp)
info "Running checkhealth (this may take a moment)..."

# Run checkhealth and capture output
$NVIM_CMD --headless -c "checkhealth" -c "w! $HEALTH_OUTPUT" -c "qa!" 2>/dev/null || true

if [ -f "$HEALTH_OUTPUT" ] && [ -s "$HEALTH_OUTPUT" ]; then
  # Known issues to ignore (providers we don't use, headless limitations)
  IGNORE_PATTERNS=(
    "provider.*python"
    "provider.*ruby"
    "provider.*perl"
    "provider.*node"
    "clipboard"
    "No clipboard tool found"
    "python3.*not available"
    "has.*python3.*not available"
    "TSUpdate"
    "query.*error"
  )

  # Build grep exclude pattern
  EXCLUDE_PATTERN=$(IFS='|'; echo "${IGNORE_PATTERNS[*]}")

  # Find errors that aren't in our ignore list
  # Only match lines that start with error indicators, not config values containing "error"
  REAL_ERRORS=$(grep -E "^[[:space:]]*(ERROR|✗|x\))" "$HEALTH_OUTPUT" | grep -ivE "$EXCLUDE_PATTERN" || true)

  if [ -n "$REAL_ERRORS" ]; then
    error "Checkhealth reported errors:"
    echo "$REAL_ERRORS" | head -20
  else
    success "No unexpected checkhealth errors"
  fi

  # Count warnings for info
  WARN_COUNT=$(grep -icE "WARNING|⚠" "$HEALTH_OUTPUT" || echo "0")
  info "Checkhealth warnings (informational): $WARN_COUNT"
else
  warn "Could not run checkhealth or output was empty"
fi

rm -f "$HEALTH_OUTPUT"

# ============================================================================
# Step 5: LSP Binary Check
# ============================================================================
section "LSP Server Availability"

check_lsp() {
  local name=$1
  local cmd=$2
  if command -v "$cmd" &> /dev/null; then
    success "$name ($cmd) available"
  else
    warn "$name ($cmd) not found"
  fi
}

check_lsp "Rust Analyzer" "rust-analyzer"
check_lsp "Nix Language Server" "nixd"
check_lsp "Lua Language Server" "lua-language-server"
check_lsp "Python (Pyright)" "pyright"
check_lsp "TypeScript" "typescript-language-server"

# ============================================================================
# Step 6: Keymap Conflict Check
# ============================================================================
section "Keymap Conflict Check"

KEYMAP_CHECK=$(mktemp)
cat > "$KEYMAP_CHECK" << 'EOF'
local maps = vim.api.nvim_get_keymap("n")
local seen = {}
local conflicts = {}

for _, map in ipairs(maps) do
  local key = map.lhs
  if seen[key] then
    table.insert(conflicts, key)
  end
  seen[key] = true
end

if #conflicts > 0 then
  print("KEYMAP_CONFLICTS:" .. table.concat(conflicts, ","))
else
  print("KEYMAP_OK")
end

vim.cmd("qa!")
EOF

KEYMAP_OUTPUT=$($NVIM_CMD --headless -c "luafile $KEYMAP_CHECK" 2>&1)

if echo "$KEYMAP_OUTPUT" | grep -q "KEYMAP_OK"; then
  success "No keymap conflicts detected"
elif echo "$KEYMAP_OUTPUT" | grep -q "KEYMAP_CONFLICTS"; then
  CONFLICTS=$(echo "$KEYMAP_OUTPUT" | grep "KEYMAP_CONFLICTS" | cut -d: -f2)
  warn "Potential keymap conflicts: $CONFLICTS"
fi

rm -f "$KEYMAP_CHECK"

# ============================================================================
# Summary
# ============================================================================
section "Summary"

echo ""
if [ $ERRORS -gt 0 ]; then
  echo -e "${RED}✗ Validation failed with $ERRORS error(s) and $WARNINGS warning(s)${NC}"
  exit 1
else
  echo -e "${GREEN}✓ Validation passed with $WARNINGS warning(s)${NC}"
  exit 0
fi

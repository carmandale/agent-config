#!/usr/bin/env bash
#==============================================================================
# test-symlink-parity.sh — Verify install.sh, bootstrap.sh, and README agree
#
# Extracts the symlink paths from each source and checks they match.
# Catches drift like:
#   - install.sh creates ~/.agents/skills but bootstrap.sh checks ~/.codex/skills
#   - README documents ~/.pi/agent/commands but install.sh creates ~/.pi/agent/prompts
#   - New symlink added to install.sh but not to bootstrap.sh or README
#
# Usage:
#   ~/.agent-config/tests/test-symlink-parity.sh
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

INSTALL_SH="$REPO_ROOT/install.sh"
BOOTSTRAP_SH="$REPO_ROOT/scripts/bootstrap.sh"
README_MD="$REPO_ROOT/README.md"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0
ERRORS=()

assert() {
  local name="$1"
  local condition="$2"
  TOTAL=$((TOTAL + 1))
  if eval "$condition"; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} $name"
  else
    FAIL=$((FAIL + 1))
    ERRORS+=("$name")
    echo -e "  ${RED}FAIL${NC} $name"
  fi
}

section() {
  echo -e "\n${BOLD}=== $1 ===${NC}"
}

# Temp files for extracted paths
INSTALL_PATHS=$(mktemp)
BOOTSTRAP_PATHS=$(mktemp)
README_HOW_PATHS=$(mktemp)
cleanup() { rm -f "$INSTALL_PATHS" "$BOOTSTRAP_PATHS" "$README_HOW_PATHS"; }
trap cleanup EXIT

echo -e "${BOLD}Symlink Parity Test Suite${NC}"
echo "Repo: $REPO_ROOT"
echo ""

#==============================================================================
section "1. Source files exist"
#==============================================================================

assert "install.sh exists" "[[ -f '$INSTALL_SH' ]]"
assert "bootstrap.sh exists" "[[ -f '$BOOTSTRAP_SH' ]]"
assert "README.md exists" "[[ -f '$README_MD' ]]"

#==============================================================================
section "2. Extract symlink paths from each source"
#==============================================================================

# install.sh: extract destination paths from create_symlink calls
# Pattern: create_symlink "$SOMETHING" "$HOME/.path/to/thing"
# Normalize: strip $HOME/ prefix, leave relative path
grep 'create_symlink "\$' "$INSTALL_SH" \
  | sed 's/.*"\$HOME\///' \
  | sed 's/".*//' \
  | sort \
  > "$INSTALL_PATHS"

INSTALL_COUNT=$(wc -l < "$INSTALL_PATHS" | tr -d ' ')
assert "install.sh has symlink targets ($INSTALL_COUNT found)" \
  "[[ $INSTALL_COUNT -gt 0 ]]"

# bootstrap.sh: extract check paths from the symlink verification loop
# Pattern: "$HOME/.path/to/thing:$REPO_ROOT/..."
grep '\$HOME/\.' "$BOOTSTRAP_SH" \
  | grep ':\$REPO_ROOT' \
  | sed 's/.*"\$HOME\///' \
  | sed 's/:\$.*//' \
  | sort \
  > "$BOOTSTRAP_PATHS"

BOOTSTRAP_COUNT=$(wc -l < "$BOOTSTRAP_PATHS" | tr -d ' ')
assert "bootstrap.sh has symlink checks ($BOOTSTRAP_COUNT found)" \
  "[[ $BOOTSTRAP_COUNT -gt 0 ]]"

# README.md "How It Works" section: extract paths from the symlink map
# Pattern: ~/.path/to/thing      → ~/.agent-config/...
# Only grab lines inside the "How It Works" code block
# Strategy: take left side of →, strip ~/
sed -n '/^## How It Works/,/^## /p' "$README_MD" \
  | grep '→' \
  | awk -F'→' '{print $1}' \
  | sed 's/^[[:space:]]*//' \
  | sed 's/[[:space:]]*$//' \
  | sed 's|^~/||' \
  | sort \
  > "$README_HOW_PATHS"

README_COUNT=$(wc -l < "$README_HOW_PATHS" | tr -d ' ')
assert "README 'How It Works' has symlink entries ($README_COUNT found)" \
  "[[ $README_COUNT -gt 0 ]]"

#==============================================================================
section "3. install.sh ↔ bootstrap.sh parity"
#==============================================================================

# Every path in install.sh must be checked in bootstrap.sh
INSTALL_ONLY=$(comm -23 "$INSTALL_PATHS" "$BOOTSTRAP_PATHS")
if [[ -n "$INSTALL_ONLY" ]]; then
  echo -e "  ${RED}In install.sh but NOT in bootstrap.sh:${NC}"
  echo "$INSTALL_ONLY" | while read -r p; do echo "    - $p"; done
fi
assert "every install.sh symlink is verified by bootstrap.sh" \
  "[[ -z '$INSTALL_ONLY' ]]"

# Every path in bootstrap.sh should exist in install.sh
BOOTSTRAP_ONLY=$(comm -13 "$INSTALL_PATHS" "$BOOTSTRAP_PATHS")
if [[ -n "$BOOTSTRAP_ONLY" ]]; then
  echo -e "  ${RED}In bootstrap.sh but NOT in install.sh:${NC}"
  echo "$BOOTSTRAP_ONLY" | while read -r p; do echo "    - $p"; done
fi
assert "every bootstrap.sh check corresponds to an install.sh symlink" \
  "[[ -z '$BOOTSTRAP_ONLY' ]]"

assert "install.sh and bootstrap.sh have same count ($INSTALL_COUNT vs $BOOTSTRAP_COUNT)" \
  "[[ '$INSTALL_COUNT' == '$BOOTSTRAP_COUNT' ]]"

#==============================================================================
section "4. install.sh ↔ README 'How It Works' parity"
#==============================================================================

# Every path in install.sh should be documented in README
INSTALL_NOT_IN_README=$(comm -23 "$INSTALL_PATHS" "$README_HOW_PATHS")
if [[ -n "$INSTALL_NOT_IN_README" ]]; then
  echo -e "  ${YELLOW}In install.sh but NOT in README 'How It Works':${NC}"
  echo "$INSTALL_NOT_IN_README" | while read -r p; do echo "    - $p"; done
fi
assert "every install.sh symlink is documented in README" \
  "[[ -z '$INSTALL_NOT_IN_README' ]]"

# Every path in README should exist in install.sh
README_NOT_IN_INSTALL=$(comm -13 "$INSTALL_PATHS" "$README_HOW_PATHS")
if [[ -n "$README_NOT_IN_INSTALL" ]]; then
  echo -e "  ${YELLOW}In README but NOT in install.sh:${NC}"
  echo "$README_NOT_IN_INSTALL" | while read -r p; do echo "    - $p"; done
fi
assert "every README symlink exists in install.sh" \
  "[[ -z '$README_NOT_IN_INSTALL' ]]"

assert "install.sh and README have same count ($INSTALL_COUNT vs $README_COUNT)" \
  "[[ '$INSTALL_COUNT' == '$README_COUNT' ]]"

#==============================================================================
section "5. All three sources agree"
#==============================================================================

ALL_MATCH="true"
if ! diff -q "$INSTALL_PATHS" "$BOOTSTRAP_PATHS" >/dev/null 2>&1; then
  ALL_MATCH="false"
fi
if ! diff -q "$INSTALL_PATHS" "$README_HOW_PATHS" >/dev/null 2>&1; then
  ALL_MATCH="false"
fi

assert "install.sh, bootstrap.sh, and README all have identical symlink sets" \
  "[[ '$ALL_MATCH' == 'true' ]]"

#==============================================================================
section "6. Symlinks actually resolve on this machine"
#==============================================================================

while IFS= read -r rel_path; do
  full_path="$HOME/$rel_path"
  label="~/$rel_path"
  if [[ -L "$full_path" ]]; then
    target=$(readlink "$full_path")
    if [[ -e "$full_path" ]]; then
      assert "$label → resolves" "true"
    else
      assert "$label → BROKEN (target: $target)" "false"
    fi
  elif [[ -e "$full_path" ]]; then
    assert "$label exists but is NOT a symlink (install.sh needs re-run)" "false"
  else
    assert "$label is MISSING (install.sh needs re-run)" "false"
  fi
done < "$INSTALL_PATHS"

#==============================================================================
# Report
#==============================================================================

echo ""
echo -e "${BOLD}════════════════════════════════${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}ALL $TOTAL TESTS PASSED${NC}"
else
  echo -e "${RED}${BOLD}$FAIL of $TOTAL TESTS FAILED${NC}"
  echo ""
  echo "Failed tests:"
  for err in "${ERRORS[@]}"; do
    echo -e "  ${RED}- $err${NC}"
  done
fi
echo -e "${BOLD}════════════════════════════════${NC}"

exit $FAIL

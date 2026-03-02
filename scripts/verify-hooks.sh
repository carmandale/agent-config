#!/usr/bin/env bash
#==============================================================================
# verify-hooks.sh - Integration test for Claude hooks
#
# Verifies that all hook files referenced by settings.json exist and are
# valid (node can parse them). This catches the class of bug where a tracked
# config references untracked dependencies.
#
# Usage:
#   ./scripts/verify-hooks.sh              # Check hook files exist
#   ./scripts/verify-hooks.sh --syntax     # Also verify node can load each .mjs
#   ./scripts/verify-hooks.sh --build      # Also verify a clean build succeeds
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIGS="$REPO_ROOT/configs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

ERRORS=0
WARNINGS=0
CHECKS=0

check_syntax=false
check_build=false
for arg in "$@"; do
  case "$arg" in
    --syntax) check_syntax=true ;;
    --build)  check_build=true ;;
  esac
done

echo ""
echo "═══ Hook Integration Test ═══"
echo ""

#──────────────────────────────────────────────────────────────────────────────
# 1. Verify hooks source is tracked in repo
#──────────────────────────────────────────────────────────────────────────────
echo "─── Source tracked in repo ───"

hooks_baseline="$CONFIGS/claude/hooks"
if [[ -d "$hooks_baseline/src" && -f "$hooks_baseline/package.json" ]]; then
  src_count=$(find "$hooks_baseline/src" -name '*.ts' -not -path '*__tests__*' | wc -l | tr -d ' ')
  echo -e "${GREEN}✓${NC} Hooks source tracked: $src_count .ts files in configs/claude/hooks/src/"
  CHECKS=$((CHECKS + 1))
else
  echo -e "${RED}✗${NC} Hooks source NOT in repo at configs/claude/hooks/"
  ERRORS=$((ERRORS + 1))
fi

#──────────────────────────────────────────────────────────────────────────────
# 2. Verify settings.json hook paths resolve
#──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── settings.json hook paths ───"

settings="$CONFIGS/claude/settings.json"
if [[ ! -f "$settings" ]]; then
  echo -e "${RED}✗${NC} settings.json not found"
  ERRORS=$((ERRORS + 1))
else
  hook_paths=$(grep -oE '(\$HOME|~)/\.claude/hooks/[^"\\]+' "$settings" \
    | sed "s|\\\$HOME|$HOME|g; s|^~|$HOME|" \
    | sort -u)

  total=0
  missing=0
  while IFS= read -r hp; do
    [[ -z "$hp" ]] && continue
    total=$((total + 1))
    label="${hp/#$HOME/~}"
    if [[ -f "$hp" ]]; then
      CHECKS=$((CHECKS + 1))
    else
      echo -e "${RED}✗${NC} MISSING: $label"
      missing=$((missing + 1))
      ERRORS=$((ERRORS + 1))
    fi
  done <<< "$hook_paths"

  if [[ $missing -eq 0 ]]; then
    echo -e "${GREEN}✓${NC} All $total hook paths resolve"
  else
    echo -e "${RED}✗${NC} $missing of $total hook paths missing"
  fi
fi

#──────────────────────────────────────────────────────────────────────────────
# 3. Verify no hardcoded user paths in source
#──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── No hardcoded user paths ───"

  # Exclude test files and generic test fixtures like /Users/test/
if grep -rE '/Users/[a-z]+' "$hooks_baseline/src/" --include='*.ts' 2>/dev/null \
    | grep -v '__tests__/' \
    | grep -v '/Users/test/' \
    | grep -q .; then
  echo -e "${RED}✗${NC} Hardcoded /Users/* paths found in hooks source:"
  grep -rn '/Users/[a-z]+' "$hooks_baseline/src/" --include='*.ts' 2>/dev/null \
    | grep -v '__tests__/' \
    | grep -v '/Users/test/' \
    | head -5
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✓${NC} No hardcoded user paths"
  CHECKS=$((CHECKS + 1))
fi

#──────────────────────────────────────────────────────────────────────────────
# 4. Verify no broken symlinks
#──────────────────────────────────────────────────────────────────────────────
echo ""
echo "─── No broken symlinks ───"

broken=$(find "$HOME/.claude/hooks" -type l ! -exec test -e {} \; -print 2>/dev/null)
if [[ -n "$broken" ]]; then
  echo -e "${RED}✗${NC} Broken symlinks in ~/.claude/hooks/:"
  echo "$broken" | while read -r f; do
    echo "  $f → $(readlink "$f")"
  done
  ERRORS=$((ERRORS + 1))
else
  echo -e "${GREEN}✓${NC} No broken symlinks"
  CHECKS=$((CHECKS + 1))
fi

#──────────────────────────────────────────────────────────────────────────────
# 5. (Optional) Syntax check — verify node can parse each .mjs
#──────────────────────────────────────────────────────────────────────────────
if [[ "$check_syntax" == "true" ]]; then
  echo ""
  echo "─── Syntax check (.mjs files) ───"

  dist_dir="$HOME/.claude/hooks/dist"
  if [[ -d "$dist_dir" ]]; then
    syntax_ok=0
    syntax_fail=0
    for mjs in "$dist_dir"/*.mjs; do
      [[ -f "$mjs" ]] || continue
      if node --check "$mjs" 2>/dev/null; then
        syntax_ok=$((syntax_ok + 1))
      else
        echo -e "${RED}✗${NC} Syntax error: $(basename "$mjs")"
        syntax_fail=$((syntax_fail + 1))
        ERRORS=$((ERRORS + 1))
      fi
    done
    if [[ $syntax_fail -eq 0 ]]; then
      echo -e "${GREEN}✓${NC} All $syntax_ok .mjs files parse OK"
      CHECKS=$((CHECKS + 1))
    fi
  else
    echo -e "${YELLOW}⚠${NC} dist/ not found — build first"
    WARNINGS=$((WARNINGS + 1))
  fi
fi

#──────────────────────────────────────────────────────────────────────────────
# 6. (Optional) Clean build test
#──────────────────────────────────────────────────────────────────────────────
if [[ "$check_build" == "true" ]]; then
  echo ""
  echo "─── Clean build test ───"

  hooks_dir="$HOME/.claude/hooks"
  if [[ -f "$hooks_dir/package.json" ]]; then
    if (cd "$hooks_dir" && npm run build 2>&1 | tail -1); then
      mjs_count=$(ls -1 "$hooks_dir/dist"/*.mjs 2>/dev/null | wc -l | tr -d ' ')
      echo -e "${GREEN}✓${NC} Build succeeded: $mjs_count .mjs files"
      CHECKS=$((CHECKS + 1))
    else
      echo -e "${RED}✗${NC} Build failed"
      ERRORS=$((ERRORS + 1))
    fi
  else
    echo -e "${RED}✗${NC} No package.json at ~/.claude/hooks/"
    ERRORS=$((ERRORS + 1))
  fi
fi

#──────────────────────────────────────────────────────────────────────────────
# Summary
#──────────────────────────────────────────────────────────────────────────────
echo ""
echo "═══════════════════════════════"
echo -e "  Passed:   ${GREEN}$CHECKS${NC}"
echo -e "  Errors:   ${RED}$ERRORS${NC}"
echo -e "  Warnings: ${YELLOW}$WARNINGS${NC}"
echo "═══════════════════════════════"

if [[ $ERRORS -gt 0 ]]; then
  exit 1
fi

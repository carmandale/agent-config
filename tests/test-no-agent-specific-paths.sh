#!/usr/bin/env bash
#==============================================================================
# test-no-agent-specific-paths.sh — Verify shared content doesn't depend on
# agent-specific executable paths.
#
# Scans commands/*.md and skills/**/SKILL*.md for hardcoded user-home paths
# to agent-specific script locations. These paths bind shared content to a
# single agent's install location — the exact antipattern that caused the
# bd-to-br migration gap (spec 020).
#
# What we flag:
#   ~/.claude/scripts/   — Claude-specific executable path
#   $HOME/.claude/scripts/ — same, variable form
#   os.path.expanduser("~/.claude/ — Python invocation form
#   ~/.codex/scripts/    — Codex-specific (preventive)
#   ~/.pi/agent/scripts/ — Pi-specific (preventive)
#
# What we DON'T flag:
#   $CLAUDE_PROJECT_DIR/.claude/ — project-relative (Category 2, different problem)
#   ./.claude/scripts/          — project-relative
#   Files in **/references/**   — third-party documentation
#
# Usage:
#   ~/.agent-config/tests/test-no-agent-specific-paths.sh
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0
FAIL=0
TOTAL=0
ERRORS=()

assert_no_matches() {
  local description="$1"
  local pattern="$2"
  local scope="$3"
  TOTAL=$((TOTAL + 1))

  local matches
  matches=$(rg -n "$pattern" $scope 2>/dev/null || true)

  if [[ -z "$matches" ]]; then
    PASS=$((PASS + 1))
    printf "${GREEN}✓${NC} %s\n" "$description"
  else
    FAIL=$((FAIL + 1))
    ERRORS+=("$description")
    printf "${RED}✗${NC} %s\n" "$description"
    echo "$matches" | while IFS= read -r line; do
      printf "    %s\n" "$line"
    done
  fi
}

echo ""
echo "${BOLD}test-no-agent-specific-paths.sh${NC}"
echo "Scanning shared content for hardcoded agent-specific executable paths..."
echo ""

# Build the scope: commands/*.md + skills SKILL files, excluding references dirs
CMD_FILES="$REPO_ROOT/commands/*.md"

# For skills, we use rg's glob to include SKILL*.md but exclude references/
SKILL_GLOB="-g '*/SKILL*.md' -g '!*/references/*' -g '!*.bak'"

# --- Claude-specific paths ---

assert_no_matches \
  "No ~/.claude/scripts/ in commands" \
  '~/\.claude/scripts/' \
  "$REPO_ROOT/commands/*.md"

assert_no_matches \
  'No $HOME/.claude/scripts/ in commands' \
  '\$HOME/\.claude/scripts/' \
  "$REPO_ROOT/commands/*.md"

assert_no_matches \
  'No os.path.expanduser("~/.claude/) in commands' \
  'expanduser.*~/\.claude/' \
  "$REPO_ROOT/commands/*.md"

# Skills (need rg with globs for recursive + exclusion)
SKILL_MATCHES=$(rg -n '~/\.claude/scripts/' "$REPO_ROOT/skills/" -g '*/SKILL*.md' -g '!*/references/*' -g '!*.bak' 2>/dev/null || true)
TOTAL=$((TOTAL + 1))
if [[ -z "$SKILL_MATCHES" ]]; then
  PASS=$((PASS + 1))
  printf "${GREEN}✓${NC} No ~/.claude/scripts/ in skills\n"
else
  FAIL=$((FAIL + 1))
  ERRORS+=("No ~/.claude/scripts/ in skills")
  printf "${RED}✗${NC} No ~/.claude/scripts/ in skills\n"
  echo "$SKILL_MATCHES" | while IFS= read -r line; do
    printf "    %s\n" "$line"
  done
fi

SKILL_HOME_MATCHES=$(rg -n '\$HOME/\.claude/scripts/' "$REPO_ROOT/skills/" -g '*/SKILL*.md' -g '!*/references/*' -g '!*.bak' 2>/dev/null || true)
TOTAL=$((TOTAL + 1))
if [[ -z "$SKILL_HOME_MATCHES" ]]; then
  PASS=$((PASS + 1))
  printf "${GREEN}✓${NC} No \$HOME/.claude/scripts/ in skills\n"
else
  FAIL=$((FAIL + 1))
  ERRORS+=('No $HOME/.claude/scripts/ in skills')
  printf "${RED}✗${NC} No \$HOME/.claude/scripts/ in skills\n"
  echo "$SKILL_HOME_MATCHES" | while IFS= read -r line; do
    printf "    %s\n" "$line"
  done
fi

SKILL_EXPAND_MATCHES=$(rg -n 'expanduser.*~/\.claude/' "$REPO_ROOT/skills/" -g '*/SKILL*.md' -g '!*/references/*' -g '!*.bak' 2>/dev/null || true)
TOTAL=$((TOTAL + 1))
if [[ -z "$SKILL_EXPAND_MATCHES" ]]; then
  PASS=$((PASS + 1))
  printf "${GREEN}✓${NC} No expanduser ~/.claude/ in skills\n"
else
  FAIL=$((FAIL + 1))
  ERRORS+=("No expanduser ~/.claude/ in skills")
  printf "${RED}✗${NC} No expanduser ~/.claude/ in skills\n"
  echo "$SKILL_EXPAND_MATCHES" | while IFS= read -r line; do
    printf "    %s\n" "$line"
  done
fi

# --- Codex-specific paths (preventive) ---

assert_no_matches \
  "No ~/.codex/scripts/ in commands" \
  '~/\.codex/scripts/' \
  "$REPO_ROOT/commands/*.md"

CODEX_SKILL_MATCHES=$(rg -n '~/\.codex/scripts/' "$REPO_ROOT/skills/" -g '*/SKILL*.md' -g '!*/references/*' -g '!*.bak' 2>/dev/null || true)
TOTAL=$((TOTAL + 1))
if [[ -z "$CODEX_SKILL_MATCHES" ]]; then
  PASS=$((PASS + 1))
  printf "${GREEN}✓${NC} No ~/.codex/scripts/ in skills\n"
else
  FAIL=$((FAIL + 1))
  ERRORS+=("No ~/.codex/scripts/ in skills")
  printf "${RED}✗${NC} No ~/.codex/scripts/ in skills\n"
  echo "$CODEX_SKILL_MATCHES" | while IFS= read -r line; do
    printf "    %s\n" "$line"
  done
fi

# --- Pi-specific paths (preventive) ---

assert_no_matches \
  "No ~/.pi/agent/scripts/ in commands" \
  '~/\.pi/agent/scripts/' \
  "$REPO_ROOT/commands/*.md"

PI_SKILL_MATCHES=$(rg -n '~/\.pi/agent/scripts/' "$REPO_ROOT/skills/" -g '*/SKILL*.md' -g '!*/references/*' -g '!*.bak' 2>/dev/null || true)
TOTAL=$((TOTAL + 1))
if [[ -z "$PI_SKILL_MATCHES" ]]; then
  PASS=$((PASS + 1))
  printf "${GREEN}✓${NC} No ~/.pi/agent/scripts/ in skills\n"
else
  FAIL=$((FAIL + 1))
  ERRORS+=("No ~/.pi/agent/scripts/ in skills")
  printf "${RED}✗${NC} No ~/.pi/agent/scripts/ in skills\n"
  echo "$PI_SKILL_MATCHES" | while IFS= read -r line; do
    printf "    %s\n" "$line"
  done
fi

# --- Summary ---
echo ""
echo "─────────────────────────────────"
printf "Results: ${GREEN}%d passed${NC}, " "$PASS"
if [[ "$FAIL" -gt 0 ]]; then
  printf "${RED}%d failed${NC}" "$FAIL"
else
  printf "0 failed"
fi
printf " (of %d)\n" "$TOTAL"

if [[ "$FAIL" -gt 0 ]]; then
  echo ""
  echo "${RED}Failures:${NC}"
  for err in "${ERRORS[@]}"; do
    echo "  - $err"
  done
  echo ""
  echo "Fix: move scripts to tools-bin/ and use bare names in shared content."
  exit 1
fi

echo ""
exit 0

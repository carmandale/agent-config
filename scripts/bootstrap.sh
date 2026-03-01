#!/usr/bin/env bash
#==============================================================================
# bootstrap.sh - Check and apply baseline configs for cross-machine parity
#
# Manages config files OUTSIDE ~/.agent-config that each agent reads from
# its own config directory (~/.claude, ~/.codex, ~/.pi/agent).
#
# Usage:
#   ./scripts/bootstrap.sh check    # Compare installed vs baseline, report drift
#   ./scripts/bootstrap.sh apply    # Copy baselines to destinations (with backup)
#   ./scripts/bootstrap.sh status   # Quick summary of what's tracked
#
# Baselines live in configs/ and are the source of truth.
# Machine-specific sections (e.g., codex [projects]) are excluded from checks.
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
CONFIGS="$REPO_ROOT/configs"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_err()  { echo -e "${RED}✗${NC} $1"; }
log_info() { echo -e "${BLUE}▸${NC} $1"; }

DRIFT=0
MISSING=0
MATCHED=0

#==============================================================================
# Helpers
#==============================================================================

# Compare a baseline file against its installed location
# Args: baseline_path installed_path [strip_pattern]
# strip_pattern: sed pattern to remove machine-specific sections before comparing
check_file() {
  local baseline="$1"
  local installed="$2"
  local strip="${3:-}"
  local label="${installed/#$HOME/~}"

  if [[ ! -f "$baseline" ]]; then
    return  # No baseline to compare
  fi

  if [[ ! -f "$installed" ]]; then
    log_err "MISSING: $label"
    MISSING=$((MISSING + 1))
    return
  fi

  local base_content installed_content
  if [[ -n "$strip" ]]; then
    base_content=$(sed "$strip" "$baseline")
    installed_content=$(sed "$strip" "$installed")
  else
    base_content=$(cat "$baseline")
    installed_content=$(cat "$installed")
  fi

  if [[ "$base_content" == "$installed_content" ]]; then
    log_ok "OK: $label"
    MATCHED=$((MATCHED + 1))
  else
    log_warn "DRIFT: $label"
    if [[ "${VERBOSE:-}" == "1" ]]; then
      diff <(echo "$base_content") <(echo "$installed_content") || true
    fi
    DRIFT=$((DRIFT + 1))
  fi
}

# Compare a baseline directory against its installed location
check_dir() {
  local baseline_dir="$1"
  local installed_dir="$2"

  if [[ ! -d "$baseline_dir" ]]; then return; fi

  for f in "$baseline_dir"/*; do
    [[ -f "$f" ]] || continue
    local name=$(basename "$f")
    check_file "$f" "$installed_dir/$name"
  done
}

# Copy a baseline file to its destination, backing up if exists
apply_file() {
  local baseline="$1"
  local dest="$2"
  local label="${dest/#$HOME/~}"

  if [[ ! -f "$baseline" ]]; then return; fi

  mkdir -p "$(dirname "$dest")"

  if [[ -f "$dest" ]]; then
    local backup="${dest}.backup.$(date +%Y%m%d-%H%M%S)"
    cp "$dest" "$backup"
    log_info "Backed up: $label"
  fi

  cp "$baseline" "$dest"
  log_ok "Applied: $label"
}

# Copy a baseline directory to its destination
apply_dir() {
  local baseline_dir="$1"
  local dest_dir="$2"

  if [[ ! -d "$baseline_dir" ]]; then return; fi

  mkdir -p "$dest_dir"
  for f in "$baseline_dir"/*; do
    if [[ -f "$f" ]]; then
      apply_file "$f" "$dest_dir/$(basename "$f")"
    elif [[ -d "$f" ]]; then
      local name=$(basename "$f")
      mkdir -p "$dest_dir/$name"
      apply_dir "$f" "$dest_dir/$name"
    fi
  done
}

#==============================================================================
# Check mode
#==============================================================================
do_check() {
  echo ""
  echo "─── Shell Config ───"
  check_file "$CONFIGS/shell/zshenv" "$HOME/.zshenv"
  # Strip .zshrc.local sourcing line — that's machine-specific and always present
  check_file "$CONFIGS/shell/zshrc" "$HOME/.zshrc"

  echo ""
  echo "─── Codex (~/.codex) ───"
  # Strip [projects] section (machine-specific) before comparing config.toml
  check_file "$CONFIGS/codex/config.toml" "$HOME/.codex/config.toml" '/^\[projects\]/,$d'
  check_file "$CONFIGS/codex/config.json" "$HOME/.codex/config.json"
  check_file "$CONFIGS/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
  check_file "$CONFIGS/codex/policy/default.codexpolicy" "$HOME/.codex/policy/default.codexpolicy"

  echo ""
  echo "─── Claude Code (~/.claude) ───"
  check_file "$CONFIGS/claude/settings.json" "$HOME/.claude/settings.json"

  echo ""
  echo "─── Pi Agent (~/.pi/agent) ───"
  check_dir "$CONFIGS/pi/agents" "$HOME/.pi/agent/agents"
  check_file "$CONFIGS/pi/mcporter.json" "$HOME/.pi/agent/compound-engineering/mcporter.json"
  check_dir "$CONFIGS/pi/extensions" "$HOME/.pi/agent/extensions"

  echo ""
  echo "─── Claude Hooks (dependencies of settings.json) ───"
  # Parse settings.json for hook file paths and verify each one exists
  local settings="$CONFIGS/claude/settings.json"
  if [[ -f "$settings" ]]; then
    local hook_paths
    # Extract all paths matching $HOME/.claude/hooks/* or ~/.claude/hooks/*
    hook_paths=$(grep -oE '(\$HOME|~)/\.claude/hooks/[^"\\]+' "$settings" \
      | sed "s|\\\$HOME|$HOME|g; s|^~|$HOME|" \
      | sort -u)

    local hook_ok=0
    local hook_missing=0
    while IFS= read -r hp; do
      [[ -z "$hp" ]] && continue
      local label="${hp/#$HOME/~}"
      if [[ -f "$hp" ]]; then
        hook_ok=$((hook_ok + 1))
      else
        log_err "MISSING: $label"
        hook_missing=$((hook_missing + 1))
      fi
    done <<< "$hook_paths"

    if [[ $hook_missing -eq 0 ]]; then
      log_ok "OK: all $hook_ok hook files present"
      MATCHED=$((MATCHED + 1))
    else
      log_err "$hook_missing hook file(s) missing ($hook_ok present)"
      MISSING=$((MISSING + 1))
    fi
  fi

  echo ""
  echo "─── Symlinks (from install.sh) ───"
  for link_target in \
    "$HOME/.claude/skills:$REPO_ROOT/skills" \
    "$HOME/.claude/commands:$REPO_ROOT/commands" \
    "$HOME/.claude/CLAUDE.md:$REPO_ROOT/instructions/AGENTS.md" \
    "$HOME/.codex/skills:$REPO_ROOT/skills" \
    "$HOME/.codex/prompts:$REPO_ROOT/commands" \
    "$HOME/.codex/AGENTS.md:$REPO_ROOT/instructions/AGENTS.md" \
    "$HOME/.pi/agent/skills:$REPO_ROOT/skills" \
    "$HOME/.pi/agent/prompts:$REPO_ROOT/commands" \
    "$HOME/.pi/agent/AGENTS.md:$REPO_ROOT/instructions/AGENTS.md" \
  ; do
    local link="${link_target%%:*}"
    local target="${link_target##*:}"
    local label="${link/#$HOME/~}"
    if [[ -L "$link" ]]; then
      local actual=$(readlink "$link")
      if [[ "$actual" == "$target" ]]; then
        log_ok "OK: $label → $(basename "$target")"
        MATCHED=$((MATCHED + 1))
      else
        log_warn "DRIFT: $label → $actual (expected $target)"
        DRIFT=$((DRIFT + 1))
      fi
    else
      log_err "MISSING: $label (not a symlink)"
      MISSING=$((MISSING + 1))
    fi
  done

  echo ""
  echo "═══════════════════════════════"
  echo -e "  Matched: ${GREEN}$MATCHED${NC}"
  echo -e "  Drift:   ${YELLOW}$DRIFT${NC}"
  echo -e "  Missing: ${RED}$MISSING${NC}"
  echo "═══════════════════════════════"

  if [[ $DRIFT -gt 0 || $MISSING -gt 0 ]]; then
    echo ""
    echo "Run with VERBOSE=1 to see diffs, or './scripts/bootstrap.sh apply' to reset to baseline."
    exit 1
  fi
}

#==============================================================================
# Apply mode
#==============================================================================
do_apply() {
  echo ""
  echo "─── Shell Config ───"
  apply_file "$CONFIGS/shell/zshenv" "$HOME/.zshenv"
  apply_file "$CONFIGS/shell/zshrc" "$HOME/.zshrc"

  # Ensure secrets directory exists with correct permissions
  if [[ ! -d "$HOME/.secrets" ]]; then
    mkdir -p "$HOME/.secrets"
    chmod 700 "$HOME/.secrets"
    log_ok "Created ~/.secrets/ (mode 700)"
  fi
  if [[ ! -f "$HOME/.secrets/agent-keys.env" ]]; then
    if [[ -f "$CONFIGS/shell/secrets-template.env" ]]; then
      cp "$CONFIGS/shell/secrets-template.env" "$HOME/.secrets/agent-keys.env"
      chmod 600 "$HOME/.secrets/agent-keys.env"
      log_ok "Created ~/.secrets/agent-keys.env from template"
    fi
  fi

  echo ""
  echo "─── Codex ───"
  apply_file "$CONFIGS/codex/config.toml" "$HOME/.codex/config.toml"
  apply_file "$CONFIGS/codex/config.json" "$HOME/.codex/config.json"
  apply_file "$CONFIGS/codex/rules/default.rules" "$HOME/.codex/rules/default.rules"
  apply_file "$CONFIGS/codex/policy/default.codexpolicy" "$HOME/.codex/policy/default.codexpolicy"

  echo ""
  echo "─── Claude Code ───"
  apply_file "$CONFIGS/claude/settings.json" "$HOME/.claude/settings.json"

  echo ""
  echo "─── Pi Agent ───"
  apply_dir "$CONFIGS/pi/agents" "$HOME/.pi/agent/agents"
  apply_file "$CONFIGS/pi/mcporter.json" "$HOME/.pi/agent/compound-engineering/mcporter.json"
  apply_dir "$CONFIGS/pi/extensions" "$HOME/.pi/agent/extensions"

  echo ""
  log_ok "Baseline configs applied. Run './scripts/bootstrap.sh check' to verify."
  echo ""
  log_info "Note: Codex config.toml baseline excludes [projects] section."
  log_info "Add trusted projects manually: codex --trust <path>"
  echo ""
  log_info "Next: run './install.sh' to set up symlinks if not already done."
}

#==============================================================================
# Status mode
#==============================================================================
do_status() {
  echo ""
  echo "Tracked baseline configs:"
  echo ""
  echo "  Shell (~/):"
  echo "    .zshenv          — PATH setup, secrets loading (all shells incl SSH)"
  echo "    .zshrc           — interactive shell config (prompt, plugins, history)"
  echo "    ~/.secrets/      — agent-keys.env (API keys, 600 perms, not tracked)"
  echo ""
  echo "  Codex (~/.codex):"
  echo "    config.toml      — model, MCP servers, features, agents (excludes [projects])"
  echo "    config.json      — provider URLs, tool settings"
  echo "    rules/           — default rules"
  echo "    policy/          — default policy"
  echo ""
  echo "  Claude Code (~/.claude):"
  echo "    settings.json    — permissions, hooks, plugins, statusline"
  echo "    hooks/           — TypeScript hooks (src/ → dist/ via esbuild)"
  echo "                       settings.json references ~28 .mjs files in hooks/dist/"
  echo "                       Build: cd ~/.claude/hooks && npm install && npm run build"
  echo ""
  echo "  Pi Agent (~/.pi/agent):"
  echo "    agents/          — agent chain definitions (6 files)"
  echo "    mcporter.json    — MCPorter MCP bridge config"
  echo "    extensions/      — extension config scripts (6 .ts files only)"
  echo "                       Extension packages (interactive-shell, ralph, etc.)"
  echo "                       are installed per-machine via npm/bun, not tracked"
  echo ""
  echo "  NOT tracked (machine-specific or credentials):"
  echo "    auth.json, .credentials.json, sessions/, cache/, history.*"
  echo "    codex config.toml [projects] section"
  echo ""
  echo "Usage:"
  echo "  ./scripts/bootstrap.sh check   — compare installed vs baseline"
  echo "  ./scripts/bootstrap.sh apply   — copy baselines (with backup)"
  echo ""
}

#==============================================================================
# Main
#==============================================================================
case "${1:-status}" in
  check)  do_check ;;
  apply)  do_apply ;;
  status) do_status ;;
  *)
    echo "Usage: $0 {check|apply|status}"
    exit 1
    ;;
esac

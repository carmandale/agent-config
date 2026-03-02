#!/usr/bin/env bash
#==============================================================================
# setup.sh - Full machine setup for agent-config
#
# Orchestrates: Homebrew packages, shell config baselines, symlinks, and
# agent bootstrap configs. Idempotent — safe to run multiple times.
#
# Usage:
#   ./scripts/setup.sh                    # Full setup
#   ./scripts/setup.sh --skip-brew        # Skip brew bundle
#   ./scripts/setup.sh --skip-shell       # Skip shell config
#   ./scripts/setup.sh --skip-agents      # Skip agent bootstrap
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

log_ok()   { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_err()  { echo -e "${RED}✗${NC} $1"; }
log_info() { echo -e "${BLUE}▸${NC} $1"; }
log_step() { echo -e "\n${BOLD}═══ $1 ═══${NC}"; }

# Parse flags
SKIP_BREW=false
SKIP_SHELL=false
SKIP_AGENTS=false

for arg in "$@"; do
  case "$arg" in
    --skip-brew)   SKIP_BREW=true ;;
    --skip-shell)  SKIP_SHELL=true ;;
    --skip-agents) SKIP_AGENTS=true ;;
    --help|-h)
      echo "Usage: $0 [--skip-brew] [--skip-shell] [--skip-agents]"
      echo ""
      echo "  --skip-brew    Skip Homebrew package installation"
      echo "  --skip-shell   Skip shell config (zshenv/zshrc) setup"
      echo "  --skip-agents  Skip agent config bootstrap (codex/claude/pi)"
      exit 0
      ;;
    *)
      echo "Unknown flag: $arg"
      echo "Usage: $0 [--skip-brew] [--skip-shell] [--skip-agents]"
      exit 1
      ;;
  esac
done

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Agent Config - Machine Setup                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

WARNINGS=()
MANUAL_STEPS=()

#==============================================================================
# Step 1: Homebrew
#==============================================================================
if [[ "$SKIP_BREW" == "true" ]]; then
  log_info "Skipping Homebrew (--skip-brew)"
else
  log_step "Homebrew"

  if ! command -v brew >/dev/null 2>&1; then
    log_warn "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Add to current session PATH
    if [ -d "/opt/homebrew/bin" ]; then
      export PATH="/opt/homebrew/bin:/opt/homebrew/sbin:$PATH"
    fi
    log_ok "Homebrew installed"
  else
    log_ok "Homebrew found: $(brew --prefix)"
  fi

  if [[ -f "$REPO_ROOT/Brewfile" ]]; then
    log_info "Installing packages from Brewfile..."
    if brew bundle --file="$REPO_ROOT/Brewfile"; then
      log_ok "Brew bundle complete"
    else
      log_warn "Some brew packages failed to install (non-fatal)"
      WARNINGS+=("Some brew packages failed — run 'brew bundle --file=Brewfile' manually to retry")
    fi
  else
    log_err "Brewfile not found at $REPO_ROOT/Brewfile"
  fi
fi

#==============================================================================
# Step 2: Shell config
#==============================================================================
if [[ "$SKIP_SHELL" == "true" ]]; then
  log_info "Skipping shell config (--skip-shell)"
else
  log_step "Shell Config"

  SHELL_CONFIGS="$REPO_ROOT/configs/shell"

  # --- ~/.zshenv ---
  if [[ -f "$SHELL_CONFIGS/zshenv" ]]; then
    if [[ -f "$HOME/.zshenv" ]]; then
      local_backup="$HOME/.zshenv.backup.$(date +%Y%m%d-%H%M%S)"
      cp "$HOME/.zshenv" "$local_backup"
      log_info "Backed up ~/.zshenv → $(basename "$local_backup")"
    fi
    cp "$SHELL_CONFIGS/zshenv" "$HOME/.zshenv"
    log_ok "Applied ~/.zshenv"
  fi

  # --- ~/.zshrc ---
  if [[ -f "$SHELL_CONFIGS/zshrc" ]]; then
    if [[ -f "$HOME/.zshrc" ]]; then
      local_backup="$HOME/.zshrc.backup.$(date +%Y%m%d-%H%M%S)"
      cp "$HOME/.zshrc" "$local_backup"
      log_info "Backed up ~/.zshrc → $(basename "$local_backup")"
    fi
    cp "$SHELL_CONFIGS/zshrc" "$HOME/.zshrc"
    log_ok "Applied ~/.zshrc"
    log_info "Machine-specific config goes in ~/.zshrc.local"
  fi

  # --- ~/.secrets/ directory ---
  if [[ ! -d "$HOME/.secrets" ]]; then
    mkdir -p "$HOME/.secrets"
    chmod 700 "$HOME/.secrets"
    log_ok "Created ~/.secrets/ (mode 700)"
  else
    log_ok "~/.secrets/ already exists"
  fi

  # --- ~/.secrets/agent-keys.env ---
  if [[ ! -f "$HOME/.secrets/agent-keys.env" ]]; then
    if [[ -f "$SHELL_CONFIGS/secrets-template.env" ]]; then
      cp "$SHELL_CONFIGS/secrets-template.env" "$HOME/.secrets/agent-keys.env"
      chmod 600 "$HOME/.secrets/agent-keys.env"
      log_ok "Created ~/.secrets/agent-keys.env from template (mode 600)"
      MANUAL_STEPS+=("Edit ~/.secrets/agent-keys.env — add your API keys")
    fi
  else
    log_ok "~/.secrets/agent-keys.env already exists"
    # Ensure permissions are correct
    chmod 600 "$HOME/.secrets/agent-keys.env"
  fi
fi

#==============================================================================
# Step 3: Symlinks (install.sh)
#==============================================================================
log_step "Symlinks"

if [[ -x "$REPO_ROOT/install.sh" ]]; then
  "$REPO_ROOT/install.sh"
  log_ok "Symlinks applied"
else
  log_err "install.sh not found or not executable"
fi

#==============================================================================
# Step 4: Agent bootstrap configs (includes hooks deploy + build)
#==============================================================================
if [[ "$SKIP_AGENTS" == "true" ]]; then
  log_info "Skipping agent bootstrap (--skip-agents)"
else
  log_step "Agent Configs"

  if [[ -x "$SCRIPT_DIR/bootstrap.sh" ]]; then
    "$SCRIPT_DIR/bootstrap.sh" apply
    log_ok "Agent configs applied"
  else
    log_err "bootstrap.sh not found or not executable"
  fi
fi

#==============================================================================
# Step 5: Verify
#==============================================================================
log_step "Verification"

if [[ -x "$SCRIPT_DIR/bootstrap.sh" ]]; then
  if "$SCRIPT_DIR/bootstrap.sh" check; then
    log_ok "All checks passed"
  else
    log_warn "Some checks failed — review output above"
    WARNINGS+=("bootstrap.sh check reported drift or missing configs")
  fi
fi

# Count skills and commands
SKILL_COUNT=$(find "$REPO_ROOT/skills" -mindepth 2 -maxdepth 2 -name "SKILL.md" 2>/dev/null | wc -l | tr -d ' ')
COMMAND_COUNT=$(ls -1 "$REPO_ROOT/commands"/*.md 2>/dev/null | wc -l | tr -d ' ')
log_info "Skills: $SKILL_COUNT | Commands: $COMMAND_COUNT"

#==============================================================================
# Step 6: Summary
#==============================================================================
log_step "Setup Complete"

echo ""
if [[ ${#WARNINGS[@]} -gt 0 ]]; then
  echo -e "${YELLOW}Warnings:${NC}"
  for w in "${WARNINGS[@]}"; do
    echo -e "  ${YELLOW}⚠${NC} $w"
  done
  echo ""
fi

if [[ ${#MANUAL_STEPS[@]} -gt 0 ]]; then
  echo -e "${BLUE}Manual steps needed:${NC}"
  for s in "${MANUAL_STEPS[@]}"; do
    echo -e "  ${BLUE}▸${NC} $s"
  done
  echo ""
fi

echo "Agent CLIs (installed separately):"
for cli in claude codex pi openclaw; do
  if command -v "$cli" >/dev/null 2>&1; then
    log_ok "$cli found"
  else
    log_warn "$cli not found — install separately"
  fi
done
echo ""

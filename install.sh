#!/usr/bin/env bash
#==============================================================================
# install.sh - Set up symlinks for unified agent configuration
#
# Creates symlinks from each agent's config location to this central repo.
# Safe to run multiple times - backs up existing directories, replaces symlinks.
#==============================================================================

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log_info() { echo -e "${BLUE}▸${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_error() { echo -e "${RED}✗${NC} $1" >&2; }

# Get the directory where this script lives
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
COMMANDS_DIR="$SCRIPT_DIR/commands"
INSTRUCTIONS_DIR="$SCRIPT_DIR/instructions"
AGENTS_MD="$INSTRUCTIONS_DIR/AGENTS.md"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║              Agent Config - Unified Setup                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

#==============================================================================
# Helper: Create symlink, backing up existing directory if needed
#==============================================================================
create_symlink() {
    local target="$1"    # What the symlink points to
    local link="$2"      # Where the symlink is created
    local link_dir="$(dirname "$link")"
    
    # Create parent directory if needed
    if [[ ! -d "$link_dir" ]]; then
        mkdir -p "$link_dir"
        log_info "Created directory: $link_dir"
    fi
    
    # Handle existing file/directory/symlink
    if [[ -L "$link" ]]; then
        # It's already a symlink - remove and recreate
        rm -f "$link"
    elif [[ -d "$link" ]]; then
        # It's a real directory - back it up
        local backup="${link}.backup.$(date +%Y%m%d-%H%M%S)"
        mv "$link" "$backup"
        log_warn "Backed up existing directory: $backup"
    elif [[ -f "$link" ]]; then
        # It's a file - back it up
        local backup="${link}.backup.$(date +%Y%m%d-%H%M%S)"
        mv "$link" "$backup"
        log_warn "Backed up existing file: $backup"
    fi
    
    # Create the symlink
    ln -sf "$target" "$link"
    log_success "Linked: $link → $target"
}

#==============================================================================
# Verify source directories exist
#==============================================================================
if [[ ! -d "$COMMANDS_DIR" ]]; then
    log_error "Commands directory not found: $COMMANDS_DIR"
    exit 1
fi

if [[ ! -f "$AGENTS_MD" ]]; then
    log_error "AGENTS.md not found: $AGENTS_MD"
    exit 1
fi

log_info "Source: $SCRIPT_DIR"
echo ""

#==============================================================================
# Pi Agent
#==============================================================================
echo "─── Pi Agent ───"
create_symlink "$COMMANDS_DIR" "$HOME/.pi/agent/commands"
create_symlink "$AGENTS_MD" "$HOME/.pi/agent/AGENTS.md"
echo ""

#==============================================================================
# Claude Code
#==============================================================================
echo "─── Claude Code ───"
create_symlink "$COMMANDS_DIR" "$HOME/.claude/commands"
create_symlink "$AGENTS_MD" "$HOME/.claude/CLAUDE.md"
echo ""

#==============================================================================
# Codex (OpenAI)
#==============================================================================
echo "─── Codex ───"
create_symlink "$COMMANDS_DIR" "$HOME/.codex/prompts"
create_symlink "$AGENTS_MD" "$HOME/.codex/AGENTS.md"
echo ""

#==============================================================================
# OpenCode
#==============================================================================
echo "─── OpenCode ───"
create_symlink "$COMMANDS_DIR" "$HOME/.config/opencode/commands"
# OpenCode uses project-level instructions, not user-level
log_info "OpenCode uses project-level .opencode/ for instructions"
echo ""

#==============================================================================
# Summary
#==============================================================================
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    Setup Complete! ✓                           ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Commands available: $(ls -1 "$COMMANDS_DIR"/*.md 2>/dev/null | wc -l | tr -d ' ')"
echo ""
echo "Try these commands in any agent:"
echo "  /handoff     - End-of-session summary"
echo "  /checkpoint  - Mid-session context compression"
echo "  /commit      - Smart commit workflow"
echo "  /debug       - Structured debugging"
echo ""
echo "Edit global instructions:"
echo "  $AGENTS_MD"
echo ""

#==============================================================================
# Skills (Unified across all agents)
#==============================================================================
SKILLS_DIR="$SCRIPT_DIR/skills"

if [[ -d "$SKILLS_DIR" ]]; then
    echo "─── Skills (Unified) ───"
    
    # Claude Code
    create_symlink "$SKILLS_DIR" "$HOME/.claude/skills"
    
    # Codex
    create_symlink "$SKILLS_DIR" "$HOME/.codex/skills"
    
    # Pi Agent (both locations for compatibility)
    create_symlink "$SKILLS_DIR" "$HOME/.config/agent-skills"
    create_symlink "$SKILLS_DIR" "$HOME/.pi/agent/skills"
    
    echo ""
    log_info "Skills unified: $(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d | wc -l | tr -d ' ') skills across $(ls -1 "$SKILLS_DIR" | wc -l | tr -d ' ') categories"
    echo ""
fi

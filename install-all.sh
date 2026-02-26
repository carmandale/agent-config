#!/usr/bin/env bash
#==============================================================================
# install-all.sh - Complete agent setup for all platforms
#
# Runs both:
# 1. agent-config symlinks (commands, instructions, skills)
# 2. compound-engineering-plugin converter (agents, MCP configs)
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║           Complete Agent Setup - All Platforms                 ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

#==============================================================================
# Step 1: Run agent-config symlinks
#==============================================================================
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ Step 1: Setting up symlinks (commands, instructions, skills)   │"
echo "└─────────────────────────────────────────────────────────────────┘"
"$SCRIPT_DIR/install.sh"

#==============================================================================
# Step 2: Install compound-engineering to all global targets
#==============================================================================
echo ""
echo "┌─────────────────────────────────────────────────────────────────┐"
echo "│ Step 2: Installing compound-engineering plugin (all targets)   │"
echo "└─────────────────────────────────────────────────────────────────┘"
echo ""

# Check if bunx is available
if ! command -v bunx &> /dev/null; then
    echo "⚠ bunx not found. Install bun first: curl -fsSL https://bun.sh/install | bash"
    echo "  Skipping compound-engineering install."
else
    # NOTE: Pi and Codex use symlinks to agent-config, so they already have
    # access to compound/ skills and commands. Running `install` for them
    # would COPY skills into the symlinked directory, causing duplicates.
    # Only run install for agents with their own (non-symlinked) directories.
    echo "Installing compound-engineering to: opencode, droid"
    echo "(Pi and Codex use symlinks - they get compound/ automatically)"
    bunx @every-env/compound-plugin install compound-engineering \
        --to opencode \
        --also droid
fi

#==============================================================================
# Summary
#==============================================================================
echo ""
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    All Agents Updated! ✓                       ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""
echo "Global targets installed:"
echo "  ✓ Pi          ~/.pi/agent/"
echo "  ✓ Claude      ~/.claude/"
echo "  ✓ Codex       ~/.codex/"
echo "  ✓ OpenCode    ~/.config/opencode/"
echo "  ✓ Factory     ~/.factory/"
echo ""
echo "Project-level targets (run in each project):"
echo "  bunx @every-env/compound-plugin install compound-engineering --to copilot"
echo "  bunx @every-env/compound-plugin install compound-engineering --to gemini"
echo "  bunx @every-env/compound-plugin install compound-engineering --to kiro"
echo ""

#!/usr/bin/env bash
#==============================================================================
# vendor-sync.sh - Sync vendored skills from their source repositories
#
# Vendored skills are copies of skills from external repos that don't warrant
# git submodules (they're subdirectories of larger projects, not standalone
# skill repos). This script re-copies from source and records provenance.
#
# Usage: ./scripts/vendor-sync.sh [skill-name]
#   No args: sync all vendored skills
#   skill-name: sync only that skill
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

log_ok() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }
log_err() { echo -e "${RED}✗${NC} $1" >&2; }

#==============================================================================
# Provenance Manifest
#
# Each entry: name | source_repo | source_path | vendor_dest | last_synced_commit
#==============================================================================
declare -A VENDOR_SOURCE VENDOR_PATH VENDOR_DEST VENDOR_COMMIT

# compound (19 skills) — from compound-engineering-plugin
VENDOR_SOURCE[compound]="git@github.com:anthropics/compound-engineering-plugin.git"
VENDOR_PATH[compound]="plugins/compound-engineering/skills"
VENDOR_DEST[compound]="skills/domain/compound"
VENDOR_COMMIT[compound]="03898070a7f2f2c8ab7ec2cc9c09481a79d4781e"

# compound commands — same source repo
VENDOR_SOURCE[compound-commands]="git@github.com:anthropics/compound-engineering-plugin.git"
VENDOR_PATH[compound-commands]="plugins/compound-engineering/commands"
VENDOR_DEST[compound-commands]="commands/compound"
VENDOR_COMMIT[compound-commands]="03898070a7f2f2c8ab7ec2cc9c09481a79d4781e"

# surf — from surf-cli
VENDOR_SOURCE[surf]="git@github.com:nichochar/surf-cli.git"
VENDOR_PATH[surf]="skills/surf"
VENDOR_DEST[surf]="skills/tools/surf"
VENDOR_COMMIT[surf]="dfbc169bdde6ca1156055e29b5ec473e13b9d871"

# xcode-26 — from Xcode26-Agent-Skills
VENDOR_SOURCE[xcode-26]="git@github.com:nichochar/Xcode26-Agent-Skills.git"
VENDOR_PATH[xcode-26]="xcode-26"
VENDOR_DEST[xcode-26]="skills/domain/swift/xcode-26"
VENDOR_COMMIT[xcode-26]="b11f995ecb7bc404774d8e03e1d4d78309454170"

# remotion-best-practices — from ~/.agents/skills (no upstream git repo)
VENDOR_SOURCE[remotion-best-practices]="local:~/.agents/skills/remotion-best-practices"
VENDOR_PATH[remotion-best-practices]="."
VENDOR_DEST[remotion-best-practices]="skills/domain/other/remotion-best-practices"
VENDOR_COMMIT[remotion-best-practices]="none"

# find-skills — from ~/.agents/skills (no upstream git repo)
VENDOR_SOURCE[find-skills]="local:~/.agents/skills/find-skills"
VENDOR_PATH[find-skills]="."
VENDOR_DEST[find-skills]="skills/tools/find-skills"
VENDOR_COMMIT[find-skills]="none"

# visual-explainer — was a nested git clone, now vendored (no upstream)
VENDOR_SOURCE[visual-explainer]="local:~/.agents/skills/visual-explainer"
VENDOR_PATH[visual-explainer]="."
VENDOR_DEST[visual-explainer]="skills/workflows/visual-explainer"
VENDOR_COMMIT[visual-explainer]="none"

# gj-tool — from ~/dev/gj-tool (local dev repo, canonical build tool)
VENDOR_SOURCE[gj-tool]="local:~/dev/gj-tool/skill"
VENDOR_PATH[gj-tool]="."
VENDOR_DEST[gj-tool]="skills/tools/gj-tool"
VENDOR_COMMIT[gj-tool]="none"

ALL_VENDORS=(compound compound-commands surf xcode-26 remotion-best-practices find-skills visual-explainer gj-tool)

#==============================================================================
# Sync function
#==============================================================================
sync_vendor() {
    local name="$1"
    local source="${VENDOR_SOURCE[$name]}"
    local path="${VENDOR_PATH[$name]}"
    local dest="${VENDOR_DEST[$name]}"

    echo ""
    echo "── $name ──"
    echo "  Source: $source :: $path"
    echo "  Dest:   $dest"

    if [[ "$source" == local:* ]]; then
        local local_path="${source#local:}"
        local_path="${local_path/#\~/$HOME}"
        if [[ -d "$local_path" ]]; then
            rsync -a --delete "$local_path/" "$REPO_ROOT/$dest/"
            log_ok "Synced from local path"
        else
            log_warn "Local source not found: $local_path (skip)"
        fi
    else
        log_warn "Git-based sync not yet implemented. Manual copy needed."
        echo "  To sync: copy $path from a clone of $source into $dest"
    fi
}

#==============================================================================
# Main
#==============================================================================
if [[ $# -eq 1 ]]; then
    name="$1"
    if [[ -z "${VENDOR_SOURCE[$name]+x}" ]]; then
        log_err "Unknown vendor: $name"
        echo "Available: ${ALL_VENDORS[*]}"
        exit 1
    fi
    sync_vendor "$name"
else
    echo "Syncing all vendored skills..."
    for name in "${ALL_VENDORS[@]}"; do
        sync_vendor "$name"
    done
fi

echo ""
log_ok "Vendor sync complete. Run 'git diff' to review changes."

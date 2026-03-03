#!/usr/bin/env bash
#==============================================================================
# convert-commands-gemini.sh - Convert MD slash commands to Gemini TOML format
#
# Reads commands/*.md (with optional YAML frontmatter), extracts description
# and prompt body, and writes .toml files to ~/.gemini/commands/.
#
# Source of truth: commands/*.md (shared across Claude, Codex, Pi)
# Output: ~/.gemini/commands/*.toml (generated, not hand-edited)
#
# Usage:
#   ./scripts/convert-commands-gemini.sh [source_dir] [dest_dir]
#   Defaults: source_dir=commands/  dest_dir=~/.gemini/commands/
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"

SOURCE_DIR="${1:-$REPO_ROOT/commands}"
DEST_DIR="${2:-$HOME/.gemini/commands}"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log_info() { echo -e "${BLUE}▸${NC} $1"; }
log_success() { echo -e "${GREEN}✓${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1"; }

converted=0
skipped=0

# Ensure destination exists
mkdir -p "$DEST_DIR"

# Process each .md file recursively
while IFS= read -r -d '' md_file; do
    rel_path="${md_file#"$SOURCE_DIR"/}"
    toml_path="$DEST_DIR/${rel_path%.md}.toml"

    # Ensure subdirectory exists
    mkdir -p "$(dirname "$toml_path")"

    # Read the file
    content="$(cat "$md_file")"

    # Parse YAML frontmatter (between --- delimiters) and body
    description=""
    body=""

    if [[ "$content" == ---* ]]; then
        # Extract ONLY the first frontmatter block and body using awk
        frontmatter="$(echo "$content" | awk '
            BEGIN { n=0 }
            /^---$/ { n++; next }
            n==1 { print }
            n>=2 { exit }
        ')"
        body="$(echo "$content" | awk '
            BEGIN { n=0 }
            /^---$/ { n++; next }
            n>=2 { print }
        ')"
        # Extract description from frontmatter (first match only)
        description="$(echo "$frontmatter" | awk -F': ' '/^description:/{print substr($0, index($0,": ")+2); exit}')" || true
        # Strip surrounding quotes if present
        description="${description#\"}"
        description="${description%\"}"
        description="${description#\'}"
        description="${description%\'}"
    else
        # No frontmatter — entire file is the prompt body
        body="$content"
    fi

    # Strip leading/trailing blank lines from body
    body="$(echo "$body" | sed '/./,$!d' | sed -e :a -e '/^\n*$/{$d;N;ba' -e '}')"

    # Skip empty prompts
    if [[ -z "$body" ]]; then
        log_warn "Skipped (empty body): $rel_path"
        ((skipped++)) || true
        continue
    fi

    # Escape triple single-quotes in body (edge case for literal strings)
    body="${body//\'\'\'/\'\'\\\'}"

    # Write TOML file
    # Use TOML literal strings (''') for the prompt to avoid backslash escaping
    # issues. Literal strings treat \ as literal characters.
    {
        echo "# Auto-generated from commands/$rel_path — do not hand-edit"
        echo "# Source: ~/.agent-config/commands/$rel_path"
        echo ""
        if [[ -n "$description" ]]; then
            # Escape double quotes in description
            escaped_desc="${description//\"/\\\"}"
            echo "description = \"$escaped_desc\""
        fi
        echo "prompt = '''"
        echo "$body"
        echo "'''"
    } > "$toml_path"

    ((converted++)) || true
done < <(find "$SOURCE_DIR" -name "*.md" -type f -print0 | sort -z)

log_success "Converted $converted commands to TOML → $DEST_DIR"
if [[ $skipped -gt 0 ]]; then
    log_warn "Skipped $skipped commands (empty body)"
fi

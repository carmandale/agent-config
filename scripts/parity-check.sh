#!/usr/bin/env bash
#==============================================================================
# parity-check.sh — Cross-machine parity verification
#
# Compares runtime state (tool versions, git state, Homebrew packages)
# between the laptop and Mac mini (mini-ts) over SSH.
#
# Usage:
#   parity-check.sh              # Human-readable table
#   parity-check.sh --json       # JSON array for agent consumption
#   parity-check.sh --help       # Show help
#
# Exit codes:
#   0 — All checks PASS or DRIFT (expected)
#   1 — Unexpected DRIFT or MISSING detected
#   2 — SSH connectivity failure or timeout
#   3 — Missing dependency (e.g., jq for --json)
#
# See also: tools-bin/agent-config-parity (local config-surface auditing)
#==============================================================================

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(dirname "$SCRIPT_DIR")"
BREWFILE="$REPO_ROOT/Brewfile"
SSH_HOST="mini-ts"

# ── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
DIM='\033[2m'
BOLD='\033[1m'
NC='\033[0m'

log_ok()   { echo -e "  ${GREEN}✓${NC} $1"; }
log_drift(){ echo -e "  ${YELLOW}✗${NC} $1"; }
log_miss() { echo -e "  ${RED}✗${NC} $1"; }
log_exp()  { echo -e "  ${DIM}~${NC} $1"; }
log_warn() { echo -e "${YELLOW}⚠${NC} $1" >&2; }
log_err()  { echo -e "${RED}✗${NC} $1" >&2; }

# ── Argument Parsing ─────────────────────────────────────────────────────────
OUTPUT_JSON=false

usage() {
    cat <<'USAGE'
Usage: parity-check.sh [OPTIONS]

Compare runtime state between laptop and Mac mini (mini-ts).

Options:
  --json    Output JSON array (requires jq)
  --help    Show this help message

Checks:
  Agent infra   pi version, pi packages, agent-config HEAD/branch,
                pi-messenger version/branch/source, openclaw version
  Core tools    node, claude, codex versions
  Homebrew      Brewfile packages installed on both machines

Exit codes:
  0  All PASS or DRIFT (expected)
  1  Unexpected DRIFT or MISSING
  2  SSH failure or timeout
  3  Missing dependency

See also:
  agent-config-parity  — local config-surface auditing (symlinks, paths)
  parity-check.sh      — cross-machine runtime state comparison (this tool)
USAGE
}

parse_args() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --json) OUTPUT_JSON=true; shift ;;
            --help|-h) usage; exit 0 ;;
            *) log_err "Unknown option: $1"; usage; exit 1 ;;
        esac
    done
}

# ── Dependency Checks ────────────────────────────────────────────────────────
check_deps() {
    if [[ "$OUTPUT_JSON" == true ]]; then
        if ! command -v jq &>/dev/null; then
            echo "ERROR: --json requires jq (install: brew install jq)" >&2
            exit 3
        fi
    fi
}

TIMEOUT_CMD=""

resolve_timeout_cmd() {
    if command -v timeout &>/dev/null; then
        TIMEOUT_CMD="timeout"
    elif command -v gtimeout &>/dev/null; then
        TIMEOUT_CMD="gtimeout"
    else
        log_warn "Neither timeout nor gtimeout found — SSH has no end-to-end timeout protection"
        log_warn "Install coreutils: brew install coreutils"
        TIMEOUT_CMD=""
    fi
}

# ── Helpers ──────────────────────────────────────────────────────────────────
is_missing() {
    local val="$1"
    [[ -z "$val" ]] && return 0
    [[ "$val" == *"command not found"* ]] && return 0
    [[ "$val" == *"not found"* ]] && return 0
    [[ "$val" == "MISSING" ]] && return 0
    return 1
}

classify_pm_source() {
    local src="$1"
    if [[ "$src" == npm:* ]]; then
        echo "npm"
    elif [[ "$src" == ../* ]] || [[ "$src" == /* ]]; then
        echo "local-path"
    elif [[ -z "$src" ]] || is_missing "$src"; then
        echo "missing"
    else
        echo "unknown"
    fi
}

# ── Results Storage ──────────────────────────────────────────────────────────
# Parallel arrays for results (bash 3 compat — no array of arrays)
declare -a RESULT_KEYS=()
declare -a RESULT_LOCAL=()
declare -a RESULT_REMOTE=()
declare -a RESULT_VERDICT=()

add_result() {
    RESULT_KEYS+=("$1")
    RESULT_LOCAL+=("$2")
    RESULT_REMOTE+=("$3")
    RESULT_VERDICT+=("$4")
}

# ── Local Gather ─────────────────────────────────────────────────────────────
declare -A LOCAL=()

gather_local() {
    # Tool versions
    LOCAL[pi_version]=$(pi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "MISSING")
    LOCAL[node_version]=$(node --version 2>/dev/null || echo "MISSING")
    LOCAL[claude_version]=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "MISSING")
    LOCAL[codex_version]=$(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1 || echo "MISSING")
    LOCAL[openclaw_version]=$(openclaw --version 2>/dev/null | head -1 || echo "MISSING")

    # Agent-config git state (use fixed-length SHA for cross-machine comparison)
    LOCAL[agent_config_head]=$(git -C "$HOME/.agent-config" rev-parse --short=7 HEAD 2>/dev/null || echo "MISSING")
    LOCAL[agent_config_branch]=$(git -C "$HOME/.agent-config" branch --show-current 2>/dev/null || echo "MISSING")

    # Pi list output format:
    #   2-space indent = package identifier (npm:name or /path or ../path)
    #   4-space indent = resolved path
    local pi_list_output
    pi_list_output=$(pi list 2>/dev/null || true)

    # Pi packages: identifier lines (2-space indent, not 4-space)
    LOCAL[pi_packages]=$(echo "$pi_list_output" | grep -E '^  [^ ]' | sed 's/^  //' | sort | paste -sd, - || true)
    [[ -z "${LOCAL[pi_packages]}" ]] && LOCAL[pi_packages]="(none)"

    # Pi-messenger: path is the 4-space-indented line containing "messenger"
    local pm_path
    pm_path=$(echo "$pi_list_output" | grep "messenger" | grep -E '^    /' | tail -1 | sed 's/^    //' | xargs 2>/dev/null || true)

    # Pi-messenger source: the 2-space-indented identifier line containing "messenger"
    local pm_source_raw
    pm_source_raw=$(echo "$pi_list_output" | grep "messenger" | grep -E '^  [^ ]' | head -1 | sed 's/^  //' | xargs 2>/dev/null || true)

    if [[ -z "$pm_path" ]] || [[ ! -d "$pm_path" ]]; then
        LOCAL[pm_version]="MISSING"
        LOCAL[pm_branch]="MISSING"
        LOCAL[pm_source]="MISSING"
    else
        LOCAL[pm_version]=$(grep '"version"' "$pm_path/package.json" 2>/dev/null | head -1 | sed 's/.*: "//;s/".*//' || echo "MISSING")
        LOCAL[pm_branch]=$(cd "$pm_path" && git branch --show-current 2>/dev/null || echo "MISSING")
        LOCAL[pm_source]="${pm_source_raw:-MISSING}"
    fi

    # Local Homebrew list (for brew check)
    LOCAL[brew_list]=$(brew list --formula -1 2>/dev/null | sort | paste -sd, - || echo "MISSING")
}

# ── Remote Gather ────────────────────────────────────────────────────────────
declare -A REMOTE=()

gather_remote() {
    local ssh_cmd="ssh -o ConnectTimeout=5 -o BatchMode=yes $SSH_HOST bash -s"
    if [[ -n "$TIMEOUT_CMD" ]]; then
        ssh_cmd="$TIMEOUT_CMD 15 $ssh_cmd"
    fi

    local remote_output
    remote_output=$($ssh_cmd << 'REMOTE_SCRIPT'
# Tool versions
echo "pi_version=$(pi --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
echo "node_version=$(node --version 2>/dev/null)"
echo "claude_version=$(claude --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)"
echo "codex_version=$(codex --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
echo "openclaw_version=$(openclaw --version 2>/dev/null | head -1)"

# Agent-config git state (fixed-length SHA)
echo "agent_config_head=$(git -C "$HOME/.agent-config" rev-parse --short=7 HEAD 2>/dev/null)"
echo "agent_config_branch=$(git -C "$HOME/.agent-config" branch --show-current 2>/dev/null)"

# Pi list output (cache once)
_pi_list=$(pi list 2>/dev/null || true)

# Pi packages: 2-space-indented identifier lines
_pi_pkgs=$(echo "$_pi_list" | grep -E '^  [^ ]' | sed 's/^  //' | sort | paste -sd, -)
echo "pi_packages=${_pi_pkgs:-(none)}"

# Pi-messenger: path is 4-space-indented line containing "messenger"
_pm_path=$(echo "$_pi_list" | grep "messenger" | grep -E '^    /' | tail -1 | sed 's/^    //' | xargs 2>/dev/null)
_pm_source=$(echo "$_pi_list" | grep "messenger" | grep -E '^  [^ ]' | head -1 | sed 's/^  //' | xargs 2>/dev/null)
if [ -z "$_pm_path" ] || [ ! -d "$_pm_path" ]; then
    echo "pm_version=MISSING"
    echo "pm_branch=MISSING"
    echo "pm_source=MISSING"
else
    echo "pm_version=$(grep '"version"' "$_pm_path/package.json" 2>/dev/null | head -1 | sed 's/.*: "//;s/".*//')"
    echo "pm_branch=$(cd "$_pm_path" && git branch --show-current 2>/dev/null)"
    echo "pm_source=${_pm_source:-MISSING}"
fi

# Homebrew list
echo "brew_list=$(brew list --formula -1 2>/dev/null | sort | paste -sd, -)"
REMOTE_SCRIPT
    ) || {
        local rc=$?
        if [[ $rc -eq 124 ]]; then
            log_err "Remote commands exceeded 15s timeout"
            exit 2
        elif [[ $rc -eq 255 ]]; then
            log_err "Cannot reach $SSH_HOST (SSH timeout or connection refused)"
            exit 2
        else
            log_err "SSH command failed (exit code $rc)"
            exit 2
        fi
    }

    # Parse key=value lines into REMOTE array (split on first = only)
    while IFS= read -r line; do
        [[ -z "$line" ]] && continue
        local key="${line%%=*}"
        local val="${line#*=}"
        REMOTE[$key]="$val"
    done <<< "$remote_output"
}

# ── Compare Logic ────────────────────────────────────────────────────────────
compare_all() {
    # Ordered key list for consistent output
    local -a keys=(
        pi_version
        agent_config_head
        agent_config_branch
        pm_version
        pm_branch
        pm_source
        openclaw_version
        node_version
        claude_version
        codex_version
        pi_packages
    )

    for key in "${keys[@]}"; do
        local lval="${LOCAL[$key]:-}"
        local rval="${REMOTE[$key]:-}"
        local verdict

        if [[ "$key" == "pi_packages" ]]; then
            # Expected drift — packages intentionally differ
            if [[ "$lval" == "$rval" ]]; then
                verdict="PASS"
            else
                verdict="DRIFT (expected)"
            fi
        elif [[ "$key" == "pm_source" ]]; then
            # Compare by class, not raw string
            local lclass rclass
            lclass=$(classify_pm_source "$lval")
            rclass=$(classify_pm_source "$rval")
            if [[ "$lclass" == "missing" ]] || [[ "$rclass" == "missing" ]]; then
                if [[ "$lclass" == "missing" ]] && [[ "$rclass" == "missing" ]]; then
                    verdict="MISSING"
                elif [[ "$lclass" == "missing" ]]; then
                    verdict="MISSING (local)"
                else
                    verdict="MISSING (remote)"
                fi
            elif [[ "$lclass" == "$rclass" ]]; then
                verdict="PASS"
            else
                verdict="DRIFT"
            fi
        else
            # Standard comparison
            local lmiss rmiss
            lmiss=false; rmiss=false
            is_missing "$lval" && lmiss=true
            is_missing "$rval" && rmiss=true

            if $lmiss && $rmiss; then
                verdict="MISSING"
            elif $lmiss; then
                verdict="MISSING (local)"
            elif $rmiss; then
                verdict="MISSING (remote)"
            elif [[ "$lval" == "$rval" ]]; then
                verdict="PASS"
            else
                verdict="DRIFT"
            fi
        fi

        add_result "$key" "$lval" "$rval" "$verdict"
    done
}

# ── Homebrew Check ───────────────────────────────────────────────────────────
check_brew() {
    [[ ! -f "$BREWFILE" ]] && return

    # Parse Brewfile for package names, normalize tap-qualified names
    local -a brew_pkgs=()
    while IFS= read -r line; do
        local pkg
        pkg=$(echo "$line" | sed 's/brew "//;s/".*//')
        pkg="${pkg##*/}"  # steipete/tap/peekaboo → peekaboo
        brew_pkgs+=("$pkg")
    done < <(grep '^brew "' "$BREWFILE")

    local local_brew="${LOCAL[brew_list]:-}"
    local remote_brew="${REMOTE[brew_list]:-}"

    for pkg in "${brew_pkgs[@]}"; do
        local l_has=false r_has=false

        # Check local (comma-separated list)
        if echo ",$local_brew," | grep -q ",$pkg,"; then
            l_has=true
        fi
        # Check remote
        if echo ",$remote_brew," | grep -q ",$pkg,"; then
            r_has=true
        fi

        if $l_has && $r_has; then
            add_result "brew:$pkg" "installed" "installed" "PASS"
        elif $l_has; then
            add_result "brew:$pkg" "installed" "missing" "MISSING (remote)"
        elif $r_has; then
            add_result "brew:$pkg" "missing" "installed" "MISSING (local)"
        else
            add_result "brew:$pkg" "missing" "missing" "MISSING"
        fi
    done
}

# ── Output ───────────────────────────────────────────────────────────────────
output_human() {
    local pass=0 drift=0 expected=0 missing=0
    local total=${#RESULT_KEYS[@]}

    echo ""
    echo -e "${BOLD}Machine Parity Check — laptop ↔ $SSH_HOST${NC}"
    echo "════════════════════════════════════════════════════════════════"

    for i in $(seq 0 $((total - 1))); do
        local key="${RESULT_KEYS[$i]}"
        local lval="${RESULT_LOCAL[$i]}"
        local rval="${RESULT_REMOTE[$i]}"
        local verdict="${RESULT_VERDICT[$i]}"

        # Format the display value
        local display
        case "$verdict" in
            PASS)
                display=$(printf "%-22s %-30s %s" "$key" "$lval" "PASS")
                log_ok "$display"
                pass=$((pass + 1))
                ;;
            "DRIFT (expected)")
                display=$(printf "%-22s %-30s %s" "$key" "$lval ≠ $rval" "DRIFT (expected)")
                log_exp "$display"
                expected=$((expected + 1))
                ;;
            DRIFT)
                display=$(printf "%-22s %-30s %s" "$key" "$lval ≠ $rval" "DRIFT")
                log_drift "$display"
                drift=$((drift + 1))
                ;;
            MISSING*)
                display=$(printf "%-22s %-30s %s" "$key" "$lval ≠ $rval" "$verdict")
                log_miss "$display"
                missing=$((missing + 1))
                ;;
        esac
    done

    echo "────────────────────────────────────────────────────────────────"
    local summary="$pass/$total PASS"
    [[ $drift -gt 0 ]] && summary+=" · $drift DRIFT"
    [[ $expected -gt 0 ]] && summary+=" · $expected DRIFT (expected)"
    [[ $missing -gt 0 ]] && summary+=" · $missing MISSING"
    echo -e "  $summary"
    echo ""
}

output_json() {
    local total=${#RESULT_KEYS[@]}
    local json_parts=()

    for i in $(seq 0 $((total - 1))); do
        json_parts+=("$(jq -n \
            --arg check "${RESULT_KEYS[$i]}" \
            --arg local "${RESULT_LOCAL[$i]}" \
            --arg remote "${RESULT_REMOTE[$i]}" \
            --arg verdict "${RESULT_VERDICT[$i]}" \
            '{check:$check, local:$local, remote:$remote, verdict:$verdict}')")
    done

    printf '%s\n' "${json_parts[@]}" | jq -s '.'
}

# ── Exit Code ────────────────────────────────────────────────────────────────
compute_exit_code() {
    local total=${#RESULT_KEYS[@]}
    for i in $(seq 0 $((total - 1))); do
        local verdict="${RESULT_VERDICT[$i]}"
        case "$verdict" in
            PASS|"DRIFT (expected)") ;;  # These are fine
            *) return 1 ;;              # Any DRIFT or MISSING
        esac
    done
    return 0
}

# ── Main ─────────────────────────────────────────────────────────────────────
main() {
    parse_args "$@"
    check_deps
    resolve_timeout_cmd

    gather_local
    gather_remote

    compare_all
    check_brew

    if [[ "$OUTPUT_JSON" == true ]]; then
        output_json
    else
        output_human
    fi

    compute_exit_code
}

main "$@"

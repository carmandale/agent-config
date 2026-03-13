#!/usr/bin/env bash
# gate.sh — structural enforcement for workflow command pipeline
# Part of spec 019 (Command Compliance Gates)
#
# Three subcommands:
#   gate   <command> <spec-dir>  — pre-flight check (exit 0=PASS, 1=FAIL, 2=WARN)
#   record <command> <spec-dir>  — post-completion sentinel + state trail
#   verify <command> <spec-dir>  — post-execution anti-fabrication check
#
# Reads gate_* keys from commands/<command>.md frontmatter.
# Portable bash — no Python, Node, yq. Standard Unix tools only.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
COMMANDS_DIR="$REPO_ROOT/commands"

# --- Frontmatter parser ---
# Extract a gate_* key from a command's markdown frontmatter.
# Returns comma-separated values, trimmed of whitespace.
# Usage: parse_frontmatter_key <command> <key>
parse_frontmatter_key() {
    local cmd_file="$COMMANDS_DIR/$1.md"
    if [[ ! -f "$cmd_file" ]]; then
        echo ""
        return
    fi

    # Extract value between --- delimiters for the given key
    local in_frontmatter=0
    local value=""
    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            if [[ $in_frontmatter -eq 1 ]]; then
                break  # End of frontmatter
            fi
            in_frontmatter=1
            continue
        fi
        if [[ $in_frontmatter -eq 1 ]]; then
            # Match key: value (handling optional quotes)
            if [[ "$line" =~ ^${2}:[[:space:]]*(.*) ]]; then
                value="${BASH_REMATCH[1]}"
                # Strip surrounding quotes if present
                value="${value#\"}"
                value="${value%\"}"
                value="${value#\'}"
                value="${value%\'}"
            fi
        fi
    done < "$cmd_file"

    echo "$value"
}

# Split comma-separated string into trimmed items (one per line)
split_csv() {
    echo "$1" | tr ',' '\n' | sed 's/^[[:space:]]*//;s/[[:space:]]*$//' | grep -v '^$'
}

# --- Sentinel matching ---
# Check if a sentinel pattern exists in a file.
# Supports backward-compatible matching for old and new formats.
# Usage: check_sentinel <file> <pattern>
# Returns 0 if found, 1 if not found
check_sentinel() {
    local file="$1"
    local pattern="$2"

    if [[ ! -f "$file" ]]; then
        return 1
    fi

    # Build grep pattern for both old and new sentinel formats
    case "$pattern" in
        "plan:complete:v1")
            grep -q '<!-- plan:complete:v1\|<!-- [Pp]lan.*[Cc]omplete' "$file" 2>/dev/null
            ;;
        "codex-review:approved:v1")
            grep -q '<!-- codex-review:approved:v1\|<!-- [Cc]odex.[Rr]eview.*APPROVED' "$file" 2>/dev/null
            ;;
        "shape:complete:v1")
            grep -q '<!-- shape:complete:v1\|<!-- [Ss]hape.*[Cc]omplete' "$file" 2>/dev/null
            ;;
        "issue:complete:v1")
            grep -q '<!-- issue:complete:v1\|<!-- [Ii]ssue.*[Cc]omplete' "$file" 2>/dev/null
            ;;
        *)
            # Generic: search for the pattern literally
            grep -q "<!-- $pattern" "$file" 2>/dev/null
            ;;
    esac
}

# Determine which file to check for a sentinel.
# Sentinel patterns map to specific files.
sentinel_file() {
    local spec_dir="$1"
    local pattern="$2"

    case "$pattern" in
        "plan:complete:v1")
            echo "$spec_dir/plan.md"
            ;;
        "codex-review:approved:v1")
            echo "$spec_dir/codex-review.md"
            ;;
        "shape:complete:v1")
            echo "$spec_dir/shaping-transcript.md"
            ;;
        "issue:complete:v1")
            echo "$spec_dir/spec.md"
            ;;
        *)
            # Default: check plan.md
            echo "$spec_dir/plan.md"
            ;;
    esac
}

# --- Subcommands ---

cmd_gate() {
    local command="$1"
    local spec_dir="$2"
    local exit_code=0
    local warnings=()
    local failures=()

    echo "🔍 gate check: /$command against $spec_dir"
    echo ""

    # Validate spec dir exists
    if [[ ! -d "$spec_dir" ]]; then
        echo "❌ FAIL: Spec directory does not exist: $spec_dir"
        echo ""
        echo "Run /issue to create the spec directory first."
        exit 1
    fi

    # --- Check gate_requires ---
    local requires
    requires=$(parse_frontmatter_key "$command" "gate_requires")
    if [[ -n "$requires" ]]; then
        while IFS= read -r req_file; do
            [[ -z "$req_file" ]] && continue
            if [[ ! -f "$spec_dir/$req_file" ]]; then
                failures+=("Missing required file: $req_file")

                # Provide actionable guidance
                case "$req_file" in
                    spec.md)
                        failures+=("  → Run /issue to create the spec and bead")
                        ;;
                    plan.md|tasks.md)
                        failures+=("  → Run /plan to create the implementation plan")
                        ;;
                    codex-review.md)
                        failures+=("  → Run /codex-review to get the plan reviewed")
                        ;;
                esac
            fi
        done <<< "$(split_csv "$requires")"
    fi

    # --- Check bead in spec.md ---
    if [[ -n "$requires" ]] && echo "$requires" | grep -q "spec.md"; then
        if [[ -f "$spec_dir/spec.md" ]]; then
            if ! grep -q '^bead:' "$spec_dir/spec.md" 2>/dev/null; then
                failures+=("spec.md exists but has no bead: in frontmatter")
                failures+=("  → Every spec needs a bead (§5.2 of AGENTS.md)")
            fi
        fi
    fi

    # --- Check gate_sentinels (hard requirement — exit 1 if absent) ---
    local sentinels
    sentinels=$(parse_frontmatter_key "$command" "gate_sentinels")
    if [[ -n "$sentinels" ]]; then
        while IFS= read -r sentinel; do
            [[ -z "$sentinel" ]] && continue
            local sentinel_target
            sentinel_target=$(sentinel_file "$spec_dir" "$sentinel")

            if [[ ! -f "$sentinel_target" ]]; then
                failures+=("Sentinel file missing: $(basename "$sentinel_target") (needed for $sentinel)")
                case "$sentinel" in
                    "plan:complete:v1")
                        failures+=("  → Run /plan to create plan.md with provenance sentinel")
                        ;;
                    "codex-review:approved:v1")
                        failures+=("  → Run /codex-review to get the plan approved")
                        ;;
                esac
            elif ! check_sentinel "$sentinel_target" "$sentinel"; then
                # Check if this is a pre-existing spec (R6 backward compat)
                # Look for workflow-state.md as supplementary check
                if [[ -f "$spec_dir/workflow-state.md" ]]; then
                    # State trail exists — check if the prerequisite command ran
                    local prereq_cmd=""
                    case "$sentinel" in
                        "plan:complete:v1") prereq_cmd="/plan" ;;
                        "codex-review:approved:v1") prereq_cmd="/codex-review" ;;
                    esac
                    if [[ -n "$prereq_cmd" ]] && grep -q "$prereq_cmd" "$spec_dir/workflow-state.md" 2>/dev/null; then
                        warnings+=("Sentinel $sentinel not found in $(basename "$sentinel_target"), but workflow-state.md shows $prereq_cmd ran — likely a pre-existing spec (R6)")
                    else
                        failures+=("Sentinel $sentinel not found in $(basename "$sentinel_target")")
                        case "$sentinel" in
                            "plan:complete:v1")
                                failures+=("  → Run /plan — the plan exists but wasn't produced by the /plan command")
                                ;;
                        esac
                    fi
                else
                    # No workflow-state.md — this might be a pre-existing spec
                    # R6: warn but don't block for specs created before this system
                    warnings+=("⚠️  Sentinel $sentinel not found in $(basename "$sentinel_target") — was /$command's prerequisite run? (If this is a pre-existing spec, this warning is expected per R6)")
                fi
            fi
        done <<< "$(split_csv "$sentinels")"
    fi

    # --- Check gate_warn_sentinels (soft requirement — exit 2 if absent) ---
    local warn_sentinels
    warn_sentinels=$(parse_frontmatter_key "$command" "gate_warn_sentinels")
    if [[ -n "$warn_sentinels" ]]; then
        while IFS= read -r sentinel; do
            [[ -z "$sentinel" ]] && continue
            local sentinel_target
            sentinel_target=$(sentinel_file "$spec_dir" "$sentinel")

            if [[ -f "$sentinel_target" ]]; then
                if ! check_sentinel "$sentinel_target" "$sentinel"; then
                    warnings+=("⚠️  Recommended sentinel $sentinel not found in $(basename "$sentinel_target")")
                    case "$sentinel" in
                        "codex-review:approved:v1")
                            warnings+=("  → Consider running /codex-review before /implement")
                            warnings+=("  → This is a recommendation, not a hard requirement (yet)")
                            ;;
                    esac
                fi
            else
                warnings+=("⚠️  Recommended sentinel file missing: $(basename "$sentinel_target") (for $sentinel)")
                case "$sentinel" in
                    "codex-review:approved:v1")
                        warnings+=("  → Consider running /codex-review before /implement")
                        ;;
                esac
            fi
        done <<< "$(split_csv "$warn_sentinels")"
    fi

    # --- Write gate timestamp for verify baseline ---
    if [[ ${#failures[@]} -eq 0 ]]; then
        local ts_file="$spec_dir/.gate-${command}-timestamp"
        date +%s > "$ts_file"
    fi

    # --- Report results ---
    if [[ ${#failures[@]} -gt 0 ]]; then
        echo "❌ FAIL — gate check for /$command"
        echo ""
        for msg in "${failures[@]}"; do
            echo "  $msg"
        done
        if [[ ${#warnings[@]} -gt 0 ]]; then
            echo ""
            for msg in "${warnings[@]}"; do
                echo "  $msg"
            done
        fi
        echo ""
        echo "STOP. Do NOT create the missing files. Do NOT offer to create them."
        echo "Do NOT proceed with workarounds. Show this output to the user and wait."
        exit 1
    fi

    if [[ ${#warnings[@]} -gt 0 ]]; then
        echo "⚠️  WARN — gate check for /$command passed with warnings"
        echo ""
        for msg in "${warnings[@]}"; do
            echo "  $msg"
        done
        echo ""
        echo "Show this warning to the user and ask THEM whether to proceed."
        echo "This is the USER's decision, not yours."
        exit 2
    fi

    echo "✅ PASS — gate check for /$command"
    echo "  All prerequisites verified. Proceed."
    exit 0
}

cmd_record() {
    local command="$1"
    local spec_dir="$2"
    local harness="${GATE_HARNESS:-unknown}"
    local extra="${GATE_EXTRA:-}"

    # Parse --harness and --extra from remaining args
    shift 2
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --harness) harness="$2"; shift 2 ;;
            --extra) extra="$2"; shift 2 ;;
            *) shift ;;
        esac
    done

    echo "📝 recording: /$command completion in $spec_dir"

    # Validate spec dir exists
    if [[ ! -d "$spec_dir" ]]; then
        echo "❌ ERROR: Spec directory does not exist: $spec_dir"
        exit 1
    fi

    local iso_date
    iso_date=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    local short_date
    short_date=$(date +"%Y-%m-%d %H:%M")

    # --- Write sentinels into gate_creates files ---
    local creates
    creates=$(parse_frontmatter_key "$command" "gate_creates")
    local sentinel_line="<!-- ${command}:complete:v1 | harness: ${harness} | date: ${iso_date}"
    if [[ -n "$extra" ]]; then
        sentinel_line="${sentinel_line} | ${extra}"
    fi
    sentinel_line="${sentinel_line} -->"

    local files_recorded=()
    if [[ -n "$creates" ]]; then
        while IFS= read -r create_file; do
            [[ -z "$create_file" ]] && continue

            # Skip non-file entries like "code changes" or "commits"
            case "$create_file" in
                "code changes"|"commits"|"code changes, commits")
                    continue
                    ;;
            esac

            local target="$spec_dir/$create_file"
            if [[ -f "$target" ]]; then
                # Check if sentinel already exists
                if ! grep -q "${command}:complete:v1" "$target" 2>/dev/null; then
                    # Insert sentinel after frontmatter (after second ---) or at top
                    if head -1 "$target" | grep -q '^---$'; then
                        # Has frontmatter — insert after closing ---
                        local tmp
                        tmp=$(mktemp)
                        local found_close=0
                        local inserted=0
                        while IFS= read -r line; do
                            echo "$line" >> "$tmp"
                            if [[ "$line" == "---" && $found_close -eq 0 ]]; then
                                found_close=1
                            elif [[ "$line" == "---" && $found_close -eq 1 && $inserted -eq 0 ]]; then
                                echo "" >> "$tmp"
                                echo "$sentinel_line" >> "$tmp"
                                inserted=1
                            fi
                        done < "$target"
                        if [[ $inserted -eq 0 ]]; then
                            # Frontmatter never closed or single --- only
                            echo "" >> "$tmp"
                            echo "$sentinel_line" >> "$tmp"
                        fi
                        mv "$tmp" "$target"
                    else
                        # No frontmatter — prepend
                        local tmp
                        tmp=$(mktemp)
                        echo "$sentinel_line" > "$tmp"
                        echo "" >> "$tmp"
                        cat "$target" >> "$tmp"
                        mv "$tmp" "$target"
                    fi
                    files_recorded+=("$create_file")
                else
                    echo "  ℹ️  Sentinel already exists in $create_file — skipping"
                fi
            else
                echo "  ⚠️  File $create_file not found in spec dir — skipping sentinel"
            fi
        done <<< "$(split_csv "$creates")"
    fi

    # --- Append to workflow-state.md ---
    local state_file="$spec_dir/workflow-state.md"
    local state_entry="${short_date} | ${harness} | /${command}"

    if [[ ${#files_recorded[@]} -gt 0 ]]; then
        local joined
        joined=$(printf ", %s" "${files_recorded[@]}")
        joined="${joined:2}"  # Strip leading ", "
        state_entry="${state_entry} | ${joined} recorded"
    else
        state_entry="${state_entry} | completed"
    fi

    if [[ -n "$extra" ]]; then
        state_entry="${state_entry} (${extra})"
    fi

    echo "$state_entry" >> "$state_file"

    echo "✅ recorded /$command completion"
    if [[ ${#files_recorded[@]} -gt 0 ]]; then
        echo "  Sentinels written to: ${files_recorded[*]}"
    fi
    echo "  State trail: workflow-state.md updated"
}

cmd_verify() {
    local command="$1"
    local spec_dir="$2"

    echo "🔎 verify: checking /$command anti-fabrication in $spec_dir"
    echo ""

    # Read gate_must_not_create from command frontmatter
    local must_not_create
    must_not_create=$(parse_frontmatter_key "$command" "gate_must_not_create")

    if [[ -z "$must_not_create" ]]; then
        echo "✅ CLEAN — no gate_must_not_create defined for /$command"
        exit 0
    fi

    # Read baseline timestamp
    local ts_file="$spec_dir/.gate-${command}-timestamp"
    local baseline=0
    if [[ -f "$ts_file" ]]; then
        baseline=$(cat "$ts_file")
    else
        echo "⚠️  No gate timestamp found — checking all files (may produce false positives)"
        echo "  Run 'gate.sh gate $command $spec_dir' first to establish baseline"
    fi

    local violations=()
    while IFS= read -r forbidden_file; do
        [[ -z "$forbidden_file" ]] && continue

        # Skip non-file entries
        case "$forbidden_file" in
            "code changes"|"commits"|"code changes, commits")
                continue
                ;;
        esac

        local target="$spec_dir/$forbidden_file"
        if [[ -f "$target" ]]; then
            if [[ $baseline -gt 0 ]]; then
                # Check mtime against baseline
                local file_mtime
                if [[ "$(uname)" == "Darwin" ]]; then
                    file_mtime=$(stat -f %m "$target")
                else
                    file_mtime=$(stat -c %Y "$target")
                fi

                if [[ $file_mtime -ge $baseline ]]; then
                    violations+=("VIOLATION: $forbidden_file was created/modified after gate check (mtime: $(date -r "$file_mtime" +"%Y-%m-%d %H:%M:%S" 2>/dev/null || date -d "@$file_mtime" +"%Y-%m-%d %H:%M:%S" 2>/dev/null))")
                fi
            else
                # No baseline — report existence as potential violation
                violations+=("VIOLATION: $forbidden_file exists (no baseline timestamp for comparison)")
            fi
        fi
    done <<< "$(split_csv "$must_not_create")"

    # Clean up timestamp file
    rm -f "$ts_file"

    if [[ ${#violations[@]} -gt 0 ]]; then
        echo "❌ VIOLATION — /$command created files it must not create:"
        echo ""
        for msg in "${violations[@]}"; do
            echo "  $msg"
        done
        echo ""
        echo "These files belong to other commands. They should not have been created by /$command."
        exit 1
    fi

    echo "✅ CLEAN — no anti-fabrication violations found for /$command"
    exit 0
}

# --- Usage ---
usage() {
    cat << 'EOF'
Usage: gate.sh <subcommand> <command> <spec-dir> [options]

Subcommands:
  gate   <command> <spec-dir>   Pre-flight check (exit 0=PASS, 1=FAIL, 2=WARN)
  record <command> <spec-dir>   Post-completion sentinel + state trail
  verify <command> <spec-dir>   Post-execution anti-fabrication check

Options (record only):
  --harness <id>    Harness/model identifier (e.g., "pi/claude-sonnet-4")
  --extra <fields>  Additional sentinel fields (e.g., "rounds: 2, model: gpt-5.3-codex")

Examples:
  gate.sh gate implement specs/019-command-compliance-gates/
  gate.sh record plan specs/019-command-compliance-gates/ --harness "pi/claude-sonnet-4"
  gate.sh verify implement specs/019-command-compliance-gates/

Environment:
  GATE_HARNESS   Default harness identifier (overridden by --harness)
  GATE_EXTRA     Default extra sentinel fields (overridden by --extra)
EOF
}

# --- Main dispatch ---
if [[ $# -lt 1 ]]; then
    usage
    exit 1
fi

subcmd="$1"
shift

case "$subcmd" in
    gate)
        if [[ $# -lt 2 ]]; then
            echo "Usage: gate.sh gate <command> <spec-dir>"
            exit 1
        fi
        cmd_gate "$1" "$2"
        ;;
    record)
        if [[ $# -lt 2 ]]; then
            echo "Usage: gate.sh record <command> <spec-dir> [--harness <id>] [--extra <fields>]"
            exit 1
        fi
        cmd_record "$@"
        ;;
    verify)
        if [[ $# -lt 2 ]]; then
            echo "Usage: gate.sh verify <command> <spec-dir>"
            exit 1
        fi
        cmd_verify "$1" "$2"
        ;;
    -h|--help|help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown subcommand: $subcmd"
        echo ""
        usage
        exit 1
        ;;
esac

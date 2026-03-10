#!/usr/bin/env bash
# scripts/migrate-to-br.sh — Fleet-wide bd→br migration
# Spec: 013-br-fleet-migration | Bead: .agent-config-2gy
#
# Reads a fleet manifest and migrates each repo from bd to br.
# Detection: `br list` output — if DATABASE_ERROR, repo needs migration.
# NEVER auto-commits to other repos. Operator reviews JSONL changes.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
AGENT_CONFIG_DIR="$(dirname "$SCRIPT_DIR")"
VERSION_FILE="$AGENT_CONFIG_DIR/configs/br-version.txt"
MANIFEST_FILE=""
DRY_RUN=false
DISCOVER_ROOT=""

# Summary counters
declare -a MIGRATED=()
declare -a SKIPPED_BR_WORKS=()
declare -a SKIPPED_ALREADY=()
declare -a INITIALIZED=()
declare -a FAILED=()
declare -a JSONL_DIRTY=()

usage() {
    cat <<EOF
Usage: $(basename "$0") [OPTIONS]

Options:
  --manifest FILE    Path to fleet-manifest.txt (default: specs/013-br-fleet-migration/fleet-manifest.txt)
  --discover ROOT    Discovery mode: scan ROOT for .beads/ dirs and print manifest (no migration)
  --dry-run          Log actions without executing
  -h, --help         Show this help

Modes:
  Default: Read manifest, migrate repos that need it
  --discover: Scan for repos and output manifest format (for initial manifest generation)
EOF
    exit 0
}

# Parse arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        --manifest) MANIFEST_FILE="$2"; shift 2 ;;
        --discover) DISCOVER_ROOT="$2"; shift 2 ;;
        --dry-run) DRY_RUN=true; shift ;;
        -h|--help) usage ;;
        *) echo "ERROR: Unknown option: $1"; usage ;;
    esac
done

# ============================================================
# Discovery mode — output manifest, do NOT migrate
# ============================================================
if [[ -n "$DISCOVER_ROOT" ]]; then
    echo "# Fleet Manifest — generated $(date +%Y-%m-%d)"
    echo "# Format: <status> <repo-path>"
    find "$DISCOVER_ROOT" -mindepth 2 -maxdepth 2 -name ".beads" -type d -print0 2>/dev/null | \
    while IFS= read -r -d '' beads_dir; do
        repo_dir=$(dirname "$beads_dir")
        repo_name=$(basename "$repo_dir")
        output=$(cd "$repo_dir" && br list 2>&1) || true
        if echo "$output" | grep -q "DATABASE_ERROR"; then
            echo "needs-migration $repo_dir"
        else
            echo "br-works $repo_dir"
        fi
    done | sort -t' ' -k1,1 -k2,2
    exit 0
fi

# ============================================================
# Migration mode — read manifest, process repos
# ============================================================

# Default manifest path
if [[ -z "$MANIFEST_FILE" ]]; then
    MANIFEST_FILE="$AGENT_CONFIG_DIR/specs/013-br-fleet-migration/fleet-manifest.txt"
fi

if [[ ! -f "$MANIFEST_FILE" ]]; then
    echo "ERROR: Manifest not found: $MANIFEST_FILE"
    echo "Generate one with: $(basename "$0") --discover /path/to/repos"
    exit 1
fi

# ============================================================
# Preflight: version check
# ============================================================
if [[ ! -f "$VERSION_FILE" ]]; then
    echo "ERROR: Version file not found: $VERSION_FILE"
    exit 1
fi

EXPECTED_VERSION=$(cat "$VERSION_FILE" | tr -d '[:space:]')
ACTUAL_VERSION=$(br --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)

if [[ "$EXPECTED_VERSION" != "$ACTUAL_VERSION" ]]; then
    echo "ERROR: br version mismatch — expected $EXPECTED_VERSION, got $ACTUAL_VERSION."
    echo "Update br or configs/br-version.txt before proceeding."
    exit 1
fi

echo "✅ br version check: $ACTUAL_VERSION matches $EXPECTED_VERSION"
echo ""

# ============================================================
# Detect if repo needs migration: br list check for DATABASE_ERROR
# ============================================================
needs_migration() {
    local repo_dir="$1"
    local output
    output=$(cd "$repo_dir" && br list 2>&1) || true
    echo "$output" | grep -q "DATABASE_ERROR"
}

# ============================================================
# Per-repo migration procedure
# ============================================================
migrate_repo() {
    local repo_dir="$1"
    local repo_name
    repo_name=$(basename "$repo_dir")
    local beads_dir="$repo_dir/.beads"
    local db_file="$beads_dir/beads.db"
    local jsonl_file="$beads_dir/issues.jsonl"

    echo "━━━ Processing: $repo_name ━━━"
    echo "    Path: $repo_dir"

    # Step 1: Check if already br-compatible
    if ! needs_migration "$repo_dir"; then
        echo "    ✅ br list works — already compatible, skipping"
        SKIPPED_BR_WORKS+=("$repo_name")
        echo ""
        return 0
    fi

    echo "    🔄 DATABASE_ERROR detected — needs migration"

    # Step 2: Pre-flush with bd
    if [[ -f "$jsonl_file" ]]; then
        echo "    📤 Pre-flush: bd sync --flush-only"
        if [[ "$DRY_RUN" == true ]]; then
            echo "    [DRY-RUN] Would run: cd '$repo_dir' && bd sync --flush-only"
        else
            local flush_exit=0
            local flush_output
            flush_output=$(cd "$repo_dir" && bd sync --flush-only 2>&1) || flush_exit=$?

            # Hard-fail if exit code is non-zero AND beads.db has data
            if [[ "$flush_exit" -ne 0 ]]; then
                if [[ -f "$db_file" ]] && [[ $(stat -f%z "$db_file" 2>/dev/null || echo 0) -gt 0 ]]; then
                    echo "    ❌ FAILED: bd sync --flush-only exited $flush_exit with a non-empty beads.db"
                    echo "    Output: $(echo "$flush_output" | head -5)"
                    echo "    Operator must investigate before this repo can proceed."
                    FAILED+=("$repo_name: pre-flush exit=$flush_exit — $(echo "$flush_output" | head -1)")
                    echo ""
                    return 1
                else
                    echo "    ⚠️  bd sync --flush-only exited $flush_exit but no beads.db with data — continuing"
                fi
            fi

            # Check if JSONL was modified
            local jsonl_dirty
            jsonl_dirty=$(cd "$repo_dir" && git diff --name-only -- .beads/issues.jsonl 2>/dev/null || true)
            if [[ -n "$jsonl_dirty" ]]; then
                echo "    📝 JSONL was updated by pre-flush (needs manual git commit)"
                JSONL_DIRTY+=("$repo_dir")
            fi
        fi
    fi

    # Step 3: Backup existing db + clean WAL/SHM (stale WAL corrupts fresh br init)
    if [[ -f "$db_file" ]]; then
        echo "    💾 Backup: mv beads.db → beads.db.bd-backup"
        if [[ "$DRY_RUN" == true ]]; then
            echo "    [DRY-RUN] Would run: mv '$db_file' '$db_file.bd-backup'"
        else
            mv "$db_file" "${db_file}.bd-backup"
            # Remove WAL/SHM files — they belong to the old bd database
            # Leaving them causes "database disk image is malformed" on br init
            [[ -f "${db_file}-wal" ]] && trash "${db_file}-wal" 2>/dev/null
            [[ -f "${db_file}-shm" ]] && trash "${db_file}-shm" 2>/dev/null
        fi
    fi

    # Step 3.5: Normalize JSONL IDs for br compatibility
    # br rejects: (a) uppercase chars in IDs, (b) dots in hash portion (bd sub-issue notation)
    if [[ -f "$jsonl_file" ]] && [[ $(grep -c '{' "$jsonl_file" 2>/dev/null || echo 0) -gt 0 ]]; then
        local has_upper has_dots needs_normalize=false
        has_upper=$(jq -r '.id' "$jsonl_file" 2>/dev/null | grep -c '[A-Z]' || true)
        has_dots=$(jq -r '.id' "$jsonl_file" 2>/dev/null | grep -c '\.' || true)
        [[ "$has_upper" -gt 0 ]] && needs_normalize=true
        [[ "$has_dots" -gt 0 ]] && needs_normalize=true
        if [[ "$needs_normalize" == true ]]; then
            echo "    🔡 Normalizing JSONL IDs (uppercase=$has_upper, dots=$has_dots)"
            if [[ "$DRY_RUN" == false ]]; then
                # Lowercase all IDs and replace dots with 'd' (collision-free, verified)
                # Also normalize depends_on/blocked_by refs
                local tmp_jsonl="${jsonl_file}.normalizing"
                jq -c '
                    def normalize_id: ascii_downcase | gsub("\\."; "d");
                    .id |= normalize_id |
                    if .depends_on then .depends_on = [.depends_on[] | .id |= normalize_id] else . end |
                    if .blocked_by then .blocked_by = [.blocked_by[] | .id |= normalize_id] else . end
                ' "$jsonl_file" > "$tmp_jsonl" && mv "$tmp_jsonl" "$jsonl_file"
                # Mark JSONL as dirty since we modified it
                JSONL_DIRTY+=("$repo_dir")
            fi
        fi
    fi

    # Step 4: br init — use lowercased prefix from JSONL (not basename)
    local prefix="$repo_name"
    if [[ -f "$jsonl_file" ]] && [[ $(grep -c '{' "$jsonl_file" 2>/dev/null || echo 0) -gt 0 ]]; then
        # Extract prefix from first JSONL entry (already lowercased above)
        local first_id
        first_id=$(jq -r '.id' "$jsonl_file" 2>/dev/null | head -1)
        if [[ -n "$first_id" ]]; then
            local detected_prefix="${first_id%-*}"
            if [[ -n "$detected_prefix" && "$detected_prefix" != "$first_id" ]]; then
                prefix="$detected_prefix"
                if [[ "$prefix" != "$repo_name" ]]; then
                    echo "    ℹ️  Using JSONL prefix '$prefix' (differs from repo name '$repo_name')"
                fi
            fi
        fi
    fi
    echo "    🔧 Init: br init --prefix '$prefix' --force"
    if [[ "$DRY_RUN" == true ]]; then
        echo "    [DRY-RUN] Would run: cd '$repo_dir' && br init --prefix '$prefix' --force"
    else
        (cd "$repo_dir" && br init --prefix "$prefix" --force 2>&1) || {
            echo "    ❌ FAILED: br init failed"
            FAILED+=("$repo_name: br init failed")
            echo ""
            return 1
        }
    fi

    # Step 5: Import from JSONL
    if [[ -f "$jsonl_file" ]] && [[ $(grep -c '{' "$jsonl_file" 2>/dev/null || echo 0) -gt 0 ]]; then
        # Detect multi-prefix: if JSONL has IDs with different prefixes, need --rename-prefix
        local import_flags="--import-only"
        local unique_prefixes
        unique_prefixes=$(jq -r '.id' "$jsonl_file" 2>/dev/null | sed 's/-[^-]*$//' | sort -u | wc -l | tr -d ' ')
        if [[ "$unique_prefixes" -gt 1 ]]; then
            import_flags="--import-only --rename-prefix"
            echo "    🔧 Multi-prefix detected ($unique_prefixes prefixes) — adding --rename-prefix"
        fi

        echo "    📥 Import: br sync $import_flags"
        if [[ "$DRY_RUN" == true ]]; then
            echo "    [DRY-RUN] Would run: cd '$repo_dir' && br sync $import_flags"
        else
            local import_exit=0
            local import_output
            import_output=$(cd "$repo_dir" && br sync $import_flags 2>&1) || import_exit=$?
            if [[ "$import_exit" -ne 0 ]]; then
                echo "    ❌ FAILED: br sync $import_flags exited $import_exit"
                echo "    Output: $(echo "$import_output" | head -5)"
                FAILED+=("$repo_name: import exit=$import_exit — $(echo "$import_output" | head -1)")
                echo ""
                return 1
            fi
        fi

        # Step 6: ID-set integrity check (uses sqlite3 directly — br list caps at 50)
        if [[ "$DRY_RUN" == false ]]; then
            echo "    🔍 Verifying ID-set integrity..."
            local br_ids jsonl_ids br_count jsonl_count
            br_ids=$(sqlite3 "$db_file" "SELECT id FROM issues ORDER BY id;" 2>/dev/null)
            jsonl_ids=$(jq -r '.id' "$jsonl_file" 2>/dev/null | sort)
            br_count=$(echo "$br_ids" | grep -c . || echo 0)
            jsonl_count=$(echo "$jsonl_ids" | grep -c . || echo 0)

            if echo "$import_flags" | grep -q "rename-prefix"; then
                # --rename-prefix generates new hashes, so ID-set diff will always differ
                # Verify by count only + confirm import logged correct number
                if [[ "$br_count" -ne "$jsonl_count" ]]; then
                    echo "    ❌ FAILED: Count mismatch after --rename-prefix (db=$br_count, jsonl=$jsonl_count)"
                    FAILED+=("$repo_name: count mismatch after rename — db=$br_count, jsonl=$jsonl_count")
                    echo ""
                    return 1
                fi
                echo "    ✅ Count-based integrity verified: $br_count issues (--rename-prefix changes IDs)"
            else
                local id_diff
                id_diff=$(diff <(echo "$br_ids") <(echo "$jsonl_ids") 2>/dev/null || true)
                if [[ -n "$id_diff" ]]; then
                    echo "    ❌ FAILED: ID-set mismatch (db=$br_count, jsonl=$jsonl_count)"
                    echo "    Diff: $(echo "$id_diff" | head -5)"
                    FAILED+=("$repo_name: ID-set mismatch — db=$br_count, jsonl=$jsonl_count")
                    echo ""
                    return 1
                fi
                echo "    ✅ ID-set integrity verified: $br_count issues match"
            fi
        fi
    else
        echo "    ℹ️  No JSONL data — init only (no import)"
        INITIALIZED+=("$repo_name")
        echo ""
        return 0
    fi

    # Step 7: br doctor (informational — br doctor has known false positives)
    if [[ "$DRY_RUN" == false ]]; then
        local doctor_output
        doctor_output=$(cd "$repo_dir" && br doctor 2>&1) || true
        if echo "$doctor_output" | grep -q "ERROR"; then
            echo "    ⚠️  br doctor reports errors (non-blocking, known false positives):"
            echo "$doctor_output" | grep "ERROR" | sed 's/^/    /'
        fi
    fi

    MIGRATED+=("$repo_name")
    echo "    ✅ Migration complete"
    echo ""
    return 0
}

# ============================================================
# Main: process manifest
# ============================================================
echo "═══════════════════════════════════════════════════"
echo "  Fleet Migration: bd → br"
echo "  Manifest: $MANIFEST_FILE"
echo "  Dry run: $DRY_RUN"
echo "═══════════════════════════════════════════════════"
echo ""

TOTAL=0
while IFS= read -r line; do
    # Skip comments and empty lines
    [[ "$line" =~ ^#.*$ ]] && continue
    [[ -z "$line" ]] && continue

    status=$(echo "$line" | awk '{print $1}')
    repo_path=$(echo "$line" | cut -d' ' -f2-)

    if [[ ! -d "$repo_path" ]]; then
        echo "⚠️  Repo not found, skipping: $repo_path"
        continue
    fi

    TOTAL=$((TOTAL + 1))

    case "$status" in
        already-migrated)
            echo "━━━ $(basename "$repo_path"): already-migrated (manifest) — skipping ━━━"
            SKIPPED_ALREADY+=("$(basename "$repo_path")")
            echo ""
            ;;
        br-works)
            echo "━━━ $(basename "$repo_path"): br-works (manifest) — verifying ━━━"
            # Verify it still works
            if needs_migration "$repo_path"; then
                echo "    ⚠️  Manifest says br-works but DATABASE_ERROR detected! Migrating..."
                migrate_repo "$repo_path" || true
            else
                echo "    ✅ Confirmed: br list works"
                SKIPPED_BR_WORKS+=("$(basename "$repo_path")")
            fi
            echo ""
            ;;
        needs-migration)
            migrate_repo "$repo_path" || true
            ;;
        *)
            echo "⚠️  Unknown status '$status' for: $repo_path"
            ;;
    esac
done < "$MANIFEST_FILE"

# ============================================================
# Summary
# ============================================================
echo ""
echo "═══════════════════════════════════════════════════"
echo "  MIGRATION SUMMARY"
echo "═══════════════════════════════════════════════════"
echo ""
echo "Total repos processed: $TOTAL"
echo ""

if [[ ${#MIGRATED[@]} -gt 0 ]]; then
    echo "✅ MIGRATED (${#MIGRATED[@]}):"
    printf '   %s\n' "${MIGRATED[@]}"
    echo ""
fi

if [[ ${#SKIPPED_BR_WORKS[@]} -gt 0 ]]; then
    echo "⏭️  SKIPPED — br already works (${#SKIPPED_BR_WORKS[@]}):"
    printf '   %s\n' "${SKIPPED_BR_WORKS[@]}"
    echo ""
fi

if [[ ${#SKIPPED_ALREADY[@]} -gt 0 ]]; then
    echo "⏭️  SKIPPED — already migrated (${#SKIPPED_ALREADY[@]}):"
    printf '   %s\n' "${SKIPPED_ALREADY[@]}"
    echo ""
fi

if [[ ${#INITIALIZED[@]} -gt 0 ]]; then
    echo "🔧 INITIALIZED — no data (${#INITIALIZED[@]}):"
    printf '   %s\n' "${INITIALIZED[@]}"
    echo ""
fi

if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "❌ FAILED (${#FAILED[@]}):"
    printf '   %s\n' "${FAILED[@]}"
    echo ""
fi

if [[ ${#JSONL_DIRTY[@]} -gt 0 ]]; then
    echo "📝 JSONL CHANGES NEEDING MANUAL COMMIT (${#JSONL_DIRTY[@]}):"
    for repo in "${JSONL_DIRTY[@]}"; do
        echo "   cd '$repo' && git add .beads/issues.jsonl && git commit -m 'chore: pre-br-migration bd flush' && git push"
    done
    echo ""
fi

# Exit with error if any failed
if [[ ${#FAILED[@]} -gt 0 ]]; then
    echo "⛔ ${#FAILED[@]} repo(s) failed. Investigate before proceeding."
    exit 1
fi

echo "✅ All repos processed successfully."

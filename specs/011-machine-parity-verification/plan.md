<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-09 -->
<!-- Status: REVISED -->
<!-- Revisions: R1: +pi_packages verdicted, +pm_source check, +pm_path guard, +timeout 15, +jq check, +parity tool boundary, +path quoting. R2: INFO→DRIFT(expected), +timeout portability, +pi_packages regex fix, +classify_pm_source() -->
---
title: "Machine Parity Verification — Implementation Plan"
date: 2026-03-09
bead: .agent-config-8i7
---

# 011: Machine Parity Verification — Plan

## Relationship to Existing `agent-config-parity`

An existing tool lives at `tools-bin/agent-config-parity` (323 lines). It audits **local config state**: symlink integrity (managed surfaces), external config paths, and a handful of tool versions (git, bash, bun, node, bd, rg). It uses a snapshot/compare workflow — run on each machine separately, then diff the snapshots.

**This script (`parity-check.sh`) has a different scope and workflow:**

| Concern | `agent-config-parity` | `parity-check.sh` (this spec) |
|---------|----------------------|-------------------------------|
| **Purpose** | Audit local config integrity (symlinks, paths) | Quick live cross-machine version/state comparison |
| **Workflow** | Two manual runs → compare snapshots | Single command, live SSH, instant answer |
| **Checks** | Symlink targets, external paths, 7 tool binaries | Pi ecosystem versions, git state, Homebrew Brewfile |
| **Output** | key=value snapshot files | Human table or `--json` |
| **SSH** | None (local-only) | Batched SSH to mini-ts |
| **PASS/DRIFT/MISSING** | No (raw diff) | Yes (per-check verdicts) |

**Ownership boundary:** `agent-config-parity` owns config-surface auditing (are symlinks correct?). `parity-check.sh` owns runtime-state comparison (are versions in sync?). Neither tool replaces the other. The skill file (T9) documents when to use which tool.

## Selected Shape

**Shape B: Parallel SSH with Structured Output** (from shaping-transcript.md)

Single bash script. Gathers all local values, batches all remote checks into one SSH call, compares, outputs human table (default) or JSON (`--json`).

## Architecture

```
parity-check.sh
├── parse_args()           # --json flag, --help
├── check_deps()           # Verify jq available when --json requested
├── gather_local()         # LOCAL associative array
├── gather_remote()        # Single ssh mini-ts bash -s heredoc → REMOTE array
├── is_missing()           # Detect "command not found" / empty / MISSING
├── compare_all()          # Iterate keys, assign PASS/DRIFT/MISSING
├── check_brew()           # Brewfile-based set comparison (separate from k/v checks)
├── output_human()         # Colored table
├── output_json()          # jq -n --arg (NEVER string interpolation)
└── summary + exit code    # 0=pass, 1=drift, 2=ssh-failure, 3=missing-dep
```

## File Locations

| Artifact | Path |
|----------|------|
| Script | `~/.agent-config/scripts/parity-check.sh` |
| Skill | `~/.agent-config/skills/machine-parity/SKILL.md` |

## Check List

| Key | Command (both sides) | Normalization | Category | Spec Req |
|-----|---------------------|---------------|----------|----------|
| `pi_version` | `pi --version` | `grep -oE '[0-9]+\.[0-9]+\.[0-9]+'` | Agent infra | R2 |
| `pi_packages` | `pi list` (parse identifiers) | Sorted comma-separated list of package identifiers | Agent infra | R2 |
| `agent_config_head` | `git -C ~/.agent-config rev-parse --short HEAD` | Short SHA only (commit message varies) | Agent infra | R2 |
| `agent_config_branch` | `git -C ~/.agent-config branch --show-current` | Raw | Agent infra | R2 |
| `pm_version` | `grep '"version"' <pm_path>/package.json` | `sed 's/.*: "//;s/".*//'` | Agent infra | R2 |
| `pm_branch` | `cd <pm_path> && git branch --show-current` | Raw | Agent infra | R2 |
| `pm_source` | `pi list` install identifier for messenger | Raw (e.g., `npm:pi-messenger` vs `../../dev/pi-messenger-fork`) | Agent infra | R2 |
| `openclaw_version` | `openclaw --version` | Raw `head -1` (preserves beta suffixes) | Agent infra | R2 |
| `node_version` | `node --version` | Raw | Core tools | R2 |
| `claude_version` | `claude --version` | `grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'` | Core tools | R2 |
| `codex_version` | `codex --version` | `2>/dev/null \| grep -oE '[0-9]+\.[0-9]+\.[0-9]+'` | Core tools | R2 |
| `brew_required` | Brewfile ∩ `brew list --formula -1` | See Homebrew section | Homebrew | R2 |

### `pi_packages` — Verdicted Check (Codex R1+R2 Fix)

The spec requires checking `pi packages`. Packages differ between machines by design (laptop has pi-subagents, pi-design-deck; mini does not). The check compares the **sorted list of package install identifiers** as they appear in `pi list` output — these ARE the identifiers (e.g., `npm:pi-subagents`, `../../dev/pi-messenger-fork`). Since machines intentionally have different packages, the verdict is `DRIFT (expected)` with a human-readable note. It still counts as DRIFT in the summary but does NOT affect the exit code (exit 0 still possible with expected drifts).

Extraction (identifier lines — first line of each package entry, not the indented path line):
```bash
pi list 2>/dev/null | grep -E '^\s+(npm:|\.\./)' | sed 's/^\s*//' | sort | paste -sd, -
```

This extracts only the identifier lines (which start with `npm:` or `../`), NOT the indented path lines (which start with `/`). Local-path installs show as relative paths (`../../dev/pi-messenger-fork`), npm installs as `npm:name`.

### `pm_source` — Install Method Check (Codex R1+R2 Fix)

The spec requires `pi-messenger source`. This checks how pi-messenger is installed — the identifier line from `pi list` (e.g., `npm:pi-messenger` vs `../../dev/pi-messenger-fork`). The comparison uses **source classification**, not raw string comparison:

**Classification logic:**
```bash
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
```

**Comparison rule:**
- Same class → PASS (two local-path installs are both "fork installs" regardless of directory name)
- Different class → DRIFT (e.g., `npm:pi-messenger` vs `../../dev/pi-messenger-fork` — one machine runs stale npm)
- Either missing → MISSING

The raw source string is still shown in the output for context, but the verdict is based on class comparison.

Extraction:
```bash
pi list 2>/dev/null | grep "messenger" | grep -Ev '^\s+/' | head -1 | xargs
```

Note: `grep -Ev '^\s+/'` excludes indented path lines (which start with whitespace + `/`), keeping only the identifier line.

### pi-messenger Path Resolution

The `pi list` output is multiline. Extract the pi-messenger install path with:

```bash
pm_path=$(pi list 2>/dev/null | grep "messenger" | grep -E '^\s+/' | tail -1 | xargs)
```

**Guard against empty path (Codex R1 Fix):** If `pm_path` is empty or not a directory, set `pm_version=MISSING` and `pm_branch=MISSING` immediately — do NOT attempt file reads or git commands on an empty path:

```bash
if [[ -z "$pm_path" ]] || [[ ! -d "$pm_path" ]]; then
    LOCAL[pm_version]="MISSING"
    LOCAL[pm_branch]="MISSING"
    LOCAL[pm_source]="MISSING"
else
    LOCAL[pm_version]=$(grep '"version"' "$pm_path/package.json" 2>/dev/null | head -1 | sed 's/.*: "//;s/".*//' || echo "MISSING")
    LOCAL[pm_branch]=$(cd "$pm_path" && git branch --show-current 2>/dev/null || echo "MISSING")
fi
```

All path variables are always double-quoted. The `[[ -d "$pm_path" ]]` validation rejects empty/invalid paths before any filesystem access.

### Homebrew Check

Not a key=value comparison — it's a set operation:

1. Parse `~/.agent-config/Brewfile` for `brew "..."` entries
2. Normalize tap-qualified names: `${pkg##*/}` (e.g., `steipete/tap/peekaboo` → `peekaboo`)
3. Get `brew list --formula -1` from both machines
4. For each Brewfile package, check presence on each side
5. Report: per-package PASS (both), MISSING_LOCAL, MISSING_REMOTE, or MISSING_BOTH

### Version Extraction Strategy

Different tools need different extraction — no single regex works:

| Tool | Strategy | Why |
|------|----------|-----|
| pi, codex | `2>/dev/null \| grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \| head -1` | codex emits WARNING to stderr; semver only |
| claude | `2>/dev/null \| grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' \| head -1` | Strips "(Claude Code)" suffix |
| openclaw | `head -1` (raw) | Preserves `-beta.1` suffixes |
| node | Raw | Already clean (`v25.6.1`) |

### Command-Not-Found Detection

`set -euo pipefail` does NOT abort inside `$()` command substitutions. A missing tool produces `bash: codex: command not found` as the captured value. Detection:

```bash
is_missing() {
    local val="$1"
    [[ -z "$val" ]] && return 0
    [[ "$val" == *"command not found"* ]] && return 0
    [[ "$val" == *"not found"* ]] && return 0
    [[ "$val" == "MISSING" ]] && return 0
    return 1
}
```

Compare logic uses `is_missing` to distinguish MISSING from DRIFT, and reports WHICH side is missing.

## SSH Design

Single batched call with **end-to-end timeout** (Codex R1+R2 Fix):

**Timeout command resolution** — `timeout` is from GNU coreutils. On macOS it's available via Homebrew's coreutils (as `timeout` or `gtimeout`), but is NOT a POSIX built-in. The script resolves at startup:

```bash
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
```

**SSH call with timeout wrapper:**

```bash
SSH_OPTS="-o ConnectTimeout=5 -o BatchMode=yes"
ssh_cmd="ssh $SSH_OPTS mini-ts bash -s"
if [[ -n "$TIMEOUT_CMD" ]]; then
    ssh_cmd="$TIMEOUT_CMD 15 $ssh_cmd"
fi

remote_output=$($ssh_cmd << 'REMOTE'
# ... all remote checks, outputting key=value lines ...
REMOTE
) || {
    rc=$?
    if [[ $rc -eq 124 ]]; then
        # timeout(1) killed the SSH session — remote commands hung
        echo "ERROR: Remote commands exceeded 15s timeout" >&2
        exit 2
    elif [[ $rc -eq 255 ]]; then
        # SSH connection failure
        echo "ERROR: Cannot reach mini-ts (SSH timeout or connection refused)" >&2
        exit 2
    fi
}
```

`ConnectTimeout=5` handles the fast-fail case (host unreachable). The 15s outer timeout (when available) handles hung remote commands. Exit code 2 = connectivity/timeout failure.

**Performance target (R7):** The `<10s` spec requirement is a target, not a hard abort. Normal operation completes in 2-4s (single SSH round trip, ~12 parallel commands inside the heredoc). The 15s timeout is the safety net. Task T8.4 includes a performance validation step.

## JSON Output

**Prerequisite check (Codex R1 Fix):** When `--json` is requested, verify `jq` is available before doing any work:

```bash
if [[ "$OUTPUT_JSON" == true ]]; then
    if ! command -v jq &>/dev/null; then
        echo "ERROR: --json requires jq (install: brew install jq)" >&2
        exit 3
    fi
fi
```

Exit code 3 = missing dependency. Clear error message with install instructions.

**MUST use `jq -n --arg`** — never bash string interpolation:

```bash
jq -n --arg check "$key" --arg local "$local_val" \
      --arg remote "$remote_val" --arg verdict "$verdict" \
  '{check:$check, local:$local, remote:$remote, verdict:$verdict}'
```

Results accumulated in an array, final output via `jq -s '.'`.

## Human Output

Colored aligned table:

```
Machine Parity Check — laptop ↔ mini-ts
════════════════════════════════════════════════════════════
  ✓ pi_version          0.57.1                      PASS
  ✗ claude_version      2.1.69 ≠ 2.1.63            DRIFT
  ✗ openclaw_version    2026.3.9 ≠ 2026.3.2-beta.1 DRIFT
  ✓ node_version        v25.6.1                     PASS
  ~ pi_packages         3 pkgs ≠ 1 pkg             DRIFT (expected)
  ✓ pm_source           local-path ≈ local-path     PASS
  ✗ brew: peekaboo      installed ≠ missing         MISSING (remote)
────────────────────────────────────────────────────────────
  8/12 PASS · 2 DRIFT · 1 DRIFT (expected) · 1 MISSING
```

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All checks PASS or DRIFT (expected) — no unexpected drift |
| 1 | Any DRIFT or MISSING detected |
| 2 | SSH connectivity failure or timeout |
| 3 | Missing dependency (e.g., jq for --json) |

## Known Limitations

1. **openclaw pre-release suffixes**: Compared as raw strings (correct behavior — `2026.3.9` ≠ `2026.3.9-beta.1` shows DRIFT). Semantically equivalent but numerically different versions (hypothetical `2026.3.9` vs `2026.3.9-0`) would show false DRIFT. Acceptable for this use case.
2. **`pi list` output contract**: The `pi list` format is not a stable API. If pi changes its output format, the messenger path extraction may break. The `is_missing()` guard prevents crashes — it would report MISSING instead of a wrong value. The skill file documents this dependency.
3. **`pi_packages` intentional drift**: Packages differ between machines by design. The check is `DRIFT (expected)` — it shows what's installed, renders with `~` instead of `✗`, and does NOT affect the exit code (exit 0 still possible).

## Conventions Followed

- Script pattern: matches `setup.sh` style (colors, `log_ok`/`log_warn`/`log_err`/`log_info`, `set -euo pipefail`)
- Location: `scripts/` directory alongside existing scripts
- Skill wraps script: `skills/machine-parity/SKILL.md` tells agents when/how to run it, and clarifies the boundary with `agent-config-parity`
- Syncs to mini automatically via dual-push (agent-config already has this)

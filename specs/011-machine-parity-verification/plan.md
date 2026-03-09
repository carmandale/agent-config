---
title: "Machine Parity Verification — Implementation Plan"
date: 2026-03-09
bead: .agent-config-8i7
---

# 011: Machine Parity Verification — Plan

## Selected Shape

**Shape B: Parallel SSH with Structured Output** (from shaping-transcript.md)

Single bash script. Gathers all local values, batches all remote checks into one SSH call, compares, outputs human table (default) or JSON (`--json`).

## Architecture

```
parity-check.sh
├── parse_args()           # --json flag, --help
├── gather_local()         # LOCAL associative array
├── gather_remote()        # Single ssh mini-ts bash -s heredoc → REMOTE array
├── is_missing()           # Detect "command not found" / empty / MISSING
├── compare_all()          # Iterate keys, assign PASS/DRIFT/MISSING
├── check_brew()           # Brewfile-based set comparison (separate from k/v checks)
├── output_human()         # Colored table
├── output_json()          # jq -n --arg (NEVER string interpolation)
└── summary + exit code    # 0=pass, 1=drift, 2=ssh-failure
```

## File Locations

| Artifact | Path |
|----------|------|
| Script | `~/.agent-config/scripts/parity-check.sh` |
| Skill | `~/.agent-config/skills/machine-parity/SKILL.md` |

## Check List

| Key | Command (both sides) | Normalization | Category |
|-----|---------------------|---------------|----------|
| `pi_version` | `pi --version` | `grep -oE '[0-9]+\.[0-9]+\.[0-9]+'` | Agent infra |
| `pi_packages` | `pi list` (parse names) | Extract package identifiers | Agent infra |
| `agent_config_head` | `git -C ~/.agent-config log --oneline -1` | Raw (includes short SHA + message) | Agent infra |
| `agent_config_branch` | `git -C ~/.agent-config branch --show-current` | Raw | Agent infra |
| `pm_version` | `grep '"version"' <pm_path>/package.json` | `sed 's/.*: "//;s/".*//'` | Agent infra |
| `pm_branch` | `cd <pm_path> && git branch --show-current` | Raw | Agent infra |
| `openclaw_version` | `openclaw --version` | Raw `head -1` (preserves beta suffixes) | Agent infra |
| `node_version` | `node --version` | Raw | Core tools |
| `claude_version` | `claude --version` | `grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?'` | Core tools |
| `codex_version` | `codex --version` | `2>/dev/null \| grep -oE '[0-9]+\.[0-9]+\.[0-9]+'` | Core tools |
| `brew_required` | Brewfile ∩ `brew list --formula -1` | See Homebrew section | Homebrew |

### pi-messenger Path Resolution

The `pi list` output is multiline. Extract the pi-messenger install path with:

```bash
pm_path=$(pi list 2>/dev/null | grep "messenger" | grep -E '^\s+/' | tail -1 | xargs)
```

This hardened form:
- Filters to indented path-only lines (skips package identifiers)
- Handles spaces in paths (laptop: `Groove Jones Dropbox/...`)
- Handles different directory names (mini: `pi-messenger-fork`)
- Is safe if multiple messenger-like packages exist (takes last path match)

### Homebrew Check

Not a key=value comparison — it's a set operation:

1. Parse `~/.agent-config/Brewfile` for `brew "..."` entries
2. Normalize tap-qualified names: `${pkg##*/}` (e.g., `steipete/tap/peekaboo` → `peekaboo`)
3. Get `brew list --formula -1` from both machines
4. For each Brewfile package, check presence on each side
5. Report: per-package PASS (both), MISSING_LOCAL, MISSING_REMOTE, or MISSING_BOTH

### Version Extraction Strategy (Bug Fix from Review)

Different tools need different extraction — no single regex works:

| Tool | Strategy | Why |
|------|----------|-----|
| pi, codex | `2>/dev/null \| grep -oE '[0-9]+\.[0-9]+\.[0-9]+' \| head -1` | codex emits WARNING to stderr; semver only |
| claude | `2>/dev/null \| grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' \| head -1` | Strips "(Claude Code)" suffix |
| openclaw | `head -1` (raw) | Preserves `-beta.1` suffixes |
| node | Raw | Already clean (`v25.6.1`) |

### Command-Not-Found Detection (Bug Fix from Review)

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

Single batched call with timeout:

```bash
SSH_OPTS="-o ConnectTimeout=5 -o BatchMode=yes"
remote_output=$(ssh $SSH_OPTS mini-ts 'bash -s' << 'REMOTE'
# ... all remote checks, outputting key=value lines ...
REMOTE
) || {
    rc=$?
    if [[ $rc -eq 255 ]]; then
        # SSH connection failure — special handling
        echo "ERROR: Cannot reach mini-ts" >&2
        exit 2
    fi
}
```

Exit codes: 0 = all pass, 1 = any drift/missing, 2 = SSH connectivity failure.

## JSON Output (Bug Fix from Review)

**MUST use `jq -n --arg`** — never bash string interpolation. jq is in the Brewfile (installed on both machines).

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
  ✗ brew: peekaboo      installed ≠ missing         MISSING (remote)
────────────────────────────────────────────────────────────
  8/11 PASS · 2 DRIFT · 1 MISSING
```

## Known Limitations

1. **openclaw pre-release suffixes**: `2026.3.9` and `2026.3.9-beta.1` are compared as raw strings, so they correctly show DRIFT. But `2026.3.9` and `2026.3.9-0` (hypothetical) would show DRIFT when semantically equivalent. Acceptable for this use case.
2. **pi_packages comparison**: Packages differ between machines by design (laptop has pi-subagents, pi-design-deck). We compare pi-messenger specifically; the full package list is shown for informational context only, not as PASS/DRIFT.

## Conventions Followed

- Script pattern: matches `setup.sh` style (colors, `log_ok`/`log_warn`/`log_err`/`log_info`, `set -euo pipefail`)
- Location: `scripts/` directory alongside existing scripts
- Skill wraps script: `skills/machine-parity/SKILL.md` tells agents when/how to run it
- Syncs to mini automatically via dual-push (agent-config already has this)

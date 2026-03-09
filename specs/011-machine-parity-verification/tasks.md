---
title: "Machine Parity Verification — Tasks"
date: 2026-03-09
bead: .agent-config-8i7
---

# 011: Machine Parity Verification — Tasks

## T1: Script Skeleton
- [ ] **T1.1**: Create `scripts/parity-check.sh` with shebang, `set -euo pipefail`, color/log functions matching `setup.sh` pattern
- [ ] **T1.2**: Add `--json` and `--help` flag parsing
- [ ] **T1.3**: Add SSH connectivity check with `ConnectTimeout=5`, `BatchMode=yes`, exit code 2 on failure
- [ ] **T1.4**: Add `is_missing()` helper detecting empty, "command not found", "not found", and "MISSING" values
- [ ] **T1.5**: `chmod +x`, verify it runs and prints help

## T2: Local Gather
- [ ] **T2.1**: `declare -A LOCAL` — gather pi_version, node_version, claude_version, codex_version, openclaw_version using per-tool extraction strategies (see plan: version extraction strategy table)
- [ ] **T2.2**: Gather agent_config_head and agent_config_branch via `git -C ~/.agent-config`
- [ ] **T2.3**: Gather pm_version and pm_branch using hardened path resolution: `pi list | grep "messenger" | grep -E '^\s+/' | tail -1 | xargs`, then read package.json and git branch from that path
- [ ] **T2.4**: Verify all LOCAL values are populated (test with `declare -p LOCAL`)

## T3: Remote Gather
- [ ] **T3.1**: Build single `ssh $SSH_OPTS mini-ts 'bash -s' << 'REMOTE'` heredoc that outputs `key=value` lines for all checks (same extraction commands as T2)
- [ ] **T3.2**: Parse heredoc output into `declare -A REMOTE` — split on first `=` only (values may contain `=`)
- [ ] **T3.3**: Handle SSH failure (exit 255) → print error, exit 2
- [ ] **T3.4**: Test: run the heredoc standalone, verify all key=value lines are clean

## T4: Compare Logic
- [ ] **T4.1**: Iterate ordered key list; for each: check `is_missing` on both sides, then string compare
- [ ] **T4.2**: Verdicts: PASS (equal), DRIFT (both present, differ), MISSING_LOCAL, MISSING_REMOTE
- [ ] **T4.3**: Store results in array of `(key, local_val, remote_val, verdict)` tuples
- [ ] **T4.4**: Track counters: pass_count, drift_count, missing_count

## T5: Homebrew Check
- [ ] **T5.1**: Parse `Brewfile` for `brew "..."` entries, normalize tap-qualified names with `${pkg##*/}`
- [ ] **T5.2**: Get `brew list --formula -1` from both sides (local direct, remote in the SSH heredoc from T3)
- [ ] **T5.3**: For each Brewfile package: check presence in both lists, assign PASS/MISSING_LOCAL/MISSING_REMOTE
- [ ] **T5.4**: Append Homebrew results to the main results array (same tuple format)

## T6: Human Output
- [ ] **T6.1**: Print header: "Machine Parity Check — laptop ↔ mini-ts"
- [ ] **T6.2**: For each result: colored line — green ✓ PASS (show value once), yellow ✗ DRIFT (show both), red ✗ MISSING (show which side)
- [ ] **T6.3**: Print summary line: "X/Y PASS · Z DRIFT · W MISSING"
- [ ] **T6.4**: Test: run script, verify output is aligned and readable

## T7: JSON Output
- [ ] **T7.1**: When `--json` flag set, accumulate each result as `jq -n --arg check ... --arg local ... --arg remote ... --arg verdict ...` (NEVER string interpolation)
- [ ] **T7.2**: Final output: `jq -s '.'` to produce JSON array
- [ ] **T7.3**: Test: `./parity-check.sh --json | jq .` — must be valid JSON, test with a DRIFT case and a MISSING case

## T8: Exit Codes + Edge Cases
- [ ] **T8.1**: Exit 0 if all PASS, exit 1 if any DRIFT or MISSING, exit 2 if SSH failure
- [ ] **T8.2**: Test: verify exit code reflects actual state (both in normal and --json mode)
- [ ] **T8.3**: Test: disconnect mini from network, verify exit 2 + clear error message

## T9: Skill Wrapper
- [ ] **T9.1**: Create `skills/machine-parity/SKILL.md` with: name, description, when to use, how to run (`~/.agent-config/scripts/parity-check.sh` or `parity-check.sh --json`), what the output means
- [ ] **T9.2**: Include interpretation guidance: what DRIFT means for each check category, suggested fixes

## T10: Integration
- [ ] **T10.1**: `git add scripts/parity-check.sh skills/machine-parity/SKILL.md`
- [ ] **T10.2**: Commit and push (dual-push syncs script to mini automatically)
- [ ] **T10.3**: Verify on mini: `ssh mini-ts "~/.agent-config/scripts/parity-check.sh"` runs and produces output
- [ ] **T10.4**: Run `parity-check.sh --json | jq .` on mini — verify valid JSON

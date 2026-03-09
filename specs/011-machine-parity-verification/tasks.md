<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-09 -->
<!-- Status: RECONCILED — aligned to revised plan (timeout resolution, classify_pm_source, DRIFT expected) -->
---
title: "Machine Parity Verification — Tasks"
date: 2026-03-09
bead: .agent-config-8i7
---

# 011: Machine Parity Verification — Tasks

## T1: Script Skeleton
- [ ] **T1.1**: Create `scripts/parity-check.sh` with shebang, `set -euo pipefail`, color/log functions matching `setup.sh` pattern
- [ ] **T1.2**: Add `--json` and `--help` flag parsing
- [ ] **T1.3**: Add `check_deps()` — when `--json` requested, verify `jq` is available; if missing, print `"ERROR: --json requires jq (install: brew install jq)"` and exit 3
- [ ] **T1.4**: Add `resolve_timeout_cmd()` — check for `timeout`, fall back to `gtimeout`, warn if neither available (no hard dependency — degrades gracefully)
- [ ] **T1.5**: Add SSH connectivity pre-check with `ConnectTimeout=5`, `BatchMode=yes`, end-to-end `$TIMEOUT_CMD 15` wrapper, exit code 2 on failure (124=timeout, 255=SSH)
- [ ] **T1.6**: Add `is_missing()` helper detecting empty, "command not found", "not found", and "MISSING" values
- [ ] **T1.7**: Add `classify_pm_source()` — classifies pm_source identifier into `npm`/`local-path`/`missing`/`unknown`
- [ ] **T1.8**: `chmod +x`, verify it runs and prints help

## T2: Local Gather
- [ ] **T2.1**: `declare -A LOCAL` — gather pi_version, node_version, claude_version, codex_version, openclaw_version using per-tool extraction strategies (see plan: version extraction strategy table)
- [ ] **T2.2**: Gather agent_config_head (`git rev-parse --short HEAD`) and agent_config_branch via `git -C ~/.agent-config`
- [ ] **T2.3**: Gather pm_version, pm_branch, and pm_source using hardened path resolution: `pi list | grep "messenger" | grep -E '^\s+/' | tail -1 | xargs`; **guard empty pm_path**: if empty or not a directory, set all three to `MISSING` immediately — do NOT attempt file reads or git commands
- [ ] **T2.4**: Gather pi_packages: `pi list | grep -E '^\s+(npm:|\.\./)' | sed 's/^\s*//' | sort | paste -sd, -` (identifier lines only — `npm:` or `../` prefixed, NOT indented path lines)
- [ ] **T2.5**: Gather pm_source: `pi list | grep "messenger" | grep -Ev '^\s+/' | head -1 | xargs` (the install identifier, not the path). Classify via `classify_pm_source()`: `npm:*` → "npm", `../*` or `/*` → "local-path", empty → "missing" (the install identifier, not the path)
- [ ] **T2.6**: All path variables must be double-quoted; validate with `[[ -d "$pm_path" ]]` before any filesystem access
- [ ] **T2.7**: Verify all LOCAL values are populated (test with `declare -p LOCAL`)

## T3: Remote Gather
- [ ] **T3.1**: Build single `timeout 15 ssh $SSH_OPTS mini-ts 'bash -s' << 'REMOTE'` heredoc that outputs `key=value` lines for all checks (same extraction commands as T2, including pm_path guard and pi_packages/pm_source)
- [ ] **T3.2**: Parse heredoc output into `declare -A REMOTE` — split on first `=` only (values may contain `=`)
- [ ] **T3.3**: Handle exit codes: 124 (timeout killed SSH — remote commands hung) → exit 2 with timeout message; 255 (SSH connection failure) → exit 2 with connectivity message
- [ ] **T3.4**: Test: run the heredoc standalone, verify all key=value lines are clean

## T4: Compare Logic
- [ ] **T4.1**: Iterate ordered key list; for each: check `is_missing` on both sides, then string compare
- [ ] **T4.2**: Verdicts: PASS (equal), DRIFT (both present, differ), MISSING_LOCAL, MISSING_REMOTE
- [ ] **T4.3**: Special handling for pi_packages: verdict is `DRIFT (expected)` — packages intentionally differ between machines; does NOT affect exit code; renders with `~` symbol in human output
- [ ] **T4.4**: Special handling for pm_source: use `classify_pm_source()` to classify as `npm`/`local-path`/`missing`/`unknown`. Compare class, not raw string — two different local paths are both "local-path" → PASS
- [ ] **T4.5**: Store results in array of `(key, local_val, remote_val, verdict)` tuples
- [ ] **T4.6**: Track counters: pass_count, drift_count, expected_drift_count, missing_count

## T5: Homebrew Check
- [ ] **T5.1**: Parse `Brewfile` for `brew "..."` entries, normalize tap-qualified names with `${pkg##*/}`
- [ ] **T5.2**: Get `brew list --formula -1` from both sides (local direct, remote in the SSH heredoc from T3)
- [ ] **T5.3**: For each Brewfile package: check presence in both lists, assign PASS/MISSING_LOCAL/MISSING_REMOTE
- [ ] **T5.4**: Append Homebrew results to the main results array (same tuple format)

## T6: Human Output
- [ ] **T6.1**: Print header: "Machine Parity Check — laptop ↔ mini-ts"
- [ ] **T6.2**: For each result: colored line — green ✓ PASS (show value once), yellow ✗ DRIFT (show both), red ✗ MISSING (show which side), dim ~ DRIFT (expected) (show both, no alarm)
- [ ] **T6.3**: Print summary line: "X/Y PASS · Z DRIFT · N DRIFT (expected) · W MISSING"
- [ ] **T6.4**: Test: run script, verify output is aligned and readable

## T7: JSON Output
- [ ] **T7.1**: When `--json` flag set (and jq verified in T1.3), accumulate each result as `jq -n --arg check ... --arg local ... --arg remote ... --arg verdict ...` (NEVER string interpolation)
- [ ] **T7.2**: Final output: `jq -s '.'` to produce JSON array
- [ ] **T7.3**: Test: `./parity-check.sh --json | jq .` — must be valid JSON, test with a DRIFT case and a MISSING case

## T8: Exit Codes + Edge Cases
- [ ] **T8.1**: Exit 0 if all PASS or DRIFT (expected), exit 1 if any unexpected DRIFT or MISSING, exit 2 if SSH failure/timeout, exit 3 if missing dependency
- [ ] **T8.2**: Test: verify exit code reflects actual state (both in normal and --json mode)
- [ ] **T8.3**: Test: disconnect mini from network, verify exit 2 + clear error message within 5s
- [ ] **T8.4**: Performance validation: time the script 3 runs, verify all complete under 10s. If any exceeds, investigate which remote command is slow.

## T9: Skill Wrapper
- [ ] **T9.1**: Create `skills/machine-parity/SKILL.md` with: name, description, when to use, how to run (`~/.agent-config/scripts/parity-check.sh` or `parity-check.sh --json`), what the output means
- [ ] **T9.2**: Include interpretation guidance: what DRIFT means for each check category, suggested fixes
- [ ] **T9.3**: Document boundary with `agent-config-parity`: "Use `parity-check.sh` for quick version/state sync checks. Use `agent-config-parity` for deep config-surface auditing (symlinks, paths, managed surfaces)."

## T10: Integration
- [ ] **T10.1**: `git add scripts/parity-check.sh skills/machine-parity/SKILL.md`
- [ ] **T10.2**: Commit and push (dual-push syncs script to mini automatically)
- [ ] **T10.3**: Verify on mini: `ssh mini-ts "~/.agent-config/scripts/parity-check.sh"` runs and produces output
- [ ] **T10.4**: Run `parity-check.sh --json | jq .` on mini — verify valid JSON

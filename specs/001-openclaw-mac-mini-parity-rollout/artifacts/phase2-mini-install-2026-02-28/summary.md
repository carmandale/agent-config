# Phase 2/3 Mini Install + Verification Summary

Date: 2026-02-28  
Bead: `.agent-config-k2j`  
Spec: `specs/001-openclaw-mac-mini-parity-rollout/spec.md`

## Remote Execution

- Host: `mini-ts` (`Chips-Mac-mini.local`)
- Repo created on mini: `~/.agent-config` (fresh clone)
- Repo state used: `main` at `9c9ee3dd498ae0048e82c92ef80ab487da0837bb`

## Install Results

1. `install.sh` completed successfully.
2. `install-all.sh` completed with partial plugin step:
   - `bunx not found`
   - compound-engineering install skipped in Step 2.
3. Backup captured during install:
   - `/Users/chipcarman/.codex/skills.backup.20260228-052912`

## Verification Artifacts

- `mini_repo_sync.log`
- `install.sh.log`
- `install-all.sh.log`
- `mini.snapshot`
- `mini.report.txt`
- `mini_smoke_checks.txt`
- `compare_vs_phase1.txt`
- `compare_vs_laptop_current.txt`

## Managed Surface Outcome

From `mini.snapshot`, all managed `install.sh` surfaces are `status=ok`:

- `pi_commands`, `pi_instructions`, `pi_skills`
- `claude_commands`, `claude_instructions`, `claude_skills`
- `codex_prompts`, `codex_instructions`, `codex_skills`
- `opencode_commands`
- `agent_skills`

Smoke checks confirmed command/instruction/skill visibility for Pi, Claude, Codex, and OpenCode command path.

## Delta Classification

### Canonical Direction (User Guidance)

Use repo-defined installer outcomes as canonical and treat laptop inconsistencies as cleanup targets, not as ground truth to replicate.

### Expected / Accepted

1. Managed status improved versus laptop Phase 1 baseline:
   - `claude_instructions`: `drift_target` -> `ok`
   - `pi_commands`: `missing` -> `ok`
2. Repo cleanliness differs:
   - mini `repo.dirty_entries=0`
   - laptop baseline had dirty entries from in-progress local work.

### Non-Blocking Drift

1. External machine-local surfaces differ (config/plugin directories absent on mini):
   - `~/.codex/config.json` missing
   - `~/.factory/{commands,droids}` missing
   - `~/.config/opencode/config.json` missing
   - `~/.pi/agent/compound-engineering` missing

### Blocking for “same tools/setup” parity goal

1. Toolchain gaps on mini:
   - `bun`/`bunx` missing (blocked compound-plugin install step)
   - `bd` missing
   - `rg` missing
2. Tool versions differ:
   - `git`, `bash`, `node` do not match laptop baseline versions

## Recommended Next Move (Phase 4)

1. Decide whether strict parity requires matching laptop’s local config/plugin directories or only managed symlink surfaces.
2. Install missing toolchain components on mini (`bun`, `bd`, `rg`) and rerun `install-all.sh`.
3. Re-run mini snapshot + compare to drive blocking deltas to zero.

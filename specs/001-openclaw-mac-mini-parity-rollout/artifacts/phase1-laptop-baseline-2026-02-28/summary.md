# Phase 1 Laptop Baseline Summary

Date: 2026-02-28  
Bead: `.agent-config-k2j`  
Spec: `specs/001-openclaw-mac-mini-parity-rollout/spec.md`

## Baseline Repo State

- Branch: `main`
- SHA: `8e642a1fb111361a14c2214a34f55fae29504fe5`
- Origin: `https://github.com/carmandale/agent-config.git`

## Evidence Files

- `repo_sha.txt`
- `laptop.snapshot`
- `laptop.report.txt`

## Managed Surface Status (from `laptop.snapshot`)

- `ok`: agent_skills, claude_commands, claude_skills, codex_instructions, codex_prompts, codex_skills, opencode_commands, pi_instructions, pi_skills
- `drift_target`: claude_instructions
- `missing`: pi_commands

## Outside-of-Repo Surfaces Observed

- Present files/dirs:
  - `~/.claude/settings.json`
  - `~/.codex/config.json`
  - `~/.codex/config.toml`
  - `~/.config/opencode/config.json`
  - `~/.pi/agent/compound-engineering`
  - `~/.factory/commands`
  - `~/.factory/droids`
- Missing paths:
  - `~/.pi/agent/config.json`
  - `~/.config/opencode/config.toml`
  - `~/.config/opencode/compound-engineering`

## Tool Versions Captured

- `git`: `2.50.1`
- `bash`: `5.2.37`
- `bun`: `1.3.5`
- `bunx`: `1.3.5`
- `node`: `v24.1.0`
- `bd`: `0.50.3`
- `rg`: `15.1.0`

## Notes for Phase 2/3

1. Keep repo SHA aligned on Mac mini before install.
2. Validate whether `claude_instructions` drift and missing `pi_commands` are intentional parity targets or should be normalized during rollout.

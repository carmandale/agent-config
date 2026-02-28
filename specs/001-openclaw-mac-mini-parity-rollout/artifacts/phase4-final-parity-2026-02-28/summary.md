# Phase 4 Final Summary (2026-02-28)

## Scope
- Canonical parity script aligned across machines at repo SHA `69d12dc63a4de93add516b98604a09f35a1b368e`.
- Laptop + mini toolchains upgraded/aligned for `git`, `bash`, `node`, `bun`, and `rg`.
- Mini non-interactive/login shell PATH corrected via `~/.zprofile` so Homebrew tools resolve first.
- Fresh parity snapshots/reports/smoke checks captured in this artifact directory.

## Done
- Managed surfaces (`managed.*.status`) are `ok` on both machines.
- Command/instruction/skill symlink targets resolve to `~/.agent-config` on both machines.
- `git/node/bun/rg/bd` versions are aligned.
- `tools-bin/agent-config-parity` now emits normalized home paths and records resolved tool bins.
- `agent-config-parity compare` now ignores ephemeral `repo.dirty_entries` in addition to snapshot timestamp/host/user keys.

## Remaining Differences (Classified)
1. `external.codex_config_json` present on laptop, missing on mini.
   - Classification: expected machine-local config drift.
   - Decision: do not auto-copy; review explicitly in follow-up bootstrap bead.
2. `external.opencode_config_json` present on laptop, missing on mini.
   - Classification: expected machine-local config drift.
   - Decision: do not auto-copy; review explicitly in follow-up bootstrap bead.
3. `external.pi_compound_engineering` present on laptop, missing on mini.
   - Classification: likely legacy laptop artifact (non-canonical for symlink-first Pi setup).
   - Decision: treat as cleanup target in follow-up bead.
4. `system.macos.version` and `system.macos.build` differ.
   - Classification: expected hardware/OS baseline difference.
   - Decision: non-blocking for config parity.
5. `tool.bash.version` platform tuple differs though release is aligned (`5.3.9`).
   - Classification: expected OS-build suffix difference.
   - Decision: non-blocking for functional parity.

## Follow-up
- Created bead: `.agent-config-gyi`  
  Title: "Automate external config bootstrap for cross-machine parity"
- Purpose: define deterministic handling for external parity surfaces so new-machine installs do not inherit accidental laptop drift.

## Blockers
- None for functional parity rollout.

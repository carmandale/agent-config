<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: REVISED -->
<!-- Revisions: A2 detection mechanism updated from .bd-backup file check to br doctor (backup file is gitignored, won't exist cross-machine). Manifest-driven targeting added. -->
---
title: "Fleet-wide br migration: bd→br across 39 repos + hooks + governance"
date: 2026-03-10
bead: .agent-config-2gy
type: feature
status: in_progress
---

# Fleet-wide br migration: bd→br across 39 repos + hooks + governance

## Context

Spec 010 evaluated beads backends and migrated agent-config from `bd` (v0.50.3, Go/SQLite) to `br` (v0.1.24, beads_rust/SQLite). That migration covered one repo on two machines. The remaining ~38 repos still run on `bd`, and a live bug in Claude Code hooks (`bd prime`) injects stale `bd` commands into every session — contradicting AGENTS.md §6 which already says `br`.

DarkTiger confirmed `bd` is completely bricked in GMP (groovetech-media-player): the `agent_fields` migration crashes on DB open with a truncated column type error (`near "EGER"` — tail of `INTEGER`). Fleet investigation revealed 10 additional repos with schema-drift errors (missing columns), 5 repos nagging about Dolt migration, and 14 repos where `bd` still works. All 39 repos have intact JSONL. Upstream `bd` dropped SQLite in v0.59.0 (Dolt-only) and has active bugs: #2430 (journal corruption), #2488 (export crash), #2489 (broken atomic commits).

## Problem Statement

1. **Live bug**: `bd prime` in `configs/claude/settings.json` (lines 87, 249) injects `bd sync`, `bd ready`, `bd close` instructions into every Claude Code session — directly contradicting AGENTS.md §6. This is actively causing agent confusion today.
2. **Bricked repo**: GMP cannot use `bd` at all — migration crash on every command.
3. **Dead-end tool**: `bd` v0.50.3 has no future — upstream abandoned SQLite, and the Dolt path has known data-loss bugs.
4. **Incomplete migration**: Spec 010 migrated agent-config but left 38 repos, hooks, parity tooling, and version governance unaddressed.

## Selected Shape: A — Full br fleet migration (flag-day)

Shaped by WildFalcon (proposer) + QuickPhoenix (challenger) over 4 challenge rounds. See `shaping-transcript.md` for full context.

### Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | All repos can create/read/update/close beads reliably with a single tool | Core goal |
| R1 | JSONL remains source of truth — no data loss during migration | Must-have |
| R2 | Works on both machines (laptop + Mac mini) with version parity | Must-have |
| R3 | Migration is safe — can recover if something goes wrong per-repo | Must-have |
| R4 | Claude Code hooks inject correct (br) workflow context, not stale bd commands | Must-have |
| R5 | Doc/skill/command surface updated consistently — no stale bd references in live paths | Must-have |
| R6 | br version governance — upgrade gated, version pinned, drift detectable across machines | Must-have |
| R7 | Bricked repo (GMP) recovered with dual-prefix handling | Must-have |
| R8 | Schema-drift repos (10) pre-flushed and migrated without data loss | Must-have |
| R9 | Migration script is automated, tested, and handles already-migrated repos | Must-have |

### Shape Parts

| Part | Mechanism |
|------|-----------|
| **A1** | Pre-flush: `bd sync --flush-only` in all 24 non-bricked repos to ensure JSONL is current |
| **A2** | Migration script (`scripts/migrate-to-br.sh`): per-repo `br init --prefix $(basename $PWD) --force` + `br sync --import-only --rename-prefix`. Detects already-migrated repos via `br doctor` pass (originally `.beads/beads.db.bd-backup`, changed during planning because backup file is gitignored and won't exist cross-machine). Fails visibly on errors. Manifest-driven (not recursive discovery) for deterministic targeting. |
| **A3** | GMP special case: `br init --prefix "groovetech-media-player" --force` + `br sync --import-only --rename-prefix` (handles dual `groovetech`/`groovetech-media-player` prefixes) |
| **A4** | Hook replacement: `configs/claude/hooks/br-prime.sh` — tracked script outputting br-compatible workflow context. Prominent `br sync ≠ bd sync` warning at top. `settings.json` lines 87+249 updated to call it. Deployed by bootstrap.sh rsync. |
| **A5** | AGENTS_v1.md deletion: remove `instructions/AGENTS_v1.md` (28 stale `bd` references, superseded by current AGENTS.md) |
| **A6** | Parity tool update: add `br` to `tools-bin/agent-config-parity` record_tool list. Keep `bd` during 30-day fallback window, then remove. |
| **A7** | Version governance: `configs/br-version.txt` with pinned version. AGENTS.md §6: "Never run `br upgrade` without `--version`. Both machines must be updated together." |
| **A8** | Two-machine sequence: laptop migrates first, git push JSONL changes, mini pulls + runs same script. |
| **A9** | bd disposition: keep binary for 30-day fallback (matches spec 010 precedent), then remove. |

## Acceptance Criteria

1. `br ready` and `br list` work in all 39 repos on both machines
2. `bd prime` no longer appears in `configs/claude/settings.json` or live `~/.claude/settings.json`
3. `br-prime.sh` produces correct br-compatible context and is deployed to both machines
4. GMP issues (148) are accessible via `br list --all` with correct `groovetech-media-player-*` prefixes
5. `instructions/AGENTS_v1.md` does not exist
6. `tools-bin/agent-config-parity` tracks `br` version
7. `configs/br-version.txt` exists with `0.1.24`
8. AGENTS.md §6 includes `br upgrade` prohibition
9. Migration script exists at `scripts/migrate-to-br.sh`, is tested, handles edge cases
10. No `bd` command references remain in live instruction/hook paths (verified by grep)

## Scope

### In scope
- Migration script for all 39 repos
- Hook replacement (`bd prime` → `br-prime.sh`)
- `AGENTS_v1.md` deletion
- Parity tool update
- Version governance artifacts
- AGENTS.md §6 update
- Laptop + mini migration execution
- GMP dual-prefix recovery

### Out of scope
- br upstream bug fixes (display cap in `br list --all` — issue #168)
- Recreating GMP orphaned bead `42q` (finalize artifact is the real closure per DarkTiger)
- Migrating away from beads entirely
- Changes to the JSONL format or `.beads/` directory structure

## Risks

1. **GMP dual-prefix rename**: `--rename-prefix` is untested on this specific JSONL. Test in throwaway copy first.
2. **Bootstrap.sh side effects on mini**: Prior napkin incident — hooks missing on mini after bootstrap re-run. Bootstrap now has hook-file verification (lines 164-191) but caution warranted.
3. **br single-maintainer risk**: Entire fleet depends on Jeffrey Emanuel. Mitigated by version pinning + binary snapshot, but not eliminated.
4. **Schema-drift repos potential JSONL staleness**: `bd sync --flush-only` should capture current state, but if any issues were created after the drift but before flush, they may only exist in SQLite. Verify counts post-migration.

## Prior Art

- **Spec 010**: Single-repo migration (agent-config). Established the `br init --prefix` + backup pattern. Documented gotchas in napkin.
- **DarkTiger GMP investigation**: Confirmed corruption mechanism, `br` resilience, `--rename-prefix` path.
- **Shaping transcript**: 4 rounds of challenge. See `shaping-transcript.md`.

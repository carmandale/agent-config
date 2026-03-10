<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: REVISED -->
<!-- Revisions: R1: hard-fail on flush failure, ID-set integrity check, manifest-driven, version preflight, spec drift documented. R2: fixed jq format mismatch, empty repos get br init, fleet count table, R3 path fix, R5 scope expanded. -->
---
title: "Plan: Fleet-wide br migration"
date: 2026-03-10
bead: .agent-config-2gy
---

# Plan: Fleet-wide br migration

## Overview

Migrate all beads-using repos from `bd` (v0.50.3) to `br` (v0.1.24) across laptop (39 repos) and Mac mini (3 repos, 1 already done). Fix live `bd prime` hook poisoning. Add version governance and parity tracking.

**Critical ordering constraint**: Hooks must NOT switch to br until all repos are migrated. Deploying br-prime.sh before migration creates a poison window where agents get br commands that fail on bd-schema databases (`DATABASE_ERROR: no such column: blocked_at`). Phase order: Build → Execute → Deploy → Cleanup.

## Architecture Decisions

### Migration script design (`scripts/migrate-to-br.sh`)

**Repo discovery**: Two modes. (1) **Manifest mode** (default): the script reads a `fleet-manifest.txt` file listing explicit repo paths, one per line, with status annotations. This is deterministic and auditable. The manifest is generated once before migration by scanning for `.beads/` directories plus manual verification. (2) **Discovery mode** (`--discover`): scans for directories containing `.beads/` under a configurable root for initial manifest generation. Discovery is never used for the actual migration — only manifest mode runs the migration.

**Fleet manifest** (`specs/013-br-fleet-migration/fleet-manifest.txt`): Generated before Phase 2, committed to the spec directory. Contains every repo path + pre-migration status (working/schema-drift/dolt-nag/bricked/empty/no-jsonl/already-migrated). This is the single source of truth for fleet state, resolving the inconsistency between spec and plan counts.

<!-- REVISED during implementation: actual fleet classification differs from planning assumptions.
16 repos already work with br (including GMP which was previously bricked but has since been migrated).
Detection uses br list DATABASE_ERROR check, not the original bd-based categories. -->

**Laptop fleet** (40 repos total, verified 2026-03-10):

| Category | Count | Migration action |
|----------|-------|-----------------|
| Already-migrated (agent-config) | 1 | Skip (manifest annotation) |
| br-works (br list succeeds) | 16 | Skip (verified at runtime, includes GMP and former empty/no-JSONL repos) |
| Needs-migration (br list → DATABASE_ERROR) | 23 | Full procedure: flush → backup → init → import → verify |
| **Total** | **40** | |

**Mini fleet** (3 repos total): agent-config (skip, already done), openclaw (9 issues, full procedure), chip-voice (2 issues, full procedure).

**Already-migrated detection**: <!-- REVISED during implementation: br doctor gives unreliable results (exit 0 on bd-schema, exit 1 on br-schema). Detection uses br list instead. --> Run `br list` — if it succeeds without `DATABASE_ERROR`, the repo is already br-compatible and is skipped. If `br list` returns `DATABASE_ERROR: no such column: blocked_at`, the DB is bd-schema and needs migration. This replaced the originally-planned `br doctor` check which proved unreliable during implementation testing.

**GMP special case**: Hardcoded by repo name (`groovetech-media-player`), not error-pattern detection. `bd list` in GMP returns a misleading "out of sync" warning instead of the migration crash, which means dynamic classification fails. A3 path (`--rename-prefix`) is unconditional for GMP to resolve dual `groovetech`/`groovetech-media-player` prefixes.

**Script preflight**: Before any per-repo work, the script reads `configs/br-version.txt` and compares against `br --version`. If they differ, the script hard-fails with an error: "br version mismatch — expected X.Y.Z, got A.B.C. Update br or configs/br-version.txt before proceeding." This enforces R6 governance at the point of execution, not just documentation.

**Per-repo procedure** (from spec 010 precedent):
1. Detect: `br doctor` passes → skip entire repo (already migrated)
2. Pre-flush: `bd sync --flush-only`. **If this fails AND `.beads/beads.db` exists with data (file size > 0)**, the script **hard-fails for that repo** with a prominent error and adds it to the "FAILED" list. The operator must investigate before that repo can proceed. The only exception is GMP (hardcoded special case), which is known-bricked — its pre-flush failure is expected and the script proceeds using existing JSONL as source of truth. Rationale: silent skip violates R1 (no data loss) because unflushed SQLite state would be lost.
3. `mv .beads/beads.db .beads/beads.db.bd-backup`
4. `br init --prefix "$(basename $PWD)" --force`
5. `br sync --import-only` (+ `--rename-prefix` for GMP)
6. Verify: ID-set integrity check — `br list --all --json | jq -r '.[].id' | sort > /tmp/br-ids.txt` and `jq -r '.id' .beads/issues.jsonl | sort > /tmp/jsonl-ids.txt`, then `diff /tmp/br-ids.txt /tmp/jsonl-ids.txt`. Both sides produce newline-delimited sorted IDs in the same format. Any diff = hard-fail for that repo. Count match is a secondary confirmation (`wc -l` on both files), not the primary check.
7. `br doctor` — all checks pass

Detection-first ordering prevents pre-flush from running `bd sync --flush-only` on already-migrated repos (agent-config), which would fail because bd can't read br's schema.

**Empty/no-JSONL repos**: These repos have a `.beads/` directory but no `issues.jsonl` or an empty one — no beads data to migrate. The script runs `br init --prefix "$(basename $PWD)" --force` (no import step) so that `br ready` and `br list` work immediately. This satisfies R0/AC1 ("all repos operational") without requiring a separate first-use initialization. These repos are listed in the "INITIALIZED (no data)" section of the summary.

**Spec/plan drift acknowledgment**: The plan changes two mechanics from the spec's Shape A2: (1) already-migrated detection uses `br doctor` instead of `.beads/beads.db.bd-backup` file check — because the backup file is gitignored and won't exist on other machines, and (2) `--force` is added back to `br init`. Both changes were validated during planning challenge rounds (HappyOwl challenge #3). The spec should be updated to reflect these refinements.

### Hook replacement (`br-prime.sh`)

Shell script in `configs/claude/hooks/br-prime.sh`. Outputs br-compatible workflow context (~83 lines). Key command mappings:

| bd command | br equivalent | Notes |
|-----------|--------------|-------|
| `bd sync` | `br sync --flush-only` | **CRITICAL**: bare `br sync` = IMPORT (data overwrite trap) |
| `bd ready` | `br ready` | Same |
| `bd list` | `br list` | Same |
| `bd create` | `br create` | `--tags` → `--labels` |
| `bd update` | `br update` | `-d` → `--description` |
| `bd close` | `br close` | Same |
| `bd show` | `br show` | Same |
| `bd dep add` | `br dep add` | Same |
| `bd blocked` | `br blocked` | Same |
| `bd stats` | `br stats` | Same |
| `bd doctor` | `br doctor` | Same |
| `bd tag` | `br label add` | Command renamed |
| `bd edit` | (blocked) | Warning preserved — opens $EDITOR, blocks agents |
| `bd prime` | (removed) | Self-reference removed, hook calls the script directly |

First line of output must be the sync direction warning:
```
⚠️ CRITICAL: `br sync` (bare) = IMPORT. Use `br sync --flush-only` to EXPORT.
```

### Version governance

- `configs/br-version.txt`: Contains `0.1.24` (pinned version)
- AGENTS.md §6 addition: "Never run `br upgrade` without `--version <X.Y.Z>`. Both machines must be updated together."
- `tools-bin/agent-config-parity`: Add `record_tool br` at line 220. Keep `record_tool bd` during 30-day fallback.

### Two-machine sequence

1. **Laptop**: Run migration script → all 38 remaining repos migrated
2. **Laptop**: Commit updated JSONL files where applicable, push
3. **Mini**: Run migration script independently → discovers agent-config (skip, done), openclaw (9 issues), chip-voice (2 issues)
4. **Both**: Run `bootstrap.sh apply` to deploy updated settings.json + br-prime.sh
5. **Both**: Verify with `bootstrap.sh check`

openclaw and chip-voice are mini-only repos — they have no laptop counterpart. Mini runs migration independently for those. No laptop-first dependency.

## Requirement Traceability

| Req | Addressed by | Verification |
|-----|-------------|-------------|
| R0 | Phase 2 migration | `br ready` AND `br list` work in every repo on both machines |
| R1 | A1 pre-flush + ID-set integrity check | ID-set diff (sorted IDs from br vs JSONL) — zero diff per repo |
| R2 | Phase 2 laptop + mini, Phase 3 bootstrap | `br --version` matches `configs/br-version.txt` on both machines |
| R3 | Per-repo backup (`beads.db.bd-backup`) | Can restore by `mv .beads/beads.db.bd-backup .beads/beads.db` |
| R4 | Phase 3 br-prime.sh + settings.json | `grep "bd prime"` returns nothing in BOTH `configs/claude/settings.json` AND live `~/.claude/settings.json` on both machines |
| R5 | Phase 3 AGENTS_v1.md delete + docs | `rg '\bbd\b' instructions/ commands/ skills/ configs/claude/settings.json configs/claude/hooks/` — false positives only. Also check live `~/.claude/settings.json` and `~/.claude/hooks/` on both machines. |
| R6 | Phase 1 governance artifacts + script preflight | `configs/br-version.txt` exists, AGENTS.md §6 has prohibition, migration script enforces version match at runtime |
| R7 | Phase 2 GMP special case | `br list --all` in GMP shows `groovetech-media-player-*` prefixes |
| R8 | Phase 2 pre-flush (all 10 tested OK) | Schema-drift repos verified: all 10/10 flush successfully |
| R9 | Phase 1 script + dry-run matrix | Script tested against 6 edge cases before fleet execution |

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|-----------|
| GMP `--rename-prefix` unexpected behavior | Mixed prefixes in beads.db | Test in throwaway copy before live migration |
| bootstrap.sh breaks mini hooks | All Claude Code sessions fail | bootstrap.sh has hook-file check (lines 164-191); run `check` before `apply` |
| br schema changes in future version | Fleet breaks on upgrade | Version pinned in `configs/br-version.txt`; `br upgrade` prohibited without `--version` |
| JSONL staleness in repos not recently flushed | Missing recent issues | Pre-flush step catches this; verify counts post-migration |

## Files Changed

| File | Action | Shape Part |
|------|--------|-----------|
| `scripts/migrate-to-br.sh` | Create | A2, A3 |
| `configs/claude/hooks/br-prime.sh` | Create | A4 |
| `configs/claude/settings.json` | Edit (lines 87, 249) | A4 |
| `configs/br-version.txt` | Create | A7 |
| `instructions/AGENTS_v1.md` | Delete | A5 |
| `instructions/AGENTS.md` | Edit (§6) | A7 |
| `tools-bin/agent-config-parity` | Edit (line 219-220) | A6 |
| `specs/013-br-fleet-migration/log.md` | Append | Tracking |

---
shaping: true
date: 2026-03-10
participants: WildFalcon (proposer), QuickPhoenix (challenger)
harness: pi/claude-sonnet-4-6
---

# Beads Fleet Migration — Shaping Transcript

## Context

DarkTiger (in GMP) reported bd SQLite corruption. WildFalcon investigated fleet-wide, consulted DarkTiger for GMP-specific details, then ran formal shaping with QuickPhoenix as challenger.

## Intelligence Gathered

### From DarkTiger (GMP session)
- bd 0.50.3 `agent_fields` migration crash: `near "EGER"` (truncated INTEGER)
- bd completely bricked in GMP — every command fails
- br 0.1.24 works — reads JSONL/SQLite, handles corruption gracefully
- br list display bug: shows 51 of 148 known issues
- Bead `groovetech-media-player-42q` orphaned (never persisted to JSONL)
- Other sibling repos (orchestrator, AVPStreamKit, Pfizer, media-server): bd works with Dolt nag warnings
- GMP is the ONLY confirmed bricked repo

### Fleet Assessment (WildFalcon)
- 39 repos with .beads/ directories, 34 with actual JSONL data
- 1 bricked (GMP) — migration crash on DB open
- 10 schema-drift (missing columns) — bd list fails but bd sync works
- 5 Dolt-nag repos — bd wants daemon mode
- 14 working fine — bd 0.50.3 functions normally
- 10 empty/unused
- All repos have intact JSONL — no data loss
- br v0.1.24 installed on both machines (laptop + mini)
- bd v0.50.3 installed on both machines

### Upstream Status
- bd v0.59.0: dropped SQLite entirely, Dolt-only
- Active bd bugs: #2430 (Dolt journal corruption), #2488 (export crash), #2489 (broken atomic commits)
- br v0.1.24: 3 trivial open issues, released 2026-03-08

## Challenge Rounds

### Round 1 (QuickPhoenix → 7 findings)

**BLOCKER 1: `bd prime` wired into hooks** — CONFIRMED
- Lines 87 and 249 of `~/.claude/settings.json`
- `bd prime` injects `bd sync`, `bd ready`, `bd close` instructions
- Contradicts AGENTS.md §6 which already says `br`
- Actively poisoning every Claude Code session TODAY

**BLOCKER 2: Mini br not installed** — RESOLVED
- Feb 28 parity snapshot was stale (pre-Mar 9 migration)
- Verified via SSH: `br 0.1.24` at `/Users/chipcarman/.local/bin/br`

**BLOCKER 3: AGENTS_v1.md bd references** — CONFIRMED
- 28 `bd` references in `instructions/AGENTS_v1.md`
- Discoverable by cass, context injection, agents

**GAP 4: JSONL completeness** — VERIFIED
- GMP: SQLite=148, JSONL=148 (exact match)
- Migration crash didn't corrupt JSONL

**GAP 5: br upgrade policy undefined** — VALID
- Same failure pattern as bd (unpinned, single maintainer)

**GAP 6: GMP dual-prefix** — PARTIALLY ADDRESSED
- Two prefixes in JSONL: `groovetech` (old), `groovetech-media-player` (new)
- `br sync --rename-prefix` flag exists for this exact case

**GAP 7: Migration window** — VALID
- Flag-day vs phased needs decision

### Round 2 (WildFalcon responses)

- BLOCKER 1: Concrete fix — `configs/claude/hooks/br-prime.sh` tracked in agent-config, deployed by bootstrap rsync
- GMP recovery: `br init --prefix "groovetech-media-player" --force` + `br sync --import-only --rename-prefix`
- Version governance: `configs/br-version.txt` + AGENTS.md §6 prohibition
- Flag-day script: `scripts/migrate-to-br.sh` with per-repo sequence
- AGENTS_v1.md: delete (archive still discoverable)

### Round 3 (QuickPhoenix → 3 corrections)

**1. Parity tool doesn't track br** — CONFIRMED (WildFalcon accepted)
- `tools-bin/agent-config-parity` tracks `bd` not `br`
- Governance claim was false

**2. `bd sync --flush-only` doesn't exist** — WRONG (WildFalcon pushed back)
- Flag confirmed in `bd sync --help` Flags section
- QuickPhoenix's output was truncated by GMP DB error

**3. Schema-drift repos can't be pre-flushed** — WRONG (WildFalcon pushed back)
- Tested 4 schema-drift repos: all exported successfully
- Schema-drift errors affect queries, not sync/export path
- Distinct from GMP migration-on-open crash

### Round 4 (QuickPhoenix final)

- Accepted both pushbacks
- Two additions for R set: `br upgrade` prohibition in AGENTS.md §6, already-migrated repo detection
- B/R7 correction: uncertain not proven ❌ (ALTER TABLE vs CREATE TABLE distinction)
- B/R5 reframe: B is a rollback of spec 010, not continuation

## Requirements (R)

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

## Shapes

### A: Full br fleet migration (flag-day) — SELECTED

| Part | Mechanism |
|------|-----------|
| **A1** | Pre-flush: `bd sync --flush-only` in all 24 non-bricked repos |
| **A2** | Migration script (`scripts/migrate-to-br.sh`): per-repo `br init --prefix $(basename $PWD) --force` + `br sync --import-only --rename-prefix`. Detects already-migrated repos (`.beads/beads.db.bd-backup`), skips with warning. Fails visibly on errors. |
| **A3** | GMP special case: `br init --prefix "groovetech-media-player" --force` + `br sync --import-only --rename-prefix` |
| **A4** | Hook replacement: `configs/claude/hooks/br-prime.sh` — tracked script, prominent `br sync ≠ bd sync` warning, deployed by bootstrap rsync. settings.json lines 87+249 updated. |
| **A5** | AGENTS_v1.md deletion |
| **A6** | Parity tool: add `br` to record_tool list. Keep `bd` during 30-day fallback, then remove. |
| **A7** | Version governance: `configs/br-version.txt` + AGENTS.md §6: "Never run `br upgrade` without `--version`." |
| **A8** | Two-machine sequence: laptop first, git push JSONL, mini pulls + runs script. |
| **A9** | bd disposition: keep binary 30 days (spec 010 precedent), then remove. |

### B: Fix bd in-place — REJECTED (fails R0, R5, R6, R7*, R9)

*R7: uncertain — deleting beads.db + bd init might bypass the ALTER TABLE bug. Not tested.

### C: Upgrade bd to 0.59.0 (Dolt) — REJECTED (fails R0, R1, R2, R3, R4, R5, R6, R9)

## Fit Check

| Req | Requirement | Status | A | B | C |
|-----|-------------|--------|---|---|---|
| R0 | All repos reliable with single tool | Core goal | ✅ | ❌ | ❌ |
| R1 | JSONL source of truth, no data loss | Must-have | ✅ | ✅ | ❌ |
| R2 | Both machines, version parity | Must-have | ✅ | ✅ | ❌ |
| R3 | Safe migration, per-repo recovery | Must-have | ✅ | ✅ | ❌ |
| R4 | Hooks inject correct br context | Must-have | ✅ | ✅ | ❌ |
| R5 | No stale bd references in live paths | Must-have | ✅ | ❌ | ❌ |
| R6 | br version governance | Must-have | ✅ | ❌ | ❌ |
| R7 | GMP recovered | Must-have | ✅ | ❓ | ❌ |
| R8 | Schema-drift repos migrated | Must-have | ✅ | ✅ | ❌ |
| R9 | Automated migration script | Must-have | ✅ | ❌ | ❌ |

## What the Two-Agent Gate Caught

**QuickPhoenix caught (proposer errors):**
- Parity tool doesn't track br (false governance claim)
- B/R7 overconfidence (ALTER vs CREATE distinction)
- 2>/dev/null suppression in migration script
- br upgrade prohibition scope (napkin insufficient, needs AGENTS.md §6)
- Already-migrated repo detection gap

**WildFalcon caught (challenger errors):**
- bd sync --flush-only exists (truncated help output)
- Schema-drift repos flush successfully (conflated two error modes)
- Mini br install confirmed (stale parity snapshot)

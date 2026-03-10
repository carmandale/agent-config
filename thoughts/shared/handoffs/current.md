# Current State — 2026-03-10

## Active Work: Spec 013 — Fleet-wide br Migration

**Bead**: `.agent-config-2gy`
**Branch**: `feat/013-br-fleet-migration`
**Spec**: `specs/013-br-fleet-migration/`

### Status: Phases 1-3 COMPLETE on laptop. Mini + cleanup remaining.

### What's Done (laptop)

| Phase | Status | Summary |
|-------|--------|---------|
| Phase 1: Build | ✅ DONE | Migration script, hook, version pin, dry-run tested, navigator-reviewed |
| Phase 2: Execute | ✅ DONE | 40/40 repos migrated (23 migrated + 16 already br-works + 1 already-migrated) |
| Phase 3: Deploy | ✅ DONE | settings.json updated, AGENTS_v1.md deleted, AGENTS.md §6 updated, parity tool updated |
| Phase 4: Cleanup | ⏳ 2026-04-10 | Bead `.agent-config-1na` created for 30-day cleanup |

### Implementation Discoveries (not in original plan)

1. **br lowercases all prefixes** during `br init --prefix`. JSONL IDs with uppercase fail import.
   - Fix: Step 3.5 in script normalizes JSONL IDs (lowercase + dot→'d' replacement)
2. **br rejects dots in hash portion** (bd sub-issue `.N` notation not supported)
   - Fix: Same normalization step replaces `.` with `d` in hash portion
3. **Stale WAL/SHM files corrupt `br init --force`**
   - Fix: Script trashes WAL/SHM alongside db backup
4. **Multi-prefix repos** (destructive_command_guard has `bd-*` and `git_safety_guard-*`)
   - Fix: Auto-detect multiple prefixes, add `--rename-prefix`; count-based verification for rename cases
5. **`br list --all --json` caps at 50** (br issue #168) — uses sqlite3 directly for ID verification

### Remaining Tasks (7 of 53)

| Task | Description | Blocked by |
|------|-------------|-----------|
| 28-31 | Mini deployment (pull, run script, verify) | SSH access to mini |
| 37 | Mini hook deployment (pull, bootstrap) | Task 28 |
| 45 | Mini verification (no bd in deployed state) | Task 37 |
| 49-53 | Phase 4: 30-day cleanup (2026-04-10) | Calendar gate |

### Key Files

- `scripts/migrate-to-br.sh` — manifest-driven migration script
- `configs/claude/hooks/br-prime.sh` — hook replacement (13 command mappings)
- `configs/br-version.txt` — version pin (0.1.24)
- `specs/013-br-fleet-migration/fleet-manifest.txt` — 40 repos classified

### Commits on branch

| SHA | Description |
|-----|-------------|
| `5dfe3864` | Phase 1 build artifacts (5 files) |
| `731097d2` | Navigator review fixes (4 defects, 2 doc drifts) |
| `6298a2bf` | Plan.md stale procedure fix |
| `ca302834` | Phase 2 fix: br ID format constraints (uppercase, dots, WAL) |
| `30af6e0f` | Phase 3: deploy hooks, delete AGENTS_v1, update parity |

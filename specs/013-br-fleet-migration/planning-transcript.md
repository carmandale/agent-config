---
date: 2026-03-10
participants: WildFalcon (proposer), HappyOwl (challenger)
harness: pi/claude-sonnet-4-6
---

# Planning Transcript — Spec 013: Fleet-wide br migration

## Research Phase (WildFalcon)

### Key findings shared with challenger before writing plan:
1. Fleet is 39 laptop repos + 3 mini repos (not 39+39). Mini only has agent-config (done), openclaw (9), chip-voice (2).
2. Hook insertion points: settings.json lines 85-88 (SessionStart) and 247-250 (PreCompact) have `"command": "bd prime"`.
3. Parity tool: line 219 has `record_tool bd`. Add `record_tool br`.
4. bd prime output: 83 lines / 3416 chars, 13 bd commands to translate.
5. AGENTS.md §6 already uses br (spec 010). Only addition: br upgrade prohibition.
6. Pre-flush works in all 10 schema-drift repos (tested 10/10).
7. Proposed 3-phase structure: Fix live bugs → Build script → Execute migration.

## Challenge Round 1 (HappyOwl → 8 problems)

### #1 BLOCKER — Phase 1 creates transitional poison state
br-prime.sh deployed before repos migrated → agents get br commands that fail on bd-schema DBs. Verified: `br sync --flush-only` in unmigrated repo → DATABASE_ERROR.
**Fix**: Reorder to Build → Execute → Deploy.

### #2 BUG — "24 non-bricked repos" count wrong
24 was agent-config's issue count, not fleet count. Actual: 24 working + 6 drift + 4 Dolt-nag + 1 empty + 4 no-JSONL = 39.
**Fix**: Corrected counts in plan.

### #3 GAP — Already-migrated detection breaks on mini
`.beads/beads.db.bd-backup` is gitignored. Mini won't have it.
**Fix**: Use `br doctor` + schema detection instead of file artifact.

### #4 GAP — Mini has different home dir
Script can't hardcode laptop paths.
**Fix**: Repo discovery via find, each machine scans independently.

### #5 GAP — 6/10 schema-drift repos untested
Only 4/10 tested during shaping.
**Fix**: Tested all 10/10 — all flush successfully.

### #6 MISSING — No dry-run test matrix
**Fix**: Added 6-case matrix (a-f).

### #7 MISSING — 30-day cleanup tasks absent
**Fix**: Added Phase 4 with explicit tasks + bead reminder.

### #8 QUESTION — openclaw + chip-voice mini-only?
Confirmed: neither exists on laptop. Mini migrates independently.

## Challenge Round 2 (HappyOwl → 4 problems on written plan)

### #1 CORRECTNESS — $HOME in settings.json won't expand
Checked existing hooks: .sh hooks use `~/.claude/hooks/...` format.
**Fix**: Task 27 uses `~/.claude/hooks/br-prime.sh`.

### #2 BUG — Pre-flush hits agent-config
Standalone pre-flush sweep tries `bd sync --flush-only` on agent-config (br-schema DB) → fails.
**Fix**: Folded pre-flush into migration script after already-migrated detection. Detect → skip-or-migrate.

### #3 GAP — Migration script never committed
Mini can't pull it for Phase 2 task 23.
**Fix**: Added task 18 (commit after Phase 1 dry-run, before Phase 2 execution).

### #4 SCALE — Task 22 is multi-repo commits
Pre-flush JSONL changes are in 34 separate git repos, not agent-config.
**Fix**: Script logs repos with dirty JSONL. Operator reviews + commits manually. No auto-commit.

## What the Two-Agent Gate Caught

**HappyOwl caught (proposer errors):**
- Phase ordering blocker (hooks before migration = poison window)
- Pre-flush hitting already-migrated repos (bd can't read br schema)
- $HOME path format mismatch (existing hooks use ~)
- Migration script not committed before mini needs it
- Multi-repo JSONL commits need operator review, not auto-commit
- "24 non-bricked repos" count was wrong
- Already-migrated detection mechanism breaks cross-machine
- 6/10 schema-drift repos were untested assumptions
- 30-day cleanup tasks were missing from phase structure

**WildFalcon research confirmed:**
- All 10/10 schema-drift repos flush successfully
- openclaw + chip-voice are mini-only
- bootstrap.sh handles settings.json deployment (line 276)
- Existing .sh hooks use ~/... path format

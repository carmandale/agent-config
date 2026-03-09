---
title: "Tasks: Migrate from bd to br (beads_rust)"
date: 2026-03-09
bead: .agent-config-17q
---

# Tasks: Migrate from bd to br

## Phase 1: Install & Verify (laptop only, throwaway test)

- [x] 1. Install br on laptop via `curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash` — v0.1.24 at ~/.local/bin/br
- [x] 2. Verify installation: `br --version`, `which br` ✓
- [x] 3. Create throwaway test directory, copy `.beads/issues.jsonl` there ✓
- [x] 4. Test `br init` in throwaway → verify it creates `beads.db` ✓ (⚠️ MUST use `--prefix ".agent-config"` — br auto-detects prefix from dir name, not JSONL)
- [x] 5. Test `br init` in a directory with an existing `beads.db` → ALREADY_INITIALIZED error ✓
- [x] 6. Run `br sync --import-only` in throwaway → all 24 issues imported ✓
- [x] 7. Smoke test command surface: all commands verified ✓
- [x] 8. JSONL round-trip test: timestamps normalized to UTC, new default fields (compaction_level, source_repo, original_size) — no data loss ✓
- [x] 9. Test bare `br sync` (no flags) → confirmed IMPORT (not export) ✓
- [x] 10. Clean up throwaway test directory ✓

## Phase 2: Migrate agent-config on laptop

- [x] 11. Flush bd state: `bd sync --flush-only` ✓
- [x] 12. Rename bd's database: `mv .beads/beads.db .beads/beads.db.bd-backup` ✓
- [x] 13. Run `br init --prefix ".agent-config"` ✓ (prefix required — see Phase 1 discovery)
- [x] 14. Run `br sync --import-only` → all 24 issues imported ✓
- [x] 15. Verify `br list` — all issues with correct fields, statuses, priorities ✓
- [x] 16. Update pre-commit hook — 4 substitution points ✓
- [x] 17. Update post-merge hook — 3 substitution points ✓
- [x] 18. Add tracked hook templates to `hooks/` (pre-commit + post-merge) ✓
- [x] 19. Update `install.sh` — simplified hook section, removed old bd guard ✓
- [x] 20. Test hooks: commit triggered pre-commit flush successfully ✓
- [x] 21. Commit hook changes + tracked templates + gitignore entries ✓ (b9d481e4)

## Phase 3: Update documentation & commands

All bare `bd sync` → `br sync --flush-only` (bare `br sync` = import, not export!)

- [x] 22. Update `instructions/AGENTS.md` — 7 refs updated ✓
- [x] 23. Update `instructions/CLAUDE.md` — 11 refs updated, pgrep/pkill block removed ✓
- [x] 24. Update commands — 15 files, all special cases handled ✓
- [x] 25. Update skills — 8 files (GLOBAL scope), all refs updated ✓
- [x] 26. Update `.beads/README.md` — rewritten for br ✓
- [x] 27. Update `.beads/config.yaml` — updated comments, removed daemon refs ✓
- [x] 28. Update napkin with migration decision rationale ✓
- [x] 29. Commit all doc/command/skill updates as ONE commit ✓ (9c5a2451)
- [x] 30. Pushed to origin ✓ (post-receive ran install.sh on mini automatically)

## Phase 4: Mini migration (one uninterrupted SSH session)

- [x] 31. Push Phase 3 commit to origin ✓
- [x] 32. SSH to mini ✓
- [x] 33. Install br v0.1.24 on mini ✓ (/Users/chipcarman/.local/bin/br)
- [x] 34. Verify: br --version, which br ✓
- [x] 35. br init --prefix ".agent-config" + br sync --import-only → 24 issues ✓
- [x] 36. Verify br list — 24 issues ✓
- [x] 37. install.sh → pre-commit + post-merge hooks installed ✓

## Phase 5: Verification & Cleanup

- [x] 38. br doctor on laptop — all checks pass ✓ (fresh init fixed schema.tables)
- [x] 39. br doctor on mini — all checks pass ✓
- [x] 40. Trashed stale bd artifacts: daemon.log (5.5MB), dolt-server.lock, .migration-hint-ts ✓
- [x] 41. Removed .migration-hint-ts on mini ✓
- [x] 42. E2E test: created .agent-config-18o on laptop → pushed → visible on mini ✓
- [x] 43. Multi-clone conflict test: both sides edited .agent-config-17q → JSONL conflict detected by br doctor (3 conflict markers) → resolved via git rebase → clean doctor after ✓
- [x] 44. rg '\bbd\b' — only AGENTS_v1.md (archived) + open-sets false positive ✓
- [x] 45. bd binary stays at /opt/homebrew/bin/bd (30-day fallback)
- [x] 46. beads.db.bd-backup preserved (30-day retention)
- [x] 47. Closed bead .agent-config-17q with full evidence ✓
- [x] 48. Updated spec.md status: shaping → done ✓

## Dependencies

```
Phase 1 (verify) → Phase 2 (laptop migrate) → Phase 3 (docs) → Phase 4 (mini) → Phase 5 (cleanup)
```

All phases are strictly sequential. No parallelism — each phase validates assumptions the next phase depends on.

## Codex Review Findings (incorporated)

### Round 1
1. ✅ Tracked hook templates added (tasks 18–19) — hooks now propagate via git + install.sh
2. ✅ Pre-cutover flush added (task 11) — eliminates data-loss window from unflushed DB state
3. ✅ `bd tag` → `br label add`, `--tags` → `--labels` mappings added (tasks 24–25)
4. ✅ Smoke tests expanded: `br create` (R1.1), `br update --status` (R1.3), `br label add` (task 7)
5. ✅ Issue count corrected: 24 (not 22) throughout
6. ✅ `prompt-craft/SKILL.md` and `ntm/SKILL.md` added to skill updates; `open-sets/SKILL.md` marked false positive
7. ✅ Bare `bd sync` count corrected: 13 (not 12)

### Round 2
8. ✅ `--tags` → `--labels` (plural, not singular) — verified from br CreateArgs source
9. ✅ Issue count 24 now consistent everywhere (was still 22 in Phase 1 task 6)
10. ✅ ID prefix corrected: `.agent-config-*` not `bd-*` — plan and smoke test updated
11. ✅ Multi-clone conflict test added (task 43)
12. ✅ Task numbering cleaned — sequential 1–48, no gaps or overlaps

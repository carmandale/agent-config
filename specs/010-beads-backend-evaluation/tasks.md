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

- [ ] 22. Update `instructions/AGENTS.md` — 7 occurrences:
  - Line 189: `bd ready || bd --no-db ready` → `br ready` (remove fallback, br always has DB)
  - Lines 244–245: `bd sync` → `br sync --flush-only`
  - Lines 252–255: `bd ready/update/close/sync` → `br` equivalents
- [ ] 23. Update `instructions/CLAUDE.md` — 11 occurrences:
  - Lines 239, 284, 375–376: `bd` commands → `br` equivalents
  - Lines 339, 350, 353: bare `bd sync` → `br sync --flush-only`
  - Lines 358–360: REMOVE pgrep/pkill contention block entirely, replace with: "br has no daemon; if .beads/ files are dirty, run `br sync --flush-only` to export, then stage normally."
- [ ] 24. Update commands — 15 files, special cases:
  - `retro.md`: `bd update $BEAD_ID -d` → `br update $BEAD_ID --description`
  - `retro.md`: `bd tag $BEAD_ID retro-complete` → `br label add $BEAD_ID retro-complete`
  - `retro.md`, `iterate.md`: `--tags` → `--labels` (plural)
  - `pr-create.md`: `bd update <id> -d` → `br update <id> --description`
  - `checkpoint.md`, `handoff.md`, `finalize.md`: `--sort updated` → `--sort updated` (identical, verified)
  - All bare `bd sync` → `br sync --flush-only` (13 occurrences total)
  - All other `bd` → `br` (same flags apply)
  - Files: checkpoint.md, context-dump.md, estimate.md, finalize.md, fix-all.md, focus.md, handoff.md, issue.md, iterate.md, parallel.md, pr-create.md, retro.md, standup.md, triage.md, worktree-task.md
- [ ] 25. Update skills — 8 files (⚠️ GLOBAL scope, affects all repos):
  - Coordinate timing: no active cross-repo agent sessions using these skills
  - `skills/domain/ralph/ralph-tui-create-beads/SKILL.md` (18 refs) — `bd dep add` → `br dep add`, `bd create` → `br create`
  - `skills/tools/agent-mail/SKILL.md` (13 refs) — note: bare `bd sync` here too → `--flush-only`
  - `skills/tools/bv/SKILL.md` (7 refs)
  - `skills/workflows/resume-handoff/SKILL.md` (5 refs)
  - `skills/tools/plan/SKILL.md` (1 ref)
  - `skills/tools/work/SKILL.md` (1 ref)
  - `skills/meta/prompt-craft/SKILL.md` (1 ref — `bd create` example)
  - `skills/tools/ntm/SKILL.md` (1 ref — `bd-1,bd-2` bead ID examples, review for consistency)
  - ⚠️ DO NOT edit `skills/domain/math/math/topology/open-sets/SKILL.md` — `bd(A)` is math notation, not a bd command
- [ ] 26. Update `.beads/README.md` — replace `bd` examples with `br`
- [ ] 27. Update `.beads/config.yaml` comments — replace `bd` references with `br`
- [ ] 28. Update napkin (`.claude/napkin.md`) with migration decision rationale
- [ ] 29. Commit all doc/command/skill updates as ONE commit
- [ ] 30. Do NOT push yet — Phase 4 must be ready to execute immediately after push

## Phase 4: Mini migration (one uninterrupted SSH session)

⚠️ Steps 31–37 must execute in one uninterrupted SSH session. The window where docs say `br` but mini only has `bd` must be less than 5 minutes.

- [ ] 31. Push Phase 3 commit to origin (triggers post-receive on mini, updating docs)
- [ ] 32. SSH to mini
- [ ] 33. Install br on mini: `curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash`
- [ ] 34. Verify: `br --version`, `which br`
- [ ] 35. In `~/.agent-config`: run `br init` + `br sync --import-only` (mini has no existing beads.db — no collision risk)
- [ ] 36. Verify `br list` shows all issues (should be 24)
- [ ] 37. Run install.sh on mini to install tracked hook templates (pre-commit + post-merge)

## Phase 5: Verification & Cleanup

- [ ] 38. Run `br doctor` on laptop — all checks pass
- [ ] 39. Run `br doctor` on mini (via SSH) — all checks pass
- [ ] 40. On laptop, remove stale bd artifacts from `.beads/`:
  - `daemon.log` (5.8MB — stale bd daemon log)
  - `dolt-server.lock`
  - `.sync.lock`
  - `.migration-hint-ts`
  - Use `trash` per §8
- [ ] 41. On mini, remove stale bd artifacts from `.beads/` (if any)
- [ ] 42. Verify end-to-end workflow: create test bead on laptop → commit → push → pull on mini → `br list` shows it
- [ ] 43. Multi-clone conflict test: update same issue on both machines before syncing, verify JSONL conflict is detectable by `br doctor` and recoverable via manual merge + `br sync --import-only`
- [ ] 44. Verify bare `rg '\bbd\b' instructions/ commands/ skills/` returns only the open-sets false positive + spec directory refs
- [ ] 45. Keep bd binary installed as emergency fallback (review after 30 days)
- [ ] 46. Keep `beads.db.bd-backup` for 30 days, then remove
- [ ] 47. Close bead `.agent-config-17q` with evidence: br version, issue count, both machines verified
- [ ] 48. Update spec.md status: `shaping` → `done`

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

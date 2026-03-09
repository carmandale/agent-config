---
title: "Tasks: Migrate from bd to br (beads_rust)"
date: 2026-03-09
bead: .agent-config-17q
---

# Tasks: Migrate from bd to br

## Phase 1: Install & Verify (laptop only, throwaway test)

- [ ] 1. Install br on laptop via `curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash`
- [ ] 2. Verify installation: `br --version`, `which br`
- [ ] 3. Create throwaway test directory, copy `.beads/issues.jsonl` there
- [ ] 4. Test `br init` in throwaway → verify it creates `beads.db`
- [ ] 5. Test `br init` in a directory with an existing `beads.db` → verify `AlreadyInitialized` error (not silent overwrite)
- [ ] 6. Run `br sync --import-only` in throwaway → verify all 24 issues import
- [ ] 7. Smoke test command surface:
  - `br list` — shows all issues
  - `br ready` — shows actionable issues
  - `br show <id>` — shows issue detail with correct fields
  - `br ready --json` — produces valid JSON output
  - `br create "test issue" -p 2` — verify creates with auto-detected prefix (`.agent-config-*`, R1.1)
  - `br update <id> --status in_progress` — verify status transition (R1.3)
  - `br update <id> --description "test"` — updates description (NOT `-d`)
  - `br close <id> --reason "test"` — closes with reason
  - `br label add <id> test-label` — verify label command (replaces bd tag)
  - `br list --sort updated` — verify sort flag works
  - `br doctor` — all checks pass
  - `br sync --flush-only` — exports DB→JSONL
- [ ] 8. JSONL round-trip test: export → diff against original → verify zero meaningful changes (field ordering may differ, content must match)
- [ ] 9. Test bare `br sync` (no flags) → confirm it does IMPORT, not export (documenting the behavioral difference)
- [ ] 10. Clean up throwaway test directory

## Phase 2: Migrate agent-config on laptop

- [ ] 11. Flush bd state: `bd sync --flush-only` (ensure no unflushed DB changes are lost)
- [ ] 12. Rename bd's database: `mv .beads/beads.db .beads/beads.db.bd-backup`
- [ ] 13. Run `br init` in agent-config root
- [ ] 14. Run `br sync --import-only` → verify all 24 issues import
- [ ] 15. Verify `br list` shows all issues with correct fields, statuses, priorities
- [ ] 16. Update pre-commit hook (`.git/hooks/pre-commit`) — 4 substitution points:
  - `command -v bd` → `command -v br`
  - `"bd command not found"` → `"br command not found"`
  - `bd sync --flush-only` → `br sync --flush-only`
  - `"Run 'bd sync --flush-only'"` → `"Run 'br sync --flush-only'"`
- [ ] 17. Update post-merge hook (`.git/hooks/post-merge`) — 3 substitution points:
  - `command -v bd` → `command -v br`
  - `bd import -i "$BEADS_DIR/issues.jsonl"` → `br sync --import-only`
  - Error messages (2x) → reference `br`
- [ ] 18. Add tracked hook templates to `hooks/` directory (br versions of pre-commit + post-merge)
- [ ] 19. Update `install.sh` to copy pre-commit and post-merge hooks (matching existing post-commit pattern)
- [ ] 20. Test hooks: create a test bead change, commit, verify JSONL is updated by pre-commit hook
- [ ] 21. Commit hook changes + tracked templates + beads.db.bd-backup gitignore entry

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

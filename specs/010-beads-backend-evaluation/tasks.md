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
- [ ] 6. Run `br sync --import-only` in throwaway → verify all 22 issues import
- [ ] 7. Smoke test command surface:
  - `br list` — shows all issues
  - `br ready` — shows actionable issues
  - `br show <id>` — shows issue detail with correct fields
  - `br ready --json` — produces valid JSON output
  - `br update <id> --description "test"` — updates description (NOT `-d`)
  - `br close <id> --reason "test"` — closes with reason
  - `br doctor` — all checks pass
  - `br sync --flush-only` — exports DB→JSONL
- [ ] 8. JSONL round-trip test: export → diff against original → verify zero meaningful changes (field ordering may differ, content must match)
- [ ] 9. Test bare `br sync` (no flags) → confirm it does IMPORT, not export (documenting the behavioral difference)
- [ ] 10. Clean up throwaway test directory

## Phase 2: Migrate agent-config on laptop

- [ ] 11. Rename bd's database: `mv .beads/beads.db .beads/beads.db.bd-backup`
- [ ] 12. Run `br init` in agent-config root
- [ ] 13. Run `br sync --import-only` → verify all 22 issues import
- [ ] 14. Verify `br list` shows all issues with correct fields, statuses, priorities
- [ ] 15. Update pre-commit hook (`.git/hooks/pre-commit`) — 4 substitution points:
  - `command -v bd` → `command -v br`
  - `"bd command not found"` → `"br command not found"`
  - `bd sync --flush-only` → `br sync --flush-only`
  - `"Run 'bd sync --flush-only'"` → `"Run 'br sync --flush-only'"`
- [ ] 16. Update post-merge hook (`.git/hooks/post-merge`) — 3 substitution points:
  - `command -v bd` → `command -v br`
  - `bd import -i "$BEADS_DIR/issues.jsonl"` → `br sync --import-only`
  - Error messages (2x) → reference `br`
- [ ] 17. Test hooks: create a test bead change, commit, verify JSONL is updated by pre-commit hook
- [ ] 18. Commit hook changes + beads.db.bd-backup gitignore entry

## Phase 3: Update documentation & commands

All bare `bd sync` → `br sync --flush-only` (bare `br sync` = import, not export!)

- [ ] 19. Update `instructions/AGENTS.md` — 7 occurrences:
  - Line 189: `bd ready || bd --no-db ready` → `br ready` (remove fallback, br always has DB)
  - Lines 244–245: `bd sync` → `br sync --flush-only`
  - Lines 252–255: `bd ready/update/close/sync` → `br` equivalents
- [ ] 20. Update `instructions/CLAUDE.md` — 11 occurrences:
  - Lines 239, 284, 375–376: `bd` commands → `br` equivalents
  - Lines 339, 350, 353: bare `bd sync` → `br sync --flush-only`
  - Lines 358–360: REMOVE pgrep/pkill contention block entirely, replace with: "br has no daemon; if .beads/ files are dirty, run `br sync --flush-only` to export, then stage normally."
- [ ] 21. Update commands — 15 files, special cases:
  - `retro.md`: `bd update $BEAD_ID -d` → `br update $BEAD_ID --description`
  - `pr-create.md`: `bd update <id> -d` → `br update <id> --description`
  - All other `bd` → `br` (same flags apply)
  - Files: checkpoint.md, context-dump.md, estimate.md, finalize.md, fix-all.md, focus.md, handoff.md, issue.md, iterate.md, parallel.md, pr-create.md, retro.md, standup.md, triage.md, worktree-task.md
- [ ] 22. Update skills — 6 files (⚠️ GLOBAL scope, affects all repos):
  - Coordinate timing: no active cross-repo agent sessions using these skills
  - `skills/domain/ralph/ralph-tui-create-beads/SKILL.md` (18 refs)
  - `skills/tools/agent-mail/SKILL.md` (13 refs) — note: bare `bd sync` here too
  - `skills/tools/bv/SKILL.md` (7 refs)
  - `skills/workflows/resume-handoff/SKILL.md` (5 refs)
  - `skills/tools/plan/SKILL.md` (1 ref)
  - `skills/tools/work/SKILL.md` (1 ref)
- [ ] 23. Update napkin (`.claude/napkin.md`) with migration decision rationale
- [ ] 24. Commit all doc/command/skill updates as ONE commit
- [ ] 25. Do NOT push yet — Phase 4 must be ready to execute immediately after push

## Phase 4: Mini migration (one uninterrupted SSH session)

⚠️ Steps 26–31 must execute in one uninterrupted SSH session. The window where docs say `br` but mini only has `bd` must be less than 5 minutes.

- [ ] 26. Push Phase 3 commit to origin (triggers post-receive on mini, updating docs)
- [ ] 27. SSH to mini
- [ ] 28. Install br on mini: `curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash`
- [ ] 29. Verify: `br --version`, `which br`
- [ ] 30. In `~/.agent-config`: run `br init` + `br sync --import-only` (mini has no existing beads.db — no collision risk)
- [ ] 31. Verify `br list` shows all issues
- [ ] 32. Mini currently has NO pre-commit/post-merge hooks — add the br-version hooks from laptop (copy from laptop's .git/hooks/)

## Phase 5: Verification & Cleanup

- [ ] 33. Run `br doctor` on laptop — all checks pass
- [ ] 34. Run `br doctor` on mini (via SSH) — all checks pass
- [ ] 35. On laptop, remove stale bd artifacts from `.beads/`:
  - `daemon.log` (5.8MB — stale bd daemon log)
  - `dolt-server.lock`
  - `.sync.lock`
  - `.migration-hint-ts`
  - Use `trash` per §8
- [ ] 36. On mini, remove stale bd artifacts from `.beads/` (if any)
- [ ] 37. Verify end-to-end workflow: create test bead on laptop → commit → push → pull on mini → `br list` shows it
- [ ] 38. Keep bd binary installed as emergency fallback (review after 30 days)
- [ ] 39. Keep `beads.db.bd-backup` for 30 days, then remove
- [ ] 40. Close bead `.agent-config-17q` with evidence: br version, issue count, both machines verified
- [ ] 41. Update spec.md status: `shaping` → `done`

## Dependencies

```
Phase 1 (verify) → Phase 2 (laptop migrate) → Phase 3 (docs) → Phase 4 (mini) → Phase 5 (cleanup)
```

All phases are strictly sequential. No parallelism — each phase validates assumptions the next phase depends on.

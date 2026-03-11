<!-- Codex Review: APPROVED after 2 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: REVISED -->
<!-- Revisions: added Phase 2 (test guard), Phase 3 (README), expanded Phase 4 canonicalization, added Phase 5 verification steps -->

# Tasks: 014 — Parity Tool Drift

## Phase 1: Fix Parity Tool Managed Paths

- [x] 1. Replace `pi_commands` entry (`$HOME/.pi/agent/commands`) with `pi_prompts` entry (`$HOME/.pi/agent/prompts` → `$repo_dir/commands`)
- [x] 2. Remove `pi_skills` entry (`$HOME/.pi/agent/skills`) — install.sh intentionally does not create this
- [x] 3. Remove `codex_skills` entry (`$HOME/.codex/skills`) — this is Codex's internal dir, not our symlink
- [x] 4. Add `agents_skills` entry (`$HOME/.agents/skills` → `$repo_dir/skills`) — the unified Codex+Gemini skills path
- [x] 5. Add `gemini_instructions` entry (`$HOME/.gemini/GEMINI.md` → `$repo_dir/instructions/AGENTS.md`)
- [x] 6. Bump `snapshot.version` from `"1"` to `"2"` (managed key names changed)
- [x] 7. Add coupling-awareness comment above the `record_managed_path` block referencing `tests/test-symlink-parity.sh`

## Phase 2: Extend Symlink Parity Test

- [x] 8. Add `PARITY_TOOL="$REPO_ROOT/tools-bin/agent-config-parity"` path variable
- [x] 9. Add section 7: extract managed path destinations from parity tool using `record_managed_path` grep pattern
- [x] 10. Add assertion: every install.sh symlink is tracked by parity tool
- [x] 11. Add assertion: every parity tool managed path exists in install.sh
- [x] 12. Add assertion: install.sh and parity tool have same count

## Phase 3: Fix README Stale Entries

- [x] 13. Remove `~/.pi/agent/skills → ~/.agent-config/skills` from "How It Works" symlink map (~line 94)
- [x] 14. Remove `~/.pi/agent/skills → ~/.agent-config/skills` from "Skills (Unified)" symlinks section (~line 388)

## Phase 4: Fix Hardcoded Paths in Extension

- [x] 15. Add `import { homedir } from "node:os"` and `import { join, resolve } from "node:path"` to `installed-binary-guard.ts`
- [x] 16. Build `BINARY_SOURCE_MAP` keys dynamically using `join(homedir(), "bin", "gj")`
- [x] 17. Build source and install values dynamically using `homedir()` — preserve Dropbox path structure as relative to home
- [x] 18. Fix `normalizePath()` canonicalization order: (1) strip `@`, (2) expand `~/` with `homedir()`, (3) `resolve()` to absolute
- [x] 19. Verify no `/Users/dalecarman` literals remain: `grep -c '/Users/' configs/pi/extensions/installed-binary-guard.ts` → 0

## Phase 5: Verify

- [x] 20. Run `tests/test-symlink-parity.sh` — all assertions pass including new section 7
- [x] 21. Run `agent-config-parity snapshot` — all managed paths report `ok`
- [x] 22. Run `scripts/bootstrap.sh check` — symlinks section matches
- [x] 23. Verify `snapshot.version=2` in parity output
- [x] 24. Verify `grep 'pi/agent/skills' README.md` returns empty (stale entry removed)
- [x] 25. Commit: `fix(014): align parity tool with install.sh, extend test guard, fix extension paths`

<!-- Codex Review: APPROVED after 2 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: REVISED -->
<!-- Revisions: (1) replaced comment-only coupling with automated test guard in test-symlink-parity.sh, (2) bumped snapshot schema version 1→2, (3) added README stale entry cleanup, (4) fixed normalizePath canonicalization order, (5) strengthened verification plan -->

# Plan: 014 — Parity Tool Drift

## Strategy

All six bugs stem from the same root cause: the parity tool's managed path list diverged from install.sh's actual behavior. The fix is:

1. Update the parity tool's managed paths to match install.sh and bootstrap.sh (which are already correct and in sync)
2. Extend the existing `tests/test-symlink-parity.sh` to include the parity tool as a fourth source — this prevents future drift with an automated guard
3. Fix the README's stale symlink map (it still documents `~/.pi/agent/skills`)
4. Bump the snapshot schema version since managed key names change
5. Fix the hardcoded paths in `installed-binary-guard.ts` with proper canonicalization

Bootstrap.sh is the reference — it was correctly updated during specs 012 and 013. The parity tool and README were not.

## Architecture Decision: Automated Coupling Guard

The root cause is independent path lists with no structural coupling. The repo already has `tests/test-symlink-parity.sh` which verifies install.sh ↔ bootstrap.sh ↔ README agreement by extracting symlink paths from each source and diffing them. This is exactly the right place to add the parity tool as a fourth source.

**Rejected alternative**: Comment-only cross-references. This is what the original plan proposed but Codex correctly identified that comments don't prevent drift — the existing test framework does.

**Approach**: Add a section 7 to `test-symlink-parity.sh` that extracts managed paths from the parity tool and verifies they match install.sh's symlink set. The extraction pattern is `record_managed_path "<key>" "<path>" "<target>"` → extract `<path>` with `$HOME/` stripped.

## Insertion Points

### 1. Parity tool (`tools-bin/agent-config-parity`)

Lines 185-197, the `record_managed_path` block. Replace the entire managed path section:

**Remove**:
- `pi_commands` at `$HOME/.pi/agent/commands` (wrong — Pi uses `prompts`)
- `codex_skills` at `$HOME/.codex/skills` (Codex internal dir, not our symlink)
- `pi_skills` at `$HOME/.pi/agent/skills` (intentionally not created by install.sh)

**Add**:
- `pi_prompts` at `$HOME/.pi/agent/prompts` → `$repo_dir/commands`
- `agents_skills` at `$HOME/.agents/skills` → `$repo_dir/skills`
- `gemini_instructions` at `$HOME/.gemini/GEMINI.md` → `$repo_dir/instructions/AGENTS.md`

**Keep unchanged**: `pi_instructions`, `claude_commands`, `claude_instructions`, `codex_prompts`, `codex_instructions`, `opencode_commands`, `claude_skills`, `agent_skills`

**Bump snapshot version**: Line 161, change `emit "snapshot.version" "1"` to `emit "snapshot.version" "2"`.

**Add version note comment** near the `record_managed_path` block:
```bash
# COUPLED: These paths MUST match install.sh create_symlink calls.
# Automated guard: tests/test-symlink-parity.sh verifies all 4 sources agree.
# If you add/remove/rename a path here, also update install.sh, bootstrap.sh, README.md.
```

### 2. Test (`tests/test-symlink-parity.sh`)

Add section 7 after section 6:

**Section 7: install.sh ↔ parity tool managed paths**

Extract managed path destinations from the parity tool. The extraction pattern:
```bash
grep 'record_managed_path' "$PARITY_TOOL" \
  | grep -v '^record_managed_path()' \
  | sed -n 's/.*"\$HOME\/\([^"]*\)".*/\1/p' \
  | sort
```

This captures the second argument (`$HOME/...` path) from each `record_managed_path` call. Then diff against install.sh paths — they must match exactly.

### 3. README.md — Stale symlink map

Two locations document symlink maps:

**"How It Works" section** (line ~80-95): Remove `~/.pi/agent/skills` entry. The current map lists:
```
~/.pi/agent/skills       → ~/.agent-config/skills
```
This must be removed — install.sh explicitly does not create this symlink.

**"Skills (Unified)" section** (line ~384-388): Same stale entry under "Symlinks":
```
~/.pi/agent/skills      → ~/.agent-config/skills
```
Remove this entry.

### 4. Extension (`configs/pi/extensions/installed-binary-guard.ts`)

**Replace** hardcoded `/Users/dalecarman` with dynamic paths:

- Add `import { homedir } from "node:os"` and `import { join, resolve } from "node:path"` (or use existing `os`/`path` if already imported)
- Build `BINARY_SOURCE_MAP` keys dynamically: `[join(homedir(), "bin", "gj")]`
- Build source/install values dynamically using `homedir()`
- Fix `normalizePath()` canonicalization order:
  1. Strip leading `@` first (some models prepend it)
  2. Then expand `~/` to `homedir()`
  3. Then `resolve()` to get absolute canonical path
- This order ensures `@~/bin/gj` correctly normalizes to `/Users/<whoever>/bin/gj`

### 5. Snapshot schema version change

Bump `snapshot.version` from `1` to `2`. The `compare` function does not enforce version matching (it just diffs key-value pairs), so old vs new snapshots will show key name changes as diff lines rather than silently matching wrong keys. No migration code needed — the tool is a diff engine, not a database.

## Verification

After implementation:

1. Run `tests/test-symlink-parity.sh` — must pass all assertions including the new section 7 (parity tool ↔ install.sh)
2. Run `agent-config-parity snapshot` — confirm all managed paths report `ok` status, no `drift_not_symlink_dir` or `missing`
3. Run `agent-config-parity report` — confirm clean output
4. Run `scripts/bootstrap.sh check` — confirm symlink section matches
5. Verify installed-binary-guard.ts has zero `/Users/` literals: `grep -c '/Users/' configs/pi/extensions/installed-binary-guard.ts` → 0
6. Verify README has no `~/.pi/agent/skills` entry: `grep 'pi/agent/skills' README.md` → empty
7. Verify snapshot version is `2`: `agent-config-parity snapshot | grep snapshot.version`

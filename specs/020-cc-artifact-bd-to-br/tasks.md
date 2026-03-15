---
title: "cc-artifact bd-to-br migration — Tasks"
date: 2026-03-14
bead: .agent-config-324
---

<!-- plan:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-14T13:52:17Z -->

# Tasks

## Phase 1: Create agent-artifact in tools-bin/

- [x] 1.1 Copy `~/.claude/scripts/cc-artifact` to `tools-bin/agent-artifact`
- [x] 1.2 Replace `command -v bd` with `command -v br` (line 141)
- [x] 1.3 Replace `bd show "$PRIMARY_BEAD"` with `br show "$PRIMARY_BEAD"` (line 142)
- [x] 1.4 Replace error message `"Run: bd list --status in_progress --json"` with br equivalent (line 144)
- [x] 1.5 Replace `"bd"` Python subprocess call with `"br"` (line 155)
- [x] 1.6 Replace `"bd update $PRIMARY_BEAD --status=in_progress"` warning with br equivalent (line 169)
- [x] 1.7 Change bd-not-found fallback (line 172) from warning+skip to hard error+exit 1
- [x] 1.8 Restructure: remove the `if command -v br` / `else` branch — br must be present, no else
- [x] 1.9 Add path self-validation before final `echo "$FILE_PATH"`: verify file exists, bead ID in directory name (when PRIMARY_BEAD set), filename ends with `_${MODE}.yaml`
- [x] 1.10 Mark executable: `chmod +x tools-bin/agent-artifact`
- [x] 1.11 Verify: `tools-bin/agent-artifact --help` runs successfully
- [x] 1.12 Verify: `rg '\bbd\b' tools-bin/agent-artifact` returns zero matches

## Phase 2: Move generate-reasoning.sh to tools-bin/

- [x] 2.1 Copy `~/.claude/scripts/generate-reasoning.sh` to `tools-bin/generate-reasoning.sh`
- [x] 2.2 Mark executable: `chmod +x tools-bin/generate-reasoning.sh`
- [x] 2.3 Verify: `tools-bin/generate-reasoning.sh` shows usage without errors (runs with no args)

## Phase 3: Update consumer commands

- [x] 3.1 `commands/finalize.md`: Update 3 path references (description line 2, prose line 7, Python invocation line 213) from `~/.claude/scripts/cc-artifact` to bare `agent-artifact`
- [x] 3.2 `commands/finalize.md`: Update Python invocation to use `shutil.which("agent-artifact")` to resolve path, with exact-path verification against `~/.agent-config/tools-bin/agent-artifact` (anti-shadow guard)
- [x] 3.3 `commands/finalize.md`: Remove inline Python validation block (path.exists, bead-in-path.name, endswith, frontmatter checks) — replace with trust-exit-code instruction
- [x] 3.4 `commands/finalize.md`: Remove/update the "IMPORTANT" validation instruction (lines 255-256)
- [x] 3.5 `commands/handoff.md`: Same changes as 3.1-3.4 (mirrored structure)
- [x] 3.6 `commands/checkpoint.md`: Same path reference updates as 3.1-3.2; remove validation block (simpler — no bead-in-path check but still has frontmatter duplication)
- [x] 3.7 `commands/checkpoint.md`: Update "IMPORTANT" instruction (lines 242-243)

## Phase 4: Update skill files

- [x] 4.1 `skills/meta/continuity-ledger/SKILL.md` line 17: `~/.claude/scripts/cc-artifact` → `agent-artifact`
- [x] 4.2 `skills/meta/git-commits/SKILL.md` line 40: `bash .claude/scripts/generate-reasoning.sh` → `generate-reasoning.sh`
- [x] 4.3 `skills/workflows/commit/SKILL.md` line 35: `bash .claude/scripts/generate-reasoning.sh` → `generate-reasoning.sh`
- [x] 4.4 `skills/workflows/commit/SKILL.v6.md`: same path update as 4.3
- [x] 4.5 `skills/workflows/describe-pr/SKILL.md` line 37: `bash .claude/scripts/aggregate-reasoning.sh` → `aggregate-reasoning.sh` (phantom script — path update only)
- [x] 4.6 `skills/workflows/recall-reasoning/SKILL.md` lines 34, 52: `bash .claude/scripts/search-reasoning.sh` → `search-reasoning.sh` (phantom script — path update only)

## Phase 5: Structural enforcement test

- [x] 5.1 Create `tests/test-no-agent-specific-paths.sh` following test-symlink-parity.sh structure
- [x] 5.2 Scan `commands/*.md` for `~/.claude/scripts/`, `os.path.expanduser("~/.claude/`, `$HOME/.claude/scripts/`
- [x] 5.3 Scan `skills/**/SKILL*.md` (includes SKILL.md, SKILL.v6.md, etc.) for same patterns (exclude `**/references/**` directories)
- [x] 5.4 Include equivalent patterns for `~/.codex/scripts/`, `~/.pi/agent/scripts/`
- [x] 5.5 Assert zero matches — each hit is a failing test with file:line detail
- [x] 5.6 Verify test passes after all other phases are complete

## Phase 6: Update existing tests

- [x] 6.1 Update `tests/test-continuity-lifecycle.sh` line 16: `CC_ARTIFACT="$HOME/.claude/scripts/cc-artifact"` → `CC_ARTIFACT="$(command -v agent-artifact)"`
- [x] 6.2 Run `bash tests/test-continuity-lifecycle.sh` to verify it passes with new path

## Phase 7: Cleanup and verification

- [x] 7.1 Run full test suite: `bash tests/test-no-agent-specific-paths.sh`
- [x] 7.2 Run existing test: `bash tests/test-symlink-parity.sh` (ensure no regressions)
- [x] 7.3 End-to-end: happy path with bead — `agent-artifact --mode finalize --bead <valid-bead-id> --no-edit --goal "test" --now "test" --outcome SUCCEEDED` → verify exit 0, bead ID in directory name of output path, file ends with `_finalize.yaml`
- [x] 7.4 End-to-end: invalid bead — `agent-artifact --mode finalize --bead nonexistent-xyz --no-edit --goal "test" --now "test" --outcome FAILED` → verify exit non-zero with "bead not found" message referencing `br`
- [x] 7.5 End-to-end: missing br — `env PATH=/usr/bin:/bin ~/.agent-config/tools-bin/agent-artifact --mode finalize --bead <valid-bead-id> --no-edit --goal "test" --now "test" --outcome FAILED` → verify exit non-zero with "br not found" error (invokes script by absolute path so it's found, but br is stripped from PATH)
- [x] 7.6 Remove `~/.claude/scripts/cc-artifact` from laptop
- [x] 7.7 Remove `~/.claude/scripts/generate-reasoning.sh` from laptop
- [x] 7.8 Verify: `rg '\.claude/scripts/' commands/*.md skills/**/SKILL*.md` returns zero matches (the resume-handoff line 284 contains `cc-artifact` in an artifact path, not a `~/.claude/scripts/` invocation — it won't match this pattern)

## Phase 8: Follow-up beads (not this spec)

- [x] 8.1 Filed bead `.agent-config-3on` → `specs/023-cc-synthesize-migration/`
- [x] 8.2 Filed bead `.agent-config-1gl` → `specs/024-missing-reasoning-scripts/`
- [x] 8.3 Filed bead `.agent-config-chj` → `specs/025-project-relative-script-deps/`

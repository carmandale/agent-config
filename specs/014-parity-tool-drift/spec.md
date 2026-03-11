<!-- Codex Review: APPROVED after 2 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: UNCHANGED -->
<!-- Revisions: none — spec requirements were not modified during review -->

# Spec 014: Parity Tool Drift — Managed Paths Don't Match install.sh

**Bead**: `.agent-config-kcx`
**Priority**: P2
**Type**: Bug

## Problem

The `tools-bin/agent-config-parity` tool is the cross-machine comparison surface for verifying that two machines (laptop + Mac mini) have identical agent configuration. It captures managed symlink paths, compares expected vs actual targets, and reports drift.

**The parity tool's managed path list has drifted from what `install.sh` actually creates.** This means:
- Parity reports **false drift** for paths that were intentionally removed
- Parity reports **false OK** for stale symlinks that shouldn't exist
- Parity **misses real drift** for paths it doesn't check at all
- One extension has **hardcoded user-specific paths** that break on the Mac mini

## Root Cause Analysis (§2.5)

**Symptom**: Parity tool reports incorrect managed path status.

**Why?** The parity tool's managed path list doesn't match install.sh's actual symlink creation.

**Why?** install.sh was refactored (Pi skills deduplication in spec 012, Gemini support added earlier) but the parity tool was never updated to match.

**Why?** There is no structural coupling between install.sh's symlink declarations and the parity tool's managed path declarations. They are independent lists that must be kept in sync manually. bootstrap.sh's symlink check list was updated correctly, but the parity tool was missed.

**Root cause**: Two independent lists (install.sh symlinks vs parity tool managed paths) that must stay in sync but have no shared source of truth or automated sync check.

## Findings

### Bug 1: `pi_commands` checks wrong path
- **File**: `tools-bin/agent-config-parity`, line 187
- **Code**: `record_managed_path "pi_commands" "$HOME/.pi/agent/commands" "$repo_dir/commands"`
- **Reality**: install.sh creates `$HOME/.pi/agent/prompts` (Pi uses "prompts" not "commands")
- **Impact**: On laptop, reports false "ok" because a stale `~/.pi/agent/commands` symlink exists from a pre-rename install. On a clean machine (or mini), reports "missing". Cross-machine compare shows spurious drift.
- **Confirmation**: bootstrap.sh correctly checks `$HOME/.pi/agent/prompts:$REPO_ROOT/commands`

### Bug 2: `pi_skills` checks path install.sh intentionally doesn't create
- **File**: `tools-bin/agent-config-parity`, line 197
- **Code**: `record_managed_path "pi_skills" "$HOME/.pi/agent/skills" "$repo_dir/skills"`
- **Reality**: install.sh explicitly does NOT create `~/.pi/agent/skills` — comment says "Do NOT create ~/.pi/agent/skills — it points to the same dir as ~/.agents/skills and causes pi to scan everything twice."
- **Impact**: Always reports `drift_not_symlink_dir` (because a real dir exists with one manual symlink inside). False drift on every parity run.
- **Confirmation**: bootstrap.sh correctly does NOT check this path

### Bug 3: `codex_skills` checks path Codex doesn't use for agent-config skills
- **File**: `tools-bin/agent-config-parity`, line 195
- **Code**: `record_managed_path "codex_skills" "$HOME/.codex/skills" "$repo_dir/skills"`
- **Reality**: install.sh never creates `~/.codex/skills`. Codex discovers agent-config skills from `~/.agents/skills/` (unified path). `~/.codex/skills` is Codex's own internal skill directory (contains `.system/`).
- **Impact**: Always reports `drift_not_symlink_dir`. False drift on every parity run.
- **Confirmation**: bootstrap.sh correctly does NOT check `~/.codex/skills`

### Bug 4: Missing `~/.agents/skills` check
- **File**: `tools-bin/agent-config-parity` — absent
- **Reality**: install.sh creates `~/.agents/skills` → `$SKILLS_DIR` (the unified Codex + Gemini skills path). bootstrap.sh checks it.
- **Impact**: If this symlink breaks on one machine, parity compare cannot detect it. Silent blind spot.

### Bug 5: Missing Gemini instructions check
- **File**: `tools-bin/agent-config-parity` — absent
- **Reality**: install.sh creates `~/.gemini/GEMINI.md` → `$AGENTS_MD`. bootstrap.sh checks it.
- **Impact**: Gemini instructions drift between machines is invisible to the parity tool.

### Bug 6: `installed-binary-guard.ts` hardcoded user paths
- **File**: `configs/pi/extensions/installed-binary-guard.ts`, lines 11-13, 20
- **Code**:
  ```typescript
  "/Users/dalecarman/bin/gj": { ... }
  return path.replace("~", "/Users/dalecarman");
  ```
- **Reality**: This file is deployed to both machines via `bootstrap.sh apply`. On Mac mini (user `chipcarman`), all paths are wrong — the guard would never match.
- **Impact**: The installed binary guard silently does nothing on the Mac mini. No error, just no protection.

## Out of Scope

- Gemini TOML converter's triple-quote edge case (cosmetic, no current commands trigger it)
- Stale `~/.pi/agent/commands` symlink cleanup (separate concern — install.sh doesn't have a stale symlink cleanup mechanism)
- Duplicated hook-path extraction logic between bootstrap.sh and verify-hooks.sh (maintenance risk, not a bug)
- Gemini converter's lack of stale .toml cleanup (no stale files exist currently)

---
title: "Migrate from bd to br (beads_rust)"
date: 2026-03-09
bead: .agent-config-17q
---

# Plan: Migrate from bd to br (beads_rust)

**Shape:** C (from shaping-transcript.md)
**Participants:** OakJaguar (proposer) × DarkMoon (challenger)

## Decision Summary

Shape B (bd v0.59.0+ Dolt) eliminated by bugs #2433, #2251, and daemon requirement. Shape A (stay pinned on bd v0.50.3) fails R2 — upstream dropped SQLite, no remediation path if macOS breaks the binary. Shape C (br) passes all requirements. R2 is the sole discriminator.

## Architecture

br is a drop-in replacement for bd's classic SQLite+JSONL architecture:
- Same `.beads/` directory, same `beads.db` filename, same `issues.jsonl` format
- Same ID format (`bd-` prefix + random hash) — auto-detected from existing JSONL
- No daemon, no auto-commit, no auto-hook-install (explicit-control design)
- `br sync --flush-only` = export DB→JSONL (identical to bd)
- `br sync --import-only` = import JSONL→DB (identical to bd)

### Critical Behavioral Difference

**Bare `br sync` (no flags) defaults to IMPORT-ONLY.** This is the opposite of `bd sync` which does a combined flush+import+git operation. All 12 occurrences of bare `bd sync` in AGENTS.md, CLAUDE.md, and commands must become `br sync --flush-only`, not `br sync`.

### Removed Capabilities (Not Needed)

- `--no-db` mode: br always uses SQLite. The `bd --no-db ready` fallback is unnecessary because br always has a DB after init.
- Daemon/pgrep/pkill: br has no background process. The CLAUDE.md contention block is dead code.
- `bd sync --resolve` LWW merge: br uses git-level JSONL conflict resolution + `br sync --import-only`. `br doctor` detects conflict markers.

### Flag Differences

| bd command | br equivalent | Notes |
|-----------|---------------|-------|
| `bd sync` (bare) | `br sync --flush-only` | ⚠️ bare br sync = import! |
| `bd sync --flush-only` | `br sync --flush-only` | Identical |
| `bd sync --import-only` | `br sync --import-only` | Identical |
| `bd import -i <file>` | `br sync --import-only` | br uses flag, not subcommand |
| `bd ready \|\| bd --no-db ready` | `br ready` | No fallback needed |
| `bd update <id> -d "text"` | `br update <id> --description "text"` | No `-d` short alias on update |
| `bd ready --json` | `br ready --json` | Identical |
| `bd doctor` | `br doctor` | Identical |
| `bd close <id> --reason="text"` | `br close <id> --reason "text"` | Identical (= vs space) |

## Blast Radius

### Git Hooks (2 files, 7 substitution points)

**pre-commit** (`.git/hooks/pre-commit`):
1. `command -v bd` → `command -v br`
2. `"bd command not found"` error message → `"br command not found"`
3. `bd sync --flush-only` → `br sync --flush-only`
4. `"Run 'bd sync --flush-only'"` error message → `"Run 'br sync --flush-only'"`

**post-merge** (`.git/hooks/post-merge`):
5. `command -v bd` → `command -v br`
6. `bd import -i "$BEADS_DIR/issues.jsonl"` → `br sync --import-only`
7. Error messages (2x) → reference br

### Instructions (2 files, 18 references)

**AGENTS.md** (7 refs, lines 189, 244, 245, 252–255):
- Line 189: `bd ready || bd --no-db ready` → `br ready` (remove fallback)
- Lines 244–245: `bd sync` → `br sync --flush-only`
- Lines 252–255: `bd ready/update/close/sync` → `br` equivalents

**CLAUDE.md** (11 refs, lines 239, 284, 339, 350, 353, 358–360, 375–376):
- Regular file, NOT a symlink to AGENTS.md
- Lines 358–360: REMOVE pgrep/pkill contention block entirely (br has no daemon)
- All `bd sync` bare → `br sync --flush-only`
- All `bd ready/update/close` → `br` equivalents

### Commands (15 files, ~40 references)

Heaviest: retro.md (10), worktree-task.md (5), finalize.md (4), standup.md (3), focus.md (3), fix-all.md (3).

Special cases:
- `retro.md`: `bd update $BEAD_ID -d "$CURRENT"` → `br update $BEAD_ID --description "$CURRENT"`
- `pr-create.md`: `bd update <bead-id> -d "PR: <url>"` → `br update <bead-id> --description "PR: <url>"`
- All bare `bd sync` → `br sync --flush-only`

### Skills (6 files, ~38 references — GLOBAL scope)

These are symlinked globally via install.sh. Edits affect ALL repos, not just agent-config:
- `ralph-tui-create-beads/SKILL.md` (18 refs)
- `agent-mail/SKILL.md` (13 refs)
- `bv/SKILL.md` (7 refs)
- `resume-handoff/SKILL.md` (5 refs)
- `plan/SKILL.md` (1 ref)
- `work/SKILL.md` (1 ref)

**Constraint:** Batch all skill edits into one commit. Do not edit while another repo has active agents using these skills.

### .beads/ Directory

**DB filename collision:** Both bd and br use `beads.db`. Running `br init` on a directory with bd's existing `beads.db` returns `AlreadyInitialized` error. `--force` would overwrite.

**Mitigation:** Rename bd's `beads.db` → `beads.db.bd-backup` before `br init`.

## Rollback Plan

- bd binary stays installed at `/opt/homebrew/bin/bd` — commands don't collide (`br` vs `bd`)
- `beads.db.bd-backup` preserves the original SQLite DB
- JSONL is never modified by `br init` — it's read-only import
- All doc/hook changes are revertable git commits
- If br import produces wrong data: revert hooks + docs, rename backup back to `beads.db`, resume using bd

## Risk Assessment

| Risk | Level | Mitigation |
|------|-------|------------|
| JSONL schema incompatibility | LOW | Verified at source code level — all fields match |
| `beads.db` collision | LOW | Rename-before-init, verified in Phase 1 throwaway |
| Bare `br sync` behavior | MITIGATED | All 12 occurrences explicitly changed to `--flush-only` |
| Mini transition window | LOW | Sequence-locked to one SSH session |
| Global skill edit timing | LOW | Batched into one commit, coordinated timing |
| br upstream abandonment | MEDIUM | 20K Rust + MIT license, read-and-patch capable for platform fixes |

## Machines

| Machine | bd status | br status | .beads/ state |
|---------|-----------|-----------|---------------|
| Laptop | v0.50.3 at /opt/homebrew/bin/bd | Not installed | Full: beads.db + issues.jsonl |
| Mini | v0.50.3 at /opt/homebrew/bin/bd | Not installed | Minimal: issues.jsonl only (no DB, synced via git) |

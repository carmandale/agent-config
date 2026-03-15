---
title: "cc-artifact bd-to-br migration gap"
date: 2026-03-14
bead: .agent-config-324
---

# cc-artifact bd-to-br migration gap

## Problem

The `cc-artifact` script (`~/.claude/scripts/cc-artifact`) still references `bd` (deprecated, removed fleet-wide in spec 013). When agents run `/finalize`, `/handoff`, or `/checkpoint`, the script warns "bd not found; skipping bead validation" — artifacts are created without bead validation, agents get confused, bead IDs are lost from artifact paths.

### Root Cause

Agent-config tracks and distributes *content* (commands, skills, instructions) but has no systematic tracking of the *executable dependencies* those commands call. Five scripts at `~/.claude/scripts/` are consumed by shared commands/skills but live outside the repo at a Claude-specific path. When spec 013 migrated `bd` → `br` across 43 repos, these scripts were invisible to the migration.

Secondary issues compound the problem:
- The `/finalize` and `/handoff` commands duplicate validation that has drifted from reality (`bead in path.name` checks filename, but bead is in directory name)
- The `cc-` naming prefix is Claude-specific but the scripts serve all agents
- Nothing prevents future shared commands from depending on unmanaged, agent-specific paths

## Selected Shape: C (from shaping)

Move all Category 1 scripts to `tools-bin/` (already on PATH), rename with agent-agnostic names, make the artifact script self-validating, add structural test to prevent recurrence. See `shaping-transcript.md` for full exploration including alternatives A and B.

## Requirements (from shaping)

| ID | Requirement |
|----|-------------|
| R0 | Bead validation works with `br` |
| R1 | Invalid bead IDs produce clear error — no silent skip |
| R2 | Path validation in consumers correct or removed if redundant |
| R3 | All Cat 1 scripts tracked in agent-config at agent-agnostic location |
| R4 | `br` CLI differences handled correctly |
| R5 | No `bd` references in session lifecycle scripts |
| R6 | Commands/skills use agent-agnostic invocation |
| R7 | Agent-agnostic names — no `cc-` prefix on shared tools |
| R8 | Automated test catches shared content depending on agent-specific paths |
| R9 | Validation lives in script, not duplicated in consumers |

## Scope

### In scope (Category 1 — user-home scripts with absolute paths)

| Script | Consumers | Action |
|--------|-----------|--------|
| cc-artifact | /finalize, /handoff, /checkpoint, continuity-ledger, resume-handoff | Rename → `agent-artifact`, fix bd→br, add self-validation |
| generate-reasoning.sh | git-commits, commit skill | Move to tools-bin/ |

### Deferred (separate beads — see tasks.md Phase 7)

| Script | Reason for deferral |
|--------|-------------------|
| cc-synthesize | Runtime dependency on `~/.claude/hooks/dist/synthesize-ledgers.mjs`. Moving to tools-bin/ without resolving the hooks dependency creates false sense of "managed." No shared consumers. |
| aggregate-reasoning.sh, search-reasoning.sh | Don't exist on disk (phantom references). Skills referencing them get path updates only (`.claude/scripts/X` → bare `X`), so they work when scripts are eventually created. |

### Out of scope (separate bead)

Category 2 scripts (project-relative via runtime harness): qlty_check.py, ast_grep_find.py, braintrust_analyze.py, etc. Different architectural problem.

## Acceptance Criteria

1. `rg '\bbd\b' tools-bin/agent-artifact` returns zero matches
2. `agent-artifact --mode finalize --bead <valid-id>` succeeds with bead ID in directory name
3. `agent-artifact --mode finalize --bead <invalid-id>` fails with clear `br`-based error
4. `agent-artifact` without `br` installed fails with actionable error (not silent skip)
5. `/finalize`, `/handoff`, `/checkpoint` commands reference bare `agent-artifact` — no `~/.claude/scripts/` path
6. No inline path validation in consumer commands — script exit code is the contract
7. `tests/test-no-agent-specific-paths.sh` passes — no agent-specific paths in shared content
8. `~/.claude/scripts/cc-artifact` removed (originals cleaned up)
9. Mini parity: `tools-bin/` scripts available via standard `git pull` update

<!-- gate:issue:completed pi/claude-sonnet-4 2026-03-14T13:11Z -->

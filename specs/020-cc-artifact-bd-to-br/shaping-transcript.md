---
shaping: true
---

<!-- shape:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-14T13:38:21Z -->

# cc-artifact bd-to-br — Shaping Transcript

**Participants**: user + pi/claude-sonnet-4
**Date**: 2026-03-14

---

## Problem

`cc-artifact` script at `~/.claude/scripts/` still references `bd` (deprecated Go beads tool, removed fleet-wide in spec 013). When agents run `/finalize`, `/handoff`, or `/checkpoint`, the script warns "bd not found; skipping bead validation" — causing artifacts to be created without proper bead validation. Additionally, the `/finalize` and `/handoff` commands have inline validation that checks `bead in path.name` but the bead ID is in the directory name, not the filename.

## Root Cause Analysis (5 Whys)

1. **Why did cc-artifact still use `bd`?** → Spec 013 (fleet migration) didn't touch it.
2. **Why didn't spec 013 touch it?** → It lives outside agent-config at `~/.claude/scripts/` — unmanaged.
3. **Why is it unmanaged?** → Agent-config tracks *content* (commands, skills, instructions) but has no systematic tracking of the *executable dependencies* those commands call.
4. **Why is there no tracking?** → Commands were written for Claude Code first, then moved to shared `commands/`, but their script dependencies stayed at `~/.claude/scripts/`. Nobody recognized the gap.
5. **Why did nobody recognize it?** → No enforcement. Nothing catches a shared command referencing an unmanaged, agent-specific path.

## Investigation: Full Scope of Unmanaged Scripts

Audit of `~/.claude/scripts/` found **two categories** of scripts referenced by shared commands/skills:

### Category 1: User-home scripts invoked by absolute path (`~/.claude/scripts/X`)

| Script | Consumers (shared) | `bd` refs |
|--------|-------------------|-----------|
| cc-artifact | /finalize, /handoff, /checkpoint, continuity-ledger, resume-handoff | 6 |
| cc-synthesize | (no shared refs found) | 0 |
| generate-reasoning.sh | git-commits, commit skill | 0 |
| aggregate-reasoning.sh | describe-pr skill | 0 |
| search-reasoning.sh | recall-reasoning skill | 0 |

### Category 2: Project-relative scripts via runtime harness (`scripts/X`)

| Script | Consumers |
|--------|-----------|
| qlty_check.py | qlty-check, implement-task |
| ast_grep_find.py | ast-grep-find |
| braintrust_analyze.py | braintrust-analyze, braintrust-tracing, validate-agent |
| recall_temporal_facts.py | system-overview |
| multi_tool_pipeline.py | skill-developer |

**Decision**: Category 2 is a different architectural problem (project-layout dependency) — separate bead.

## Requirements (R) — Final

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Bead validation works with `br` | Core goal |
| R1 | Invalid bead IDs produce clear error — no silent skip | Must-have |
| R2 | Path validation in consumers is correct (or removed if redundant) | Must-have |
| R3 | All Cat 1 scripts tracked in agent-config at agent-agnostic location | Must-have |
| R4 | `br` CLI differences handled correctly | Must-have |
| R5 | No `bd` references in session lifecycle scripts | Must-have |
| R6 | Commands/skills use agent-agnostic invocation | Must-have |
| R7 | Scripts have agent-agnostic names — no `cc-` prefix on shared tools | Must-have |
| R8 | Automated test catches shared content depending on agent-specific paths (recurrence prevention) | Must-have |
| R9 | Validation lives in script, not duplicated in consumers | Must-have |

### Requirement negotiation notes

- R3: User stated "cc-artifact must be managed. and it isn't/shouldn't be claude specific" — elevated from Undecided to Must-have and expanded scope.
- R7: User challenge "are we solving symptoms or root problems?" — naming is part of the architecture. `cc-` prefix on agent-agnostic shared tools is wrong.
- R8: Root-cause analysis showed no enforcement preventing recurrence. User: "fix the architecture."
- R9: Duplicated validation between script and consumers was the root cause of the path.name bug. Single source of truth.
- R7 (Category 2 scripts): Agreed as separate bead — Out of scope.

## Shapes Explored

### A: scripts/shared/ in agent-config, per-file symlinks to ~/.local/bin/

Rejected: unnecessary indirection. Creates symlinks into a second location when tools-bin/ already exists and is on PATH.

### B: scripts/shared/ with directory symlink to ~/.local/share/agent-scripts/

Rejected: invents new convention, uses full-path invocation instead of bare names.

### C: tools-bin/ with agent-agnostic naming, self-validating output, structural enforcement ← SELECTED

Reuses existing infrastructure. Zero new symlinks or path setup. Bare name invocation. Proven pattern (agent-config-parity already lives here).

## Fit Check: R × C

| Req | Requirement | Status | C |
|-----|-------------|--------|---|
| R0 | Bead validation works with `br` | Core goal | ✅ |
| R1 | Invalid bead IDs produce clear error — no silent skip | Must-have | ✅ |
| R2 | Path validation in consumers correct or removed | Must-have | ✅ |
| R3 | All Cat 1 scripts tracked, agent-agnostic location | Must-have | ✅ |
| R4 | `br` CLI differences handled | Must-have | ✅ |
| R5 | No `bd` references in lifecycle scripts | Must-have | ✅ |
| R6 | Commands/skills use agent-agnostic invocation | Must-have | ✅ |
| R7 | Agent-agnostic names | Must-have | ✅ |
| R8 | Test catches agent-specific path dependencies | Must-have | ✅ |
| R9 | Validation in script, not consumers | Must-have | ✅ |

## Selected Shape: C

| Part | Mechanism |
|------|-----------|
| **C1** | Rename and move scripts to `tools-bin/`: `cc-artifact` → `agent-artifact`, `cc-synthesize` → `agent-synthesize`, reasoning scripts keep names (no `cc-` prefix) |
| **C2** | `tools-bin/` already on PATH via `.zshenv` — zero new infrastructure |
| **C3** | `agent-artifact`: replace all 6 `bd` references with `br` equivalents (`command -v br`, `br show`, `br list --json`, etc.) |
| **C4** | `agent-artifact`: when `br` not installed, hard error with actionable message — no silent skip |
| **C5** | `agent-artifact`: self-validates output before printing path — verifies bead ID in directory name, file ends with `_<mode>.yaml`, frontmatter correct. Exit non-zero if validation fails. |
| **C6** | Remove duplicated validation from `/finalize`, `/handoff`, `/checkpoint` — consumers trust script's exit code. If exit 0, path guaranteed correct. |
| **C7** | Update all path references in commands/skills: `~/.claude/scripts/cc-artifact` → bare `agent-artifact`, same for other scripts |
| **C8** | Test: `tests/test-no-agent-specific-paths.sh` — scans commands/ and skills/ for hardcoded agent-specific paths in executable invocations. Fails if found. |
| **C9** | Cleanup: remove originals from `~/.claude/scripts/` after confirming tools-bin/ versions work |

## Why C and not A or B

- `tools-bin/` already exists, is on PATH, has precedent (`agent-config-parity`)
- No new symlinks, no new path conventions, no new infrastructure
- Bare name invocation — agents don't need to know where scripts live
- Self-validating output eliminates the class of bug where consumers drift from script behavior
- Structural test prevents recurrence of the "shared content → agent-specific path" gap

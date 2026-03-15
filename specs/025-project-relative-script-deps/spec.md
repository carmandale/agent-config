---
title: "Category 2 project-relative script dependencies"
date: 2026-03-15
bead: .agent-config-chj
---

<!-- issue:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-15T07:18:30Z -->

# Category 2 project-relative script dependencies

## Problem

Shared skills reference scripts via project-relative paths (`$CLAUDE_PROJECT_DIR/.claude/scripts/` or `./.claude/scripts/`). These assume every project has a `.claude/scripts/` directory containing specific Python and bash scripts. This is a different problem from spec 020 (which fixed user-home absolute paths) — these are project-layout dependencies.

## Affected Skills

| Skill | Scripts referenced | Path pattern |
|-------|-------------------|-------------|
| `skills/domain/math/math-unified/SKILL.md` | sympy_compute.py, z3_solve.py, pint_compute.py, math_router.py | `$CLAUDE_PROJECT_DIR/.claude/scripts/math/` |
| `commands/sim-run.md` | xcodebuild wrapper | `./.claude/scripts/xcodebuild` |
| `skills/tools/last30days/SPEC.md` | last30days.py | `~/.claude/skills/last30days/` |
| `skills/tools/gj-tool/scripts/capture-logs` | capture-logs | `~/.claude/skills/xcode-build/` |

## Why This Is Different from Spec 020

Spec 020 fixed scripts at **user-home absolute paths** (`~/.claude/scripts/cc-artifact`). Those are global — one copy serves all projects, so moving them to `tools-bin/` was clean.

Category 2 scripts use **project-relative paths** — they assume the script exists *within the current project*. This is architecturally different:
- The scripts may be project-specific (math scripts only make sense in projects with math deps)
- They use a runtime harness (`uv run python -m runtime.harness`)
- They depend on project-local Python environments (`.venv/`, `pyproject.toml`)

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Shared skills should not assume project-specific file layouts | Core goal |
| R1 | Scripts that ARE project-specific should be documented as dependencies | Must-have |
| R2 | Scripts that are actually universal should move to agent-config | Must-have |
| R3 | `$CLAUDE_PROJECT_DIR` references in shared skills are audited | Must-have |

## Open Questions

This definitely benefits from `/shape` first:
- Are these scripts genuinely project-specific, or are they universal tools that happened to be installed per-project?
- Should shared skills check for script existence and degrade gracefully?
- Is `$CLAUDE_PROJECT_DIR` the right mechanism, or should these use a different discovery pattern?

## Scope

### In scope
- Audit all project-relative script references in shared content
- Classify each: universal (move to tools-bin) vs project-specific (document as dependency)
- Fix the universal ones; add existence checks for project-specific ones

### Out of scope
- Rewriting the skills themselves
- Changes to the math/computation stack

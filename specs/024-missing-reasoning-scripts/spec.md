---
title: "Missing reasoning scripts (aggregate + search)"
date: 2026-03-15
bead: .agent-config-1gl
---

<!-- issue:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-15T07:18:30Z -->

# Missing reasoning scripts (aggregate + search)

## Problem

Two skills reference reasoning scripts that don't exist on disk:

| Skill | References | Script exists? |
|-------|-----------|----------------|
| `skills/workflows/describe-pr/SKILL.md` (line 37) | `aggregate-reasoning.sh main` | ❌ No |
| `skills/workflows/recall-reasoning/SKILL.md` (lines 34, 52) | `search-reasoning.sh "<query>"` | ❌ No |

Spec 020 updated the paths from `.claude/scripts/X` to bare `X`, so when these scripts are created in `tools-bin/`, the skills will work immediately.

The companion script `generate-reasoning.sh` (which creates per-commit reasoning files) DOES exist and was moved to `tools-bin/` in spec 020. The missing scripts are the consumers of what `generate-reasoning.sh` produces:
- `aggregate-reasoning.sh` — aggregates commit reasoning files for PR descriptions
- `search-reasoning.sh` — searches reasoning files by query

## Decision Needed

Two valid approaches:

1. **Create the scripts** in `tools-bin/` — they should aggregate/search the `.git/claude/commits/*/reasoning.md` files that `generate-reasoning.sh` produces
2. **Remove the skill references** — if the reasoning system is unused/abandoned, clean up the dead references

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Skills don't reference scripts that don't exist | Core goal |
| R1 | If created, scripts follow tools-bin/ conventions (agent-agnostic, on PATH) | Must-have |
| R2 | If removed, skills still have working alternatives for their use case | Must-have |

## Scope

### In scope
- Determine: create scripts or remove references
- Implement the chosen approach

### Out of scope
- Redesigning the reasoning system
- Changes to `generate-reasoning.sh`

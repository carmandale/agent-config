# Skills Infrastructure Issue: Missing Scripts

**Date:** 2026-01-22
**Status:** Partially Fixed

## Problem

Many skills in `~/.pi/agent/skills/cc3/` reference Python scripts and a `runtime.harness` module that don't exist anywhere. When agents load these skills in other repos, they fail because:

1. `scripts/xxx.py` - These relative paths don't resolve
2. `runtime.harness` - This Python module doesn't exist
3. `runtime.mcp_client` - The MCP wrapper infrastructure was never deployed

## Scope

**40 unique scripts referenced** across 100+ skill files:

| Script | References | Purpose |
|--------|------------|---------|
| `scripts/sympy_compute.py` | 88 | Symbolic math |
| `scripts/z3_solve.py` | 61 | SAT/SMT solving |
| `scripts/shapely_compute.py` | 40 | Geometry |
| `scripts/braintrust_analyze.py` | 21 | Tracing analysis |
| `scripts/ragie_query.py` | 16 | RAG queries |
| `scripts/perplexity_search.py` | 16 | Web search (**FIXED**) |
| `scripts/pint_compute.py` | 13 | Unit conversion |
| `scripts/qlty_check.py` | 10 | Code quality |
| `scripts/nia_docs.py` | 10 | Library docs |
| `scripts/math_tutor.py` | 10 | Math tutoring |

## Fixes Applied

### 1. `pplx` CLI (Perplexity) ✅

Created standalone CLI at `~/.local/bin/pplx`:
- Direct Perplexity API calls
- No runtime.harness dependency
- Works from any directory

Updated skills:
- `~/.pi/agent/skills/cc3/perplexity-search/SKILL.md`
- `~/.pi/agent/skills/cc3/research-agent/SKILL.md`

## Recommended Solutions

### Option A: Create Standalone CLIs (Recommended for high-use tools)

Like the `pplx` fix - create simple CLI wrappers in `~/.local/bin/`:

```bash
~/.local/bin/sympy-compute  # For sympy
~/.local/bin/z3-solve       # For Z3
~/.local/bin/pint-convert   # For unit conversion
```

### Option B: Create Central Scripts Repository

Put all scripts in a known location with a shim:

```bash
~/.agent-config/scripts/
├── sympy_compute.py
├── z3_solve.py
└── ...
```

Update skills to use: `python ~/.agent-config/scripts/xxx.py`

### Option C: Deprecate/Remove Broken Skills

Skills that depend on unavailable infrastructure should be:
1. Marked as deprecated in their description
2. Or removed if they can't be fixed

## Next Steps

1. [ ] Audit which scripts are actually needed vs theoretical
2. [ ] Create CLIs for the most-used scripts (sympy, z3, shapely)
3. [ ] Update skills to use absolute paths or CLIs
4. [ ] Remove or deprecate skills that can't be fixed
5. [ ] Document the pattern for adding new tool skills

## Root Cause

These skills appear to have been generated for a "Claude Code 3" (cc3) framework that included:
- A Python runtime harness
- MCP server wrappers
- A scripts directory structure

This framework was never fully deployed, leaving skills that reference phantom infrastructure.

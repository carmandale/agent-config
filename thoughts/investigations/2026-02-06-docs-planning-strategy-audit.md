# Investigation: Documentation & Planning Strategy Audit

**Date:** 2026-02-06  
**Status:** Complete  
**Outcome:** Unified strategy drafted for review

## Summary

The current documentation and planning approach across the 4 main GrooveTech repos (orchestrator, pfizer, ms, gmp) has grown organically, resulting in **5+ parallel systems** for specs/plans with inconsistent naming, locations, and tooling. This investigation catalogs the current state and proposes a canonical unified strategy.

## Symptoms

- Confusion about where to find/create specs and plans
- Multiple "homes" for the same type of document (`.agent-os/specs/`, `specs/`, `openspec/changes/`, `Docs/Specs/`, `thoughts/shared/plans/`, `plans/`)
- Inconsistent naming (`Docs/` vs `docs/`, feature IDs vs dates)
- Stale/copy-pasted template content in `.agent-os/product/` across repos
- Session artifacts split between `thoughts/shared/handoffs/`, `.handoff/`, `.checkpoint/`
- Master AGENTS.md defines *mechanics* (napkin, beads, ignored paths) but not *canonical planning lanes*

---

## Investigation Log

### Phase 1: AGENTS.md Analysis

**Hypothesis:** Master AGENTS.md defines where plans/specs should live  
**Findings:** It does NOT. Master AGENTS defines:
- Napkin convention (Section 0)
- Beads workflow (Section 5)
- Ignored paths including `plans/`, `.beads/`, `.learnings/`, `.handoff/`, `.checkpoint/`

**Conclusion:** Gap identified - no canonical planning lane defined globally

### Phase 2: Per-Repo Catalog via builder

**orchestrator/**
| Lane | Path | Status |
|------|------|--------|
| Human docs | `Docs/Plans/`, `Docs/Specs/` | Active |
| Ad-hoc plans | `plans/` | Active |
| Thoughts plans | `thoughts/shared/plans/` | Active |
| Agent-OS | `.agent-os/specs/` | Active |
| OpenSpec | `openspec/changes/` | Single change |
| Ralph | `.ralph/plans/` | Active |
| Handoffs | `thoughts/shared/handoffs/current.md` | Active |

**PfizerOutdoCancerV2/** 
| Lane | Path | Status |
|------|------|--------|
| SpecKit (CANONICAL) | `specs/<id>/{spec,plan,tasks}.md` | **Cleanest pattern** |
| Ad-hoc plans | `plans/` | Active |
| Docs plans | `Docs/plans/` | Active |
| Agent-OS planning | `.agent-os/planning/` | Planning dumps |
| Ralph | `.ralph/plans/` | Active |
| Handoffs | `thoughts/shared/handoffs/current.md` | Active |
| Checkpoints | `.checkpoint/` | Unique to Pfizer |

**groovetech-media-server/**
| Lane | Path | Status |
|------|------|--------|
| Human docs | `docs/specs/` | Active |
| Agent-OS | `.agent-os/specs/` | Active |
| OpenSpec | `openspec/changes/` | **Most mature** |
| Ad-hoc plans | `plans/` | Active |
| PRD-in-tasks | `tasks/` | Unusual pattern |
| Ralph-O | `.ralph-o/sessions/` | Active |
| Handoffs | `thoughts/shared/handoffs/` + `.handoff/` | **Duplicate lanes** |
| Napkin | `.claude/napkin.md` | Only repo with napkin |

**groovetech-media-player/**
| Lane | Path | Status |
|------|------|--------|
| Human docs | `Docs/design/`, `Docs/PLAN-*.md` | Mixed |
| Agent-OS | `.agent-os/specs/` | Active |
| OpenSpec | `openspec/` | Skeleton only |
| Thoughts plans | `thoughts/shared/plans/` | Active |
| Ralph-O | `.ralph-o/sessions/` | Active |
| Handoffs | `thoughts/shared/handoffs/current.md` | Active |

### Phase 3: Inconsistency Analysis

1. **Specs live in 4+ different homes** depending on repo
2. **Plans live in 4+ different homes** depending on repo
3. **Case inconsistency:** `Docs/` vs `docs/`
4. **ID format varies:** `001-slug` (Pfizer) vs `2025-01-02-slug` (Agent-OS) vs no ID (ad-hoc)
5. **OpenSpec maturity varies:** Active (MS) → Minimal (orchestrator) → Skeleton (GMP) → Absent (Pfizer)
6. **Handoff location varies:** `thoughts/shared/handoffs/` everywhere + `.handoff/` (MS only) + `.checkpoint/` (Pfizer only)
7. **Stale templates:** `.agent-os/product/README.md` appears copy-pasted without updates

---

## Root Cause

No canonical planning strategy was ever defined globally. Each repo evolved its own patterns based on:
- What tool was being used at the time (Ralph, OpenSpec, SpecKit)
- What seemed convenient for that feature
- Copy-paste from other repos without adaptation

The master AGENTS.md focused on *agent behavior* (napkin, alignment, git safety) but not *artifact location*.

---

## Recommendations

### Unified Strategy: 4 Canonical Lanes

#### Lane A — Feature Delivery (CANONICAL DEFAULT)
```
specs/<id>/
├── spec.md     # User-facing requirements + acceptance scenarios
├── plan.md     # Implementation plan + architecture decisions
├── tasks.md    # Ordered, checkable execution list
└── research.md # Optional - only when unknowns exist
```

**ID Format:** `<number>-<short-slug>` (e.g., `001-improve-app-loading`)

**Why:** Self-contained, diff-friendly, PR-reviewable, already proven in Pfizer.

#### Lane B — Change Proposals (OPT-IN HIGH RIGOR)
```
openspec/changes/<change-id>/
├── proposal.md
├── tasks.md
└── specs/<topic>/spec.md
```

**Use when:**
- Breaking changes (API/schema/protocol)
- Cross-repo behavior contracts
- Security/privacy/auth flows
- Operationally risky changes

#### Lane C — Scratch Notes (NON-CANONICAL)
```
plans/           # Drafts, explorations, working notes
thoughts/        # Session-specific thinking
```

Explicitly **not** the source of truth.

#### Lane D — Session Handoff Ledger (CANONICAL STATE)
```
thoughts/shared/handoffs/current.md
```

Single answer to "what's the current state?" across all repos.

### Deprecations

| Path | Action |
|------|--------|
| `.agent-os/specs/` | Archive-only; no new work |
| `.handoff/` | Migrate to `thoughts/shared/handoffs/` |
| `.agent-os/planning/` | Scratch only; real plans go to `specs/` |
| `Docs/PLAN-*.md` | Migrate to `specs/<id>/plan.md` |

### Where to Encode This

1. **Global master** (`~/.agent-config/instructions/AGENTS.md`): Define default conventions + lane selection criteria
2. **Repo-local** (`<repo>/AGENTS.md`): Declare which lanes are active, any exceptions

---

## Implementation Plan

### Week 0 (Immediate)
- [ ] Add "Canonical Planning Artifacts" section to master AGENTS.md
- [ ] Add "Planning Lanes" section to each repo's AGENTS.md

### Week 1
- [ ] New feature work starts in `specs/` in ALL repos
- [ ] Stop creating new `.agent-os/specs/` items

### Week 2-3
- [ ] Migrate top 3-5 active items per repo to `specs/`
- [ ] Standardize handoff lane (deprecate `.handoff/`)

### Week 4
- [ ] Add CI/pre-commit checks for spec structure
- [ ] Clean up stale `.agent-os/product/README.md` templates

---

## Drafted Changes

See companion file: `2026-02-06-canonical-planning-strategy.md`

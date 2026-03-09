---
title: "Codex Review: Migrate from bd to br (beads_rust)"
date: 2026-03-09
bead: .agent-config-17q
reviewer: gpt-5.3-codex (OpenAI Codex v0.107.0)
session_id: 019cd347-f7ee-7430-87d8-4070ae8639ce
review_id: c65fd30a
rounds: 4
verdict: APPROVED
---

# Codex Review: Spec 010 — bd → br Migration

## Summary

4-round iterative review of the bd → br (beads_rust) migration plan. Codex reviewed spec.md, plan.md, and tasks.md against the codebase (hooks, instructions, commands, skills, .beads/ data). All findings were addressed before approval.

## Round 1 — REVISE (6 findings)

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 1 | CRITICAL | Hooks not tracked in git — `.git/hooks/` doesn't propagate | Added tasks 18–19: tracked hook templates in `hooks/` + install.sh wiring |
| 2 | CRITICAL | Data-loss window — no `bd sync --flush-only` before renaming beads.db | Added task 11: mandatory pre-cutover flush |
| 3 | HIGH | Incomplete flag mapping — `bd tag`, `--tags`, `--sort updated` unmapped | Added `bd tag` → `br label add`, `--tags` → `--labels`, verified `--sort updated` identical |
| 4 | HIGH | Smoke test gaps — no `br create` (R1.1), status transition (R1.3), or conflict test (R4) | Expanded Phase 1 smoke tests with `br create`, `br update --status`, `br label add` |
| 5 | MEDIUM | Missed skills — `prompt-craft/SKILL.md` and `ntm/SKILL.md` have real bd refs | Added to skill update list; `open-sets/SKILL.md` marked false positive |
| 6 | MEDIUM | Bare `bd sync` count wrong (12 → 13) | Corrected throughout |

## Round 2 — REVISE (5 findings)

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 7 | HIGH | `--tags` → `--label` should be `--labels` (plural) | Fixed — verified from br CreateArgs source: `pub labels: Vec<String>` |
| 8 | MEDIUM | Issue count still 22 in Phase 1 task 6 | Changed to 24 |
| 9 | MEDIUM | ID format: plan says `bd-` prefix but data uses `.agent-config-*` | Corrected plan + smoke test |
| 10 | MEDIUM | No multi-clone conflict test | Added task 43 |
| 11 | LOW | Task numbering overlaps (Phase 2 and 3 both use 19–21) | Rewrote with clean sequential 1–48 |

## Round 3 — REVISE (2 findings)

| # | Severity | Finding | Resolution |
|---|----------|---------|------------|
| 12 | MEDIUM | Spec still says 22 issues in problem statement + acceptance | Fixed to 24 |
| 13 | MEDIUM | Plan blast-radius still says `--label` (singular) | Fixed to `--labels` (plural) |

## Round 4 — APPROVED

Both remaining inconsistencies verified fixed. No blocking issues remain.

## Key Improvements Made

1. **Hook propagation** now uses tracked templates + install.sh (root-cause fix, not local-only)
2. **Pre-cutover flush** eliminates data-loss window
3. **Complete flag mapping** including tag→label, --tags→--labels, --sort verified
4. **Expanded smoke tests** cover R1.1, R1.3, labels, and sort
5. **Multi-clone conflict test** added for R4 verification
6. **Issue count** consistent at 24 throughout all documents
7. **ID prefix** correctly documented as `.agent-config-*`
8. **48 tasks** cleanly numbered across 5 phases

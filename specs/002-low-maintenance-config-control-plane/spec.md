# Spec 002: Low-Maintenance Config Control Plane

Bead: `.agent-config-qxx`  
Created: 2026-02-28  
Status: Draft (planning)

## Summary

Define and execute a low-maintenance system for cross-machine agent configuration so setup and parity are reliable, auditable, and cheap to operate. The design should preserve the proven `~/.agent-config` source-of-truth pattern while reducing manual glue work.

## Problem

Current setup is functional but still custom-heavy:

1. Parity depends on bespoke scripts and operator discipline.
2. Tool/version synchronization requires manual attention.
3. External surfaces outside `~/.agent-config` (agent-local settings, optional plugin artifacts, shell path behavior) can drift silently.
4. Time spent maintaining this system competes with higher-value Vision Pro visual work.

## Goals

1. Minimize maintenance overhead while increasing reliability.
2. Keep a single canonical source for commands/instructions/skills.
3. Make new-machine bootstrap deterministic and repeatable.
4. Make drift visible with clear policy: fix, accept, or defer.
5. Preserve rollback paths and avoid risky big-bang migrations.
6. Enforce a North Star filter: no over-engineering, no AI-generated bloat, and clear focus protection for Vision Pro app work.

## Non-Goals

1. Rebuilding the entire environment in one step.
2. Forcing immediate full migration to Nix.
3. Reworking unrelated command/skill content.
4. Changing runtime behavior of existing agents without explicit need.
5. Building a tooling platform project that competes with product delivery time.

## Options to Evaluate

1. **Continue current approach** with incremental hardening only.
2. **Hybrid control plane**: keep `~/.agent-config` + add `chezmoi` (state orchestration), `brew bundle` (packages), and `mise` lockfile (runtime versions).
3. **Full replacement**: move to `nix-darwin` + `home-manager` for maximal reproducibility.

## Requirements

1. One-command bootstrap for a new machine with documented prerequisites.
2. Deterministic tool/runtime versions for parity-sensitive tools.
3. Drift detection that distinguishes managed, external, and system differences.
4. Explicit decision records for each intentional difference.
5. Safe rollback steps for every migration phase.
6. Bead-linked `spec/plan/tasks` artifacts with measurable exit criteria.
7. Every introduced tool or script must replace at least one recurring manual step and have an explicit owner.
8. Every phase must pass a North Star gate before continuing.

## Success Metrics

1. New-machine setup to functional parity in under 30 minutes without ad hoc edits.
2. Weekly parity check is <= 5 minutes and produces actionable output.
3. No critical parity regressions across laptop and mini for 30 days.
4. Maintenance work for config system stays below 1 hour per month.
5. Weekly config-maintenance time decreases by at least 50% from baseline.
6. Net maintenance surface does not grow beyond agreed complexity budget (documented in Phase 1 scorecard).

## Risks

1. Added tooling complexity could increase cognitive load.
2. Over-eager migration could break currently working workflows.
3. Secret/config handling may diverge across agents if not standardized.
4. Version pinning gaps can create false confidence.
5. AI-generated scaffolding could accumulate without real operational value.

## North Star Filter (Hard Gate)

Every phase must pass all checks below:

1. **Focus protection:** expected maintenance savings is material enough to protect product development time.
2. **Complexity budget:** change removes more operational complexity than it adds.
3. **No bloat:** no new automation is accepted without proven recurring use and owner accountability.
4. **Scoped blast radius:** changes remain in config/ops surface and do not spill into app implementation complexity.
5. **Fast rollback:** change can be reverted quickly to last known-good workflow.

## Acceptance Scenarios

1. **Fresh machine bootstrap**
   - Given a clean machine,
   - when bootstrap is run,
   - then managed surfaces and toolchain converge to policy-defined targets with no manual edits.

2. **Drift detection and classification**
   - Given two machines with small differences,
   - when parity checks run,
   - then differences are classified as managed drift, external drift, or expected system variance.

3. **Rollback**
   - Given a failed migration phase,
   - when rollback steps are applied,
   - then previous known-good setup is restored and revalidated.

4. **Low-maintenance operation**
   - Given normal weekly updates,
   - when update flow is executed,
   - then sync remains stable without bespoke troubleshooting.

5. **North Star compliance**
   - Given a proposed migration phase,
   - when the phase is reviewed against the hard-gate filter,
   - then it proceeds only if all North Star checks pass.

## Shaping Notes

1. Prefer additive migration over replacement.
2. Keep `~/.agent-config` as canonical content plane unless clear evidence justifies replacement.
3. Use decision gates between phases; stop escalation when goals are met.

# Tasks 002: Low-Maintenance Config Control Plane

Bead: `.agent-config-qxx`  
Spec: `specs/002-low-maintenance-config-control-plane/spec.md`  
Plan: `specs/002-low-maintenance-config-control-plane/plan.md`

## Phase 1: Baseline and Scoring

- [ ] Define parity policy classes (`managed`, `external`, `system`) and ownership rules.
- [ ] Create option scorecard with measurable thresholds.
- [ ] Capture current baseline metrics (setup time, maintenance time, failure modes).
- [ ] Confirm decision gates A/B/C with explicit pass/fail criteria.
- [ ] Add explicit North Star hard-gate checklist and complexity budget thresholds.

## Phase 2: Hybrid Prototype

- [ ] Prototype `chezmoi` for external surfaces only (no replacement of repo-managed symlinks).
- [ ] Create `Brewfile` baseline and validate `brew bundle check/install` on laptop + mini.
- [ ] Add `mise.toml` + lockfile for parity-critical runtimes/tools.
- [ ] Validate no regression in existing `install.sh` / `install-all.sh` behavior.
- [ ] Run North Star gate review and record pass/fail before advancing.

## Phase 3: Operationalization

- [ ] Add single bootstrap/update wrapper command.
- [ ] Add single validation command that includes parity and tool checks.
- [ ] Write rollback runbook for each migration component.
- [ ] Run 2-4 week pilot and log maintenance effort.
- [ ] Validate pilot against maintenance-time target and complexity budget.

## Phase 4: Decision and Adoption

- [ ] Publish final decision: keep current, adopt hybrid, or escalate to full replacement.
- [ ] If hybrid adopted, document canonical day-1/day-2 workflows.
- [ ] If replacement needed, open follow-up bead/spec for Nix path.
- [ ] Close bead with final evidence and residual risks.
- [ ] Include explicit North Star pass/fail verdict in closeout summary.

## Exit Criteria

- [ ] Selected approach demonstrably reduces maintenance burden.
- [ ] Bootstrap and parity workflows are deterministic and documented.
- [ ] Rollback path is validated.
- [ ] Remaining drift classes are intentional and owner-assigned.
- [ ] North Star hard-gate filter passes with evidence.

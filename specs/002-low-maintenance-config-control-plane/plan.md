# Plan 002: Low-Maintenance Config Control Plane

Bead: `.agent-config-qxx`  
Spec: `specs/002-low-maintenance-config-control-plane/spec.md`

## Strategy

Use a phased, reversible migration with explicit decision gates:

1. Baseline and score current system.
2. Prototype hybrid control plane without replacing current workflow.
3. Validate reliability and maintenance effort.
4. Adopt hybrid as default if it meets targets.
5. Keep full replacement (Nix) as optional later phase, not default path.

## North Star Guardrails

All phases are governed by these hard rules:

1. Prefer the smallest change that materially lowers maintenance cost.
2. Do not add a tool unless it replaces recurring manual work.
3. Reject AI-generated scaffolding that does not have clear operational ownership.
4. Stop escalation when success metrics are met; avoid "more tooling" by default.
5. Revert phase work if complexity increases faster than maintenance savings.

## Recommended Target Architecture (Default)

1. `~/.agent-config` remains canonical content source for commands/instructions/skills.
2. `chezmoi` manages machine-level config surfaces outside repo-managed symlinks.
3. `brew bundle` manages package/app/service installation baseline.
4. `mise` + lockfile manage runtime/tool version pinning.
5. `tools-bin/agent-config-parity` remains parity verification gate.

## Why This Target

1. Preserves current working architecture.
2. Adds standard tooling where custom scripts are currently fragile.
3. Avoids full Nix migration cost while still improving determinism.
4. Minimizes ongoing attention load.

## Phase Breakdown

### Phase 1: Baseline and Decision Model

1. Freeze current known-good state and parity policy classes (`managed`, `external`, `system`).
2. Define scorecard:
   - reliability
   - setup time
   - maintenance time
   - rollback complexity
3. Document explicit go/no-go criteria for each option.

**Decision Gate A:** Is current stack + small hardening enough to hit success metrics?
If yes, stop at minimal hardening and do not proceed to broader migration.

### Phase 2: Hybrid Prototype (Non-Destructive)

1. Introduce `chezmoi` in a sandboxed path for external surfaces only.
2. Add `Brewfile` baseline and validate `brew bundle check/install` flow.
3. Add `mise.toml` and lockfile for parity-critical tools.
4. Keep existing `install.sh` and `install-all.sh` unchanged during prototype.

**Decision Gate B:** Does hybrid reduce manual steps and drift without regressions?
If not, roll back prototype components and stay on current stack plus targeted fixes.

### Phase 3: Operationalization

1. Add a single bootstrap/update command wrapper.
2. Add a validation command that runs:
   - `chezmoi verify` (or equivalent)
   - `brew bundle check`
   - `mise` validation
   - `agent-config-parity` compare/report
3. Define incident/rollback runbook for failed updates.

**Decision Gate C:** Can this run reliably for 2-4 weeks with low maintenance overhead?
If pilot exceeds complexity budget or monthly maintenance target, fail gate and revert/escalate deliberately.

### Phase 4: Adopt or Escalate

1. If hybrid meets metrics, adopt as default and close project.
2. If hybrid misses metrics, evaluate deeper replacement path (`nix-darwin` + `home-manager`) as follow-up spec.

## Validation Plan

1. Test bootstrap on laptop and mini from same repo SHA.
2. Re-run parity after each phase and classify deltas.
3. Track operator time spent per weekly sync.
4. Confirm rollback works in one controlled failure drill.
5. Track North Star scorecard at each decision gate and record pass/fail evidence.

## Rollback Plan

1. Keep current `install.sh` + parity flow as fallback baseline.
2. Apply changes incrementally so any phase can be reverted independently.
3. Preserve pre-change snapshots and config backups.

## Open Questions

1. Which external files should be mandatory vs optional in parity policy?
2. Should plugin-generated surfaces be normalized or intentionally excluded?
3. Do we want strict version lockstep for all tools or only parity-critical ones?

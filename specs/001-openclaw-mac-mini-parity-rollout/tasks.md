# Tasks 001: OpenClaw Mac Mini Parity Rollout

Bead: `.agent-config-k2j`  
Spec: `specs/001-openclaw-mac-mini-parity-rollout/spec.md`  
Plan: `specs/001-openclaw-mac-mini-parity-rollout/plan.md`

## Phase 1: Baseline (Laptop)

- [x] Record baseline commit SHA for `~/.agent-config`.
- [x] Run `tools-bin/agent-config-parity snapshot --output /tmp/laptop.snapshot`.
- [x] Capture tool prerequisites (`bunx`, `bd`, shell environment essentials).
- [x] Review outside-of-repo surfaces from parity report (settings, plugin dirs, auth/tooling context).
- [x] Save baseline evidence artifact for later diff.

## Phase 2: Install (OpenClaw Mac Mini)

- [x] Ensure Mac mini repo checkout matches baseline SHA.
- [x] Run `./install.sh` and record output.
- [x] Run `./install-all.sh` if parity scope includes plugin-generated surfaces.
- [x] Capture any installer backup paths created during run.

## Phase 3: Verify Parity

- [x] Run `tools-bin/agent-config-parity snapshot --output /tmp/mini.snapshot` on Mac mini.
- [x] Run `tools-bin/agent-config-parity compare /tmp/laptop.snapshot /tmp/mini.snapshot`.
- [x] Run smoke checks for representative command/instruction/skill visibility per agent.
- [x] Classify each delta as expected, intentional, or blocking.

## Phase 4: Resolve Drift

- [ ] Document decisions for script-vs-doc-vs-laptop mismatches.
- [ ] Apply only minimal changes needed for parity (if required).
- [ ] Create follow-up bead(s) for non-blocking cleanup and modernization.
- [ ] Update rollout summary with explicit done/pending/blockers.

## Exit Criteria

- [ ] OpenClaw Mac mini is functionally aligned with laptop for agreed parity surfaces.
- [ ] Any remaining differences are explicitly documented and approved.
- [ ] Bead has linked spec path and current status reflects rollout state.

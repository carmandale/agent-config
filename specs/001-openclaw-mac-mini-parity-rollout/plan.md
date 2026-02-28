# Plan 001: OpenClaw Mac Mini Parity Rollout

Bead: `.agent-config-k2j`  
Spec: `specs/001-openclaw-mac-mini-parity-rollout/spec.md`

## Strategy

Roll out in four phases:

1. Capture current laptop truth (not assumptions).
2. Install on Mac mini using repo-provided installer flow.
3. Validate parity via a fixed verification matrix.
4. Resolve/document drift with explicit decisions and follow-up tasks.

## Architecture Context

1. `~/.agent-config` repository is canonical source for shared `commands/`, `instructions/`, and `skills/`.
2. `install.sh` is the primary symlink orchestrator.
3. `install-all.sh` is orchestration wrapper for `install.sh` + optional compound plugin install.
4. Each agent reads from different destination paths; parity requires path-level verification, not only script success.

## Implementation Approach

### Phase 1: Baseline Capture (Laptop)

1. Capture current branch + commit SHA of `~/.agent-config`.
2. Capture symlink/dir status for relevant targets:
   - `~/.pi/agent/{prompts,commands,AGENTS.md,skills}`
   - `~/.claude/{commands,CLAUDE.md,skills}`
   - `~/.codex/{prompts,AGENTS.md,skills}`
   - `~/.config/opencode/commands`
   - `~/.factory/{commands,droids}`
3. Capture key tool availability/versions (`bunx`, `bd`, etc.) used by install scripts.
4. Capture explicit outside-of-repo parity surfaces (agent-local config, plugin-generated dirs, auth/toolchain context).
5. Save baseline output as rollout evidence.

### Phase 2: OpenClaw Mac Mini Install

1. Clone or update `~/.agent-config` to same SHA as laptop baseline.
2. Run `./install.sh`, then `./install-all.sh` only if plugin surfaces are required for parity target.
3. Record install output and backup actions created by installer.

### Phase 3: Parity Verification

1. Run `tools-bin/agent-config-parity snapshot` on Mac mini.
2. Diff Mac mini matrix against laptop baseline.
3. Verify representative command/instruction/skill visibility on each agent surface.
4. Classify every difference:
   - expected and accepted
   - expected but requires script/docs update
   - unexpected and blocking

### Phase 4: Drift Decisions and Stabilization

1. For each script-vs-doc-vs-laptop mismatch, record one decision:
   - make Mac mini match current script behavior
   - change script to match desired parity
   - update README/instructions to match reality
2. Create follow-up bead(s) for non-blocking cleanup.
3. Publish final rollout summary with done vs pending.

## Technical Decisions (Initial)

1. Treat repo-defined installer behavior (`install.sh` + `install-all.sh`) as canonical; treat laptop state as observational input only.
2. Use scripted verification output as source of truth.
3. Avoid broad installer refactors during first migration unless required to reach parity.

## Validation Plan

1. Preflight checks pass on both machines.
2. `agent-config-parity compare` output produced and reviewed.
3. At least one command/instruction/skill smoke check passes per agent surface.
4. Outside-of-repo surfaces and tool versions are explicitly reviewed for parity.
5. Drift decisions captured with owner + follow-up path.

## Rollback and Recovery

1. Use installer-generated timestamped backups to restore prior state.
2. Re-run matrix checks after rollback to confirm return to baseline.
3. If plugin phase fails, continue with core symlink parity and log plugin as explicit blocker.

## Risks and Mitigations

1. **Risk:** Hidden local customizations on laptop.
   - **Mitigation:** baseline capture before Mac mini changes.
2. **Risk:** README/script mismatch causes wrong assumptions.
   - **Mitigation:** trust executable script outputs; file follow-up doc fix task.
3. **Risk:** `bunx` unavailable on Mac mini.
   - **Mitigation:** treat plugin setup as separate gate with explicit pass/fail reporting.

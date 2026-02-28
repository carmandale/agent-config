# Spec 001: OpenClaw Mac Mini Parity Rollout

Bead: `.agent-config-k2j`  
Created: 2026-02-28  
Status: Completed (rollout executed; follow-up cleanup bead opened)

## Summary

Install `~/.agent-config` on the OpenClaw Mac mini for the first time and achieve practical parity with the laptop setup for commands, instructions, and skills across supported agents.

This spec is planning-first and execution-ready: no installer behavior changes are required to begin rollout, but known script-vs-doc drift must be handled explicitly during implementation.

## Problem

`agent-config` has been used only on one machine so far. Moving to a second machine introduces setup risk:

- hidden machine assumptions (tooling, paths, plugin dependencies)
- unclear canonical targets where README and scripts differ
- no validated parity checklist between laptop and Mac mini

Without a shaped rollout plan, setup can appear successful while agent behavior still differs.

## Goals

1. Create a reproducible first-time install workflow for OpenClaw Mac mini.
2. Match laptop behavior for high-value surfaces:
   - command discovery/execution
   - instruction loading
   - skill availability
3. Produce evidence-based parity checks and rollback steps.
4. Keep rollout traceable through bead + spec/plan/tasks artifacts.

## Non-Goals

1. Redesigning the entire multi-agent architecture.
2. Refactoring all historical command/skill workflow drift in this phase.
3. Publishing new plugin architecture changes beyond what is needed for parity.

## Current-State Findings (from repo investigation)

1. `install.sh` is the core symlink installer for commands, instructions, and skills.
2. `install-all.sh` wraps `install.sh` and then attempts optional compound-plugin installation.
3. There are known parity-sensitive drift points to resolve during rollout:
   - README claims vs `install.sh` actual symlink behavior for some surfaces.
   - potential instruction target mismatch (`AGENTS.md` vs `CLAUDE.md`) depending on desired parity mode.
   - potential path mismatch for Pi command surface (`prompts` vs `commands`) depending on current laptop state.

## Scope

### In Scope

1. Baseline capture of active laptop symlink/dir matrix and key tool versions.
2. First-time OpenClaw Mac mini install using canonical repo scripts.
3. Parity verification matrix across Pi, Claude, Codex, OpenCode, and Factory-relevant surfaces.
4. Decision logging where README/script/laptop behavior diverge.
5. Rollback and recovery instructions for mislinked paths.

### Out of Scope

1. Large cleanup of legacy skills or command internals unrelated to parity setup.
2. Feature development inside unrelated repositories.

## Requirements

1. A new bead exists and remains linked to planning artifacts.
2. `spec.md`, `plan.md`, and `tasks.md` exist at `specs/001-openclaw-mac-mini-parity-rollout/`.
3. Install workflow includes explicit preflight checks (repo revision, required binaries, writable target dirs).
4. Verification compares laptop baseline to Mac mini state using deterministic checks.
5. Final rollout report captures:
   - what matched
   - what intentionally differs
   - what was blocked and why
6. Parity workflow includes explicit visibility into surfaces outside `.agent-config` and tool version sync status.

## Acceptance Scenarios

1. **Baseline Capture**
   - Given the laptop setup,
   - when baseline capture commands are run,
   - then command/instruction/skill targets are recorded for parity comparison.

2. **First-Time Install**
   - Given a clean or unknown OpenClaw Mac mini agent config state,
   - when install workflow is executed,
   - then symlinks/directories are created without destructive data loss.

3. **Parity Verification**
   - Given install completion on Mac mini,
   - when parity verification matrix is run,
   - then high-value surfaces match laptop behavior or have documented intentional deltas.

4. **Drift Handling**
   - Given README/script/laptop drift is detected,
   - when the rollout completes,
   - then each drift point has an explicit decision (adopt script, patch script, or patch docs) and owner.

5. **Rollback**
   - Given a broken or unexpected post-install state,
   - when rollback steps are applied,
   - then previous configuration can be restored from backups and revalidated.

## Risks

1. False parity confidence if only install exit status is checked.
2. Hidden local customizations on laptop not represented in repo scripts.
3. Partial plugin installation when `bunx` or network is unavailable.
4. Link target mismatch causing behavior divergence despite “successful” install.

## Shaping Notes

1. Favor deterministic checks over manual spot checks.
2. Separate “make Mac mini match laptop now” from “clean up architecture globally.”
3. Keep initial rollout small and auditable; defer broad cleanup to follow-up beads.

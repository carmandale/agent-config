---
title: "Machine Parity Verification Skill"
date: 2026-03-09
bead: .agent-config-8i7
---

# 011: Machine Parity Verification

## Problem

We run agent infrastructure across two machines — a laptop (Dales-MacBook-Pro-M4-6) and a Mac mini (chips-mac-mini, SSH alias `mini-ts`). Both run pi, pi-messenger, agent-config, openclaw, and shared tooling. When things drift — different pi versions, stale pi-messenger, agent-config out of sync, missing tools — subtle breakdowns occur that are hard to diagnose.

Today, verifying parity is manual: SSH in, run a bunch of commands, visually compare. This session alone required ~10 separate `ssh mini-ts "..."` invocations to check pi version, pi-messenger version, install method, git state, etc. There's no single command that answers "are my machines in sync?"

## Requirements

| ID | Requirement |
|----|-------------|
| R1 | Single command produces a side-by-side comparison of laptop vs Mac mini state |
| R2 | Checks cover: pi version, pi packages, agent-config HEAD + branch, pi-messenger version + source, openclaw version, node version |
| R3 | Clear PASS/DRIFT/MISSING indicators per check |
| R4 | Works from the laptop (SSH to mini for remote checks) |
| R5 | Output is useful to both humans (readable) and agents (parseable) |
| R6 | Extensible — easy to add new checks without rewriting the core |
| R7 | Fast — should complete in <10 seconds (parallel SSH where possible) |

## Acceptance Scenarios

### AS-1: Clean Parity
**Given** both machines are fully in sync  
**When** the parity check runs  
**Then** all checks show PASS and the summary says "All checks passed."

### AS-2: Version Drift
**Given** the Mac mini has pi v0.56.1 and the laptop has pi v0.57.1  
**When** the parity check runs  
**Then** the pi version check shows DRIFT with both versions displayed.

### AS-3: Missing Tool
**Given** a checked tool is not installed on one machine  
**When** the parity check runs  
**Then** that check shows MISSING with which machine lacks it.

### AS-4: Agent Invocation
**Given** an agent asks "are my machines in sync?"  
**When** the agent runs the skill  
**Then** the output is structured enough for the agent to reason about which specific items are drifted.

## Constraints

- Must work over SSH (`ssh mini-ts`) — no assumptions about shared filesystem
- No new dependencies on the Mac mini (use standard CLI tools)
- Lives in `~/.agent-config` (shared across all agents via symlinks)
- Should be both a bash script (direct execution) and a skill (agent-guided)

## Non-Goals

- Automatically fixing drift (that's a separate concern — this is diagnosis only)
- Checking application-level state (database, running processes, etc.)
- Monitoring/alerting (this is on-demand, not continuous)

## Prior Art

- `install.sh` verifies symlinks but only on the local machine
- `post-commit` hook checks symlink integrity after commits
- The `mini-sync` skill documents the dual-push pattern but doesn't verify state
- Spec 001 (openclaw mac-mini parity rollout) did a one-time parity check but wasn't reusable

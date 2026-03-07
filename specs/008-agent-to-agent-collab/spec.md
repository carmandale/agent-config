---
title: "Agent-to-Agent Autonomous Collaboration Protocol"
date: 2026-03-07
bead: .agent-config-ezz
---

# Agent-to-Agent Autonomous Collaboration Protocol

## Problem

Four workflow commands (`/plan`, `/shape`, `/codex-review`, `/implement`) require two participants — a second perspective prevents corner-cutting. Today there is no mechanism for an agent to spawn a collaborator. The only path is manual: the user starts two pi sessions, joins both to the mesh, and hopes they coordinate.

This breaks at scale. The user has 9+ projects where agents need to collaborate autonomously (Mode 2). An agent working alone hits a two-agent gate and has no way to:

1. Launch a second agent with a specific role and context
2. Exchange structured messages in a turn-based protocol
3. Know when collaboration is complete
4. Dismiss the collaborator when done

## What Exists Today (traced by JadeRaven in pi-messenger repo)

The plumbing is all there in Crew:

- **Subprocess spawning**: `crew/agents.ts:runAgent()` and `crew/lobby.ts:spawnLobbyWorker()` spawn `pi --mode json --no-session -p "<prompt>"` with the pi-messenger extension, a known name via `PI_AGENT_NAME`, and model/thinking config.
- **Auto-join mesh**: crew-worker.md protocol Phase 1 calls `pi_messenger({ action: "join" })`.
- **Turn-triggering messages**: `store.ts:sendMessageToAgent()` writes to inbox, FSWatcher picks it up, `index.ts:deliverMessage()` calls `pi.sendMessage({ triggerTurn: true, deliverAs: "steer" })` — this injects the message as a steering prompt that starts a new LLM turn. Works in `--mode json`.
- **Graceful shutdown**: `SHUTDOWN_MESSAGE` sent to inbox, crew-worker.md handles it (release reservations, exit). SIGTERM fallback after `work.shutdownGracePeriodMs` (default 30s).
- **Name generation**: `generateMemorableName()` + `PI_AGENT_NAME` env — spawning agent knows the collaborator's name immediately.

## What's Missing

### M1: `spawn` / `dismiss` tool actions

An agent inside a pi session cannot call `runAgent()` — it's an internal function, not exposed as a tool action. Need:

```
pi_messenger({ action: "spawn", agent: "crew-collaborator", prompt: "..." })
→ { name: "ZenPhoenix", pid: 12345 }

pi_messenger({ action: "dismiss", name: "ZenPhoenix" })
→ sends SHUTDOWN_MESSAGE, waits grace period, SIGTERM
```

~100 lines wrapping existing `runAgent()` machinery. Reuses `discoverCrewAgents()`, `generateMemorableName()`, `pushModelArgs()`, `resolveThinking()`, `registerWorker()`, the JSONL progress pipeline.

### M2: Message budget for collaborators

Default budget is 10 messages per session (`chatty` level). A structured 4-phase collaboration needs 8-16+ messages per agent. The budget exists to stop workers from chatting instead of working — but collaborators exist to chat. The messages ARE the work.

Options (not mutually exclusive):
- **Immediate**: Config override in `~/.pi/agent/pi-messenger.json` to raise `chatty` budget
- **Proper**: Exempt collaborators from budget in `executeSend()` (check `PI_CREW_COLLABORATOR=1` env var)
- **Middle ground**: New `collaborative` coordination level with budget of 50-100

### M3: Collaboration agent definitions

Agent `.md` files that define the collaboration protocol — what role the collaborator plays, what phases to follow, how to signal completion. Lives alongside existing `crew-worker.md`, `crew-planner.md`, etc. Zero code — pure convention.

### M4: Collaboration protocol convention

Structured message format so agents know where they are in the workflow:
- Phase markers: `[PHASE:research]`, `[PHASE:challenge]`, `[PHASE:revise]`, `[PHASE:agree]`
- Completion signal: `[COMPLETE]` with summary of what was produced
- Role awareness: proposer vs challenger, driver vs navigator

## Two Modes

### Mode 1 — Interactive (user present)
User starts two pi sessions manually, joins both to mesh, they collaborate with user oversight. Works today with manual coordination. The protocol improvements (M3, M4) make this more structured.

### Mode 2 — Autonomous (no user)
Agent hits a two-agent gate, spawns a collaborator via `spawn` action, they ping-pong through the protocol, produce artifacts, agent dismisses collaborator. User sees one pi session; collaborator is invisible infrastructure.

**End-to-end Mode 2 flow:**
1. User runs `pi "do /plan on spec 007"`
2. Agent reads `/plan` command, detects two-agent requirement
3. Agent calls `pi_messenger({ action: "spawn", agent: "crew-challenger", prompt: "..." })`
4. Collaborator auto-joins mesh with known name
5. Agents exchange structured messages through phases
6. They produce `plan.md` + `tasks.md` in the spec directory
7. Agent calls `pi_messenger({ action: "dismiss", name: "..." })`
8. Agent presents final artifacts to user

## Requirements

### R1: spawn action
A running agent can spawn a collaborator subprocess by calling `pi_messenger({ action: "spawn", ... })`. Returns the collaborator's name and pid. The collaborator auto-joins the mesh and is ready to receive messages.

### R2: dismiss action
A running agent can gracefully shut down a collaborator by calling `pi_messenger({ action: "dismiss", name: "..." })`. Sends shutdown message, waits grace period, falls back to SIGTERM.

### R3: Collaborator message budget
Collaborators spawned via `spawn` are not subject to the standard worker message budget. The budget constraint is for workers who should be coding, not chatting. Collaborators' entire job is message exchange.

### R4: Agent definitions for collaboration roles
At least two agent `.md` files: one for a "challenger" role (stress-test, find gaps, raise risks) and one for a "proposer" role (research, propose approach, revise based on feedback). Follows existing crew agent `.md` format with frontmatter for model/tools/thinking.

### R5: Structured protocol convention
A documented message format with phase markers, role assignments, and completion signals that agents follow during collaboration. Convention, not enforcement — agents can read and follow it.

### R6: Works from CLI
The entire Mode 2 flow is triggerable from a single `pi "<task>"` command. No manual setup of multiple terminals or mesh joins required.

## Acceptance Criteria

- [ ] An agent can call `pi_messenger({ action: "spawn", agent: "crew-challenger", prompt: "..." })` and get back a named collaborator on the mesh
- [ ] The spawned collaborator can receive messages via `send` and responds with `triggerTurn` steering
- [ ] The spawning agent can dismiss the collaborator cleanly via `pi_messenger({ action: "dismiss", ... })`
- [ ] Collaborators are not blocked by the standard message budget
- [ ] Agent `.md` files exist for at least challenger and proposer roles
- [ ] A documented protocol convention exists for phase-structured collaboration
- [ ] The `/plan` command can use this to satisfy its two-agent gate autonomously
- [ ] `pi "do /plan on specs/008-agent-to-agent-collab"` works end-to-end without user intervention for the collaboration step

## Scope Boundary

**In scope:** spawn/dismiss actions, message budget fix, agent definitions, protocol convention, updates to workflow commands to use spawn.

**Out of scope:** Changes to Crew's hierarchical task orchestration, changes to the Swarm system, UI/overlay for watching collaborations, cross-repo collaboration (collaborator works in the same repo as the spawning agent).

## Where the code changes live

All code changes are in the **pi-messenger** repo, not agent-config:
- `handlers.ts` — new `spawn`/`dismiss` action handlers, budget exemption
- `crew/agents.ts` — may need to export/refactor `runAgent()` for reuse
- `crew/agents/` — new `.md` files for collaboration roles

Convention changes are in **agent-config**:
- `commands/plan.md`, `commands/shape.md`, etc. — updated to use spawn when no second participant is available
- Protocol documentation

---
title: "Tasks — Agent-to-Agent Collaboration"
date: 2026-03-07
bead: .agent-config-ezz
---

# Tasks

## Layer 1: Immediate Unblock (no code)

- [ ] **Task 1: Raise message budget via config**
  Create/update `~/.pi/agent/pi-messenger.json` with `messageBudgets.chatty: 100`. Verify by starting a pi session, joining mesh, and confirming higher budget in send output.

## Layer 2: Core Primitives (pi-messenger repo)

- [ ] **Task 2: Extract reusable spawn logic from crew/agents.ts**
  Refactor `runAgent()` so the subprocess spawning, env setup, JSONL pipeline, and worker registration are callable from both the existing Crew work handler and the new `spawn` action. No behavior change to existing Crew functionality.
  _Depends on: nothing_

- [ ] **Task 3: Implement `spawn` action handler**
  New case in `handlers.ts` action switch. Accepts `{ action: "spawn", agent: "<name>", prompt: "<context>" }`. Uses extracted spawn logic from Task 2. Sets `PI_CREW_COLLABORATOR=1` env. Returns `{ name, pid }`. Include mesh-join wait (poll `list` until name appears, 30s timeout).
  _Depends on: Task 2_

- [ ] **Task 4: Implement `dismiss` action handler**
  New case in `handlers.ts`. Accepts `{ action: "dismiss", name: "<name>" }`. Sends `SHUTDOWN_MESSAGE`, waits grace period, SIGTERM fallback, unregisters worker. Returns confirmation.
  _Depends on: Task 2_

- [ ] **Task 5: Exempt collaborators from message budget**
  In `executeSend()` (handlers.ts ~line 280), check `process.env.PI_CREW_COLLABORATOR === '1'` and skip budget enforcement. Collaborators' messages ARE the work.
  _Depends on: nothing (can parallel with Tasks 2-4)_

- [ ] **Task 6: Test spawn → message → dismiss lifecycle**
  Integration test: spawn a collaborator, send it a message, verify it responds (triggerTurn activates), send another exchange, dismiss it, verify process exits. Test edge cases: spawn failure, dismiss of already-exited process, message to not-yet-joined collaborator.
  _Depends on: Tasks 3, 4, 5_

## Layer 3: Protocol Convention

- [ ] **Task 7: Write crew-challenger.md agent definition**
  In `pi-messenger/crew/agents/`. Defines the challenger role: receive proposals, challenge assumptions, find gaps, raise risks, demand evidence. Phase-aware (research → challenge → revise → agree). Read-only tool access. Follows existing crew agent `.md` format.
  _Depends on: nothing (can parallel with Layer 2)_

- [ ] **Task 8: Write crew-proposer.md agent definition**
  In `pi-messenger/crew/agents/`. Defines the proposer role: research codebase, propose approach, revise based on challenges, produce final artifacts. Full tool access. Leads the collaboration flow.
  _Depends on: nothing (can parallel with Layer 2)_

- [ ] **Task 9: Document collaboration protocol**
  Message format with phase markers (`[PHASE:research]`, `[PHASE:challenge]`, `[PHASE:revise]`, `[PHASE:agree]`, `[COMPLETE]`). Termination criteria. Role negotiation. Written into the agent `.md` files, not a separate doc.
  _Depends on: Tasks 7, 8_

## Layer 4: Workflow Command Integration (agent-config repo)

- [ ] **Task 10: Update /plan to auto-spawn collaborator**
  When no second participant is present, `/plan` detects this and spawns a `crew-challenger` via the `spawn` action. Sends research findings, exchanges through protocol phases, dismisses when complete. Falls back to user-as-second-participant if spawn fails.
  _Depends on: Tasks 3, 4, 9_

- [ ] **Task 11: Update /shape to auto-spawn collaborator**
  Same pattern as Task 10 but for the shaping workflow. Spawns a collaborator for the shaping methodology's two-perspective requirement.
  _Depends on: Tasks 3, 4, 9_

- [ ] **Task 12: Update /implement to auto-spawn collaborator**
  Same pattern for the driver/navigator implementation workflow.
  _Depends on: Tasks 3, 4, 9_

- [ ] **Task 13: End-to-end test — autonomous /plan**
  Run `pi "do /plan on specs/008-agent-to-agent-collab"` and verify: agent detects two-agent gate, spawns collaborator, they exchange structured messages through all phases, produce plan.md + tasks.md, collaborator is dismissed, artifacts are presented to user. No manual intervention required.
  _Depends on: Task 10_

## Dependency Graph

```
Task 1 (config) ─── standalone, do first

Task 2 (extract spawn logic)
├── Task 3 (spawn action) ──┐
├── Task 4 (dismiss action) ├── Task 6 (integration test)
                             │
Task 5 (budget exemption) ──┘

Task 7 (challenger.md) ──┐
Task 8 (proposer.md)  ───┼── Task 9 (protocol doc)
                          │
                          ├── Task 10 (/plan update) ── Task 13 (e2e test)
                          ├── Task 11 (/shape update)
                          └── Task 12 (/implement update)
```

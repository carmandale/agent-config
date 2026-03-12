---
title: Deterministic Multi-Agent Collaboration
bead: .agent-config-ef7
date: 2026-03-11
status: blocked
blocked_on: pi-messenger spec 004 (blocking collab exchange)
shaped_with: JadeDragon (pi-messenger repo agent)
---

# Deterministic Multi-Agent Collaboration

## Problem

Multi-agent workflow commands (`/shape`, `/plan`, `/implement`) require two participants. The spawning agent launches a collaborator via `pi_messenger({ action: "spawn" })`, which returns after ~30 seconds (mesh join). The collaborator then takes 3–10 minutes to read files, analyze the codebase, and compose its first response.

During this gap, the spawning agent is in an ambiguous state — the tool call returned, but there's nothing to act on. LLMs are forward-biased: after a tool call returns, they must produce output or make another call. "Do nothing for 10 minutes" is not a reliable instruction.

**Observed failure modes:**
- Agent pings the collaborator before it's ready, disrupting its work
- Agent dismisses the collaborator after 1–2 minutes, assuming it's stuck
- Agent abandons the collaboration and proceeds solo, violating the two-agent gate
- Agent attempts to send messages before the first reply, causing confused exchanges
- All of the above waste 3–10 minutes of compute and force restarts

## Root Cause

The collaboration API exposes **async primitives** (spawn, then separately wait for messages via FSWatcher → triggerTurn) to an agent that can only work **synchronously** (tool call → result → next action). The gap between "spawn returned" and "first message arrives" is a dead zone where the agent has no deterministic action to take.

This is not a prompting problem. No amount of warnings, napkin entries, or command restructuring eliminates the architectural mismatch. The fix must be structural.

## Requirements (Confirmed via Shaping with JadeDragon)

| ID | Requirement | Priority |
|----|-------------|----------|
| R0 | Spawning agent receives collaborator's first response without entering an ambiguous waiting state | Core goal |
| R1 | Subsequent message exchanges are deterministic (send → receive is atomic) | Must-have |
| R2 | User sees live activity indicators (elapsed time + evidence of work) during blocking waits, updated periodically | Must-have |
| R3 | Spawning agent can cancel a blocking wait (Ctrl+C / session shutdown) | Must-have |
| R4 | Collaborator crash during wait produces useful error with log context, not a hang | Must-have |
| R5 | No changes required to existing workflow commands (/shape, /plan, /implement) | Must-have |
| R6 | ~~Works across all runtimes~~ | Deferred (collaborators are pi-only today) |
| R7 | Timeout produces clear error with actionable guidance, not silent fallback | Must-have |
| R8 | Multiple concurrent collaborators don't interfere with each other's blocking waits | Must-have |
| R9 | All agent communication flows through the inbox (mesh coherence) | Must-have |

## Selected Shape: A — Blocking Tool Call with Inbox Polling

Two shapes were explored. Shape B (protocol-level RPC via stdin/stdout) was rejected because it requires a parallel IPC channel that breaks the mesh invariant (R9) and creates asymmetric communication (inbox for outbound, stdout for inbound) that fails R8.

Shape A blocks inside the tool call's `execute()` by polling the spawner's own inbox directory for a message from the specific collaborator. It uses existing infrastructure (inbox files, polling patterns from `pollUntilReady`/`pollUntilExited`), adds ~80–100 lines, and preserves mesh coherence.

### Parts

| Part | Mechanism |
|------|-----------|
| **A1** | `executeSpawn` polls inbox for first message after mesh join, returns message content in result |
| **A2** | `executeSend` polls inbox for reply from collaborator after writing outbound message |
| **A3** | Watcher filter: `blockingCollaborators` set on state, installed BEFORE mesh polling begins; `deliverMessage` skips messages from blocked senders; cleanup in finally/abort handler. Filter is per-call (active only during blocking polls), not per-collaborator-lifetime. |
| **A4** | Progress: `onUpdate` fires periodically with elapsed time + log file size delta |
| **A5** | Cancellation: `signal.addEventListener('abort', ...)` breaks polling loop, cleans up filter set, dismisses collaborator |
| **A6** | Crash detection: polling loop checks `proc.exitCode`, reads log tail on crash, returns immediately with error |
| **A7** | Timeout: configurable max wait, returns error result with `timeout: true` and actionable message |

### Breadboarded Flows

**Flow 1 — Spawn + First Message (A1, A3, A4, A7)**
```
Agent calls: spawn({ agent: "crew-challenger", prompt: "..." })
TUI: Spawning... → joined mesh → Waiting... 2m45s (log: +38KB) → 4m10s (log: +71KB)
Returns: { name, agent, firstMessage: "I've read the spec. Three concerns: ..." }
         + send/dismiss affordance instructions (no "wait patiently" language)
```

**Flow 2 — Send + Reply (A2, A4)**
```
Agent calls: send({ to: "CalmNova", message: "[PHASE:revise] Updated approach..." })
TUI: Sent → Waiting for reply... 45s (log: +8KB)
Returns: content includes reply text inline; details has { delivered, reply }
```

**Flow 3 — Timeout (A7)**
```
TUI: Waiting... 9m30s → Timeout after 10m
Returns: { error: "timeout", name, message: "Did not respond within 10m. Dismiss and retry." }
```

**Flow 4 — Crash (A6)**
```
TUI: Waiting... 2m10s → Process exited (code 1)
Returns: { error: "collaborator_crashed", exitCode, logTail: "Error: ...", message }
```

**Flow 5 — User Cancellation (A5)**
```
TUI: Waiting... 1m40s → [Ctrl+C]
Returns: { error: "cancelled", name, message: "Cancelled. CalmNova dismissed." }
Cleanup: filter removed, process dismissed, registry cleaned
```

**Flow 6 — Peer Send (unchanged)**
```
Agent calls: send({ to: "FastLion", message: "FYI" })
Returns immediately: { delivered: true }
No blocking. Routing based on collaborator registry lookup.
```

## Dependency: pi-messenger spec 004

The implementation lives entirely in pi-messenger. JadeDragon is driving `specs/004-blocking-collab-exchange/`. The shaping session was conducted jointly — full transcript saved as `shaping-transcript.md` in their spec directory.

## Agent-Config Scope (This Spec)

Once pi-messenger spec 004 ships:

### 1. Simplify `docs/agent-collaboration.md`

Remove patience-policing language that becomes unnecessary:
- The "⚠️ Wait for the collaborator's first message" warning block
- "Do not ping. Silence means 'processing,' not 'stuck.'"
- "Do not dismiss before 5 minutes minimum."
- The `session.toolCalls` / `session.tokens` monitoring instructions
- The "To check if actually stuck" guidance

Replace with documentation of the synchronous behavior:
- `spawn` returns with the collaborator's first response (no waiting needed)
- `send` to collaborators returns with the reply (no waiting needed)
- Timeout/error handling per the confirmed flows above

### 2. Update napkin entries

- Item 1 ("Agents will try subagent, interactive_shell...") — keep, still valid
- Item 2 ("'Two participants required' not specific enough") — keep, still valid
- Item 3 ("Agents skip workflow gates under forward momentum") — keep, broader issue
- Item 4 ("Message budget too low") — archive, already fixed

### 3. Verify commands work without changes (R5)

`/shape`, `/plan`, `/implement` all use `pi_messenger({ action: "send", to: ... })`. With default-block for collaborators, verify they work without prompt modifications.

## Acceptance Criteria

- [ ] pi-messenger spec 004 shipped and available
- [ ] `agent-collaboration.md` updated: patience-policing removed, synchronous behavior documented
- [ ] `/shape` tested: spawn + full exchange completes without manual intervention
- [ ] `/plan` tested: spawn + full exchange completes without manual intervention
- [ ] `/implement` tested: spawn + full exchange completes without manual intervention
- [ ] Napkin updated: timing-related items archived
- [ ] No changes required to `/shape`, `/plan`, `/implement` command files (R5 verified)

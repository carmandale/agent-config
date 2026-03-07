---
title: "Implementation Plan — Agent-to-Agent Collaboration"
date: 2026-03-07
bead: .agent-config-ezz
---

# Implementation Plan

## Approach

Build in three layers, each independently useful:

1. **Layer 1 (immediate unblock):** Config override to raise message budget. Zero code. Enables Mode 1 today.
2. **Layer 2 (core primitive):** `spawn`/`dismiss` actions in pi-messenger. ~100 lines wrapping existing crew machinery. Enables Mode 2.
3. **Layer 3 (protocol):** Agent `.md` definitions and convention documentation. Updates to workflow commands. Makes Mode 2 structured and repeatable.

## Layer 1: Message Budget Config

**File:** `~/.pi/agent/pi-messenger.json` (or project-level `.pi/messenger/crew/config.json`)

Override `messageBudgets.chatty` from 10 to 100. The `loadCrewConfig()` in `crew/utils/config.ts` deep-merges user config over defaults. No code change. Immediate effect.

This unblocks Mode 1 (user starts two agents manually) right now.

## Layer 2: spawn/dismiss Actions (pi-messenger repo)

### spawn action

**Handler location:** `handlers.ts` — new case in the action switch.

**Implementation:** Wraps existing `runAgent()` from `crew/agents.ts`:
1. Look up agent definition via `discoverCrewAgents()` — find the `.md` file by name
2. Generate name via `generateMemorableName()`, set `PI_AGENT_NAME` in env
3. Set `PI_CREW_COLLABORATOR=1` in env (for budget exemption)
4. Build args: `pi --mode json --no-session -p "<prompt>" --extension <pi-messenger-path>`
5. Add model args via `pushModelArgs()`, thinking via `resolveThinking()`
6. Spawn subprocess, track via `registerWorker()`
7. Return `{ name, pid }` to calling agent

**Budget exemption:** In `executeSend()` (handlers.ts line 280), before the budget check:
```typescript
if (process.env.PI_CREW_COLLABORATOR === '1') {
  // Collaborators exist to exchange messages — skip budget
} else {
  const budget = crewConfig.messageBudgets?.[crewConfig.coordination] ?? 10;
  // ... existing check
}
```

### dismiss action

**Handler location:** `handlers.ts` — new case in the action switch.

**Implementation:** Wraps existing shutdown pattern from `crew/agents.ts`:
1. Look up worker by name in registry
2. Send `SHUTDOWN_MESSAGE` to their inbox
3. Wait `work.shutdownGracePeriodMs` (default 30s)
4. If still running, SIGTERM
5. `unregisterWorker()`
6. Return confirmation

### Refactoring needed in crew/agents.ts

`runAgent()` may need its spawn logic extracted into a reusable function that both the existing Crew work handler and the new `spawn` action handler can call. The key pieces to extract:
- Process spawning with env setup
- JSONL progress pipeline attachment
- Worker registration/lifecycle

## Layer 3: Protocol Convention

### Agent definitions (pi-messenger repo, `crew/agents/`)

**crew-challenger.md** — Stress-tester role:
- Frontmatter: model, tools (read-only — no writes), thinking level
- Protocol: receive proposal, challenge assumptions, find gaps, raise risks, demand evidence
- Phase awareness: knows about research → challenge → revise → agree flow
- Completion: signals `[AGREE]` when satisfied or `[BLOCK]` with specific objections

**crew-proposer.md** — Research-and-propose role:
- Frontmatter: model, tools (full access), thinking level
- Protocol: research codebase, propose approach, revise based on challenges
- Phase awareness: leads the flow, incorporates challenger feedback
- Completion: produces final artifacts when both agree

### Protocol convention (documented in agent .md files, not enforced in code)

Message format:
```
[PHASE:research] Here are my findings on the codebase...
[PHASE:challenge] Three concerns with this approach...
[PHASE:revise] Updated approach addressing your concerns...
[PHASE:agree] Looks solid. Producing artifacts now.
[COMPLETE] plan.md and tasks.md written to specs/008-agent-to-agent-collab/
```

Termination: Proposer sends `[COMPLETE]`, challenger confirms or raises final objections. Spawning agent sees `[COMPLETE]` in message and calls `dismiss`.

### Workflow command updates (agent-config repo, `commands/`)

Update `/plan`, `/shape`, `/implement` to detect when no second participant is available and auto-spawn:

```
If you are the only participant and the user hasn't indicated they're the second agent:
1. Call pi_messenger({ action: "spawn", agent: "crew-challenger", prompt: "..." })
2. Send your research findings to the collaborator
3. Exchange messages through the protocol phases
4. When [COMPLETE], call pi_messenger({ action: "dismiss", ... })
5. Present artifacts to user
```

## Risk Assessment

**Low risk:** Layer 1 (config override) — no code, immediately reversible.

**Medium risk:** Layer 2 (spawn/dismiss) — wrapping existing functions that are battle-tested by Crew. Main risk is subprocess lifecycle edge cases (what if spawn fails, what if collaborator crashes mid-conversation, what if the spawning agent's session ends before dismissing).

**Low risk:** Layer 3 (protocol) — pure convention in markdown files. Wrong protocol is annoying but not breaking.

## Open Questions

1. **Should the spawning agent wait for the collaborator to join the mesh before sending first message?** Probably yes — poll `list` until the name appears, with a timeout.
2. **What happens if the spawning agent's pi session ends/crashes before dismissing?** The collaborator would become an orphan. Stuck detection (existing feature) would eventually flag it, but cleanup should be more immediate.
3. **Should collaborators have file write access?** The challenger role probably shouldn't write to the repo — they challenge, the proposer writes. But the proposer role might need writes for producing artifacts.
4. **Cross-repo collaboration** — out of scope for now, but eventually an agent in repo A might need a collaborator grounded in repo B (like JadeRaven helping from pi-messenger). That's a harder problem.

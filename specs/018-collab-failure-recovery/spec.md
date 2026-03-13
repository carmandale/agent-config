---
title: "Collaboration Failure Recovery Protocol"
date: 2026-03-12
bead: .agent-config-1vk
depends_on:
  - pi-messenger spec 004 (blocking collab exchange)
  - pi-messenger spec 005 (deterministic collab timeout / stall detection)
  - .agent-config-ef7 (spec 016 — deterministic multi-agent collaboration)
---

# 018 — Collaboration Failure Recovery Protocol

## Problem

When a collaborator becomes unresponsive during a multi-agent workflow (`/shape`, `/plan`, `/implement`), the driver agent has no graduated recovery strategy. Every failure immediately escalates to the user.

### Observed failure (verbatim)

```
pi_messenger — Message sent to BrightUnion, but no reply within 300s.
               Collaborator is still running — retry or dismiss.
(96 messages remaining)

pi_messenger — Message sent to BrightUnion, but no reply within 300s.
               Collaborator is still running — retry or dismiss.
(95 messages remaining)
```

The driver agent:
1. Retried the message — 300s timeout again (10 min total burned)
2. Spent internal reasoning debating whether to retry, dismiss, or ask user
3. Re-read collaboration docs, considered constraints, tried to decide autonomously
4. Eventually asked the user with 3 options, none of which were automatic
5. User had to stop their work to make a decision the system should have made

### Root cause (5 whys)

1. **Why did the user get interrupted?** The driver agent couldn't decide what to do after two timeouts.
2. **Why couldn't it decide?** The collaboration doc says "On ANY failure — tell the user and wait." No graduated strategy exists.
3. **Why is there no graduated strategy?** The error handling table lists actions per error type but the bold-text override ("ANY failure → ask user") contradicts the table's "retry once for timeout" guidance.
4. **Why does the override contradict the table?** It was written as a safety rail against agents proceeding solo — a valid concern. But "don't proceed solo" and "don't recover automatically" are different constraints that got conflated.
5. **Why were they conflated?** The recovery protocol was never designed — it was a warning bolted onto an error table. The two-agent gate (legitimate) got entangled with error recovery (needs automation).

**Separation:** The two-agent gate says "don't do the work solo." It does NOT say "don't retry spawning a collaborator." Automatic retry/respawn before user escalation is perfectly compatible with the gate — you're still getting a second perspective, just from a fresh instance.

## What exists today

### Error handling in `agent-collaboration.md`

| Error | Guidance |
|-------|----------|
| `timeout` | "Retry spawn once. If it fails again, tell the user." |
| `crashed` | "Report the error to user with the log tail." |
| `cancelled` | "Collaborator is dismissed, report cancellation." |

Then a bold override: **"On ANY collaboration failure — tell the user and wait for guidance."**

The table says "retry once for timeout." The override says "ask the user for everything." The agent in the observed failure followed the override — it retried the *send* (not the spawn), failed, and escalated.

### What pi-messenger specs 004/005 will change

Once shipped, the error taxonomy becomes:

| Error | Signal | Source |
|-------|--------|--------|
| `stall` | Log file unchanged for `stallThresholdMs` | spec 005 |
| `crashed` | `proc.exitCode !== null` | spec 004 |
| `cancelled` | `signal.aborted` (user Ctrl+C) | spec 004 |

Fixed wall-clock timeouts are removed. `timeout` is replaced by `stall`. The blocking call model means `send` returns with the reply or an error — no ambiguous waiting.

### What spec 016 will change

Updates `agent-collaboration.md` to remove patience-policing language and document the synchronous behavior. But spec 016's scope doesn't include defining the recovery protocol — it defers to this spec.

## Solution

Define a graduated recovery protocol that automates what it can and only escalates to the user when automation is exhausted. The protocol respects the two-agent gate — recovery always involves getting a second perspective, never proceeding solo.

### Recovery table (replaces current error handling section)

| Error | Automatic recovery | Escalation |
|-------|-------------------|------------|
| **stall** (send) | 1. Dismiss stalled collaborator. 2. Spawn fresh collaborator with same role + accumulated context. 3. Resume from the last completed phase. | If respawn also stalls → ask user. |
| **stall** (spawn) | 1. Dismiss stalled collaborator. 2. Retry spawn once (same prompt). | If retry also stalls → ask user. |
| **crashed** (send) | 1. Log tail preserved in error. 2. Spawn fresh collaborator with same role + accumulated context. 3. Resume from last completed phase. | If respawn also crashes → ask user with both log tails. |
| **crashed** (spawn) | 1. Retry spawn once. | If retry also crashes → ask user with log tail. |
| **cancelled** | No recovery — user initiated. Report and stop. | — |

### Key principles

1. **One automatic retry/respawn before user escalation.** Not zero (current behavior). Not infinite (runaway compute). Exactly one.
2. **Respawn carries context.** The replacement collaborator gets the accumulated context from the conversation so far — research findings, phase completions, agreements reached. It doesn't start from scratch.
3. **Phase markers enable recovery.** The `[PHASE:research]`, `[PHASE:challenge]`, `[PHASE:revise]`, `[PHASE:agree]` markers in the collaboration protocol aren't just labels — they're recovery checkpoints. The driver knows what phase was completed and can resume from the right point.
4. **Cancelled is final.** User pressed Ctrl+C. Don't retry, don't ask. Report and stop.
5. **The two-agent gate is never bypassed.** "Retry with a fresh collaborator" is not "proceed solo." The gate is preserved.

### What changes where

| File | Change |
|------|--------|
| `docs/agent-collaboration.md` § Error handling | Replace contradictory table + override with the recovery table above |
| `docs/agent-collaboration.md` § Error handling | Remove the bold "ANY failure → ask user" override |
| `docs/agent-collaboration.md` § Error handling | Add "context accumulation" guidance — how to build the respawn prompt with prior phases |
| `commands/shape.md` | Add: "If collaborator fails, follow recovery protocol in agent-collaboration.md" (one line) |
| `commands/plan.md` | Same one-line addition |
| `commands/implement.md` | Same one-line addition |

### Context accumulation template

When respawning after a stall/crash, the driver builds the prompt:

```
You are replacing a previous collaborator who became unresponsive.

Completed work so far:
- [PHASE:research] Driver findings: <summary>
- [PHASE:challenge] Previous collaborator's challenges: <summary of what they raised before stalling>

Resume from [PHASE:revise] — address the challenges above and continue.

Spec: specs/NNN-slug/spec.md
```

This ensures the fresh collaborator doesn't re-do completed phases.

## Requirements

| ID | Requirement | Priority |
|----|-------------|----------|
| R1 | Stall/crash during `send` triggers automatic dismiss + respawn (one attempt) before user escalation | Must-have |
| R2 | Stall/crash during `spawn` triggers automatic retry (one attempt) before user escalation | Must-have |
| R3 | Respawn prompt includes accumulated context from completed phases | Must-have |
| R4 | `cancelled` error is final — no recovery, no retry | Must-have |
| R5 | Two-agent gate is never bypassed — recovery always involves a second perspective | Must-have |
| R6 | Workflow commands reference the recovery protocol (not duplicate it) | Must-have |
| R7 | Max one automatic retry/respawn per failure — no unbounded loops | Must-have |

## Acceptance criteria

- [ ] `agent-collaboration.md` error handling section replaced with graduated recovery table
- [ ] Bold "ANY failure → ask user" override removed
- [ ] Context accumulation guidance added with template
- [ ] `/shape`, `/plan`, `/implement` commands reference recovery protocol
- [ ] Recovery table covers all error types from pi-messenger specs 004/005 (stall, crashed, cancelled)
- [ ] No scenario exists where the agent proceeds solo after a failure (two-agent gate preserved)
- [ ] No scenario exists where the agent retries more than once without user involvement

## Scope boundary

**In scope:** Recovery protocol definition, `agent-collaboration.md` updates, command cross-references.

**Out of scope:**
- pi-messenger code changes (those are specs 004/005)
- Spec 016's doc simplification (patience-policing removal) — this spec adds the recovery protocol, spec 016 removes the noise
- Automatic model escalation on retry (e.g., retry with a stronger model) — future enhancement
- Multi-collaborator recovery (only one collaborator at a time today)

## Dependencies

This spec **can be partially implemented now** (the protocol definition and command references) but the error types (`stall` vs. `timeout`) depend on pi-messenger specs 004/005 shipping. The recovery table is written against the post-004/005 error taxonomy.

**Sequencing:**
1. pi-messenger spec 004 ships (blocking calls)
2. pi-messenger spec 005 ships (stall detection)
3. Spec 016 ships (doc simplification, patience-policing removal)
4. **This spec ships** (recovery protocol, replaces error handling section)

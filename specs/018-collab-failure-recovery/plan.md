---
title: "Collaboration Failure Recovery Protocol — Implementation Plan"
date: 2026-03-12
bead: .agent-config-1vk
---

# Plan — 018 Collaboration Failure Recovery Protocol

## Overview

Single-file documentation change to `docs/agent-collaboration.md`. No code changes. No other files modified. The document is protocol — agents read and follow it as-is — so precision in the replacement text is the deliverable.

**Dependency gate:** Do not implement until pi-messenger specs 004 (blocking collab exchange) and 005 (deterministic stall detection) have merged to main. The recovery table uses the `stall` error type from spec 005. Implementing before that merge creates a doc that references behavior that doesn't exist.

## What changes

Three surgical edits to `docs/agent-collaboration.md`, all in a single atomic commit:

### Edit 1: Spawn return type (line 62)

**Current:**
```
Returns: `{ name, agent, firstMessage: "..." }` on success. On failure: `{ error: "timeout" | "crashed" | "cancelled" }` with details.
```

**Replacement:**
```
Returns: `{ name, agent, firstMessage: "..." }` on success. On failure: `{ error: "stall" | "crashed" | "cancelled", name }` with details.
```

Changes: `"timeout"` → `"stall"`, added `name` to the error result (per ZenWolf's commit `90fb7b6` — both spawn and send stall results now include a top-level `name` field).

### Edit 2: Error handling section (lines 102–110)

**Current (9 lines):**
```markdown
### Error handling

| Error | Meaning | What to do |
|-------|---------|------------|
| `timeout` | Collaborator didn't respond within the time limit | Retry spawn once. If it fails again, tell the user. |
| `crashed` | Collaborator process died (log tail included in error) | Report the error to user with the log tail. |
| `cancelled` | User pressed Ctrl+C during the wait | Collaborator is dismissed, report cancellation. |

**On ANY collaboration failure — timeout, crash, or spawn error — tell the user and wait for guidance. Do NOT proceed solo. Do NOT offer to "just do it yourself." The two-agent gate exists because single-agent work skips the scrutiny that catches real defects. A failed collaboration is not permission to bypass the gate — it's a problem the user needs to know about.**
```

**Replacement:**

```markdown
### Error handling and recovery

When a `spawn` or `send` returns an error, follow the graduated recovery protocol below. The principle: **one automatic recovery attempt before user escalation. Never proceed solo.**

| Error | Context | Automatic recovery | If recovery fails |
|-------|---------|-------------------|-------------------|
| `stall` | spawn | Dismiss stalled collaborator. Retry spawn once (same prompt). | Ask user — include stall duration. |
| `stall` | send | Dismiss stalled collaborator. Spawn fresh collaborator with same role + accumulated context (see below). Resume from last completed phase. | Ask user — include stall duration and phase reached. |
| `crashed` | spawn | Retry spawn once. | Ask user — include log tail from both attempts. |
| `crashed` | send | Spawn fresh collaborator with same role + accumulated context. Resume from last completed phase. | Ask user — include log tail and phase reached. |
| `cancelled` | any | No recovery — user initiated. Report and stop. | — |

**Recovery is not proceeding solo.** Dismiss + respawn gets a fresh second perspective with accumulated context — the two-agent gate is preserved. After one automatic recovery attempt, if the replacement collaborator also fails, tell the user and wait for guidance. Do NOT proceed with work using only one perspective. Do NOT offer to "just do it yourself." The gate exists because single-agent work skips the scrutiny that catches real defects.

**Max rounds guard on respawn:** The 5-exchange limit before escalation (§ Max rounds guard) applies per-collaborator. Respawning resets the count — the fresh collaborator hasn't seen the prior exchanges and needs a full round budget to be effective.

### Context accumulation for respawn

When respawning after a stall or crash mid-conversation, include accumulated context so the replacement doesn't redo completed work.

**Phase completion rules:**
- A phase is **completed** if the collaborator sent a message with a `[PHASE:X]` marker AND the driver incorporated the content (responded to it, used it in decisions, or built on it).
- A phase is **partial** if the collaborator stalled mid-response or sent incomplete content. Include partial content verbatim — don't summarize what might be truncated.
- If no phases were completed (stall on first response), no context accumulation is needed — retry with the original prompt.

**Summary construction:** Each completed phase gets 2–4 bullet points capturing key conclusions and decisions — not the full transcript, not a single sentence.

**Worked example — stall at challenge phase:**

The driver completed research and sent findings to the collaborator. The collaborator sent a `[PHASE:challenge]` response raising three concerns, then the driver sent a revision addressing those concerns. The collaborator stalled while reviewing the revision (no `[PHASE:agree]` received).

Respawn prompt:
```
You are replacing a previous collaborator who became unresponsive during a /plan session.

Completed phases:
- [PHASE:research] Driver found 3 insertion points in handlers.ts (lines 45, 112, 189),
  existing retry pattern in crew/utils/retry.ts, and no tests covering the error path.
- [PHASE:challenge] Previous collaborator raised:
  1. The retry pattern in retry.ts uses exponential backoff but the recovery table
     specifies immediate retry — inconsistent.
  2. No rollback path if the respawn succeeds but produces incompatible output.
  3. Line 189 insertion conflicts with a concurrent PR (#47) touching the same function.
- [PHASE:revise] Driver revised the approach: adopted exponential backoff from retry.ts
  (concern 1), added output validation step after respawn (concern 2), rebased on #47
  (concern 3).

The previous collaborator stalled while reviewing the revision. Resume from [PHASE:agree] —
evaluate whether the revision adequately addresses the three concerns above. If not,
raise new challenges.

Spec: specs/018-collab-failure-recovery/spec.md
```

Note: the summary includes the specific concerns verbatim (not "the collaborator had some concerns") so the replacement can evaluate whether the revision actually addressed them.
```

### Edit 3: No other edits

No changes to:
- Mode 1 (lines 1–42) — interactive collaboration is unaffected
- Mode 2 §§ 1–4 (lines 48–100, except line 62 above) — spawn/send/dismiss mechanics unchanged
- Configuration section (lines 112–128) — unchanged
- Available Collaboration Roles (lines 130–136) — unchanged

## Files NOT modified (and why)

| File | Reason |
|------|--------|
| `commands/shape.md` | Already contains "Read this file completely and follow it exactly" pointing to agent-collaboration.md (line 46). The recovery protocol is part of that file. No redundant reference needed. |
| `commands/plan.md` | Same — line 51. |
| `commands/implement.md` | Same — line 52. |
| `commands/codex-review.md` | Uses `codex exec -s read-only`, not pi_messenger spawn. The recovery protocol applies to pi_messenger collaborator failures. Applying it to CLI invocations would be a misapplication. Explicitly excluded. |

## Requirement traceability

| Requirement | Addressed by |
|-------------|-------------|
| R1: stall/crash on send → auto dismiss + respawn | Recovery table rows 2 and 4 |
| R2: stall/crash on spawn → auto retry | Recovery table rows 1 and 3 |
| R3: Respawn includes accumulated context | Context accumulation section with worked example |
| R4: cancelled is final | Recovery table row 5 |
| R5: Two-agent gate never bypassed | Gate paragraph: "Recovery is not proceeding solo" |
| R6: Workflow commands reference protocol | Commands already reference agent-collaboration.md in full — no additions needed |
| R7: Max one retry/respawn | Recovery table "If recovery fails" column; gate paragraph "after one automatic recovery attempt" |

## Risks

| Risk | Mitigation |
|------|-----------|
| Implementer commits line 62 change separately from error handling section → transient internal inconsistency | Plan explicitly marks these as one atomic commit. tasks.md notes this. |
| The worked example in the doc becomes stale as collaboration patterns evolve | The example is illustrative, not normative. The recovery table is the protocol; the example shows how to apply it. |
| Agent reads old cached version of agent-collaboration.md | Not in scope — caching is a runtime concern, not a documentation concern. |

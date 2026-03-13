# How to Collaborate with Another Agent

> This document is the single source of truth for agent-to-agent collaboration mechanics.
> Workflow commands (/shape, /plan, /implement) reference this file — do not duplicate these instructions inline.

## The Rule

Collaboration uses **pi_messenger** — that's it. Do NOT use subagent, interactive_shell, or bash to spawn/create agents. Those are wrong tools for this.

There are two modes. Try Mode 1 first. Use Mode 2 if no collaborator is available.

---

## Mode 1: Collaborator Already on the Mesh (interactive)

The user has started another agent in a separate pi session. They are already on the mesh.

### 1. Check who's on the mesh

```
pi_messenger({ action: "list" })
```

You'll see named agents with status indicators (🟢 online, 🟡 idle, 🟠 away). The user will tell you who your collaborator is, or you'll see them in the list.

### 2. Send them a message

```
pi_messenger({ action: "send", to: "<their-name>", message: "..." })
```

This delivers your message AND triggers their next turn — they will wake up and respond. You don't need to do anything else to activate them.

### 3. Wait for their reply

When they respond, pi_messenger delivers their message to you as a steering prompt that starts your next turn. You don't need to poll or check — the message comes to you automatically.

### 4. Continue the back-and-forth

Exchange messages through whatever protocol your workflow requires (shaping phases, planning research/challenge, implementation driver/navigator). Each message triggers the other agent's turn.

### 5. If no collaborator is on the mesh

Try Mode 2 (spawn one yourself). If spawn is not available, tell the user: "I need a second agent for [shaping/planning/implementation]. No collaborator is on the mesh — can you start one?" Do not proceed solo. Do not fake the two-agent exchange by talking to yourself.

---

## Mode 2: Spawn a Collaborator (autonomous)

No second agent is available. You spawn one yourself. This launches a separate pi process (not a subagent — a fully independent agent).

### 1. Spawn (blocks until first response)

```
pi_messenger({ action: "spawn", agent: "crew-challenger", prompt: "Read specs/NNN-slug/spec.md and challenge the proposed approach. Context: <your research findings>" })
```

The `agent` parameter must be a crew agent with `crewRole: collaborator` (e.g., `crew-challenger`). The `prompt` should include specific file paths to read and the context the collaborator needs — do NOT tell them to `/ground` themselves.

**This call blocks until the collaborator sends its first message** (typically 3–10 minutes). The tool result includes the collaborator's response directly — no waiting, no polling, no ambiguity. The TUI shows progress to the user during the wait.

Returns: `{ name, agent, firstMessage: "..." }` on success. On failure: `{ error: "stalled" | "collaborator_crashed" | "mesh_timeout" | "cancelled", name }` with details.

### 2. Exchange messages (each send blocks until reply)

Send messages and receive replies in a single tool call:

```
pi_messenger({ action: "send", to: "<their-name>", message: "..." })
```

When sending to a collaborator, this **blocks until they reply**. The tool result includes their response. Each exchange is atomic — you send a message and get the reply back in the same call.

Use phase markers to structure the conversation:

```
[PHASE:research] Here are my findings on the codebase...
[PHASE:challenge] Three concerns with this approach...
[PHASE:revise] Updated approach addressing your concerns...
[PHASE:agree] Looks solid. Producing artifacts now.
[COMPLETE] plan.md and tasks.md written to specs/NNN-slug/
```

### 3. Max rounds guard

After 5 exchanges without `[PHASE:agree]`, stop the collaboration and escalate to the user: "Collaborator and I can't agree on X. Here are both positions. Your call." Do not loop forever.

### 4. Dismiss when done

When you receive `[PHASE:agree]` or `[COMPLETE]`, or after escalating to the user:

```
pi_messenger({ action: "dismiss", name: "<their-name>" })
```

This sends a shutdown message, waits for graceful exit, falls back to SIGTERM. Always dismiss — do not leave collaborators running.

### 5. If spawn fails

Follow the recovery protocol in § Error handling and recovery below. For `stalled`, `collaborator_crashed`, or `mesh_timeout` errors, the protocol retries once automatically before escalating to the user. For configuration errors (`agent_not_found`, `not_collaborator_role`), retrying won't help — tell the user and fall back to Mode 1.

### Error handling and recovery

When a `spawn` or `send` returns an error, follow the graduated recovery protocol below. The principle: **one automatic recovery attempt before user escalation. Never proceed solo.**

| Error | Context | Automatic recovery | If recovery fails |
|-------|---------|-------------------|-------------------|
| `stalled` | spawn | Dismiss stalled collaborator (`result.name`). Retry spawn once (same prompt). | Ask user — include stall duration. |
| `stalled` | send | Dismiss stalled collaborator (`result.name`). Spawn fresh collaborator with same role + accumulated context (see below). Resume from last completed phase. | Ask user — include stall duration and phase reached. |
| `collaborator_crashed` | spawn | Retry spawn once. | Ask user — include log tail from both attempts. |
| `collaborator_crashed` | send | Spawn fresh collaborator with same role + accumulated context. Resume from last completed phase. | Ask user — include log tail and phase reached. |
| `mesh_timeout` | spawn | Retry spawn once. | Ask user — the collaborator failed to join the mesh. |
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

Spec: specs/NNN-slug/spec.md
```

Note: the summary includes the specific concerns verbatim (not "the collaborator had some concerns") so the replacement can evaluate whether the revision actually addressed them.

---

## Configuration

Users can control collaborator model and thinking independently of workers:

```json
{
  "crew": {
    "models": { "collaborator": "anthropic/claude-sonnet-4-6" },
    "thinking": { "collaborator": "high" },
    "messageBudgets": { "chatty": 100 }
  }
}
```

Set in `~/.pi/agent/pi-messenger.json` (user-level) or `.pi/messenger/crew/config.json` (project-level).

## Available Collaboration Roles

| Agent | Role | Tools | Use for |
|-------|------|-------|---------|
| `crew-challenger` | Challenges proposals, finds gaps, raises risks | read, bash, pi_messenger (read-only, NO write/edit) | /shape, /plan, /codex-review |

The spawning agent is always the proposer — no separate crew-proposer.md is needed. The workflow command (/plan, /shape, etc.) defines the proposer's behavior.

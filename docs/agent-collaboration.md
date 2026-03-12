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

Returns: `{ name, agent, firstMessage: "..." }` on success. On failure: `{ error: "timeout" | "crashed" | "cancelled" }` with details.

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

Tell the user: "I tried to spawn a collaborator but it failed. Can you start a second agent manually?" Fall back to Mode 1.

### Error handling

| Error | Meaning | What to do |
|-------|---------|------------|
| `timeout` | Collaborator didn't respond within the time limit | Retry spawn once. If it fails again, tell the user. |
| `crashed` | Collaborator process died (log tail included in error) | Report the error to user with the log tail. |
| `cancelled` | User pressed Ctrl+C during the wait | Collaborator is dismissed, report cancellation. |

**On ANY collaboration failure — timeout, crash, or spawn error — tell the user and wait for guidance. Do NOT proceed solo. Do NOT offer to "just do it yourself." The two-agent gate exists because single-agent work skips the scrutiny that catches real defects. A failed collaboration is not permission to bypass the gate — it's a problem the user needs to know about.**

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

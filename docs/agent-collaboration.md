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

### 1. Spawn

```
pi_messenger({ action: "spawn", agent: "crew-challenger", prompt: "Read specs/NNN-slug/spec.md and challenge the proposed approach. Context: <your research findings>" })
```

This blocks until the collaborator joins the mesh and is ready to receive messages. Returns `{ name: "<their-name>", pid: <number> }`.

The `agent` parameter must be a crew agent with `crewRole: collaborator` (e.g., `crew-challenger`). The `prompt` should include specific file paths to read and the context the collaborator needs — do NOT tell them to `/ground` themselves.

### ⚠️ Wait for the collaborator's first message

After spawn returns, the collaborator is processing its initial prompt — reading files, analyzing context, composing its first response. **Do NOT send additional messages until the collaborator sends its first message to you.** This takes **3–10 minutes** on large codebases.

- **Do not ping.** Silence means "processing," not "stuck."
- **Do not dismiss before 5 minutes minimum.** Challengers on large repos (GMP, Orchestrator) routinely need 5–10 minutes for their first response.
- **To check if actually stuck:** Look at the collaborator's registry entry — if `session.toolCalls` or `session.tokens` are still increasing, it's working. Flat counts for 3+ minutes with no message = potentially stuck.

### 2. Exchange messages

Same as Mode 1 — send messages, receive replies via steering prompts. Use phase markers:

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

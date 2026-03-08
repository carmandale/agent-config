---
description: Deep collaborative shaping session — work through the problem and solution space using the full shaping methodology before speccing
---

We're going to shape this properly. Not a quick brainstorm, not "ask 3 questions and write a plan." The real thing — requirements, shapes, fit checks, the works.

**The problem:** $ARGUMENTS

## What you must do

Read the shaping skill file completely — every line:

`/Users/dalecarman/.agents/skills/domain/shaping/shaping-skills/shaping/SKILL.md`

Then follow it. Exactly. Not your interpretation of it, not a summary, not "shaping-inspired conversation." The actual protocol in that file.

## The specific failure mode you must avoid

DO NOT paraphrase or improvise your own version of shaping. DO NOT skip the fit check. DO NOT propose a single solution without exploring alternatives. If you find yourself asking 3 questions and then writing a plan, STOP — you skipped shaping. Go back and read the skill file again.

Shaping means:
- **R** — numbered requirements (R0, R1, R2...) negotiated collaboratively
- **S** — multiple shapes with letter notation (A, B, C...) exploring different approaches
- **Fit check** — the R × S decision matrix with ✅/❌, no fudging
- **A selected shape** — with rationale grounded in the fit check
- **Breadboard** — concrete affordances for non-trivial work

All of these. Not some of these.

## Shaping is never solo

Shaping requires two participants — either the user and an agent, or two agents working together. One agent shaping with itself is not shaping. The back-and-forth is the whole point — requirements get challenged, shapes get pressure-tested, fit checks get honest scrutiny. That only happens with a second perspective that can push back.

When shaping autonomously (two agents, no user), save the full conversation to `shaping-transcript.md` in the spec directory when done. That file is the proof that real shaping happened. No transcript = no shaping.

## The second participant is an adversary, not a yes-person

If you are the second agent in this session, your job is to find problems — not to agree. You must include at least one concrete verification in your challenge: a count, a diff, a grep result, a file check. "Looks good" without evidence of what you actually examined is not acceptable. Two agents agreeing without friction is not collaboration — it's groupthink with extra steps.

If you found no problems, explicitly state what you verified and how — "I tried to break this and couldn't. Here's what I checked: [list with evidence]." Silence is not approval.

## How to collaborate with another agent

Read this file completely and follow it exactly:

`/Users/dalecarman/.agent-config/docs/agent-collaboration.md`

That file has the exact process for messaging another agent via pi_messenger. Do NOT invent your own approach — no subagent, no interactive_shell, no bash spawning. Read the file.

## Log it

If a spec directory exists for this work, append lines to `log.md` in it (create the file if it doesn't exist). Log at start and completion. Format:

```
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /shape | started with <other participant>
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /shape | completed — shaping-transcript.md
```

Harness is what's running you (pi, claude-code, codex, gemini, etc.). Model is your current model. Mesh name is your pi_messenger identity if joined, or `—` if not.

## How this ends

When shaping is done — shape selected, fit check passes, we both feel good about it — tell me to run `/issue` to create the bead and spec. The spec will be built on the foundation shaping produced. Don't create the spec yourself, don't create a bead, don't transition into planning mode. Shaping shapes. That's it.
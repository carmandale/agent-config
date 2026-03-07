---
description: Build a real implementation plan using two agents and the workflows-plan skill — research the codebase, propose a plan, stress-test it
---

Build the implementation plan for the specified spec. This is a two-agent session — one agent researches and proposes, the other stress-tests and validates. Neither agent works alone.

**Target:** $ARGUMENTS

## Before anything else

Check that the target spec directory has a `spec.md` with a `bead:` in its YAML frontmatter. If there's no spec.md, or no bead, stop. Tell the user to run `/issue` first — the bead and numbered spec directory are non-negotiable tracking infrastructure. Do not create them yourself. Do not proceed without them.

## What you must do

Read the workflows-plan skill file completely — every line:

`/Users/dalecarman/.agents/skills/workflows/workflows-plan/SKILL.md`

That skill has the real protocol — idea refinement, parallel research agents, codebase investigation, pattern analysis, detail levels. Don't wing your own version of planning. Read it and follow it.

Start by reading `spec.md` in the target spec directory. That's your problem definition — the requirements and acceptance criteria that `/issue` or `/shape` already established. Your job is to figure out HOW to solve it, not to redefine WHAT to solve. If shaping was done, the selected shape and fit check are your starting constraints — don't re-derive what's already decided.

## The specific failure mode you must avoid

DO NOT skip the codebase research. DO NOT write a plan from vibes and general knowledge. DO NOT produce a task list without understanding the existing patterns, architecture, and blast radius of the changes. If your plan doesn't reference specific files, functions, or patterns you found in the codebase, you skipped research. Go back and read the skill file again.

## Planning is never solo

Planning requires two participants — either the user and an agent, or two agents working together. One agent planning with itself is not planning.

**Engage the second agent BEFORE writing anything.** The failure mode is: one agent does all the research, writes the entire plan, then sends it to the other agent for review. That's a review, not collaborative planning. Instead:

1. Do your codebase research — read relevant code, understand the architecture, find insertion points.
2. **Before writing plan.md**, share your findings with the second agent: "Here's what I found. Here's what I think the approach should be. What am I missing? What's the blast radius I'm not seeing?"
3. The second agent challenges, adds their perspective, raises risks, suggests alternatives.
4. **Then** write the plan together, incorporating both perspectives.
5. Not "here's the finished plan, review it."

When planning autonomously (two agents, no user), save the full conversation to `planning-transcript.md` in the spec directory when done. That file is the proof that real planning happened with two perspectives. No transcript = no planning.

## How to collaborate with another agent

Read this file completely and follow it exactly:

`/Users/dalecarman/.agent-config/docs/agent-collaboration.md`

That file has the exact process for messaging another agent via pi_messenger. Do NOT invent your own approach — no subagent, no interactive_shell, no bash spawning. Read the file.

## What you produce

Two files in the spec directory:

- `plan.md` — implementation approach, architecture decisions, requirement-to-change traceability, the "how"
- `tasks.md` — ordered checkable task list with dependencies, the "do this"

Both files get YAML frontmatter with title, date, and bead ID from the spec.

## Log it

Append lines to `log.md` in the spec directory (create if needed). Log at start and completion. Format:

```
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /plan | started with <other participant>
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /plan | completed — plan.md + tasks.md
```

Harness is what's running you (pi, claude-code, codex, gemini, etc.). Model is your current model. Mesh name is your pi_messenger identity if joined, or `—` if not.

## How this ends

When the plan is done — both agents agree it's solid, research is grounded, tasks are concrete — tell me to run `/codex-review <spec>` for an independent review, or `/implement <spec>` if it's straightforward enough to skip review.

$ARGUMENTS
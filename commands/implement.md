---
description: Execute a plan with two agents — one implements following the workflows-work protocol, one validates every step
---

Implement the specified plan. Read the full spec, plan, and tasks end to end and understand the intent behind them, not just the steps.

**Target:** $ARGUMENTS

## Before anything else

Check that the target spec directory has `spec.md`, `plan.md`, and `tasks.md`, and that `spec.md` has a `bead:` in its YAML frontmatter. If any are missing, stop. Tell the user what's missing — typically `/issue` for the bead+spec, `/plan` for the plan+tasks. Do not create them yourself. Do not proceed without them.

## Alignment gate

Before writing any code, check alignment with our North Star, Apple best practices, AGENTS.md rules, and the existing architecture. If you don't agree with the plan — if it's misaligned, overengineered, fighting the codebase, or just wrong — you must stop and tell me why and what you suggest would be better. Do NOT implement a plan you believe is wrong.

## What you must do

Read the workflows-work skill file completely and follow its execution protocol:

`/Users/dalecarman/.agents/skills/workflows/workflows-work/SKILL.md`

That skill has the real protocol — branch management, incremental commit heuristics, continuous testing, quality gates, progress tracking, PR creation. Don't wing your own version of execution. Read it and follow it.

## The specific failure mode you must avoid

DO NOT implement everything then claim it works. DO NOT skip testing after each change. DO NOT commit everything in one giant commit at the end. DO NOT ignore the quality gates in the skill. If you find yourself writing code for 30 minutes without running a test or making a commit, STOP — you're not following the protocol. Go back and read the skill file again.

## Implementation is never solo

Implementation requires two participants — either the user and an agent, or two agents working together. One agent implementing with itself is not implementation. The back-and-forth is the whole point — one agent writes code following the workflows-work protocol, the other validates each step: did you test? Did you follow existing patterns? Does this actually match the plan? Did you break anything? Is this the right commit boundary? That scrutiny is what forces the protocol to actually be followed.

When implementing autonomously (two agents, no user), one agent drives (writes code, runs tests, commits) and the other navigates (validates against plan, checks quality, catches drift). The git commits and PR are the proof artifacts — but the two-agent interaction is what makes them honest.

## How this ends

Be sure to comply with ALL rules in AGENTS.md and ensure that any code you write or revise conforms to the best practices referenced in the AGENTS.md file. When all tasks are checked off, tests pass, and the PR is up — you're done.

$ARGUMENTS
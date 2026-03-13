---
description: Execute a plan with two agents — one implements following the workflows-work protocol, one validates every step
gate_requires: spec.md, plan.md, tasks.md
gate_sentinels: plan:complete:v1
gate_warn_sentinels: codex-review:approved:v1
gate_creates: code changes, commits
gate_must_not_create: spec.md, plan.md, tasks.md, codex-review.md
---

Implement the specified plan. Read the full spec, plan, and tasks end to end and understand the intent behind them, not just the steps.

**Target:** $ARGUMENTS

## HARD CONSTRAINT — Gate Check

Run `scripts/gate.sh gate implement specs/<NNN>-<slug>/` before any work.

- **Exit 1 (FAIL):** STOP COMPLETELY. Do NOT create the missing files. Do NOT offer to create them. Do NOT proceed with workarounds. Show the output to the user and wait.
- **Exit 2 (WARN):** Show the warning to the user and ask THEM whether to proceed. This is the USER's decision, not yours. Do NOT silently ignore. Do NOT decide for the user that "it's probably fine."
- **Exit 0 (PASS):** Proceed.

Do NOT create spec.md, plan.md, tasks.md, or codex-review.md — those belong to /issue, /plan, and /codex-review. If tasks.md is missing, /plan was not run. Stop and tell the user to run /plan.

If you catch yourself about to rationalize past a FAIL result, STOP — you are doing the exact thing this gate exists to prevent.

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

## The navigator is an adversary, not an ally

The navigator's job is NOT to confirm the driver's work passes. It's to find where it doesn't. When validating a step, the navigator must:
- Read the actual code that was written, not just the test output
- Verify that what changed matches what the plan says should change (diff the PR, not the commit message)
- Include at least one concrete verification in each review: a count, a grep, a file check, a diff

"Did you test?" is not validation. "You ran 21 tests but the plan specified changes to 3 files — show me the coverage" is validation.

If the navigator found no issues with a step, they must say what they checked: "I diffed the PR against the plan, verified test coverage for the changed files, and found no gaps. Here's the diff summary: [...]" Silence is not approval.

For the full adversarial review protocol, read: `/Users/dalecarman/.agents/skills/review/adversarial-review/SKILL.md`

## How to collaborate with another agent

Read this file completely and follow it exactly:

`/Users/dalecarman/.agent-config/docs/agent-collaboration.md`

That file has the exact process for messaging another agent via pi_messenger. Do NOT invent your own approach — no subagent, no interactive_shell, no bash spawning. Read the file.

## Log it

Append lines to `log.md` in the spec directory (create if needed). Log at start and completion. Format:

```
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /implement | started with <other participant>
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /implement | completed — N commits
```

Harness is what's running you (pi, claude-code, codex, gemini, etc.). Model is your current model. Mesh name is your pi_messenger identity if joined, or `—` if not.

## How this ends

Be sure to comply with ALL rules in AGENTS.md and ensure that any code you write or revise conforms to the best practices referenced in the AGENTS.md file. When all tasks are checked off, tests pass, and the PR is up — you're done.

## After completion

Run `scripts/gate.sh record implement specs/<NNN>-<slug>/ --harness "<harness>/<model>"` to update the pipeline state trail.

Then run `scripts/gate.sh verify implement specs/<NNN>-<slug>/` to confirm no anti-fabrication violations (you should not have created spec.md, plan.md, tasks.md, or codex-review.md).

$ARGUMENTS
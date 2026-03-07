---
title: "Plan: Agent workflow verification"
date: 2026-03-07
bead: .agent-config-gfi
---

# Implementation Plan

## Research Findings

Joint audit by JadeGrove + IronMoon of all 7 commands against shaping requirements:

| Command | Words | Next-step? (R0) | Artifact? (R1/R5) | Needs work? |
|---------|-------|-----------------|-------------------|-------------|
| `/ground` | 315 | ❌ Asks "what are we working on?" — no command suggestions | N/A (orientation, not a gate) | Yes — add next-step |
| `/shape` | 365 | ✅ "tell me to run `/issue`" | ✅ `shaping-transcript.md` | No |
| `/issue` | 367 | ✅ Suggests `/codex-review` or `/implement` | ✅ spec.md with bead frontmatter | No |
| `/sweep` | 330 | ❌ "wait for approval" — no next command | ✅ Creates bead + spec/plan/tasks | Yes — add next-step |
| `/audit-agents` | 255 | ❌ Nothing | ⚠️ Fixes in-place, no named spec artifact | Yes — add next-step |
| `/codex-review` | 1950 | Partial — "ready for your approval to implement" but doesn't name `/implement` | ✅ Best artifact contract (session ID, verdict, model, rounds) | Yes — make explicit |
| `/implement` | 173 | N/A (terminal) | ✅ git commits | No |

**prompt-craft finding (IronMoon):** "Anchor Trust in Artifacts" section already has the principle AND the verified spec directory listing. What's missing is specific content markers per artifact. The task is "add content markers to existing section" — not "create a new section."

**`/audit-agents` artifact note (IronMoon):** This command fixes in-place rather than producing spec artifacts. That's by design — it's a review-and-fix command, not a spec-creation command. Acknowledged as intentional, not a gap.

## Approach

Four changes. Each independent and small. All follow the voice constraint — one sentence additions, not process sections.

### Change 1: Next-step suggestions (R0)

Add one conversational sentence to 4 commands:

- **`/ground`** — After "What are we working on?", add: for new work → `/shape` or `/issue`, bug hunting → `/sweep`, code review → `/audit-agents`.
- **`/sweep`** — After "wait for approval," add: once approved, run `/codex-review <spec>` then `/implement <spec>`.
- **`/audit-agents`** — At end, add: if findings warrant a spec, run `/issue` then `/codex-review`. If fixes were direct, commit and you're done.
- **`/codex-review`** — After approval flow, explicitly name `/implement <spec>` as next step.

**Style rule:** One sentence each. Conversational. Not a "## Next Steps" header.

### Change 2: Artifact Contract content markers in prompt-craft (B5)

Expand the EXISTING "Anchor Trust in Artifacts" section in `skills/meta/prompt-craft/SKILL.md` with specific content markers. Don't create a new section — the principle and file listing are already there. Add what's missing:

- `codex-review.md` must contain: Codex session ID, model identifier, VERDICT line, round-by-round feedback
- `shaping-transcript.md` must contain: messages from two distinct named participants, requirements table, fit check, selected shape
- `spec.md` frontmatter must contain: `bead:` with valid ID, `date:`, `title:`
- Pattern guidance for future commands: if your command is a critical gate, define what file it produces and what content makes it real

### Change 3: `/help-workflow` command (B6)

New file: `commands/help-workflow.md`

Conversational single paragraph listing all commands in typical workflow order. For each: name, one-line purpose, what artifact it produces (if any). Readable in 10 seconds. Not a reference manual, not a table.

### Change 4: Napkin update

Add entry for artifact contracts and next-step suggestions as standard patterns for all commands.

## What this does NOT do

- Does not change artifact-producing behavior (already working)
- Does not touch the shaping submodule (R10 accepted gap)
- Does not add pre-check hints or prerequisite lists (B3 dropped during shaping)
- Does not add enforcement hooks or tooling
- Does not add spec artifacts to `/audit-agents` (intentional — it fixes in-place)

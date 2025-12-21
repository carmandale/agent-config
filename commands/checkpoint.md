---
description: Mid-session checkpoint - writes timestamped file, preserves context for continuation
---

Create a checkpoint mid-session to preserve context. Use when:
- Context is getting long and may be compacted
- Before switching to a complex subtask
- Before a break
- To document progress for team visibility

## Step 1: Gather Session State

Run these in parallel:

```bash
# Files changed this session
git status --short

# Uncommitted diff stats
git diff --stat

# Recent commits (this session)
git log --oneline -10

# Beads in progress
bd list --status in_progress --json

# Recently closed beads
bd list --status closed --json | jq -r '.[:5] | .[] | "\(.id): \(.title)"'
```

## Step 2: Analyze Session

Review the conversation history to identify:

- **Original Goal:** What was the user's initial request?
- **Accomplished:** What's been completed?
- **Remaining:** What's still left to do?
- **Key Decisions:** Architectural/design choices and WHY they were made
- **Patterns Discovered:** Any insights about the codebase
- **Blockers:** Open questions or issues

## Step 3: Write Checkpoint File

Create the checkpoint directory if needed:

```bash
mkdir -p .checkpoint
```

**Filename format:** `.checkpoint/YYYY-MM-DD-HHMM.md`

Example: `.checkpoint/2025-12-21-0930.md`

If there's an active bead, include it: `.checkpoint/2025-12-21-0930-{BEAD_ID}.md`

**File contents:**

```markdown
# Checkpoint

**Date:** YYYY-MM-DD HH:MM
**Active Bead:** {BEAD_ID if any} - {title}
**Goal:** {one-line summary of what we're working on}

## Accomplished

- [Completed item with brief context]
- [Completed item with brief context]

## Remaining

- [ ] [Pending item]
- [ ] [Pending item]

## Key Decisions

| Decision | Reasoning |
|----------|-----------|
| {what we decided} | {why we decided it} |

## Patterns Discovered

- [Codebase insight or pattern worth remembering]

## Files Changed

| File | Change |
|------|--------|
| path/to/file | modified/created/deleted |

## Active Beads

| ID | Title | Status |
|----|-------|--------|
| {id} | {title} | {status} |

## Blockers / Open Questions

- [Any unresolved issues]

## Resume Prompt

---
Continue working on: {goal}

Context:
- [Key context point 1]
- [Key context point 2]

Current state:
- [Where we left off]
- [What's loaded/ready]

Next steps:
1. [Immediate next action]
2. [Following action]

Key decisions already made:
- [Decision 1]
- [Decision 2]
---
```

## Step 4: Handle --save-decisions Flag

If `--save-decisions` was specified (or if there are significant architectural decisions):

For each key decision identified, create a bead:

```bash
bd create "Decision: {brief title}" -t chore -d "## Decision
{What we decided}

## Reasoning
{Why we decided it}

## Context
{When/where this applies}"
```

Link decisions to current work if there's an active bead.

## Step 5: Commit Checkpoint

```bash
# Stage the checkpoint
git add .checkpoint/

# Commit
git commit -m "checkpoint: {brief description of session state}

- {N} items accomplished
- {N} items remaining
- Active bead: {BEAD_ID if any}"
```

## Step 6: Confirm

**Output confirmation:**

```
✓ Checkpoint saved

  File: .checkpoint/YYYY-MM-DD-HHMM.md
  Accomplished: {N} items
  Remaining: {N} items
  Decisions: {N} captured
  Active beads: {N}

  To continue with fresh context: paste the Resume Prompt section
```

## Tips

- Run `/checkpoint` before context gets too long
- Checkpoints are cumulative - each one is a snapshot in time
- Use the Resume Prompt to continue in a new session
- Checkpoints help team members understand session progress
- Unlike `/handoff`, checkpoint doesn't require a bead (but should reference one if active)

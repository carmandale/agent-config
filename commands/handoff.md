---
description: End-of-session handoff - REQUIRES active bead, writes timestamped file, syncs and commits
---

You are ending a work session. Your job is to create a clean handoff so the next session (or agent) can pick up seamlessly.

## CRITICAL: Bead Requirement

**This command REQUIRES an active bead.** A handoff without a bead is not allowed.

```bash
# Check for in-progress beads
bd list --status in_progress --json
```

**If no beads are in progress, STOP and tell the user:**

> ❌ Cannot create handoff: No active bead found.
> 
> A handoff must be connected to a bead for traceability. Either:
> 1. Create a bead for the work you did: `bd create "description" -t task`
> 2. Or identify which existing bead this session was working on

**Do not proceed until a bead is identified.**

## Step 1: Identify the Primary Bead

From the in-progress beads, identify which one this session primarily worked on. This is the `PRIMARY_BEAD_ID`.

If multiple beads were worked on, pick the most significant one. Others will be listed in the handoff.

## Step 2: Gather Current State

Run these in parallel:

```bash
# What's in progress?
bd list --status in_progress --json

# What was recently closed?
bd list --status closed --json | head -20

# Git status - uncommitted work?
git status --short

# Recent commits this session
git log --oneline -10

# Any open PRs?
gh pr list --state open --json number,title,headRefName --jq '.[] | "\(.number): \(.title) (\(.headRefName))"'
```

## Step 3: Identify Loose Ends

Check for:
- Uncommitted changes that should be committed or stashed
- In-progress beads that should be updated with notes
- TODOs mentioned in conversation but not filed as beads
- Decisions made that should be documented

## Step 4: Write Handoff File

Create the handoff directory if needed and write the file:

```bash
mkdir -p .handoff
```

**Filename format:** `.handoff/YYYY-MM-DD-HHMM-{BEAD_ID}.md`

Example: `.handoff/2025-12-21-0930-orchestrator-2ok.md`

**File contents:**

```markdown
# Session Handoff

**Date:** YYYY-MM-DD HH:MM
**Primary Bead:** {BEAD_ID} - {BEAD_TITLE}
**Agent:** {agent name if known, or "unknown"}

## Completed This Session

- [list of closed beads or completed work with bead IDs]

## In Progress

- **{BEAD_ID}**: {title} - {current status/blockers}

## Related Beads

| Bead ID | Title | Status | Notes |
|---------|-------|--------|-------|
| {id} | {title} | {status} | {brief note} |

## Key Decisions Made

| Decision | Reasoning | Bead |
|----------|-----------|------|
| {what} | {why} | {related bead if any} |

## Next Up

1. [what should be tackled next, in priority order]
2. [...]

## Continuation Prompt

---
Continue working on {PRIMARY_BEAD_ID}: {title}

Context:
- [Key context point 1]
- [Key context point 2]

Current state:
- [Where we left off]
- [What's ready/blocked]

Next steps:
1. [Immediate next action]
2. [Following action]
---
```

## Step 5: Update Bead with Handoff Reference

Add a note to the primary bead referencing the handoff:

```bash
bd comment {PRIMARY_BEAD_ID} "Handoff created: .handoff/YYYY-MM-DD-HHMM-{BEAD_ID}.md"
```

## Step 6: Commit and Sync

```bash
# Stage the handoff file
git add .handoff/

# Commit with bead reference
git commit -m "handoff({PRIMARY_BEAD_ID}): Session handoff YYYY-MM-DD

- {brief summary of session}
- Continuation prompt included"

# Sync beads
bd sync

# Push everything
git push
```

## Step 7: Verify

```bash
git status  # Should be clean
git log -1  # Should show handoff commit
bd show {PRIMARY_BEAD_ID}  # Should show handoff comment
```

**Output confirmation:**

```
✓ Handoff complete

  File: .handoff/YYYY-MM-DD-HHMM-{BEAD_ID}.md
  Bead: {PRIMARY_BEAD_ID} - {title}
  Commit: {short SHA}

  To continue: paste the Continuation Prompt into a new session
```

## IMPORTANT

- **Never skip the bead requirement** - traceability is essential
- **Always commit the handoff file** - it's part of the project history
- **Always push** - the handoff isn't complete until it's on remote

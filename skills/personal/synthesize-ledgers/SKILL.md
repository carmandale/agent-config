---
description: Synthesize multiple session event files into a unified current.md ledger
---

# Synthesize Ledgers

You are tasked with synthesizing session event files from parallel agents into a unified `current.md` ledger.

## Background

When multiple agents work in parallel (worktrees, branches), each writes session events to `thoughts/shared/handoffs/events/`. This skill synthesizes those events into a single unified ledger using CRDT-like merge semantics to avoid conflicts.

## Process

1. **Discover event files:**
   ```bash
   ls -la thoughts/shared/handoffs/events/
   ```

2. **Preview what will be merged:**
   - Read each event file to understand contents
   - Show the user:
     - Number of events found
     - Agents/branches represented
     - Timestamp range
     - Key sections that will be merged

3. **Explain merge semantics:**
   | Section | Strategy |
   |---------|----------|
   | **Now** | Latest timestamp wins (LWW) |
   | **This Session** | Union of all items, dedupe by hash |
   | **Decisions** | Merge by key, latest timestamp per key |
   | **Checkpoints** | Concatenate, sort by time, dedupe by phase |
   | **Open Questions** | Union of all, exact match dedupe |

4. **Run synthesis:**
   ```bash
   cd ~/.claude/hooks && node dist/synthesize-ledgers.mjs "$(pwd)/thoughts/shared/handoffs/events" "$(pwd)/thoughts/shared/handoffs/current.md"
   ```

5. **Show results:**
   - Display the generated `current.md`
   - Highlight any conflicts resolved (e.g., different "Now" values)
   - Report event count and branches combined

6. **Offer next steps:**
   - Archive source events? (move to `archive/YYYY-MM-DD/`)
   - Commit the synthesized ledger?
   - Clean up old events (retention policy)?

## YAML Event File Format

Each event file has YAML frontmatter:
```yaml
---
ts: 2026-01-11T10:00:00Z
agent: abc12345
branch: feat/feature-a
type: session_end
reason: clear
---

now: Current focus description

this_session:
- Completed task 1
- Completed task 2

decisions:
  key: "value with rationale"

checkpoints:
- phase: 1
  status: completed
  updated: 2026-01-11T09:00:00Z
```

## Output Format

The synthesized `current.md` includes:
- Unified ledger sections
- Metadata footer showing source events and branches

## When to Use

- After parallel work completes (merge branches)
- On session start (automatic via hook)
- Before creating a PR (ensure ledger is up-to-date)
- When resolving ledger conflicts manually

## Triggers

- `/synthesize-ledgers`
- "synthesize ledgers"
- "merge ledgers"
- "combine events"

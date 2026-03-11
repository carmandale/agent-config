---
name: crew-navigator-posture
description: When pi_messenger crew workers are actively executing tasks, avoid editing the same files — review their commits instead. Use when crew workers are in-progress, when task.list shows active workers, or after pi_messenger plan creates tasks with auto-work. This skill is about active-worker collision avoidance; use navigator-role for the adversarial review protocol.
---

# Crew Active → Review First

## The Rule

When crew workers are executing tasks, **review their output instead of writing code yourself**. Workers commit faster than you can read the source files. If you start editing a file a worker is also changing, you'll create conflicts or duplicate work.

This skill covers **collision avoidance with active workers**. For how to do the actual adversarial review, see `navigator-role`.

## When This Fires

- `pi_messenger({ action: "task.list" })` shows tasks with `[WorkerName]` assigned
- You just ran `pi_messenger({ action: "plan" })` or `pi_messenger({ action: "work" })`
- Multiple tasks are `🔄 in-progress`

## What to Do

1. **Check commit history before touching any file:**
   ```bash
   git log --oneline -5                         # What did workers just commit?
   git log --oneline <base>..HEAD -- path/to/file  # Did a worker already change this file?
   git diff <base>..HEAD -- path/to/file        # What exactly changed since work started?
   ```
   Use the commit before `pi_messenger work` started as `<base>`.

2. **Claim only unclaimed tasks** — tasks that have no `[WorkerName]` and aren't blocked

3. **If a worker already committed changes to your file**, verify their changes match the plan instead of re-implementing

4. **Your highest-value activity is adversarial review:**
   - Diff each commit against the plan
   - Count: files changed, tests written, assertions per test
   - Verify response shapes, error codes, edge cases
   - Catch what the worker missed (dead code, missing tests, silent scope changes)

## The Anti-Pattern

```
# BAD: You read source files for 10 minutes, start editing api-handler.js
# Meanwhile, a worker already committed those same changes 3 minutes ago
# Your edits are now redundant — you wasted time reimplementing done work
```

## The Correct Pattern

```
# GOOD: Check what workers committed since work started
git log --oneline <base>..HEAD
# → 2740626 feat(webhook-score): add token guard...

# Diff their work against the plan
git diff <base>..HEAD -- src/api/webhook-score.js

# Review: does this match the spec? Any bugs? Missing coverage?
# THEN take unclaimed tasks or write tests the workers missed
```

## Source

Observed during multi-worker crew execution: lead agent edited files while workers were committing the same changes, producing identical output — wasted effort. Workers completed 4/7 tasks while lead was still reading source files.

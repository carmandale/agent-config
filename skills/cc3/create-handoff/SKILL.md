---
name: create-handoff
description: "DEPRECATED: Use /checkpoint, /handoff, or /finalize commands instead"
---

# Create Handoff — DEPRECATED

This skill has been superseded by the dedicated slash commands which are smarter and more complete:

- **`/checkpoint`** — Mid-session snapshot (bead optional). Auto-captures session summary from transcript, infers bead and outcome.
- **`/handoff`** — End-of-session transfer (bead required). Auto-captures session summary, smart bead inference, outcome inference.
- **`/finalize`** — Memorial for completed work (bead required). Auto-captures session summary, closes GH issues, comprehensive closure.

All three commands use `~/.claude/scripts/cc-artifact` and write to `thoughts/shared/handoffs/<session>/`.

To resume from any artifact: **`/resume-handoff`**

## Why deprecated?

The commands (`/checkpoint`, `/handoff`, `/finalize`) added:
1. **Session transcript reading** — Python script reads `.jsonl` to auto-capture files modified, commands run, errors, test results
2. **Smart bead inference** — 5-level fallback (CLI arg → transcript → commands → git branch → bd list)
3. **Outcome inference** — Automatic SUCCEEDED/PARTIAL_PLUS/PARTIAL_MINUS/FAILED based on session activity
4. **`--no-edit` handling** — Prevents blocking agents with $EDITOR

This skill lacked all of those features. Use the commands instead.

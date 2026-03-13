# Planning Transcript — Spec 018

**Date:** 2026-03-12
**Proposer:** JadePhoenix (pi/claude-sonnet-4-20250514)
**Challenger:** OakUnion (crew-challenger, claude-sonnet-4-6)

## Exchange 1: Research findings + proposed plan structure

**JadePhoenix [PHASE:research]:**
- agent-collaboration.md is 136 lines, error handling section is lines 102–110 (9 lines)
- Three workflow commands already reference agent-collaboration.md in full
- Proposed 4-phase plan: update error section, update line 62 type, add command references, verify

**OakUnion [PHASE:challenge] — 4 concerns:**
1. One-line command additions are redundant — commands already require full read of agent-collaboration.md
2. Recovery table uses `stall` error type that doesn't exist until pi-messenger 005 ships — can't partially implement
3. Context accumulation template has `<summary>` placeholders with no specification for what goes in them
4. Max rounds guard interaction with respawn is unaddressed (does count reset?)

## Exchange 2: Revisions addressing all 4 concerns

**JadePhoenix [PHASE:revise]:**
1. ACCEPTED — dropped all command file changes. Single-file change only.
2. ACCEPTED — hard dependency on 004+005, no partial shipping.
3. ACCEPTED — defined: completed vs. partial phase, 2-4 bullet summaries, concrete worked example.
4. ACCEPTED — per-collaborator reset, capped by retry-once limit. One line in doc.

**OakUnion [PHASE:challenge] — 3 additional issues:**
A. Phase 1+2 must be atomic — updating `stall` in error section while `timeout` remains on line 62 creates inconsistency window.
B. (Repeated concern 3 — already addressed in previous message)
C. (Repeated concern 4 — already addressed in previous message)
Plus: Q1 answer — codex-review.md excluded (uses `codex exec`, not pi_messenger). Q2 answer — line 62 owned by spec 018.

## Exchange 3: Final revision

**JadePhoenix [PHASE:revise]:**
- Concern A: ACCEPTED — merged into single atomic commit
- Pointed out B/C were already addressed
- Proposed final plan structure: single atomic change, 8 ordered tasks

**OakUnion [PHASE:challenge] — conditional agree with 1 remaining issue:**
- Issue A (new): The rewritten two-agent gate paragraph needs actual draft text in plan.md, not just "keep intent, remove contradiction." For doc-only specs, the plan IS the draft — the implementer shouldn't author primary specification text without review.

## Exchange 4: Agreement

**JadePhoenix [PHASE:agree]:** Accepted — will include all draft text in plan.md.

**OakUnion [PHASE:agree]:** Agreement confirmed. Listed 7 improvements surfaced by challenge process.

## Key principle established

"For doc-only specs, the plan IS the draft." — When the deliverable is documentation (not code), plan.md must contain the actual replacement text, not instructions to write it. The implementer copy-edits; they don't author.

## Artifacts produced

- `plan.md` — 3 surgical edits with full draft text
- `tasks.md` — 6 tasks, single atomic commit, dependency gate

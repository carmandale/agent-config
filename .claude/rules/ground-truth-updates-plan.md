# Ground Truth Updates Plan

When implementation reveals plan assumptions are wrong, update the plan documents before continuing.

## Pattern

Plans are written with incomplete information. Implementation produces ground truth that invalidates assumptions. The plan must be updated to reflect reality — otherwise future readers (including agents resuming from a handoff) will act on wrong information.

## DO

- Add `<!-- REVISED: [date] — [what changed and why] -->` comments to changed sections
- Update counts, classifications, and detection methods to match reality
- Keep the original text readable (don't delete context, annotate it)
- Update tasks.md if task descriptions reference invalidated assumptions

## DON'T

- Leave plan.md contradicting your implementation
- "Fix it later" — the next agent session reads the plan first
- Only update the code and forget the docs
- Rewrite the entire plan (preserve the audit trail)

## When This Triggers

- A detection method doesn't work as planned (use the one that does)
- Fleet/data counts are different from planning estimates
- A tool behaves differently than documented (version-specific behavior)
- A "special case" turns out to be normal (or vice versa)

## Source

- Spec 013: Hit 3 times in one session:
  1. `br doctor` gave opposite exit codes from plan assumption → detection changed to `br list` DATABASE_ERROR check
  2. Fleet was 23 needs-migration (not 35) — 16 repos already worked with br
  3. br ID format constraints (lowercase-only, no dots) — required JSONL normalization step not in plan
  
  Navigator review also flagged 2 documentation drifts where plan.md hadn't been updated to match implementation.

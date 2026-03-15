<!-- plan:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-14T13:52:17Z -->

# Planning Transcript: 020-cc-artifact-bd-to-br

**Participants**: MintStorm (pi/claude-sonnet-4) + OakOwl (crew-challenger)
**Date**: 2026-03-14

---

## [PHASE:research] MintStorm → OakOwl

Shared complete file inventory (8 areas of change), research findings, and 5 specific questions for challenge:
1. File inventory completeness
2. cc-synthesize hooks dependency
3. Phantom scripts (aggregate/search-reasoning.sh)
4. Self-validation exit-code-as-contract sufficiency
5. Test false-positive avoidance

## [PHASE:challenge] OakOwl → MintStorm

Six challenges raised:

1. **CRITICAL (later retracted)**: Claimed `br list --json` doesn't work, needs `--format json`. Evidence: hit DATABASE_ERROR during testing.
2. **MEDIUM**: cc-synthesize depends on `~/.claude/hooks/dist/synthesize-ledgers.mjs` at runtime. Moving to tools-bin/ creates false sense of "managed." Recommended: defer to separate bead.
3. **MEDIUM**: Test false-positive surface — 23 hits for `.claude/scripts/` in documentation/Category 2 references. Recommended: narrow to `~/` home-dir absolute form only, exclude `**/references/**`.
4. **LOW**: Phantom scripts are pre-existing breakage. Recommended: update paths to bare names, file separate bead for creation.
5. **AGREE**: Consumer validation removal is safe — script's internal validation covers all checks.
6. **LOW**: PATH availability — bare name fails if agent harness uses `/bin/sh` instead of zsh. Existing risk (same as agent-config-parity). Recommended: add command-exists check.

## [PHASE:revise] MintStorm → OakOwl

Verified #1 with evidence:
- `br list --status in_progress --json --limit 1` → exit 0, valid JSON
- `br show .agent-config-324 --json` → exit 0, valid JSON
- `br show nonexistent-bead-xyz` → exit 3, ISSUE_NOT_FOUND

Accepted #2 (defer cc-synthesize), #3 (narrow test), #4 (update paths only for phantoms).
Partially accepted #6 (script self-check for br, not consumer-side).
Disagreed on allowlist file — unnecessary complexity.

## [PHASE:agree] OakOwl → MintStorm

Retracted #1 (misattributed DATABASE_ERROR to --json flag).
Accepted all revisions. One implementation note: api-security.md reference doc has 14 hits in exact `~/.claude/scripts/` form — test needs reference dir exclusion or scoping to SKILL.md files.

Final agreement: proceed with planning. All scope decisions confirmed.

# Planning Transcript — 019 Command Compliance Gates

**Date:** 2026-03-12
**Participants:** IronQuartz (pi/claude-sonnet-4-thinking, driver) + EpicIce (crew-challenger)
**Outcome:** Plan and tasks written after resolving 7 challenges (2 fatal, 2 hard, 2 moderate, 1 minor)

---

## Phase: Research (IronQuartz)

Codebase research findings shared with EpicIce before writing any plan:

1. `scripts/` directory exists with 8 scripts — gate.sh is natural addition
2. Command frontmatter varies: most have just `description:`, codex-review.md has 5 keys
3. Command sizes: 52-343 lines (codex-review.md is largest)
4. Claude Code hooks: `UserPromptSubmit` exists (1 hook: premortem-suggest), `PostToolUse` has 5+ hooks — both are viable insertion points
5. Pi extensions: `installed-binary-guard.ts` is precedent for blocking behavior
6. Existing sentinel: `<!-- ground:complete:v1 -->` in ground.md
7. No workflow-state.md exists yet

## Phase: Challenge (EpicIce)

EpicIce raised 7 challenges against the proposed plan:

### FATAL #1: Plan doesn't enforce codex-review (most common failure)
- `/implement` only required `plan:complete:v1` sentinel, not codex-review
- The plan shipped enforcement for everything EXCEPT the most documented failure
- **Resolution:** Added `gate_warn_sentinels` key — exit code 2 (WARN) for missing codex-review sentinel. Soft enforcement now, one frontmatter change to harden later.

### FATAL #2: gate_must_not_create is prose enforcement, not structural
- Pre-flight check runs BEFORE execution — can't prevent fabrication DURING execution
- R7 says "deterministic code, not prose" but anti-fabrication enforcement IS prose
- **Resolution:** Three-layer anti-fabrication: (A) prose HARD CONSTRAINT, (B) `gate.sh verify` post-execution check, (C) PostToolUse hook as stretch goal. Honestly disclosed that Layer A is prose and Layer C is stretch goal.

### HARD #3: Sentinel format mismatch
- Existing codex-review headers (`<!-- Codex Review: APPROVED ...`) differ from proposed new format
- gate.sh needs concrete grep patterns decided at plan time
- **Resolution:** Backward-compatible grep matching (both formats), new format from `gate.sh record` only. codex-review.md Step 6 updated to use `gate.sh record` instead of manual header writing.

### HARD #4: Layer 2 hooks under-specified
- Phase 5 was 2 sentences for the most technically complex phase
- Claude Code and Pi have completely different hook models
- Spec path extraction from `$ARGUMENTS` is hard
- **Resolution:** Split into Phase 5a (Claude Code UserPromptSubmit), 5b (PostToolUse, stretch goal), 5c (Pi extension). Each with separate implementation, testing, and failure UX. Glob fallback for spec path resolution.

### MODERATE #5: gate_creates is dead metadata
- Nothing in the plan actually read gate_creates
- **Resolution:** `gate.sh record` reads gate_creates to know which files to write sentinels into.

### MODERATE #6: /shape spec-directory chicken-and-egg
- /shape saves to spec dir, but /shape can run before /issue creates the spec dir
- **Resolution:** /shape has no gate_requires. If no spec dir exists, agent tells user to run /issue first or saves transcript to temp location. gate.sh for /shape skips spec-dir checks when no dir argument provided.

### MINOR #7: Integration testing timing
- Phase 6 testing too late — should test after Phase 1+2
- **Resolution:** Added Phase 2.5 smoke test with specific pass/fail/warn scenarios against both test dir and existing spec 017.

## Phase: Agreement (EpicIce)

EpicIce agreed after all 7 concerns were resolved. Key note: Phase 5b (PostToolUse hook) explicitly marked as stretch goal — plan ships without it.

## Artifacts Produced

- `plan.md` — implementation approach with 6 phases, architecture decisions, requirement traceability
- `tasks.md` — 35 ordered checkable tasks across 6 phases + stretch goal

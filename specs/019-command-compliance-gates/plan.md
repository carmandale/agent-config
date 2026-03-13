---
title: "Implementation Plan — Command Compliance Gates"
date: 2026-03-12
bead: .agent-config-1v4
---

# Plan: 019 — Command Compliance Gates

> Planned collaboratively by IronQuartz + EpicIce (crew-challenger) on 2026-03-12.
> Full transcript: `planning-transcript.md`

## Overview

Implement Shape D (scripts + structured command headers + layered enforcement) from the shaped spec. The implementation creates `scripts/gate.sh`, adds structured frontmatter and HARD CONSTRAINT blocks to 5 pipeline commands, writes provenance sentinels, tracks pipeline state, and adds Layer 2 hooks where harness infrastructure exists.

## Architecture

### gate.sh — central validation script

Three subcommands:

| Subcommand | Purpose | Exit codes |
|------------|---------|------------|
| `gate <command> <spec-dir>` | Pre-flight check — reads command frontmatter, validates spec dir | 0 = PASS, 1 = FAIL, 2 = WARN |
| `record <command> <spec-dir>` | Post-completion — writes sentinels into artifacts, appends to workflow-state.md | 0 = OK, 1 = ERROR |
| `verify <command> <spec-dir>` | Post-execution check — verifies no forbidden files were created or modified since gate-check time | 0 = CLEAN, 1 = VIOLATION |

### Frontmatter keys

| Key | Purpose | Used by |
|-----|---------|---------|
| `gate_requires` | Files that must exist in spec dir | `gate` subcommand |
| `gate_sentinels` | Sentinel patterns that must be present in required files | `gate` subcommand |
| `gate_warn_sentinels` | Sentinel patterns that trigger warning (exit 2) if absent | `gate` subcommand |
| `gate_creates` | Files this command produces (sentinels written into these) | `record` subcommand |
| `gate_must_not_create` | Files this command must NOT produce | `verify` subcommand, HARD CONSTRAINT text |

### Sentinel format

**Matching (backward-compatible):**
```bash
# gate.sh matches both old and new formats
grep -q '<!-- [Cc]odex.[Rr]eview.*APPROVED\|codex-review:approved:v1' "$file"
```

**Writing (new format only):**
```
<!-- plan:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-12T19:30:00Z -->
<!-- codex-review:approved:v1 | rounds: 2 | model: gpt-5.3-codex | date: 2026-03-12T20:00:00Z -->
<!-- shape:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-12T18:00:00Z -->
<!-- issue:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-12T17:00:00Z -->
```

Sentinel format managed by `gate.sh record`, not by command prose. Single source of truth.

### Command frontmatter (all 5 commands)

```yaml
# commands/issue.md
---
description: Create a bead and numbered spec...
gate_creates: spec.md, log.md
gate_must_not_create: plan.md, tasks.md, codex-review.md, shaping-transcript.md
---

# commands/shape.md
---
description: Deep collaborative shaping session...
gate_creates: shaping-transcript.md
gate_must_not_create: spec.md, plan.md, tasks.md, codex-review.md
---

# commands/plan.md
---
description: Build a real implementation plan...
gate_requires: spec.md
gate_creates: plan.md, tasks.md, planning-transcript.md
gate_must_not_create: spec.md, codex-review.md
---

# commands/codex-review.md
---
name: codex-review
description: Send the current plan to OpenAI Codex CLI...
gate_requires: spec.md, plan.md
gate_sentinels: plan:complete:v1
gate_creates: codex-review.md
gate_must_not_create: spec.md, plan.md, tasks.md
---

# commands/implement.md
---
description: Execute a plan with two agents...
gate_requires: spec.md, plan.md, tasks.md
gate_sentinels: plan:complete:v1
gate_warn_sentinels: codex-review:approved:v1
gate_creates: code changes, commits
gate_must_not_create: spec.md, plan.md, tasks.md, codex-review.md
---
```

**Design decisions:**
- `/issue` and `/shape` have no `gate_requires` — they are entry points. Either can run first.
- `/plan` requires `spec.md` but no sentinel (because `/issue` is new and existing specs don't have sentinels). The sentinel chain starts at `/plan`.
- `/codex-review` requires `plan:complete:v1` sentinel — enforces that `/plan` actually ran.
- `/implement` hard-requires `plan:complete:v1`, soft-warns on missing `codex-review:approved:v1`. This addresses the most common failure (skipping codex-review) without hard-blocking. One frontmatter change upgrades warn to enforce later.
- `/shape` has no `gate_requires` — it remains a valid entry point before `/issue`. If a spec directory exists, the transcript is saved there. If no spec directory exists, `/shape` operates without one (the transcript lives in the conversation or a temp location until `/issue` creates the directory). gate.sh is not invoked when no spec directory is provided. This preserves the existing flow: shape → issue → plan.

### HARD CONSTRAINT block (R10)

Every command that invokes gate.sh gets this block immediately after frontmatter, before any guidance prose:

```markdown
## HARD CONSTRAINT — Gate Check

Run `scripts/gate.sh gate <command> specs/<NNN>-<slug>/` before any work.

- **Exit 1 (FAIL):** STOP COMPLETELY. Do NOT create the missing files. Do NOT offer
  to create them. Do NOT proceed with workarounds. Show the output to the user and wait.
- **Exit 2 (WARN):** Show the warning to the user and ask THEM whether to proceed.
  This is the USER's decision, not yours. Do NOT silently ignore. Do NOT decide
  for the user that "it's probably fine."
- **Exit 0 (PASS):** Proceed.

If you catch yourself about to rationalize past a FAIL result, STOP — you are doing
the exact thing this gate exists to prevent.
```

**Note on exit 2 (WARN):** WARN exists solely for `gate_warn_sentinels` — currently used only for codex-review soft enforcement on `/implement`. The agent cannot proceed past a WARN on its own — it must surface the warning and let the user decide. This is not a weakening of R10: exit 1 is an unconditional hard stop; exit 2 delegates the decision to the user rather than the agent.

### Pipeline state trail

`gate.sh record` appends to `workflow-state.md` in the spec directory:

```markdown
2026-03-12 18:47 | pi/claude-sonnet-4 | /issue | spec.md created
2026-03-12 19:10 | pi/claude-sonnet-4 | /shape | shaping-transcript.md created
2026-03-12 19:30 | pi/claude-sonnet-4 | /plan | plan.md + tasks.md created
2026-03-12 20:00 | codex/gpt-5.3-codex | /codex-review | codex-review.md — APPROVED round 2
2026-03-12 21:00 | pi/claude-sonnet-4 | /implement | started
```

### Layer 2: Hooks (harness-dependent)

**Phase 5a: Claude Code UserPromptSubmit hook** (`configs/claude/hooks/src/gate-check.ts` → `dist/gate-check.mjs`)
- TypeScript source in `src/`, built via existing esbuild pipeline to `dist/gate-check.mjs`
- Referenced in `settings.json` as `node "$HOME/.claude/hooks/dist/gate-check.mjs"`
- Consistent with existing hooks (import-validator, compiler-in-the-loop, etc.)
- Receives user prompt as JSON on stdin
- Pattern matches slash commands: `/plan `, `/implement `, `/codex-review `
- Extracts argument, resolves to spec dir with canonicalization:
  1. Strip leading `@` (some models prepend it)
  2. Expand `~/` to home directory
  3. `resolve()` to absolute path
  4. Verify resolved path is under the project's `specs/` directory (containment check)
  5. Fallback: glob `specs/*$arg*/` for partial matches
- Runs `gate.sh gate <command> <spec-dir>`, captures output
- If exit 1: outputs gate.sh failure text as system reminder on stdout via `console.log(JSON.stringify({ result: 'block', reason: gateOutput }))` — matching the `skill-activation-prompt.ts` blocking pattern. The agent receives the FAIL reason in context and the HARD CONSTRAINT text instructs it to stop.
- If exit 2: outputs gate.sh warning text on stdout via `console.log(JSON.stringify({ hookSpecificOutput: { hookEventName: 'UserPromptSubmit', additionalContext: gateWarning } }))` — matching the `memory-awareness.ts` context injection pattern.
- If spec dir not resolved: no output (passes through silently)
- **Note:** Both output paths use stdout via `console.log()`, consistent with all existing hooks in this repo. The `result: 'block'` path hard-blocks the prompt submission for exit 1 (agent cannot proceed, same as skill-activation-prompt.ts blocking). The `hookSpecificOutput` path provides advisory context for exit 2 (agent sees the warning, HARD CONSTRAINT text governs the response). The hook does not invent a new output contract.

**Phase 5b: Claude Code PostToolUse hook** (`configs/claude/hooks/src/gate-fabrication-guard.ts` → `dist/gate-fabrication-guard.mjs`) — STRETCH GOAL
- TypeScript source in `src/`, built via existing esbuild pipeline
- Fires on Write and Edit tool calls
- Would need session state to know which command is active and which spec dir
- Checks file path against `gate_must_not_create`
- **May be deferred** — session state tracking adds complexity. The plan is shippable without this. Layers A (prose) and B (gate.sh verify) cover anti-fabrication for v1.

**Phase 5c: Pi extension** (`configs/pi/extensions/gate-check.ts`)
- TypeScript extension using pi's `tool_call` event for bash commands
- Intercepts bash tool calls, checks if the command text starts with a slash command pattern
- Note: Pi extensions intercept tool_call events, not raw user prompts. Slash commands in pi are injected as user prompts by the harness, so the extension monitors for gate.sh invocations in bash calls and can warn if gate.sh wasn't run before spec-dir file operations begin
- Uses same path canonicalization as Phase 5a
- Separate implementation from Claude Code hook

### Anti-fabrication enforcement (three layers)

| Layer | Mechanism | Type | Catches |
|-------|-----------|------|---------|
| A | `gate_must_not_create` frontmatter + HARD CONSTRAINT text | Prose | Lazy bypass |
| B | `gate.sh verify <command> <spec-dir>` — post-execution check. Compares file mtimes against `<spec-dir>/.gate-<command>-timestamp` (e.g., `.gate-implement-timestamp`). Per-command, per-spec, no collision. Timestamp file cleaned up after verification. Added to `.gitignore`. | Voluntary script | Accidental fabrication |
| C | PostToolUse hook checking file writes (Phase 5b, stretch goal) | Structural | Motivated fabrication |

Honestly disclosed: Layer A is prose (the mechanism the spec says fails 40%). Layer B is voluntary. Layer C is structural but harness-dependent and stretch goal. For v1, Layers A+B are sufficient — they raise the bar significantly from the current state (zero enforcement).

### Backward compatibility (R6)

- Existing specs without sentinels: gate.sh warns ("no sentinel found") but does not block
- Existing codex-review.md headers (`<!-- Codex Review: APPROVED ...`): matched by backward-compatible grep
- No retroactive requirement: specs created before this ships work as before

## Requirement traceability

| Req | How addressed | Phase |
|-----|--------------|-------|
| R0 | gate.sh gate checks prerequisites before command runs | 1, 2 |
| R1 | gate_creates and gate_must_not_create frontmatter keys | 2 |
| R2 | gate_sentinels checked by gate.sh, written by gate.sh record | 1, 4 |
| R3 | Frontmatter keys at top of command, parsed by gate.sh | 2 |
| R4 | workflow-state.md appended by gate.sh record; read by gate.sh gate as supplementary prerequisite check when sentinels are absent (R6 backward compat) | 1, 4 |
| R5 | Only enforcement scaffolding added — command behavior unchanged | All |
| R6 | gate.sh warns for missing sentinels on pre-existing specs, doesn't block | 1 |
| R7 | gate.sh is deterministic bash — exit 0/1/2 | 1 |
| R8 | gate_must_not_create + HARD CONSTRAINT + gate.sh verify | 1, 2, 3 |
| R9 | gate.sh reads rules from command frontmatter — one source of truth | 1 |
| R10 | HARD CONSTRAINT block in every command | 3 |

## Risks

| Risk | Mitigation |
|------|------------|
| Agents skip running gate.sh (same failure mode with different surface) | R10 HARD CONSTRAINT text + Layer 2a: Claude Code hard-blocks on exit 1 via `result: 'block'` (agent cannot proceed — same mechanism as skill-activation blocking) and injects advisory context on exit 2; Layer 2b: Pi detects/warns if gate wasn't run but does not block. On Codex/Gemini, only Layer 1 + Layer 3 are available. |
| Frontmatter parsing edge cases (leading spaces, missing keys) | Phase 2.5 smoke test with real command files |
| Phase 5b (PostToolUse hook) complexity blocks the plan | Explicitly marked stretch goal — plan ships without it |
| Sentinel format mismatch between old and new | Backward-compatible grep matching resolves this |
| Hook spec path resolution is fragile | Path canonicalization (strip @, expand ~/, resolve(), containment check) + glob fallback + pass-through on resolution failure |
| verify false-positives on pre-existing files | Timestamp-based comparison: `gate` writes `<spec-dir>/.gate-<command>-timestamp`; `verify` compares forbidden file mtimes against that baseline. Per-command naming avoids collision. Cleaned up after verify. |
| Concurrent workflow-state.md writes | Append-only with line-level atomicity (echo >> file). Acceptable for single-agent-per-spec-dir usage pattern |

## Phase summary

| Phase | What | Files changed | Depends on |
|-------|------|---------------|------------|
| 1 | Create gate.sh | `scripts/gate.sh` (new) | — |
| 2 | Add frontmatter to commands | 5 command files | — |
| 2.5 | Smoke test gate.sh + frontmatter | (test only) | 1, 2 |
| 3 | Add HARD CONSTRAINT blocks | 5 command files | 2 |
| 4 | Add sentinel writing + state tracking to commands | 5 command files | 1 |
| 3.8 | Review /sweep and /audit-agents | `commands/sweep.md`, `commands/audit-agents.md` | 2 |
| 5a | Claude Code UserPromptSubmit hook | `configs/claude/hooks/src/gate-check.ts`, `configs/claude/settings.json` | 1 |
| 5b | Claude Code PostToolUse hook (STRETCH) | `configs/claude/hooks/src/gate-fabrication-guard.ts` | 1, 2 |
| 5c | Pi gate-check extension | `configs/pi/extensions/gate-check.ts` | 1 |
| 6 | End-to-end testing | (test only) | All |

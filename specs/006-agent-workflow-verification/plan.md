<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Status: REVISED -->
<!-- Revisions: Added Change 5 (verification), R-to-change traceability, R8-safe "typically" wording, redaction note, Gemini TOML content checks, codex-review included in full verification scope -->
---
title: "Plan: Agent workflow verification"
date: 2026-03-07
bead: .agent-config-gfi
---

# Implementation Plan

## Research Findings

Joint audit by JadeGrove + IronMoon of all 7 commands against shaping requirements:

| Command | Words | Next-step? (R0) | Artifact? (R1/R5) | Needs work? |
|---------|-------|-----------------|-------------------|-------------|
| `/ground` | 315 | ❌ No command suggestions | N/A (orientation) | Yes — add next-step |
| `/shape` | 365 | ✅ Suggests `/issue` | ✅ `shaping-transcript.md` | No |
| `/issue` | 367 | ✅ Suggests `/codex-review` or `/implement` | ✅ spec.md with bead | No |
| `/sweep` | 330 | ❌ "wait for approval" only | ✅ Creates bead + spec | Yes — add next-step |
| `/audit-agents` | 255 | ❌ Nothing | ⚠️ Fixes in-place (by design) | Yes — add next-step |
| `/codex-review` | 1950 | Partial — implies but doesn't name `/implement` | ✅ Best artifact contract | Yes — make explicit |
| `/implement` | 173 | N/A (terminal) | ✅ git commits | No |

## Requirement-to-Change Traceability

| Req | Addressed by | Verification |
|-----|-------------|--------------|
| R0 | Change 1 (next-step sentences in 4 commands) | Read each command, confirm next-step present |
| R1 | Change 2 (content markers in prompt-craft) | Read prompt-craft, confirm markers defined |
| R3 | Changes 1-3 + Change 5 | Commands: `ls` all 3 symlink paths × 5 files. Skills: `ls` at `~/.agents/skills/` and `~/.claude/skills/`. Gemini: verify 5 TOML files exist + `grep` for expected content |
| R4 | Already satisfied | Verify `/shape` contains "never solo" + transcript requirement |
| R5 | Already satisfied | Verify prompt-craft contains directory listing |
| R6 | Already satisfied | Verify codex-review contains transcript save step |
| R7 | Already satisfied | Verify `/shape` has literal file path; verify `/issue` references skill |
| R8 | Change 1 style constraint | All next-steps use "typically" language |
| R9 | Change 3 (`/help-workflow`) | File exists, lists all 7 commands |
| R10 | Accepted gap | Documented in spec |

## Approach: Five changes

### Change 1: Next-step suggestions (R0)

Add one conversational sentence to 4 commands:

- `/ground` — After "What are we working on?", add: for new work you'd typically start with `/shape` or `/issue`, for bug hunting try `/sweep`, for code review try `/audit-agents`.
- `/sweep` — After "wait for approval," add: once approved, you'd typically run `/codex-review <spec>` to review, then `/implement <spec>` to build.
- `/audit-agents` — At end, add: if findings warrant a spec, run `/issue` to create one, then `/codex-review`. If fixes were direct, commit and you're done.
- `/codex-review` — After approval flow, add: next step is typically `/implement <spec>`.

Style rule: One sentence each. Conversational. Phrased as "typical" guidance, not mandatory pipeline (preserves R8).

### Change 2: Artifact Contract content markers in prompt-craft skill

Expand the EXISTING "Anchor Trust in Artifacts" section with specific content markers:

- `codex-review.md`: Codex session ID, model identifier, VERDICT line, round-by-round feedback
- `shaping-transcript.md`: messages from two distinct named participants, requirements table, fit check, selected shape
- `spec.md` frontmatter: `bead:` with valid ID, `date:`, `title:`

Pattern guidance for future commands. Redaction note for sensitive content in transcripts.

### Change 3: `/help-workflow` command

New file: `commands/help-workflow.md`. Conversational listing of all commands in typical order with purposes and artifacts. Readable in 10 seconds.

### Change 4: Napkin update

Add entry for artifact contracts and next-step suggestions as standard patterns.

### Change 5: Full cross-agent verification (R3)

After all changes, verify ALL changed/new files across ALL agent surfaces:

**Commands** (ground, sweep, audit-agents, codex-review, help-workflow) × 3 paths:
- `~/.claude/commands/`, `~/.pi/agent/prompts/`, `~/.codex/prompts/`

**Skill** (prompt-craft) × 2 paths:
- `~/.agents/skills/meta/prompt-craft/SKILL.md`, `~/.claude/skills/meta/prompt-craft/SKILL.md`

**Gemini TOML** — 5 files, existence + content:
- Verify existence of all 5 `.toml` files
- `grep -q "typically" <file>` per changed command TOML (confirms next-step text propagated)
- `grep -q "workflow" ~/.gemini/commands/help-workflow.toml`

## What this does NOT do

- Does not change artifact-producing behavior (already working)
- Does not touch the shaping submodule (R10 accepted gap)
- Does not add pre-check hints or prerequisite lists (dropped during shaping)
- Does not add enforcement hooks or tooling
- Does not add spec artifacts to `/audit-agents` (intentional design)

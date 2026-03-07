---
title: "Plan: Agent workflow verification"
date: 2026-03-07
bead: .agent-config-gfi
---

# Implementation Plan

## Approach

Four focused changes. Each is small and independent. No architectural shifts — this is finishing and documenting what was built ad-hoc.

### 1. Add next-step suggestions to commands missing them (R0)

Commands that already suggest next steps: `/shape` → `/issue`, `/issue` → `/codex-review` or `/implement`.

Commands that need it:
- **`/ground`** — Currently ends with "What are we working on?" Add: typical next commands depending on intent (new work → `/shape` or `/issue`, bug hunting → `/sweep`, review → `/audit-agents`).
- **`/sweep`** — Currently ends with "wait for approval." Add: after approval, suggest `/codex-review <spec>` then `/implement <spec>`.
- **`/audit-agents`** — Currently ends with nothing specific. Add: suggest reviewing fixes or running `/codex-review` if a spec was produced.
- **`/implement`** — Currently self-contained. Fine as-is — implementation is the last step.

Style: one sentence at the end of each command, conversational. Not a "Next Steps" header with bullet points.

### 2. Add Artifact Contracts section to prompt-craft skill (B5)

Expand the existing "Anchor Trust in Artifacts" section in `skills/meta/prompt-craft/SKILL.md` with a formal Artifact Contract pattern:

- Define what an artifact contract is: a specific file with required content markers
- List the current contracts:
  - `codex-review.md`: must contain Codex session ID, model identifier, VERDICT line, round-by-round feedback
  - `shaping-transcript.md`: must contain messages from two distinct named participants, requirements table, fit check, selected shape
  - `spec.md` frontmatter: must contain `bead:` field with valid bead ID
- Define the pattern for future commands: if your command is a critical gate, define what artifact it produces and what content markers make it verifiable

Keep it concise. This is a pattern definition, not a process document.

### 3. Create `/help-workflow` command (B6)

New file: `commands/help-workflow.md`

Single paragraph listing all commands in typical workflow order with one-line descriptions and what artifact each produces. Must be conversational, not a table or formal reference doc. The user should be able to read it in 10 seconds and know what to run.

Commands to list: `/ground`, `/shape`, `/issue`, `/sweep`, `/audit-agents`, `/codex-review`, `/implement`

### 4. Update napkin

Add entry about artifact contracts and next-step suggestions being required for all commands.

## What this plan does NOT do

- Does not change any artifact-producing behavior (already working)
- Does not touch the shaping submodule (R10 accepted gap)
- Does not add pre-check hints or prerequisite lists to commands (B3 was explicitly dropped during shaping — over-structuring)
- Does not add enforcement hooks or tooling

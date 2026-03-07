<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Status: UNCHANGED -->
<!-- Revisions: none — spec is user intent, plan revisions conform to spec -->
---
title: "Agent workflow verification: artifact contracts + help-workflow"
date: 2026-03-07
bead: .agent-config-gfi
shaping: true
status: active
---

# Agent Workflow Verification System

## Source

Two-agent shaping session (QuickPhoenix ↔ IronMoon, 2026-03-07) identified gaps in the command suite built earlier this session. Full transcript: `shaping-transcript.md` in this directory.

## Problem

Seven commands were built ad-hoc across one session (`/ground`, `/shape`, `/issue`, `/sweep`, `/audit-agents`, `/codex-review`, `/implement`). Research audit found:

- **4 of 7 commands don't suggest what to run next.** `/shape` → `/issue` and `/issue` → `/codex-review` or `/implement` work. But `/ground`, `/sweep`, `/audit-agents` have no next-step, and `/codex-review` only implies `/implement` without naming it. (Joint audit by JadeGrove + IronMoon)
- **No discoverability mechanism.** Seven commands exist with no way for a user (or an agent) to see the full suite and typical workflow order.
- **Artifact contracts lack content markers.** prompt-craft's "Anchor Trust in Artifacts" section has the principle and the verified spec directory listing, but not specific content markers per artifact (e.g., "codex-review.md must contain session ID, VERDICT line"). Future commands have no contract template. (IronMoon finding)
- **`/audit-agents` has no spec artifacts** — by design. It fixes in-place rather than creating specs. Intentional for a review-and-fix command. (IronMoon finding)

## Requirements (from shaping — see transcript)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Each command suggests what to run next | Core goal |
| R1 | Critical gates produce artifacts — faking harder than doing | Must-have |
| R3 | Works across all agents via symlinks | Must-have |
| R4 | Shaping requires two independent perspectives — detection via transcript | Must-have |
| R5 | Verification glanceable from spec directory via file existence | Must-have |
| R6 | Codex review produces verifiable transcript | Must-have |
| R7 | Agents follow skill protocols as written | Core goal |
| R8 | Commands individually usable, no mandatory pipeline | Must-have |
| R9 | Discover full suite and typical workflow order | Nice-to-have |
| R10 | Protections work via command or skill directly | Accepted gap (submodule) |

**Constraint:** Commands preserve natural voice/intensity — no over-structuring.

## Selected Shape: B-modified

| Part | What it does |
|------|-------------|
| B1 | Commands stay short/forceful wrappers (no change) |
| B2 | Artifact contracts: define content markers for `codex-review.md`, `shaping-transcript.md`, spec.md frontmatter |
| B5 | prompt-craft skill gets formal Artifact Contract pattern section |
| B6 | `/help-workflow` command listing commands, typical order, artifacts |

## Acceptance Criteria

- [ ] `/ground` suggests next commands based on intent (new work → `/shape` or `/issue`, bugs → `/sweep`, review → `/audit-agents`)
- [ ] `/sweep` suggests `/codex-review <spec>` then `/implement <spec>` after approval
- [ ] `/audit-agents` suggests reviewing fixes or `/codex-review` if spec produced
- [ ] `/codex-review` suggests `/implement <spec>` after approval
- [ ] prompt-craft skill defines Artifact Contract pattern with content markers for each artifact type
- [ ] `/help-workflow` command exists — conversational, lists all 7 commands + artifacts, readable in 10 seconds
- [ ] All new/changed files accessible via agent symlinks

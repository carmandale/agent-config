---
title: "Agent workflow verification: artifact contracts + help-workflow"
date: 2026-03-07
bead: .agent-config-gfi
shaping: true
status: active
---

# Agent Workflow Verification System

## Source

After thousands of sessions, the user settled on a development workflow: `/ground` → `/shape` → `/issue` → `/codex-review` → `/implement`. The commands were built in a single session (this one) with insights about prompt craft (over-structuring kills agent performance), process theater (agents fake workflows), and artifact-based trust (file existence beats agent claims).

A two-agent shaping session (QuickPhoenix ↔ IronMoon) produced Shape B-modified. See `shaping-transcript.md` in this directory for the full negotiation.

## Problem

The command suite works but has gaps identified during shaping:

1. **No artifact contracts.** Commands like `/codex-review` save a transcript, and `/shape` saves a transcript for autonomous sessions, but there's no documented contract defining what each artifact must contain. Without that, agents produce empty or minimal files that satisfy existence checks but not content checks.

2. **Inconsistent next-step suggestions.** `/shape` suggests `/issue`. `/issue` suggests `/codex-review` or `/implement`. But `/ground`, `/sweep`, and `/audit-agents` don't suggest what to run next. The user has to remember the sequence.

3. **No discoverability.** Seven commands exist with no way for a user (or an agent) to see the full suite and typical workflow order.

4. **prompt-craft skill lacks the Artifact Contract pattern.** The "Anchor Trust in Artifacts" section describes the principle but doesn't define a reusable pattern that future command authors can follow.

## Requirements (from shaping)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Each command suggests what to run next — user always knows the next step | Core goal |
| R1 | Critical gates produce artifacts with real content (transcripts, IDs, timestamps) — faking harder than doing | Must-have |
| R3 | Works across all agents via symlinks | Must-have |
| R4 | Shaping requires two independent perspectives — solo invalid, detection via transcript | Must-have |
| R5 | Verification status glanceable from spec directory via file existence | Must-have |
| R6 | Codex review produces mechanically verifiable transcript | Must-have |
| R7 | Agents follow skill protocols as written, not their interpretation | Core goal |
| R8 | Commands individually usable, no mandatory pipeline | Must-have |
| R9 | User can discover the full suite and typical workflow order | Nice-to-have |
| R10 | Protections work whether entering via command or skill directly | Accepted gap for shaping (submodule) |

**Constraint:** Commands preserve natural voice/intensity — no over-structuring.

## Selected Shape: B-modified

| Part | Mechanism |
|------|-----------|
| B1 | Commands stay short/forceful wrappers |
| B2 | Artifact contracts: `codex-review.md` (session ID + VERDICT), `shaping-transcript.md` (two participant voices), spec.md (bead in frontmatter) |
| B5 | prompt-craft skill gets Artifact Contract pattern section |
| B6 | `/help-workflow` command listing commands + their artifacts |

## Acceptance Criteria

- Every command suggests what to run next (R0)
- prompt-craft skill has an "Artifact Contracts" section defining the pattern with specific content markers per artifact (B5)
- `/help-workflow` command exists listing all commands, typical order, and what artifact each produces (B6)
- Existing artifact behavior unchanged — just documented (B2)

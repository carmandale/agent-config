<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Status: UNCHANGED -->
<!-- Revisions: none — spec requirements confirmed covered by revised plan -->
---
title: "/ground session-awareness and tiered caching"
date: 2026-03-07
bead: .agent-config-cml
---

# /ground Session-Awareness and Tiered Caching

## Problem

The `/ground` command burns ~32% of context window (~36KB across AGENTS.md, README.md, napkin, handoffs, plus multiple investigation tool calls). This is correct and valuable on first invocation — forced file reads beat injected system-prompt content (napkin rule #3). But there is no mechanism to:

1. **Detect same-session re-invocation** — accidentally running `/ground` twice doubles the cost for zero benefit.
2. **Leverage cross-session stability** — if HEAD hasn't moved and napkin hasn't changed, re-doing full investigation is waste.

The forced re-read of AGENTS.md via tool call is non-negotiable (napkin rule #3: system prompt content gets wallpaper treatment; tool-call results get high attention). The optimization is about avoiding redundant *full* grounding when a lighter check suffices.

## Requirements

### R1: Same-session skip
If `/ground` has already been run in the current conversation (the agent has already produced a `## Grounded` summary), re-invocation must skip the full process. Cost should be near-zero — just reading the command file and recognizing prior grounding.

### R2: Cross-session light ground
When a cached grounding summary exists and is still fresh (same git HEAD, napkin unchanged, handoff unchanged), `/ground` should load the cached summary and run only a delta check (recent git log, status, any new handoffs). Cost target: ~5% of context vs 32%.

### R3: Full ground (current behavior, preserved)
On first invocation in a new session with no cache, or when cache is stale (HEAD moved, napkin changed, new handoffs), the full grounding runs exactly as it does today. All forced file reads stay.

### R4: Cache artifact
Write a `.ground-cache.md` file (location TBD — repo root or `.claude/`) containing:
- Timestamp of grounding
- Git HEAD SHA at time of grounding
- Napkin content hash
- Handoff file hash
- Condensed grounding summary (the `## Grounded` block)

### R5: Transparency
The agent must announce which tier it's using: "Full ground", "Light ground (cache hit, checking delta)", or "Already grounded this session — skipping."

## Acceptance Criteria

- [ ] Running `/ground` twice in the same session produces a skip message, not a full re-read
- [ ] A `.ground-cache.md` is written after every full or light ground
- [ ] When HEAD matches cache and napkin is unchanged, light ground runs instead of full
- [ ] When HEAD has moved or napkin changed, full ground runs despite cache existing
- [ ] The `## Grounded` summary is identical in quality regardless of tier
- [ ] Forced re-read of AGENTS.md via tool call is preserved in full ground tier (napkin rule #3)
- [ ] The command works across all agents that consume it (Pi, Claude Code, Codex, Gemini)

## Constraints

- `/ground` is a markdown command file, not executable code. All logic is expressed as agent instructions.
- The agent decides which tier to use based on observable state (conversation history, file existence, content comparison).
- No external dependencies — everything uses standard file I/O and git commands the agent already has.

## Out of Scope

- Changing what `/ground` investigates during full grounding
- Modifying the forced re-read rationale (napkin rule #3 is settled)
- Caching individual skill or command file reads

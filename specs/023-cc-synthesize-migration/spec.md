---
title: "cc-synthesize agent-agnostic migration"
date: 2026-03-15
bead: .agent-config-3on
---

<!-- issue:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-15T07:18:30Z -->

# cc-synthesize agent-agnostic migration

## Problem

`cc-synthesize` at `~/.claude/scripts/cc-synthesize` synthesizes ledger event files into a unified `current.md`. It depends on `~/.claude/hooks/dist/synthesize-ledgers.mjs` — a Claude hooks build artifact — at runtime. This was deferred from spec 020 because moving it to `tools-bin/` without resolving the hooks dependency creates a false sense of "managed."

The script calls:
```bash
node "$HOOKS_DIR/dist/synthesize-ledgers.mjs" "$EVENTS_DIR" "$OUTPUT_FILE"
```
where `HOOKS_DIR="${HOME}/.claude/hooks"`.

## Current State

- **Location**: `~/.claude/scripts/cc-synthesize` (unmanaged, Claude-specific)
- **Runtime dependency**: `~/.claude/hooks/dist/synthesize-ledgers.mjs` (Claude hooks build output)
- **Shared consumers**: None currently — no commands or skills reference it
- **Name**: `cc-` prefix is Claude-specific

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | cc-synthesize is agent-agnostic and tracked in agent-config | Core goal |
| R1 | Runtime dependency on Claude hooks is resolved (not just relocated) | Must-have |
| R2 | Agent-agnostic name (no `cc-` prefix) | Must-have |
| R3 | Passes `test-no-agent-specific-paths.sh` if/when consumers are added | Must-have |

## Scope

### In scope
- Resolve the `synthesize-ledgers.mjs` dependency
- Rename `cc-synthesize` → `agent-synthesize` (or similar)
- Move to `tools-bin/`

### Out of scope
- Adding new consumers (commands/skills that call it)
- The ledger event format itself

## Open Questions

This might benefit from `/shape` first — the hooks dependency has multiple valid approaches:
- Inline the Node logic into bash (eliminate dependency)
- Move `synthesize-ledgers.mjs` into agent-config alongside the script
- Keep at current location but document the dependency explicitly

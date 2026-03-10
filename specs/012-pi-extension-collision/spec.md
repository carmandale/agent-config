---
title: "fix: Resolve pi-messenger extension collision — user-level vs package-level"
type: fix
status: active
date: 2026-03-10
bead: .agent-config-12r
---

# fix: Resolve pi-messenger extension collision — user-level vs package-level

## Source

Pi agent startup shows:

```
[Extension issues]
  auto (user) ~/.pi/agent/extensions/pi-messenger/index.ts
    Tool "pi_messenger" conflicts with .../dev/pi-messenger/index.ts
  auto (user) ~/.pi/agent/extensions/pi-messenger/index.ts
    Command "/messenger" conflicts with .../dev/pi-messenger/index.ts
  auto (user) ~/.pi/agent/extensions/pi-messenger/index.ts
    Extension command 'messenger' ... conflicts ... Skipping.
```

## Problem

Pi finds the pi-messenger extension from **two sources** and both register the same `pi_messenger` tool and `/messenger` command:

| # | Path | Source | How it gets there |
|---|------|--------|-------------------|
| 1 | `~/.pi/agent/extensions/pi-messenger/index.ts` | npm package install (v0.13.0) | Auto-discovered via `extensions/*/index.ts` |
| 2 | `/Users/dalecarman/Groove Jones Dropbox/.../pi-messenger/index.ts` | Local dev fork (v0.14.0) | Loaded via `settings.json` → `packages` array |

### Root Cause (preliminary)

Two independent mechanisms load the same extension:
1. **Pi package system** (`settings.json` → `packages` → local path) — loads the dev fork
2. **Auto-discovery** (`~/.pi/agent/extensions/*/index.ts`) — finds the npm-installed copy

Neither mechanism knows about the other. Pi has no deduplication by tool/command name across discovery paths.

### Collision Class

This is the same pattern as spec 005 (gj-tool skill collision): two independent install mechanisms place the same logical component into overlapping discovery paths. The recurring nature suggests agent-config lacks a structural guard against this class of conflict.

### Severity

- Warning on every Pi startup
- Pi skips duplicates (non-blocking), but which version wins is unclear
- The npm copy (v0.13.0) may be stale vs the dev fork (v0.14.0)
- Confusing and recurring — same pattern as spec 005

## Outcome

- Pi agent starts with zero extension collision warnings for pi-messenger
- A single, canonical source owns the pi-messenger extension
- The fix survives `pi` updates, `npm` installs, and settings.json changes
- A structural guard prevents this class of collision from recurring across extensions (and ideally skills too)

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Pi agent starts with no pi-messenger extension collisions | Core goal |
| R1 | Single canonical source for the extension (not two copies) | Core goal |
| R2 | Fix survives routine setup operations (install.sh, npm install, pi update) | Durability |
| R3 | Document or automate a guard against extension/skill collision class | Prevention |

## Open Questions (for shaping)

- Should the npm copy be removed entirely (dev fork is canonical)?
- Should the dev path be removed from settings.json packages (npm is canonical)?
- Is there a pi-level mechanism to exclude/override extensions?
- What structural guard would prevent this collision class across all extensions AND skills?
- Is there a broader agent-config install/bootstrap check that should detect collisions?

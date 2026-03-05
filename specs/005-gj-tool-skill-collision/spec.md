---
shaping: true
title: "fix: Resolve gj-tool skill collision on Pi agent startup"
type: fix
status: active
date: 2026-03-05
bead: TBD
---

# fix: Resolve gj-tool skill collision on Pi agent startup

## Source

> after they update, pi-agent startup gets
>
> [Skill conflicts]
>   "gj-tool" collision:
>     ✓ auto (user) ~/.pi/agent/skills/gj-tool/SKILL.md
>     ✗ auto (user) ~/.agents/skills/gj-tool/SKILL.md (skipped)
>     ✗ auto (user) ~/.agents/skills/tools/gj-tool/SKILL.md (skipped)
>
> and then you fix it, and then it repeats.

## Problem

Pi agent finds the `gj-tool` skill in **three locations** on every startup, triggering a collision warning:

| # | Path | Source | How it gets there |
|---|------|--------|-------------------|
| 1 | `~/.pi/agent/skills/gj-tool/SKILL.md` | gj-tool `install.sh` | Direct `cp` from gj-tool repo |
| 2 | `~/.agents/skills/gj-tool/SKILL.md` | agent-config discovery symlink | `~/.agents/skills` → `~/.agent-config/skills/gj-tool` → `tools/gj-tool` |
| 3 | `~/.agents/skills/tools/gj-tool/SKILL.md` | agent-config actual | `~/.agents/skills` → `~/.agent-config/skills/tools/gj-tool/` |

Pi scans **both** `~/.pi/agent/skills/` and `~/.agents/skills/` (via agent-config symlink), finding the same SKILL.md three times.

### Root Cause

Two independent systems install the same skill to overlapping discovery paths:
1. **gj-tool's `install.sh`** copies SKILL.md directly to `~/.pi/agent/skills/gj-tool/`
2. **agent-config** has the skill at `skills/tools/gj-tool/` with a discovery symlink `skills/gj-tool → tools/gj-tool`

The cycle is: user runs `gj-tool/install.sh` → collision appears → someone removes the direct copy → next `gj-tool/install.sh` run restores it.

### Severity

- Non-blocking warning (Pi picks one and skips duplicates)
- But noisy, recurring, and confusing — erodes trust in the setup

## Outcome

- Pi agent starts with zero skill collision warnings for gj-tool
- Running gj-tool's `install.sh` does NOT re-create the collision
- A single, canonical source owns the gj-tool skill
- The fix survives repeated `install.sh` and `gj-tool install.sh` runs

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Pi agent starts with no gj-tool skill collisions | Core goal |
| R1 | gj-tool install.sh can be run repeatedly without re-creating collision | Must-have |
| R2 | All agents (Pi, Claude, Codex, Gemini) discover gj-tool skill | Must-have |
| R3 | gj-tool skill content stays in sync with gj-tool repo source | Must-have |
| R4 | Fix doesn't require manual intervention after either install script runs | Must-have |
| R5 | Changes to gj-tool's install.sh must be coordinated with BrightGrove agent | Must-have |

## Shapes

### A: agent-config owns skill, gj-tool stops installing

gj-tool's `install.sh` removes the skill copy step. agent-config's `skills/tools/gj-tool/` is the single source. gj-tool repo is the upstream; `vendor-sync.sh` or manual copy keeps agent-config current.

| Part | Mechanism |
|------|-----------|
| A1 | gj-tool `install.sh`: remove the `cp` to `~/.pi/agent/skills/gj-tool/` |
| A2 | gj-tool `install.sh`: add cleanup of stale `~/.pi/agent/skills/gj-tool/` if it exists |
| A3 | agent-config `vendor-sync.sh`: add gj-tool entry to sync from `~/dev/gj-tool/skill/` |
| A4 | agent-config `skills/tools/gj-tool/` remains the canonical location |

### B: gj-tool owns skill path, agent-config removes its copy

agent-config removes `skills/tools/gj-tool/` and the discovery symlink. gj-tool continues installing directly to `~/.pi/agent/skills/gj-tool/`. Other agents lose gj-tool skill unless gj-tool also installs to their paths.

| Part | Mechanism |
|------|-----------|
| B1 | agent-config: remove `skills/tools/gj-tool/` and `skills/gj-tool` symlink |
| B2 | gj-tool continues installing to `~/.pi/agent/skills/gj-tool/` |
| B3 | gj-tool adds install targets for other agents (Claude, Codex, Gemini) |

### C: gj-tool install.sh checks for agent-config and skips

gj-tool's install.sh detects whether agent-config is present and skips skill install if so. Hybrid: works with or without agent-config.

| Part | Mechanism |
|------|-----------|
| C1 | gj-tool `install.sh`: check if `~/.agents/skills/gj-tool/SKILL.md` exists |
| C2 | If exists → skip skill install, log "agent-config managing skill" |
| C3 | If not exists → install to `~/.pi/agent/skills/gj-tool/` as fallback |
| C4 | agent-config keeps its copy as the primary source |

## Fit Check

| Req | Requirement | Status | A | B | C |
|-----|-------------|--------|---|---|---|
| R0 | Pi agent starts with no gj-tool skill collisions | Core goal | ✅ | ✅ | ✅ |
| R1 | gj-tool install.sh can be run repeatedly without re-creating collision | Must-have | ✅ | ✅ | ✅ |
| R2 | All agents discover gj-tool skill | Must-have | ✅ | ❌ | ✅ |
| R3 | Skill content stays in sync with gj-tool repo | Must-have | ✅ | ✅ | ✅ |
| R4 | No manual intervention after either install | Must-have | ✅ | ✅ | ✅ |
| R5 | Changes coordinated with BrightGrove | Must-have | ✅ | ✅ | ✅ |

**Notes:**
- B fails R2: gj-tool would need to know about all agent discovery paths (Claude, Codex, Gemini) — violates separation of concerns
- A is cleanest: one owner (agent-config) for distribution, one upstream (gj-tool repo) for content
- C works but adds conditional logic that's fragile across machines with different setups

## Selected Shape: A

Shape A is the cleanest architecture. agent-config already distributes skills to all agents — that's its job. gj-tool should own the content (it's the upstream repo), agent-config should own the distribution.

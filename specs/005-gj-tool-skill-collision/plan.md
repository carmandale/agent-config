---
shaping: true
title: "Plan: gj-tool skill collision fix"
date: 2026-03-05
shape: A — agent-config owns distribution, gj-tool owns content
---

# Plan: gj-tool skill collision fix

## Overview

Eliminate the three-way gj-tool skill collision on Pi startup by establishing clear ownership:
- **gj-tool repo** = upstream source of truth for skill content
- **agent-config** = sole distribution channel to all agents

## Architecture (Before → After)

### Before (collision)
```
gj-tool install.sh
  └─ cp → ~/.pi/agent/skills/gj-tool/SKILL.md        ← PATH 1 (direct copy)

agent-config install.sh
  └─ symlink ~/.agents/skills → ~/.agent-config/skills/
       ├─ skills/gj-tool → tools/gj-tool              ← PATH 2 (discovery symlink)
       └─ skills/tools/gj-tool/SKILL.md               ← PATH 3 (actual file)

Pi scans: ~/.pi/agent/skills/ + ~/.agents/skills/ → sees all 3 → COLLISION
```

### After (clean)
```
gj-tool repo (~/dev/gj-tool/skill/)
  └─ vendor-sync.sh copies to agent-config

agent-config
  └─ skills/tools/gj-tool/SKILL.md                    ← SINGLE SOURCE
  └─ skills/gj-tool → tools/gj-tool                   ← discovery symlink (same file)
  └─ symlink ~/.agents/skills → ~/.agent-config/skills/

gj-tool install.sh
  └─ installs binary, config, logs only
  └─ cleans up legacy ~/.pi/agent/skills/gj-tool/ if present

Pi scans: ~/.pi/agent/skills/ (empty for gj-tool) + ~/.agents/skills/ → 1 skill → NO COLLISION
```

## Work Split

| Owner | Task | Repo |
|-------|------|------|
| BrightGrove | Remove skill copy from gj-tool install.sh | gj-tool |
| BrightGrove | Add cleanup of `~/.pi/agent/skills/gj-tool/` | gj-tool |
| VividArrow | Add gj-tool to vendor-sync.sh manifest | agent-config |
| VividArrow | Remove stale `~/.pi/agent/skills/gj-tool/` on this machine | agent-config (local) |
| Both | Verify: run gj-tool install.sh + Pi startup = 0 collisions | both |

## Risks

| Risk | Mitigation |
|------|------------|
| vendor-sync.sh gets stale (gj-tool skill updates not propagated) | gj-tool is a local repo — sync is a local cp, not a git clone. Low friction. |
| User without agent-config loses gj-tool skill after gj-tool install.sh update | gj-tool install.sh should check for agent-config presence; if absent, fall back to direct install (Shape C hybrid — nice-to-have, not required for us) |
| Pi scanning behavior changes in future versions | Discovery symlink + actual file in same tree is how all 300 skills work. Proven pattern. |

## Testing Strategy

1. Run `gj-tool/install.sh` → confirm no files created at `~/.pi/agent/skills/gj-tool/`
2. Run `~/.agent-config/install.sh` → confirm `~/.agents/skills/gj-tool/SKILL.md` resolves
3. Start Pi agent → confirm zero `[Skill conflicts]` output for gj-tool
4. Run `~/.agent-config/scripts/vendor-sync.sh gj-tool` → confirm skill content matches source

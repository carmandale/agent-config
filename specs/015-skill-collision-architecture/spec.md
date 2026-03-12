---
title: "Recurring skill collisions from overlapping discovery paths — architectural fix"
date: 2026-03-10
bead: .agent-config-1pz
---

# Recurring skill collisions from overlapping discovery paths

## The Pattern (Third Occurrence)

This is the third time the same collision class has surfaced:

| Spec | Date | Collision | What collided | Fix applied |
|------|------|-----------|---------------|-------------|
| 005 | 2026-03-05 | gj-tool | gj-tool's `install.sh` direct copy + agent-config discovery paths | Removed direct copy |
| 012 | 2026-03-10 | pi-messenger | npm-installed extension + settings.json package | Removed npm copy, added collision guard in bootstrap.sh |
| **015** | **2026-03-10** | **release** | **paperclip package skill + agent-config discovery symlink + agent-config actual dir** | **TBD — this spec** |

Each prior fix removed the specific duplicate instance. The architecture that produces these collisions is unchanged.

## Current Collision: `release`

```
[Skill conflicts]
  "release" collision:
    ✓ auto (user) ~/.pi/agent/skills/release/SKILL.md
    ✗ auto (user) ~/.agents/skills/release/SKILL.md (skipped)
    ✗ auto (user) ~/.agents/skills/workflows/release/SKILL.md (skipped)
```

Three paths, two independent sources:

| # | Path | Source | Mechanism |
|---|------|--------|-----------|
| 1 | `~/.pi/agent/skills/release/` | paperclip project | Symlink installed by package to Pi user skills dir |
| 2 | `~/.agents/skills/release/` | agent-config | `~/.agents/skills → ~/.agent-config/skills`, discovery symlink `release → workflows/release` |
| 3 | `~/.agents/skills/workflows/release/` | agent-config | Same chain, recursive scan finds real dir under `workflows/` |

Note: **paths 2 and 3 are self-collision within agent-config** — the discovery symlink pattern (`skills/release → workflows/release`) means the same SKILL.md is found at two paths by any recursive scanner.

## Root Problem (Not the Symptom)

The symptom is "release collision warning on Pi startup." But the root problem is architectural:

### 1. Discovery symlinks cause self-collision

agent-config uses the pattern:
```
skills/workflows/release/SKILL.md    ← actual file
skills/release → workflows/release   ← discovery symlink
```

Any tool that recursively scans `skills/` will find both `skills/release/SKILL.md` and `skills/workflows/release/SKILL.md` — the same file via two paths. This is an inherent property of the discovery symlink design, not a bug in any specific skill.

**Scale**: There are ~261 discovery symlinks. Each one is a potential self-collision for any recursive scanner.

### 2. Multiple overlapping discovery paths with no isolation

Pi discovers skills from multiple independent paths:
- `~/.pi/agent/skills/` — user-level skills dir (packages install here)
- `~/.agents/skills/` → `~/.agent-config/skills/` — shared skills (Codex/Gemini/Pi)
- Package-declared skills (via `settings.json` → `packages` → `pi.skills`)

These paths can overlap when a package installs a skill with the same name as one in agent-config. There's no namespace, no priority system, no deduplication — just a collision warning.

### 3. Guards are detective, not preventive

The collision guard from spec 012 (`scripts/lib/collision-check.sh`) runs during `bootstrap.sh check` and `install.sh` but:
- It only catches known patterns (package-vs-extensions, direct copies)
- It doesn't catch the self-collision from discovery symlinks
- It doesn't prevent new packages from creating collisions
- It runs after-the-fact, not at the moment of conflict creation

## The Real Question

Are we going to keep playing whack-a-mole (fix each collision instance as it surfaces), or fix the architecture that creates them? Three occurrences in 5 days establishes a pattern.

## Scope

- **In scope**: Architectural fix to eliminate the class of collision, not just this instance
- **In scope**: The self-collision problem from discovery symlinks
- **In scope**: Cross-source collision (external packages vs agent-config)
- **Out of scope**: Pi's internal discovery/deduplication logic (we don't control Pi's scanner)
- **Out of scope**: Changing how external packages declare skills (we don't control paperclip)

## Acceptance Criteria

1. `release` (and all other skills) produce zero collision warnings on Pi startup
2. Adding a new skill to agent-config does not create self-collision
3. External packages that happen to share a skill name with agent-config don't produce collisions
4. The fix survives `install.sh`, `git pull`, and new skill additions without manual intervention
5. The solution works for all agents that share the `~/.agents/skills/` path (Codex, Gemini, Pi)

## Constraints

- Cannot modify Pi's skill scanner source code
- Cannot control how external packages (paperclip etc.) name their skills
- Must maintain backward compatibility — skills must still be discoverable by all agents
- Must not require per-skill manual configuration

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Zero skill collision warnings on Pi startup | Core goal |
| R1 | Adding a new skill to agent-config never creates self-collision | Must-have |
| R2 | External packages sharing a skill name don't produce collisions (via naming convention + guard) | Must-have |
| R3 | All agents (Pi, Claude Code, Codex, Gemini) continue discovering skills correctly | Must-have |
| R4 | Zero per-skill manual maintenance | Must-have |
| R5 | Survives git pull, install.sh, new package installs | Must-have |
| R6 | Structural prevention for self-collision; convention + detective guard for cross-source | Must-have |

## Selected Shape: B — Symlink cleanup + clean ownership boundary

| Part | Mechanism |
|------|-----------|
| **B1** | Delete all 261 discovery symlinks from `skills/` top level |
| **B2** | Remove `testflight` symlink from `~/.pi/agent/skills/` (redundant — already in agent-config via `~/.agents/skills/`) |
| **B3** | Rename agent-config's `release` → `release-prep` (convention: agent-config avoids bare generic names packages are likely to claim) |
| **B4** | Add `install.sh` guard: scan `~/.pi/agent/skills/` for symlinks pointing into `~/.agent-config/` and warn (redundant second paths) |
| **B5** | Update `install.sh` to stop creating discovery symlinks for new skills |

See `shaping-transcript.md` for full exploration of shapes A, B, C and fit check.

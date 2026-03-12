---
shaping: true
---

# Shaping Transcript — Spec 015: Skill Collision Architecture

**Participants**: User + Pi/claude-sonnet-4
**Date**: 2026-03-10

---

## Frame

**Source**: Third recurrence of skill collision class — specs 005 (gj-tool), 012 (pi-messenger), now `release`. User asks: "Are we solving symptoms, or are we solving ROOT problems in the architecture?"

**Problem**: agent-config's skill directory architecture creates two classes of collision that recur every time a new skill or package is added:
1. **Self-collision** — 261 discovery symlinks (`skills/X → category/X`) cause recursive scanners (Pi) to find every skill twice within the same tree
2. **Cross-collision** — Multiple overlapping global scan paths (`~/.pi/agent/skills/` + `~/.agents/skills/`) mean external packages inevitably collide with agent-config skills

**Outcome**: Zero collision warnings. Adding a skill to agent-config or installing a package never produces collisions. The architecture makes self-collision impossible and cross-collision manageable.

---

## Investigation

### Pi Skill Discovery (from docs/skills.md)

Pi scans these locations:
- Global: `~/.pi/agent/skills/`, `~/.agents/skills/`
- Project: `.pi/skills/`, `.agents/skills/` (cwd + ancestors)
- Packages: `skills/` dirs or `pi.skills` in package.json
- Settings: `skills` array
- CLI: `--skill <path>`

Discovery rules: "Recursive SKILL.md files under subdirectories"
Collision handling: "Name collisions (same name from different locations) warn and keep the first skill found."

### Current `release` Collision Traced

| # | Path | Source | Mechanism |
|---|------|--------|-----------|
| 1 | `~/.pi/agent/skills/release/` | paperclip | Manual symlink → paperclip dev repo |
| 2 | `~/.agents/skills/release/` | agent-config | `~/.agents/skills → ~/.agent-config/skills`, discovery symlink `release → workflows/release` |
| 3 | `~/.agents/skills/workflows/release/` | agent-config | Same chain, recursive scan finds real dir under `workflows/` |

Paths 2+3 = self-collision within agent-config. Path 1 vs 2/3 = cross-source collision.

### Key Findings

1. **Commands already use full category paths** (`skills/workflows/workflows-plan/SKILL.md`), not flat symlinks — removing discovery symlinks won't break references
2. **Only ONE actual name collision** between paperclip and agent-config: `release`
3. **testflight in `~/.pi/agent/skills/`** is a symlink back INTO agent-config — redundant second path
4. **Paperclip skills were manually symlinked**, not auto-installed by Pi's package system
5. **All 261 discovery symlinks are dead weight** — every agent scans recursively

### The Two Skills Named `release`

- **agent-config**: `name: release` — "Release preparation workflow - security audit → E2E tests → review → changelog → docs"
- **paperclip**: `name: release` — "Coordinate a full Paperclip release across engineering verification, npm, GitHub, website publishing, and announcement follow-up"

Genuinely different skills with the same generic name.

---

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Zero skill collision warnings on Pi startup | Core goal |
| R1 | Adding a new skill to agent-config never creates self-collision | Must-have |
| R2 | External packages sharing a skill name don't produce collisions (via naming convention + guard) | Must-have |
| R3 | All agents (Pi, Claude Code, Codex, Gemini) continue discovering skills correctly | Must-have |
| R4 | Zero per-skill manual maintenance | Must-have |
| R5 | Survives git pull, install.sh, new package installs | Must-have |
| R6 | Structural prevention for self-collision; convention + detective guard for cross-source | Must-have |

---

## Shapes

### A: Symlink cleanup only (partial fix)

| Part | Mechanism |
|------|-----------|
| **A1** | Delete all 261 discovery symlinks from `skills/` top level |
| **A2** | Update `install.sh` to stop creating discovery symlinks for new skills |

### B: Symlink cleanup + clean ownership boundary

| Part | Mechanism |
|------|-----------|
| **B1** | Delete all 261 discovery symlinks from `skills/` top level |
| **B2** | Remove `testflight` symlink from `~/.pi/agent/skills/` (redundant — already in agent-config via `~/.agents/skills/`) |
| **B3** | Rename agent-config's `release` → `release-prep` (convention: agent-config avoids bare generic names packages are likely to claim) |
| **B4** | Add `install.sh` guard: scan `~/.pi/agent/skills/` for symlinks pointing into `~/.agent-config/` and warn (redundant second paths) |
| **B5** | Update `install.sh` to stop creating discovery symlinks for new skills |

### C: Consolidate — single skill tree through agent-config

| Part | Mechanism |
|------|-----------|
| **C1** | Delete all 261 discovery symlinks from `skills/` top level |
| **C2** | Move paperclip skills from `~/.pi/agent/skills/` into agent-config as external symlinks |
| **C3** | Remove testflight from `~/.pi/agent/skills/` |
| **C4** | Empty `~/.pi/agent/skills/` entirely |
| **C5** | Add `install.sh` guard: `~/.pi/agent/skills/` must be empty |
| **C6** | Update `install.sh` to stop creating discovery symlinks |

---

## Fit Check

| Req | Requirement | Status | A | B | C |
|-----|-------------|--------|---|---|---|
| R0 | Zero skill collision warnings on Pi startup | Core goal | ❌ | ✅ | ✅ |
| R1 | Adding a new skill to agent-config never creates self-collision | Must-have | ✅ | ✅ | ✅ |
| R2 | External packages sharing a skill name don't collide | Must-have | ❌ | ✅ | ✅ |
| R3 | All agents continue discovering skills correctly | Must-have | ✅ | ✅ | ✅ |
| R4 | Zero per-skill manual maintenance | Must-have | ✅ | ✅ | ✅ |
| R5 | Survives git pull, install.sh, new packages | Must-have | ✅ | ✅ | ❌ |
| R6 | Structural prevention for self-collision; convention + guard for cross-source | Must-have | ❌ | ✅ | ✅ |

**Notes:**
- A fails R0, R2, R6: no mechanism for cross-source conflicts
- B passes all: structural for self-collision (symlink removal), convention + guard for cross-source
- C fails R5: external packages that auto-install to `~/.pi/agent/skills/` defeat the consolidation

---

## Decision

**Selected: Shape B** — Symlink cleanup + clean ownership boundary

**Rationale**: The honest architectural assessment is that self-collision is fully fixable at the root (delete discovery symlinks — they serve no purpose), while cross-collision is inherently constrained by Pi's hardcoded dual scan paths. Shape B is structural where we control the architecture, pragmatic where we don't. Shape C's consolidation is theoretically cleaner but fragile to external package behavior we can't control. "Structural where we can be, convention where we can't" — user's words.

**Architectural principle established**: Discovery symlinks were a design mistake. Pi (and all agents) scan recursively. Flat access symlinks create self-collision. Remove them and don't recreate them.

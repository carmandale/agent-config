---
shaping: true
---

# Agent Config Portability — Shaping

## Frame

### Source

> I noticed that in the current install on laptop, that in codex, a tool was
> missing... we should fix this before we propagate to mini, but this could
> reveal some deeper structural/architectural issues that we might need to
> consider

> my North Star doesn't want AI code bloat and over-engineering, but it also
> doesn't want tech debt. and you are about to bake critical tech debt into the
> actual foundation. bad idea. we need to slow down, back up, and fix this at
> the root level.

> my initial thought is that we don't want external tools like this, but want
> everything in agent-config.

> my instinct is to NOT put ourselves in the position of redesigning other
> vendors intent. that would be out of scope for this and arrogant too.

### Problem

`~/.agent-config` is supposed to be the single source of truth for all agent
configuration. In practice, 11 symlinks escape the repo boundary to
machine-local paths that break on any other machine. The compound plugin
symlink imports an entire 19-skill directory from an external repo. Skills are
scattered across 7 category subdirs, 60 uncategorized top-level dirs, and
external locations with no placement policy. This structural debt makes parity
impossible to achieve reliably and will only get worse as more skills are added.

### Outcome

`~/.agent-config` is fully self-contained. Cloning the repo and running
install gives you everything. No external symlinks. Clear rules for where
things go. Parity between machines is a property of the repo, not operator
discipline.

### Out of Scope

How each agent (Claude Code, Codex, Pi) discovers and presents commands vs
skills is a vendor design decision. We don't redesign their discovery
mechanisms or try to bridge gaps between them. We make the repo self-contained;
each agent consumes it however it was designed to.

---

## Current State (CURRENT)

### External Symlinks (11 total, 2 broken)

| # | Skill | Target | Size | Status |
|---|-------|--------|------|--------|
| 1 | breadboarding | ~/dev/shaping-skills/breadboarding | 60K | resolves |
| 2 | shaping | ~/dev/shaping-skills/shaping | 24K | resolves |
| 3 | napkin | ~/dev/napkin | 140K | resolves (has own .git) |
| 4 | surf | ~/Groove Jones Dropbox/.../surf-cli/skills/surf | 20K | resolves |
| 5 | compound | ~/Groove Jones Dropbox/.../compound-engineering/skills | 996K (19 skills) | resolves |
| 6 | remotion-best-practices | ~/.agents/skills/remotion-best-practices | 168K | resolves |
| 7 | find-skills | ~/.agents/skills/find-skills | 8K | resolves |
| 8 | swiftui-expert-skill | ../../../.agents/skills/swiftui-expert-skill | 148K | BROKEN |
| 9 | xcode-26 | ~/Groove Jones Dropbox/.../Xcode26-Agent-Skills/xcode-26 | small | resolves |
| 10 | last30days | ~/Groove Jones Dropbox/.../last30days-skill | 28MB | resolves |
| 11 | cc3/interactive-shell/SKILL.md | ~/.pi/agent/extensions/interactive-shell/SKILL.md | small | BROKEN |

Also: `create-handoff -> cc3/create-handoff` is broken (internal).

### Structural Inventory

| Surface | Count |
|---------|-------|
| SKILL.md files total | 275 |
| Category dirs (cc3, personal, tools, compound, ralph-o, swift, setup) | 7 |
| Skills in categories | ~167 |
| Uncategorized top-level real dirs | 60 |
| Top-level symlinks (category shortcuts) | 190 |
| External symlinks | 11 |
| Commands (commands/*.md) | 46 |
| Command/skill overlaps | 4 |
| Compound plugin duplicate skills | 3 |

### Discovery Asymmetry

| Agent | Discovers commands/ | Discovers skills/ |
|-------|--------------------|--------------------|
| Claude Code | Yes (as /slash) | Yes (auto, as /slash) |
| Codex | Yes (as /prompts) | No auto-discovery; uses `Skill: open SKILL.md` fallback |
| Pi | Yes (as /commands) | Yes (auto) |

---

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | agent-config is fully self-contained — no symlinks escape the repo | Core goal |
| R1 | Cloning + install.sh gives a working setup on any machine | Core goal |
| R2 | Clear placement policy: every skill has exactly one canonical location in the repo | Must-have |
| R3 | External-origin skills are vendored or submoduled — no machine-local symlinks | Must-have |
| R4 | Broken symlinks are removed | Must-have |
| R5 | No duplicate skills (same skill in both compound plugin dir and agent-config) | Must-have |
| R6 | Skills that are actively developed in external repos can still be updated easily | Must-have |
| R7 | The migration doesn't break currently-working agent skill discovery | Must-have |

---

## Shapes

### A: Vendor Everything, Flatten Categories

Vendor all external skills into agent-config. Eliminate category subdirs. All
skills live at `skills/<name>/SKILL.md` — flat, no nesting.

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **A1** | Copy all 11 external skill contents into `skills/<name>/` as real dirs | |
| **A2** | Remove all external symlinks | |
| **A3** | Remove all category dirs (cc3/, personal/, tools/, compound/, ralph-o/, swift/, setup/) | ⚠️ |
| **A4** | Move all category-nested skills to top level | ⚠️ |
| **A5** | Remove all top-level symlinks (they're just shortcuts to categories, no longer needed) | |
| **A6** | Remove broken symlinks (create-handoff, swiftui-expert-skill, interactive-shell) | |
| **A7** | For external repos that are actively developed, add a `scripts/vendor-update.sh` | |

### B: Vendor Externals, Keep Categories

Vendor external skills in but preserve the current category organization.
Fix broken symlinks. Don't restructure internals.

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **B1** | Copy all 11 external skill contents into appropriate category dirs | |
| **B2** | Remove all external symlinks | |
| **B3** | Keep category dirs as-is (cc3/, personal/, tools/, etc.) | |
| **B4** | Keep top-level symlinks pointing into categories | |
| **B5** | Remove broken symlinks | |
| **B6** | Move 60 uncategorized top-level dirs into appropriate categories + update symlinks | ⚠️ |
| **B7** | For external repos, add `scripts/vendor-update.sh` | |

### C: Vendor Externals Only (Minimal Change)

Only fix the external dependency problem. Don't touch internal organization.

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **C1** | Copy all 11 external skill contents into their current top-level locations as real dirs | |
| **C2** | Remove all external symlinks, replace with real dirs | |
| **C3** | Remove broken symlinks | |
| **C4** | For external repos, add `scripts/vendor-update.sh` | |
| **C5** | Leave categories, top-level symlinks, and uncategorized dirs as-is | |

### D: Hybrid Sync, Functional Taxonomy ✅ SELECTED

Submodule external repos that are skill-only. Vendor skills that are
subdirectories of larger projects. Replace origin-based categories (cc3,
personal) with function-based taxonomy. File all 275 skills. Resolve
duplicates.

**Category taxonomy** (from spike):

| Category | Decision rule (ask in order) | ~Count |
|----------|------------------------------|:------:|
| tools/ | Wraps external CLI/API/service | 60 |
| review/ | Analyzes/reviews code or content | 25 |
| workflows/ | Orchestrates multi-step dev processes | 45 |
| meta/ | Agent behavior rules, patterns, skill system | 55 |
| domain/ | Technology-specific knowledge | 90 |

domain/ sub-groups: `domain/swift/`, `domain/compound/`, `domain/ralph/`,
`domain/notion/`, `domain/gitnexus/`, `domain/shaping/`, `domain/math/`

**Agent discovery is unaffected** — agents discover via top-level symlinks
(`skills/bird -> tools/bird`), not category paths.

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **D1** | Add git submodules for skill-repos: shaping-skills (breadboarding + shaping), napkin, last30days (skill files only, skip assets/) | |
| **D2** | Vendor skills from larger projects: surf (from surf-cli), compound 19 skills (from compound-engineering-plugin), xcode-26 (from Xcode26-Agent-Skills), remotion-best-practices, find-skills (from .agents/skills/) | |
| **D3** | Remove all external symlinks, replace with submodule paths or vendored real dirs | |
| **D4** | Remove broken symlinks (create-handoff, swiftui-expert-skill, cc3/interactive-shell) | |
| **D5** | Replace origin-based categories (cc3/, personal/, setup/) with functional taxonomy: tools/, review/, workflows/, meta/, domain/ | |
| **D6** | Reclassify all 275 skills into the new taxonomy using the sequential decision rule (see spike-categories.md for full mapping) | |
| **D7** | Resolve 3 compound duplicates (document-review, orchestrating-swarms, setup): diff both copies, keep the more complete one | |
| **D8** | Add `scripts/vendor-sync.sh` for vendored skills (records provenance: source repo, path, commit) | |
| **D9** | Update install.sh to run `git submodule update --init` if submodules present | |
| **D10** | Regenerate all top-level symlinks to point at new category locations | |

---

## Fit Check

| Req | Requirement | Status | A | B | C | D |
|-----|-------------|--------|---|---|---|---|
| R0 | agent-config is fully self-contained | Core goal | ✅ | ✅ | ✅ | ✅ |
| R1 | Cloning + install.sh gives working setup | Core goal | ✅ | ✅ | ✅ | ✅ |
| R2 | Clear placement policy for every skill | Must-have | ✅ | ❌ | ❌ | ✅ |
| R3 | External-origin skills are vendored or submoduled | Must-have | ✅ | ✅ | ✅ | ✅ |
| R4 | Broken symlinks removed | Must-have | ✅ | ✅ | ✅ | ✅ |
| R5 | No duplicate skills | Must-have | ✅ | ✅ | ❌ | ✅ |
| R6 | External-origin skills easily updatable | Must-have | ❌ | ❌ | ❌ | ✅ |
| R7 | Migration doesn't break agent skill discovery | Must-have | ✅ | ✅ | ✅ | ✅ |

**Notes:**
- A fails R6: Vendor-only with a sync script, but no git-managed version pinning for actively-developed skill repos
- B fails R2: Categories exist but 60 skills are uncategorized and no policy prevents future drift
- B fails R6: Same as A
- C fails R2: Doesn't touch internal organization at all
- C fails R5: Doesn't address compound plugin duplicates
- C fails R6: Same as A
- D passes all: submodules for skill-repos (R6), enforced categories (R2), vendored + provenance for the rest (R3)

---

## Resolved Questions

1. **last30days:** Vendor skill files only (SKILL.md, scripts/, fixtures/, tests/ = ~250K). Skip assets/ (14MB demo images) and .git/. Record provenance.

2. **Upstream sync:** Hybrid — git submodules for repos that ARE skills (shaping-skills, napkin, last30days). Vendor with provenance script for skills extracted from larger projects (surf, compound, xcode-26, remotion, find-skills).

3. **Categories:** Keep meaningful categories. Enforce placement — every skill in exactly one category. File the 60 strays.

4. **Vendor discovery redesign:** Out of scope. Each agent's discovery mechanism is a vendor design decision.

5. **Compound 19 skills:** Stay grouped as `compound/` when vendored in. Clear provenance.

6. **Duplicate resolution (D7):** Compare both copies of document-review, orchestrating-swarms, and setup. Keep whichever is more complete/current. (Requires spike.)

## Open Questions

1. **D7 duplicate resolution:** Need to diff both copies of document-review, orchestrating-swarms, and setup to pick the canonical version. (Small task during execution, not a blocker for shape selection.)

---

## Spike: Category Taxonomy — RESOLVED

See `spike-categories.md` for full analysis. Summary:

- 5 functional categories: tools/, review/, workflows/, meta/, domain/
- domain/ has named sub-groups (swift/, compound/, ralph/, notion/, gitnexus/, shaping/, math/)
- Sequential decision rule for placement
- Full draft mapping of all 60 strays
- D6 flag cleared — taxonomy is defined

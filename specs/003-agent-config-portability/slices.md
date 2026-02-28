---
shaping: true
---

# Agent Config Portability — Slices

Shape: **D (Hybrid Sync, Functional Taxonomy)**
Shaping doc: `specs/003-agent-config-portability/shaping.md`
Spike: `specs/003-agent-config-portability/spike-categories.md`

## Slice Overview

```
V1: Clean house ──→ V2: Submodule skill-repos ──→ V3: Vendor externals ──→ V4: Taxonomy restructure
     (D4)                (D1, D9)                    (D2, D3, D7, D8)        (D5, D6, D10)
```

Each slice is independently verifiable. Earlier slices reduce risk for later
ones (broken symlinks cleaned before submodules, externals resolved before
restructure).

---

## V1: Clean House

**Parts:** D4
**Goal:** Remove all broken symlinks. Zero broken references in the repo.

| What | Action |
|------|--------|
| `skills/create-handoff -> cc3/create-handoff` | Delete (target never existed) |
| `skills/swiftui-expert-skill -> ../../../.agents/skills/swiftui-expert-skill` | Delete broken symlink; vendor from `~/.agents/skills/swiftui-expert-skill` (148K, resolves on laptop) into `skills/swiftui-expert-skill/` as real dir |
| `skills/cc3/interactive-shell/SKILL.md -> ~/.pi/agent/extensions/...` | Delete broken file-level symlink; check if `skills/interactive-shell/` (top-level real dir) already has the content |

**Verify:**
```bash
find skills -type l ! -exec test -e {} \; -print
# Expected: empty output
```

---

## V2: Submodule Skill-Repos

**Parts:** D1, D9
**Goal:** Add git submodules for repos that ARE skills. Update install.sh.

| Repo | Submodule path | Skills provided |
|------|---------------|-----------------|
| shaping-skills | `skills/domain/shaping/shaping-skills` | breadboarding, shaping |
| napkin | `skills/domain/shaping/napkin` | napkin |
| last30days | `skills/tools/last30days` | last30days (skip assets/) |

**Actions:**
1. `git submodule add <repo-url> <submodule-path>` for each
2. For last30days: add `.gitmodules` config or post-checkout hook to exclude `assets/`
3. Remove the old external symlinks for breadboarding, shaping, napkin, last30days
4. Create top-level discovery symlinks pointing into submodule locations
5. Update `install.sh` to include `git submodule update --init --recursive`

**Verify:**
```bash
git submodule status
# Expected: 3 submodules with pinned commits

# Discovery still works:
ls skills/breadboarding/SKILL.md  # or skill.md
ls skills/napkin/SKILL.md
ls skills/last30days/SKILL.md
```

---

## V3: Vendor Remaining Externals

**Parts:** D2, D3, D7, D8
**Goal:** Copy remaining external skills into repo. Zero external symlinks.
Resolve duplicates. Add provenance tracking.

### Vendor targets

| Skill | Source | Vendor to | Size |
|-------|--------|-----------|------|
| surf | ~/...surf-cli/skills/surf | skills/tools/surf/ | 20K |
| compound (19 skills) | ~/...compound-engineering/.../skills | skills/domain/compound/ | 996K |
| xcode-26 | ~/...Xcode26-Agent-Skills/xcode-26 | skills/domain/swift/xcode-26/ | small |
| remotion-best-practices | ~/.agents/skills/remotion-best-practices | skills/domain/remotion-best-practices/ | 168K |
| find-skills | ~/.agents/skills/find-skills | skills/tools/find-skills/ | 8K |

### Duplicate resolution (D7)

| Skill | Compound plugin copy | agent-config copy | Action |
|-------|---------------------|-------------------|--------|
| document-review | Diff both | skills/document-review/ | Keep more complete, delete other |
| orchestrating-swarms | Diff both | skills/orchestrating-swarms/ | Keep more complete, delete other |
| setup | Diff both | skills/setup/ | Keep more complete, delete other |

### Provenance script (D8)

Create `scripts/vendor-sync.sh` with a manifest:
```bash
# Manifest: vendored skill -> source repo, path, last-synced commit
# surf -> git@github.com:user/surf-cli.git :: skills/surf/ @ <commit>
# compound/* -> git@github.com:user/compound-engineering-plugin.git :: plugins/.../skills/ @ <commit>
# ...
```

Running `scripts/vendor-sync.sh` copies latest from known source paths and
records the new commit SHA.

**Verify:**
```bash
# Zero external symlinks:
find skills -type l -exec readlink {} \; | grep -E '^/|^\.\.\./|^~'
# Expected: empty output

# Vendored skills resolve:
ls skills/tools/surf/SKILL.md
ls skills/domain/compound/brainstorming/SKILL.md
ls skills/domain/swift/xcode-26/SKILL.md

# Provenance recorded:
cat scripts/vendor-sync.sh  # manifest section lists all vendored skills
```

---

## V4: Taxonomy Restructure

**Parts:** D5, D6, D10
**Goal:** Replace origin-based categories with functional taxonomy. Every skill
in exactly one category. All top-level symlinks regenerated.

### New category structure

```
skills/
├── tools/          # Wraps external CLI/API/service (~60)
├── review/         # Analyzes/reviews code or content (~25)
├── workflows/      # Orchestrates multi-step dev processes (~45)
├── meta/           # Agent behavior rules, patterns, skill system (~55)
├── domain/         # Technology-specific knowledge (~90)
│   ├── swift/
│   ├── compound/
│   ├── ralph/
│   ├── notion/
│   ├── gitnexus/
│   ├── shaping/    # (submodules live here)
│   └── math/
├── <name> -> <category>/<name>   # Top-level discovery symlinks
└── ...
```

### Execution approach

Write a migration script (`scripts/restructure-categories.sh`) that:

1. Creates new category dirs
2. For each skill, moves from old location to new category location
3. Updates (or creates) the top-level discovery symlink
4. Removes empty old category dirs (cc3/, personal/, setup/)
5. Validates: every skill dir has a SKILL.md, every top-level symlink resolves

### Classification source

Full mapping in `spike-categories.md`. Decision rule:

1. Wraps external CLI/API/service? → `tools/`
2. Analyzes/reviews code or content? → `review/`
3. Orchestrates multi-step dev process? → `workflows/`
4. Specific to a named tech domain? → `domain/<sub>/`
5. Agent behavior rule or pattern? → `meta/`

### Old categories dissolved

| Old | New home |
|-----|----------|
| cc3/ (~104 skills) | Split across workflows/, meta/, tools/, domain/ |
| personal/ (~19 skills) | Split across tools/, domain/ |
| ralph-o/ (~12 skills) | → domain/ralph/ |
| swift/ (~5 skills) | → domain/swift/ |
| compound/ (~19 vendored) | → domain/compound/ |
| setup/ (0 skills) | Deleted |

**Verify:**
```bash
# Every skill in exactly one category:
find skills -maxdepth 1 -type d -not -name skills | sort
# Expected: only category dirs + .system

# Every top-level symlink resolves:
find skills -maxdepth 1 -type l ! -exec test -e {} \; -print
# Expected: empty output

# Agent discovery test — spot check:
ls skills/commit/SKILL.md       # -> workflows/commit
ls skills/github/SKILL.md       # -> tools/github
ls skills/kieran-python-reviewer/SKILL.md  # -> review/kieran-python-reviewer
ls skills/no-polling-agents/SKILL.md       # -> meta/no-polling-agents
ls skills/swift-concurrency-expert/SKILL.md # -> domain/swift/swift-concurrency-expert

# Count check:
find skills -name SKILL.md -o -name skill.md | wc -l
# Expected: ~275 (same as before)
```

---

## Slice Dependencies

```
V1 ─→ V2 ─→ V3 ─→ V4
```

Each slice can be committed independently. V1-V3 can be done in one session.
V4 is the largest (275 skill moves) but is mechanical and scriptable.

## Risk Notes

- **V4 is the biggest blast radius** — touching every skill's location. The
  migration script should be tested with a dry-run mode first.
- **Submodule paths (V2)** need careful thought about where in the new
  taxonomy they land, since V4 will restructure around them. The paths in V2
  already use the V4 taxonomy (`domain/shaping/`, `tools/`) so they won't
  need to move again.
- **commands/ directory is untouched** — this restructure only affects skills/.
  The compound commands symlink (`commands/compound -> external plugin`) is a
  separate issue if it needs addressing.

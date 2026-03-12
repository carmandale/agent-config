<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: REVISED -->
<!-- Revisions: R1: added B5b (restructure-categories.sh), B4b (Vector 4), Phase 4 (consumer updates), broadened Phase 5 (docs). R2: expanded Phase 4 with heal-skill, compound-learnings, absolute vendor-sync paths -->
---
title: "Plan: Skill collision architecture fix — discovery symlink removal + ownership boundary"
date: 2026-03-10
bead: .agent-config-1pz
shape: "B — Symlink cleanup + clean ownership boundary"
---

# Plan: Skill Collision Architecture Fix

## Overview

Fix the recurring skill collision class (specs 005, 012, 015) by removing the architectural cause: 261 discovery symlinks that create self-collision for recursive scanners, plus establishing a clean ownership boundary between agent-config skills and external package skills.

Selected Shape B from shaping. Challenger (MintCastle) identified 4 issues in the draft — all incorporated. Codex R1 identified 5 additional issues — incorporated in this revision.

## Architecture: Before → After

### Before (collision)

```
~/.agent-config/skills/
├── release → workflows/release       ← DISCOVERY SYMLINK (×261)
├── workflows/release/SKILL.md        ← REAL FILE
├── tools/testflight/SKILL.md
└── ...

Pi scans ~/.agents/skills/ (→ above tree) recursively:
  finds skills/release/SKILL.md         ← via symlink
  finds skills/workflows/release/SKILL.md ← via real dir
  → SELF-COLLISION (same file, two paths)

Pi also scans ~/.pi/agent/skills/:
  finds release/SKILL.md               ← paperclip (different skill!)
  → CROSS-COLLISION (same name, different sources)

Total: 3 hits for "release", 261 potential self-collisions
```

### After (clean)

```
~/.agent-config/skills/
├── tools/                             ← 5 category dirs only
├── review/
├── workflows/release-prep/SKILL.md    ← RENAMED (was release)
├── meta/
├── domain/
└── (no discovery symlinks)

Pi scans ~/.agents/skills/ recursively:
  finds skills/workflows/release-prep/SKILL.md  ← one hit only
  → NO self-collision

Pi scans ~/.pi/agent/skills/:
  finds release/SKILL.md               ← paperclip (name: release)
  → NO cross-collision (different names: release vs release-prep)

collision-check.sh:
  Vector 1 (recursive) catches future package-declared cross-source collisions
  Vector 4 (new) catches any ~/.pi/agent/skills/ entry that shares a name with agent-config
  Vector 3 (new) catches loopback symlinks into agent-config
```

## Requirement → Change Traceability

| Req | Requirement | Addressed by |
|-----|-------------|-------------|
| R0 | Zero collision warnings | B1 (self-collision), B3 (cross-collision for release) |
| R1 | No self-collision from new skills | B1+B5+B5b (symlinks gone, never recreated, restructure-categories.sh updated) |
| R2 | Cross-source name collisions handled | B3 (rename), B1b (recursive Vector 1), B4b (new Vector 4 for all Pi skills) |
| R3 | All agents discover correctly | B1 verified: 312 SKILL.md files reachable via recursive scan |
| R4 | Zero per-skill maintenance | B1 (structural), B5 (no symlink creation code) |
| R5 | Survives git pull, install.sh | B5+B5b (install.sh + restructure-categories.sh updated) |
| R6 | Structural + convention + guard | B1 (structural), B3 (convention), B1b+B4b (guards) |

## Implementation Details

### Phase 1: Prepare (non-breaking changes)

#### B3: Rename `release` → `release-prep` + update frontmatter

Rename `skills/workflows/release/` → `skills/workflows/release-prep/`.

Update SKILL.md frontmatter:
- `name: release` → `name: release-prep`
- Update description to clarify it's the generic release preparation workflow (not project-specific)

**Why first**: This resolves the active cross-collision with paperclip immediately, before the structural changes. Can be verified in isolation.

#### Move orphan skills to categories

3 skills exist as real directories at the `skills/` top level, outside any category:
- `skills/apple-notes/` → `skills/tools/apple-notes/`
- `skills/machine-parity/` → `skills/tools/machine-parity/`
- `skills/mini-sync/` → `skills/tools/mini-sync/`

All three wrap external CLIs/services → `tools/` per the taxonomy decision rule.

### Phase 2: Atomic structural change (B1 + B1b together)

**CRITICAL: B1 and B1b must be in the same commit.** Removing discovery symlinks without updating the collision guard creates a silent regression where future cross-source collisions go undetected. (MintCastle finding #1.)

#### B1: Delete all 261 discovery symlinks

```bash
cd ~/.agent-config
find skills/ -maxdepth 1 -type l -delete
```

All agents scan recursively — these symlinks are redundant for discovery and actively cause self-collision.

**Verified**: All 312 skills remain reachable via recursive scan of category dirs (verified during shaping with `find skills/ -name "SKILL.md" | sort -u | wc -l` = 312).

#### B1b: Update collision-check.sh Vector 1 to use recursive find

**The problem** (MintCastle finding #1): Vector 1 currently does a flat check:
```bash
if [[ -d "$AGENT_CONFIG_SKILLS/$skill_name" ]] || [[ -L "$AGENT_CONFIG_SKILLS/$skill_name" ]]; then
```

After B1 removes `skills/release` (flat symlink), this check can never find `skills/workflows/release-prep` at depth 2. Future cross-source collisions would be silently undetected.

**The fix**: Replace the flat check with a recursive find:
```bash
if find "$AGENT_CONFIG_SKILLS" -name "$skill_name" -type d -print -quit 2>/dev/null | grep -q .; then
```

`-print -quit` short-circuits on first match for performance (312 skills × N packages would otherwise be slow).

### Phase 3: Guards and cleanup

#### B2: Remove redundant testflight symlink from `~/.pi/agent/skills/`

`~/.pi/agent/skills/testflight → ~/.agent-config/skills/tools/testflight` is a second path to a skill already reachable through `~/.agents/skills/`. Remove it:
```bash
trash ~/.pi/agent/skills/testflight
```

#### B4: Add install.sh guard for agent-config loopback symlinks (Vector 3)

Scan `~/.pi/agent/skills/` for symlinks whose resolved target is inside `~/.agent-config/`. These are redundant second paths that create cross-collision.

**Scope note** (MintCastle finding #3): B4 catches the narrow "loopback" case (like testflight). The primary cross-source collision detection is provided by Vector 1 (B1b) and Vector 4 (B4b).

Add to `collision-check.sh` as Vector 3:
```bash
# Vector 3: Symlinks in ~/.pi/agent/skills/ pointing back into agent-config
for entry in "$PI_SKILLS"/*/; do
  [[ -L "${entry%/}" ]] || continue
  resolved=$(cd "${entry%/}" && pwd -P 2>/dev/null)
  if [[ "$resolved" == "$AGENT_CONFIG_SKILLS"* ]]; then
    log_warn "LOOPBACK: $(basename "$entry") in ~/.pi/agent/skills/ points into agent-config"
    log_warn "    Fix: trash ${entry%/}"
    DRIFT=$((DRIFT + 1))
  fi
done
```

#### B4b: Add broad cross-source collision check (Vector 4) — Codex R1 finding #2

**The problem**: Vector 1 only processes non-`npm:` local packages that declare skills via `pi.skills` in package.json. Vector 2 only catches non-symlink direct copies. Neither catches the most common real-world collision: a skill manually symlinked into `~/.pi/agent/skills/` (like paperclip's skills) that shares a name with an agent-config skill.

**The fix**: Add Vector 4 — compare ALL entries in `~/.pi/agent/skills/` (symlinks and dirs alike) against agent-config skill names via recursive find:

```bash
# Vector 4: Any entry in ~/.pi/agent/skills/ whose name matches an agent-config skill
if [[ -d "$PI_SKILLS" ]]; then
  for entry in "$PI_SKILLS"/*/; do
    [[ -d "$entry" ]] || continue
    local entry_name
    entry_name=$(basename "$entry")
    # Skip if it's a loopback (already caught by Vector 3)
    if [[ -L "${entry%/}" ]]; then
      local resolved
      resolved=$(cd "${entry%/}" && pwd -P 2>/dev/null)
      [[ "$resolved" == "$AGENT_CONFIG_SKILLS"* ]] && continue
    fi
    # Check if this name exists anywhere in agent-config
    if find "$AGENT_CONFIG_SKILLS" -name "$entry_name" -type d -print -quit 2>/dev/null | grep -q .; then
      collision_count=$((collision_count + 1))
      log_err "CROSS-SOURCE COLLISION: '$entry_name' exists in both ~/.pi/agent/skills/ and agent-config"
      log_err "    pi-skills: ${entry%/}"
      log_err "    agent-config: $(find "$AGENT_CONFIG_SKILLS" -name "$entry_name" -type d -print -quit)"
      log_err "    Fix: rename one of them to avoid name conflict"
      DRIFT=$((DRIFT + 1))
    fi
  done
fi
```

This covers the gap: any skill in `~/.pi/agent/skills/` — regardless of how it got there (manual symlink, package install, direct copy) — is checked against all agent-config skill names at any depth.

#### B5: Update install.sh — fix stats

**Fix the summary stat line** (line 188):

Before:
```bash
log_info "Skills unified: $(find "$SKILLS_DIR" -mindepth 2 -maxdepth 2 -type d | wc -l | tr -d ' ') skills across $(ls -1 "$SKILLS_DIR" | wc -l | tr -d ' ') categories"
```

After:
```bash
log_info "Skills unified: $(find "$SKILLS_DIR" -name "SKILL.md" | wc -l | tr -d ' ') skills across $(find "$SKILLS_DIR" -maxdepth 1 -mindepth 1 -type d -not -name '.*' | wc -l | tr -d ' ') categories"
```

This gives the real SKILL.md count (312, not the undercounted 214) and derives the category count dynamically (excludes `.system`).

#### B5b: Disable symlink regeneration in restructure-categories.sh — Codex R1 finding #1

**The problem**: `scripts/restructure-categories.sh` Phase 6 (lines 333-421) explicitly regenerates all discovery symlinks. Running this script after our fix would undo B1 entirely.

**The fix**: Remove Phase 6 from `restructure-categories.sh`. Replace with a comment explaining why:

```bash
# Phase 6 (REMOVED — spec 015): Discovery symlinks were removed because they
# cause self-collision for recursive scanners (Pi, Claude Code, Codex, Gemini).
# All agents discover skills via recursive SKILL.md scan of category dirs.
# Do NOT recreate top-level symlinks.
```

This is the only script besides `install.sh` that can create discovery symlinks. With both blocked, R1 and R5 are structurally guaranteed.

### Phase 4: Consumer updates — Codex R1 finding #3, Codex R2 finding #1

A repo-wide grep audit (`rg -l "ln -s.*skills/" commands/ skills/ scripts/ README.md AGENTS.md`) identifies all files that reference flat discovery symlink paths or instruct creating them. Each must be updated or the old pattern leaks back in.

#### 4a. Update test-continuity-lifecycle.sh

Line 515 asserts a top-level symlink exists:
```bash
assert "resume-handoff top-level symlink resolves" \
  "[[ -L '$HOME/.claude/skills/resume-handoff' && -d '$HOME/.claude/skills/resume-handoff' ]]"
```

After B1 this fails. Remove this assertion entirely — the category-path assertion on line 513 already provides coverage.

#### 4b. Update vendor-sync.sh local source paths — Codex R2 finding #2

Three `VENDOR_SOURCE` entries use flat discovery paths through `~/.agents/skills/`:
```
VENDOR_SOURCE[remotion-best-practices]="local:~/.agents/skills/remotion-best-practices"
VENDOR_SOURCE[find-skills]="local:~/.agents/skills/find-skills"
VENDOR_SOURCE[visual-explainer]="local:~/.agents/skills/visual-explainer"
```

These are circular self-references — `readlink -f` gives the same resolved path for both source and destination. After B1 the flat symlink path breaks.

**Fix**: Use absolute category paths anchored to `~/.agent-config`:
```
VENDOR_SOURCE[remotion-best-practices]="local:~/.agent-config/skills/domain/other/remotion-best-practices"
VENDOR_SOURCE[find-skills]="local:~/.agent-config/skills/tools/find-skills"
VENDOR_SOURCE[visual-explainer]="local:~/.agent-config/skills/workflows/visual-explainer"
```

Using `~/.agent-config/...` instead of relative paths because vendor-sync resolves `local:` by stripping the prefix and expanding `~` without anchoring to `$REPO_ROOT` (line 100-103). Relative paths would break when run from outside the repo root.

#### 4c. Update commands/compound/heal-skill.md — Codex R2 finding #1

Line 37 sets `SKILL_DIR=./skills/$SKILL_NAME` which assumes a flat top-level layout. After B1, `./skills/brave-search` doesn't exist — only `./skills/tools/brave-search`.

**Fix**: Update skill detection to search category dirs:
```bash
SKILL_DIR=$(find ./skills -name "$SKILL_NAME" -type d -print -quit)
```

Also update line 16's detection command:
```bash
ls -1 ./skills/*/SKILL.md → find ./skills -name "SKILL.md" -maxdepth 3
```

#### 4d. Update skills/meta/compound-learnings/SKILL.md — Codex R2 finding #1

Lines 199-201 instruct creating discovery symlinks:
```bash
ln -s <category>/<name> skills/<name>
```

**Fix**: Remove the instruction entirely. Replace with a note that skills in category dirs are discovered automatically via recursive scan — no symlink needed.

#### 4e. Low-priority doc references (update but not blocking)

These files contain discovery symlink references in historical/vendored context:
- `skills/domain/shaping/shaping-skills/README.md` — external submodule, has `ln -s` install instructions pointing to `~/.claude/skills/`. Not agent-config's discovery symlinks; these install shaping skills into Claude Code's skill dir. **Leave as-is** — these are upstream instructions for a different use case.
- `skills/tools/last30days/docs/plans/*.md` — historical plan docs. **Leave as-is** — these are archived plans, not active instructions.

### Phase 5: Documentation cleanup — Codex R1 finding #4 (broadened)

Documentation cleanup must cover ALL files that reference or instruct creating discovery symlinks, not just repo-root AGENTS.md.

#### Update repo-root AGENTS.md

Lines 13, 42, 54, 160 reference `~/.pi/agent/skills` as a symlink target and reference the discovery symlink pattern. Remove stale symlink table entry, update skill organization section to remove "Top-level symlinks enable discovery" and the `ln -s` instruction.

#### Update README.md

- Line ~376: Remove `└── <name> -> <category>/<name>  # Discovery symlinks` from the tree diagram
- Lines ~397-401: Remove `ln -s tools/my-tool skills/my-tool  # Discovery symlink` from the "Adding Skills" instructions

#### Update instructions/AGENTS.md (if applicable)

Check for any references to discovery symlinks in the global instructions file. (Preliminary check: not present, but verify during implementation.)

### Phase 6: Verification

1. Run `pi` and confirm zero `[Skill conflicts]` warnings on startup
2. Run `./install.sh` and confirm zero collision drift
3. Run `scripts/bootstrap.sh check` and confirm clean
4. Run `tests/test-symlink-parity.sh` and confirm all tests pass
5. Run `tests/test-continuity-lifecycle.sh` and confirm updated assertion passes
6. Verify skill count: `find ~/.agents/skills -name "SKILL.md" | wc -l` matches expected
7. Verify paperclip's `release` found with no collision (via `~/.pi/agent/skills/`)
8. Verify agent-config's `release-prep` found (via `~/.agents/skills/workflows/release-prep/`)
9. Verify `scripts/restructure-categories.sh` no longer regenerates discovery symlinks
10. Verify `scripts/vendor-sync.sh` runs without broken path errors

## Review History

### MintCastle (crew-challenger, claude-sonnet-4-6)

| # | Issue | Severity | Resolution |
|---|-------|----------|------------|
| 1 | B1 breaks Vector 1 collision detection silently | Critical | Added B1b: recursive find, same commit as B1 |
| 2 | B5 stat fix targets wrong number | Medium | Fixed: use `find -name "SKILL.md"` for real count |
| 3 | B4 doesn't replace Vector 1's cross-source coverage | Medium | Restructured: Vector 1 = primary, B4 = supplemental |
| 4 | B3 must update SKILL.md frontmatter `name:` field | Low | Added to B3: rename dir + update frontmatter |

### Codex R1 (gpt-5.3-codex)

| # | Issue | Severity | Resolution |
|---|-------|----------|------------|
| 1 | restructure-categories.sh Phase 6 regenerates symlinks — reintroduction path | Critical | Added B5b: remove Phase 6 from the script |
| 2 | Cross-source collision detection incomplete — Vector 1 only covers local packages, Vector 2 only non-symlink copies | Critical | Added B4b: new Vector 4 checks ALL ~/.pi/agent/skills/ entries against agent-config |
| 3 | test-continuity-lifecycle.sh and vendor-sync.sh depend on flat discovery paths | High | Added Phase 4: consumer updates for both scripts |
| 4 | Docs scope too narrow — README.md and AGENTS.md both instruct creating discovery symlinks | High | Broadened Phase 5 to cover README.md and AGENTS.md |
| 5 | Python string interpolation in collision-check.sh (security) | Medium | Noted as pre-existing, out of scope for this spec. Tracked for future hardening. |

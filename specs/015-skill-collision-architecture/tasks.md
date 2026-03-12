<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: RECONCILED -->
<!-- Revisions: Added B4b (Vector 4), B5b (restructure-categories.sh), Phase 4 consumer updates (4a-4e), broadened Phase 5 docs cleanup -->
---
title: "Tasks: Skill collision architecture fix"
date: 2026-03-10
bead: .agent-config-1pz
---

# Tasks

## Phase 1: Prepare (non-breaking)

- [x] **1.1** Rename `skills/workflows/release/` → `skills/workflows/release-prep/`
- [x] **1.2** Update `skills/workflows/release-prep/SKILL.md` frontmatter: `name: release` → `name: release-prep`, update description
- [x] **1.3** Move `skills/apple-notes/` → `skills/tools/apple-notes/`
- [x] **1.4** Move `skills/machine-parity/` → `skills/tools/machine-parity/`
- [x] **1.5** Move `skills/mini-sync/` → `skills/tools/mini-sync/`
- [x] **1.6** Verify: `find skills/ -maxdepth 1 -type d -not -name skills -not -name '.*'` returns only category dirs (tools, review, workflows, meta, domain)
- [x] **1.7** Commit Phase 1: `fix(015): rename release→release-prep, move orphan skills to categories`

## Phase 2: Atomic structural change (MUST be single commit)

- [x] **2.1** Delete all discovery symlinks: `find skills/ -maxdepth 1 -type l -delete`
- [x] **2.2** Verify zero symlinks remain: `find skills/ -maxdepth 1 -type l | wc -l` = 0
- [x] **2.3** Verify all skills still reachable: `find skills/ -name "SKILL.md" | wc -l` = current count
- [x] **2.4** Update `scripts/lib/collision-check.sh` Vector 1: replace flat check with recursive find (`find "$AGENT_CONFIG_SKILLS" -name "$skill_name" -type d -print -quit`)
- [x] **2.5** Commit Phase 2 (B1 + B1b together): `fix(015): remove 261 discovery symlinks, update collision guard to recursive find`

## Phase 3: Guards and cleanup

- [x] **3.1** Remove `~/.pi/agent/skills/testflight` symlink (redundant loopback into agent-config)
- [x] **3.2** Add Vector 3 to `collision-check.sh`: detect loopback symlinks in `~/.pi/agent/skills/` that resolve into `~/.agent-config/`
- [x] **3.3** Add Vector 4 to `collision-check.sh`: check ALL `~/.pi/agent/skills/` entries (symlinks and dirs) against agent-config skill names via recursive find
- [x] **3.4** Update `install.sh` line 188: fix summary stat to use `find -name "SKILL.md"` for skill count and derive category count dynamically
- [x] **3.5** Remove Phase 6 from `scripts/restructure-categories.sh` (symlink regeneration) — replace with explanatory comment
- [x] **3.6** Verify install.sh has no other code that creates discovery symlinks
- [x] **3.7** Commit Phase 3: `fix(015): add Vector 3+4 guards, fix stats, disable symlink regeneration`

## Phase 4: Consumer updates

- [x] **4.1** Update `tests/test-continuity-lifecycle.sh`: remove line 515 top-level symlink assertion (category-path assertion on line 513 already covers it)
- [x] **4.2** Update `scripts/vendor-sync.sh`: change 3 `local:` source paths to absolute `~/.agent-config/...` category paths (or remove if self-referential no-ops)
- [x] **4.3** Update `commands/compound/heal-skill.md`: replace flat `SKILL_DIR=./skills/$SKILL_NAME` with `find`-based category discovery, update line 16 detection command
- [x] **4.4** Update `skills/meta/compound-learnings/SKILL.md`: remove lines 199-201 discovery symlink creation instruction, replace with note about recursive discovery
- [x] **4.5** Audit: verify `skills/domain/shaping/shaping-skills/README.md` and `last30days/docs/plans/*.md` are historical/external (leave as-is)
- [x] **4.6** Commit Phase 4: `fix(015): update consumers of flat discovery symlink paths`

## Phase 5: Documentation

- [x] **5.1** Update repo-root `AGENTS.md`: remove stale `~/.pi/agent/skills` symlink reference, remove "Top-level symlinks enable discovery" text, remove `ln -s` instruction
- [x] **5.2** Update `README.md`: remove `<name> -> <category>/<name>` tree entry, remove `ln -s tools/my-tool skills/my-tool` from "Adding Skills" instructions
- [x] **5.3** Verify `instructions/AGENTS.md` (global) has no discovery symlink references
- [x] **5.4** Commit Phase 5: `docs(015): remove all discovery symlink references from docs`

## Phase 6: Verification

- [ ] **6.1** Run `pi` startup — confirm zero `[Skill conflicts]` warnings
- [ ] **6.2** Run `./install.sh` — confirm zero collision drift
- [ ] **6.3** Run `scripts/bootstrap.sh check` — confirm clean
- [ ] **6.4** Run `tests/test-symlink-parity.sh` — confirm all tests pass
- [ ] **6.5** Run `tests/test-continuity-lifecycle.sh` — confirm updated assertion passes
- [ ] **6.6** Verify skill counts: `find ~/.agents/skills -name "SKILL.md" | wc -l` matches expected
- [ ] **6.7** Verify paperclip's `release` found with no collision
- [ ] **6.8** Verify agent-config's `release-prep` found at `~/.agents/skills/workflows/release-prep/`
- [ ] **6.9** Verify `scripts/restructure-categories.sh` no longer regenerates discovery symlinks
- [ ] **6.10** Verify `scripts/vendor-sync.sh` runs without broken path errors

## Dependencies

```
Phase 1 (prepare) → Phase 2 (atomic B1+B1b) → Phase 3 (guards) → Phase 4 (consumers) → Phase 5 (docs) → Phase 6 (verify)
```

Phase 2 is the critical gate — B1 and B1b MUST be in the same commit to avoid a window where the collision guard is blind.

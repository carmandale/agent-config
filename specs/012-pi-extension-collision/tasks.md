<!-- Codex Review: APPROVED after 2 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: RECONCILED -->
<!-- Revisions: Added Phase 4 (install.sh preventive check), added Phase 6 (test guard), switched T1.1 to trash, corrected T5.1 threshold to -mtime +5, expanded T3.2 with two skill collision vectors -->
---
title: "Tasks: Pi extension collision fix + structural guard"
date: 2026-03-10
bead: .agent-config-12r
---

# Tasks: Pi Extension Collision Fix

## Phase 1: Fix the collision (laptop only)

- [ ] **T1.1** Remove stale npm-installed pi-messenger: `trash ~/.pi/agent/extensions/pi-messenger/` (fallback: `mv` to `~/.Trash/pi-messenger-$(date +%Y%m%d)/`)
- [ ] **T1.2** Verify removal: `ls ~/.pi/agent/extensions/pi-messenger/` should fail (dir gone)
- [ ] **T1.3** Start Pi, confirm zero `[Extension issues]` for pi-messenger

## Phase 2: Fix false-positive bootstrap check

- [ ] **T2.1** In `scripts/bootstrap.sh` `do_check()` symlinks loop (~line 207): remove the entry `"$HOME/.pi/agent/skills:$REPO_ROOT/skills"`
- [ ] **T2.2** Run `./scripts/bootstrap.sh check` — confirm `MISSING: ~/.pi/agent/skills (not a symlink)` is gone
- [ ] **T2.3** Verify all other symlink checks still pass

## Phase 3: Create shared collision-check helper

- [ ] **T3.1** Create `scripts/lib/collision-check.sh` with:
  - `get_pi_package_names()`: parse `~/.pi/agent/settings.json` packages array → output one basename per line. Handle npm:name, npm:@scope/name@ver, local paths. Graceful skip if settings.json missing (`log_info`). JSON parsing via python3 with grep/sed fallback.
  - `check_extension_collisions()`: call `get_pi_package_names`, list `~/.pi/agent/extensions/*/` dirs, compare → report COLLISION with paths, versions, fix instruction. Increment `DRIFT` counter.
  - `check_skill_collisions()` with two vectors:
    - Vector 1: For each package path, check `package.json` → `pi.skills` → list skill subdirs → compare against `~/.agent-config/skills/` → report name matches
    - Vector 2: If `~/.pi/agent/skills/` is a real dir (not symlink), report any non-symlink entries as potential collisions
  - Code comments documenting coverage limits (legacy dirs, scoped names untested)
- [ ] **T3.2** In `bootstrap.sh`: `source "$SCRIPT_DIR/lib/collision-check.sh"` and call both check functions from `do_check()` as `─── Pi Extension/Skill Collisions ───` section between "Pi Agent" and "Claude Hooks"
- [ ] **T3.3** In `install.sh`: `source "$SCRIPT_DIR/scripts/lib/collision-check.sh"` and call both check functions at end of script, after all symlinks

## Phase 4: Test collision guard

- [ ] **T4.1** Test extension collision: `mkdir -p ~/.pi/agent/extensions/pi-design-deck && ./scripts/bootstrap.sh check` → reports COLLISION; then `rmdir ~/.pi/agent/extensions/pi-design-deck`
- [ ] **T4.2** Test install.sh warning: recreate fake dir, run `./install.sh` → same warning appears; remove fake dir
- [ ] **T4.3** Test clean state: `./scripts/bootstrap.sh check` → 0 collisions, all checks pass

## Phase 5: Clean up noise

- [ ] **T5.1** Delete stale backup files: `find ~/.pi/agent/extensions/ -name '*.backup.*' -mtime +5 -delete`
- [ ] **T5.2** Verify: `ls ~/.pi/agent/extensions/*.backup.* 2>/dev/null | wc -l` → 0
- [ ] **T5.3** Optional: remove stale `~/.pi/agent/skills/` directory (contains only redundant testflight symlink, already discoverable via `~/.agents/skills/`)

## Phase 6: Test the guard

- [ ] **T6.1** Test extension collision detection: `mkdir -p ~/.pi/agent/extensions/pi-design-deck && ./scripts/bootstrap.sh check` → reports COLLISION for pi-design-deck; then `rmdir ~/.pi/agent/extensions/pi-design-deck`
- [ ] **T6.2** Test clean state: `./scripts/bootstrap.sh check` → 0 collisions, all checks pass, no false positives
- [ ] **T6.3** Test skill collision Vector 2: create `mkdir -p ~/.pi/agent/skills/test-fake-skill && ./scripts/bootstrap.sh check` → reports potential collision; then `rmdir ~/.pi/agent/skills/test-fake-skill`

## Phase 7: Commit, verify end-to-end, sync Mini

- [ ] **T7.1** `git add scripts/lib/collision-check.sh scripts/bootstrap.sh install.sh && git commit -m "fix(012): extension/skill collision guard + cleanup"`
- [ ] **T7.2** Full verification: `./scripts/bootstrap.sh check` — all pass, 0 collisions, 0 false positives
- [ ] **T7.3** Start Pi — zero `[Extension issues]`, zero `[Skill conflicts]`
- [ ] **T7.4** Push and sync Mini: `git push && ssh mini-ts "cd ~/.agent-config && git pull --ff-only && ./scripts/bootstrap.sh check"` — guard runs cleanly, 0 collisions

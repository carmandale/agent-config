# Current State — 2026-03-10

## Most Recent: Spec 014 — Parity Tool Drift ✅ COMPLETE

**Bead**: `.agent-config-kcx`
**PR**: https://github.com/carmandale/agent-config/pull/3 (merged)
**Spec**: `specs/014-parity-tool-drift/`

### What Shipped

6 bugs fixed in 4 files, 5 commits:
1. Parity tool managed paths aligned with install.sh (3 wrong removed, 2 missing added)
2. Test guard extended — `test-symlink-parity.sh` now verifies 4 sources agree (prevents future drift)
3. README stale `~/.pi/agent/skills` entry removed
4. Extension hardcoded `/Users/dalecarman` replaced with dynamic `homedir()`
5. Snapshot schema bumped 1→2

### Artifacts Created During Compounding
- Rule: `.claude/rules/structural-coupling.md` — enforce agreement structurally, not with comments
- Rule update: `.claude/rules/wrapper-script-safety.md` — added TypeScript homedir() equivalent
- Napkin updated with 4 new entries

---

## Active Work: Spec 013 — Fleet-wide br Migration (Laptop Complete, Mini Remaining)

**Bead**: `.agent-config-2gy`
**Branch**: `feat/013-br-fleet-migration`
**Spec**: `specs/013-br-fleet-migration/`

### Remaining Tasks (7 of 53)

| Task | Description | Blocked by |
|------|-------------|-----------|
| 28-31 | Mini deployment (pull, run script, verify) | SSH access to mini |
| 37 | Mini hook deployment (pull, bootstrap) | Task 28 |
| 45 | Mini verification (no bd in deployed state) | Task 37 |
| 49-53 | Phase 4: 30-day cleanup (2026-04-10) | Calendar gate |

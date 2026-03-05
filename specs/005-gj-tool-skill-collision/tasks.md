---
title: "Tasks: gj-tool skill collision fix"
date: 2026-03-05
spec: 005-gj-tool-skill-collision
---

# Tasks

## agent-config side (VividArrow)

- [x] **T1: Add gj-tool to vendor-sync.sh manifest**
  - Add entry: source `~/dev/gj-tool/skill/`, dest `skills/tools/gj-tool/`
  - Follow existing local-source pattern (like `remotion-best-practices`)
  - Run `vendor-sync.sh gj-tool` to verify sync works

- [x] **T2: Remove stale direct-install copy**
  - Remove `~/.pi/agent/skills/gj-tool/` directory (the direct copy from gj-tool install.sh)
  - Verify `~/.pi/agent/skills/` no longer contains gj-tool

- [x] **T3: Verify agent-config distribution is clean**
  - Confirm `~/.agents/skills/gj-tool/SKILL.md` resolves (via agent-config symlink chain)
  - Confirm `~/.agents/skills/tools/gj-tool/SKILL.md` resolves (same file)
  - These two paths resolve to the SAME inode — Pi should deduplicate or only scan one

## gj-tool side (BrightGrove)

- [x] **T4: Remove skill install from gj-tool install.sh** (BrightGrove commit 9815a9d)
  - Remove the block that copies SKILL.md + scripts/ to `~/.pi/agent/skills/gj-tool/`
  - Remove or update the Claude skill location warning

- [x] **T5: Add legacy cleanup to gj-tool install.sh** (BrightGrove commit 9815a9d)
  - If `~/.pi/agent/skills/gj-tool/` exists, remove it
  - Log: "Cleaning up legacy skill install (now managed by agent-config)"

## Verification (both)

- [x] **T6: End-to-end verification**
  - Run `~/dev/gj-tool/install.sh` → no files at `~/.pi/agent/skills/gj-tool/`
  - Run `~/.agent-config/install.sh` → symlinks intact
  - Start Pi agent → zero gj-tool skill collision warnings
  - Run `vendor-sync.sh gj-tool` → content matches `~/dev/gj-tool/skill/SKILL.md`

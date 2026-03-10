<!-- Codex Review: APPROVED after 2 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: REVISED -->
<!-- Revisions: Restored R4 skills coverage (C3 two-vector guard), added preventive install.sh check (C6), switched to trash for cleanup (security), corrected backup age threshold (+5 not +7), added verification matrix, added Mini SSH evidence -->
---
title: "Plan: Pi extension collision fix + structural guard"
date: 2026-03-10
bead: .agent-config-12r
shape: "C — Fix instance + collision guard in bootstrap.sh"
---

# Plan: Pi Extension Collision Fix + Structural Guard

## Overview

Fix the pi-messenger extension collision (two sources loading the same tool/command) and add a structural guard to `bootstrap.sh check` that catches this collision class for both extensions and skills. Also fix a false-positive bootstrap check and clean up stale backup files.

## Architecture: Before → After

### Before (collision)

```
Legacy: npx pi-messenger (install.mjs)
  └─ copies to ~/.pi/agent/extensions/pi-messenger/ (v0.13.0)  ← SOURCE 1

Modern: settings.json → packages
  └─ "/path/to/dev/pi-messenger" (v0.14.0)                     ← SOURCE 2

Pi auto-discovers extensions/ AND loads packages → both register
pi_messenger tool + /messenger command → COLLISION
```

### After (clean)

```
settings.json → packages → dev fork (v0.14.0)                  ← SINGLE SOURCE

~/.pi/agent/extensions/pi-messenger/  REMOVED
bootstrap.sh check → collision guard catches future overlaps
                      for both extensions AND skills
```

## Requirement → Change Traceability

| Req | Requirement | Addressed by |
|-----|-------------|-------------|
| R0 | Zero collision warnings | C1a: remove stale npm copy |
| R1 | Single canonical source | C1a: dev fork via packages is sole source |
| R2 | Survives routine operations | C2: guard detects re-introduction; install.sh integration prevents silent re-creation |
| R3 | Guard detects collision class | C2: new bootstrap.sh check section for extensions |
| R4 | Covers extensions AND skills | C2: extension collision check + C3: skill collision check (package-declared skills vs agent-config, direct copies in ~/.pi/agent/skills/) |
| R5 | Minimal config maintenance | C2/C3: runs as part of existing `bootstrap.sh check` flow |

## Implementation Details

### C1a: Remove stale npm copy (laptop only)

The stale copy at `~/.pi/agent/extensions/pi-messenger/` is an old npm install (v0.13.0). The dev fork (v0.14.0) loaded via `settings.json` packages is canonical.

**Removal method**: Use `trash` (Homebrew CLI) to move to Trash instead of executing the bundled `install.mjs` script. Running arbitrary code from a stale package for cleanup is an unnecessary trust decision when we only need to delete a directory.

```bash
trash ~/.pi/agent/extensions/pi-messenger/
```

If `trash` is not available: `mv ~/.pi/agent/extensions/pi-messenger/ ~/.Trash/pi-messenger-$(date +%Y%m%d)/`

**Mini**: Confirmed via SSH that Mini does NOT have `~/.pi/agent/extensions/pi-messenger/` — no action needed there. Evidence: `ssh mini-ts "ls -d ~/.pi/agent/extensions/pi-messenger/"` → `NOT_FOUND`.

### C1b: Fix false-positive symlink check in bootstrap.sh

**Problem**: `do_check()` symlinks table includes `~/.pi/agent/skills → skills`, but `install.sh` deliberately does NOT create this symlink — two explicit comments (lines 99 and 183-184) explain that Pi already discovers skills via `~/.agents/skills`, and adding `~/.pi/agent/skills` would cause double discovery.

**Fix**: Remove the line `"$HOME/.pi/agent/skills:$REPO_ROOT/skills"` from the `do_check()` symlinks loop in `scripts/bootstrap.sh` (~line 207).

### C2: Extension collision guard — shared helper

The collision detection logic lives in a single shared file `scripts/lib/collision-check.sh`, sourced by both `bootstrap.sh` and `install.sh`. This eliminates drift risk (Codex advisory: duplicating logic across scripts leads to inconsistent warnings).

**Shared file**: `scripts/lib/collision-check.sh`

Exports two functions:
- `get_pi_package_names()` — parses `~/.pi/agent/settings.json` packages array, outputs one basename per line
- `check_extension_collisions()` — compares package names against `~/.pi/agent/extensions/*/` dirs, outputs collision details
- `check_skill_collisions()` — checks the two skill collision vectors (see C3)

**Extension collision logic** (inside `check_extension_collisions()`):
1. Read `~/.pi/agent/settings.json` (live, not baseline — Pi settings are machine-specific)
2. If file doesn't exist → `log_info "Skipping (no ~/.pi/agent/settings.json)"` and return
3. Call `get_pi_package_names()` to extract basenames:
   - `npm:name@ver` → `name`; `npm:@scope/name@ver` → `name` (last path component); local path → `basename`
4. List directories in `~/.pi/agent/extensions/` (only `*/` entries, not bare `.ts` files)
5. If any extension dir name matches a package basename → COLLISION
6. Report both paths, version from `package.json` if readable, explicit fix: `trash ~/.pi/agent/extensions/<name>/`

**Coverage limits** (documented as code comments in the shared file):
- Catches: package whose basename matches an extensions/ dir name (the real collision pattern)
- Does NOT catch: legacy extensions/ dirs that later get a packages entry under a different name
- Does NOT catch: scoped npm packages where installed dir name differs from package basename

**Parser dependency**: Uses `python3 -c` for JSON extraction (universally available on macOS). Falls back to `grep`/`sed` heuristic if python3 is missing (with `log_warn` noting reduced accuracy).

**Consumers**:
- `bootstrap.sh` → `source scripts/lib/collision-check.sh` in `do_check()`, new section `─── Pi Extension/Skill Collisions ───` between "Pi Agent" and "Claude Hooks"
- `install.sh` → `source scripts/lib/collision-check.sh` at end, post-install warning if collisions found

### C3: Skill collision guard in bootstrap.sh check

Same function, second check block. Two skill collision vectors:

**Vector 1: Package-declared skills vs agent-config skills.**
For each package in `settings.json`, check if its `pi.skills` directories contain skill names that also exist in `~/.agent-config/skills/`. This catches the case where a Pi package bundles a skill that conflicts with our agent-config managed skills.

Logic: For each package path, read `package.json` → `pi.skills` array → list subdirectories → compare names against `~/.agent-config/skills/`.

**Vector 2: Direct copies in `~/.pi/agent/skills/` (the spec 005 pattern).**
If `~/.pi/agent/skills/` is a real directory (not a symlink), list its entries and check if any are regular directories (not symlinks). A regular directory here means something was directly copied in (like gj-tool's old installer did), creating a duplicate of what's already available via `~/.agents/skills/`.

Logic: If `~/.pi/agent/skills` exists AND is not a symlink → list entries → for each entry that is a directory (not a symlink), report as potential collision.

### C4: Actionable output format

All collision reports follow this pattern:
```
✗ COLLISION: <name> in both extensions/ and settings.json packages
    extensions/: ~/.pi/agent/extensions/<name>/ (v0.13.0)
    packages:    /path/to/dev/<name> (v0.14.0)
    Fix: trash ~/.pi/agent/extensions/<name>/
```

Increments the `DRIFT` counter (same as other bootstrap.sh checks) so the exit code reflects collision state.

### C5: Clean up stale backup files

```bash
find ~/.pi/agent/extensions/ -name '*.backup.*' -mtime +5 -delete
```

**Corrected threshold**: `-mtime +5` (not +7). Current backup ages: March 1 files = 9 days old, March 3 files = 7 days old (on March 10). With `-mtime +5`, all 25 files are reliably caught. The threshold is conservative enough to preserve any backup from the current week.

### C6: Integration with install.sh (preventive, not just detective)

Add a post-install collision check to `install.sh` by sourcing the same shared helper (`scripts/lib/collision-check.sh`). This makes the guard preventive (catches during setup) not just detective (catches during check).

```bash
# At end of install.sh, after all symlinks:
source "$SCRIPT_DIR/scripts/lib/collision-check.sh"
check_extension_collisions
check_skill_collisions
```

Same functions, same output, zero drift. If someone runs `npx pi-messenger` and then `./install.sh`, the warning fires immediately — not only when they remember to run `bootstrap.sh check`.

## Verification Matrix

| Check | Command | Expected |
|-------|---------|----------|
| Extension collision gone | Start Pi | Zero `[Extension issues]` lines |
| Guard detects test collision | `mkdir -p ~/.pi/agent/extensions/pi-design-deck && ./scripts/bootstrap.sh check` | Reports COLLISION for pi-design-deck |
| Guard clean when no collision | Remove test dir, `./scripts/bootstrap.sh check` | Reports OK, zero collisions |
| False-positive fixed | `./scripts/bootstrap.sh check` | No `MISSING: ~/.pi/agent/skills` line |
| Backup cleanup | `ls ~/.pi/agent/extensions/*.backup.* \| wc -l` | 0 files remaining |
| Mini guard works | `ssh mini-ts "cd ~/.agent-config && git pull && ./scripts/bootstrap.sh check"` | Guard runs, 0 collisions |
| install.sh warns on collision | Re-create test collision dir, `./install.sh` | Warning at end of output |

## Risks

| Risk | Mitigation |
|------|------------|
| `trash` not installed | Fallback: `mv` to `~/.Trash/` with dated suffix |
| python3 not available for JSON parsing | Fallback: grep/sed heuristic with reduced-accuracy warning |
| Package name extraction misses edge cases | Documented coverage limits; guard is additive (warns, doesn't block) |
| Future Pi versions change discovery paths | Guard reads live state, not hardcoded; easy to update |
| Fresh machine with no settings.json | Guard skips gracefully with info message |

## Collaboration Record

**Planning challenger**: YoungXenon (crew-challenger, claude-sonnet-4-6) — 3 rounds, 2 blockers resolved
**Codex reviewer**: gpt-5.3-codex — Round 1 REVISE with 6 findings

**Key corrections from planning challenge**:
1. C3 (original skill guard) had wrong premise — ~/.pi/agent/skills is a real dir, not a symlink
2. C1b flipped from "add symlink" to "remove false-positive check" — install.sh deliberately skips this symlink
3. Package name mapping gets explicit coverage-limit documentation

**Key corrections from Codex Round 1**:
1. Restored skills collision coverage (R4) — two concrete vectors instead of "existing checks cover it"
2. Added preventive integration in install.sh (not just detective in bootstrap.sh check)
3. Switched from install.mjs --remove to trash (security: don't execute untrusted code for cleanup)
4. Corrected backup age threshold from +7 to +5 days
5. Added explicit verification matrix with commands and expected outputs
6. Added Mini SSH evidence for "laptop-only" claim

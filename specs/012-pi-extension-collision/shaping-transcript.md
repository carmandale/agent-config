---
shaping: true
---

# Shaping Transcript: Pi Extension Collision (012)

**Participants**: User + pi/claude-sonnet-4-5
**Date**: 2026-03-10

---

## Problem

Pi loads pi-messenger from two independent sources:
1. `~/.pi/agent/extensions/pi-messenger/` — npm copy (v0.13.0) via `npx pi-messenger` installer
2. `settings.json` → `packages` → local dev fork (v0.14.0)

Both register tool `pi_messenger` and command `/messenger` → collision on every startup.

Same collision class as spec 005 (gj-tool skill collision). Spec 005 was fixed per-instance but no structural guard was added → pattern recurred.

---

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Zero extension collision warnings for pi-messenger | Core goal |
| R1 | Single canonical source for the extension | Core goal |
| R2 | Fix survives routine operations (pi update, install.sh, settings changes) | Must-have |
| R3 | Guard detects this collision class before user sees it | Must-have |
| R4 | Guard covers both extensions AND skills | Must-have |
| R5 | Minimal config maintenance | Must-have |

---

## Investigation / Spike

### Two install mechanisms (don't know about each other)

| Mechanism | How | Where files land | Lifecycle |
|-----------|-----|------------------|-----------|
| Legacy: `npx pi-messenger` | `install.mjs` copies from npm | `~/.pi/agent/extensions/pi-messenger/` | Manual, no auto-update |
| Modern: settings.json `packages` | Pi loads from source path directly | Wherever path points | `pi update` for npm/git; local paths live |

### Pi's dedup rules

Pi deduplicates packages between global and project settings by identity (npm name, git URL, or resolved path). But this dedup does NOT cover the overlap between `settings.json` packages and the `extensions/` auto-discovery directory. Different identity types → no dedup → collision.

### Collision scan results

- **Extensions**: Only pi-messenger collides. Other packages (pi-subagents, pi-design-deck) use modern install only.
- **Skills**: pi-messenger declares skills in both copies, but they don't collide with agent-config skills. Fixing the extension collision fixes the skill collision.
- **Backup files**: 25 `.backup.*` files in extensions/ (noise, unrelated).

### Ownership

- Upstream pi-messenger (npm, install.mjs): owned by Nico — we don't control
- Our dev fork (v0.14.0): we control
- `~/.pi/agent/extensions/` stale copy: our machine, we control
- `bootstrap.sh`: agent-config, we control

---

## Shapes Explored

### A: Remove npm copy only (no guard)
- ✅ R0, R1, R5
- ❌ R2, R3, R4 — next `npx pi-messenger` re-creates collision silently

### B: Remove dev path from packages only (no guard)
- ✅ R0, R1, R5
- ❌ R2, R3, R4 — if dev path re-added, collision returns

### C: Fix instance + collision guard in bootstrap.sh
- ✅ All requirements

### D: Fix instance + documentation guard only
- ✅ R0, R1, R5
- ❌ R2, R3, R4 — spec 005 napkin entry didn't prevent this recurrence, documentation alone insufficient

## Fit Check

| Req | Requirement | Status | A | B | C | D |
|-----|-------------|--------|---|---|---|---|
| R0 | Zero collision warnings | Core goal | ✅ | ✅ | ✅ | ✅ |
| R1 | Single canonical source | Core goal | ✅ | ✅ | ✅ | ✅ |
| R2 | Survives routine operations | Must-have | ❌ | ❌ | ✅ | ❌ |
| R3 | Guard detects collision class | Must-have | ❌ | ❌ | ✅ | ❌ |
| R4 | Covers extensions AND skills | Must-have | ❌ | ❌ | ✅ | ❌ |
| R5 | Minimal config maintenance | Must-have | ✅ | ✅ | ✅ | ✅ |

---

## Selected Shape: C

| Part | Mechanism |
|------|-----------|
| **C1** | Remove stale npm copy: `node ~/.pi/agent/extensions/pi-messenger/install.mjs --remove` (laptop + Mini) |
| **C2** | `bootstrap.sh check` → new "Extension/Skill Collisions" section: extract package names from `settings.json`, compare against `extensions/` dirs → report collisions with versions + fix |
| **C3** | Same guard checks skill name overlap: `~/.pi/agent/skills/` dirs vs `~/.agents/skills/` dirs |
| **C4** | Actionable output: collision paths, both versions, explicit fix instruction |
| **C5** | Clean up 25 `.backup.*` files in `~/.pi/agent/extensions/` |

### Breadboard

```
settings.json → extract package names
                         ↓
extensions/ dir listing → compare → match? → COLLISION report (path, version, fix)
                                           → no match → OK

~/.pi/agent/skills/ listing ─┐
                              ├→ compare → match? → COLLISION report
~/.agents/skills/ listing ───┘           → no match → OK
```

Guard lives as a new section in `do_check()` between "Pi Agent" and "Symlinks" sections.

### User decisions
- Use `install.mjs --remove` for proper cleanup (not raw rm)
- Clean up .backup files in same pass
- Guard in `bootstrap.sh check` (runs on both machines as part of standard verification)

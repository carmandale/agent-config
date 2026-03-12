---
title: "Planning Transcript — Spec 015"
date: 2026-03-10
---

# Planning Transcript

**Proposer**: NiceLion (pi/claude-sonnet-4)
**Challenger**: MintCastle (crew-challenger, claude-sonnet-4-6)
**Rounds**: 2 (challenge → revise → agree)

---

## Proposer Research Phase

NiceLion investigated:
- `install.sh` — skills section, collision check integration, summary stat line
- `scripts/lib/collision-check.sh` — all 3 vectors, coverage limits, the flat check on line 240
- `tests/test-symlink-parity.sh` — confirmed it tests symlink destinations, not discovery symlinks within the skills tree
- `AGENTS.md` (repo root) — found stale `~/.pi/agent/skills` references on lines 13, 42, 54, 160
- `~/.pi/agent/skills/` contents — 8 entries (7 paperclip + 1 testflight loopback)
- Skill count verification: 312 SKILL.md files via recursive find, 261 discovery symlinks, 3 orphan top-level dirs

Proposed plan: Shape B with 5 parts (B1-B5) from shaping, plus orphan skill moves and AGENTS.md cleanup.

---

## MintCastle Challenge

[PHASE:challenge] — 4 problems identified:

**Problem 1 (Critical): B1 breaks Vector 1 detection silently**

Vector 1 in collision-check.sh uses a flat check `[[ -d "$AGENT_CONFIG_SKILLS/$skill_name" ]] || [[ -L "$AGENT_CONFIG_SKILLS/$skill_name" ]]`. After B1 removes discovery symlinks, this check can never find skills at depth 2+ in category dirs. Future cross-source collisions would go undetected.

Fix: Update Vector 1 to use `find "$AGENT_CONFIG_SKILLS" -name "$skill_name" -type d`. Must be same commit as B1.

**Problem 2: B5 stat fix targets wrong number**

`find -type d` doesn't follow symlinks — the 214 count comes from real dirs, not symlinks. `ls -1` gives 269 (includes symlinks). After B1, ls drops to 8. Both numbers are wrong — real count is 312 (SKILL.md files). Fix: use `find -name "SKILL.md"`.

**Problem 3: B4 scope too narrow**

B4 catches symlinks pointing back into agent-config (testflight). But it doesn't catch cross-source collisions (paperclip's release pointing to paperclip's dir). Primary cross-source detection comes from fixed Vector 1, not B4.

**Problem 4: B3 frontmatter name not updated**

Directory rename without `name:` field update leaves stale frontmatter that could collide in skill registries indexing by name.

---

## NiceLion Revision

[PHASE:revise] — All 4 incorporated:
1. Added B1b (Vector 1 recursive fix), constrained to same commit as B1
2. Fixed B5 to use `find -name "SKILL.md"` and derive category count dynamically
3. Restructured: Vector 1 = primary guard, B4 = supplemental loopback detector
4. B3 now includes frontmatter update

---

## MintCastle Agreement

[PHASE:agree] — "All four concerns addressed. B1+B1b same-commit constraint is exactly right."

Additional note: category count (5) should be derived dynamically, not hardcoded as a magic number. Use `find skills -maxdepth 1 -mindepth 1 -type d -not -name '.*' | wc -l`. Incorporated.

---

## Outcome

Plan approved after 1 revision round. Critical finding: B1 without B1b would have silently regressed the collision guard — the exact kind of issue that's hardest to catch in review.

# Codex Review — Spec 015: Skill Collision Architecture

**Model**: gpt-5.3-codex
**Session ID**: 019cdff2-be63-7120-81e2-e97a15bceb30
**Rounds**: 3
**Final Verdict**: APPROVED

---

## Round 1 — VERDICT: REVISE

5 findings:

1. **Critical**: `restructure-categories.sh` Phase 6 regenerates all discovery symlinks — reintroduction path not blocked (lines 333-421)
2. **Critical**: Cross-source collision detection incomplete — Vector 1 only covers local packages, Vector 2 only non-symlink copies. Manual symlinks in `~/.pi/agent/skills/` (like paperclip's) aren't caught.
3. **High**: `test-continuity-lifecycle.sh` (line 515) and `vendor-sync.sh` (lines 60, 66, 72) depend on flat discovery paths — would break after B1
4. **High**: Docs cleanup too narrow — README.md and AGENTS.md both instruct creating discovery symlinks
5. **Medium**: Python string interpolation security risk in collision-check.sh (pre-existing, noted for future)

Adversarial gate: identified 3 assumptions contradicted by source code, skeptical engineer objection about blast radius, production needs (CI gate, rollback plan, caller audit).

### Revisions Made
- Added B5b: remove restructure-categories.sh Phase 6
- Added B4b: new Vector 4 — broad cross-source check for ALL ~/.pi/agent/skills/ entries
- Added Phase 4: consumer updates for test and vendor-sync
- Broadened Phase 5 to cover README.md and AGENTS.md

---

## Round 2 — VERDICT: REVISE

2 remaining findings:

1. Consumer/docs sweep still incomplete: `heal-skill.md` assumes flat `skills/<name>` layout (line 37), `compound-learnings/SKILL.md` instructs creating discovery symlinks (lines 199-201)
2. Vendor-sync fix uses relative `local:skills/...` paths but script resolves without REPO_ROOT anchoring — fragile

### Revisions Made
- Expanded Phase 4 with full grep-driven consumer audit (4a-4e)
- Added 4c: heal-skill.md category-aware skill detection
- Added 4d: compound-learnings/SKILL.md instruction removal
- Fixed vendor-sync paths to absolute `~/.agent-config/...`

---

## Round 3 — VERDICT: APPROVED

Codex verified 4 specific checks:

1. Full consumer/doc sweep in-scope in Phase 4 (lines 225-287)
2. vendor-sync uses absolute `local:~/.agent-config/...` matching script resolution logic (lines 250-257, vendor-sync.sh:99-103)
3. Symlink reintroduction blocked by B5b + verification gates (lines 210-223, 315)
4. Cross-source detection strengthened with Vector 4 (lines 160-193)

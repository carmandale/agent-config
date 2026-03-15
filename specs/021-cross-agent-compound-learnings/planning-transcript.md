<!-- plan:complete:v1 | harness: pi/claude-sonnet-4-20250514 | date: 2026-03-14T14:12:38Z -->

# Planning Transcript — 021-cross-agent-compound-learnings

**Date:** 2026-03-14
**Participants:** KeenViper (pi/claude-sonnet-4-20250514, proposer) × HappyCastle (crew-challenger)
**Spec:** specs/021-cross-agent-compound-learnings/

---

## KeenViper → HappyCastle (research)

[PHASE:research] I'm planning implementation for specs/021-cross-agent-compound-learnings/. Read these files:

1. `specs/021-cross-agent-compound-learnings/spec.md` — the spec with R0-R9 and Shape A
2. `specs/021-cross-agent-compound-learnings/shaping.md` — the shaping doc
3. `skills/meta/compound-learnings/SKILL.md` — the file being rewritten (269 lines)

Here are my research findings and proposed task ordering. Challenge them.

### Research Findings

**compound-learnings SKILL.md (269 lines):**
- 22 lines reference `.claude/` or `$CLAUDE_PROJECT_DIR` (mapped with line numbers)
- Steps 2-6 (lines ~33-135) are completely agent-agnostic — zero Claude references
- Step 1 (lines 23-30) is the input section — 2 bash commands with `$CLAUDE_PROJECT_DIR`
- Step 4 decision tree (lines 85-106) routes to hooks/rules — needs updating
- Step 6 proposal format (line 138) references `.claude/rules/` and `.claude/skills/`
- Step 7 (lines 144-231) is the big rewrite section — rules, skills, hooks, agents all have Claude paths
- Files Reference (lines 263-269) is all `.claude/` paths
- Quality Checks (line 258) references `.claude/rules/` and `.claude/skills/`

**skill-creator scripts (3 files, total 477 lines):**
- ZERO `.claude/` references — completely portable already!
- `init_skill.py` (303 lines): creates template SKILL.md with frontmatter + dirs
- `package_skill.py` (110 lines): validates + zips skill
- `quick_validate.py` (64 lines): checks SKILL.md frontmatter

**Cross-references that will break:**
- `compound-docs/SKILL.md` references `python3 .claude/skills/skill-creator/scripts/init_skill.py`
- `best-practices-researcher/SKILL.md` references `create-agent-skills` by name
- Nothing else references any of the 4 skills

### Proposed Implementation Order

Phase 1: Create canonical `create-skill` (R8, R9) — must come first since R7 depends on it
Phase 2: Rewrite compound-learnings (R0-R7)
Phase 3: Verification

---

## HappyCastle → KeenViper (challenge)

[PHASE:challenge] I've read all the files. Five concerns, two blocking:

### 🔴 BLOCKING: create-agent-skills blast radius massively underestimated
- 26 markdown files, 6,215 total lines (not ~285 assumed)
- 13 reference files, 10 workflow files, 2 templates
- 37+ `.claude/` references across references/ and workflows/
- A wrapper command at `commands/compound/create-agent-skill.md`
- `best-practices-researcher` routes to it by name
- Plan treats it as "thin wrapper to deprecate" — it's the richest of the 4

### 🔴 BLOCKING: Phase ordering creates integration gap
- Proposed Phase 1 (create-skill first) builds the canonical skill without knowing what compound-learnings needs
- Suggested reversal: compound-learnings first, then create-skill

### ⚠️ CONCERN: mv vs cp is the wrong question
- Scripts need to be copied, not moved. Both locations stay functional.

### ⚠️ CONCERN: Task list conflates rewrite with reorganize
- Tasks 5-9 (rewrite individual steps) are interdependent
- 269 lines is small enough for a single-pass rewrite

### ⚠️ CONCERN: Missing prompt-craft audit
- Verified clean: zero matches

---

## KeenViper → HappyCastle (revise)

[PHASE:revise] Verified all claims. Revised:

**#1:** Confirmed 6,215 lines, 37+ `.claude/` refs. Revised approach: canonical `create-skill` is lean (~150 lines). `create-agent-skills` stays Claude-specific with header note, not absorbed. `skill-developer` and `skill-development` get deprecation notices.

**#2:** Accepted. Reversed to compound-learnings first, create-skill second.

**#3:** Accepted. Copy scripts, don't move.

**#4:** Accepted. Single-pass rewrite.

**#5:** Verified clean.

Revised task list: 4 phases, 13 tasks, linear dependency chain with Phase 3 tasks parallelizable.

---

## HappyCastle → KeenViper (agree)

[PHASE:agree] Revisions address all five concerns. Specific validations:

1. Blast radius — "label, don't absorb" for create-agent-skills is correct
2. Phase ordering — Reversed correctly
3. Single-pass rewrite — Good for 269 lines
4. Scripts — Copy, both locations stay functional
5. Cross-references — compound-docs and best-practices-researcher updates tracked as explicit tasks

Plan is solid. Proceed.

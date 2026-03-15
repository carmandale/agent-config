---
title: "Tasks: Generalize compound-learnings for cross-agent compatibility"
date: 2026-03-14
bead: .agent-config-xw9
---

<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.4 | date: 2026-03-14 -->
<!-- Status: REVISED — Step 6 AskUserQuestion fix, R5 per-source failure handling, Task 13 multi-agent, paths verified, line counts corrected, sensitive data check -->
<!-- plan:complete:v1 | harness: pi/claude-sonnet-4-20250514 | date: 2026-03-14T14:12:38Z -->

# Tasks

## Phase 1: Rewrite compound-learnings (R0–R7)

- [x] **Task 1: Single-pass rewrite of `skills/meta/compound-learnings/SKILL.md`**
  - Dependencies: none
  - Files: `skills/meta/compound-learnings/SKILL.md`
  - Changes:
    - **Frontmatter:** Remove `allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion]`. Keep `name` and `description` (update description to remove "rules" mention since rules are now AGENTS.md heuristics). No `$CLAUDE_PROJECT_DIR`.
    - **Step 1 (Gather Learnings):** Replace `$CLAUDE_PROJECT_DIR/.claude/cache/learnings/` with ordered source detection: (1) CASS via `cass search --robot` (check `which cass` first), (2) `.learnings/` in project root, (3) `.claude/cache/learnings/` if present (legacy fallback), (4) napkin (check `.claude/napkin.md` then `.napkin.md`). Include date-range filtering guidance. **Per-source failure handling:** if a source exists but returns empty/errors, report specific message and fall through. **All-empty stop:** if no sources yield data, report actionable guidance ("Install CASS for cross-agent analysis, or create `.learnings/`") and stop gracefully.
    - **Steps 2–5:** Unchanged (pure methodology, zero tool references). Leave as-is.
    - **Step 6 (Propose Artifacts):** Replace `AskUserQuestion` (line 143) with generic language: "Ask the user for approval for each artifact (or batch approval)." This is a tool-name fix only — the methodology is unchanged.
    - **Step 4 (Decision Tree):** Update routing: "Should run automatically?" → "Claude Code enhancement (see appendix below)". "When X, do Y?" → "AGENTS.md or napkin heuristic". Skills and Agent Updates unchanged.
    - **Step 6 (Propose Artifacts) — paths:** Change `**File:** .claude/rules/[name].md or .claude/skills/[name]/SKILL.md` to `**File:** ~/.agent-config/skills/<category>/<name>/SKILL.md` (for skills) or `Project AGENTS.md / napkin` (for heuristics).
    - **Step 7 (Create Approved Artifacts):** 
      - **For Skills:** Change path from `.claude/skills/` to `~/.agent-config/skills/<category>/<name>/SKILL.md`. Update taxonomy reference. Update SKILL.md template with `name` and `description` (mandatory). Reference `create-skill` for full guidance.
      - **For Heuristics (was Rules):** Replace entire rules section with guidance to append to project AGENTS.md or napkin. Template: add to relevant section with context comment.
      - **For Hooks/Rules/Agents:** Move entire hooks section, original rules section, and agents section to new `## Claude Code Enhancements` appendix at end of file. Mark clearly: "The following artifact types are available when running in Claude Code."
    - **Step 8 (Summary Report):** Update to reference `~/.agent-config/skills/` for skills, `AGENTS.md` for heuristics.
    - **Quality Checks:** Change "Check `.claude/rules/` and `.claude/skills/`" to "Check `~/.agent-config/skills/` and project AGENTS.md". Add sensitive data check: "Does the pattern contain sensitive data (API keys, credentials, PII)? If so, redact before creating an artifact."
    - **Files Reference:** Replace entire section with agent-agnostic paths: Skills → `~/.agent-config/skills/<category>/<name>/SKILL.md`, Heuristics → project AGENTS.md or napkin, Claude-specific → see appendix.
  - Acceptance: `rg '\$CLAUDE_PROJECT_DIR' SKILL.md` returns 0 matches. `rg '\.claude/' SKILL.md` returns matches ONLY in Step 1 fallback source detection and Claude appendix.

## Phase 2: Create canonical `create-skill` (R8, R9)

- [x] **Task 2: Create `skills/meta/create-skill/SKILL.md`**
  - Dependencies: Task 1 (so we know what compound-learnings expects)
  - Files: `skills/meta/create-skill/SKILL.md` (new)
  - Content: Lean skill creation guide (~150 lines) covering:
    - YAML frontmatter template (`name` and `description` mandatory)
    - Shared taxonomy (`tools/`, `review/`, `workflows/`, `domain/<sub>/`, `meta/`) with decision rule
    - Directory structure (SKILL.md + optional scripts/, references/, assets/)
    - Canonical path: `~/.agent-config/skills/<category>/<name>/SKILL.md`
    - Progressive disclosure principle (from skill-creator)
    - Writing style guidance (imperative form, from skill-creator)
    - Reference to scripts for init/validate/package
    - "Agent-specific frontmatter" appendix: `allowed-tools`, `model`, `context`, `agent` are optional Claude Code fields
  - Source material: Extract shared content from `skill-creator/SKILL.md` (210 lines) and `create-agent-skills/SKILL.md` (275 lines). Use only what's agent-agnostic.

- [x] **Task 3: Copy scripts to canonical location**
  - Dependencies: Task 2
  - Files: `skills/meta/create-skill/scripts/` (new — 3 files, 477 lines)
  - Action: Copy `skills/domain/compound/skill-creator/scripts/{init_skill.py,package_skill.py,quick_validate.py}` to `skills/meta/create-skill/scripts/`. Verify scripts have zero `.claude/` references (already confirmed). Verify scripts are executable.

## Phase 3: Deprecation notices + cross-reference updates

All tasks in this phase are independent of each other. Depends on Tasks 1–3.

- [x] **Task 4: Add deprecation header to `skills/meta/skill-developer/SKILL.md`**
  - Dependencies: Task 2
  - Action: Add to top of file (after frontmatter): `> ⚠️ **Deprecated.** This skill is Claude Code-specific. For agent-agnostic skill creation, use the [`create-skill`](../create-skill/SKILL.md) skill.`
  - Relative path verified: `meta/skill-developer/` → `../create-skill/SKILL.md` ✓

- [x] **Task 5: Add deprecation header to `skills/meta/skill-development/SKILL.md`**
  - Dependencies: Task 2
  - Action: Same deprecation header as Task 4.
  - Relative path verified: `meta/skill-development/` → `../create-skill/SKILL.md` ✓

- [x] **Task 6: Add Claude-specific header to `skills/domain/compound/create-agent-skills/SKILL.md`**
  - Dependencies: Task 2
  - Action: Add to top of file (after frontmatter): `> ℹ️ **Claude Code-specific.** This skill covers Claude Code skill authoring with advanced features (hooks, MCP pipelines, subagents). For agent-agnostic skill creation, see [`create-skill`](../../../meta/create-skill/SKILL.md).`
  - Relative path verified: `domain/compound/create-agent-skills/` → `../../../meta/create-skill/SKILL.md` ✓

- [x] **Task 7: Add Claude-specific header to `skills/domain/compound/skill-creator/SKILL.md`**
  - Dependencies: Task 2
  - Action: Same pattern as Task 6 (relative path `../../../meta/create-skill/SKILL.md`). Note that scripts are also available at `meta/create-skill/scripts/`.
  - Relative path verified: `domain/compound/skill-creator/` → `../../../meta/create-skill/SKILL.md` ✓

- [x] **Task 8: Update `skills/domain/compound/compound-docs/SKILL.md`**
  - Dependencies: Task 3
  - Action: Change `python3 .claude/skills/skill-creator/scripts/init_skill.py` to reference the canonical location: `python3 ~/.agent-config/skills/meta/create-skill/scripts/init_skill.py` (or relative path if appropriate).

- [x] **Task 9: Update `skills/workflows/best-practices-researcher/SKILL.md`**
  - Dependencies: Task 2
  - Action: Change `create-agent-skills` reference to `create-skill` in the AI/Agents routing table.

## Phase 4: Verification

- [x] **Task 10: Verify compound-learnings has no Claude hardcodings**
  - Dependencies: Task 1
  - Checks:
    - `rg '\$CLAUDE_PROJECT_DIR' skills/meta/compound-learnings/SKILL.md` → 0 matches
    - `rg '\.claude/' skills/meta/compound-learnings/SKILL.md` → matches ONLY in: (a) Step 1 fallback source `.claude/cache/learnings/`, (b) Step 1 napkin check `.claude/napkin.md`, (c) Claude Code Enhancements appendix
    - `rg 'allowed-tools' skills/meta/compound-learnings/SKILL.md` → 0 matches in frontmatter
    - Verify `~/.agent-config/skills/` appears as canonical path in Steps 6, 7, Quality Checks, Files Reference

- [x] **Task 11: Verify `create-skill` is functional**
  - Dependencies: Tasks 2, 3
  - Checks:
    - `skills/meta/create-skill/SKILL.md` exists with valid frontmatter
    - `skills/meta/create-skill/scripts/init_skill.py` exists and is executable
    - `skills/meta/create-skill/scripts/package_skill.py` exists
    - `skills/meta/create-skill/scripts/quick_validate.py` exists
    - No `.claude/` hardcoded paths in SKILL.md or scripts

- [x] **Task 12: Verify no dangling references**
  - Dependencies: Tasks 4–9
  - Checks:
    - `rg 'skill-developer' skills/ --type md` → only matches in skill-developer's own SKILL.md and its deprecation notice
    - `rg 'skill-development' skills/ --type md` → only matches in skill-development's own SKILL.md and its deprecation notice
    - `compound-docs/SKILL.md` references new script path
    - `best-practices-researcher/SKILL.md` references `create-skill`

- [x] **Task 13: Smoke test — multi-agent compatibility**
  - Dependencies: Tasks 10–12
  - Action: Read `compound-learnings/SKILL.md` from each agent's perspective:
    - **Pi:** Verify no PascalCase tool names (`Read`, `Glob`, `AskUserQuestion`), no `$CLAUDE_PROJECT_DIR`, Step 1 works when `.claude/cache/learnings/` doesn't exist.
    - **Codex:** Verify no `allowed-tools` frontmatter (Codex ignores this field), no `.claude/hooks/` instructions in main flow (only in appendix), skill output path resolves via `~/.agents/skills/` symlink.
    - **Gemini:** Verify no Claude-specific env vars, generic verbs in instructions, skill output path resolves via `~/.agents/skills/` or `~/.config/agent-skills/` symlink.
    - **Claude Code:** Verify Claude appendix still contains full hooks/rules/agents recipes, skill output still works via `.claude/skills/` symlink.
    - All agents: Verify skill creation template in Step 7 produces a valid SKILL.md at `~/.agent-config/skills/`.

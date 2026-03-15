---
title: "Plan: Generalize compound-learnings for cross-agent compatibility"
date: 2026-03-14
bead: .agent-config-xw9
---

<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.4 | date: 2026-03-14 -->
<!-- Status: REVISED — D1 updated (Step 6 AskUserQuestion fix), D5 updated (per-source failure handling), R4/R5/R6 traceability refined, security check added, blast radius updated -->
<!-- plan:complete:v1 | harness: pi/claude-sonnet-4-20250514 | date: 2026-03-14T14:12:38Z -->

# Plan: Generalize compound-learnings

## Approach

Shape A — generalize in-place. Single-pass rewrite of `compound-learnings/SKILL.md` (269 lines), creation of a lean canonical `create-skill`, and targeted deprecation/labeling of overlapping skills. No 6,000-line absorption of `create-agent-skills` — that stays Claude-specific with a header note.

## Architecture Decisions

### D1: compound-learnings is a single-pass rewrite, not incremental patches

The skill is 269 lines. Steps 2–5 (~70 lines) are untouched (pure methodology, zero tool references). Step 6 line 143 references `AskUserQuestion` (Claude tool name) — this must be replaced with generic language ("ask the user for approval") to satisfy R6. The remaining ~170 lines across Steps 1, 4, 6, 7, frontmatter, Files Reference, and Quality Checks are all interconnected — Step 7's artifact creation depends on Step 4's decision tree, which depends on what outputs are possible. A single coherent rewrite is cleaner than 5 cascading patches.

### D2: `create-agent-skills` stays Claude-specific — labeled, not absorbed

`create-agent-skills` has 6,215 lines across 26 files (13 references, 10 workflows, 2 templates, 1 SKILL.md). Its references and workflows are deeply Claude-specific (37+ `.claude/` references). Absorbing this into a canonical skill would be a massive rewrite that's out of scope. Instead:
- It stays as-is with a header: "Claude Code-specific. For agent-agnostic skill creation, see `create-skill`."
- The canonical `create-skill` is lean — template, taxonomy, scripts, ~150 lines.

### D3: Scripts are copied, not moved

`skill-creator/scripts/` (init, validate, package — 477 lines total, zero `.claude/` refs) are copied to `meta/create-skill/scripts/`. The original stays functional at its current location. Both `skill-creator` and `create-agent-skills` are labeled as Claude-specific but not broken.

### D4: Phase ordering — compound-learnings first

The spec says "R8 gates R7" but that's about path references, not about the canonical skill existing. compound-learnings can reference `~/.agent-config/skills/` and say "see `create-skill` for full guidance" before `create-skill` exists. Building compound-learnings first ensures `create-skill` is built to match what compound-learnings expects.

### D5: Input source ordered detection with failure handling

Step 1 replaces `$CLAUDE_PROJECT_DIR/.claude/cache/learnings/` with ordered fallback:
1. CASS (`cass search --robot`) — check `which cass` first. **If CASS exists but returns empty results or errors:** report "CASS returned no results for the given query/date range. Try broadening the search or check `cass status`." Then fall through to next source.
2. `.learnings/` in project root — check existence. **If directory exists but is empty:** report "`.learnings/` directory exists but contains no files." Fall through.
3. `.claude/cache/learnings/` — check existence (legacy Claude fallback). Same empty handling.
4. Napkin — check `.claude/napkin.md` then `.napkin.md`
5. **If ALL sources are unavailable or empty:** report "No learnings sources found. Install CASS (`cass`) for cross-agent session analysis, or create `.learnings/` in your project root. See `self-improving-agent` skill for logging learnings." Stop gracefully.

Date-range filtering guidance included for all sources.

### D6: Decision tree output routing

Step 4 decision tree changes:
- "Sequence of commands?" → SKILL (unchanged)
- "Automatic on event?" → ~~HOOK~~ → "Claude Code enhancement (see appendix)"
- "When X, do Y / never do X?" → ~~RULE~~ → "AGENTS.md / napkin heuristic"
- "Enhances existing agent?" → AGENT UPDATE (unchanged, but with generic guidance)

### D7: Claude Code Enhancements appendix

All Claude-specific content (hooks recipe, rules recipe, agent definition recipe) moves to a `## Claude Code Enhancements` appendix at the bottom of the skill. This section is clearly marked "When running in Claude Code, these additional artifact types are available." It preserves the full hook/rule creation guidance for Claude Code users without breaking other agents.

## Requirement Traceability

| Req | Satisfied by |
|-----|-------------|
| R0 | Phase 1 (compound-learnings rewrite — removes all Claude-only barriers) |
| R1 | Phase 1, Task 1 — Step 1 ordered source detection |
| R2 | Phase 1, Task 1 — Step 7 skills output to `~/.agent-config/skills/` |
| R3 | Phase 1, Task 1 — Claude appendix for hooks/rules/agents |
| R4 | Phase 1, Task 1 — Steps 2–5 unchanged; Step 6 minor edit (tool name only) |
| R5 | Phase 1, Task 1 — ordered fallback with per-source failure messaging and all-empty stop |
| R6 | Phase 1, Task 1 — frontmatter `allowed-tools` removed; Step 6 `AskUserQuestion` → generic; all instructions use generic verbs |
| R7 | Phase 1, Task 1 — Step 7 skill template uses `~/.agent-config/skills/` |
| R8 | Phase 2 (canonical `create-skill`) + Phase 3 (deprecation/labeling) |
| R9 | Phase 2, Task 3 — scripts copied to canonical skill |

## Blast Radius

### Files modified
| File | Change | Lines affected |
|------|--------|---------------|
| `skills/meta/compound-learnings/SKILL.md` | Rewrite | ~170 of 269 |
| `skills/domain/compound/compound-docs/SKILL.md` | Path update (1 line) | 1 |
| `skills/workflows/best-practices-researcher/SKILL.md` | Name update (1 line) | 1 |
| `skills/meta/skill-developer/SKILL.md` | Deprecation header added | +5 |
| `skills/meta/skill-development/SKILL.md` | Deprecation header added | +5 |
| `skills/domain/compound/create-agent-skills/SKILL.md` | Claude-specific header added | +3 |
| `skills/domain/compound/skill-creator/SKILL.md` | Claude-specific header added | +3 |

### Files created
| File | Purpose |
|------|---------|
| `skills/meta/create-skill/SKILL.md` | Canonical agent-agnostic skill creation guide |
| `skills/meta/create-skill/scripts/init_skill.py` | Copied from skill-creator |
| `skills/meta/create-skill/scripts/package_skill.py` | Copied from skill-creator |
| `skills/meta/create-skill/scripts/quick_validate.py` | Copied from skill-creator |

### Security consideration

Step 6's quality checks already ask "Is it general enough?" and "Is it specific enough?" — add a check: "Does the pattern contain sensitive data (API keys, credentials, PII)? If so, redact before creating an artifact." This is a single line addition to the existing Quality Checks section, not a new system.

### Files NOT modified (explicitly out of scope)
- `create-agent-skills/references/` (6,000+ lines) — stays Claude-specific
- `create-agent-skills/workflows/` — stays Claude-specific
- `commands/compound/create-agent-skill.md` — stays, Claude-specific command
- `napkin/SKILL.md` — separate spec
- CASS, CM, self-improving-agent — separate concerns

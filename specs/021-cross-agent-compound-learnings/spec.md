---
title: "Generalize compound-learnings for cross-agent compatibility"
date: 2026-03-14
bead: .agent-config-xw9
shaped: true
shape: A
shaping-doc: shaping.md
---

<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.4 | date: 2026-03-14 -->
<!-- Status: REVISED — R4 wording updated (Steps 2-5 + Step 6 tool-name fix), R8 acceptance criteria aligned (2 deprecated + 2 Claude-specific), A8 shape summary aligned, risk table aligned, Files in Scope expanded -->
<!-- issue:complete:v1 | harness: pi/claude-sonnet-4-20250514 | date: 2026-03-14T14:04:39Z -->

# Generalize compound-learnings for cross-agent compatibility

## Problem

The `compound-learnings` skill (`meta/compound-learnings/SKILL.md`) transforms session learnings into permanent capabilities — skills, rules, hooks, and agent updates. Its methodology (pattern extraction, frequency analysis, categorization, signal thresholds) is agent-agnostic and proven. But every input source, output path, and creation instruction is hardcoded for Claude Code.

**Impact:**
- Pi, Codex, Gemini agents cannot run this skill — the input source (`.claude/cache/learnings/`) doesn't exist, the output paths (`.claude/rules/`, `.claude/hooks/`) are wrong, and the tool names (`Read`, `Glob`, `AskUserQuestion`) don't match.
- Skills created through this workflow _do_ land in the shared `~/.agent-config/skills/` directory (via symlink), but the creation guidance references Claude-specific concepts.
- 4 overlapping skill-creation skills (`create-agent-skills`, `skill-creator`, `skill-developer`, `skill-development`) all assume Claude Code — compounding the problem.

### Specific hardcodings

| Item | Current (Claude-only) | Impact |
|------|----------------------|--------|
| `$CLAUDE_PROJECT_DIR` | Used as base path everywhere | Undefined in other agents |
| `.claude/cache/learnings/` | Learnings source (Step 1) | Doesn't exist for Pi/Codex/Gemini |
| `.claude/rules/` | Rules output | Not symlinked, no equivalent |
| `.claude/hooks/` + esbuild pipeline | Hooks output | Claude-only architecture |
| `.claude/agents/` | Agent definition output | Claude `.md` format; Pi uses subagent configs |
| `.claude/skills/` | Skills output | Works via symlink, but instructions reference Claude concepts |
| `allowed-tools: [Read, Glob, Grep, ...]` | PascalCase Claude tool names | Pi uses `read`, `bash`; other agents vary |
| Hook registration in `settings.json` | Claude hook system | No equivalent in Pi (extensions) or Codex |

### Cross-agent learning systems that exist but aren't wired

| System | What it does | Cross-agent? | Status |
|--------|-------------|--------------|--------|
| **CASS** (`cass`) | Indexes sessions from 11 agents | ✅ | Installed |
| **CM** (`cm`) | Distills CASS into procedural memory | ✅ | Not installed |
| **self-improving-agent** | Logs to `.learnings/` in project root | ⚠️ Per-project | Available |
| **napkin** | Per-repo runbook | ❌ Hardcoded `.claude/napkin.md` | Available |

---

## Selected Shape: A — Generalize in-place

> Full shaping in `shaping.md`. Shapes B (methodology extraction) and C (CASS-first rewrite) were eliminated — B for premature extraction with no other consumer, C for hard CASS dependency failing R5.

Rewrite compound-learnings as a single agent-agnostic skill. Replace all `.claude/` references with generic equivalents. Skills are the primary output. Agent-specific outputs (rules, hooks) move to a clearly-marked Claude appendix. The 4 overlapping skill-creation skills are rationalized into one canonical skill via extract + deprecate + preserve.

| Part | Mechanism |
|------|-----------|
| **A1** | **Input: ordered source detection** — Step 1 tries sources: (1) CASS (`cass search --robot`), (2) `.learnings/` in project root, (3) `.claude/cache/learnings/` if present, (4) napkin (detect path). Use first available. Date-range filtering to avoid re-analyzing. |
| **A2** | **Output — Skills:** `~/.agent-config/skills/<category>/<name>/SKILL.md` with shared taxonomy |
| **A3** | **Output — Rules:** "append to project AGENTS.md or napkin" — captures intent in the most universal location |
| **A4** | **Output — Hooks/Agents:** `## Claude Code Enhancements` appendix, clearly marked as agent-specific |
| **A5** | **Frontmatter:** remove `allowed-tools`, remove `$CLAUDE_PROJECT_DIR`. Generic verbs in instructions. |
| **A6** | **Skill creation guidance:** inline templates reference `~/.agent-config/skills/` and shared taxonomy |
| **A7** | **Decision tree (Step 4):** Rules → "AGENTS.md/napkin"; Hooks → "Claude-only, see appendix" |
| **A8** | **Skill-creation rationalization:** canonical `create-skill` in `meta/`, preserve `skill-creator`'s scripts, deprecate 2 (`skill-developer`, `skill-development`) with redirect notices, label 2 (`create-agent-skills`, `skill-creator`) as Claude-specific with redirect |

---

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Any agent (Pi, Codex, Gemini, Claude Code) can run compound-learnings and produce shared skills | Core goal |
| R1 | Input sources are agent-agnostic — ordered detection (CASS → `.learnings/` → `.claude/cache/learnings/` → napkin), not hardcoded to `.claude/` | Must-have |
| R2 | Skill output targets `~/.agent-config/skills/` as canonical path | Must-have |
| R3 | Agent-specific outputs (rules, hooks, agent defs) available where the agent supports them; intent captured in agent-agnostic locations (AGENTS.md, napkin) where it doesn't | Must-have |
| R4 | Methodology (Steps 2–5: pattern extraction, consolidation, meta-patterns, categorization, thresholds) preserved unchanged; Step 6 proposal format preserved with tool-name generalization only | Must-have |
| R5 | Graceful degradation when CASS or other input sources are unavailable | Must-have |
| R6 | No Claude-specific tool names or env vars in skill frontmatter or instructions | Must-have |
| R7 | Skill-creation guidance within compound-learnings references shared paths and taxonomy | Must-have |
| R8 | The 4 overlapping skill-creation skills rationalized — canonical `create-skill` with shared paths, deprecation notices for others | Must-have |
| R9 | Executable tooling from consolidated skills (init, validate, package scripts) preserved or explicitly deprecated with rationale | Must-have |

**Dependency chain:** R8 gates R7 (creation guidance can't use shared paths if the creation skill itself is Claude-locked). R9 gates R8 (consolidation must account for `skill-creator`'s executable scripts).

---

## Acceptance Criteria

1. **Pi agent can run compound-learnings** and produce a valid skill in `~/.agent-config/skills/` without errors or references to missing `.claude/` paths.
2. **No `$CLAUDE_PROJECT_DIR`** references remain in compound-learnings.
3. **No `.claude/` hardcoded paths** remain except as one of several fallback sources in Step 1's ordered detection.
4. **CASS is the primary learnings source** when available; skill degrades gracefully with clear messaging when CASS isn't installed, falling back to `.learnings/` or `.claude/cache/learnings/`.
5. **Canonical `create-skill`** exists in `meta/` with shared paths (`~/.agent-config/skills/`), shared taxonomy, and YAML frontmatter template.
6. **`skill-creator`'s scripts** (`init_skill.py`, `package_skill.py`, `quick_validate.py`) are preserved in the canonical skill or explicitly deprecated with rationale.
7. **2 deprecated skills** (`skill-developer`, `skill-development`) contain deprecation notices pointing to the canonical `create-skill`. **2 Claude-specific skills** (`create-agent-skills`, `skill-creator`) get "Claude Code-specific" headers pointing to `create-skill` for the generic path — they remain functional for Claude Code users.
8. **Rules and hooks** are documented as agent-specific enhancements in a `## Claude Code Enhancements` appendix, not as universal outputs.
9. **Decision tree (Step 4)** routes rules to "AGENTS.md/napkin heuristic" and hooks to "Claude-only, see appendix."
10. **`allowed-tools` field** removed from frontmatter; instructions use generic verbs.

---

## Out of Scope

- Installing CM (`cm`) — separate concern
- Rewriting `self-improving-agent`, `workflows-compound`, or `learnings-researcher` — different purposes
- Creating a Pi-native hook/extension system equivalent — platform gap, not this spec's job
- Changing the napkin skill itself — separate spec if needed (napkin hardcodes `.claude/napkin.md`)
- Modifying CASS or its indexing behavior

## Constraints

- `~/.agent-config/skills/` is the source of truth for shared skills
- Symlinks: `~/.claude/skills/`, `~/.agents/skills/`, `~/.config/agent-skills/` → `~/.agent-config/skills/`
- Skills in category directories are auto-discovered — no symlinks needed within the tree
- YAML frontmatter `description` field is the primary discovery mechanism for all agents

## Risks

| Risk | Mitigation |
|------|-----------|
| Skill-creation skill consolidation breaks workflows referencing old names | 2 deprecated skills get redirect notices; 2 Claude-specific skills get headers pointing to canonical — no functionality removed |
| CASS availability varies by machine | Graceful degradation: ordered fallback, clear "CASS not found" message |
| Napkin path varies (`.claude/napkin.md` vs other) | Simple ordered check: `.claude/napkin.md` → `.napkin.md` → skip |
| `skill-creator`'s scripts may have Claude-specific assumptions | Audit scripts during consolidation; update paths if needed |

## Files in Scope

| File | Role |
|------|------|
| `skills/meta/compound-learnings/SKILL.md` | Primary target — generalize |
| `skills/domain/compound/skill-creator/SKILL.md` | Source for canonical `create-skill` (has scripts) |
| `skills/domain/compound/skill-creator/scripts/` | Executable tooling to preserve |
| `skills/domain/compound/create-agent-skills/SKILL.md` | Label Claude-specific → redirect to canonical |
| `skills/meta/skill-developer/SKILL.md` | Deprecate → redirect |
| `skills/meta/skill-development/SKILL.md` | Deprecate → redirect |
| `skills/meta/create-skill/SKILL.md` | New canonical skill (to create) |
| `skills/domain/compound/compound-docs/SKILL.md` | Cross-reference update (script path) |
| `skills/workflows/best-practices-researcher/SKILL.md` | Cross-reference update (skill name) |

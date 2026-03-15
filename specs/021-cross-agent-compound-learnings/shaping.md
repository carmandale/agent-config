---
shaping: true
---

# Cross-Agent Compound Learnings — Shaping

## Frame

### Source

The `compound-learnings` skill (`meta/compound-learnings/SKILL.md`) is a meta-learning workflow that mines past session data, detects recurring patterns, and transforms them into permanent capabilities (skills, rules, hooks, agent updates). It originated in the Compound Engineering suite for Claude Code.

The user runs this across Pi, Codex, Gemini, and Claude Code via the shared `~/.agent-config/skills/` symlink architecture. Every input path, output path, and creation instruction is hardcoded for Claude Code — `$CLAUDE_PROJECT_DIR`, `.claude/cache/learnings/`, `.claude/rules/`, `.claude/hooks/`, `.claude/agents/`, Claude-specific tool names in YAML frontmatter.

Additionally, 4 overlapping "skill creation" skills exist (`create-agent-skills`, `skill-creator`, `skill-developer`, `skill-development`) — all referencing Claude Code paths and concepts.

### Problem

- Pi, Codex, Gemini agents cannot run compound-learnings effectively — the input source doesn't exist, the output paths are wrong, and the tool names don't match.
- Skills created through this workflow _do_ land in the shared directory (via symlink), but the creation guidance references Claude-specific concepts.
- 4 overlapping skill-creation skills cause confusion and all assume Claude Code.
- The methodology (pattern extraction, frequency analysis, signal thresholds) is agent-agnostic and proven — it's wasted when locked to one agent.

### Outcome

Any agent in the shared skill ecosystem can run compound-learnings to mine its own sessions and produce shared skills that all agents benefit from. The methodology is preserved. Agent-specific capabilities (Claude hooks, rules) remain available when running in Claude Code but don't break other agents.

---

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Any agent (Pi, Codex, Gemini, Claude Code) can run compound-learnings and produce shared skills | Core goal |
| R1 | Input sources are agent-agnostic — ordered detection (CASS → `.learnings/` → `.claude/cache/learnings/` → napkin), not hardcoded to `.claude/` | Must-have |
| R2 | Skill output targets `~/.agent-config/skills/` as canonical path | Must-have |
| R3 | Agent-specific outputs (rules, hooks, agent definitions) available where the agent supports them; intent captured in agent-agnostic locations (AGENTS.md, napkin) where it doesn't | Must-have |
| R4 | Methodology (Steps 2–5: pattern extraction, consolidation, meta-patterns, categorization, thresholds) preserved unchanged; Step 6 proposal format preserved with tool-name generalization only | Must-have |
| R5 | Graceful degradation when CASS or other input sources are unavailable | Must-have |
| R6 | No Claude-specific tool names or env vars in skill frontmatter or instructions | Must-have |
| R7 | Skill-creation guidance within compound-learnings references shared paths and taxonomy | Must-have |
| R8 | The 4 overlapping skill-creation skills are rationalized — canonical `create-skill` with shared paths, deprecation notices for others | Must-have |
| R9 | Executable tooling from consolidated skill-creation skills (init, validate, package scripts) preserved or explicitly deprecated with rationale | Must-have |

---

## CURRENT: How it works today

| Part | Mechanism |
|------|-----------|
| **CUR1** | **Input:** `ls -t $CLAUDE_PROJECT_DIR/.claude/cache/learnings/*.md` — reads Claude-only cache |
| **CUR2** | **Analysis:** Steps 2–6 — pattern extraction, consolidation, meta-patterns, categorization, thresholds (agent-agnostic) |
| **CUR3** | **Output — Skills:** writes to `.claude/skills/<category>/<name>/SKILL.md` (works via symlink) |
| **CUR4** | **Output — Rules:** writes to `.claude/rules/<name>.md` (Claude-only, not symlinked) |
| **CUR5** | **Output — Hooks:** shell wrapper + esbuild TS → `settings.json` registration (Claude-only architecture) |
| **CUR6** | **Output — Agents:** edits `.claude/agents/<name>.md` (Claude-only format) |
| **CUR7** | **Frontmatter:** `allowed-tools: [Read, Glob, Grep, Write, Edit, Bash, AskUserQuestion]` (Claude tool names) |
| **CUR8** | **Skill creation guidance:** references `.claude/skills/`, `$CLAUDE_PROJECT_DIR`, "Claude Code skills" |

---

## Shapes Explored

### B: Extract methodology + agent adapters — ELIMINATED

Split into pure methodology skill + thin orchestrator with agent detection. Eliminated because: no other workflow consumes the methodology (verified via `rg "pattern extraction|frequency table|signal threshold|meta-pattern"` — only compound-learnings matches). Premature extraction with no current consumer.

### C: CASS-first rewrite + Claude companion — ELIMINATED

Rebuild entirely around CASS as sole input. Eliminated because: hard CASS dependency fails R5 (graceful degradation). CASS isn't installed on all machines, and even when installed, may have no indexed sessions for a new project.

---

## Selected Shape: A — Generalize in-place

Rewrite compound-learnings as a single agent-agnostic skill. Replace all `.claude/` references with generic equivalents. Skills are the primary output. Agent-specific outputs (rules, hooks) move to a clearly-marked appendix that only applies when running in Claude Code. The 4 overlapping skill-creation skills are rationalized into one canonical skill via extract + deprecate + preserve.

| Part | Mechanism |
|------|-----------|
| **A1** | **Input: ordered source detection** — Step 1 tries sources in order: (1) CASS (`cass search --robot`), (2) `.learnings/` in project root, (3) `.claude/cache/learnings/` if present, (4) napkin (detect path). Use first available. Include date-range filtering guidance to avoid re-analyzing old sessions. |
| **A2** | **Output — Skills:** write to `~/.agent-config/skills/<category>/<name>/SKILL.md` with shared taxonomy (`tools/`, `review/`, `workflows/`, `domain/<sub>/`, `meta/`) |
| **A3** | **Output — Rules:** replace with "append to project AGENTS.md or napkin" guidance. Captures the heuristic's _intent_ in the most universal location available. |
| **A4** | **Output — Hooks/Agents:** move to a `## Claude Code Enhancements` appendix section, clearly marked as "when running in Claude Code." Hooks get the esbuild/settings.json recipe; agents get the `.claude/agents/` recipe. |
| **A5** | **Frontmatter:** remove `allowed-tools` field entirely. Remove all `$CLAUDE_PROJECT_DIR` references. Instructions use generic verbs ("read the file", "search for") not tool names. |
| **A6** | **Skill creation guidance:** update inline templates in Step 7 to reference `~/.agent-config/skills/` and shared taxonomy. YAML frontmatter template with `name` and `description` (mandatory). |
| **A7** | **Decision tree (Step 4):** Rules → "AGENTS.md/napkin heuristic"; Hooks → "flag as Claude-only, see appendix"; Skills and Agent Updates unchanged. |
| **A8** | **Skill-creation skill rationalization:** Create canonical `create-skill` in `meta/`. Extract shared content (SKILL.md template, taxonomy, YAML frontmatter guidance). Preserve `skill-creator`'s init/validate/package scripts (relocated into the canonical skill). Document agent-specific frontmatter fields (`allowed-tools`, `model`, `context`) as optional in a "Claude Code" appendix. Deprecate 2 (`skill-developer`, `skill-development`) with notices pointing to canonical. Label 2 (`create-agent-skills`, `skill-creator`) as Claude-specific with redirect to canonical. |

---

## Fit Check: R × A

| Req | Requirement | Status | A |
|-----|-------------|--------|---|
| R0 | Any agent can run compound-learnings and produce shared skills | Core goal | ✅ |
| R1 | Input sources are agent-agnostic — ordered detection | Must-have | ✅ |
| R2 | Skill output targets `~/.agent-config/skills/` | Must-have | ✅ |
| R3 | Agent-specific outputs: available where supported, intent in AGENTS.md elsewhere | Must-have | ✅ |
| R4 | Methodology (Steps 2–6) preserved unchanged | Must-have | ✅ |
| R5 | Graceful degradation when sources unavailable | Must-have | ✅ |
| R6 | No Claude-specific tool names/env vars in frontmatter | Must-have | ✅ |
| R7 | Skill-creation guidance uses shared paths and taxonomy | Must-have | ✅ |
| R8 | 4 skill-creation skills rationalized | Must-have | ✅ |
| R9 | Executable tooling preserved | Must-have | ✅ |

**All requirements satisfied.** No flagged unknowns (⚠️).

---

## Shaping Decisions Log

1. **Shape B eliminated** — premature methodology extraction with no other consumer (verified via search)
2. **Shape C eliminated** — hard CASS dependency fails R5
3. **R3 sharpened** — "available where supported, intent captured elsewhere" (not "output parity across agents" — platform limitation, not design flaw)
4. **R8 promoted** from Nice-to-have to Must-have — R8 is a blocking dependency for R7 (creation guidance can't reference shared paths if the creation skill itself is Claude-locked)
5. **R9 added** — `skill-creator`'s init/validate/package scripts are real executable tooling that must survive consolidation
6. **A8 revised** — extract + deprecate + preserve (not naive "merge 4 into 1")

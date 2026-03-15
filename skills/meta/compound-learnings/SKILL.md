---
name: compound-learnings
description: Transform session learnings into permanent capabilities (skills, heuristics, agent updates). Use when asked to "improve setup", "learn from sessions", "compound learnings", or "what patterns should become skills".
---

# Compound Learnings

Transform ephemeral session learnings into permanent, compounding capabilities.

## When to Use

- "What should I learn from recent sessions?"
- "Improve my setup based on recent work"
- "Turn learnings into skills"
- "What patterns should become permanent?"
- "Compound my learnings"

## Process

### Step 1: Gather Learnings

Try sources in order. Use the first that yields results. If a source exists but returns empty or errors, report a specific message and try the next source.

**Source 1 — CASS (cross-agent session search):**

```bash
# Check if CASS is available
which cass >/dev/null 2>&1 && echo "CASS available" || echo "CASS not installed — skipping"

# Search recent sessions for patterns (use --robot for machine-readable output)
cass search "patterns learnings takeaway" --robot --after 2026-01-01
```

If CASS returns no results: "CASS returned no results for the given query/date range. Try broadening the search or check `cass status`." Fall through to next source.

**Source 2 — Project learnings directory:**

```bash
# Check for .learnings/ in project root
ls .learnings/*.md 2>/dev/null | head -20
```

If `.learnings/` exists but is empty: "`.learnings/` directory exists but contains no files." Fall through.

**Source 3 — Claude Code learnings cache (legacy fallback):**

```bash
# Only if .claude/cache/learnings/ exists
ls -t .claude/cache/learnings/*.md 2>/dev/null | head -20
```

**Source 4 — Napkin (curated patterns):**

```bash
# Check for napkin in common locations
cat .claude/napkin.md 2>/dev/null || cat .napkin.md 2>/dev/null || echo "No napkin found"
```

**If ALL sources are unavailable or empty:** "No learnings sources found. Install CASS (`cass`) for cross-agent session analysis, or create `.learnings/` in your project root. See `self-improving-agent` skill for logging learnings during sessions." Stop gracefully.

**Date filtering:** For any source, scope to recent sessions (e.g., last 30 days) unless the user specifies a broader range. This avoids re-analyzing old sessions on repeated runs.

Read the most recent 5–10 results (or specify a date range).

### Step 2: Extract Patterns (Structured)

For each learnings source, extract entries from these specific sections:

| Section Header | What to Extract |
|----------------|-----------------|
| `## Patterns` or `Reusable techniques` | Direct candidates for heuristics |
| `**Takeaway:**` or `**Actionable takeaway:**` | Decision heuristics |
| `## What Worked` | Success patterns |
| `## What Failed` | Anti-patterns (invert to heuristics) |
| `## Key Decisions` | Design principles |

Build a frequency table as you go:

```markdown
| Pattern | Sessions | Category |
|---------|----------|----------|
| "Check artifacts before editing" | abc, def, ghi | debugging |
| "Pass IDs explicitly" | abc, def, ghi, jkl | reliability |
```

### Step 2b: Consolidate Similar Patterns

Before counting, merge patterns that express the same principle:

**Example consolidation:**
- "Artifact-first debugging"
- "Verify hook output by inspecting files"
- "Filesystem-first debugging"
→ All express: **"Observe outputs before editing code"**

Use the most general formulation. Update the frequency table.

### Step 3: Detect Meta-Patterns

**Critical step:** Look at what the learnings cluster around.

If >50% of patterns relate to one topic (e.g., "hooks", "tracing", "async"):
→ That topic may need a **dedicated skill** rather than multiple heuristics
→ One skill compounds better than five heuristics

Ask yourself: *"Is there a skill that would make all these heuristics unnecessary?"*

### Step 4: Categorize (Decision Tree)

For each pattern, determine artifact type:

```
Is it a sequence of commands/steps?
  → YES → SKILL (executable > declarative)
  → NO ↓

Should it run automatically on an event?
  → YES → CLAUDE CODE ENHANCEMENT (see appendix below)
  → NO ↓

Is it "when X, do Y" or "never do X"?
  → YES → HEURISTIC (append to AGENTS.md or napkin)
  → NO ↓

Does it enhance an existing agent workflow?
  → YES → AGENT UPDATE
  → NO → Skip (not worth capturing)
```

**Artifact Type Examples:**

| Pattern | Type | Why |
|---------|------|-----|
| "Run linting before commit" | Claude Code enhancement | Automatic gate (hook) |
| "Extract learnings on session end" | Claude Code enhancement | Automatic trigger (hook) |
| "Debug hooks step by step" | Skill | Manual sequence |
| "Always pass IDs explicitly" | Heuristic | Append to AGENTS.md |

### Step 5: Apply Signal Thresholds

| Occurrences | Action |
|-------------|--------|
| 1 | Note but skip (unless critical failure) |
| 2 | Consider - present to user |
| 3+ | Strong signal - recommend creation |
| 4+ | Definitely create |

### Step 6: Propose Artifacts

Present each proposal in this format:

```markdown
---

## Pattern: [Generalized Name]

**Signal:** [N] sessions ([list session IDs])

**Category:** [debugging / reliability / workflow / etc.]

**Artifact Type:** Skill / Heuristic / Agent Update

**Rationale:** [Why this artifact type, why worth creating]

**Draft Content:**
\`\`\`markdown
[Actual content that would be written to file]
\`\`\`

**File:** `~/.agent-config/skills/<category>/<name>/SKILL.md` (for skills) or `Project AGENTS.md / napkin` (for heuristics)

---
```

Ask the user for approval for each artifact (or batch approval).

### Step 7: Create Approved Artifacts

#### For Skills:

Create `~/.agent-config/skills/<category>/<name>/SKILL.md`. Choose category with the decision rule: wraps CLI/API → `tools/`, analyzes/reviews → `review/`, orchestrates dev process → `workflows/`, technology-specific → `domain/<sub>/`, agent behavior → `meta/`.

**The YAML frontmatter is mandatory.** Without `description`, the skill is invisible to all agents. Use this exact template:

```markdown
---
name: <skill-name>
description: <What it does. Use when [specific triggers]. Handles [patterns].>
---

# Skill Title

## When to Use

- [trigger 1]
- [trigger 2]

## Process

[Step-by-step instructions]

## Evidence

- [source session/spec]: [what happened]
```

The `description` field is the primary discovery mechanism — include what the skill does, when to use it (trigger phrases), and what patterns/keywords should activate it.

Skills placed in category directories are discovered automatically via recursive scan — no symlink needed. See the `create-skill` skill for full guidance on skill authoring, including init/validate/package scripts.

#### For Heuristics:

Append to the project's `AGENTS.md` or napkin. Add the heuristic to the most relevant section with context:

```markdown
## [Section Name]

<!-- Heuristic from compound-learnings: [N] sessions, [category] -->
- [The reusable principle] — [brief context of why]
```

If no relevant section exists, create one. Keep heuristics concise and actionable.

#### For Agent Updates:

Edit the relevant agent configuration to add the learned capability. The format depends on which agent you're running in — check the agent's documentation for its config format.

### Step 8: Summary Report

```markdown
## Compounding Complete

**Learnings Analyzed:** [N] sessions
**Patterns Found:** [M]
**Artifacts Created:** [K]

### Created:
- Skill: `debug-hooks` — Hook debugging workflow → `~/.agent-config/skills/workflows/debug-hooks/SKILL.md`
- Heuristic: "Pass IDs explicitly" — added to project AGENTS.md

### Skipped (insufficient signal):
- "Pattern X" (1 occurrence)

**Your setup is now permanently improved.**
```

## Quality Checks

Before creating any artifact:

1. **Is it general enough?** Would it apply in other projects?
2. **Is it specific enough?** Does it give concrete guidance?
3. **Does it already exist?** Check `~/.agent-config/skills/` and project AGENTS.md first
4. **Is it the right type?** Sequences → skills, heuristics → AGENTS.md/napkin
5. **Does it contain sensitive data?** API keys, credentials, PII must be redacted before creating an artifact.

## Files Reference

- **Skills:** `~/.agent-config/skills/<category>/<name>/SKILL.md`
- **Heuristics:** Project `AGENTS.md` or `.claude/napkin.md` / `.napkin.md`
- **Claude Code-specific artifacts:** See appendix below

---

## Claude Code Enhancements

> The following artifact types are available when running in Claude Code. They are not universal — other agents (Pi, Codex, Gemini) do not support these mechanisms. If a pattern should be an automatic gate or trigger, capture its *intent* as a heuristic in AGENTS.md for other agents, and create the hook/rule here for Claude Code.

#### For Rules (Claude Code only):
```bash
cat > .claude/rules/<name>.md << 'EOF'
# Rule Name

[Context: why this rule exists, based on N sessions]

## Pattern
[The reusable principle]

## DO
- [Concrete action]

## DON'T
- [Anti-pattern]

## Source Sessions
- [session-id-1]: [what happened]
- [session-id-2]: [what happened]
EOF
```

#### For Hooks (Claude Code only):
Create shell wrapper + TypeScript handler:

```bash
cat > .claude/hooks/<name>.sh << 'EOF'
#!/bin/bash
set -e
cd "$(dirname "$0")"
cat | node dist/<name>.mjs
EOF
chmod +x .claude/hooks/<name>.sh
```

Then create `src/<name>.ts`, build with esbuild, and register in `.claude/settings.json`:

```json
{
  "hooks": {
    "EventName": [{
      "hooks": [{
        "type": "command",
        "command": ".claude/hooks/<name>.sh"
      }]
    }]
  }
}
```

#### For Agent Definitions (Claude Code only):
Edit existing agent in `.claude/agents/<name>.md` to add the learned capability.

---
name: create-skill
description: Create agent-agnostic skills for the shared skill ecosystem. Use when creating a new skill, scaffolding a skill directory, validating skill structure, or understanding skill authoring best practices. Works across all agents (Pi, Codex, Gemini, Claude Code).
---

# Create Skill

Guide for creating effective, agent-agnostic skills that work across all agents in the shared `~/.agent-config/skills/` ecosystem.

## When to Use

- "Create a skill for X"
- "Help me make a new skill"
- "Turn this into a skill"
- "How do I create a skill?"
- "Scaffold a new skill"

## Canonical Path

All shared skills live in `~/.agent-config/skills/` — this is the source of truth. Symlinks make skills visible to all agents:

| Agent | Discovers skills from |
|-------|----------------------|
| Claude Code | `~/.claude/skills/` → `~/.agent-config/skills/` |
| Pi | `~/.agents/skills/` → `~/.agent-config/skills/` |
| Codex | `~/.agents/skills/` → `~/.agent-config/skills/` |
| Gemini | `~/.agents/skills/` → `~/.agent-config/skills/` |

Skills placed in category directories are auto-discovered via recursive scan — no per-skill symlinks needed.

## Skill Structure

```
~/.agent-config/skills/<category>/<skill-name>/
├── SKILL.md          # Required: main skill definition
├── scripts/          # Optional: executable code (Python/Bash)
├── references/       # Optional: documentation loaded into context as needed
└── assets/           # Optional: files used in output (templates, icons)
```

## Category Taxonomy

Choose the category using this decision rule:

| Question | Category |
|----------|----------|
| Wraps an external CLI, API, or service? | `tools/` |
| Analyzes or reviews code/content? | `review/` |
| Orchestrates a multi-step dev process? | `workflows/` |
| Specific to a named technology domain? | `domain/<sub>/` |
| Agent behavior rule or meta-pattern? | `meta/` |

Apply rules in order — first match wins.

## YAML Frontmatter (Required)

Every SKILL.md must have YAML frontmatter with at minimum `name` and `description`:

```yaml
---
name: my-skill-name
description: What it does. Use when [specific triggers]. Handles [patterns].
---
```

### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `name` | Yes | Lowercase letters, numbers, hyphens. Max 64 chars. |
| `description` | Yes | What it does AND when to use it. This is the primary discovery mechanism — all agents use it to decide when to load the skill. Max 1024 chars. |

**The `description` is the trigger.** Include what the skill does, when to use it (trigger phrases), and what patterns/keywords should activate it.

**Bad:** `description: Helps with documents`
**Good:** `description: Extract text and tables from PDF files, fill forms, merge documents. Use when working with PDF files or when the user mentions PDFs, forms, or document extraction.`

### Agent-Specific Frontmatter (Optional)

These fields are supported by Claude Code but ignored by other agents. Include them only when needed:

| Field | Agent | Description |
|-------|-------|-------------|
| `allowed-tools` | Claude Code | Restrict which tools the skill can use. Example: `[Read, Bash, Write]` |
| `model` | Claude Code | Model to use: `haiku`, `sonnet`, `opus` |
| `context` | Claude Code | Set `fork` to run in isolated subagent context |
| `agent` | Claude Code | Subagent type when `context: fork` |
| `disable-model-invocation` | Claude Code | Prevent auto-loading; manual `/invoke` only |
| `user-invocable` | Claude Code | Set `false` to hide from slash menu |

## SKILL.md Template

```markdown
---
name: <skill-name>
description: <What it does. Use when [specific triggers]. Handles [patterns].>
---

# Skill Title

## When to Use

- [trigger phrase 1]
- [trigger phrase 2]

## Process

[Step-by-step instructions]

## Examples

[Concrete usage examples]
```

## Writing Style

Write using **imperative/infinitive form** (verb-first instructions). Use objective, instructional language:

- ✅ "To accomplish X, do Y"
- ❌ "You should do X"

## Progressive Disclosure

Keep SKILL.md under 500 lines. Split detailed content into reference files:

```
my-skill/
├── SKILL.md           # Entry point — overview + navigation
├── reference.md       # Detailed docs (loaded when needed)
└── scripts/
    └── helper.py      # Utility script (executed, not loaded)
```

Link from SKILL.md: `For details, see [reference.md](reference.md).`

Keep references one level deep from SKILL.md. Avoid nested chains.

## Scripts

This skill includes scripts for scaffolding, validating, and packaging skills:

### Initialize a new skill

```bash
python3 ~/.agent-config/skills/meta/create-skill/scripts/init_skill.py <skill-name> --path <output-directory>
```

Creates a template skill directory with SKILL.md, scripts/, references/, and assets/ subdirectories.

### Validate a skill

```bash
python3 ~/.agent-config/skills/meta/create-skill/scripts/quick_validate.py <path/to/skill-folder>
```

Checks YAML frontmatter format, required fields, and basic structure.

### Package a skill for distribution

```bash
python3 ~/.agent-config/skills/meta/create-skill/scripts/package_skill.py <path/to/skill-folder>
```

Validates and creates a distributable zip file.

## Quality Checklist

Before committing a new skill:

- [ ] Valid YAML frontmatter (`name` + `description`)
- [ ] `description` includes trigger keywords and is specific
- [ ] SKILL.md under 500 lines
- [ ] Uses standard markdown headings
- [ ] References one level deep, properly linked
- [ ] Examples are concrete, not abstract
- [ ] No hardcoded agent-specific paths in main content
- [ ] Tested with real usage

## Related Skills

- For Claude Code-specific skill features (hooks, MCP pipelines, subagents), see `create-agent-skills`
- For the full Claude Code skill authoring process with init/validate/package scripts, see `skill-creator`

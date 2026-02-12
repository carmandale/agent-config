# Agent Config Repository

Unified configuration hub for AI coding agents. One central location that all agents share via symlinks.

## What This Repo Is

This is **the source of truth** for agent configuration across Pi, Claude Code, Codex, and other agents. Changes here propagate to all agents automatically via symlinks.

## Directory Structure

```
~/.agent-config/
├── skills/                  # Shared skills (symlinked to ~/.claude/skills, ~/.pi/agent/skills, etc.)
│   ├── personal/            # User-created skills
│   ├── tools/               # CLI/tool integrations
│   ├── cc3/                 # Claude Code v3 framework skills
│   ├── compound/            # Compound skills
│   └── [name] -> [category]/[name]  # Top-level symlinks for discovery
├── commands/                # Slash commands (shared across agents)
├── instructions/
│   ├── AGENTS.md            # Global instructions (symlinked to ~/.claude/CLAUDE.md, etc.)
│   └── CLAUDE.md -> AGENTS.md
├── install.sh               # Creates all symlinks
└── README.md                # User documentation
```

## Symlink Architecture

The `install.sh` script creates these symlinks:

| Agent Config Location | Points To |
|-----------------------|-----------|
| `~/.claude/skills` | `~/.agent-config/skills` |
| `~/.claude/CLAUDE.md` | `~/.agent-config/instructions/AGENTS.md` |
| `~/.claude/commands` | `~/.agent-config/commands` |
| `~/.pi/agent/skills` | `~/.agent-config/skills` |
| `~/.pi/agent/AGENTS.md` | `~/.agent-config/instructions/AGENTS.md` |
| `~/.pi/agent/commands` | `~/.agent-config/commands` |
| `~/.codex/skills` | `~/.agent-config/skills` |

## Skills System

**Both Pi and Claude Code have native skill systems.** Skills are discovered from `~/.claude/skills/` (or `~/.pi/agent/skills/`).

### Skill Format

```
skills/personal/my-skill/
└── SKILL.md
```

**SKILL.md structure:**
```markdown
---
name: my-skill
description: What it does. Use when [specific triggers]. Handles [patterns].
---

# my-skill

Instructions for the skill...
```

### Critical: Description is the Trigger

The `description` field in YAML frontmatter is **the primary mechanism** for skill discovery. Include:
- What the skill does
- **When to use it** (trigger phrases)
- URL patterns, file types, or keywords that should activate it

**Bad:** `description: CLI for X`
**Good:** `description: Read and search X/Twitter. Use when user shares x.com links, asks to read tweets, or search Twitter.`

### Skill Organization

- `skills/personal/` - User-created skills
- `skills/tools/` - CLI tool integrations
- `skills/cc3/` - Framework skills
- Top-level symlinks (e.g., `skills/bird -> personal/bird`) enable discovery

## Commands

Slash commands in `commands/` are markdown files with optional YAML frontmatter:

```markdown
---
description: What this command does
---

Command instructions...
```

## Making Changes

1. **Edit skills** in `skills/[category]/[name]/SKILL.md`
2. **Edit global instructions** in `instructions/AGENTS.md`
3. **Add commands** in `commands/[name].md`
4. **Run `./install.sh`** if symlinks break

Changes take effect immediately for new agent sessions (no restart needed for most agents).

## Common Tasks

### Add a new skill
```bash
mkdir -p skills/personal/my-skill
# Create skills/personal/my-skill/SKILL.md
ln -s personal/my-skill skills/my-skill  # Top-level symlink for discovery
```

### Fix broken symlinks
```bash
./install.sh
```

### Check what an agent sees
```bash
ls -la ~/.claude/skills/        # What Claude Code sees
ls -la ~/.pi/agent/skills/      # What Pi sees
```

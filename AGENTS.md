# Agent Config Repository

Unified configuration hub for AI coding agents. One central location that all agents share via symlinks.

## What This Repo Is

This is **the source of truth** for agent configuration across Pi, Claude Code, Codex, Gemini, and other agents. Changes here propagate to all agents automatically via symlinks.

## Directory Structure

```
~/.agent-config/
├── skills/                  # Shared skills (symlinked to ~/.claude/skills, ~/.agents/skills, etc.)
│   ├── tools/               # Wraps external CLI/API/service (~76)
│   ├── review/              # Analyzes/reviews code or content (~21)
│   ├── workflows/           # Orchestrates multi-step dev processes (~54)
│   ├── meta/                # Agent behavior rules, patterns (~42)
│   └── domain/              # Technology-specific knowledge (~62)
│       ├── swift/           # Apple/Swift platform
│       ├── compound/        # Vendored compound plugin set
│       ├── ralph/           # Ralph orchestrator
│       ├── shaping/         # Shaping methodology (submodules)
│       └── ...              # agentica, design, gitnexus, math, notion, other
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
| `~/.pi/agent/AGENTS.md` | `~/.agent-config/instructions/AGENTS.md` |
| `~/.pi/agent/prompts` | `~/.agent-config/commands` |
| `~/.agents/skills` | `~/.agent-config/skills` |
| `~/.config/agent-skills` | `~/.agent-config/skills` |
| `~/.config/opencode/commands` | `~/.agent-config/commands` |
| `~/.codex/prompts` | `~/.agent-config/commands` |
| `~/.codex/AGENTS.md` | `~/.agent-config/instructions/AGENTS.md` |
| `~/.gemini/GEMINI.md` | `~/.agent-config/instructions/AGENTS.md` |

## Skills System

**Both Pi and Claude Code have native skill systems.** Skills are discovered from `~/.claude/skills/` and `~/.agents/skills/` (both symlinked to `~/.agent-config/skills/`).

### Skill Format

```
skills/<category>/my-skill/
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

Functional taxonomy with a sequential decision rule for placement:
1. Wraps external CLI/API/service? -> `tools/`
2. Analyzes/reviews code or content? -> `review/`
3. Orchestrates multi-step dev process? -> `workflows/`
4. Specific to a named technology domain? -> `domain/<sub>/`
5. Agent behavior rule or pattern? -> `meta/`

Top-level symlinks (e.g., `skills/bird -> tools/bird`) enable discovery.

## Workflow Commands

The core workflow for tracked, spec-driven work. Each command suggests the next step with the specific command and spec path. All commands are individually usable — no mandatory pipeline.

```
/ground → /shape (2 agents) → /issue → /plan (2 agents) → /codex-review (2 agents) → /implement (2 agents)
 orient     discover            define     plan               gate                       build
```

| Command | What it does | Produces | Suggests next |
|---------|-------------|----------|---------------|
| `/ground` | Orient: read instructions, investigate codebase | — | `/shape`, `/issue`, `/sweep`, `/audit-agents` |
| `/shape <problem>` | Explore problem + solution space (2 agents, forced skill read) | `shaping-transcript.md` | `/issue` |
| `/issue <description>` | Create bead + `spec.md` in `specs/NNN-slug/` | `spec.md` with bead | `/plan <spec>` or `/shape` |
| `/plan <spec>` | Build plan + tasks (2 agents, forced skill read) | `plan.md`, `tasks.md`, `planning-transcript.md` | `/codex-review <spec>` or `/implement <spec>` |
| `/codex-review <spec>` | Codex reviews plan iteratively (2 agents) | `codex-review.md` | `/implement <spec>` |
| `/implement <spec>` | Execute plan with quality gates (2 agents, forced skill read) | git commits + PR | — |
| `/sweep` | Random code exploration → bug hunting → spec | `specs/NNN-slug/` with bead | `/codex-review <spec>` → `/implement <spec>` |
| `/audit-agents` | Skeptical review of agent code, fix in-place | direct fixes | `/issue` if spec warranted, or commit |

**Two-agent gates:** `/shape`, `/plan`, `/codex-review`, and `/implement` require two participants. One agent working alone is not sufficient — the second perspective is what forces skill protocols to be followed.

**Pre-checks:** `/plan` refuses without `spec.md` + bead. `/implement` refuses without `spec.md` + `plan.md` + `tasks.md` + bead. Commands tell you exactly what's missing and which command to run.

**Audit log:** Every workflow command appends to `log.md` in the spec directory with timestamp, mesh identity, harness/model, command, and event.

## Commands (General)

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
mkdir -p skills/tools/my-skill           # Choose the right category
# Create skills/tools/my-skill/SKILL.md
# Skills in category dirs are discovered automatically — no symlink needed
```

### Fix broken symlinks
```bash
./install.sh
```

### Check what an agent sees
```bash
ls -la ~/.claude/skills/        # What Claude Code sees
ls -la ~/.agents/skills/        # What Pi / Codex / Gemini see
```

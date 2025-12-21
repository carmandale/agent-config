# Agent Config

Unified configuration for AI coding agents. One central location for slash commands and instructions that all agents share via symlinks.

## Supported Agents

| Agent | Commands | Instructions |
|-------|----------|--------------|
| **Pi** (pi-coding-agent) | `~/.pi/agent/commands/` | `~/.pi/agent/AGENTS.md` |
| **Claude Code** | `~/.claude/commands/` | `~/.claude/CLAUDE.md` |
| **Codex** (OpenAI) | `~/.codex/prompts/` | `~/.codex/instructions.md` |
| **OpenCode** | `~/.config/opencode/commands/` | Project-level only |

## Installation

```bash
git clone https://github.com/carmandale/agent-config.git ~/.agent-config
cd ~/.agent-config
./install.sh
```

## Structure

```
~/.agent-config/
├── commands/                 # Shared slash commands (27+)
│   ├── handoff.md           # End-of-session handoff
│   ├── checkpoint.md        # Mid-session context compression
│   ├── commit.md            # Smart commit workflow
│   ├── debug.md             # Structured debugging
│   ├── sweep.md             # Code cleanup pass
│   ├── triage.md            # Issue triage
│   └── ...
├── instructions/
│   └── AGENTS.md            # Unified global instructions
├── install.sh               # Creates symlinks
└── README.md
```

## How It Works

The `install.sh` script creates symlinks from each agent's config location to this central repository:

```
~/.pi/agent/commands     → ~/.agent-config/commands
~/.claude/commands       → ~/.agent-config/commands
~/.codex/prompts         → ~/.agent-config/commands
~/.config/opencode/commands → ~/.agent-config/commands

~/.pi/agent/AGENTS.md    → ~/.agent-config/instructions/AGENTS.md
~/.claude/CLAUDE.md      → ~/.agent-config/instructions/AGENTS.md
~/.codex/instructions.md → ~/.agent-config/instructions/AGENTS.md
```

## Dual Instructions Support

All agents support **both** user-level and project-level instructions:

| Level | Pi | Claude Code | Purpose |
|-------|-----|-------------|---------|
| **User (Global)** | `~/.pi/agent/AGENTS.md` | `~/.claude/CLAUDE.md` | Your universal standards |
| **Project (Repo)** | `./AGENTS.md` | `./CLAUDE.md` | Project-specific rules |

**Load order:** Global → Parent directories → Current directory

This means you can have:
- **Global AGENTS.md**: Core standards, never-do rules, preferred workflows
- **Repo AGENTS.md**: Project architecture, specific conventions, tooling

## Key Commands

### Session Management
| Command | Description |
|---------|-------------|
| `/handoff` | End-of-session summary, sync beads/git, generate continuation prompt |
| `/checkpoint` | Mid-session context compression, preserve decisions |
| `/standup` | Quick status update |
| `/retro` | Session retrospective |

### Development Workflows
| Command | Description |
|---------|-------------|
| `/commit` | Smart commit with conventional format |
| `/debug` | Structured debugging workflow |
| `/sweep` | Code cleanup pass |
| `/fix-all` | Fix all lint/type errors |
| `/iterate` | Iterative refinement loop |

### Planning & Triage
| Command | Description |
|---------|-------------|
| `/triage` | Issue triage and prioritization |
| `/estimate` | Time estimation for tasks |
| `/repo-dive` | Deep dive into unfamiliar repo |

### Team & Parallel Work
| Command | Description |
|---------|-------------|
| `/parallel` | Spawn parallel workstreams |
| `/swarm` | Coordinate multiple agents |
| `/swarm-status` | Check swarm progress |
| `/swarm-collect` | Gather swarm results |

## Customization

### Adding Commands

Create a new `.md` file in `~/.agent-config/commands/`:

```markdown
---
description: Your command description (shown in autocomplete)
---

Your prompt instructions here...

Use $1, $2, etc. for positional arguments.
Use $@ for all arguments joined.
```

### Modifying Global Instructions

Edit `~/.agent-config/instructions/AGENTS.md` - changes apply to all agents immediately.

### Project-Specific Instructions

Create `AGENTS.md` (or `CLAUDE.md`) in your project root:

```markdown
# Project Instructions

## Architecture
- This is a visionOS app using SwiftUI and RealityKit
- Follow MVVM pattern

## Conventions
- Use `gj` tool for all builds (never raw xcodebuild)
- Run `gj test P0` before committing

## Never Do
- Don't add UIKit patterns to visionOS code
- Don't modify the Shared Types package without approval
```

## Updating

```bash
cd ~/.agent-config
git pull
./install.sh  # Re-run if symlinks are broken
```

## Troubleshooting

### Commands not showing up
```bash
# Verify symlinks exist and point correctly
ls -la ~/.pi/agent/commands
ls -la ~/.claude/commands
ls -la ~/.codex/prompts
```

### Broken symlinks after moving directories
```bash
cd ~/.agent-config
./install.sh
```

### Agent not reading instructions
- **Pi**: Restart the agent session
- **Claude Code**: Instructions load per-session
- **Codex**: Restart codex

## License

MIT

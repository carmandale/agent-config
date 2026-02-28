# Agent Config

Unified configuration for AI coding agents. One central location for slash commands and instructions that all agents share via symlinks.

## Supported Agents

| Agent | Commands | Instructions |
|-------|----------|--------------|
| **Pi** (pi-coding-agent) | `~/.pi/agent/commands/` | `~/.pi/agent/AGENTS.md` |
| **Claude Code** | `~/.claude/commands/` | `~/.claude/CLAUDE.md` |
| **Codex** (OpenAI) | `~/.codex/prompts/` | `~/.codex/AGENTS.md` |
| **Droid** (Factory) | `~/.factory/commands/` | `~/.factory/droids/` |
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
├── tools-bin/
│   └── agent-config-parity  # Cross-machine parity + version sync utility
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
~/.codex/AGENTS.md       → ~/.agent-config/instructions/AGENTS.md

~/.claude/skills         → ~/.agent-config/skills
~/.codex/skills          → ~/.agent-config/skills
~/.config/agent-skills   → ~/.agent-config/skills
~/.pi/agent/skills       → ~/.agent-config/skills
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

## Session Workflow

The core workflow for tracked, traceable work sessions:

```
/focus <bead-id>           # Start: load context, mark in-progress
    ↓
  ... do work ...
    ↓
/checkpoint                # Optional: mid-session save
    ↓
  ... more work ...
    ↓
/handoff                   # End: summarize, commit, requires bead
```

### Key Rules

- **`/handoff` requires a bead** - hard stop if no active bead (traceability)
- **`/handoff` writes** `.handoff/YYYY-MM-DD-HHMM-{bead-id}.md` - tracked & committed
- **`/checkpoint` writes** `.checkpoint/YYYY-MM-DD-HHMM.md` - tracked & committed
- **`/focus` marks bead in-progress** and loads relevant context

## Key Commands

### Session Management
| Command | Description |
|---------|-------------|
| `/focus <bead>` | **Start** session - load context, mark bead in-progress |
| `/handoff` | **End** session - requires bead, writes `.handoff/`, commits |
| `/checkpoint` | Mid-session save - writes `.checkpoint/`, commits |
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

## Parity and Version Sync (Laptop <-> Mac Mini)

Use `tools-bin/agent-config-parity` to make parity explicit and reproducible.

### Step 1: Align repo version on both machines

```bash
cd ~/.agent-config
git fetch origin
git checkout main
git pull --ff-only
git rev-parse HEAD
```

The `git rev-parse HEAD` value must match on laptop and Mac mini.

### Step 2: Run installers from the same checkout

```bash
cd ~/.agent-config
./install.sh
./install-all.sh
```

### Step 3: Capture snapshots

Laptop:
```bash
~/.agent-config/tools-bin/agent-config-parity snapshot --output /tmp/laptop.snapshot
```

Mac mini:
```bash
~/.agent-config/tools-bin/agent-config-parity snapshot --output /tmp/mini.snapshot
```

### Step 4: Compare snapshots

```bash
~/.agent-config/tools-bin/agent-config-parity compare /tmp/laptop.snapshot /tmp/mini.snapshot
```

No diff means parity for tracked repo/symlink/tool keys.

### Step 5: Human-readable audit

```bash
~/.agent-config/tools-bin/agent-config-parity report
```

Focus on:
- `repo.sha`
- `managed.*.status` and `managed.*.actual`
- `tool.*.version`

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
- **Droid**: Custom droids load from `~/.factory/droids/`

## What Is Outside `.agent-config`

These are not fully contained in this repo and can still break parity:

- Agent-local settings files (`~/.claude/settings.json`, `~/.codex/config.*`, `~/.pi/agent/config.json`, `~/.config/opencode/config.*`)
- Compound/plugin-generated directories in agent homes (for example under `~/.pi/agent/compound-engineering`, `~/.config/opencode/compound-engineering`, `~/.factory/`)
- Toolchain versions (`git`, `bash`, `bun/bunx`, `node`, `bd`, `rg`)
- Auth state and credentials (environment variables, keychain entries, logged-in sessions)

Run `~/.agent-config/tools-bin/agent-config-parity report` to see these surfaces explicitly.

## License

MIT

## Skills (Unified)

Skills are now unified across all agents, organized into categories:

```
~/.agent-config/skills/
├── cc3/            # Continuous-Claude-v3 framework skills (106)
├── tools/          # CLI/tool integrations (28): cass, bv, gj-tool, oracle, etc.
├── swift/          # SwiftUI/iOS development (4)
└── personal/       # User additions (20): checkpoint, finalize, etc.
```

### Symlinks

All agents point to the same unified location:

```
~/.claude/skills        → ~/.agent-config/skills
~/.codex/skills         → ~/.agent-config/skills
~/.factory/droids       → ~/.agent-config/skills (custom droids)
~/.config/agent-skills  → ~/.agent-config/skills
~/.pi/agent/skills      → ~/.agent-config/skills
```

### Adding Skills

Add new skills to the appropriate category:

```bash
# For tool integrations
mkdir ~/.agent-config/skills/tools/my-tool
# Create SKILL.md with description and instructions

# For personal skills
mkdir ~/.agent-config/skills/personal/my-skill
```

### Skill Format

Each skill needs a `SKILL.md` file:

```markdown
---
name: my-skill
description: Brief description of what the skill does
---

# Skill Name

Detailed instructions for the skill...
```

## Full Install (All Agents)

For a complete setup that includes both symlinks AND compound-engineering plugin:

```bash
cd ~/.agent-config
./install-all.sh
```

This runs:
1. `install.sh` - Creates symlinks for commands, instructions, skills
2. `bunx @every-env/compound-plugin install compound-engineering --to opencode --also droid`

### What Each System Provides

| Component | agent-config (symlinks) | compound-plugin (converter) |
|-----------|------------------------|----------------------------|
| Commands | ✓ Shared via symlink | — |
| Instructions | ✓ AGENTS.md symlinked | — |
| Skills | ✓ Shared via symlink | — |
| Agent definitions | — | ✓ Per-format agents |
| MCP config | — | ✓ mcporter.json, etc. |

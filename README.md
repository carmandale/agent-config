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

### Full machine setup (new machine)

```bash
git clone https://github.com/carmandale/agent-config.git ~/.agent-config
cd ~/.agent-config
./scripts/setup.sh
```

`setup.sh` orchestrates everything: Homebrew packages, shell config baselines, secrets directory, symlinks, Claude hooks build, and agent config bootstrap. Safe to run multiple times.

### Quick update (existing machine)

```bash
cd ~/.agent-config
git pull
./install.sh                    # Symlinks only
./scripts/bootstrap.sh apply    # Agent configs only
./scripts/bootstrap.sh check    # Verify everything
```

### What setup.sh does

1. **Homebrew** — installs packages from `Brewfile` (required + recommended)
2. **Shell config** — applies `~/.zshenv` (PATH, secrets) and `~/.zshrc` (interactive baseline), creates `~/.secrets/` for API keys
3. **Symlinks** — runs `install.sh` (commands, instructions, skills to all agents)
4. **Claude hooks** — builds TypeScript hooks if source exists (settings.json depends on 28 hook files)
5. **Agent configs** — runs `bootstrap.sh apply` (codex, claude, pi baselines)
6. **Verification** — runs `bootstrap.sh check` to confirm everything resolves

### Known gap: hooks not yet tracked

Claude hooks source (`~/.claude/hooks/`) is not yet in this repo. On a fresh machine, `setup.sh` warns and tells you to rsync from an existing machine. This breaks the "one clone, one setup" promise. Tracked in bead `.agent-config-6on` / spec `004-hooks-in-repo`.

## Structure

```
~/.agent-config/
├── commands/                 # Shared slash commands (27+)
├── configs/
│   ├── claude/               # Claude Code settings.json baseline
│   ├── codex/                # Codex config.toml, config.json, rules, policy
│   ├── pi/                   # Pi agents, mcporter, extensions
│   └── shell/                # zshenv, zshrc, secrets-template.env
├── instructions/
│   └── AGENTS.md             # Unified global instructions
├── scripts/
│   ├── setup.sh              # Full machine setup orchestrator
│   └── bootstrap.sh          # Agent config check/apply/status
├── skills/                   # Unified skills (253+)
├── specs/                    # Planning artifacts (shaping, plans)
├── tools-bin/                # CLI utilities
├── Brewfile                  # Homebrew packages (required + recommended)
├── install.sh                # Creates symlinks
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

If there is diff output, classify each key before making changes:
- `managed.*` drift is usually actionable and should be fixed.
- `external.*` drift is often machine-local and should be reviewed, not blindly copied.
- `system.*` drift is expected when macOS versions differ between machines.

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

Managed by bootstrap (baselines tracked in `configs/`):
- `~/.claude/settings.json`, `~/.codex/config.*`, `~/.pi/agent/agents/`, extensions, mcporter
- `~/.zshenv`, `~/.zshrc` (shell baselines)

**Not yet tracked** (breaks "one clone" promise):
- `~/.claude/hooks/` — TypeScript hooks that settings.json depends on (spec `004-hooks-in-repo`)

Machine-specific (intentionally not tracked):
- `~/.zshrc.local` — per-machine aliases, conda, pnpm, app paths
- `~/.secrets/agent-keys.env` — API keys (template tracked, values not)
- Agent CLI installations (claude, codex, pi, openclaw)
- Toolchain versions (`git`, `node`, `bun`, `bd`, `rg`)
- Auth state and credentials (keychain entries, logged-in sessions)

Run `~/.agent-config/tools-bin/agent-config-parity report` to see these surfaces explicitly.

## License

MIT

## Skills (Unified)

Skills are unified across all agents, organized by function:

```
~/.agent-config/skills/
├── tools/          # Wraps external CLI/API/service (76)
├── review/         # Analyzes/reviews code or content (21)
├── workflows/      # Orchestrates multi-step dev processes (54)
├── meta/           # Agent behavior rules, patterns (42)
├── domain/         # Technology-specific knowledge (60)
│   ├── swift/      # Apple/Swift platform
│   ├── compound/   # Vendored compound plugin set
│   ├── ralph/      # Ralph orchestrator
│   ├── shaping/    # Shaping methodology (submodules)
│   └── ...         # agentica, gitnexus, math, notion, other
└── <name> -> <category>/<name>  # Discovery symlinks
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

Add new skills to the appropriate category using the decision rule:
1. Wraps external CLI/API/service? -> `tools/`
2. Analyzes/reviews code or content? -> `review/`
3. Orchestrates multi-step dev process? -> `workflows/`
4. Specific to a named technology domain? -> `domain/<sub>/`
5. Agent behavior rule or pattern? -> `meta/`

```bash
mkdir ~/.agent-config/skills/tools/my-tool
# Create SKILL.md with description and instructions
ln -s tools/my-tool skills/my-tool  # Discovery symlink
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

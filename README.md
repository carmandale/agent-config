# Agent Config

Unified configuration for AI coding agents. One central location for slash commands and instructions that all agents share via symlinks.

## Supported Agents

| Agent | Commands | Instructions |
|-------|----------|--------------|
| **Pi** (pi-coding-agent) | `~/.pi/agent/prompts/` | `~/.pi/agent/AGENTS.md` |
| **Claude Code** | `~/.claude/commands/` | `~/.claude/CLAUDE.md` |
| **Codex** (OpenAI) | `~/.codex/prompts/` | `~/.codex/AGENTS.md` |
| **Gemini** (Google) | TOML format (manual) | `~/.gemini/GEMINI.md` |
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
4. **Claude hooks** — deploys hook source from `configs/claude/hooks/`, installs deps, builds TypeScript → `.mjs` (settings.json depends on ~28 hook files)
5. **Agent configs** — runs `bootstrap.sh apply` (codex, claude, pi baselines)
6. **Verification** — runs `bootstrap.sh check` to confirm everything resolves

## Structure

```
~/.agent-config/
├── commands/                 # Shared slash commands (46+)
├── configs/
│   ├── claude/               # Claude Code settings.json + hooks source
│   ├── codex/                # Codex config.toml, config.json, rules, policy
│   ├── pi/                   # Pi agents, mcporter, extensions
│   └── shell/                # zshenv, zshrc, secrets-template.env
├── docs/                     # Additional documentation (gj-tool, cupertino, etc.)
├── instructions/
│   └── AGENTS.md             # Unified global instructions
├── scripts/
│   ├── setup.sh              # Full machine setup orchestrator
│   ├── bootstrap.sh          # Agent config check/apply/status
│   ├── vendor-sync.sh        # Sync vendored skill repos
│   └── verify-hooks.sh       # Verify hook file integrity
├── skills/                   # Unified skills (300+)
├── specs/                    # Planning artifacts (shaping, plans)
├── tests/                    # Test scripts
├── thoughts/                 # Shared thoughts and handoffs
├── tools-bin/                # CLI utilities (agent-config-parity)
├── Brewfile                  # Homebrew packages (required + recommended)
├── install.sh                # Creates symlinks
├── install-all.sh            # Full install: symlinks + compound-engineering
└── README.md
```

## How It Works

The `install.sh` script creates symlinks from each agent's config location to this central repository:

```
~/.pi/agent/prompts      → ~/.agent-config/commands
~/.claude/commands       → ~/.agent-config/commands
~/.codex/prompts         → ~/.agent-config/commands
~/.config/opencode/commands → ~/.agent-config/commands

~/.pi/agent/AGENTS.md    → ~/.agent-config/instructions/AGENTS.md
~/.claude/CLAUDE.md      → ~/.agent-config/instructions/AGENTS.md
~/.codex/AGENTS.md       → ~/.agent-config/instructions/AGENTS.md
~/.gemini/GEMINI.md      → ~/.agent-config/instructions/AGENTS.md

~/.claude/skills         → ~/.agent-config/skills
~/.agents/skills         → ~/.agent-config/skills  (Codex + Gemini)
~/.config/agent-skills   → ~/.agent-config/skills
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

## Workflow Commands

The core workflow for tracked, spec-driven work. Each command suggests the next step. All commands are individually usable — no mandatory pipeline.

```
/ground                        # Orient: read instructions, investigate codebase
    ↓
/shape <problem>               # Discover: explore problem + solution space (2 agents)
    ↓                            produces: shaping-transcript.md
/issue <description>           # Define: create bead + spec.md
    ↓                            produces: specs/NNN-slug/spec.md
/plan <spec>                   # Plan: build plan.md + tasks.md (2 agents)
    ↓                            produces: plan.md, tasks.md, planning-transcript.md
/codex-review <spec>           # Gate: Codex reviews plan iteratively (2 agents)
    ↓                            produces: codex-review.md
/implement <spec>              # Build: execute plan with quality gates (2 agents)
                                 produces: git commits + PR
```

**Entry points vary.** Clear problem → `/issue` first. Vague idea → `/shape` first. Bug hunting → `/sweep`. Code review → `/audit-agents`. The workflow adapts to how you start.

### Two-Agent Gates

Four commands require two participants (user + agent, or two agents). This is the enforcement mechanism — a second perspective prevents corner-cutting:

| Command | Skill forced | Two-agent dynamic |
|---------|-------------|-------------------|
| `/shape` | shaping SKILL.md | Explore problem ↔ challenge assumptions |
| `/plan` | workflows-plan SKILL.md | Research & propose ↔ stress-test |
| `/codex-review` | (self-contained) | Claude orchestrates ↔ Codex reviews |
| `/implement` | workflows-work SKILL.md | Implement ↔ validate each step |

### Spec Directory

Every piece of tracked work lives in `specs/NNN-slug/`:

```
specs/003-gj-unit-swift-testing/
├── spec.md                    # What and why (bead in frontmatter)
├── plan.md                    # How (architecture decisions, insertion points)
├── tasks.md                   # Do this (ordered checkable list)
├── shaping-transcript.md      # Proof: two-agent shaping happened
├── planning-transcript.md     # Proof: two-agent planning happened
├── codex-review.md            # Proof: Codex actually reviewed
└── log.md                     # Audit trail: who ran what, when, with what model
```

File existence is the dashboard. `ls specs/*/log.md` across projects shows what's happening.

### Audit Log

Every workflow command appends to `log.md` in the spec directory:

```
YYYY-MM-DD HH:MM | ZenPhoenix | pi/claude-opus-4-6     | /shape        | started with RedEagle
YYYY-MM-DD HH:MM | ZenPhoenix | pi/claude-opus-4-6     | /issue        | bead .gj-tool-xyz — spec.md
YYYY-MM-DD HH:MM | —          | codex/gpt-5.3-codex    | /codex-review | round 3 — VERDICT: APPROVED
```

Mesh name (pi_messenger identity) if available, `—` if not. Harness/model always mandatory.

### Pre-checks

Commands enforce prerequisites:
- `/plan` refuses without `spec.md` + bead frontmatter → tells you to run `/issue`
- `/implement` refuses without `spec.md` + `plan.md` + `tasks.md` + bead → tells you what's missing

### Discovery & Bug Hunting

| Command | Description | Suggests next |
|---------|-------------|---------------|
| `/ground` | Orient: read instructions, investigate codebase | `/shape`, `/issue`, `/sweep`, or `/audit-agents` |
| `/sweep` | Random code exploration → bug hunting → spec creation | `/codex-review <spec>` then `/implement <spec>` |
| `/audit-agents` | Skeptical review of agent-written code, fix in-place | `/issue` if spec warranted, or commit |

## Session Management

| Command | Description |
|---------|-------------|
| `/focus <bead>` | **Start** session - load context, mark bead in-progress |
| `/handoff` | **End** session - requires bead, writes `.handoff/`, commits |
| `/checkpoint` | Mid-session save - writes `.checkpoint/`, commits |
| `/standup` | Quick status update |
| `/retro` | Session retrospective |

## Other Commands

| Command | Description |
|---------|-------------|
| `/commit` | Smart commit with conventional format |
| `/debug` | Structured debugging workflow |
| `/fix-all` | Fix all lint/type errors |
| `/iterate` | Iterative refinement loop |
| `/triage` | Issue triage and prioritization |
| `/repo-dive` | Deep dive into unfamiliar repo |
| `/parallel` | Spawn parallel workstreams |
| `/swarm` | Coordinate multiple agents |

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
ls -la ~/.pi/agent/prompts
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
- **Gemini**: Restart gemini
- **Droid**: Custom droids load from `~/.factory/droids/`

## What Is Outside `.agent-config`

Managed by bootstrap (baselines tracked in `configs/`):
- `~/.claude/settings.json`, `~/.claude/hooks/` (TypeScript source + build), `~/.codex/config.*`, `~/.pi/agent/agents/`, extensions, mcporter
- `~/.zshenv`, `~/.zshrc` (shell baselines)

Machine-specific (intentionally not tracked):
- `~/.zshrc.local` — per-machine aliases, conda, pnpm, app paths
- `~/.secrets/agent-keys.env` — API keys (template tracked, values not)
- Agent CLI installations (claude, codex, gemini, pi, openclaw)
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
├── domain/         # Technology-specific knowledge (62)
│   ├── swift/      # Apple/Swift platform
│   ├── compound/   # Vendored compound plugin set
│   ├── ralph/      # Ralph orchestrator
│   ├── shaping/    # Shaping methodology (submodules)
│   └── ...         # agentica, design, gitnexus, math, notion, other
```

### Symlinks

All agents point to the same unified location:

```
~/.claude/skills        → ~/.agent-config/skills
~/.agents/skills        → ~/.agent-config/skills  (Codex + Gemini)
~/.config/agent-skills  → ~/.agent-config/skills
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
# Skills in category dirs are discovered automatically — no symlink needed
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

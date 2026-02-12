---
name: codex-orchestrator
description: Spawn and manage OpenAI Codex agents via tmux for parallel research, implementation, review, and testing. Use when delegating coding tasks to background agents.
triggers:
  - spawn codex
  - delegate to codex
  - use codex agent
  - parallel agents
  - codex orchestrator
  - start codex
---

# Codex Orchestrator

Delegate tasks to GPT Codex agents running in tmux sessions. Agents work in the background while you continue strategic work.

## Prerequisites

```bash
codex-agent health   # Verify tmux + codex installed
```

If not installed, run:
```bash
~/.agent-config/tools-bin/codex-orchestrator/plugins/codex-orchestrator/scripts/install.sh
```

## Quick Reference

### Spawn Agents

```bash
# Research (read-only)
codex-agent start "Investigate auth flow for vulnerabilities" --map -s read-only

# Implementation (default: workspace-write, xhigh reasoning)
codex-agent start "Implement the auth refactor per PRD" --map

# With file context
codex-agent start "Review these files" --map -f "src/auth/**/*.ts"

# Dry run (preview prompt without executing)
codex-agent start "task" --map --dry-run
```

### Monitor

```bash
codex-agent jobs --json          # Structured status (tokens, files, summary)
codex-agent jobs                 # Human-readable table
codex-agent capture <id> 100     # Last 100 lines of output
codex-agent output <id>          # Full session output
codex-agent watch <id>           # Live stream
codex-agent status <id>          # Detailed job info
```

### Communicate

```bash
codex-agent send <id> "Focus on the database layer"
codex-agent send <id> "The dependency is installed. Continue."
tmux attach -t codex-agent-<id>  # Direct interaction (Ctrl+B, D to detach)
```

### Control

```bash
codex-agent kill <id>            # Stop agent (last resort)
codex-agent clean                # Remove jobs >7 days old
codex-agent delete <id>          # Delete specific job
```

## Defaults

| Setting | Default | Override |
|---------|---------|----------|
| Model | gpt-5.3-codex | `-m <model>` |
| Reasoning | xhigh | `-r low/medium/high/xhigh` |
| Sandbox | workspace-write | `-s read-only` or `-s danger-full-access` |

## Flags Reference

| Flag | Short | Values | Description |
|------|-------|--------|-------------|
| `--reasoning` | `-r` | low, medium, high, xhigh | Reasoning depth |
| `--sandbox` | `-s` | read-only, workspace-write, danger-full-access | File access |
| `--file` | `-f` | glob | Include files (repeatable) |
| `--map` | | flag | Include docs/CODEBASE_MAP.md |
| `--dir` | `-d` | path | Working directory |
| `--model` | `-m` | string | Model override |
| `--json` | | flag | JSON output (jobs only) |
| `--strip-ansi` | | flag | Clean terminal codes from output |
| `--dry-run` | | flag | Preview prompt without executing |

## When to Use

- **Parallel research** — spawn 3+ read-only agents investigating different areas
- **Long-running implementation** — agents run 20-60+ minutes, that's normal
- **Security/code review** — dedicated review agents with `-s read-only`
- **Test writing** — spawn agent to write tests while you continue planning
- **Any coding task** — Codex agents are the default for execution work

## Codebase Map

Always use `--map` to give agents architectural context. Requires `docs/CODEBASE_MAP.md`:

```bash
# Generate with Cartographer or manually create
codex-agent start "task" --map
```

Without a map, agents waste time exploring. With a map, they execute immediately.

## Agent Timing (CRITICAL)

| Task Type | Typical Duration |
|-----------|------------------|
| Simple research | 10-20 minutes |
| Single feature | 20-40 minutes |
| Complex implementation | 30-60+ minutes |

**This is normal.** Agents read thoroughly, think deeply, implement carefully, and verify their work. Don't kill them for "taking too long."

**Do NOT:**
- Kill agents after 20 minutes
- Assume something is wrong at 30+ minutes
- Spawn replacements for "slow" agents

**DO:**
- Check progress with `codex-agent capture <id>`
- Send clarifying messages if genuinely stuck
- Let agents finish — quality takes time

## Jobs JSON Output

```json
{
  "id": "8abfab85",
  "status": "completed",
  "elapsed_ms": 14897,
  "tokens": {
    "input": 36581,
    "output": 282,
    "context_window": 258400,
    "context_used_pct": 14.16
  },
  "files_modified": ["src/auth.ts", "src/types.ts"],
  "summary": "Implemented the authentication flow..."
}
```

## Multi-Agent Patterns

### Parallel Investigation

```bash
# Spawn 3 research agents simultaneously
codex-agent start "Audit auth flow" --map -s read-only
codex-agent start "Review API security" --map -s read-only  
codex-agent start "Check data validation" --map -s read-only

# Monitor all
codex-agent jobs --json
```

### Sequential Implementation

```bash
# Phase 1
codex-agent start "Implement Phase 1 of PRD" --map
# Wait, review with: codex-agent jobs --json

# Phase 2 (after Phase 1 verified)
codex-agent start "Implement Phase 2 of PRD" --map
```

### Redirection (Don't Kill and Respawn)

```bash
# Agent going wrong direction? Redirect it
codex-agent send abc123 "Stop - focus on the auth module instead"

# Agent needs info?
codex-agent send abc123 "The dependency is installed. Run typecheck."

# For full interaction
tmux attach -t codex-agent-abc123
# (Ctrl+B, D to detach)
```

## Storage

Jobs stored at `~/.codex-agent/jobs/`:
- `<id>.json` — Job metadata
- `<id>.prompt` — Original prompt
- `<id>.log` — Terminal output

## Troubleshooting

```bash
# Health check
codex-agent health

# Agent stuck?
codex-agent capture <id> 100   # See what's happening
codex-agent send <id> "Status update - what's blocking you?"

# Session ended unexpectedly?
codex-agent output <id>        # Check full log for errors
```

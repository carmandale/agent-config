---
name: perplexity-search
description: AI-powered web search, research, and reasoning via Perplexity
allowed-tools: [Bash, Read]
---

# Perplexity AI Search

Web search with AI-powered answers, deep research, and chain-of-thought reasoning.

## When to Use

- Direct web search for AI-synthesized answers
- Research with citations from multiple sources
- Chain-of-thought reasoning for complex decisions
- Deep comprehensive research on topics

## Prerequisites

```bash
# Check if pplx CLI is available
which pplx || echo "Install: see Setup below"

# API key required
export PERPLEXITY_API_KEY=your-key
# Or add to ~/.env, ~/.claude/.env, or ~/.config/perplexity/.env
```

## Setup (one-time)

The `pplx` CLI should be at `~/.local/bin/pplx`. If missing:
1. Ensure `httpx` is installed: `pip install httpx`
2. Create the CLI from skill docs or ask for it to be set up

## Models (2025)

| Model | Mode | Purpose |
|-------|------|---------|
| `sonar` | `--ask`, `--search` | Lightweight search with grounding |
| `sonar-pro` | `--research` | Advanced search for complex queries |
| `sonar-reasoning-pro` | `--reason` | Chain of thought reasoning |
| `sonar-deep-research` | `--deep` | Expert-level exhaustive research |

## Usage

### Quick question (AI answer)
```bash
pplx --ask "What is the latest version of Python?"
```

### Web search with AI synthesis
```bash
pplx --search "SQLite graph database patterns" --recency week
```

### AI-synthesized research
```bash
pplx --research "compare FastAPI vs Django for microservices"
```

### Chain-of-thought reasoning
```bash
pplx --reason "should I use Neo4j or SQLite for small graph under 10k nodes?"
```

### Deep comprehensive research
```bash
pplx --deep "state of AI agent observability 2025"
```

## Parameters

| Flag | Description |
|------|-------------|
| `--ask QUERY` | Quick question with AI answer (sonar) |
| `--search QUERY` | Web search with AI synthesis (sonar) |
| `--research QUERY` | AI-synthesized research (sonar-pro) |
| `--reason QUERY` | Chain-of-thought reasoning (sonar-reasoning-pro) |
| `--deep QUERY` | Deep comprehensive research (sonar-deep-research) |

### Search Options
| Flag | Description |
|------|-------------|
| `--recency {day,week,month,year}` | Filter by recency |
| `--domains DOMAIN [...]` | Limit to specific domains |
| `--max-tokens N` | Max response tokens (default: 4096) |

### Output Options
| Flag | Description |
|------|-------------|
| `--json` | Output raw JSON response |
| `--no-citations` | Hide source citations |

## Mode Selection Guide

| Need | Use | Why |
|------|-----|-----|
| Quick fact | `--ask` | Fast, lightweight |
| Find info with sources | `--search` | AI synthesizes with citations |
| Comprehensive answer | `--research` | AI combines multiple sources deeply |
| Complex decision | `--reason` | Chain-of-thought analysis |
| Expert-level report | `--deep` | Exhaustive multi-source research |

## Examples

```bash
# Recent info on a topic
pplx --search "OpenTelemetry AI agent tracing" --recency month

# Limit to specific domains
pplx --search "Swift concurrency best practices" --domains apple.com swift.org

# Get AI synthesis for comparison
pplx --research "best practices for AI agent logging 2025"

# Make a decision
pplx --reason "microservices vs monolith for startup MVP"

# Deep dive (takes longer)
pplx --deep "comprehensive guide to building feedback loops for autonomous agents"

# Get raw JSON for parsing
pplx --ask "current Python version" --json | jq '.choices[0].message.content'
```

## API Key Required

Requires `PERPLEXITY_API_KEY`. The CLI checks:
1. `PERPLEXITY_API_KEY` environment variable
2. `~/.env`
3. `~/.claude/.env`
4. `~/.config/perplexity/.env`

Get your API key at: https://www.perplexity.ai/settings/api

---
name: machine-parity
description: Compare runtime state between laptop and Mac mini (mini-ts). Use when asked "are my machines in sync?", after deploying changes to agent-config, after updating tools on one machine, or when debugging cross-machine behavior differences.
---

# Machine Parity Check

Quick cross-machine runtime state comparison between laptop and Mac mini.

## When to Use

- **"Are my machines in sync?"** — run `parity-check.sh`
- After pushing agent-config changes (verify the dual-push landed)
- After upgrading pi, claude, codex, openclaw, or node on one machine
- After `pi install` or `pi uninstall` on either machine
- When debugging behavior differences between machines

## How to Run

```bash
# Human-readable output (default)
~/.agent-config/scripts/parity-check.sh

# JSON output for agent consumption
~/.agent-config/scripts/parity-check.sh --json
```

## What It Checks

| Category | Checks |
|----------|--------|
| Agent infra | pi version, pi packages, agent-config HEAD/branch, pi-messenger version/branch/source, openclaw version |
| Core tools | node, claude, codex versions |
| Homebrew | All 20 Brewfile packages installed on both machines |

## Understanding the Output

| Verdict | Meaning | Action |
|---------|---------|--------|
| **PASS** | Both machines have the same value | None needed |
| **DRIFT** | Values differ between machines | Update the behind machine |
| **DRIFT (expected)** | Values differ but this is intentional (e.g., pi_packages) | Informational only |
| **MISSING (local/remote)** | Tool/package not installed on one side | Install on the missing side |

## Exit Codes

| Code | Meaning |
|------|---------|
| 0 | All PASS or DRIFT (expected) — machines are in sync |
| 1 | Unexpected DRIFT or MISSING detected |
| 2 | SSH connectivity failure or timeout |
| 3 | Missing dependency (jq for --json) |

## JSON Output for Agents

```bash
# Parse with jq
~/.agent-config/scripts/parity-check.sh --json | jq '.[] | select(.verdict != "PASS")'
```

Each entry has: `check`, `local`, `remote`, `verdict`.

## Common DRIFT Fixes

| Check | Fix |
|-------|-----|
| pi_version | `ssh mini-ts "pi upgrade"` or `npm update -g @mariozechner/pi-coding-agent` |
| claude_version | `ssh mini-ts "claude update"` |
| codex_version | `ssh mini-ts "npm update -g @openai/codex"` |
| openclaw_version | Rebuild and deploy openclaw on the behind machine |
| agent_config_head | Push should auto-sync via dual-push; if stuck, `ssh mini-ts "cd ~/.agent-config && git pull"` |
| brew:* MISSING | `ssh mini-ts "brew install <package>"` |

## Boundary with `agent-config-parity`

Two parity tools exist — each with a different scope:

| Tool | Scope | Use When |
|------|-------|----------|
| `parity-check.sh` (this) | Runtime state — tool versions, git state, Homebrew | "Are my machines running the same stuff?" |
| `agent-config-parity` | Config surface — symlinks, paths, managed surfaces | "Are my config files wired correctly?" |

## Known Limitations

- **`pi list` format dependency**: If pi changes its output format, the pi-messenger path extraction may break. The script falls back to MISSING (not crash).
- **openclaw pre-release suffixes**: Compared as raw strings. `2026.3.9` vs `2026.3.9-beta.1` correctly shows DRIFT.
- **pi_packages intentional drift**: Packages differ by design (laptop has more). Shown as DRIFT (expected), doesn't affect exit code.

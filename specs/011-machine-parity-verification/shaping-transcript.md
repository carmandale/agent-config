---
shaping: true
---

# 011: Machine Parity Verification — Shaping

**Participants:** Dale (user) + pi/claude-opus-4-6  
**Date:** 2026-03-09  
**Bead:** .agent-config-8i7

## Context

During a session setting up pi-messenger fork sync to the Mac mini, we ran ~10 separate
`ssh mini-ts "..."` commands to verify state (pi version, pi-messenger version, install method,
git remotes, branch state). There's no single command that answers "are my machines in sync?"

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Single command produces side-by-side laptop vs Mac mini state comparison | Core goal |
| R1 | Checks cover agent infra: pi version, pi packages/install source, agent-config HEAD+branch, pi-messenger version+branch+source, openclaw version, node version | Must-have |
| R2 | Checks cover core tools: claude version, codex version, key Homebrew packages (aligned between machines) | Must-have |
| R3 | Clear per-check verdict: PASS / DRIFT / MISSING | Must-have |
| R4 | Works from the laptop over SSH (`ssh mini-ts`) | Must-have |
| R5 | Output readable by humans AND parseable by agents | Must-have |
| R6 | Primary artifact is a bash script — deterministic, no agent interpretation required | Must-have |
| R7 | Extensible — adding a new check doesn't require rewriting the core | Nice-to-have |
| R8 | Fast — completes in <10 seconds | Nice-to-have |
| R9 | A skill wraps the script for agent discoverability | Nice-to-have |

### Requirement Evolution

- **R2** added after Dale noted claude, codex, and Homebrew alignment are important — these are core tools.
- **R6** firmed to Must-have: Dale's rationale — "a bash script doesn't rely on an agent to follow all the steps, it guarantees it."
- **R7** downgraded to Nice-to-have: for ~15 checks, a well-organized single script beats a plugin system.

## Shapes Explored

### A: Flat Sequential Script

| Part | Mechanism |
|------|-----------|
| **A1** | Single `parity-check.sh` in `~/.agent-config/scripts/` |
| **A2** | Each check is a bash function: `check_pi_version()`, etc. |
| **A3** | Each function runs local command, SSH command, compares, prints PASS/DRIFT/MISSING |
| **A4** | Summary line at end |
| **A5** | Adding a check = adding a new function + registering it |

### B: Parallel SSH with Structured Output

| Part | Mechanism |
|------|-----------|
| **B1** | Single `parity-check.sh` in `~/.agent-config/scripts/` |
| **B2** | Gathers all local values first into an associative array |
| **B3** | Single SSH call runs a heredoc script on the mini, outputs key=value pairs |
| **B4** | Local loop compares local vs remote values, prints PASS/DRIFT/MISSING |
| **B5** | Structured output: human table by default, `--json` flag for agent parsing |
| **B6** | Adding a check = adding to the local gather + remote heredoc + comparison list |

### C: Check-Registry Pattern

| Part | Mechanism |
|------|-----------|
| **C1** | Runner discovers `scripts/parity-checks.d/*.sh` |
| **C2** | Each check file exports name + local command + remote command + comparator |
| **C3** | Runner iterates, runs each, collects results |
| **C4** | `--json` for structured output |
| **C5** | Adding a check = dropping a new `.sh` file |

## Fit Check

| Req | Requirement | Status | A | B | C |
|-----|-------------|--------|---|---|---|
| R0 | Single command, side-by-side comparison | Core goal | ✅ | ✅ | ✅ |
| R1 | Agent infra checks | Must-have | ✅ | ✅ | ✅ |
| R2 | Core tool checks (claude, codex, Homebrew) | Must-have | ✅ | ✅ | ✅ |
| R3 | Per-check verdict: PASS / DRIFT / MISSING | Must-have | ✅ | ✅ | ✅ |
| R4 | Works from laptop over SSH | Must-have | ✅ | ✅ | ✅ |
| R5 | Output readable by humans AND parseable by agents | Must-have | ❌ | ✅ | ✅ |
| R6 | Primary artifact is a bash script — deterministic | Must-have | ✅ | ✅ | ✅ |
| R7 | Extensible — new checks don't require rewriting core | Nice-to-have | ❌ | ❌ | ✅ |
| R8 | Fast — <10 seconds | Nice-to-have | ❌ | ✅ | ❌ |
| R9 | Skill wraps script for agent discovery | Nice-to-have | ✅ | ✅ | ✅ |

**Notes:**
- A fails R5: no structured output mode — agents parse human text
- A fails R7: adding a check means editing inline (acceptable but not extensible)
- B fails R7: checks are inline, but single SSH batch is the right trade-off for ~15 checks
- A fails R8: sequential SSH calls — multiple round trips
- C fails R8: one SSH per check file unless runner batches (kills simplicity)

## Selected Shape: B — Parallel SSH with Structured Output

**Rationale:** Hits all must-haves. Batched SSH is the key insight — one round trip for all remote values, fast AND structured. `--json` flag for agent parsing. R7 (directory-based extensibility) is overkill for ~15 checks; a single well-organized script with clearly labeled sections is easier to maintain.

## Detail B: Concrete Mechanism

| Part | Mechanism |
|------|-----------|
| **B1** | `~/.agent-config/scripts/parity-check.sh` — entry point, `chmod +x`, runs from anywhere |
| **B2** | **Local gather**: runs local commands, stores in associative array (`declare -A LOCAL`) |
| **B3** | **Remote gather**: single `ssh mini-ts bash -s` with heredoc, outputs `key=value` lines, parsed into `declare -A REMOTE` |
| **B4** | **Compare loop**: iterates ordered key list, compares `LOCAL[key]` vs `REMOTE[key]`, assigns PASS/DRIFT/MISSING |
| **B5** | **Human output** (default): aligned table with color — green PASS, yellow DRIFT, red MISSING, both values shown on DRIFT |
| **B6** | **Agent output** (`--json`): JSON array of `{ check, local, remote, verdict }` objects |
| **B7** | **Summary line**: "12/15 PASS · 2 DRIFT · 1 MISSING" with exit code 0 (all pass) or 1 (any drift/missing) |
| **B8** | **Homebrew check**: `brew list --formula -1` on both sides, diff for installed-only-on-one-side |
| **B9** | Skill file at `~/.agent-config/skills/machine-parity/SKILL.md` wraps the script with context for agents |

### Check List

| Key | Local Command | Remote Command | Category |
|-----|--------------|----------------|----------|
| `pi_version` | `pi --version` | `pi --version` | Agent infra |
| `pi_packages` | `pi list` (parse) | `pi list` (parse) | Agent infra |
| `agent_config_head` | `git -C ~/.agent-config log --oneline -1` | same | Agent infra |
| `agent_config_branch` | `git -C ~/.agent-config branch --show-current` | same | Agent infra |
| `pi_messenger_version` | `grep version package.json` (from pi list path) | same | Agent infra |
| `pi_messenger_branch` | `git branch --show-current` (from pi list path) | same | Agent infra |
| `openclaw_version` | `openclaw --version` | same | Agent infra |
| `node_version` | `node --version` | same | Core tools |
| `claude_version` | `claude --version` | same | Core tools |
| `codex_version` | `codex --version` | same | Core tools |
| `brew_formulas` | `brew list --formula -1` | same | Homebrew |

---
title: "Evaluate beads backend: bd Dolt vs br (beads_rust) SQLite"
date: 2026-03-09
bead: .agent-config-17q
type: feature
status: done
---

# Evaluate beads backend: bd Dolt vs br (beads_rust) SQLite

## Context

`bd` (beads) v0.59.0 removed SQLite support entirely — Dolt is the only backend. Our setup runs on SQLite (`bd` v0.50.3, pinned after a premature upgrade). The Dolt migration path has known issues:

- **[#2433](https://github.com/steveyegge/beads/issues/2433)** (OPEN) — `bd init --from-jsonl` fails on fresh clones with "database not found" (v0.59.0, filed Mar 7)
- **[#2251](https://github.com/steveyegge/beads/issues/2251)** — Dolt migration in one clone causes data loss in other independent clones via committed `metadata.json`
- **[#1918](https://github.com/steveyegge/beads/issues/1918)** — Earlier versions shipped without CGO, making migration impossible
- Dolt requires `dolt sql-server` running as a daemon — additional operational complexity

Meanwhile, `br` ([beads_rust](https://github.com/Dicklesworthstone/beads_rust)) is a Rust port of classic beads, frozen at the SQLite+JSONL architecture:

- Same `.beads/` directory, same JSONL format (confirmed compatible)
- Zero external dependencies, no daemon
- 699 stars, actively maintained (24 releases, last updated today)
- ~20K lines of Rust vs ~276K lines of Go
- Never auto-commits, never touches git (aligns with our explicit-control preference)
- Steve Yegge endorsed
- Single maintainer (Jeffrey Emanuel), no outside PRs accepted
- No Linear/Jira sync (not needed for us)

## Problem Statement

We need a reliable, maintainable issue tracker backend that:
1. Works on both laptop and Mac mini (multi-clone safe)
2. Doesn't require external daemons or server processes
3. Keeps our 24 existing issues and JSONL history intact
4. Integrates with our AGENTS.md workflow (§6 Beads Workflow)
5. Is actively maintained and not heading toward a dead end

## Candidates

| Option | Tool | Backend | Status |
|--------|------|---------|--------|
| A | `bd` v0.50.3 (pinned) | SQLite | Current — works but upstream abandoned SQLite |
| B | `bd` v0.59.0+ | Dolt | Requires Dolt install + daemon, known migration bugs |
| C | `br` v0.1.24+ | SQLite | Drop-in compatible, actively maintained, Rust |

## Scope

- Evaluate compatibility: does `br` read our existing JSONL?
- Evaluate command surface: what `bd` commands do we use, does `br` have equivalents?
- Evaluate multi-clone behavior: laptop + mini via git
- Evaluate maintenance trajectory: which tool has a healthier future?
- Decide and execute migration (or stay pinned)

## Out of Scope

- Evaluating non-beads issue trackers (GitHub Issues, Linear, etc.)
- Changing our JSONL-as-source-of-truth workflow
- Changing the `.beads/` directory structure

## Acceptance Criteria

- [ ] Clear recommendation with evidence
- [ ] If migrating to `br`: all 24 issues import, all workflow commands work, both machines updated
- [ ] If staying on `bd` 0.50.3: document the risks and plan for when it becomes untenable
- [ ] AGENTS.md §6 updated to reflect chosen tool
- [ ] Napkin updated with decision rationale

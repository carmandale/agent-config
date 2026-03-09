# 010 — Beads Backend Evaluation: Planning Transcript

**Participants:** OakJaguar (pi/claude-sonnet-4, proposer) × DarkMoon (pi/claude-sonnet-4-6, challenger)
**Date:** 2026-03-09
**Bead:** .agent-config-17q

## Research Phase (OakJaguar)

Investigated blast radius across agent-config codebase:
- Git hooks: pre-commit (calls `bd sync --flush-only`), post-merge (calls `bd import -i`)
- AGENTS.md §6: 7 bd references
- CLAUDE.md: 11 bd references (separate file, NOT symlink to AGENTS.md)
- Commands: 15 files, ~40 references
- Skills: 6 files, ~38 references (globally symlinked)
- .beads/ directory: both machines have issues.jsonl, only laptop has beads.db
- Mini has bd v0.50.3 installed but no pre-commit/post-merge hooks

## Challenge Round 1 (DarkMoon) — 6 issues

1. **BLOCKER: `bd --no-db ready` has no br equivalent** — br has no `--no-db` mode. Resolution: fallback unnecessary because br always has SQLite DB after init.

2. **BLOCKER: CLAUDE.md not in plan** — Regular file with 11 bd refs, not a symlink. Added to Phase 3.

3. **HIGH: `br init` uses same `beads.db` filename** — Confirmed: returns AlreadyInitialized error if file exists, `--force` overwrites. Mitigation: rename to beads.db.bd-backup before init.

4. **HIGH: Skill edits are globally scoped** — Skills symlinked to ~/.claude/skills/, ~/.pi/agent/skills/, etc. Must coordinate timing.

5. **MEDIUM: Pre-commit hook has 4 substitution points, not 1** — Plan said "replace flag" but hook has command checks, error messages. Specified all 7 points across both hooks.

6. **MEDIUM: `-d` flag missing on `br update`** — br create has `-d` but update only has `--description` (long form). retro.md and pr-create.md need specific fix.

## Challenge Round 2 (DarkMoon) — 3 issues

7. **pgrep/pkill must be REMOVED, not renamed** — `pgrep -f "br "` would match brew, broot, etc. br has no daemon. Entire contention block removed.

8. **Bare `br sync` = import-only, not export** — Critical behavioral difference. 12 occurrences of bare `bd sync` across AGENTS.md, CLAUDE.md, and 5 command files ALL expect export behavior. All must become `br sync --flush-only`.

9. **Mini transition window** — After pushing docs (say `br`) but before installing br on mini, agents on mini would fail. Sequence-locked: steps must execute in one uninterrupted SSH session.

## Verification

All issues verified via source code examination:
- `br init` source: `AlreadyInitialized` error confirmed
- `br sync` source: bare sync defaults to `execute_import()`, not flush
- `br update` source: `description: Option<String>` with `#[arg(long, visible_alias = "body")]` — no `-d` short alias
- `br close` source: `reason: Option<String>` — confirmed
- `br doctor` source: 9 checks (merge artifacts, sync path, conflict markers, JSONL parse, schema, SQLite integrity, DB vs JSONL counts, sync metadata)

## Outcome

Plan: 5 phases, 41 tasks. All 9 review findings incorporated. Both participants agreed.

DarkMoon's parting note: "The beads.db rename-before-init is the step most likely to feel unnecessary in the moment and get skipped. Don't skip it."

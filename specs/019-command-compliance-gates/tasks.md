---
title: "Tasks — Command Compliance Gates"
date: 2026-03-12
bead: .agent-config-1v4
---

# Tasks: 019 — Command Compliance Gates

## Phase 1: Create gate.sh

- [ ] **T1.1** Create `scripts/gate.sh` with shebang, usage help, and subcommand dispatch (`gate`, `record`, `verify`)
- [ ] **T1.2** Implement frontmatter parser: extract `gate_*` keys from a command markdown file using `grep + cut + tr + xargs`. Handle: leading spaces after comma split, missing keys (treated as empty), files without frontmatter
- [ ] **T1.3** Implement `gate` subcommand:
  - Read `gate_requires` from `commands/$CMD.md` — check each file exists in spec dir
  - Read `gate_sentinels` — for each sentinel pattern, grep the corresponding required file with backward-compatible matching (old format + new format)
  - Read `gate_warn_sentinels` — same check but exit 2 (WARN) instead of exit 1 (FAIL)
  - Check `bead:` exists in `spec.md` frontmatter when spec.md is in gate_requires
  - When `workflow-state.md` exists, cross-reference to verify prerequisite commands ran (supplementary to sentinel checks — used when sentinels are absent per R6)
  - Exit 0 (PASS), 1 (FAIL), or 2 (WARN) with specific, actionable error messages
- [ ] **T1.4** Implement `record` subcommand:
  - Read `gate_creates` from `commands/$CMD.md`
  - For each file in `gate_creates` that exists in spec dir: write sentinel `<!-- <command>:complete:v1 | harness: $HARNESS | date: <ISO> -->` as first line (or after existing frontmatter)
  - Accept `--harness` flag for harness/model identification (e.g., `--harness "pi/claude-sonnet-4"`)
  - Accept `--extra` flag for additional sentinel fields (e.g., `--extra "rounds: 2, model: gpt-5.3-codex"`)
  - Append completion entry to `workflow-state.md` in spec dir (create if needed)
  - Warn (don't fail) if a gate_creates file doesn't exist in spec dir
- [ ] **T1.5** Implement `verify` subcommand:
  - Read `gate_must_not_create` from `commands/$CMD.md`
  - Read gate-check timestamp from `<spec-dir>/.gate-<command>-timestamp` (per-command, per-spec — no collision between concurrent commands on different specs)
  - Check if any forbidden file was created or has mtime AFTER the gate-check timestamp (avoids false positives on pre-existing files like spec.md, plan.md)
  - Exit 0 (CLEAN) or 1 (VIOLATION) with list of offending files and their modification times
  - Clean up the timestamp file after verification
- [ ] **T1.5b** In `gate` subcommand: write current epoch timestamp to `<spec-dir>/.gate-<command>-timestamp` when checks pass. File naming: `.gate-implement-timestamp`, `.gate-plan-timestamp`, etc. Used by `verify` for baseline comparison. Add `.gate-*-timestamp` to `.gitignore` in spec dirs.
- [ ] **T1.6** Make gate.sh executable (`chmod +x scripts/gate.sh`)

## Phase 2: Add frontmatter to commands

- [ ] **T2.1** Add `gate_creates` and `gate_must_not_create` to `commands/issue.md` frontmatter
- [ ] **T2.2** Add `gate_creates` and `gate_must_not_create` to `commands/shape.md` frontmatter
- [ ] **T2.3** Add `gate_requires`, `gate_creates`, and `gate_must_not_create` to `commands/plan.md` frontmatter
- [ ] **T2.4** Add `gate_requires`, `gate_sentinels`, `gate_creates`, and `gate_must_not_create` to `commands/codex-review.md` frontmatter
- [ ] **T2.5** Add `gate_requires`, `gate_sentinels`, `gate_warn_sentinels`, `gate_creates`, and `gate_must_not_create` to `commands/implement.md` frontmatter

## Phase 2.5: Smoke test

- [ ] **T2.6** Create temp test spec dir with spec.md (with `bead:` frontmatter), plan.md + tasks.md (with `<!-- plan:complete:v1 ... -->` sentinel)
- [ ] **T2.7** Run `gate.sh gate implement <test-dir>` — verify PASS (exit 0)
- [ ] **T2.8** Remove tasks.md — verify FAIL (exit 1) with message mentioning /plan
- [ ] **T2.9** Restore tasks.md, remove sentinel from plan.md — verify FAIL (exit 1) with message about missing sentinel
- [ ] **T2.10** Run `gate.sh gate implement specs/017-codex-review-invocation-fix/` — verify WARN or PASS (existing spec, no sentinels = graceful handling per R6)
- [ ] **T2.11** Clean up test dir

## Phase 3: Add HARD CONSTRAINT blocks

- [ ] **T3.1** Add HARD CONSTRAINT gate check block to `commands/plan.md` — after frontmatter, before "What you must do"
- [ ] **T3.2** Add HARD CONSTRAINT gate check block to `commands/codex-review.md` — after frontmatter, before "When to Invoke"
- [ ] **T3.3** Add HARD CONSTRAINT gate check block to `commands/implement.md` — after frontmatter, before "Alignment gate"
- [ ] **T3.4** Add anti-fabrication text to `commands/implement.md` HARD CONSTRAINT: "Do NOT create spec.md, plan.md, tasks.md, or codex-review.md — those belong to /issue, /plan, and /codex-review"
- [ ] **T3.5** Add anti-fabrication text to `commands/plan.md` HARD CONSTRAINT: "Do NOT create spec.md or codex-review.md — those belong to /issue and /codex-review"
- [ ] **T3.6** Add anti-fabrication text to `commands/codex-review.md` HARD CONSTRAINT: "Do NOT create or modify spec.md, plan.md, or tasks.md"
- [ ] **T3.7** Add guidance to `commands/issue.md` and `commands/shape.md`: "After completion, run `scripts/gate.sh record <command> <spec-dir>` to write provenance sentinel"
- [ ] **T3.8** Review `commands/sweep.md` and `commands/audit-agents.md`: both route into pipeline steps (sweep creates specs, audit-agents creates specs/fixes). Add `gate_creates` frontmatter where they produce spec artifacts, add anti-fabrication guidance. If they don't produce artifacts in spec dirs, document "checked — no gate_* keys needed" as a comment

## Phase 4: Sentinel writing and pipeline state

- [ ] **T4.1** Add `gate.sh record` invocation instruction to end of `commands/issue.md`
- [ ] **T4.2** Add `gate.sh record` invocation instruction to end of `commands/shape.md`
- [ ] **T4.3** Add `gate.sh record` invocation instruction to end of `commands/plan.md`
- [ ] **T4.4** Update `commands/codex-review.md` Step 6 (writeback): replace manual header writing with `gate.sh record codex-review <spec-dir> --harness "codex/<model>" --extra "rounds: N"`
- [ ] **T4.5** Add `gate.sh record` invocation instruction to end of `commands/implement.md`
- [ ] **T4.6** Add `gate.sh verify` invocation instruction to end of `commands/plan.md`, `commands/codex-review.md`, and `commands/implement.md` (commands that consume other commands' artifacts)

## Phase 5a: Claude Code UserPromptSubmit hook

- [ ] **T5a.1** Create `configs/claude/hooks/src/gate-check.ts` — TypeScript source (built via existing esbuild pipeline to `dist/gate-check.mjs`) that:
  - Reads user prompt from stdin (JSON)
  - Pattern matches `/plan `, `/implement `, `/codex-review ` at start of prompt
  - Extracts spec argument from prompt text
  - Resolves to spec dir with canonicalization: strip leading `@`, expand `~/`, `resolve()` to absolute path, verify path is under project's `specs/` directory (containment check), fallback to glob `specs/*$arg*/`
  - Runs `scripts/gate.sh gate <command> <spec-dir>`
  - Returns `{ "decision": "block", "message": "..." }` on exit 1, passes through on exit 0 or 2
- [ ] **T5a.2** Add hook entry to `configs/claude/settings.json` under `UserPromptSubmit`: `node "$HOME/.claude/hooks/dist/gate-check.mjs"`
- [ ] **T5a.3** Run `cd configs/claude/hooks && npm run build` to verify compilation

## Phase 5b: Claude Code PostToolUse hook (STRETCH GOAL — may defer)

- [ ] **T5b.1** Create `configs/claude/hooks/src/gate-fabrication-guard.ts` — TypeScript source, fires on Write/Edit tool calls, checks file paths against `gate_must_not_create` for the active command
- [ ] **T5b.2** Add hook entry to `configs/claude/settings.json` under `PostToolUse`
- [ ] **T5b.3** Determine session state mechanism: how does the hook know which command is active?

Note: Phase 5b is explicitly a stretch goal. The plan ships without it. Layers A (prose) and B (gate.sh verify) provide anti-fabrication enforcement for v1.

## Phase 5c: Pi gate-check extension

- [ ] **T5c.1** Create `configs/pi/extensions/gate-check.ts` — TypeScript extension using `pi.on("tool_call", ...)` to monitor bash tool calls for spec-dir file operations without prior gate.sh invocation. Uses same path canonicalization as T5a.1
- [ ] **T5c.2** Handle spec path resolution with containment check (resolved path must be under `specs/`)

## Phase 6: End-to-end testing

- [ ] **T6.1** Test full pipeline on a new scratch spec: `/issue` → `/shape` → `/plan` → `/codex-review` → `/implement`. Verify sentinels accumulate, workflow-state.md grows, each gate check passes
- [ ] **T6.2** Test failure path: attempt `/implement` without running `/plan` — verify gate blocks
- [ ] **T6.3** Test fabrication detection: run `gate.sh verify` after manually creating a forbidden file — verify VIOLATION
- [ ] **T6.4** Test backward compatibility: run gate checks against existing specs 017 and 018 — verify warn-not-block behavior
- [ ] **T6.5** Test Layer 2 hook (if implemented): invoke `/implement` via Claude Code with missing prerequisites — verify prompt is blocked before command executes

<!-- plan:complete:v1 | harness: pi/claude-sonnet-4-thinking | date: 2026-03-12T19:30:00Z -->

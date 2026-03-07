# Checkpoint: Agent Workflow Commands Suite

**Date:** 2026-03-07 06:30 CST
**Agent:** JadeGrove | pi/claude-sonnet-4
**Bead:** .agent-config-gfi (spec 006, in_progress)

## What Was Built This Session

A complete suite of 8 workflow commands for AI coding agent development, with two-agent enforcement, forced skill reads, audit logging, and pre-check gates. All commands symlinked across pi, claude-code, codex, and gemini.

### Commands (all in `~/.agent-config/commands/`)

| Command | Status | Key features |
|---------|--------|-------------|
| `/ground` | ✅ Updated | Next-step suggestions by intent |
| `/shape` | ✅ Updated | Forced shaping SKILL.md read, two-agent, transcript proof, audit log |
| `/issue` | ✅ Rewritten | Simplified: bead + spec.md only. No plan/tasks (that's /plan's job) |
| `/plan` | ✅ NEW | Forced workflows-plan SKILL.md read, two-agent (engage before writing), bead gate, audit log |
| `/codex-review` | ✅ Updated | Audit log added |
| `/implement` | ✅ Rewritten | Forced workflows-work SKILL.md read, two-agent (driver+navigator), bead gate, audit log |
| `/sweep` | ✅ Updated | Next-step suggestions |
| `/audit-agents` | ✅ Updated | Next-step suggestions |
| `/help-workflow` | ❌ Not created yet | Planned in spec 006 task 6 |

### Key Design Decisions

1. **Two-agent gates are the enforcement mechanism for skill compliance.** Four commands require two participants: /shape, /plan, /codex-review, /implement. The second perspective prevents corner-cutting.

2. **Engage second agent BEFORE writing, not after.** Learned from gj-tool test run where ZenPhoenix did 90% solo then sent finished plan to RedEagle for rubber-stamp. The /plan command now explicitly says "share findings with second agent before writing plan.md."

3. **Bead + numbered spec is non-negotiable.** `/plan` refuses without spec.md + bead. `/implement` refuses without spec.md + plan.md + tasks.md + bead. Commands tell you what's missing and which command to run.

4. **Audit log in spec directory.** Every workflow command appends to `log.md`: timestamp, mesh name, harness/model, command, event. `cat specs/*/log.md` is the cross-project activity feed.

5. **Entry points vary but /issue always happens.** Clear problem → /issue first. Vague idea → /shape first → /issue to formalize. Bug hunting → /sweep. The flow adapts.

6. **Each command suggests the next step with the specific command and spec path.** No dead ends. The chain: /ground → /shape → /issue → /plan → /codex-review → /implement.

### Docs Updated

- **README.md** — Full workflow section with flow diagram, two-agent gates, spec directory layout, audit log
- **AGENTS.md** — Workflow commands table with produces/suggests columns
- **Napkin** — Rules 6-8: two-agent enforcement, bead tracking, audit log
- **prompt-craft skill** — Existing (from earlier in session)

### Test Run Evidence

Two agents (ZenPhoenix + RedEagle) ran `/shape` then `/plan` on gj-tool spec 003. Results:
- Shaping produced real collaborative output (R0-R9, 3 shapes, fit check, Shape C selected)
- Planning caught PIPESTATUS bug via two-agent stress-testing
- Plan grounded in specific code lines (bin/gj:2265-2464)
- Artifacts: shaping.md, plan.md, tasks.md, planning-transcript.md in `gj-tool/specs/003-gj-unit-swift-testing/`
- Gap found: /issue was skipped (no bead, no spec.md) → fixed with pre-check gate
- Gap found: solo-then-review pattern in /plan → fixed with "engage before writing" instruction

## What's Left

### Spec 006 (agent-workflow-verification) — Codex-approved, partially implemented

The original spec 006 had 11 tasks. Most were completed organically during this session but in a different form than planned. Remaining:

- [ ] **Task 5** — Artifact contract content markers in prompt-craft skill (expand "Anchor Trust" section with specific content markers per artifact type)
- [ ] **Task 6** — Create `/help-workflow` command (conversational listing of all 8 commands)
- [ ] **Task 8-10** — Verification: symlinks, skill propagation, Gemini TOML content checks
- [ ] **Task 11** — Final commit

### Other

- Bead `.agent-config-gfi` still in_progress — close after spec 006 is fully done
- Dirty files in working tree are unrelated rp-* commands (not blocking)
- `meta/_sandbox` SKILL.md warning is a known non-issue

## Git State

```
Working tree: clean for workflow commands (rp-* files are unrelated)
Branch: main
Latest: 5fc440ed docs: workflow commands documented across README, AGENTS.md, napkin
```

## How to Resume

1. Read this checkpoint
2. Read `specs/006-agent-workflow-verification/tasks.md` for remaining tasks
3. The spec was Codex-approved — implementation can proceed
4. Most of the work was done differently than planned (commands evolved organically based on test run feedback) — reconcile tasks.md with actual state before checking things off
5. Create `/help-workflow` (task 6) and expand prompt-craft artifact contracts (task 5)
6. Run verification (tasks 8-10), commit, close bead

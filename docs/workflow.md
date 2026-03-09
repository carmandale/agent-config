# Workflow Commands

> The pipeline for tracked, spec-driven work across all AI coding agents.
> Each command suggests the next step. All commands are individually usable — no mandatory pipeline.

## The Pipeline

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

---

## Commands in Detail

### /ground — Orient

Read all project instructions, investigate the codebase, build a mental model. This is the foundation — every session should start here.

- Reads: `AGENTS.md`, `README.md`, project instructions, napkin, handoffs
- Produces: `## Grounded` summary block
- Caching: 3-tier system (same-session skip → cross-session light ground → full ground)
- Force: `/ground force` bypasses cache

**Next:** `/shape`, `/issue`, `/sweep`, or `/audit-agents`

### /shape — Discover (2 agents required)

Explore the problem and solution space collaboratively. One agent proposes, the other challenges assumptions. The shaping process is iterative — requirements and solutions evolve together.

- Reads: shaping SKILL.md (forced read)
- Produces: `specs/NNN-slug/shaping-transcript.md`
- Two-agent dynamic: Explore problem ↔ challenge assumptions

**Next:** `/issue`

### /issue — Define

Create a bead (tracked work item) and a spec directory with `spec.md`. This is the moment work becomes tracked — no bead, no spec.

- Produces: `specs/NNN-slug/spec.md` with bead ID in frontmatter
- Spec IDs: zero-padded sequential (`001`, `002`, ...)

**Next:** `/plan <spec>`

### /plan — Plan (2 agents required)

Build an implementation plan grounded in actual codebase research. One agent researches and proposes, the other stress-tests the approach.

- Reads: workflows-plan SKILL.md (forced read)
- Pre-check: Refuses without `spec.md` + bead frontmatter
- Produces: `plan.md`, `tasks.md`, `planning-transcript.md`
- Two-agent dynamic: Research & propose ↔ stress-test

**Next:** `/codex-review <spec>`

### /codex-review — Gate (2 agents required)

Send the spec and plan to OpenAI Codex for iterative review. Claude orchestrates — revising the plan based on Codex feedback and resubmitting until Codex approves. Max 5 rounds.

- Pre-check: Requires spec directory with `spec.md` + `plan.md`
- Produces: `codex-review.md` (the review transcript — proof the review happened)
- Writeback: Updates `plan.md` (revised), `tasks.md` (reconciled), `spec.md` (review header)
- Two-agent dynamic: Claude orchestrates ↔ Codex reviews
- Only Codex can approve — the string `VERDICT: APPROVED` must appear in Codex's output

**Next:** `/implement <spec>`

### /implement — Build (2 agents required)

Execute the plan with quality gates. One agent drives (writes code, runs tests, commits), the other navigates (validates against plan, checks quality, catches drift).

- Reads: workflows-work SKILL.md (forced read)
- Pre-check: Refuses without `spec.md` + `plan.md` + `tasks.md` + bead
- Produces: git commits + PR
- Two-agent dynamic: Implement ↔ validate each step

---

## Discovery & Bug Hunting

These commands are entry points, not part of the main pipeline:

| Command | Description | Next |
|---------|-------------|------|
| `/sweep` | Random code exploration → bug hunting → spec creation | `/codex-review` → `/implement` |
| `/audit-agents` | Skeptical review of agent-written code, fix in-place | `/issue` if spec warranted, or commit |

---

## Two-Agent Gates

Four commands require two participants. This is structural enforcement — a second perspective prevents corner-cutting. One agent doing everything solo is not sufficient.

| Command | Skill Forced | Dynamic |
|---------|-------------|---------|
| `/shape` | shaping SKILL.md | Explore ↔ challenge |
| `/plan` | workflows-plan SKILL.md | Propose ↔ stress-test |
| `/codex-review` | (self-contained) | Orchestrate ↔ review |
| `/implement` | workflows-work SKILL.md | Drive ↔ navigate |

**How collaboration works:** See [agent-collaboration.md](agent-collaboration.md) for the exact mechanics — Mode 1 (interactive, collaborator already on mesh) and Mode 2 (autonomous, spawn/dismiss via pi_messenger).

---

## Spec Directory

Every piece of tracked work lives in `specs/NNN-slug/`:

```
specs/007-ground-session-cache/
├── spec.md                    # What and why (bead in frontmatter)
├── plan.md                    # How (architecture decisions, insertion points)
├── tasks.md                   # Do this (ordered checkable list)
├── shaping-transcript.md      # Proof: two-agent shaping happened
├── planning-transcript.md     # Proof: two-agent planning happened
├── codex-review.md            # Proof: Codex actually reviewed
└── log.md                     # Audit trail: who ran what, when, with what model
```

**File existence is the dashboard.** `ls specs/*/codex-review.md` tells you which specs have been reviewed. No file = didn't happen.

---

## Audit Log

Every workflow command appends to `log.md` in the spec directory:

```
YYYY-MM-DD HH:MM | ZenPhoenix | pi/claude-opus-4-6     | /shape        | started with RedEagle
YYYY-MM-DD HH:MM | ZenPhoenix | pi/claude-opus-4-6     | /issue        | bead .gj-tool-xyz — spec.md
YYYY-MM-DD HH:MM | —          | codex/gpt-5.3-codex    | /codex-review | round 3 — VERDICT: APPROVED
```

Mesh name (pi_messenger identity) if available, `—` if not. Harness/model always mandatory.

---

## Pre-checks

Commands enforce prerequisites — they refuse to proceed without the right artifacts:

| Command | Requires | Missing? Run... |
|---------|----------|-----------------|
| `/plan` | `spec.md` + bead | `/issue` |
| `/implement` | `spec.md` + `plan.md` + `tasks.md` + bead | `/issue`, then `/plan` |
| `/codex-review` | `spec.md` + `plan.md` | `/plan` |

---

## Session Management

| Command | Description |
|---------|-------------|
| `/ground` | Orient in the project (start of every session) |
| `/focus <bead>` | Load context for a specific bead, mark in-progress |
| `/finalize` | Close session — record solutions, decisions, artifacts |

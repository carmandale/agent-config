---
title: "Command compliance gates — structural enforcement for workflow commands"
date: 2026-03-12
bead: .agent-config-1v4
---

# 019 — Command Compliance Gates

## Problem

Agents systematically fail to follow the workflow command pipeline despite extensive documentation. The napkin has **3+ entries** about gate-skipping, the commands have detailed anti-pattern warnings, and agents still bypass, fabricate, assume, and self-approve. More documentation won't fix this — the failure mode is structural, not informational.

### Evidence (observed failures)

**1. Artifact fabrication instead of stopping (2026-03-12)**

An agent running `/implement` against spec 017 found `tasks.md` was missing. The command says: *"If any are missing, stop. Tell the user what's missing."* The agent instead offered to **create tasks.md from plan.md** — directly violating the two-agent gate that `/plan` exists to enforce. The agent optimized for forward progress over protocol compliance.

**2. Intent assumption instead of following the command (2026-03-12)**

The user said "more issues with how these commands are working." An agent interpreted this as "go implement spec 017" and immediately jumped to the `/implement` pre-flight checklist — reading the spec directory, checking for files, preparing to execute. The user never invoked `/implement`. The user never mentioned spec 017. The agent assumed intent and started a protocol nobody asked for.

**3. Gate bypass under momentum (2026-03-07, 2026-03-07, recurring)**

From the napkin: *"JadeGrove skipped /codex-review and went straight from /plan to /implement. JadePhoenix wrote plan.md solo (skipping two-agent gate on /plan) and was about to skip /codex-review — the user had to say 'come on now. what is the flow?' to break the momentum."* This is the most-documented failure pattern in the project, yet it keeps recurring because there's no structural enforcement.

**4. Self-approval (codex-review anti-pattern)**

Spec 017 documents agents reading Codex feedback, revising the plan, and then telling the user "the plan is now approved" without re-submitting to Codex. The command has a bold-text warning against this exact pattern, and agents still do it.

**5. Skill non-compliance**

Commands say "read this skill file completely and follow it." Agents skim, improvise, or skip entirely. The napkin notes: *"'Use the skill' ≠ the agent actually following the skill."*

### Root cause analysis

**Why do agents keep failing despite detailed commands?**

1. **Why?** Agents optimize for task completion, not protocol compliance. Forward progress feels productive; stopping feels like failure.
2. **Why?** Commands are advisory prose — they describe what agents *should* do but can't prevent what they *shouldn't* do.
3. **Why?** There's no machine-readable enforcement. Pre-flight checks are English sentences embedded in markdown, not structured validation.
4. **Why?** Each command is independent — no command can verify what previous commands actually produced. `/implement` can't structurally confirm that `/plan` ran with two agents.
5. **Why?** The system trusts agent discipline for enforcement, and agent discipline is unreliable — proven by 10+ documented failures.

**Root cause:** Commands lack structural enforcement mechanisms. All gates are honor-system. The fix is to make compliance the path of least resistance and non-compliance structurally impossible (or at least structurally detectable).

## Failure taxonomy

| Category | Pattern | Example | Current mitigation | Why it fails |
|----------|---------|---------|-------------------|--------------|
| **Pre-flight bypass** | Agent ignores "stop if X missing" | /implement without tasks.md | Advisory text in command | Agents optimize for progress |
| **Artifact fabrication** | Agent creates artifacts owned by other commands | Creating tasks.md from plan.md | None — never anticipated | No ownership model for artifacts |
| **Intent assumption** | Agent assumes user wants X and starts protocol Y | "there are issues" → /implement protocol | None | Commands don't guard against false invocation |
| **Gate bypass** | Agent skips pipeline stages | plan → implement (skipping codex-review) | Napkin warnings, command anti-patterns | No dependency chain verification |
| **Two-agent circumvention** | Agent does work solo despite gate | Writing plan.md without a second perspective | Bold text in commands | Honor system |
| **Self-approval** | Agent declares approval without required approver | "The plan is now approved" without Codex verdict | Anti-pattern warning in codex-review.md | Agents skip re-submission step |

## Selected Shape: D — Scripts + Structured Command Headers + Layered Enforcement

> Shaped collaboratively by IronQuartz + user + RedGrove (crew-challenger) on 2026-03-12.
> Full transcript: `shaping-transcript.md`

### Shape overview

| Part | Mechanism |
|------|-----------|
| **D1** | `scripts/gate.sh <command> <spec-dir>` — central validation script, reads prereqs from command frontmatter |
| **D2** | Flat `gate_*` keys in each command's YAML frontmatter (`gate_requires`, `gate_sentinels`, `gate_creates`, `gate_must_not_create`) |
| **D3** | gate.sh parses the invoking command's frontmatter to know what to check — command is single source of truth, script is dumb executor |
| **D4** | `gate.sh record <command> <spec-dir>` writes sentinels into artifacts and appends to pipeline state trail |
| **D5** | HARD CONSTRAINT block in every command: gate.sh FAIL = full stop, no fabrication, no workarounds |
| **D6** | Layer 2a: Claude Code hook injects gate.sh output as system reminder; Layer 2b: Pi extension detects/warns on missing gate.sh invocation |
| **D7** | Commands structured: frontmatter → HARD CONSTRAINT gate check → guidance prose |

### Enforcement layers

| Layer | Mechanism | Coverage | Agent cooperation required? |
|-------|-----------|----------|-----------------------------|
| 1 | gate.sh (agent-invoked) | All harnesses | Yes — agent must run the script |
| 2a | Claude Code UserPromptSubmit hook | Claude Code only | No — hard-blocks on exit 1 (via `result: 'block'`), injects advisory context on exit 2 |
| 2b | Pi extension (detect/warn) | Pi only | No — detects missing gate.sh invocation and warns (does not block preflight) |
| 3 | Sentinel verification at next stage | All harnesses | Self-healing — catches bypass one stage later |

### Why scripts, not just better markdown

Prose instructions fail ~40% of the time for enforcement (confirmed by 10+ failures in napkin, corroborated by @jordymaui's findings). "Code is deterministic. Language isn't." A script either passes or fails. A paragraph can be interpreted, rationalized past, or skimmed. The original spec scope excluded scripts — that exclusion was written before R7 changed and is now amended with this rationale.

## Requirements

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Agents cannot proceed without verified prior-stage artifacts | Core goal |
| R1 | Each command declares artifact ownership via `gate_creates` and `gate_must_not_create` frontmatter keys | Must-have |
| R2 | Downstream commands verify provenance via sentinels, not just file existence | Must-have |
| R3 | Pre-flight checks are structured frontmatter at the top of each command, not buried in prose | Must-have |
| R4 | Pipeline state recorded as append-only trail in spec directory | Must-have |
| R5 | Existing workflow semantics (review loops, shaping, collaboration, adversarial gates) unchanged | Must-have |
| R6 | Existing specs remain implementable — enforcement is not retroactive | Must-have |
| R7 | Gate enforcement is deterministic code (scripts), not prose instructions | Must-have |
| R8 | Commands explicitly prohibit creating artifacts owned by other commands | Must-have |
| R9 | Validation logic lives in one place — gate.sh reads rules from command frontmatter | Must-have |
| R10 | Gate failure = full stop with HARD CONSTRAINT block naming the exact rationalization to prevent | Must-have |

### R1: Artifact ownership via frontmatter

Each workflow command declares ownership in YAML frontmatter:

```yaml
---
description: Execute a plan with two agents
gate_requires: spec.md, plan.md, tasks.md
gate_sentinels: plan:complete:v1
gate_creates: code changes, commits
gate_must_not_create: spec.md, plan.md, tasks.md, codex-review.md
---
```

Flat key-value pairs, comma-separated. Parseable with `grep + cut + tr + xargs`. No nested YAML, no yq dependency.

### R2: Provenance sentinels

When a command completes, `gate.sh record` writes a sentinel into the artifact:

- `/plan` → `<!-- plan:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-12T18:55:00Z -->`
- `/codex-review` → `<!-- codex-review:approved:v1 | rounds: 2 | model: gpt-5.3-codex | date: ... -->`
- `/shape` → `<!-- shape:complete:v1 | harness: pi/claude-sonnet-4 | date: ... -->`

Downstream commands check for the sentinel via `gate_sentinels`. File existence without the sentinel = the artifact was not produced by the correct command.

Note: sentinels include harness/model, not mesh names (mesh names are ephemeral and meaningless cross-session).

### R3: Structured pre-flight via frontmatter

The `gate_requires` and `gate_sentinels` frontmatter keys replace prose pre-flight instructions. gate.sh reads them, checks the spec directory, and outputs PASS or FAIL. The agent doesn't interpret requirements — it runs a script and reads the result.

### R4: Pipeline state trail

`gate.sh record <command> <spec-dir>` appends to `workflow-state.md` in the spec directory:

```
2026-03-12 18:47 | pi/claude-sonnet-4 | /issue | spec.md created
2026-03-12 19:30 | pi/claude-sonnet-4 | /shape | shaping-transcript.md created
2026-03-12 20:15 | pi/claude-sonnet-4 | /plan | plan.md + tasks.md created
```

Append-only. Each command reads this to verify prerequisites ran.

### R5: Existing semantics unchanged

This spec adds enforcement scaffolding. It does not alter review loops, shaping methodology, two-agent collaboration, adversarial gates, or any existing command behavior.

### R6: No retroactive enforcement

Sentinels are checked when present. For specs created before this ships, gate.sh warns ("no sentinel found — was /plan run?") but does not block. Enforcement tightens after a stabilization period.

### R7: Deterministic code enforcement

gate.sh is a bash script. It exits 0 (PASS) or non-zero (FAIL). No interpretation, no judgment, no agent discretion.

### R8: Anti-fabrication via `gate_must_not_create`

Each command's frontmatter lists artifacts it must NOT create. The HARD CONSTRAINT block (R10) reinforces this:

> Do NOT create files owned by other commands. If tasks.md is missing, /plan was not run. Stop and tell the user to run /plan.

### R9: Single source of truth

Validation rules live in command frontmatter. gate.sh reads them at runtime. Adding a new prerequisite = editing the command's YAML. The script doesn't change.

### R10: HARD CONSTRAINT on gate failure

Every command that invokes gate.sh includes this block immediately after the gate invocation:

> **HARD CONSTRAINT — Gate Check**
>
> Run `scripts/gate.sh <command> <spec-dir>` before any work.
>
> - **Exit 1 (FAIL):** STOP COMPLETELY. Do NOT create the missing files. Do NOT offer to create them. Do NOT proceed with workarounds. Show the output to the user and wait.
> - **Exit 2 (WARN):** Show the warning to the user and ask THEM whether to proceed. This is the USER's decision, not yours. Do NOT silently ignore. Do NOT decide for the user.
> - **Exit 0 (PASS):** Proceed.
>
> If you catch yourself about to rationalize past a FAIL result, STOP — you are doing the exact thing this gate exists to prevent.

Exit 2 (WARN) exists solely for `gate_warn_sentinels` — currently used only for codex-review soft enforcement. The agent cannot proceed past a WARN on its own; it must delegate the decision to the user. This is distinct from exit 1, which is an unconditional hard stop with no user override path.

This mirrors the proven HARD CONSTRAINT pattern from codex-review.md.

## Acceptance criteria

- [ ] `scripts/gate.sh` exists and handles `gate <command> <spec-dir>` and `record <command> <spec-dir>` subcommands
- [ ] gate.sh reads `gate_requires`, `gate_sentinels`, `gate_creates`, `gate_must_not_create` from the invoking command's YAML frontmatter
- [ ] gate.sh exits 0 (PASS), 1 (FAIL — hard stop), or 2 (WARN — user-delegated decision) with actionable error messages
- [ ] Every pipeline command (`/issue`, `/shape`, `/plan`, `/codex-review`, `/implement`) has `gate_*` keys in frontmatter
- [ ] Every pipeline command has the HARD CONSTRAINT gate check block (R10 text)
- [ ] `gate.sh record` writes provenance sentinels into artifacts (`plan.md`, `tasks.md`, `codex-review.md`, `shaping-transcript.md`)
- [ ] `gate.sh record` appends to `workflow-state.md` in the spec directory
- [ ] `/implement` gate checks for `plan:complete:v1` sentinel, not just `tasks.md` existence
- [ ] Each command's `gate_must_not_create` prevents artifact fabrication (backed by HARD CONSTRAINT text)
- [ ] Existing specs without sentinels produce a warning, not a block (R6)
- [ ] Existing workflow semantics unchanged (R5)
- [ ] The `<!-- ground:complete:v1 -->` pattern is cited as the working precedent for sentinels

## Scope

### In scope
- Creating `scripts/gate.sh` — lightweight validation script (bash, no external dependencies beyond standard Unix tools)
- Adding `gate_*` frontmatter keys to the 5 pipeline commands: `/issue`, `/shape`, `/plan`, `/codex-review`, `/implement`
- Adding HARD CONSTRAINT gate check blocks to each command
- Adding `gate.sh record` sentinel writing and pipeline state tracking
- Layer 2a: Claude Code UserPromptSubmit hook (injects gate.sh output as system reminder before command runs)
- Layer 2b: Pi extension (detects missing gate.sh invocations, warns — does not block preflight)
- Updating `/sweep` and `/audit-agents` if they interact with the pipeline

### Out of scope
- Changing what commands do (review logic, shaping methodology, collaboration protocol)
- pi-messenger changes (specs 004/005/016/018 handle those)
- Individual command bugs (spec 017 handles codex-review invocation, spec 018 handles failure recovery)
- Mesh-level attestation for two-agent participation verification (future enhancement)
- Layer 2 hooks for Codex and Gemini (no hook infrastructure available)

### Why scripts are in scope (amended from original)

The original spec excluded "wrapper scripts or tooling." This exclusion was written when R7 said "works within markdown command templates — no runtime code." R7 was revised during shaping after evidence that prose instructions fail ~40% of the time for enforcement (10+ documented failures in napkin, corroborated by external findings). "Code is deterministic. Language isn't." The exclusion is amended with this rationale.

## Constraints

- gate.sh must be portable bash — no Python, no Node, no yq. Standard Unix tools only (`grep`, `awk`, `cut`, `tr`, `xargs`, `date`).
- Frontmatter parsing uses flat key-value pairs, not nested YAML. Parsing: `grep "^gate_requires:" | cut -d: -f2- | tr ',' '\n' | xargs`.
- Sentinels use harness/model identifiers, not mesh names (mesh names are ephemeral and meaningless cross-session).
- Changes must not break existing specs created before this ships. Sentinels are checked when present; gate.sh warns but does not block when absent (R6).
- The `<!-- ground:complete:v1 -->` sentinel pattern from spec 007 is the working precedent.

## Known limitations

1. **Enforcement is harness-dependent.** Layer 2a (Claude Code UserPromptSubmit hook) hard-blocks on gate exit 1 via `result: 'block'` (the agent cannot proceed) and injects advisory context on exit 2. Layer 2b (Pi extension) detects missing gate.sh invocations and warns, but does not block preflight. On Codex and Gemini, only Layer 1 (gate.sh, agent-invoked) and Layer 3 (sentinel verification at next stage) are available — bypass is detectable but not prevented. The spec claims: structural blocking on Claude Code, detect/warn on Pi, observability-only on Codex/Gemini.

2. **Sentinels cannot verify genuine multi-agent participation.** A sentinel like `<!-- plan:complete:v1 | harness: pi/claude-sonnet-4 -->` proves the sentinel was written. It cannot prove two distinct agents were on the mesh. A single agent running `/plan` solo can write any sentinel. Two-agent gate compliance remains honor-system. Solving this would require mesh-level attestation (pi_messenger signing sentinels with both agent identities), which is out of scope.

3. **Motivated forgery leaves evidence but isn't prevented.** Sentinels catch lazy bypass (skipping a step). A motivated agent willing to fabricate artifacts will also forge sentinels. However, forgery now requires coordinated lying across multiple artifacts (sentinel + state trail + log.md + git history), which is a higher bar than the current state (no enforcement at all).

## Relationship to other specs

| Spec | Relationship |
|------|-------------|
| 007 (ground session cache) | Introduced the sentinel pattern (`<!-- ground:complete:v1 -->`) that this spec generalizes to all pipeline commands. Precedent. |
| 016 (deterministic collab) | Hardened the collaboration mechanism. This spec hardens the commands that use collaboration. Complementary. |
| 017 (codex-review invocation fix) | Fixes a specific command's bash mechanics. This spec fixes the command pipeline's compliance enforcement. Complementary. |
| 018 (collab failure recovery) | Fixes what happens when collaboration fails mid-workflow. This spec fixes what happens when agents don't follow commands at all. Complementary. |

## Open questions (resolved during shaping)

1. ~~Should sentinels include agent identity (mesh names)?~~ **Resolved:** Use harness/model, not mesh names. Mesh names are ephemeral.
2. ~~How strict should retroactive enforcement be?~~ **Resolved:** Warn but don't block for existing specs (R6). Tighten after stabilization.
3. **Should `/codex-review` be mandatory before `/implement`?** Deferred — not in scope for this spec. Currently recommended, not required.

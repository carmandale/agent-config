# Shaping Transcript: Agent Workflow Verification System

**Participants:** QuickPhoenix, IronMoon
**Date:** 2026-03-07
**Bead:** .agent-config-8uy (related)

---

## Round 1: QuickPhoenix → IronMoon (Requirements)

QuickPhoenix proposed initial R table:

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Agent runs complete dev workflow without user hand-holding each transition | Core goal |
| R1 | Every critical gate produces a non-fakeable file artifact proving it ran | Must-have |
| R2 | Commands preserve the user's natural voice/intensity | Must-have |
| R3 | System works across all agents via symlinks | Must-have |
| R4 | Shaping requires two participants — never one agent solo | Must-have |
| R5 | User can verify status across 10+ projects with a glance | Must-have |
| R6 | Codex review is mechanically verifiable (transcript artifact) | Must-have |
| R7 | Agents actually follow skill protocols instead of doing half-hearted versions | Core goal |
| R8 | Commands are individually usable — not locked into a mandatory pipeline | Must-have |

---

## Round 2: IronMoon → QuickPhoenix (Pushback)

IronMoon challenged:

- **R0 contradicts R8.** R0 implies automated transitions; R8 says no mandatory pipeline. We decided the user orchestrates. Revised R0: "Each command suggests what to run next so they always know the next step."
- **R1 "non-fakeable" is aspirational.** Sharpened to "faking harder than doing."
- **R2 is a constraint, not a requirement.** Moved to constraint on all shapes.
- **R4 underspecified.** Clarified: two independent perspectives (user+agent or agent+agent).
- **R5 scope creep.** QuickPhoenix disagreed — narrowed to "glanceable from spec directory."

IronMoon added:
- **R9: Discoverability.** User needs to know what commands exist and typical order.
- **R10: Protections work via command or skill directly.**

---

## Round 3: QuickPhoenix → IronMoon (Revised R table)

Accepted most pushback. Final R table:

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Each command suggests what to run next — user always knows the next step | Core goal |
| R1 | Critical gates produce artifacts with real content (transcripts, IDs, timestamps) — faking harder than doing | Must-have |
| R3 | Works across all agents via symlinks | Must-have |
| R4 | Shaping requires two independent perspectives (user+agent or agent+agent) — solo is invalid | Must-have |
| R5 | Verification status glanceable from spec directory via file existence | Must-have |
| R6 | Codex review produces mechanically verifiable transcript | Must-have |
| R7 | Agents follow skill protocols as written, not their interpretation | Core goal |
| R8 | Commands individually usable, no mandatory pipeline | Must-have |
| R9 | User can discover the full suite and typical workflow order | Nice-to-have |
| R10 | Protections work whether entering via command or skill directly | Undecided |

**Constraint on all shapes:** Commands preserve natural voice/intensity — no over-structuring.

---

## Round 4: IronMoon proposed Shape A

### A: Thin Commands + Smart Skills

Commands stay exactly as built — short, forceful wrappers. Intelligence lives in skills. Commands handle entry/exit; skills handle substance.

| Part | Mechanism |
|------|-----------|
| A1 | `/shape` forces SKILL.md file read, ends by suggesting `/issue` |
| A2 | `/issue` creates bead + spec dir; suggests `/codex-review` or `/implement` |
| A3 | `/codex-review` produces transcript artifact — no changes needed |
| A4 | `/implement` reads spec/plan/tasks, builds with alignment gate |
| A5 | `/shape` includes anti-pattern callout preventing half-hearted shaping |
| A6 | Each command's last paragraph tells user the next command |
| A7 | Proof artifacts in spec dir: `codex-review.md`, `shaping: true` frontmatter |
| A8 | `/help-workflow` command listing commands in typical order |

**Does not:** Harden skills independently (R10 unsolved). Does not enforce two-participant shaping mechanically (R4 stated but not enforced).

---

## Round 5: QuickPhoenix proposed Shape B

### B: Commands + Artifact Contracts + Skill Hardening

Same thin commands, plus artifact contracts and skill-level protections.

| Part | Mechanism |
|------|-----------|
| B1 | Commands stay short/forceful wrappers (same as A) |
| B2 | Artifact contracts: specific files with required content markers in spec dir |
| B3 | Pre-check hints in next-command suggestions |
| B4 | Shaping skill gets preamble about two-participant requirement |
| B5 | prompt-craft skill gets Artifact Contract section |
| B6 | `/help-workflow` lists commands + artifacts each produces |

---

## Round 6: IronMoon challenged Shape B

- **B4 submodule problem:** Shaping skill is a git submodule. Editing means forking or maintaining divergence. Upstream updates would blow away our changes.
- **B3 over-structures commands:** Pre-check hints ("Requires: spec.md exists") are exactly the process-doc pattern we identified as harmful. Drop B3.
- **R10 for shaping is low-risk:** Agents almost always enter via `/shape` command, not skill directly. Real R10 risk is workflows-plan producing loose plans, mitigated by `/issue`.

---

## Fit Check

| Req | Requirement | Status | A | B |
|-----|-------------|--------|---|---|
| R0 | Each command suggests what to run next | Core goal | ✅ | ✅ |
| R1 | Artifacts with real content — faking harder than doing | Must-have | ✅ | ✅ |
| R3 | Works across all agents via symlinks | Must-have | ✅ | ✅ |
| R4 | Shaping requires two independent perspectives | Must-have | ❌ | ✅ |
| R5 | Verification glanceable from spec dir via file existence | Must-have | ✅ | ✅ |
| R6 | Codex review produces verifiable transcript | Must-have | ✅ | ✅ |
| R7 | Agents follow protocols as written | Core goal | ✅ | ✅ |
| R8 | Commands individually usable, no mandatory pipeline | Must-have | ✅ | ✅ |
| R9 | Discover full suite and workflow order | Nice-to-have | ✅ | ✅ |
| R10 | Protections work via command or skill directly | Undecided | ❌ | ❌ |

**Notes:**
- A fails R4: states two-participant rule but doesn't produce transcript artifact for detection
- B passes R4: `shaping-transcript.md` makes violations detectable (two voices visible in artifact)
- Both fail R10: submodule ownership prevents hardening shaping skill. Accepted as known limitation.

---

## Selected Shape: B-modified

B minus B3 (pre-check hints — over-structures commands) and B4 (submodule edit — ownership problem).

| Part | Mechanism |
|------|-----------|
| B1 | Commands stay short/forceful wrappers |
| B2 | Artifact contracts: `codex-review.md` (session ID + VERDICT), `shaping-transcript.md` (two participant voices), spec.md (bead in frontmatter) |
| B5 | prompt-craft skill gets Artifact Contract pattern section |
| B6 | `/help-workflow` command listing commands + their artifacts |

### Known gaps
- R10 for shaping: accepted risk, mitigated by `/shape` being normal entry point
- R10 for workflows-plan: mitigated by `/issue` being canonical, reinforced in napkin
- R4 enforcement: detection via transcript artifact, not prevention via hook

<!-- shape:complete:v1 | harness: pi/claude-sonnet-4-20250514 | date: 2026-03-14T13:59:40Z -->

# Shaping Transcript — 021-cross-agent-compound-learnings

**Date:** 2026-03-14
**Participants:** KeenViper (pi/claude-sonnet-4-20250514, proposer) × NiceBear (crew-challenger)
**Spec:** specs/021-cross-agent-compound-learnings/

---

## KeenViper → NiceBear (spawn prompt)

[PHASE:challenge] Read these files completely:

1. `specs/021-cross-agent-compound-learnings/shaping.md` — the shaping document I've drafted with requirements (R0-R8), three shapes (A, B, C), and a fit check
2. `skills/meta/compound-learnings/SKILL.md` — the current skill being generalized
3. `skills/domain/compound/create-agent-skills/SKILL.md` — one of the 4 overlapping skill-creation skills

Your job: challenge my requirements, shapes, and fit check. Specifically:

- Are any requirements missing? (What implicit constraints haven't I captured?)
- Is my fit check honest? (Did I give Shape A an easy pass?)
- Is Shape B really over-engineered, or does it solve a problem A doesn't?
- Is the R8 consolidation of 4 skills actually "nice-to-have" or is it essential to avoid the same problem recurring?
- Did I miss a shape that would be better than all three?

Be concrete. Cite file contents. Don't rubber-stamp.

---

## NiceBear → KeenViper (challenge)

[PHASE:challenge] I've read all three files completely plus the other 3 overlapping skills (skill-developer, skill-development, skill-creator). Here's my challenge — 6 specific concerns:

**1. Missing Requirement: Input source *write-back* is unspecified (R1 gap)**

R1 says "input sources are agent-agnostic" but compound-learnings doesn't just *read* from `.claude/cache/learnings/` — the whole workflow *produces* learnings files that later runs consume. Step 8 says "Your setup is now permanently improved" but there's no requirement about where the *output learnings cache* goes for non-Claude agents. If Pi runs compound-learnings and creates skills, great — but where does the session analysis itself get cached so future runs don't re-analyze the same sessions? Shape A's ordered detection (A1) handles reads but not writes. You need an R1b: "Session analysis state is persisted in an agent-agnostic location."

**2. Missing Requirement: Skill *testing/validation* is absent**

The skill-creator skill (compound/skill-creator) has a genuine asset Shape A would lose — `scripts/init_skill.py`, `scripts/package_skill.py`, `scripts/quick_validate.py`. These are real executable tooling, not just prose. None of R0-R8 address what happens to these scripts during consolidation. If R8 merges 4 skills into 1, do these scripts come along? Do they get discarded? There's no requirement for preserving executable tooling that currently ships with the overlapping skills. You need an R9: "Executable tooling from consolidated skills is preserved or explicitly deprecated."

**3. The fit check gives Shape A a free pass on R3**

R3 says "agent-specific outputs handled as enhancements, not universal outputs." Shape A's approach (A3, A4) is to move rules to "AGENTS.md/napkin" and hooks to a "Claude Code Enhancements appendix." But look at the actual compound-learnings Step 4 decision tree — it routes patterns to Rules, Hooks, Skills, or Agent Updates based on *what the pattern IS*. Shape A collapses two of those four categories into "just append to AGENTS.md." That's not "handling as an enhancement" — that's *losing output fidelity*. A pattern that should be a hook (automatic gate on an event) isn't the same as a line in AGENTS.md. The fit check should show A as ⚠️ on R3, not ✅.

**4. Shape B isn't over-engineered — it solves a real composition problem**

Your dismissal of B is: "more architecture than the problem warrants — we're editing one skill file, not building a framework." But look at what compound-learnings *actually is*: Steps 2-6 are a reusable pattern analysis methodology that could power other workflows beyond compound-learnings. The shaping doc itself calls the methodology "agent-agnostic and proven." If it's proven and agent-agnostic, extracting it into a composable unit isn't over-engineering — it's recognizing that the methodology has value independent of this one skill.

The real question: do you have *other* workflows that would consume compound-methodology? If yes, B is justified. If compound-learnings is the only consumer, then B is premature. Your fit check doesn't ask this question — it just waves B away with a complexity argument without checking whether the composition benefit is real.

**5. R8 is NOT "nice-to-have" — it's the root cause**

Look at the actual overlap:
- `create-agent-skills` (compound/): 285 lines, Claude Code specific, references `.claude/skills/`, `$CLAUDE_PROJECT_DIR`, Claude-specific frontmatter fields
- `skill-creator` (compound/): 207 lines, Claude-specific, ships with `init_skill.py`/`package_skill.py`/`quick_validate.py`
- `skill-developer` (meta/): 128 lines, references `$CLAUDE_PROJECT_DIR` 10 times, MCP pipeline focused
- `skill-development` (meta/): 34 lines, terse rules, references `.claude/skills/`, `skill-rules.json`

This is the *same problem you're solving for compound-learnings*, happening in 4 places simultaneously. If you generalize compound-learnings (R0-R7) but leave R8 as "nice-to-have," you're creating one generalized skill that *references* a skill-creation process that's still Claude-locked in 4 competing versions. Compound-learnings Step 7 says "For Skills: Create `.claude/skills/<category>/<name>/SKILL.md`" — that creation guidance needs to be canonical and agent-agnostic. If R8 isn't done, R7 is hollow.

Promote R8 to Must-have, or at minimum make it a blocking dependency for R7.

**6. Missing Shape D: Generalize in-place + extract skill-creation into canonical shared skill**

Shape A is the right base but it bundles R8 (skill consolidation) as a simple "merge 4 into 1" without acknowledging that the 4 skills have materially different scopes:

- `create-agent-skills` = Claude-specific skill authoring guide
- `skill-creator` = portable skill authoring process with actual tooling
- `skill-developer` = Claude MCP pipeline skill wrapping
- `skill-development` = terse behavioral rules

A real consolidation isn't "merge" — it's "extract what's shared, deprecate what's Claude-specific, preserve the tooling." A Shape D would be: A1-A7 unchanged, but A8 becomes "create a canonical `create-skill` skill in `meta/` that: (a) uses `~/.agent-config/skills/` paths, (b) preserves `skill-creator`'s init/validate/package scripts, (c) documents agent-specific frontmatter fields as optional Claude enhancements in an appendix, (d) the other 3 skills get deprecation notices pointing to it."

This is different from A8's "merge 4 into 1" because it's *extract + deprecate*, not merge.

**Summary:** I see two real gaps (input write-back, tooling preservation), one dishonest fit check cell (A on R3), one mis-scoped requirement (R8 should be must-have), one under-examined dismissal (B's composition value), and a missing shape that better handles the consolidation.

---

## KeenViper → NiceBear (revise)

[PHASE:revise] Good challenges. Here's my response to each, with revisions where you're right:

**#1 (Input write-back) — Acknowledged but not a separate requirement.**

You're right that this is unspecified. But compound-learnings is a manual on-demand workflow ("compound my learnings"), not a recurring pipeline. There's no queue to consume or state to track. With CASS, you search by date range — `cass search "patterns" --after 2026-03-01 --robot`. With `.learnings/`, files persist and are re-read each run. The "don't re-analyze" concern only matters for automated pipelines, which this isn't. I'll add guidance in Step 1 about date filtering, but it doesn't warrant its own requirement.

**#2 (Executable tooling) — You're right. Adding R9.**

I verified the scripts exist: `init_skill.py` (scaffold), `package_skill.py` (package), `quick_validate.py` (validate). These are real tools, not prose. The consolidation must preserve them. Adding:

> R9: Executable tooling from consolidated skill-creation skills is preserved or explicitly deprecated with rationale.

Status: Must-have (since it gates R8).

**#3 (A on R3 is dishonest) — I disagree. R3 is about handling, not parity.**

Your argument: collapsing hooks into "AGENTS.md lines" loses output fidelity. True — a line in AGENTS.md doesn't auto-fire on events. But Pi, Codex, and Gemini have NO hook mechanism. There is no automatic gate to create. The best any agent without hooks can do is: document the heuristic where the agent will read it (AGENTS.md, napkin). That's not Shape A's design flaw — it's a platform limitation.

R3 says "handled as agent-specific enhancements, not universal outputs." Shape A does exactly that: hooks stay available in the Claude appendix, and for other agents, the *intent* is captured in the most effective universal location (AGENTS.md). I sharpened R3's language:

> R3 (revised): Agent-specific outputs (rules, hooks, agent definitions) available where the agent supports them; intent captured in agent-agnostic locations (AGENTS.md, napkin) where it doesn't.

That's a ✅ for A, not ⚠️.

**#4 (Shape B isn't over-engineered) — I checked. No other consumers exist.**

Searched: `rg "pattern extraction|frequency table|signal threshold|meta-pattern"` across all skills. Only `compound-learnings` itself matches. No other skill references or could reuse the methodology. `self-improving-agent` logs patterns but doesn't analyze them. `workflows-compound` documents solutions but doesn't extract patterns. `cm` does pattern distillation but it's a standalone CLI tool. Shape B is premature extraction with no current consumer.

**#5 (R8 is must-have) — You're right. Promoting.**

R8 is a dependency for R7 to actually work. Promoted to Must-have.

**#6 (Shape D) — Adopting your refinement as a revision to A8.**

Revised A8: Create canonical `create-skill` in `meta/`. Extract shared content. Preserve `skill-creator`'s init/validate/package scripts. Document agent-specific frontmatter fields as optional in appendix. Deprecate the other 3 with notices pointing to the canonical skill. This is Shape A with your A8 refinement — not a new shape since A1-A7 are unchanged.

---

## NiceBear → KeenViper (agree)

[PHASE:agree] Your revisions address all six concerns. Here's my final assessment:

**#1 (Input write-back)** — Accepted. Manual on-demand workflow, CASS date filtering and `.learnings/` persistence handle it.

**#2 (R9)** — Satisfied. R9 as Must-have gating R8 is correct.

**#3 (R3 revised)** — You convinced me. Pi/Codex/Gemini literally cannot create hooks. "Intent captured in AGENTS.md/napkin" is the best possible action on those platforms. The revised R3 language is more honest than both the original and what I proposed. ✅

**#4 (Shape B)** — The `rg` search with zero matches outside compound-learnings is concrete evidence. Premature extraction confirmed.

**#5 (R8 promoted)** — Correct. R8 → R7 dependency chain is real.

**#6 (Revised A8)** — Extract + deprecate + preserve tooling is the right decomposition.

**Shape A (with revised A8, R8 promoted, R9 added) is solid. Proceed.**

Net changes from this challenge:
- R3 language sharpened (intent capture, not output parity)
- R8 promoted to Must-have (dependency for R7)
- R9 added as Must-have (executable tooling preservation)
- A8 revised to extract+deprecate+preserve instead of naive merge
- B and C eliminated with evidence

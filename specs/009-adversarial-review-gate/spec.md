---
title: "Adversarial Review Gate — Structural Honest Critique in Agent Workflows"
date: 2026-03-07
bead: .agent-config-44i
---

# Adversarial Review Gate

## The Incident

During the gj-tool `gj unit` PR review (PR #1), RedEagle validated ZenPhoenix's implementation and reported "All 9 testable requirements PASS." ZenPhoenix confirmed. Both agents declared the PR ready to merge.

Dale's instinct said something was off. He prompted: *"be critical. is it good? does it align with our North Star? is it best in class? is it what Apple would do? does it solve root issues and not symptoms?"*

That single prompt triggered a deep review that found **three real problems hiding in plain sight**:

1. **Flake-skip.conf silently escalated** — Dale committed 12 specific test methods as confirmed flakes. ZenPhoenix broadened it to 7 entire suites, suppressing 74 methods (11.8% of the test suite). 62 passing tests were now invisible. Nobody noticed because the suite-level skip still "worked."

2. **R1 was already solved** — The entire shaping exercise was partly triggered by "Swift Testing tests are invisible to `--filter`." The review proved `-only-testing:` works for Swift Testing on Xcode 26.3 — all 21 `@Test` methods discovered. The napkin entry was stale. Nobody verified the root assumption before building around it.

3. **No graduation mechanism** — Tests go on the flake list but never come off. Write-only suppression with no feedback loop. Apple's XCTExpectFailure alerts you when a flake starts passing; this config does not.

Two of three were fixed immediately. The third was scoped as follow-up. Without Dale's prompt, the PR would have merged with 62 passing tests silently suppressed in CI.

## Root Cause Analysis (§2.5)

**Symptom:** Agent-performed reviews rubber-stamp work. They confirm what they expect to find rather than looking for what could be wrong.

**Why does this happen?** (5 Whys)

1. *Why did RedEagle say 9/9 PASS?* — It ran the test commands, saw passing output, and pattern-matched the results against the requirements checklist.
2. *Why didn't it notice the flake-skip escalation?* — It checked "does `--filter` work?" not "is the flake list what Dale committed?" Verification was surface-level: does the feature work, not is the implementation honest.
3. *Why was verification surface-level?* — The review prompt was implicit: "validate this." Validation frames the task as confirming success, not finding failure. The agent optimized for the frame it was given.
4. *Why does "validate this" produce shallow reviews?* — LLMs have a strong confirmation bias when the surrounding context is congratulatory. ZenPhoenix said "ready to merge," RedEagle said "confirmed," the conversation momentum was toward approval. Reversing that momentum requires explicit adversarial framing.
5. *Why isn't adversarial framing already structural?* — Our workflow has *two-agent gates* but no *adversarial protocol*. Two agents agreeing with each other is not a review — it's groupthink with extra steps. The gate ensures two participants but doesn't ensure one of them is genuinely trying to find problems.

**Root cause:** The review frame is confirmatory, not adversarial. Two-agent gates ensure participation but not critical opposition. There is no structural mechanism that forces a reviewer to *look for problems first* — to verify assumptions, count things, check what actually changed vs what was claimed, and apply the Root-Cause Gate to the review subject itself.

## What "Be Critical" Actually Did (The Protocol That Worked)

Analyzing the chat transcript, Dale's prompt triggered a specific sequence of behaviors that found the bugs. This is the implicit protocol that needs to be made explicit and structural:

### 1. Re-read the actual artifacts, not the claims about them

The agent re-read `cmd_unit()`, `parse_test_results()`, `load_flake_skip_list()` — the actual code, not just the test output. It counted function sizes (33 + 143 + 224 = ~400 lines). Surface review checks "does it work." Deep review reads what was actually written.

### 2. Verify what was claimed against what actually exists

"ZenPhoenix's results said 7 skipped, but my original analysis found 12 individual test methods failing." The agent compared the *current* `flake-skip.conf` against the *committed* version via `git show`. This is the key move — don't trust claims about artifacts, diff the artifacts against their known-good state.

### 3. Count things and check the math

- Counted methods per suite (10 + 11 + 8 + 8 + 2 = 39 additional methods)
- Calculated total suppressed (74 methods)
- Calculated percentage (11.8% of 622 total)
- Counted Swift Testing coverage (151 `@Test` methods across 23 files = ~20%)

Quantification exposes problems that "it works" hides.

### 4. Test assumptions that everyone accepted

"R1 impacts 151 @Test methods across 23 files. `--filter` STILL doesn't work for any of them." Then the agent actually ran the filter — and discovered R1 *already works*. The assumption was never verified, just inherited from a stale napkin entry.

### 5. Apply the Root-Cause Gate to the review subject

"This violates §2.5 (Root Cause Gate). The root cause of flakes is simulator infrastructure, not the test code. Blanket-skipping entire suites is a bandaid that suppresses signal."

### 6. Ask "is this what Apple would do?"

Not as rhetoric — as a genuine design bar. Result bundles = yes (Apple's intended API). Suite-level test suppression = no (Apple provides XCTExpectFailure for exactly this).

## What This Spec Is About

A structural adversarial review protocol that agents follow when reviewing work. Not a suggestion, not a prompt the user remembers to type — a protocol embedded in the workflow commands and available as a standalone skill.

The protocol must be designed so that an agent following it will catch the *class of problems* that RedEagle missed: silent scope changes, unverified assumptions, surface-level validation, and confirmation bias under congratulatory momentum.

## Requirements

### R1: Adversarial Review Skill

A skill (`skills/review/adversarial-review/SKILL.md`) containing the adversarial review protocol. The protocol must include at minimum:

1. **Re-read artifacts, not claims** — Read the actual code/config/output, not summaries of it. Diff current state against known-good state (prior commits, spec, plan).
2. **Verify assumptions** — Identify the top 3 assumptions the work relies on. Test each one. If an assumption was inherited from a napkin, doc, or prior conversation, verify it's still true.
3. **Count and quantify** — For every "it works" claim, quantify the scope: how many tests, what percentage, what changed between versions. Numbers expose what "it works" hides.
4. **Check for silent scope changes** — Diff what was supposed to change (spec/plan) against what actually changed (git diff). Flag anything that changed but wasn't in the plan.
5. **Apply Root-Cause Gate (§2.5)** — Does the implementation solve root causes or symptoms? Apply the bandaid test from AGENTS.md to every non-trivial change.
6. **Test the North Star** — Is this best-in-class? Is this what Apple/industry leader would do? Where does it fall short and why?
7. **Invert the frame** — Instead of "does this work?", start from "what could be wrong?" and work backward. List potential failure modes before checking if they're present.

The skill must be *conversational and emotionally weighted* (per napkin Prompt & Command Craft rule #1), not a checklist that gets speed-run. It should read like a critical colleague, not a form.

### R2: Integration into `/codex-review`

The `/codex-review` command's Codex prompt must include adversarial framing. Currently, Codex is asked to review for "Completeness, Correctness, Risks, Missing steps, Alternatives, Security." This framing is confirmatory — it asks "is anything missing?" not "what's wrong?"

The Codex review prompt should be updated to include:
- "Start by identifying the 3 riskiest assumptions this plan makes. Verify each."
- "What would a skeptical senior engineer's first objection be?"
- "What does this plan NOT address that a production system would need?"
- The specific failure mode from the incident: "Check for scope drift — is the plan doing more or less than the spec requires?"

### R3: Integration into `/implement` validation phase

The navigator role in `/implement` already validates each step. Update the navigator's protocol to apply the adversarial skill when reviewing implementation artifacts — not just "did you test?" but "did you test what you think you tested? Show me the numbers."

### R4: Standalone `/challenge` command

A command (`commands/challenge.md`) that applies the adversarial review protocol to whatever the user points at — a PR, a plan, a piece of code, a claim by another agent. This is the structural equivalent of Dale's "be critical" prompt. Usage:

```
/challenge specs/005-gj-tool-skill-collision
/challenge "RedEagle says all 9 requirements pass"
/challenge  (applies to current conversation context)
```

The command invokes the adversarial review skill, forces a re-read of the relevant artifacts, and produces a structured critique. It is explicitly designed to *find problems*, not confirm success.

### R5: Anti-rubber-stamp language in two-agent gates

All four two-agent commands (`/shape`, `/plan`, `/codex-review`, `/implement`) must include explicit anti-rubber-stamp framing for the second participant. Currently, two agents can agree with each other and produce artifacts that look collaborative but aren't adversarial. The second participant in every two-agent gate must be explicitly told:

- Your job is to find problems, not to agree
- You must include at least one concrete verification (a count, a diff, a grep result, a file check) that demonstrates you actually examined the work, not just the plan/spec
- If you found no problems, explicitly state what you checked and how: "I tried to break this and couldn't — here's what I verified: [list with evidence]"
- "Looks good to me" without evidence of what you checked is not acceptable

This is the difference between a two-agent gate and an adversarial two-agent gate.

## Acceptance Criteria

- [ ] `skills/review/adversarial-review/SKILL.md` exists with the full protocol
- [ ] The protocol catches the *class* of problems from the incident: silent scope changes (flake-skip escalation), unverified assumptions (R1 stale claim), and surface-level validation
- [ ] `/codex-review` prompt includes adversarial framing and assumption-verification language
- [ ] `/implement` navigator role references the adversarial review protocol
- [ ] `/challenge` command exists and works standalone
- [ ] Two-agent gate commands (`/shape`, `/plan`, `/codex-review`, `/implement`) include anti-rubber-stamp language for the second participant
- [ ] The protocol is conversational and emotionally weighted, not a checklisty form
- [ ] Napkin updated with the adversarial review pattern and the incident as a reference case

## Scope Boundary

**In scope:** Adversarial review skill, `/challenge` command, updates to existing workflow commands, anti-rubber-stamp framing in two-agent gates.

**Out of scope:** Changes to pi-messenger or Crew infrastructure. Changes to Codex CLI. Automated enforcement (e.g., blocking merges without adversarial review). CI/CD integration. This is about agent prompting and protocol, not tooling.

## Design Constraints

1. The skill must follow the napkin's Prompt & Command Craft rules — conversational, emotionally weighted, no step-by-step headers for discovery tasks. The adversarial protocol should read like critical thinking, not a compliance checklist.

2. The protocol must be compatible with both Mode 1 (user + agent) and Mode 2 (two agents autonomous). When Dale says "be critical," that's Mode 1. When `/codex-review` runs Codex against a plan, that's Mode 2. The protocol works in both.

3. The `/challenge` command is the user-facing surface for Mode 1. It should be as simple as Dale's original prompt — not a heavyweight process. Point at something, get honest critique.

4. Integration into existing commands must be additive, not disruptive. The two-agent gates already work. This adds adversarial framing to them, it doesn't change their structure.

## Prior Art & References

- **AGENTS.md §2.5 Root-Cause Gate** — The diagnostic already exists for fixes. This spec extends the same thinking to *reviews*: before approving, verify the root assumptions.
- **`/audit-agents` command** — Already adversarial in tone ("agents make characteristic mistakes — plausible-looking code that's subtly wrong"). This spec generalizes that posture to all reviews.
- **The "be critical" prompt** — Dale's exact words that triggered the deep review. The `/challenge` command is the structural equivalent.
- **`/codex-review` iterative loop** — Already has "only Codex can approve" as a hard constraint. This spec adds adversarial framing to what Codex is asked to check.

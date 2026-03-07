---
title: "Plan — Adversarial Review Gate"
date: 2026-03-07
bead: .agent-config-44i
---

# Implementation Plan — Adversarial Review Gate

## Approach Summary

Create an adversarial review protocol as a skill, a standalone `/challenge` command, and bake adversarial framing directly into the four two-agent workflow gates. The skill is the reference artifact; the command is the user-facing shortcut; the workflow gate modifications are structural (agents get the framing whether they want it or not).

**Key design decisions (from BrightHawk challenge session):**

1. **Evidence over opinions.** The anti-rubber-stamp mechanism is "include concrete verification" (a count, a diff, a grep, a file check) — NOT "raise at least one concern." Requiring concerns produces theater. Requiring evidence produces investigation.

2. **Structural where it matters, opt-in where it doesn't.** The four two-agent workflow commands (`/shape`, `/plan`, `/codex-review`, `/implement`) get adversarial framing baked into their command text — that IS the agent's prompt, no opt-in required. The standalone skill and `/challenge` command are opt-in extras for when the user explicitly wants adversarial review.

3. **Don't dilute the codex-review focus list.** The existing 6-item `Focus on:` list stays as-is. A separate "Adversarial Gate" section is added AFTER the standard review with 2-3 pointed questions. Separate section = separate attention, not dilution.

4. **"What I Verified" makes rubber-stamping auditable.** Reviews must include a section with concrete observations from the implementation. This is detectable after the fact — a review with no verification section, or only vague claims, is visibly a rubber stamp.

5. **Incident-grounded examples beat abstract rules.** The skill includes a concrete good-vs-bad evidence comparison from the RedEagle incident so agents have a calibration point.

---

## Deliverables & Insertion Points

### D1: Adversarial Review Skill (CREATE)

**Path:** `skills/review/adversarial-review/SKILL.md`
**Symlink:** `skills/adversarial-review -> review/adversarial-review`

The core protocol artifact. ~80-100 lines, conversational tone. Structure:

- **YAML frontmatter:** name, description (trigger phrases: "challenge this", "be critical", "honest review", "adversarial review")
- **Opening:** The RedEagle incident as a 3-sentence story — what happened, what was missed, what caught it
- **The protocol** — written as thinking posture, not checklist:
  1. Re-read the actual artifacts (code, config, output), not summaries or claims about them
  2. Verify the top 3 assumptions — especially anything inherited from napkin/docs/prior conversation
  3. Count and quantify — for every "it works" claim, put a number on it
  4. Check for silent scope changes — diff what was supposed to change vs what actually changed
  5. Apply Root-Cause Gate (§2.5) — does this solve root causes or symptoms?
  6. Test the North Star — is this what Apple/industry leader would do?
  7. Invert the frame — start from "what could be wrong?" not "does this work?"
- **Output format — "What I Verified":** Concrete evidence section. Include the good-vs-bad example:
  - ❌ BAD: "I reviewed the test output and confirmed all 9 requirements pass." (No specifics. What did you actually check?)
  - ✅ GOOD: "flake-skip.conf has 7 entries but git show ec13566b shows 12 original per-method entries. That's 5 suites added, suppressing 74 methods (11.8% of 622 total). Three suites contain passing tests." (Specific. Auditable. Catches the bug.)
- **Closing:** "If your review doesn't contain a single number, diff, or file check — you didn't review. You rubber-stamped."

**Design constraint:** NO numbered steps. NO "Step 1, Step 2" headers. The protocol reads as a critical thinking posture — "here's how you think when reviewing" not "here are 7 steps to follow." Per napkin Prompt & Command Craft rule #1: conversational, emotionally weighted, short paragraphs with intensifiers.

### D2: `/challenge` Command (CREATE)

**Path:** `commands/challenge.md`

Short, punchy, ~25 lines. Models on `/audit-agents` (18 lines) — the most adversarial existing command. Structure:

- **YAML frontmatter:** description triggers on "challenge", "be critical", "honest assessment"
- **Body:** Points agent at the adversarial review skill path and says "read it completely, follow it, apply it to $ARGUMENTS"
- **Target resolution:** If argument is a spec directory path, read the spec/plan/implementation. If argument is a quote/claim, investigate it. If no argument, apply to current conversation context.
- **Anti-skip:** "DO NOT paraphrase the skill. DO NOT skip the 'What I Verified' section. If your output doesn't contain concrete evidence, you did it wrong."

### D3: `/codex-review` Adversarial Gate Section (MODIFY)

**File:** `commands/codex-review.md`
**Insertion point:** After the existing `Focus on:` list in the Step 3 Codex prompt (line ~110, after item 6 "Security"), add a separate adversarial gate block.

**What to add to the Codex prompt** (inside the prompt string, after the 6 focus items):

```
ADVERSARIAL GATE — answer these BEFORE giving your verdict:
7. What did you verify by reading the actual implementation (not just the plan)? Cite specific files and lines.
8. What is the riskiest assumption this plan makes? Did you test it?
9. Where does the plan's scope differ from the spec's scope? What changed that wasn't in the spec?
```

This is ~4 lines added to the Codex prompt. Separate from the focus list — different heading, different framing. The focus list asks "is anything missing?" The adversarial gate asks "what could be wrong?"

**Also modify Step 4** (Read Codex's Response & Branch on Verdict): After reading Codex's response, check that the adversarial gate questions were answered with specifics. If Codex gave a `VERDICT: APPROVED` but the adversarial gate answers are vague or missing, note this to the user: "Codex approved but didn't provide specific verification evidence for the adversarial gate questions."

### D4: `/implement` Navigator Adversarial Framing (MODIFY)

**File:** `commands/implement.md`
**Insertion point:** After the existing navigator description at lines 31-33 (the paragraph starting "When implementing autonomously..."), add:

```markdown
## The navigator is an adversary, not an ally

The navigator's job is NOT to confirm the driver's work passes. It's to find where it doesn't. When validating a step, the navigator must:
- Read the actual code that was written, not just the test output
- Verify that what changed matches what the plan says should change (diff the PR, not the commit message)
- Include at least one concrete verification in each review: a count, a grep, a file check, a diff

"Did you test?" is not validation. "You ran 21 tests but the plan specified changes to 3 files — show me the coverage" is validation.
```

~8 lines. Inserted as a new subsection after the existing "Implementation is never solo" section, before "How to collaborate with another agent."

### D5: Anti-Rubber-Stamp Paragraph in `/shape` and `/plan` (MODIFY)

**Files:** `commands/shape.md`, `commands/plan.md`
**Insertion point:** After the "never solo" paragraph in each command — specifically after the transcript requirement paragraph in each.

**Identical text in both files:**

```markdown
## The second participant is an adversary, not a yes-person

If you are the second agent in this session, your job is to find problems — not to agree. You must include at least one concrete verification in your challenge: a count, a diff, a grep result, a file check. "Looks good" without evidence of what you actually examined is not acceptable. Two agents agreeing without friction is not collaboration — it's groupthink with extra steps.
```

~5 lines each. Inserted as a new subsection between "never solo" and "How to collaborate with another agent."

### D6: Napkin Update

**File:** `.claude/napkin.md` (this repo's napkin)
**Insertion point:** Add to "Prompt & Command Craft" section.

Add entry:

```
9. **[2026-03-07] Adversarial review requires evidence, not opinions**
   Do instead: When reviewing, the anti-rubber-stamp mechanism is concrete verification (counts, diffs, file checks) — not "raise one concern." Requiring concerns produces theater. Requiring evidence produces investigation. The "What I Verified" section must contain specifics from the implementation. Reference case: RedEagle said 9/9 PASS but never diffed flake-skip.conf against the committed version — would have caught 74 suppressed methods. See spec 009.
```

---

## Requirement Traceability

| Requirement | Deliverable | Structural or Opt-in |
|-------------|-------------|---------------------|
| R1: Adversarial Review Skill | D1 (skill) | Opt-in (reference artifact) |
| R2: `/codex-review` integration | D3 (adversarial gate section) | Structural (in Codex prompt) |
| R3: `/implement` navigator | D4 (navigator framing) | Structural (in command text) |
| R4: `/challenge` command | D2 (command) | Opt-in (user invokes) |
| R5: Anti-rubber-stamp in gates | D4 + D5 (implement, shape, plan) + D3 (codex-review) | Structural (in command text) |

---

## Risks & Mitigations

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Agents skim the added text in commands | Medium | Keep additions short (5-8 lines per command). Emotional weight > length. |
| Adversarial skill becomes speed-run checklist | Medium | Written as thinking posture, not numbered steps. Incident-grounded examples. |
| Verification evidence is vague ("I checked the code") | Medium | Good-vs-bad example in skill provides calibration. "What I Verified" section is auditable. |
| Future commands don't inherit adversarial framing | Low | Pattern is a copyable paragraph. Document in napkin for future command authors. |
| Added Codex prompt text exceeds context | Very Low | Adding ~4 lines to a prompt that's already ~15 lines. Negligible. |

---

## What This Plan Does NOT Do

- Does not modify pi-messenger or Crew infrastructure (out of scope per spec)
- Does not add automated enforcement (no CI gates, no merge blockers)
- Does not change the two-agent gate structure — adds framing to it
- Does not replace `/codex-review` or `/audit-agents` — complements them
- Does not guarantee agents will follow the protocol — makes rubber-stamping detectable and frowned upon, which is the realistic target

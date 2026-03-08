---
title: "Tasks — Adversarial Review Gate"
date: 2026-03-07
bead: .agent-config-44i
---

# Tasks — Adversarial Review Gate

## Task 1: Create adversarial review skill

**Deliverable:** D1
**Files:** `skills/review/adversarial-review/SKILL.md`
**Dependencies:** None

- [x] Create `skills/review/adversarial-review/` directory
- [x] Write `SKILL.md` with YAML frontmatter (name: `adversarial-review`, description with trigger phrases)
- [x] Write the 7-point protocol in conversational voice — NOT numbered steps, NOT checklist headers
- [x] Include RedEagle incident as 3-sentence opening story
- [x] Include good-vs-bad evidence example (❌ "confirmed all 9 pass" vs ✅ "7 entries but git show shows 12, 74 methods suppressed")
- [x] Include "What I Verified" output format requirement
- [x] Include closing: "If your review doesn't contain a single number, diff, or file check — you didn't review"
- [x] Create discovery symlink: `skills/adversarial-review -> review/adversarial-review`
- [x] Verify skill shows up: `ls -la skills/adversarial-review/SKILL.md`

## Task 2: Create `/challenge` command

**Deliverable:** D2
**Files:** `commands/challenge.md`
**Dependencies:** Task 1 (references the skill path)

- [x] Write `commands/challenge.md` with YAML frontmatter
- [x] Body: instruct agent to read the adversarial review skill completely and apply to `$ARGUMENTS`
- [x] Target resolution logic: spec directory → read artifacts; quoted claim → investigate; no arg → current context
- [x] Anti-skip line: "DO NOT paraphrase the skill. If your output doesn't contain concrete evidence, you did it wrong."
- [x] Security redaction note: if target contains secrets/credentials, redact in review output
- [x] Keep it under 30 lines — model on `/audit-agents` tone
- [x] Verify: `cat commands/challenge.md | wc -l` (target: <30)
- [x] Verify all 3 target modes are documented: spec directory path, quoted claim, no argument (current context)
- [x] Read the final command and confirm it references the skill path, has anti-skip language, redaction note, and target resolution

## Task 3: Add adversarial gate to `/codex-review` Codex prompt

**Deliverable:** D3
**Files:** `commands/codex-review.md`
**Dependencies:** None

- [x] In Step 3 Codex prompt: after item 6 ("Security"), add `ADVERSARIAL GATE` block with 4 questions:
  - Identify the 3 riskiest assumptions. Verify each against source code context.
  - What would a skeptical senior engineer's first objection be?
  - What does this plan NOT address that a production system would need?
  - Where does plan scope differ from spec scope?
- [x] Wording must say "source code context" not "implementation" (pre-implementation stage)
- [x] Add no-findings contract to adversarial gate block: "If you found no issues, state what you verified and how — show your work"
- [x] In Step 4 (Read Response): if approved but adversarial gate answers are vague/missing, treat as VERDICT: REVISE and force re-review with specifics
- [x] Do NOT expand the existing 6-item Focus list — keep it separate
- [x] Verify: `grep -c "ADVERSARIAL GATE" commands/codex-review.md` → 1

## Task 4: Add navigator adversarial framing to `/implement`

**Deliverable:** D4
**Files:** `commands/implement.md`
**Dependencies:** None

- [x] Add "The navigator is an adversary, not an ally" subsection after "Implementation is never solo" section (after line ~33)
- [x] Include: read actual code not test output, diff PR not commit message, include concrete verification
- [x] Include the calibration example: "'Did you test?' is not validation. 'You ran 21 tests but the plan specified changes to 3 files — show me the coverage' is validation."
- [x] Include explicit skill reference: "For the full adversarial review protocol, read: `<skill path>`"
- [x] Keep addition to ~10 lines
- [x] Verify: command still reads coherently end-to-end (no awkward breaks)

## Task 5: Add anti-rubber-stamp paragraph to `/shape` and `/plan`

**Deliverable:** D5
**Files:** `commands/shape.md`, `commands/plan.md`
**Dependencies:** None

- [x] In `commands/shape.md`: add "The second participant is an adversary, not a yes-person" subsection after transcript paragraph, before "How to collaborate" section
- [x] In `commands/plan.md`: add identical subsection in same position
- [x] Text: requires concrete verification (count, diff, grep, file check), "Looks good" without evidence is not acceptable, groupthink warning
- [x] Include no-findings contract: "If you found no problems, state what you verified and how"
- [x] Keep addition to ~7 lines each
- [x] Verify: both commands still read coherently end-to-end

## Task 6: Update napkin

**Deliverable:** D6
**Files:** `.claude/napkin.md`
**Dependencies:** Tasks 1-5 (records the pattern after it's established)

- [x] Add entry #9 to "Prompt & Command Craft" section: adversarial review requires evidence not opinions
- [x] Reference spec 009 and the RedEagle incident
- [x] Verify: `grep "adversarial" .claude/napkin.md`

## Task 7: Proof pass — validate protocol against known incident

**Dependencies:** Tasks 1-5
**Files:** `specs/009-adversarial-review-gate/proof-pass.md` (created during verification)

- [x] Apply the adversarial review skill to the RedEagle incident and write a brief verification note in the spec directory (`specs/009-adversarial-review-gate/proof-pass.md`) showing:
  - Point 1 (re-read artifacts): Would have caught flake-skip.conf escalation by reading the actual file ← cite the exact protocol line
  - Point 2 (verify assumptions): Would have caught R1 stale claim by testing the filter ← cite the exact protocol line
  - Point 3 (count/quantify): Would have caught 74 suppressed methods (11.8%) ← cite the exact protocol line
  - For each point: would the protocol have triggered this investigation, or is it too vague?
- [x] Review the "What I Verified" good-vs-bad example: is it specific enough to calibrate an agent?
- [x] Read each modified command end-to-end: does the adversarial framing flow naturally or feel bolted-on?
- [x] Verify the codex-review adversarial gate wording says "source code context" not "implementation" (pre-implementation stage)
- [x] Verify each gate text includes the no-findings contract ("If you found no problems, state what you verified and how")

## Task 8: Commit and verify

**Dependencies:** Tasks 1-7

- [x] `git add` all new/modified files
- [x] Commit: `feat: adversarial review gate — skill, /challenge command, workflow gate updates`
- [x] Verify symlink works: `ls skills/adversarial-review/SKILL.md`
- [x] Verify commands parse: check no broken markdown in modified commands
- [x] Update `log.md`: record /implement completion

---

## Task Order

Tasks 1, 3, 4, 5 have no dependencies on each other and could be done in parallel.
Task 2 depends on Task 1 (needs skill path to reference).
Task 6 depends on Tasks 1-5 (records the pattern).
Task 7 depends on Tasks 1-5 (proof pass).
Task 8 depends on all.

**Recommended serial order:** 1 → 2 → 3 → 4 → 5 → 6 → 7 → 8

This order builds the core artifact first (skill), then the command that references it, then the structural modifications to existing commands, then the napkin update, then proof pass, then commit.

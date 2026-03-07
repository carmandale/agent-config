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

- [ ] Create `skills/review/adversarial-review/` directory
- [ ] Write `SKILL.md` with YAML frontmatter (name: `adversarial-review`, description with trigger phrases)
- [ ] Write the 7-point protocol in conversational voice — NOT numbered steps, NOT checklist headers
- [ ] Include RedEagle incident as 3-sentence opening story
- [ ] Include good-vs-bad evidence example (❌ "confirmed all 9 pass" vs ✅ "7 entries but git show shows 12, 74 methods suppressed")
- [ ] Include "What I Verified" output format requirement
- [ ] Include closing: "If your review doesn't contain a single number, diff, or file check — you didn't review"
- [ ] Create discovery symlink: `skills/adversarial-review -> review/adversarial-review`
- [ ] Verify skill shows up: `ls -la skills/adversarial-review/SKILL.md`

## Task 2: Create `/challenge` command

**Deliverable:** D2
**Files:** `commands/challenge.md`
**Dependencies:** Task 1 (references the skill path)

- [ ] Write `commands/challenge.md` with YAML frontmatter
- [ ] Body: instruct agent to read the adversarial review skill completely and apply to `$ARGUMENTS`
- [ ] Target resolution logic: spec directory → read artifacts; quoted claim → investigate; no arg → current context
- [ ] Anti-skip line: "DO NOT paraphrase the skill. If your output doesn't contain concrete evidence, you did it wrong."
- [ ] Keep it under 30 lines — model on `/audit-agents` tone
- [ ] Verify: `cat commands/challenge.md | wc -l` (target: <30)

## Task 3: Add adversarial gate to `/codex-review` Codex prompt

**Deliverable:** D3
**Files:** `commands/codex-review.md`
**Dependencies:** None

- [ ] In Step 3 Codex prompt: after item 6 ("Security"), add `ADVERSARIAL GATE` block with 3 questions:
  - What did you verify by reading actual implementation? Cite files/lines.
  - What is the riskiest assumption? Did you test it?
  - Where does plan scope differ from spec scope?
- [ ] In Step 4 (Read Response): add check that adversarial gate was answered with specifics. If approved but vague, note it to user.
- [ ] Do NOT expand the existing 6-item Focus list — keep it separate
- [ ] Verify: `grep -c "ADVERSARIAL GATE" commands/codex-review.md` → 1

## Task 4: Add navigator adversarial framing to `/implement`

**Deliverable:** D4
**Files:** `commands/implement.md`
**Dependencies:** None

- [ ] Add "The navigator is an adversary, not an ally" subsection after "Implementation is never solo" section (after line ~33)
- [ ] Include: read actual code not test output, diff PR not commit message, include concrete verification
- [ ] Include the calibration example: "'Did you test?' is not validation. 'You ran 21 tests but the plan specified changes to 3 files — show me the coverage' is validation."
- [ ] Keep addition to ~8 lines
- [ ] Verify: command still reads coherently end-to-end (no awkward breaks)

## Task 5: Add anti-rubber-stamp paragraph to `/shape` and `/plan`

**Deliverable:** D5
**Files:** `commands/shape.md`, `commands/plan.md`
**Dependencies:** None

- [ ] In `commands/shape.md`: add "The second participant is an adversary, not a yes-person" subsection after transcript paragraph, before "How to collaborate" section
- [ ] In `commands/plan.md`: add identical subsection in same position
- [ ] Text: requires concrete verification (count, diff, grep, file check), "Looks good" without evidence is not acceptable, groupthink warning
- [ ] Keep addition to ~5 lines each
- [ ] Verify: both commands still read coherently end-to-end

## Task 6: Update napkin

**Deliverable:** D6
**Files:** `.claude/napkin.md`
**Dependencies:** Tasks 1-5 (records the pattern after it's established)

- [ ] Add entry #9 to "Prompt & Command Craft" section: adversarial review requires evidence not opinions
- [ ] Reference spec 009 and the RedEagle incident
- [ ] Verify: `grep "adversarial" .claude/napkin.md`

## Task 7: Commit and verify

**Dependencies:** Tasks 1-6

- [ ] `git add` all new/modified files
- [ ] Commit: `feat: adversarial review gate — skill, /challenge command, workflow gate updates`
- [ ] Verify symlink works: `ls skills/adversarial-review/SKILL.md`
- [ ] Verify commands parse: check no broken markdown in modified commands
- [ ] Update `log.md`: record /implement completion

---

## Task Order

Tasks 1, 3, 4, 5 have no dependencies on each other and could be done in parallel.
Task 2 depends on Task 1 (needs skill path to reference).
Task 6 depends on Tasks 1-5 (records the pattern).
Task 7 depends on all.

**Recommended serial order:** 1 → 2 → 3 → 4 → 5 → 6 → 7

This order builds the core artifact first (skill), then the command that references it, then the structural modifications to existing commands, then the napkin update, then commit.

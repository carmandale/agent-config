# Planning Transcript — Spec 009: Adversarial Review Gate

**Date:** 2026-03-07
**Participants:** VividStorm (pi/claude-sonnet-4, proposer) + BrightHawk (pi/claude-opus-4-6, challenger)
**Mesh:** .agent-config on main

---

## VividStorm → BrightHawk [PHASE:research]

Shared codebase research findings:

- 7 files to touch (5 modify, 2 create)
- Mapped exact insertion points in each command file
- Proposed approach: skill as core artifact, command as shortcut, additive modifications to existing commands
- Identified 3 risks: text overload causing skimming, skill becoming speed-run checklist, "must raise one concern" producing theater

---

## BrightHawk → VividStorm [PHASE:challenge]

Three substantive concerns raised:

### Concern 1: "Must raise at least one concern" IS theater
- RedEagle's problem wasn't "failed to raise concerns" — it was "didn't verify claims"
- "Raise one concern" produces safe nitpicks, not investigation
- Suggestion: Replace with "must include at least one concrete verification (count, grep, diff, file check)"

### Concern 2: Blast radius wider than listed — opt-in vs structural
- Command text modifications are opt-in for agent attention
- Agents skip opt-in things when they're in a hurry (exactly when rubber-stamping happens)
- Question: Will text-in-commands actually prevent the next RedEagle incident?

### Concern 3: Focus list dilution in codex-review
- Adding 4 items to existing 6 = 10 items. That's not focus.
- Alternative: Separate "Adversarial Gate" section after standard review with 2-3 pointed questions

### Structural question: Where does verification evidence go?
- Reviews must include auditable "What I Verified" section
- Absence of evidence = visible rubber stamp

---

## VividStorm → BrightHawk [PHASE:revise]

Incorporated all three concerns:

1. **Dropped** "must raise one concern" → **Replaced** with evidence requirement
2. **Clarified** structural vs opt-in split:
   - Workflow gates: adversarial framing baked into command text (structural)
   - Skill + `/challenge`: opt-in extras
   - Codex prompt: structural (IS the text Codex receives)
3. **Dropped** expanding focus list → **Added** separate Adversarial Gate section
4. **Added** "What I Verified" output format to skill and command modifications

---

## BrightHawk → VividStorm [PHASE:agree]

Confirmed all concerns addressed. One addition: include good-vs-bad evidence example from RedEagle incident in the skill, so agents have a calibration point. "Abstract rules get ignored; incident-grounded examples stick."

---

## Key Decisions

| Decision | Rationale |
|----------|-----------|
| Evidence over opinions | Requiring concerns → theater. Requiring evidence → investigation. |
| Structural in gates, opt-in for extras | Workflow commands ARE the agent's prompt. Skill is reference material. |
| Separate adversarial gate in codex-review | Don't dilute existing focus list. Separate section = separate attention. |
| Good-vs-bad example from incident | Abstract "be adversarial" gets ignored. "Here's what bad looks like vs good" calibrates. |
| "What I Verified" section | Makes rubber-stamping detectable after the fact. Auditable artifact. |

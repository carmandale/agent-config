# Proof Pass — Adversarial Review Protocol vs RedEagle Incident

**Date:** 2026-03-07
**Purpose:** Validate that the adversarial review skill would have caught the 3 problems RedEagle missed.

---

## Problem 1: Flake-skip.conf silently escalated (12 methods → 74 methods)

**Protocol point that catches it:** "Read the artifacts, not the claims about them" — *"Go read X. Read the actual code, the actual config... Diff the current version against the previous version with `git show` or `git diff`."*

**Would it trigger?** YES. The protocol explicitly says to diff current state against known-good state. An agent following this would run `git show ec13566b:.gj/flake-skip.conf` vs `cat .gj/flake-skip.conf` and immediately see 12 per-method entries became 7 per-suite entries.

**Protocol point that amplifies it:** "Put a number on it" — *"How many tests ran? What percentage of the suite?"*

**Would it quantify the impact?** YES. Counting methods per suite (10+11+8+8+2 = 39 additional) and calculating 74/622 = 11.8% is exactly what the protocol demands.

## Problem 2: R1 (Swift Testing filter) was already solved

**Protocol point that catches it:** "Verify the assumptions everyone accepted" — *"Pick the top three assumptions and test them. Actually test them — run the command, read the doc, check the version."*

**Would it trigger?** YES. The protocol explicitly targets assumptions "inherited from napkin entries, prior conversations, older specs." The R1 assumption ("Swift Testing is invisible to --filter") was a napkin entry. An agent following this would run `gj unit orchestrator --filter "orchestratorTests/ContentPlanPrefetchTests"` and discover it works on Xcode 26.3.

## Problem 3: No graduation mechanism for flake list

**Protocol point that catches it:** "Test the North Star" — *"Is this what Apple would do?... Apple provides `XCTExpectFailure` for exactly the flake-skip use case."*

**Would it trigger?** PARTIALLY. The North Star test surfaces the design gap, but the protocol doesn't explicitly call out "write-only configs." An agent would need to connect "what would Apple do" to "Apple has XCTExpectFailure." The protocol gives the frame; domain knowledge fills the gap.

---

## "What I Verified" example calibration check

**❌ BAD example:** "I reviewed the test output and confirmed all 9 requirements pass." — Is this specific enough to recognize as bad? **YES.** No files, no numbers, no diffs. An agent reading this example should immediately see the contrast.

**✅ GOOD example:** "flake-skip.conf has 7 entries but `git show ec13566b` shows 12 original per-method entries..." — Is this specific enough to calibrate? **YES.** File name, git command, specific numbers, calculation. Clearly different from the bad example.

---

## Command coherence check

| Command | Adversarial framing flows naturally? | No-findings contract present? |
|---------|--------------------------------------|-------------------------------|
| `/shape` | ✅ Fits between "never solo" and "how to collaborate" | ✅ "Silence is not approval" |
| `/plan` | ✅ Same position, same text | ✅ Same |
| `/implement` | ✅ New section after navigator role description | ✅ "Silence is not approval" + skill reference |
| `/codex-review` | ✅ Separate ADVERSARIAL GATE block after focus list | ✅ "Show your work" + vague→REVISE enforcement |

All commands read coherently end-to-end. The adversarial framing is additive, not disruptive.

## Codex-review wording check

- ✅ Says "source code context" not "implementation" (line: "did you verify it against the source code context?")
- ✅ Has non-verifiable fallback ("If an assumption is not directly verifiable from source context, state why")

---

**Verdict:** Protocol covers all 3 incident problems. Problem 3 coverage is partial (depends on domain knowledge), which is acceptable — the protocol can't contain all Apple API knowledge, but it provides the thinking frame that leads there.

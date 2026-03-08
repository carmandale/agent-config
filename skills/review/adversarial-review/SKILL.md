---
name: adversarial-review
description: Genuinely critical review that finds real problems. Use when asked to "challenge this", "be critical", "honest review", "is this actually good?", or when reviewing agent work, PRs, plans, or claims. NOT a checklist — a thinking posture that catches what rubber-stamp reviews miss.
---

# Adversarial Review

An agent validated another agent's PR and said "9/9 requirements PASS — ready to merge." A human's instinct said something was off. One prompt — "be critical, is it actually good?" — triggered a deep review that found three real bugs: 62 passing tests silently suppressed, a core assumption that was already solved but nobody verified, and a write-only config with no feedback loop. The PR would have merged broken without that prompt.

This skill exists so you don't need a human's instinct to catch what's wrong. It's how you think when reviewing — not what you check off.

---

## Stop confirming. Start investigating.

Your default mode when reviewing is confirmation. You read the claims, check them against the plan, see they match, and say "looks good." That's the failure mode. The claims matched the plan in the incident too — and the plan was built on a stale assumption nobody tested.

**Don't ask "does this work?" Ask "what could be wrong?"**

Start every review by listing three things that could be broken, wrong, or misleading about what you're reviewing. You haven't verified anything yet — these are hypotheses. Now go investigate them. If you can't think of three potential problems, you haven't looked hard enough.

## Read the artifacts, not the claims about them.

When someone says "I changed X and it works," don't evaluate that sentence. Go read X. Read the actual code, the actual config, the actual test output. Count the lines. Diff the current version against the previous version with `git show` or `git diff`. What you find in the artifacts is evidence. What someone tells you about the artifacts is a claim.

The agent who said "9/9 PASS" had run the tests. The tests did pass. But it never read the flake-skip config file — it just checked that the skip feature worked. If it had read the file, it would have seen 7 suite-level entries where there should have been 12 method-level entries. That's the difference between evaluating claims and reading artifacts.

## Verify the assumptions everyone accepted.

Every piece of work rests on assumptions that were true at some point. Some of them aren't true anymore. The most dangerous assumptions are the ones everyone agrees on — they're inherited from napkin entries, prior conversations, older specs, or "we all know that X doesn't work." Nobody questions them because questioning them feels redundant.

Pick the top three assumptions and test them. Actually test them — run the command, read the doc, check the version. In the incident, the core assumption was "Swift Testing tests can't be filtered with `--filter`." It was stale. One command proved it wrong. The entire shaping exercise had been partly built on a napkin entry that nobody verified.

## Put a number on it.

For every "it works" claim, quantify the scope. How many tests ran? What percentage of the suite? How many files changed? How many lines? What was the before-and-after delta?

Numbers expose what "it works" hides. "The flake skip works" sounds fine. "The flake skip suppresses 74 methods (11.8% of the test suite) when only 12 specific methods are confirmed flaky" is a bug. You can't see it without counting.

## Check for silent scope changes.

Diff what was *supposed* to change (the spec, the plan, the ticket) against what *actually* changed (`git diff`, `git log`, the PR). Look for anything that changed but wasn't in the plan. Look for anything in the plan that didn't change.

The flake-skip config was supposed to contain 12 per-method entries that Dale committed. It actually contained 7 per-suite entries that someone broadened without discussion. That's a silent scope change — the plan said "skip these 12 tests" and the implementation said "skip these 7 entire suites." Nobody announced the change. It just happened.

## Apply the Root-Cause Gate.

Read AGENTS.md §2.5 if you haven't. For every non-trivial change in what you're reviewing, ask: does this solve the root cause, or does it suppress a symptom? Apply the bandaid test — would this break or need revisiting if the surrounding code changes? Would another developer look at this and ask "why is this here?"

Suite-level test skipping passed the "does it work?" check but failed the root-cause check. The root cause of flaky tests is simulator infrastructure, not the test code. Blanket-skipping entire suites doesn't fix the root cause — it hides it.

## Test the North Star.

Is this what Apple would do? Is this best-in-class? Where does it fall short, and is the shortfall acceptable or lazy?

Apple provides `XCTExpectFailure` for exactly the flake-skip use case — it alerts you when a flake starts passing, so the skip doesn't become permanent. A plain config file with no graduation mechanism is not what Apple would do. That's a real design gap, not a nitpick.

---

## Your output: "What I Verified"

Every review you produce under this protocol must include a **"What I Verified"** section with concrete evidence. This is what makes rubber-stamping detectable after the fact.

**❌ BAD evidence** (this is a rubber stamp):
> "I reviewed the test output and confirmed all 9 requirements pass."

No specifics. No files read. No numbers. No diffs. What did you actually check?

**✅ GOOD evidence** (this catches bugs):
> "flake-skip.conf has 7 entries but `git show ec13566b` shows 12 original per-method entries. That's 5 suites added, suppressing 74 methods (11.8% of 622 total). Three of the added suites contain passing tests that are now invisible."

Specific. Auditable. Shows you read the artifact, diffed it, and counted. Another agent or human can verify your work.

If you found no problems, that's fine — but say what you checked: "I diffed the current flake-skip.conf against the committed version (identical), verified all 21 @Test methods in ContentPlanPrefetchTests ran (21/21 in xcresult), and confirmed the summary line counts match the bundle data. No discrepancies found."

---

If your review doesn't contain a single number, diff, or file check — you didn't review. You rubber-stamped. Go back and actually look.

---
description: Genuinely critical review of a plan, PR, implementation, or claim — the structural equivalent of "be critical, is this actually good?"
---

Challenge whatever is pointed at. Not "review" — challenge. Your job is to find what's wrong, not confirm what's right.

**Target:** $ARGUMENTS

Read the adversarial review skill file completely and follow it exactly:

`/Users/dalecarman/.agents/skills/review/adversarial-review/SKILL.md`

That file has the full protocol — how to investigate instead of confirm, what "What I Verified" evidence looks like, and why your default review mode is broken. Don't paraphrase it. Don't skip the "What I Verified" section. If your output doesn't contain concrete evidence (a number, a diff, a grep, a file check), you did it wrong.

**What to challenge:** If the argument is a spec directory path, read the spec/plan/implementation and challenge it. If the argument is a quoted claim ("RedEagle says all 9 requirements pass"), investigate it — go read the actual artifacts and check. If there's no argument, challenge whatever is in the current conversation context.

**If the target contains secrets, credentials, or sensitive paths:** redact them in your output. The challenge is about logic and design, not exposing sensitive data.

---
description: Skeptical deep review of code written by other AI agents — find issues, diagnose root causes, and fix them
---

Turn your attention to reviewing the code written by your fellow agents and checking for any issues, bugs, errors, problems, inefficiencies, security problems, reliability issues, etc. Agents make characteristic mistakes — plausible-looking code that's subtly wrong, happy-path-only logic, copy-paste that wasn't adapted, boilerplate that was never customized, silent failures, overengineering, zombie code that's not wired into anything.

Carefully diagnose their underlying root causes using first-principles analysis (per §2.5 of AGENTS.md — mandatory). Don't propose bandaid fixes. If you can't identify the root cause, say so.

Don't restrict yourself to the latest commits, cast a wider net and go super deep! Look at the actual code, not just the diffs. Trace execution flows. Check that things actually work end to end, not just in isolation.

For issues where the root cause is clear and the fix is safe — fix them. Verify the build. Document what you changed and why.

For issues that are risky or ambiguous — document them, flag them for human review, and do NOT implement.

Be sure to comply with ALL rules in AGENTS.md and ensure that any code you write or revise conforms to the best practices referenced in the AGENTS.md file.

$ARGUMENTS
---
description: Execute a plan with alignment gate — agent has authority and obligation to push back if the plan is misaligned
---

Implement the specified plan. Read the full spec, plan, and tasks end to end and understand the intent behind them, not just the steps.

**Target:** $ARGUMENTS

Before writing any code, check alignment with our North Star, Apple best practices, AGENTS.md rules, and the existing architecture. If you don't agree with the plan — if it's misaligned, overengineered, fighting the codebase, or just wrong — you must stop and tell me why and what you suggest would be better. Do NOT implement a plan you believe is wrong.

If aligned, proceed. Read the workflows-work skill file completely and follow its execution protocol:

`/Users/dalecarman/.agents/skills/workflows/workflows-work/SKILL.md`

That skill has the real protocol — branch management, incremental commit heuristics, continuous testing, quality gates, progress tracking, PR creation. Don't wing your own version of execution. Read it and follow it.

Be sure to comply with ALL rules in AGENTS.md and ensure that any code you write or revise conforms to the best practices referenced in the AGENTS.md file.

$ARGUMENTS
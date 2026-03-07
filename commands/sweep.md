---
description: Deep code exploration and bug hunting — randomly investigate code files, trace execution flows, find issues, then create a numbered spec with plan and tasks
---

Strictly adhere to the `specs/` artifact rules defined in README.md.

I want you to sort of randomly explore the code files in this project, choosing code files to deeply investigate and understand and trace their functionality and execution flows through the related code files which they import or which they are imported by. Don't gravitate toward the obvious entry points — dig into the plumbing, the glue code, the error handling, the stuff nobody looks at. That's where bugs live.

Once you understand the purpose of the code in the larger context of the workflows, I want you to do a super careful, methodical, and critical check with "fresh eyes" to find any obvious bugs, problems, errors, issues, silly mistakes, etc. Don't just check boxes — actually look. If something feels off, chase it. Trace it to the root cause (per §2.5 of AGENTS.md — this is mandatory, not optional).

Every finding must include the specific file path, line numbers, and the actual code involved. No vague claims like "there might be error handling issues." Show me the exact code that's wrong and explain exactly why it's wrong. If you can't point to specific lines, you didn't actually find anything.

Then systematically and meticulously and intelligently create a numbered spec/plan/tasks to correct them. Be sure to comply with ALL rules in AGENTS.md and ensure that any code you write or revise conforms to the best practices referenced in the AGENTS.md file.

Only create the spec, plan, and tasks in the appropriate `./specs/` folder as a new numbered spec. Create a bead for the work and add the bead ID to the spec frontmatter.

Do NOT implement any fixes. Wait for explicit approval before implementing. Once approved, you'd typically run `/codex-review <spec>` for an independent review of the plan, then `/implement <spec>` to build it.

Strictly adhere to the `specs/` artifact rules defined in README.md, including creating a bead for the work.

$ARGUMENTS
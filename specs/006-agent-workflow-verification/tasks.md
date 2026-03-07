---
title: "Tasks: Agent workflow verification"
date: 2026-03-07
bead: .agent-config-gfi
---

# Tasks

- [ ] 1. Add next-step suggestion to `/ground` — one sentence after "What are we working on?" pointing to typical commands by intent
- [ ] 2. Add next-step suggestion to `/sweep` — after "wait for approval," suggest `/codex-review <spec>` then `/implement <spec>`
- [ ] 3. Add next-step suggestion to `/audit-agents` — suggest reviewing fixes or `/codex-review` if spec produced
- [ ] 4. Add Artifact Contracts section to `skills/meta/prompt-craft/SKILL.md` — define the pattern with content markers for codex-review.md, shaping-transcript.md, and spec.md frontmatter
- [ ] 5. Create `commands/help-workflow.md` — conversational listing of all commands, typical order, and artifacts produced
- [ ] 6. Update napkin — add entry about artifact contracts and next-step suggestions
- [ ] 7. Commit and verify all commands accessible via symlinks

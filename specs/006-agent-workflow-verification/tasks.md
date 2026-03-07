---
title: "Tasks: Agent workflow verification"
date: 2026-03-07
bead: .agent-config-gfi
---

# Tasks

## Change 1: Next-step suggestions
- [ ] 1. `/ground` — add one sentence after "What are we working on?" suggesting commands by intent
- [ ] 2. `/sweep` — add one sentence after "wait for approval" suggesting `/codex-review` then `/implement`
- [ ] 3. `/audit-agents` — add one sentence at end suggesting `/issue` + `/codex-review` if spec warranted, or commit if direct fixes
- [ ] 4. `/codex-review` — add one sentence after approval flow explicitly naming `/implement <spec>`

## Change 2: Artifact Contracts
- [ ] 5. Add content markers to existing "Anchor Trust in Artifacts" section in `skills/meta/prompt-craft/SKILL.md` — specific required content for codex-review.md, shaping-transcript.md, spec.md frontmatter, plus pattern guidance for future commands

## Change 3: Help
- [ ] 6. Create `commands/help-workflow.md` — conversational listing of all 7 commands, typical order, and artifacts each produces

## Change 4: Napkin
- [ ] 7. Add napkin entry for artifact contracts and next-step suggestions as standard command patterns

## Verification
- [ ] 8. All new/changed commands accessible via symlinks (claude, pi, codex)
- [ ] 9. Commit all changes

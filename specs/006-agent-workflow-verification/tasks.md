<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Status: RECONCILED -->
<!-- Revisions: Added codex-review to Change 1 scope, added verification tasks from Codex feedback -->
---
title: "Tasks: Agent workflow verification"
date: 2026-03-07
bead: .agent-config-gfi
---

# Tasks

## Change 1: Next-step suggestions
- [ ] 1. `/ground` — add one sentence after "What are we working on?" suggesting commands by intent (use "typically")
- [ ] 2. `/sweep` — add one sentence after "wait for approval" suggesting `/codex-review` then `/implement` (use "typically")
- [ ] 3. `/audit-agents` — add one sentence at end suggesting `/issue` + `/codex-review` if spec warranted, or commit if direct fixes
- [ ] 4. `/codex-review` — add one sentence after approval flow explicitly naming `/implement <spec>` (use "typically")

## Change 2: Artifact Contracts
- [ ] 5. Add content markers to existing "Anchor Trust in Artifacts" section in prompt-craft skill — specific required content for codex-review.md, shaping-transcript.md, spec.md frontmatter + redaction note + pattern guidance for future commands

## Change 3: Help
- [ ] 6. Create `commands/help-workflow.md` — conversational listing of all 7 commands, typical order, and artifacts each produces

## Change 4: Napkin
- [ ] 7. Add napkin entry for artifact contracts and next-step suggestions

## Change 5: Verification
- [ ] 8. Commands: verify all 5 changed/new command files via `ls` at `~/.claude/commands/`, `~/.pi/agent/prompts/`, `~/.codex/prompts/`
- [ ] 9. Skill: verify prompt-craft via `ls` at `~/.agents/skills/` and `~/.claude/skills/`
- [ ] 10. Gemini: verify 5 TOML files exist + `grep -q` per file for expected content ("typically" or "workflow")
- [ ] 11. Commit all changes

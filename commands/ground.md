---
description: Ground yourself in this project - deeply read instructions and investigate the codebase before doing anything else
---

Before doing any work, fully orient yourself in this project. This is not optional and must not be skimmed.

## Step 1: Read Global Instructions

Read the ENTIRE `~/.agent-config/instructions/AGENTS.md` file carefully. Do not skim. Internalize the non-negotiables, workflows, and guardrails. They apply to everything you do in this session.

## Step 2: Read Project README

Read the repo's `./README.md` (or equivalent top-level documentation) end to end. Understand:
- What this project is and why it exists
- How it's structured
- Key concepts and terminology

## Step 3: Read Project-Level Agent Instructions

Check for and read any project-specific instruction files:
- `.claude/CLAUDE.md`
- `AGENTS.md` (in repo root)
- `.cursor/rules/`
- Any other agent configuration in the repo

## Step 4: Investigate the Codebase

Use your code investigation capabilities to build a real understanding of the technical architecture:

1. **Map the structure** — directory layout, key entry points, module boundaries
2. **Identify the core abstractions** — what are the main types, protocols, services?
3. **Understand the data flow** — how does information move through the system?
4. **Note the conventions** — naming patterns, error handling, testing approach
5. **Check recent activity** — `git log --oneline -15` to see what's been happening

## Step 5: Read Napkin & Handoffs

```bash
cat .claude/napkin.md 2>/dev/null || echo "No napkin found"
ls thoughts/shared/handoffs/ 2>/dev/null && cat thoughts/shared/handoffs/current.md 2>/dev/null || echo "No handoffs found"
```

## Step 6: Confirm Grounding

Once complete, output a brief grounding summary:

```markdown
## Grounded

**Project**: [name] — [one-line purpose]
**Architecture**: [key architectural pattern in 1-2 sentences]
**Key modules**: [list 3-5 core areas]
**Recent focus**: [what recent commits suggest is active work]
**Active constraints**: [any non-obvious rules from AGENTS.md or project config that are especially relevant here]
```

Then ask: "What are we working on?" For new work, you'd typically start with `/shape` to explore the problem or `/issue` to create a tracked spec. For bug hunting, try `/sweep`. For reviewing agent-written code, try `/audit-agents`.

$ARGUMENTS
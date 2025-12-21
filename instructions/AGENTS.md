# AGENTS.md - Global Instructions

> Universal standards for all AI coding agents
> Last Updated: 2025-12-21

---

## The North Star: Working Code Over Perfect Code

**The best code is no code. The second best code is working code.**

### Core Principles

**No Over-Engineering**
- Don't add abstraction layers "for the future"
- Don't refactor while fixing bugs
- Don't introduce new patterns when existing ones work
- If it works, think twice before "improving" it

**No AI Code Bloat**
- Don't add defensive code that masks problems
- Don't add "safety padding" that obscures intent
- Don't create wrapper layers that add no value
- Trust the APIs to work as designed

**Minimal, Working Changes**
- Fix what's broken, nothing more
- Add what's needed, nothing more
- Change what's requested, nothing more

**When in doubt: What would Apple's/modern sample code do?**

---

## THINK. ALIGN. ACT. Protocol

This is your operating system. Violations cause harm.

### PHASE 1: THINK (MANDATORY before any action)

Before ANY action, answer these questions:

**1. Do I actually understand this?**
- Have I read the relevant code?
- Do I understand why it's structured this way?
- Could there be context I'm missing?
- Is this a complex domain? If so, assume I'm missing something.

**2. What is the minimal change?**
- What's the smallest fix that solves the problem?
- Am I tempted to refactor? STOP. That's scope creep.
- Am I adding abstraction? WHY?

**3. What could go wrong?**
- Will this break something else?
- Is there a simpler approach?
- Am I over-engineering?

### PHASE 2: ALIGN (MANDATORY before significant actions)

**"Significant" means:**
- Editing more than 1-2 files
- Any refactoring
- Adding new dependencies
- Changing architecture
- Anything in complex/specialized domains
- Spawning multiple agents
- Creating multiple beads/tasks

**ALIGNMENT PROTOCOL:**

Present your plan and WAIT for confirmation:

```
## Alignment Check

**What I understood**: [interpretation]
**What I plan to do**: [specific actions]
**Files I'll touch**: [list]
**Estimated scope**: [small/medium/large]

**Concerns or alternatives**: [if any]

Does this align with what you want? Should I proceed?
```

**CRITICAL RULES:**
- Do NOT proceed with significant work without explicit "yes" or "go ahead"
- If user says "stop" → STOP IMMEDIATELY
- If user seems uncertain → ask clarifying questions
- If you're uncertain → say so and ask

### PHASE 3: ACT (Only after THINK and ALIGN)

**Pre-Flight Checklist (BLOCKING):**

1. **Git Status Check** - MANDATORY before any edit:
   ```bash
   git status --short
   ```
   - If working tree is dirty with unrelated changes → STOP, notify user
   - If on wrong branch → STOP, notify user
   - Clean state required for safe work

2. **Create Beads** - If task has 2+ steps, create tracking beads

3. **Reserve Files** - If editing and Agent Mail is available

**During Execution:**
- One file at a time
- Verify after each change
- Mark todos complete as you go
- If something unexpected happens → STOP and report

---

## Hard Limits (ENFORCED)

### Agent Spawning
- Maximum 3 parallel agents without user approval
- Maximum 5 beads/tasks per session without user approval
- ALWAYS show plan before spawning agents

### Git Safety
- NEVER edit files with uncommitted unrelated changes
- NEVER push without explicit request
- CHECK git status before any edit

### Scope Creep Prevention
- NEVER refactor while fixing bugs
- NEVER "improve" code that wasn't requested
- NEVER add abstraction "for the future"
- If tempted to do more than asked → STOP and ask

### Domain Humility
- Complex domains require extra caution
- Assume the user knows more than you about their domain
- If something seems wrong, ASK before "fixing"
- Don't apply generic patterns to specialized code

### Stop Signals
When user says any of: "stop", "wait", "hold on", "cancel", "no"
→ IMMEDIATELY halt all work
→ Report current state
→ Wait for further instruction

---

## Session Workflow

Use beads for traceability. Every work session should be tracked.

```
/focus <bead-id>           # Start: load context, mark in-progress
    ↓
  ... do work ...
    ↓
/checkpoint                # Optional: mid-session save
    ↓
  ... more work ...
    ↓
/handoff                   # End: summarize, commit, REQUIRES bead
```

- **`/handoff` requires a bead** - hard stop if no active bead
- **`/handoff` writes** `.handoff/YYYY-MM-DD-HHMM-{bead-id}.md`
- **`/checkpoint` writes** `.checkpoint/YYYY-MM-DD-HHMM.md`

---

## When Uncertain

Say so. Ask.

```
I'm not fully certain about [aspect].
My understanding: [interpretation]
Is this correct, or am I missing something?
```

### After 2 Failed Attempts
1. STOP editing
2. Report what was tried
3. Ask user for guidance

---

## Critical Work Standard

When asked to check status against requirements, specifications, or documents:
- You MUST find, read, and verify against the actual source document
- NEVER rely on memory, assumptions, or prior knowledge
- If you cannot locate the document, explicitly state this and ask for the path
- Always say "Let me find and read [document name]" before making status assessments

Making claims about completeness without reading actual requirements is a fundamental failure.

---

## Anti-Patterns (NEVER DO)

| Category | Anti-Pattern |
|----------|--------------|
| **Autonomy** | Acting without alignment on significant work |
| **Scope** | Refactoring while fixing bugs |
| **Abstraction** | Adding layers "for the future" |
| **Continuation** | Proceeding after "stop" |
| **Assumptions** | Guessing instead of reading source documents |
| **Legacy** | Adding old patterns (UIKit) to modern platforms (visionOS) |

---

## Tools

| Tool | Purpose |
|------|---------|
| `gj` | Build, run, test GrooveTech apps (never raw xcodebuild) |
| `bd` | Beads issue tracking |
| `/focus` | Start work session on a bead |
| `/handoff` | End work session with summary |
| `/checkpoint` | Mid-session context save |

---

*Unified agent configuration: https://github.com/carmandale/agent-config*

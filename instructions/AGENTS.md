# AGENTS.md - Global Instructions

> Universal standards for all AI coding agents
> Last Updated: 2026-01-15

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

**No Legacy Tech Debt**
- **DELETE over WRAP** — when v1/POC code is superseded, remove it
- Don't add compatibility layers for code that was never meant to be permanent
- If asked to "keep the old way working," challenge whether it's actually needed

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

1. **Git Status Check** - Before editing a file:
   - If **that file** was dirty before you started → STOP, ask before editing (except append-only `.learnings/*.md`)
   - If **you** dirtied it this session → it's WIP, keep working
   - Other dirty files? **Not your concern**
   - Wrong branch? → STOP, notify user

2. **Create Beads** - If task has 2+ steps, create tracking beads

**During Execution:**
- One file at a time
- Verify after each change
- Mark todos complete as you go
- If something unexpected happens → STOP and report

---

## Hard Limits (ENFORCED)

### Agent Spawning
- Maximum 5 beads/tasks per session without user approval
- ALWAYS show plan before spawning agents

### Git Safety

**The rule:** Don't edit a file that was dirty before you started.

- If a file has uncommitted changes **you didn't make** → STOP, ask before editing
- If **you** dirtied it this session → it's WIP, keep working
- Other files in the repo dirty? **Not your concern**
- Exception: `.learnings/*.md` is append-only; always append even if dirty

**Paths that don't block your work** (dirty is OK, don't wait for user):
`.worktrees/`, `.DS_Store`, `*.lock`, `*-wal`, `*-shm`

### .beads/ Directory (SPECIAL HANDLING REQUIRED)

The `.beads/` directory contains the beads issue database. It requires specific handling:

**✅ CORRECT: Use `bd sync` to manage .beads/ files**
```bash
bd sync          # Exports issues, commits, pulls, pushes
git status       # Should be clean after sync
```

**❌ NEVER DO THESE:**
- `git restore .beads/` — DESTROYS sync state, loses issue changes
- `git checkout .beads/` — Same problem
- Manually committing `.beads/` files — Let `bd sync` handle it

**If `.beads/` is dirty after `bd sync`:**
1. Run `bd sync` again (sometimes needs two passes)
2. If still dirty, check which files:
   - `issues.jsonl` dirty → run `bd sync` again
   - Runtime files (`last-touched`, `sync-state.json`, `*.db`) → These should be gitignored. If tracked, run: `git rm --cached .beads/<file>`
3. If issues persist, ask the user — don't guess

**Decision tree for dirty .beads/ files:**
```
.beads/ dirty?
    ├── Run `bd sync`
    │       └── Still dirty?
    │               ├── issues.jsonl → `bd sync` again
    │               ├── Runtime files (last-touched, *.db) → `git rm --cached`
    │               └── Unknown → ASK USER
    └── Clean → proceed
```

**Rotated daemon logs:** The beads daemon creates timestamped log files like `daemon-2026-01-25T18-59-44.822.log.gz`. These should be gitignored. Add this to `.beads/.gitignore`:
```gitignore
# Rotated daemon logs
daemon-*.log.gz
```

**Never push without explicit request.**

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

## Worktree Workflow

Use git worktrees for isolated parallel development. Worktrees live **inside** the repo in `.worktrees/` (gitignored).

### Structure

```
/dev/my-repo/                    # Main repo (clean, on main)
/dev/my-repo/.worktrees/         # Gitignored worktree container
/dev/my-repo/.worktrees/bd-abc/  # Worktree for bead bd-abc
```

### Setup (one-time per repo)

```bash
# Add to .gitignore
echo ".worktrees/" >> .gitignore
```

### Create Worktree

```bash
# Ensure main is clean first
git status  # Must be clean!

# Create worktree with bead ID as branch name
git worktree add .worktrees/<bead-id> -b <bead-id>

# Enter worktree
cd .worktrees/<bead-id>
```

### Work in Worktree

```bash
# Do your work, commit normally
git add -A && git commit -m "feat: description"

# Push branch
git push -u origin <bead-id>
```

### Cleanup (after merge)

```bash
# From main repo
cd /dev/my-repo
git worktree remove .worktrees/<bead-id>
git branch -d <bead-id>

# Close bead
bd close <bead-id> --reason "Merged"
```

### Rules

- **NEVER** create worktrees as siblings outside the repo
- **ALWAYS** use `.worktrees/` inside the repo
- **ALWAYS** ensure `.worktrees/` is in `.gitignore`
- **ALWAYS** verify main is clean before creating worktree
- Use `/worktree-task <bead-id>` command for guided setup

---

## When Uncertain

Say so. Ask. **Never fabricate.**

```
I'm not fully certain about [aspect].
My understanding: [interpretation]
Is this correct, or am I missing something?
```

### Intellectual Honesty (CRITICAL)

**Inferences are not findings.** When you deduce, guess, or infer something:
- Say "I think..." or "My guess is..." or "I couldn't find it, but I infer..."
- NEVER say "Found it" or present conclusions as discoveries
- NEVER fabricate sources, rules, or explanations you can't point to
- If you searched and found nothing, say "I searched X, Y, Z and found nothing"

**"I don't know" is a valid answer.** Preferable to a confident-sounding fabrication.

**Distinguish clearly:**
- **Found**: "Line 47 of config.yaml says X" (citable)
- **Inferred**: "Based on the naming pattern, I think X" (reasoning visible)
- **Don't know**: "I couldn't find where this comes from"

Presenting guesses as facts is **lying**. It wastes user time and erodes trust.

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
| **Fabrication** | Presenting inferences as findings; saying "Found it" when you deduced it; inventing sources |
| **Legacy** | Wrapping v1/POC code instead of deleting it; adding "compatibility layers" for temporary code |

---

## Task Delegation (interactive_shell)

**When to delegate to a subagent:**
- Long-running tasks (refactoring, multi-file changes, test fixes)
- Tasks where user should see progress in real-time
- GitHub issues, feature implementation, code review
- Any task where user says "delegate", "have a subagent", "hands-free"

**How:**
```typescript
interactive_shell({
  command: 'pi "Clear prompt with full context"',
  mode: "hands-free",
  reason: "Brief description"
})
```

**Workflow:**
1. Spawn subagent with detailed prompt (include issue context, file hints)
2. User watches overlay in real-time
3. Query status periodically, send follow-up input if needed
4. User can take over by typing in overlay, or Ctrl+Q to background
5. Kill session when done, review changes together

**User steers via:** typing in overlay (direct) or telling me what to send (I relay)

---

## Oracle (GPT-5 Pro Second Opinion)

**Trigger:** User says "consult the oracle", "ask the oracle", "what does the oracle think", "oracle this"

**It's this simple:**
```bash
oracle --prompt "Clear question with context" --file "relevant/file.swift" --slug "short-name"
```

**Required elements:**
1. `--prompt` — Full context: project, stack, problem, what you tried, specific question
2. `--file` — Relevant files (quote paths with spaces, verify they exist first)
3. `--slug` — Short memorable name for recovery

**Before running:**
```bash
# 1. Check no oracle is running
oracle status --hours 1

# 2. Verify files exist
ls -la "path/to/file.swift"

# 3. Check token count
oracle --dry-run summary -p "test" --file "path/to/file.swift"
```

**Run DETACHED** (can take 45 min to 1+ hour, must not be cancelled):
```bash
nohup bash -lc 'oracle -p "## Context
Project: [name], Stack: [Swift/visionOS]

## Problem
[Error or issue]

## Question
[Specific question]" \
  --file "relevant/file.swift" \
  --slug "descriptive-name"' > /tmp/oracle-<slug>.log 2>&1 &

echo "Oracle running in background. Check: oracle status --hours 1"
```

**Check status:** `oracle status --hours 1`
**Get result:** `oracle session <slug>`
**View log:** `cat /tmp/oracle-<slug>.log`

**CRITICAL:** Use `nohup bash -lc '...'` (not just `nohup oracle`) so it works in both Pi and Codex.

---

## Tools

| Tool | Purpose |
|------|---------|
| `gj` | Build, run, test GrooveTech apps (never raw xcodebuild) |
| `bd` | Beads issue tracking |
| `interactive_shell` | Delegate tasks to subagent with user supervision |
| `oracle` | GPT-5 Pro second opinion (run detached with nohup ... &) |
| `/focus` | Start work session on a bead |
| `/handoff` | End work session with summary |
| `/checkpoint` | Mid-session context save |

---

## gj Tool (GrooveTech Build/Test)

**Use `gj` for all build/run/test operations. Never use xcodebuild directly.**

### Essential Commands

```bash
gj run <app>              # Build + run + stream logs
gj run --device <app>     # Build + run on physical device
gj logs <app> "pattern"   # Search logs (use as assertions)
gj ui screenshot <app>    # Visual verification
gj test P0                # E2E connection tests
```

### Apps: `orchestrator`, `pfizer`, `gmp`, `ms`, `all`

### Testing Quick Pattern

```bash
# Quick validation (use this first)
gj run orchestrator
gj logs orchestrator "error"      # Should be empty
gj ui screenshot orchestrator     # Visual check

# Use logs as assertions
gj logs orchestrator "connected"  # Should have output
gj logs orchestrator "error"      # Should be empty
```

### When to Test What

| Situation | Command |
|-----------|---------|
| Quick iteration | `gj logs <app> "pattern"` |
| Visual check | `gj ui screenshot <app>` |
| UI interaction | `gj ui tap-button <app> "Label"` |
| Full validation | `gj test P0` |

**Full docs:** `~/.agent-config/docs/gj-tool.md`
**UI automation:** `~/.agent-config/docs/ui-automation.md`

---

## Beads Workflow (Issue Tracking)

Use `bd` CLI for issue tracking. Issues stored in `.beads/` and tracked in git.

### Essential Commands

```bash
bd ready              # Show issues ready to work (no blockers)
bd list --status=open # All open issues
bd show <id>          # Full issue details with dependencies
bd create --title="..." --type=task --priority=2
bd update <id> --status=in_progress
bd close <id> --reason="Completed"
bd close <id1> <id2>  # Close multiple issues at once
bd sync               # Commit and push beads changes
```

### Workflow Pattern

1. **Start**: `bd ready` to find actionable work
2. **Claim**: `bd update <id> --status=in_progress`
3. **Work**: Implement the task
4. **Complete**: `bd close <id> --reason="Done"`
5. **Sync**: `bd sync` at session end

### Key Concepts

- **Dependencies**: Issues can block other issues. `bd ready` shows only unblocked work.
- **Priority**: P0=critical, P1=high, P2=medium, P3=low, P4=backlog
- **Types**: task, bug, feature, epic, question, docs
- **Blocking**: `bd dep add <issue> <depends-on>`

### Session End Protocol

```bash
git status              # Check what changed
git add <files>         # Stage code changes
git commit -m "..."     # Commit code
bd sync                 # Commit beads changes
git push                # Push to remote
```

---

## Git Push Workflow

```bash
# Stage and commit local changes first
git add -A && git commit -m "your message"

# Try to push - this will fail if remote has new commits
git push

# ONLY if push fails with "rejected" (remote ahead), then:
git pull --rebase && git push

# Sync beads after code is pushed
bd sync

# Verify clean state
git status   # MUST show "up to date with origin"
```

**NEVER run `git pull --rebase` blindly** - only use it when push fails because remote is ahead.

---

## cass — Search Agent History

Search across all AI agent conversation history before solving problems from scratch.

**NEVER run bare `cass`** — it launches TUI. Always use `--robot` or `--json`.

### Quick Commands

```bash
cass health                                    # Check index health
cass search "pattern" --robot --limit 5        # Search all agents
cass search "pattern" --robot --agent codex    # Filter by agent
cass search "pattern" --robot --days 7         # Recent only
cass view /path/to/session.jsonl -n 42 --json  # View specific result
```

### Agents Indexed

| Agent | Location |
|-------|----------|
| Claude Code | `~/.claude/projects/` |
| OpenCode | `.opencode/` in repos |
| Cursor | `~/Library/Application Support/Cursor/User/` |
| Codex | `~/.codex/sessions/` |
| Pi-Agent | `~/.pi/agent/sessions/` |

### Key Flags

| Flag | Purpose |
|------|---------|
| `--robot` / `--json` | Machine-readable output (required!) |
| `--fields minimal` | Reduce payload size |
| `--limit N` | Cap result count |
| `--agent NAME` | Filter to specific agent |
| `--workspace PATH` | Filter to specific project |
| `--days N` | Limit to recent N days |

---

## bv — Beads Viewer (AI Sidecar)

Fast terminal UI for beads with precomputed dependency metrics. Use robot flags for deterministic, dependency-aware outputs.

```bash
bv --robot-help      # All AI-facing commands
bv --robot-insights  # Graph metrics (PageRank, critical path, cycles)
bv --robot-plan      # Execution plan with parallel tracks
bv --robot-priority  # Priority recommendations with reasoning
bv --robot-recipes   # List available recipes
bv --robot-diff --diff-since <commit>  # Issue changes since commit
```

Use these instead of hand-rolling graph logic.

---

## ast-grep vs ripgrep

**Use `ast-grep` when structure matters** — parses code, matches AST nodes, can safely rewrite.

```bash
# Find structured code (ignores comments/strings)
ast-grep run -l TypeScript -p 'import $X from "$P"'

# Codemod
ast-grep run -l JavaScript -p 'var $A = $B' -r 'let $A = $B' -U
```

**Use `ripgrep` when text is enough** — fastest for literals/regex.

```bash
rg -n 'console\.log\(' -t js
```

**Combine for precision:**

```bash
rg -l -t ts 'useQuery\(' | xargs ast-grep run -l TypeScript -p 'useQuery($A)' -r 'useSuspenseQuery($A)' -U
```

**Rule of thumb:** Need correctness or rewrites → `ast-grep`. Need speed or hunting text → `rg`.

---

## UBS — Ultimate Bug Scanner

Static analysis before commits. Exit 0 = safe, Exit >0 = fix needed.

```bash
ubs file.ts file2.py                    # Specific files (< 1s)
ubs $(git diff --name-only --cached)    # Staged files
ubs --only=js,python src/               # Language filter
ubs .                                   # Whole project
```

**Output format:** `file:line:col – Issue` with 💡 fix suggestions.

**Fix workflow:**
1. Read finding → understand category + fix
2. Navigate to `file:line:col`
3. Verify real issue (not false positive)
4. Fix root cause
5. Re-run `ubs <file>` → exit 0
6. Commit

**Speed tip:** Scope to changed files. `ubs src/file.ts` (< 1s) vs `ubs .` (30s).

---

*Unified agent configuration: https://github.com/carmandale/agent-config*

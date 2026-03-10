#!/usr/bin/env bash
# configs/claude/hooks/br-prime.sh — Beads workflow context for Claude Code
# Replaces: bd prime (spec 013)
# Called by: settings.json SessionStart + PreCompact hooks

# Only emit if .beads/ exists in current directory
if [ ! -d ".beads" ]; then
    exit 0
fi

cat <<'CONTEXT'
# Beads Workflow Context

> **Context Recovery**: This is injected by br-prime.sh hook
> Runs on SessionStart and PreCompact when .beads/ detected

# ⚠️ CRITICAL: br sync DIRECTION WARNING ⚠️

**`br sync` (bare) = IMPORT. This OVERWRITES your database with JSONL contents.**
**Use `br sync --flush-only` to EXPORT database state to JSONL.**

Never run bare `br sync` unless you intend to import from JSONL.

# 🚨 SESSION CLOSE PROTOCOL 🚨

**CRITICAL**: Before saying "done" or "complete", you MUST run this checklist:

```
[ ] 1. git status                   (check what changed)
[ ] 2. git add <files>              (stage code changes)
[ ] 3. br sync --flush-only         (export beads to JSONL)
[ ] 4. git commit -m "..."          (commit code)
[ ] 5. br sync --flush-only         (export any new beads changes)
[ ] 6. git push                     (push to remote)
```

**NEVER skip this.** Work is not done until pushed.

## Core Rules
- **Default**: Use beads for ALL task tracking (`br create`, `br ready`, `br close`)
- **Prohibited**: Do NOT use TodoWrite, TaskCreate, or markdown files for task tracking
- **Workflow**: Create beads issue BEFORE writing code, mark in_progress when starting
- Persistence you don't need beats lost context
- Git workflow: hooks auto-sync, run `br sync --flush-only` at session end
- Session management: check `br ready` for available work

## Essential Commands

### Finding Work
- `br ready` - Show issues ready to work (no blockers)
- `br list --status=open` - All open issues
- `br list --status=in_progress` - Your active work
- `br show <id>` - Detailed issue view with dependencies

### Creating & Updating
- `br create --title="Summary" --description="Why + what" --type=task|bug|feature --priority=2` - New issue
  - Priority: 0-4 or P0-P4 (0=critical, 2=medium, 4=backlog). NOT "high"/"medium"/"low"
- `br update <id> --status=in_progress` - Claim work
- `br update <id> --assignee=username` - Assign to someone
- `br update <id> --title / --description / --notes / --design` - Update fields inline
- `br close <id>` - Mark complete
- `br close <id1> <id2> ...` - Close multiple issues at once
- `br close <id> --reason="explanation"` - Close with reason
- **Tip**: When creating multiple issues, use parallel subagents for efficiency
- **WARNING**: Do NOT use `br edit` - it opens $EDITOR (vim/nano) which blocks agents

### Labels & Dependencies
- `br label add <id> <label>` - Add a label to an issue
- `br dep add <issue> <depends-on>` - Add dependency
- `br blocked` - Show all blocked issues
- `br show <id>` - See what's blocking/blocked by this issue

### Sync & Collaboration
- `br sync --flush-only` - EXPORT database to JSONL (safe — this is what you want)
- `br sync --status` - Check sync status without syncing
- ⚠️ `br sync` (bare) - IMPORT from JSONL (DANGEROUS — overwrites database)

### Project Health
- `br stats` - Project statistics (open/closed/blocked counts)
- `br doctor` - Check for issues (sync problems, schema)

## Common Workflows

**Starting work:**
```bash
br ready                                  # Find available work
br show <id>                              # Review issue details
br update <id> --status=in_progress       # Claim it
```

**Completing work:**
```bash
br close <id1> <id2> ...                  # Close all completed issues at once
br sync --flush-only                      # Export to JSONL (NOT bare br sync!)
```

**Creating dependent work:**
```bash
br create --title="Implement feature X" --description="Why + what" --type=feature
br create --title="Write tests for X" --description="Why + what" --type=task
br dep add <test-id> <feature-id>         # Tests depend on Feature
```
CONTEXT

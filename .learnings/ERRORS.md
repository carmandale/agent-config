# Errors

Operational failures and error logs captured during development.

**Areas**: frontend | backend | infra | tests | docs | config
**Statuses**: pending | in_progress | resolved | wont_fix | promoted

---

## [ERR-20260116-002] cc-artifact

**Logged**: 2026-01-16T23:56:05Z
**Priority**: high
**Status**: pending
**Area**: infra

### Summary
Finalize artifact generation failed due to missing cc-artifact script

### Error
```
zsh:1: no such file or directory: /Users/dalecarman/.claude/scripts/cc-artifact
```

### Context
- Command/operation: `~/.claude/scripts/cc-artifact --mode finalize --bead .agent-config-e10`
- Environment: local CLI run

### Suggested Fix
Verify script path or install the artifact generator at the expected location.

### Metadata
- Reproducible: yes
- Related Files: N/A

---

## [ERR-20260116-001] oracle_run

**Logged**: 2026-01-16T22:46:35Z
**Priority**: high
**Status**: pending
**Area**: config

### Summary
Oracle run failed due to incorrect file path argument

### Error
```
File path invalid or not found (wrong path provided).
```

### Context
- Command/operation: initial Oracle run
- Input: wrong file path argument
- Environment: local CLI run

### Suggested Fix
Verify the path before running; use an absolute path or validate with `ls`.

### Metadata
- Reproducible: yes
- Related Files: N/A

---
## [ERR-20260120-001] create_agent_loop_issue

**Logged**: 2026-01-20T10:35:32Z
**Priority**: high
**Status**: pending
**Area**: config

### Summary
agent-loop issue creation failed when the GitHub label "agent-loop" did not exist

### Error
```
[error] Command failed: gh issue create --title "Fix finalize/handoff/checkpoint context + GH close flow" --body <...> --label agent-loop
could not add label: 'agent-loop' not found
```

### Context
- Command/operation: create_agent_loop_issue.py (bd create + gh issue create)
- Repo: ~/.agent-config
- Result: bead was created, GH issue failed due to missing label

### Suggested Fix
Create the "agent-loop" label in the target repo or update the script to create the label if missing.

### Metadata
- Reproducible: yes
- Related Files: /Users/dalecarman/.codex/skills/public/agent-loop-issue/scripts/create_agent_loop_issue.py

---

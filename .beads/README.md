# Beads - AI-Native Issue Tracking

This repository uses **br** (beads_rust) for issue tracking — an AI-native tool that lives directly in your codebase alongside your code.

## What is br?

br is issue tracking that lives in your repo, using SQLite + JSONL. Perfect for AI coding agents and developers who want their issues close to their code. No web UI, no daemon — everything works through the CLI and integrates with git.

**Learn more:** [github.com/Dicklesworthstone/beads_rust](https://github.com/Dicklesworthstone/beads_rust)

## Quick Start

### Essential Commands

```bash
# Create new issues
br create "Add user authentication"

# View all issues
br list

# View issue details
br show <issue-id>

# Update issue status
br update <issue-id> --status in_progress

# Close an issue
br close <issue-id> --reason "Done"

# Export DB→JSONL (for git commit)
br sync --flush-only

# Import JSONL→DB (after git pull)
br sync --import-only
```

### ⚠️ Critical: bare `br sync` = IMPORT only

Bare `br sync` (no flags) defaults to **import-only**. To export DB changes to JSONL, always use `br sync --flush-only`.

### Working with Issues

Issues in br are:
- **Git-native**: Stored in `.beads/issues.jsonl` and synced like code
- **AI-friendly**: CLI-first design works perfectly with AI coding agents
- **SQLite-backed**: Fast queries via local database
- **Explicit-control**: Never auto-commits, never touches git

## Install

```bash
curl -fsSL "https://raw.githubusercontent.com/Dicklesworthstone/beads_rust/main/install.sh" | bash
```

---

*br: Issue tracking that moves at the speed of thought* ⚡

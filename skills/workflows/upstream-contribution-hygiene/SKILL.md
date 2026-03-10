---
name: upstream-contribution-hygiene
description: Checklist and patterns for submitting clean PRs to repos you don't own. Use when contributing to upstream open-source repos, teammate repos, or any PR where the reviewer has no prior context on your work.
---

# Upstream Contribution Hygiene

Checklist and patterns for submitting PRs to repositories you don't own. A reviewer who didn't build the feature should be able to understand, verify, and merge it.

## When to Use

- Submitting a PR to an upstream open-source repo
- Contributing to a teammate's repo where you're not a maintainer
- Any PR where the reviewer has no prior context on your work

## Pre-Push Scan (Mandatory)

Run these before every force-push or PR update:

```bash
# 1. Personal data — usernames, machine paths, company names
grep -r "$(whoami)\|/Users/$(whoami)" $(git diff --name-only main..HEAD)

# 2. Process artifacts — specs, planning docs, beads, session logs
git diff --name-only main..HEAD | grep -E "^(specs/|thoughts/|\.beads/|\.claude/)"

# 3. Type safety — no cast bypasses shipped
grep -c "as any" $(git diff --name-only main..HEAD -- '*.ts')

# 4. Debug artifacts — console.log, TODO, HACK, BANDAID
grep -rn "console\.log\|// TODO\|// HACK\|// BANDAID" $(git diff --name-only main..HEAD -- '*.ts')
```

All four must return zero matches.

## PR Description Requirements

1. **What it does** — feature summary in 2-3 sentences
2. **Why this approach** — design decisions that aren't obvious (e.g., "CLI over MCP because subprocess has zero runtime coupling")
3. **Backward compatibility** — explicit statement: "no changes required for existing setups" or "breaking: X changed"
4. **Accurate stats** — file count, insertions, deletions from `git diff --shortstat main..HEAD`
5. **Security qualifications** — if something looks like auth but isn't, say so ("defense-in-depth, not a security boundary")

## Commit Hygiene

- Each commit compiles AND passes tests (bisectability)
- Commit messages follow conventional commits: `feat(scope):`, `refactor(scope):`, `docs:`
- No bookkeeping noise ("fix typo", "update test", "wip") — use fixup+autosquash
- Logical grouping: one concept per commit, dependencies before dependents

## Selective Staging

When your working tree has both PR code and process artifacts:

```bash
git reset --mixed main          # Unstage everything
git add <pr-files-only>         # Stage selectively
git commit -m "feat: ..."       # Commit only PR content
# Repeat for each logical commit
```

Never `git add .` on a branch with specs/, thoughts/, or session logs.

## Evidence

- **spec-003 R1**: JSONL file with machine paths committed in original PR — caught by adversarial review, excluded via selective staging
- **spec-003 R2**: 992 lines of specs/ in original PR — excluded, PR dropped from 5600 to 3385 lines
- **spec-003 R0**: PR description missing CLI-over-MCP rationale — caught by navigator, added
- **spec-003 R6**: Nonce described as "authentication" when it's defense-in-depth — qualified in JSDoc + PR description

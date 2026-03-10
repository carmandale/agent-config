---
name: fixup-restage
description: Surgical commit repair using git fixup+autosquash rebase while preserving bisectability. Use when a fix belongs in an earlier commit, after interactive rebase staging gaps, or when post-review fixes need to land in the right commit.
---

# Fixup Restage — Surgical Commit Repair with Bisectability

Repair a specific commit in a series using fixup+autosquash rebase while preserving bisectability (every commit compiles and passes tests).

## When to Use

- A fix belongs in an earlier commit, not at HEAD
- Navigator or reviewer found a staging gap after interactive rebase
- A behavioral regression was introduced by extraction and needs to go into the extraction commit
- Post-review documentation fix needs to land in the right commit

## Process

### Step 1: Make the fix in working tree

Edit the file(s). Verify the fix is correct in isolation.

### Step 2: Stage and create fixup commit

```bash
git add <fixed-files>
git commit --fixup=<target-commit-sha>
```

The `--fixup=` prefix tells autosquash which commit to fold into.

### Step 3: Stash unstaged work

```bash
git stash
```

If there are unstaged changes (specs, process artifacts), stash them so rebase operates cleanly.

### Step 4: Interactive rebase with autosquash

```bash
GIT_SEQUENCE_EDITOR="sed -i '' '/^pick.*fixup/s/^pick/fixup/'" git rebase -i --autosquash <base-ref>
```

Where `<base-ref>` is typically `main` or the branch point.

### Step 5: Verify bisectability

```bash
# Quick: test HEAD
npm test

# Thorough: test each commit (for critical PRs)
git rebase -i --exec "npm test" <base-ref>
```

### Step 6: Pop stash and continue

```bash
git stash pop
```

## Critical Gotchas

1. **Fixes applied after initial staging get missed.** If you staged files, committed, then applied a fix — the fix is in working tree but NOT in the commit. You must stage + fixup.

2. **Import dependencies break bisectability.** If commit N adds a function and commit N+2 adds the import, the fixup must go into the commit where the import's consumer lives, not where the function was defined.

3. **Lazy vs eager evaluation.** When extracting code into a shared utility, values captured at creation time may be null in one callsite but not another. After fixup, re-verify the behavioral identity of the target commit.

4. **Force-push after rebase.** The rebase rewrites SHAs from the fixup point onward. Use `git push --force` (not `--force-with-lease` if you've already force-pushed — the lease will be stale).

## Evidence

- **spec-003 T3.1**: FileReservation type import applied after initial commit 1 staging. Required fixup+autosquash to land in commit 1.
- **spec-003 T3.5**: Lazy taskId getter fix applied after commit 5 was created. Fixup folded it into the stuck-timer extraction commit.
- **spec-003 T3.4**: Codex skip comment expanded post-review. Fixup into commit 4 (Codex adapter).

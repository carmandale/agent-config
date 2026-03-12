---
name: mini-sync
description: Set up dual-push git sync from laptop to Mac mini for any repo. Use when adding a new repo that should auto-sync to mini-ts.
---

# Mini Sync — Dual-Push Repo Setup

Auto-sync a laptop repo to the Mac mini on every `git push`.
Pattern: dual push URL + post-receive hook + `updateInstead`.

## When to Use

- "sync this repo to the mini"
- "set up auto-push to mac mini"
- "replicate the agent-config sync pattern"
- Setting up a new dev tool / fork that Chip needs

## Prerequisites

- SSH access: `ssh mini-ts` works (Host `mini-ts` in `~/.ssh/config` → `chipcarman@chips-mac-mini`)
- Repo exists on GitHub (or other remote)
- You know the target path on the mini

## Steps

### 1. Clone on the mini (if not already there)

```bash
ssh mini-ts "cd ~/dev && git clone <GITHUB_URL> <DIRNAME>"
ssh mini-ts "cd ~/dev/<DIRNAME> && git checkout <BRANCH>"
```

### 2. Enable push-to-working-tree

```bash
ssh mini-ts "cd ~/dev/<DIRNAME> && git config receive.denyCurrentBranch updateInstead"
```

This tells git to accept pushes to a non-bare repo and auto-update the working tree.

### 3. Add dual push URL on the laptop

```bash
cd /path/to/local/repo

# ⚠️ IMPORTANT: set-url --add --push REPLACES on first call, ADDS on second.
# Always add the SSH URL first, then re-add GitHub.
git remote set-url --add --push origin ssh://mini-ts/<MINI_FULL_PATH>
git remote set-url --add --push origin <GITHUB_URL>
```

Verify with `git remote -v` — you should see:
```
origin  <GITHUB_URL> (fetch)
origin  ssh://mini-ts/<MINI_PATH> (push)
origin  <GITHUB_URL> (push)
```

### 4. Create post-receive hook on the mini

This hook fires after receiving a push. The working tree is already updated by `updateInstead` — the hook handles any post-update tasks (npm install, build, etc.).

```bash
ssh mini-ts 'mkdir -p ~/dev/<DIRNAME>/.git/hooks && cat > ~/dev/<DIRNAME>/.git/hooks/post-receive << '\''HOOK'\''
#!/usr/bin/env bash
unset GIT_DIR GIT_WORK_TREE
REPO_DIR="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$REPO_DIR"

info()  { echo -e "\033[0;34m▸ <DIRNAME> (mini-ts):\033[0m $1" >&2; }
ok()    { echo -e "\033[0;32m✓ <DIRNAME> (mini-ts):\033[0m $1" >&2; }
warn()  { echo -e "\033[1;33m⚠ <DIRNAME> (mini-ts):\033[0m $1" >&2; }

needs_install=false
while read oldrev newrev refname; do
    if git diff --name-only "$oldrev" "$newrev" 2>/dev/null | grep -q "^package\.json$"; then
        needs_install=true
    fi
done

if [[ "$needs_install" == true ]]; then
    info "package.json changed — running npm install"
    if npm install --omit=dev >/dev/null 2>&1; then
        ok "npm install complete"
    else
        warn "npm install failed — run manually: cd $REPO_DIR && npm install"
    fi
fi

ok "Post-receive sync complete"
exit 0
HOOK
chmod +x ~/dev/<DIRNAME>/.git/hooks/post-receive'
```

Adapt the hook body for non-Node projects (e.g., run `install.sh` for agent-config).

### 5. Test

```bash
# Dry run — verify both URLs respond
git push --dry-run origin <BRANCH>

# Real test — make a trivial commit, push, verify mini, then revert
echo "" >> README.md && git add README.md && git commit -m "test: verify sync"
git push origin <BRANCH>
ssh mini-ts "cd ~/dev/<DIRNAME> && git log --oneline -1"  # should match
git reset --soft HEAD~1 && git checkout README.md
git push --force origin <BRANCH>
```

## Currently Synced Repos

| Repo | Laptop Path | Mini Path | Branch |
|------|-------------|-----------|--------|
| agent-config | `~/.agent-config` | `~/.agent-config` | main |
| pi-messenger (fork) | `~/...Projects/dev/pi-messenger` | `~/dev/pi-messenger-fork` | feat/002-multi-runtime-support |

Update this table when adding new repos.

## Troubleshooting

| Problem | Fix |
|---------|-----|
| Push rejected | Check `receive.denyCurrentBranch` is `updateInstead` |
| Hook doesn't fire | Check `chmod +x` on post-receive |
| Working tree not updated | `unset GIT_DIR` in hook is critical — git sets it during hook execution |
| Wrong branch on mini | Mini must be on the same branch you're pushing |
| Force push needed | Works fine — `updateInstead` handles force pushes |

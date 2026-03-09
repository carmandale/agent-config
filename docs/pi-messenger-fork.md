# Pi-Messenger Fork Management

> **We do not own pi-messenger.** Upstream is [nicobailon/pi-messenger](https://github.com/nicobailon/pi-messenger).
> Our fork is [carmandale/pi-messenger](https://github.com/carmandale/pi-messenger).
> This doc explains the build, install, and sync situation across machines.

Last updated: 2026-03-09

## The Setup

### Laptop (Dales-MacBook-Pro-M4-6)

Pi-messenger is installed **from a local path** (our fork checkout), NOT from npm:

```
~/.pi/agent/settings.json → packages includes:
  "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/pi-messenger"
```

- **Source**: `~/Groove Jones Dropbox/Dale Carman/Projects/dev/pi-messenger`
- **Remotes**: `origin` = carmandale/pi-messenger, `upstream` = nicobailon/pi-messenger
- **Version**: v0.14.0 (unpublished — includes spec 002: multi-runtime support, pi-messenger-cli, Claude adapter, completion inference, Codex adapter)
- **Branch**: `feat/002-multi-runtime-support` (or merged to main on our fork)
- **Install method**: `pi install /path/to/local/dir` — pi loads the `.ts` files directly, no build step

### Mac Mini (chips-mac-mini, SSH: `mini-ts`)

Pi-messenger is installed **from npm** (upstream's published version):

```
~/.pi/agent/settings.json → packages includes:
  "npm:pi-messenger"
```

- **Source**: `/opt/homebrew/lib/node_modules/pi-messenger` (npm global)
- **Version**: v0.13.0 (upstream published)
- **Missing**: pi-messenger-cli, Claude/Codex adapters, completion inference, worker nonce auth, stuck detection — everything from spec 002

The upstream repo is also cloned at `~/dev/pi-messenger` on the mini but points at `nicobailon/pi-messenger` (not our fork) and is NOT what pi loads.

## Current Setup (as of 2026-03-09)

### Mac Mini — DONE

Our fork is cloned and registered:

```
~/dev/pi-messenger-fork  →  carmandale/pi-messenger, branch feat/002-multi-runtime-support
~/.pi/agent/settings.json  →  packages: ["../../dev/pi-messenger-fork"]
```

The old npm install (`npm:pi-messenger` v0.13.0) has been removed.

## Auto-Sync: Dual Push URL + post-receive Hook

Same pattern as `~/.agent-config`. When you `git push` from the laptop, it pushes to **both** GitHub and the Mac mini simultaneously:

```
origin (push) → ssh://mini-ts/Users/chipcarman/dev/pi-messenger-fork   ← Mac mini
origin (push) → https://github.com/carmandale/pi-messenger.git         ← GitHub
origin (fetch) → https://github.com/carmandale/pi-messenger.git
```

The Mac mini repo has:
- `receive.denyCurrentBranch = updateInstead` — auto-updates working tree on push
- `.git/hooks/post-receive` — runs `npm install` if `package.json` changed

**You just commit + push. The mini updates automatically. Pi loads .ts directly — no build needed.**

### If you need to set this up again from scratch

```bash
# On the Mac mini
cd ~/dev
git clone https://github.com/carmandale/pi-messenger.git pi-messenger-fork
cd pi-messenger-fork
git checkout feat/002-multi-runtime-support  # or main, once merged
git config receive.denyCurrentBranch updateInstead
pi remove npm:pi-messenger   # remove old npm install if present
pi install ~/dev/pi-messenger-fork

# On the laptop
cd "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/pi-messenger"
git remote set-url --add --push origin ssh://mini-ts/Users/chipcarman/dev/pi-messenger-fork
git remote set-url --add --push origin https://github.com/carmandale/pi-messenger.git
```

## Upstream Sync

Periodically pull upstream changes:

```bash
cd "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/pi-messenger"
git fetch upstream
git merge upstream/main
# Resolve conflicts if any
git push origin main
```

If upstream publishes v0.14.0+ with our PR merged (#9), we can switch back to npm installs on both machines.

## PR Status

- **PR #9**: https://github.com/nicobailon/pi-messenger/pull/9
  - Spec 002: multi-runtime support
  - 46/47 tasks done (V3.16 manual E2E deferred)
  - 394 tests passing
  - Once merged + published upstream, the fork divergence goes away

## Version Matrix

| Machine | Source | Version | Has CLI | Has Adapters | Has Completion Inference |
|---------|--------|---------|---------|-------------|------------------------|
| Laptop | local path (fork) | 0.14.0 | ✅ | ✅ | ✅ |
| Mac Mini | local path (fork) | 0.14.0 | ✅ | ✅ | ✅ |
| npm (upstream) | published | 0.13.0 | ❌ | ❌ | ❌ |

## ⚠️ Gotchas

- **Do not `pi install npm:pi-messenger`** on either machine — it will overwrite our fork with the older upstream version.
- **The npm global at `/opt/homebrew/lib/node_modules/pi-messenger`** on the laptop is stale (v0.13.0). Pi ignores it because the local path install takes precedence in `settings.json`.
- **pi-messenger has no build step.** Pi loads `.ts` files via tsx. Changes are live immediately.
- **The cli (`pi-messenger-cli`)** uses a tsx shebang. It needs `npx tsx` available or the `node_modules` from the pi-messenger directory.
- **Branch tracking**: Both machines currently track `feat/002-multi-runtime-support`. When this merges to main, switch both: `git checkout main && git pull`.
- **The old upstream clone** at `~/dev/pi-messenger` on the mini still exists (pointing at nicobailon). It's inert — pi doesn't use it. Can be removed.

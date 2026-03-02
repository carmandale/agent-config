---
name: bird
description: Read and search X/Twitter posts via CLI. Use when user shares x.com or twitter.com links, asks to read a tweet, search Twitter/X, read a thread, or post/reply on X. Handles URLs like https://x.com/user/status/123 or https://twitter.com/user/status/123.
metadata: {"clawdbot":{"emoji":"🐦","requires":{"bins":["bird"]},"install":[{"id":"brew","kind":"brew","formula":"steipete/tap/bird","bins":["bird"],"label":"Install bird (brew)"}]}}
---

# bird

Use `bird` to read/search X and post tweets/replies.

Quick start
- `bird whoami`
- `bird read <url-or-id>`
- `bird thread <url-or-id>`
- `bird search "query" -n 5`

Posting (confirm with user first)
- `bird tweet "text"`
- `bird reply <id-or-url> "text"`

Auth sources (in priority order)
1. **Env vars** — `AUTH_TOKEN` + `CT0` (most reliable for agents)
2. **Browser cookies** — auto-read from Chrome/Firefox if logged into x.com
3. Check what's available: `bird check`

## Setting up auth tokens (one-time)

Get tokens from your browser after logging into x.com:
1. Open Chrome/Firefox → x.com → log in
2. DevTools (F12) → Application → Cookies → https://x.com
3. Copy `auth_token` value → set as `AUTH_TOKEN`
4. Copy `ct0` value → set as `CT0`

```bash
# Add to ~/.zshrc or ~/.zshenv:
export AUTH_TOKEN="your_auth_token_here"
export CT0="your_ct0_here"
```

Then `source ~/.zshrc` and `bird whoami` to verify.

Config file: `~/.config/bird/config.json5`

## Fallback: x-cli (cookie-based Python)

If bird fails, use the openclaw x-cli skill:
```bash
# Install: npx playbooks add skill openclaw/skills --skill x-cli
python scripts/x_read.py tweet <url>
python scripts/x_search.py "query" --count 10
```

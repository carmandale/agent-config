# Absolute Hook Paths

Hook commands in `settings.json` must use absolute paths or `~/` expansion.

## Pattern

Claude Code hooks run with CWD set to the repo being worked on, NOT the config repo. A relative path like `configs/claude/hooks/my-hook.sh` only works when CWD happens to be `~/.agent-config`.

## DO

```json
{
  "command": "bash ~/.agent-config/configs/claude/hooks/my-hook.sh"
}
```

## DON'T

```json
{
  "command": "bash configs/claude/hooks/my-hook.sh"
}
```

## Applies To

- `settings.json` hook commands (SessionStart, PreCompact, PreToolUse, Stop, etc.)
- Any config that references scripts by path and is consumed from multiple working directories

## Source

- Spec 013: Nearly deployed `bash configs/claude/hooks/br-prime.sh` which would have failed silently in every repo except agent-config. Caught during manual testing before push.

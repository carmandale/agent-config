---
name: bash-set-e-safety
description: Detect and fix bash set -e landmines — local var masking, [[ ]] && die, IFS subshell swallowing, and $() global propagation failures. Use when writing or reviewing bash scripts under set -euo pipefail, auditing shell scripts for silent error swallowing, or debugging why die/exit doesn't fire.
---

# Bash `set -e` Safety

Four patterns that silently defeat `set -e` error propagation in bash scripts. Each is a well-documented bash behavior, but agents consistently introduce them because the code *looks correct*.

## Landmine 1: `local var=$(cmd)` masks exit code

```bash
# BROKEN — local always returns 0, masking cmd's exit code
local dir=$(get_app_dir "$app")  # get_app_dir calls die → exit 1 → masked by local

# FIXED — split declaration from assignment
local dir
dir=$(get_app_dir "$app")  # exit 1 propagates correctly
```

**Why:** `local` is a builtin that returns its own exit code (always 0). The subshell's exit code is discarded.

**Detection:**
```bash
# Find die-capable instances (exclude safe: arithmetic, echo-pipe, fallback-or)
grep 'local [a-z_]*=\$(' script.sh \
    | grep -v 'echo.*|' \
    | grep -Fv '$((' \
    | grep -v '||'
```

**Mechanical fix (sed — preserves indentation):**
```bash
# Build line-targeted sed script, then apply with sed -f
for ln in $(grep -n 'local [a-z_]*=\$(' script.sh | grep -v 'echo.*|' | grep -Fv '$((' | grep -v '||' | cut -d: -f1); do
    printf '%ds/^\([[:space:]]*\)local \([a-z_][a-z_0-9]*\)=\(.*\)$/\1local \2\\\n\1\2=\3/\n' "$ln"
done > /tmp/split-locals.sed
sed -i '' -f /tmp/split-locals.sed script.sh  # macOS
```

**Safe instances to leave alone:**
- `local x=$(echo "$y" | tr ...)` — echo can't die
- `local x=$((expr))` — arithmetic, no subshell
- `local x=$(cmd ... || default)` — fallback-or always succeeds

## Landmine 2: `[[ ]] && die` as last statement

```bash
# BROKEN — if [[ ]] is false, && die doesn't run, function returns 1, set -e kills script
check_dir() {
    [[ -d "$1" ]] && return 0
    [[ -n "$1" ]] && die "Dir not found: $1"  # if $1 is empty, returns 1 → script aborts
}

# FIXED — if/fi always has explicit flow
check_dir() {
    if [[ -d "$1" ]]; then return 0; fi
    if [[ -n "$1" ]]; then die "Dir not found: $1"; fi
    die "Dir not configured"
}
```

**Why:** `[[ false ]] && cmd` evaluates to false (exit 1). If that's the function's last statement, the function returns 1, and `set -e` treats it as a failure.

**Detection:**
```bash
grep '\[\[.*\]\] && die' script.sh
```

**Fix:** Convert every instance to `if [[ ]]; then cmd; fi`.

## Landmine 3: `IFS read <<< "$(cmd)"` swallows die

```bash
# BROKEN — die inside find_device_id runs in $() subshell, exit swallowed by <<<
IFS=$'\t' read -r uuid name <<< "$(find_device_id "$app")"

# FIXED — two-step capture
local _fd_out
_fd_out=$(find_device_id "$app")  # die propagates here
IFS=$'\t' read -r uuid name <<< "$_fd_out"
```

**Why:** The `$()` in `<<< "$(cmd)"` runs cmd in a subshell. If cmd calls `die` (which calls `exit`), the exit only kills the subshell. The `read` still executes with empty input, and the script continues with empty variables.

## Landmine 4: `$()` subshell doesn't propagate globals

```bash
# BROKEN — FOUND_NAME set inside $() subshell, never reaches parent
FOUND_NAME=""
find_device() { FOUND_NAME="iPhone"; echo "uuid-123"; }
result=$(find_device)
echo "$FOUND_NAME"  # → '' (empty!)

# FIXED — structured return via stdout
find_device() { printf '%s\t%s' "uuid-123" "iPhone"; }
local _out
_out=$(find_device)
IFS=$'\t' read -r uuid name <<< "$_out"
```

**Why:** `$()` creates a subshell — a forked copy of the process. Variables set inside the copy don't propagate back.

## Audit Checklist

When reviewing any bash script under `set -euo pipefail`:

1. `grep 'local [a-z_]*=\$(' script.sh` → Split unless safe (echo-pipe, arithmetic, fallback-or)
2. `grep '\[\[.*\]\] && die' script.sh` → Convert to if/fi
3. `grep 'read.*<<<.*\$(' script.sh` → Two-step capture
4. Check any function that sets globals inside `$()` → Use structured return

## Evidence

- **gj-tool spec 007**: QuickUnion caught global-var approach (Landmine 4) during shaping — would have shipped a no-op fix where device name was always blank
- **gj-tool spec 007**: Planning caught IFS read swallowing (Landmine 3) — would have caused dual error messages on device failure
- **gj-tool spec 008**: 49 instances of Landmine 1 found and fixed mechanically with sed
- **gj-tool spec 006**: Landmine 2 caused `check_app_dir()` to abort script on success path (hotfix f6b94e5)

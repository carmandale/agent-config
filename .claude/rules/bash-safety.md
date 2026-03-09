# Bash Safety Pitfalls

When writing bash scripts with `set -euo pipefail`, these gotchas cause silent failures.

## `((var++))` Aborts on Zero

`((0++))` evaluates to 0, which bash treats as false. With `set -e`, the script exits silently.

```bash
# BAD — exits if pass is 0
((pass++))

# GOOD
pass=$((pass + 1))
```

## JSON Output — Never Interpolate

String interpolation in bash makes injection and quoting bugs inevitable. Use `jq --arg`.

```bash
# BAD — breaks on quotes, newlines, backslashes in values
echo "{\"key\": \"$value\"}"

# GOOD
jq -n --arg k "$key" --arg v "$value" '{check: $k, value: $v}'
```

## `timeout` Is Not Portable

GNU `timeout` exists on Linux. macOS has it via `brew install coreutils` (as `gtimeout` or `timeout` depending on PATH).

```bash
# Resolve once at script start
resolve_timeout_cmd() {
    if command -v timeout &>/dev/null; then
        TIMEOUT_CMD=timeout
    elif command -v gtimeout &>/dev/null; then
        TIMEOUT_CMD=gtimeout
    else
        TIMEOUT_CMD=""  # graceful degradation
    fi
}
```

## `git rev-parse --short` Length Varies

Different git versions and repo sizes produce different default short SHA lengths. Cross-machine comparisons fail.

```bash
# BAD — might produce 7 chars on one machine, 8 on another
git rev-parse --short HEAD

# GOOD — fixed length
git rev-parse --short=7 HEAD
```

## Source Sessions
- spec-011-machine-parity-verification (2026-03-09): All four pitfalls hit during parity-check.sh implementation

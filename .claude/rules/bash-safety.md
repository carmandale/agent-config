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

## macOS `sed` — Three Distinct Failure Modes

### `sed -i` Requires Backup Extension

macOS `sed` requires a backup extension argument after `-i`. GNU `sed` doesn't.

```bash
# BAD — macOS: "invalid command code" / GNU: works fine
sed -i 's/foo/bar/g' file.txt

# GOOD — empty string means no backup (portable)
sed -i '' 's/foo/bar/g' file.txt

# BETTER — use perl for complex patterns
perl -pi -e 's/foo/bar/g' file.txt
```

### `sed` Doesn't Support `\b` Word Boundaries

macOS `sed` uses POSIX BRE by default. `\b` is a PCRE extension — it silently matches literal `b`.

```bash
# BAD — matches "abd", "bdr", not word boundaries
sed -i '' 's/\bbd\b/br/g' file.txt

# GOOD — perl supports \b natively
perl -pi -e 's/\bbd\b/br/g' file.txt
```

### `sed` Frontmatter Parsing Matches ALL `---` Pairs

When extracting YAML frontmatter (between `---` delimiters), `sed` range patterns match every `---` pair in the file, not just the first.

```bash
# BAD — matches all --- pairs, not just frontmatter
sed -n '/^---$/,/^---$/p' file.md

# GOOD — awk with counter, stops after first block
awk '/^---$/{n++} n==1{next} n==2{print; next} n>2{exit}' file.md
```

## Source Sessions
- spec-011-machine-parity-verification (2026-03-09): `((var++))`, JSON interpolation, `timeout`, `git rev-parse --short`
- spec-010-beads-backend-evaluation (2026-03-09): `sed \b` failure during bulk bd→br migration, required perl fallback
- 2026-03-03: `sed` frontmatter parser matched all `---` pairs; TOML converter broke on backslash escapes

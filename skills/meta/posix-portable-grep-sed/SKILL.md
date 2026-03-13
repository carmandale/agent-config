---
name: posix-portable-grep-sed
description: "Portable grep/sed patterns for scripts that must run on macOS (BSD) and Linux (GNU). Use when writing shell scripts, static analysis tests, or CI pipelines that use grep or sed. Covers BRE/ERE escaping, grep -oP alternatives, bash version traps."
---

# POSIX Portable grep/sed

Rules for grep and sed that work identically on macOS (BSD) and Linux (GNU).

## DO

| Need | Portable | Why |
|------|----------|-----|
| Match literal `$((` | `grep -Fv '$(('` | `-F` = fixed string, no regex escaping needed |
| Match with alternation | `grep -E 'a\|b'` or `grep -e 'a' -e 'b'` | ERE is portable with `-E` |
| Extract substrings | `sed 's/.*pattern //' \| sed 's/[")].*//'` | POSIX sed pipeline |
| Case conversion | `echo "$var" \| tr '[:upper:]' '[:lower:]'` | `tr` is POSIX |
| In-place edit (macOS) | `sed -i '' 's/old/new/' file` | macOS sed requires `''` after `-i` |
| In-place edit (Linux) | `sed -i 's/old/new/' file` | GNU sed has no separator |
| Newline in replacement | Write sed script to file, use `sed -f` | macOS sed handles `\n` in file mode |

## DON'T

| Anti-pattern | Problem | Fix |
|-------------|---------|-----|
| `grep -oP '(?<=prefix)\w+'` | `-P` (PCRE) is GNU-only, not on macOS | Use `sed` pipeline |
| `grep -v '\$\(\('` | BRE treats `\(` as group start → `Unmatched (` | `grep -Fv '$(('` |
| `${var,,}` / `${var^^}` | Bash 4+ only; macOS ships bash 3.2 | `tr '[:upper:]' '[:lower:]'` |
| `readarray` / `mapfile` | Bash 4+ only | `while IFS= read -r line` loop |
| `declare -A` | Bash 4+ associative arrays | Use case statement or external tool |
| `grep -v '\|'` (filter pipes) | Too broad — catches any line with `\|` | `grep -v 'echo.*\|'` (narrow match) |

## Quick Diagnostic

```bash
# Check a script for non-portable patterns
grep -nE 'grep.*-[a-zA-Z]*P' script.sh        # grep -P (PCRE)
grep -nE '\$\{[a-zA-Z_]+,,\}' script.sh       # ${var,,}
grep -nE '\$\{[a-zA-Z_]+\^\^\}' script.sh     # ${var^^}
grep -nE 'readarray|mapfile|declare -A' script.sh  # bash 4+
```

## Evidence

- **gj-tool spec 006**: `${app,,}` broke `normalize_app()` on macOS bash 3.2
- **gj-tool spec 008 Codex R2**: `grep -v '\$\(\('` errored with `Unmatched ( or \(` in BRE mode — fixed with `grep -Fv`
- **gj-tool spec 008 Codex R2**: `grep -oP` was not portable and missed bare-argument callsites — replaced with sed pipeline

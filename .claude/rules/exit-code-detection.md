# Exit Code Detection

Never grep command output for failure strings. Always capture exit codes.

## Pattern

Output strings are unreliable: they change between versions, vary by locale, and can appear in non-error contexts. Exit codes are the contract.

## DO

```bash
# Capture exit code explicitly
local exit_code=0
output=$(some-command 2>&1) || exit_code=$?
if [[ "$exit_code" -ne 0 ]]; then
    echo "Failed with exit $exit_code"
fi
```

## DON'T

```bash
# WRONG: grep output for failure strings
output=$(some-command 2>&1) || true
if echo "$output" | grep -q "error"; then
    echo "Failed"  # False positives, false negatives, locale-dependent
fi
```

## Why This Matters

- `|| true` discards the exit code entirely — you can't recover it
- "error" may appear in success output (e.g., "0 errors found")
- Error messages change between tool versions without notice
- Non-English locales produce different error strings

## Source

- Spec 013: Navigator review caught `|| true` discarding flush exit codes — would have silently lost unflushed SQLite state during migration. Fix: `|| exit_code=$?` pattern.

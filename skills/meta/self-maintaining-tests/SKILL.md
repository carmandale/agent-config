---
name: self-maintaining-tests
description: "Design tests that derive assertions from source code, not hardcoded lists. Use when writing static analysis tests, config completeness checks, smoke test suites, or any test that validates properties of a codebase. Prevents test drift when source changes."
---

# Self-Maintaining Tests

Tests that hardcode values extracted from source code at write-time become stale the moment source changes. Instead, derive test data dynamically from the source.

## Principles

### 1. Derive from Source, Don't Hardcode

```bash
# BAD — hardcoded list drifts when code changes
required_vars="DIR PROJECT_TYPE PROJECT_FILE SCHEME PLATFORM SIMULATOR_NAME DERIVED_DATA_BASE"

# GOOD — extract from actual callsites
required_vars=$(grep 'get_app_var ' "$SRC" | sed 's/.*get_app_var [^ ]* //' | sed 's/[")].*//' | sort -u)
```

### 2. Allowlist-of-Safe Over Blocklist-of-Dangerous

When detecting banned patterns with known exceptions:

```bash
# BAD — blocklist of dangerous functions. New function added? Test doesn't catch it.
grep 'local [a-z_]*=\$(' src.sh | grep -v 'get_config\|get_value\|find_device'

# GOOD — allowlist of structurally-safe patterns. New unsafe function? Automatically caught.
grep 'local [a-z_]*=\$(' src.sh | grep -v 'echo.*|' | grep -Fv '$((' | grep -v '||'
```

The allowlist approach catches *any* new die-capable function without maintaining a list. The safe patterns are structurally distinctive (pipelines, arithmetic, fallback-or), not function-name-based.

### 3. Mutation Tests Use Temp Copies

Never mutate tracked files for verification — use temp copies with env var override:

```bash
# BAD — mutates tracked file, dirty tree if interrupted
echo 'bad pattern' >> bin/script.sh
bats tests/  # expects failure
git checkout bin/script.sh

# GOOD — temp copy, no risk to working tree
tmp=$(mktemp); cp "$GJ_BIN" "$tmp"
echo 'bad pattern' >> "$tmp"
GJ_BIN="$tmp" bats tests/  # expects failure
rm "$tmp"
```

### 4. Refactor Before Testing

Write static analysis tests against the *clean* state, not before:

```bash
# BAD — write test first, then refactor. Test starts "failing" and you have to skip it.
# GOOD — refactor 49 instances to zero FIRST, then assert count == 0
```

Per BrightRaven (gj-tool spec 008 shaping): "The static test that asserts zero unsafe patterns should be written against the clean state — after the refactor, not before."

### 5. Path Resolution Awareness

Test helpers must resolve paths relative to the test file, not the CWD:

```bash
# BAD — assumes CWD is repo root
GJ_BIN="bin/gj"

# BAD — wrong number of ../ levels
GJ_BIN="${BATS_TEST_DIRNAME}/../../bin/gj"  # exits repo from tests/

# GOOD — one level up from tests/ to repo root
GJ_BIN="${BATS_TEST_DIRNAME}/../bin/gj"
```

### 6. Partition by Capability

Group tests by what they require at runtime:

| Tier | Requires | Example |
|------|----------|---------|
| Always-safe | Nothing | version, help, syntax check |
| Tool-gated | Specific CLI | `skip if ! command -v xcrun` |
| Config-gated | Env/config file | `skip if [[ ! -f config.env ]]` |
| Hardware-gated | Physical device | Manual verification only |

This prevents CI failures on machines without optional dependencies.

## Evidence

- **gj-tool spec 008 Codex R1**: Static 10-var list didn't catch new `get_app_var` callsites — replaced with source-derived extraction
- **gj-tool spec 008 Codex R1**: Mutation tests on tracked files risked dirty tree — redesigned with temp copies + env override
- **gj-tool spec 008 Codex R2**: `../../bin/gj` from `tests/` resolved outside the repo — off-by-one in path traversal
- **gj-tool spec 008 Planning (SageMoon)**: Blocklist of die-capable functions drifts when new functions are added — switched to allowlist-of-safe
- **gj-tool spec 008 Shaping (BrightRaven)**: Refactor 49 instances before writing static test — assert against clean state

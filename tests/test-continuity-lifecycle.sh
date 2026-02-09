#!/usr/bin/env bash
# test-continuity-lifecycle.sh — Validate the full continuity lifecycle
#
# Tests: cc-artifact, discovery script, bead-ID search, frontmatter parsing,
#        date sorting, mode fallback, spaces in paths, edge cases.
#
# Usage:
#   ~/.agent-config/tests/test-continuity-lifecycle.sh [project-dir]
#
# If project-dir is omitted, uses CWD. The script creates test artifacts
# in a temp directory, runs all tests, then cleans up.

set -euo pipefail

# --- Config ---
CC_ARTIFACT="$HOME/.claude/scripts/cc-artifact"
PASS=0
FAIL=0
TOTAL=0
ERRORS=()

# --- Colors ---
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BOLD='\033[1m'
NC='\033[0m'

# --- Helpers ---
assert() {
  local name="$1"
  local condition="$2"
  TOTAL=$((TOTAL + 1))
  if eval "$condition"; then
    PASS=$((PASS + 1))
    echo -e "  ${GREEN}PASS${NC} $name"
  else
    FAIL=$((FAIL + 1))
    ERRORS+=("$name")
    echo -e "  ${RED}FAIL${NC} $name"
  fi
}

section() {
  echo -e "\n${BOLD}=== $1 ===${NC}"
}

# --- Setup ---
PROJECT_DIR="${1:-$(pwd)}"
if [[ ! -d "$PROJECT_DIR" ]]; then
  echo "Error: project directory does not exist: $PROJECT_DIR" >&2
  exit 1
fi

# Create an isolated test sandbox (with git init for branch detection)
TEST_DIR=$(mktemp -d)
TEST_HANDOFFS="$TEST_DIR/thoughts/shared/handoffs"
mkdir -p "$TEST_HANDOFFS"
git -C "$TEST_DIR" init -q
git -C "$TEST_DIR" commit --allow-empty -m "init" -q

cleanup() {
  rm -rf "$TEST_DIR"
  # Also clean up any test artifacts created in the real project
  rm -rf "$PROJECT_DIR/thoughts/shared/handoffs/__test-lifecycle-run__"
}
trap cleanup EXIT

echo -e "${BOLD}Continuity Lifecycle Test Suite${NC}"
echo "Project: $PROJECT_DIR"
echo "Sandbox: $TEST_DIR"
echo ""

# ============================================================
section "1. cc-artifact script basics"
# ============================================================

assert "cc-artifact exists and is executable" \
  "[[ -x '$CC_ARTIFACT' ]]"

assert "cc-artifact --help exits 0" \
  "'$CC_ARTIFACT' --help >/dev/null 2>&1"

assert "cc-artifact rejects missing --mode" \
  "! '$CC_ARTIFACT' >/dev/null 2>&1"

assert "cc-artifact rejects invalid mode" \
  "! '$CC_ARTIFACT' --mode bogus >/dev/null 2>&1"

assert "cc-artifact rejects handoff without --bead" \
  "! '$CC_ARTIFACT' --mode handoff --no-edit --session-title test --goal g --now n --outcome SUCCEEDED >/dev/null 2>&1"

assert "cc-artifact rejects finalize without --bead" \
  "! '$CC_ARTIFACT' --mode finalize --no-edit --session-title test --goal g --now n --outcome SUCCEEDED >/dev/null 2>&1"

assert "cc-artifact rejects invalid outcome" \
  "! '$CC_ARTIFACT' --mode checkpoint --no-edit --session-title test --goal g --now n --outcome BOGUS >/dev/null 2>&1"

assert "cc-artifact rejects --no-edit without required fields" \
  "! '$CC_ARTIFACT' --mode checkpoint --no-edit --session-title test >/dev/null 2>&1"

# ============================================================
section "2. Checkpoint creation (no bead)"
# ============================================================

CHECKPOINT_OUTPUT=$(cd "$TEST_DIR" && "$CC_ARTIFACT" \
  --mode checkpoint \
  --no-edit \
  --session-title "lifecycle-test-checkpoint" \
  --goal "Test the checkpoint flow" \
  --now "Running automated tests" \
  --outcome PARTIAL_PLUS 2>&1)
CHECKPOINT_PATH="$CHECKPOINT_OUTPUT"

assert "checkpoint file was created" \
  "[[ -f '$CHECKPOINT_PATH' ]]"

assert "checkpoint filename ends with _checkpoint.yaml" \
  "[[ '$CHECKPOINT_PATH' == *_checkpoint.yaml ]]"

assert "checkpoint filename contains session slug" \
  "[[ '$CHECKPOINT_PATH' == *lifecycle-test-checkpoint* ]]"

if [[ -f "$CHECKPOINT_PATH" ]]; then
  CHECKPOINT_CONTENT=$(cat "$CHECKPOINT_PATH")

  assert "checkpoint has schema_version" \
    "echo '$CHECKPOINT_CONTENT' | grep -q 'schema_version:'"

  assert "checkpoint mode is checkpoint" \
    "echo '$CHECKPOINT_CONTENT' | grep -q 'mode: checkpoint'"

  assert "checkpoint has date" \
    "echo '$CHECKPOINT_CONTENT' | grep -q 'date:'"

  assert "checkpoint has outcome PARTIAL_PLUS" \
    "echo '$CHECKPOINT_CONTENT' | grep -q 'PARTIAL_PLUS'"

  assert "checkpoint has goal" \
    "echo '$CHECKPOINT_CONTENT' | grep -q 'Test the checkpoint flow'"

  assert "checkpoint has git branch" \
    "echo '$CHECKPOINT_CONTENT' | grep -q 'branch:'"
fi

# ============================================================
section "3. Artifact in project dir (spaces in path)"
# ============================================================

PROJECT_ARTIFACT=$(cd "$PROJECT_DIR" && "$CC_ARTIFACT" \
  --mode checkpoint \
  --no-edit \
  --session-title "__test-lifecycle-run__" \
  --goal "Test spaces in path" \
  --now "Validating path handling" \
  --outcome SUCCEEDED 2>&1)

assert "artifact created in project with spaces in path" \
  "[[ -f '$PROJECT_ARTIFACT' ]]"

assert "artifact is inside thoughts/shared/handoffs/" \
  "[[ '$PROJECT_ARTIFACT' == *thoughts/shared/handoffs* ]]"

# ============================================================
section "4. Discovery script (Python)"
# ============================================================

# Clean up section 2 checkpoint so discovery has only controlled fixtures
rm -rf "$TEST_HANDOFFS/lifecycle-test-checkpoint"

# Create diverse test artifacts for discovery
mkdir -p "$TEST_HANDOFFS/session-alpha"
mkdir -p "$TEST_HANDOFFS/session-beta"
mkdir -p "$TEST_HANDOFFS/session-gamma"
mkdir -p "$TEST_HANDOFFS/events"

# Artifact 1: newest by date
cat > "$TEST_HANDOFFS/session-alpha/2026-02-05_14-00_alpha_handoff.yaml" <<'YAML'
---
schema_version: "1.0.0"
mode: handoff
date: 2026-02-05T14:00:00.000Z
session: "session-alpha"
outcome: "SUCCEEDED"
primary_bead: "test-bead-aaa"
---
goal: "Alpha session goal"
now: "Next steps for alpha"
YAML

# Artifact 2: middle date
cat > "$TEST_HANDOFFS/session-beta/2026-01-15_10-30_beta_checkpoint.yaml" <<'YAML'
---
schema_version: "1.0.0"
mode: checkpoint
date: 2026-01-15T10:30:00.000Z
session: "session-beta"
outcome: "PARTIAL_PLUS"
---
goal: "Beta session goal"
now: "Next steps for beta"
YAML

# Artifact 3: oldest date
cat > "$TEST_HANDOFFS/session-gamma/2025-12-01_08-00_gamma_finalize.yaml" <<'YAML'
---
schema_version: "1.0.0"
mode: finalize
date: 2025-12-01T08:00:00.000Z
session: "session-gamma"
outcome: "SUCCEEDED"
primary_bead: "test-bead-ggg"
---
goal: "Gamma session goal"
now: "All done"
YAML

# Artifact 4: old format (no mode field, uses status)
cat > "$TEST_HANDOFFS/session-beta/2026-01-10_05-00_old-format.yaml" <<'YAML'
---
schema_version: "1.0.0"
status: complete
date: 2026-01-10
outcome: "SUCCEEDED"
---
goal: "Old format artifact"
now: "Testing fallback"
YAML

# Artifact 5: no mode, no status — fallback to filename
cat > "$TEST_HANDOFFS/session-alpha/2026-01-20_12-00_bare_handoff.yaml" <<'YAML'
---
schema_version: "1.0.0"
date: 2026-01-20T12:00:00.000Z
outcome: "PARTIAL_MINUS"
primary_bead: "test-bead-bbb"
---
goal: "Bare handoff from filename"
now: "Verify mode detection"
YAML

# Artifact 6: event file (should be excluded)
cat > "$TEST_HANDOFFS/events/2026-02-01_event.yaml" <<'YAML'
---
type: event
date: 2026-02-01T00:00:00.000Z
---
should: "not appear in discovery"
YAML

# Run discovery
DISCOVERY_OUTPUT=$(cd "$TEST_DIR" && python3 - <<'PYEOF'
import os, re, pathlib, json

project = os.getcwd()
root = pathlib.Path(project) / "thoughts" / "shared" / "handoffs"
if not root.exists():
    print("NO_HANDOFFS_DIR")
    raise SystemExit

artifacts = []
for yaml_file in root.rglob("*.yaml"):
    if "events" in yaml_file.parts:
        continue
    try:
        text = yaml_file.read_text()
        match = re.search(r"^---\n(.*?)\n---", text, re.DOTALL)
        if not match:
            continue
        front = {}
        for line in match.group(1).splitlines():
            if ":" in line and not line.startswith("  "):
                key, _, val = line.partition(":")
                front[key.strip()] = val.strip().strip('"')

        mode = front.get("mode") or front.get("status", "")
        if not mode:
            fname = yaml_file.stem.lower()
            for m in ("handoff", "checkpoint", "finalize"):
                if m in fname:
                    mode = m
                    break
            else:
                mode = "unknown"

        date = front.get("date", "")
        bead = front.get("primary_bead", "")
        outcome = front.get("outcome", "")

        body = text[match.end():]
        goal_match = re.search(r"^goal:\s*[\"']?(.+?)[\"']?\s*$", body, re.MULTILINE)
        goal = goal_match.group(1).strip() if goal_match else ""

        artifacts.append({
            "path": str(yaml_file),
            "mode": mode,
            "date": date[:16],
            "bead": bead,
            "outcome": outcome,
            "goal": goal[:80],
        })
    except Exception:
        continue

if not artifacts:
    print("NO_ARTIFACTS_FOUND")
    raise SystemExit

artifacts.sort(key=lambda a: a["date"] or "0000", reverse=True)

# Output as JSON for easy parsing
print(json.dumps(artifacts))
PYEOF
)

# Parse discovery results
ARTIFACT_COUNT=$(echo "$DISCOVERY_OUTPUT" | python3 -c "import json,sys; print(len(json.load(sys.stdin)))")

assert "discovery found exactly 5 artifacts (not events)" \
  "[[ '$ARTIFACT_COUNT' == '5' ]]"

# Check sort order
FIRST_DATE=$(echo "$DISCOVERY_OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[0]['date'])")
LAST_DATE=$(echo "$DISCOVERY_OUTPUT" | python3 -c "import json,sys; d=json.load(sys.stdin); print(d[-1]['date'])")

assert "newest artifact is first (2026-02-05)" \
  "[[ '$FIRST_DATE' == '2026-02-05T14:00' ]]"

assert "oldest artifact is last (2025-12-01)" \
  "[[ '$LAST_DATE' == '2025-12-01T08:00' ]]"

# Check sort is actually descending
SORT_OK=$(echo "$DISCOVERY_OUTPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
dates = [a['date'] for a in data if a['date']]
print('yes' if all(dates[i] >= dates[i+1] for i in range(len(dates)-1)) else 'no')
")

assert "dates are sorted descending" \
  "[[ '$SORT_OK' == 'yes' ]]"

# Check mode detection
MODES=$(echo "$DISCOVERY_OUTPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
modes = sorted(set(a['mode'] for a in data))
print(' '.join(modes))
")

assert "no unknown modes (fallback works)" \
  "[[ ! '$MODES' == *unknown* ]]"

assert "mode fallback detected 'complete' from status field" \
  "[[ '$MODES' == *complete* ]]"

assert "mode fallback detected 'handoff' from filename" \
  "[[ '$MODES' == *handoff* ]]"

# Check events excluded
EVENTS_IN_RESULTS=$(echo "$DISCOVERY_OUTPUT" | python3 -c "
import json, sys
data = json.load(sys.stdin)
print(sum(1 for a in data if 'events' in a['path']))
")

assert "events/ directory excluded from discovery" \
  "[[ '$EVENTS_IN_RESULTS' == '0' ]]"

# ============================================================
section "5. Bead-ID search (find + grep)"
# ============================================================

# Search by filename/directory
BEAD_FIND=$(find "$TEST_HANDOFFS" -name "*.yaml" 2>/dev/null | grep -i "test-bead-aaa" || true)
assert "bead search by filename finds nothing (bead not in path)" \
  "[[ -z '$BEAD_FIND' ]]"

# Search by frontmatter
BEAD_GREP=$(grep -rl "primary_bead.*test-bead-aaa" "$TEST_HANDOFFS/" 2>/dev/null || true)
assert "bead search by frontmatter finds alpha artifact" \
  "[[ -n '$BEAD_GREP' ]]"

assert "bead frontmatter search returns correct file" \
  "[[ '$BEAD_GREP' == *alpha_handoff.yaml* ]]"

# Search for bead that appears in two artifacts
BEAD_MULTI=$(grep -rl "primary_bead.*test-bead-bbb" "$TEST_HANDOFFS/" 2>/dev/null | wc -l | tr -d ' ')
assert "bead search finds exactly 1 match for test-bead-bbb" \
  "[[ '$BEAD_MULTI' == '1' ]]"

# ============================================================
section "6. Frontmatter parsing edge cases"
# ============================================================

# Artifact with quoted values containing colons
mkdir -p "$TEST_HANDOFFS/edge-cases"
cat > "$TEST_HANDOFFS/edge-cases/2026-02-01_00-00_colon-test.yaml" <<'YAML'
---
schema_version: "1.0.0"
mode: checkpoint
date: "2026-02-01T00:00:00.000Z"
session: "edge: test with colons"
outcome: "PARTIAL_PLUS"
---
goal: "Test goal: with colon in value"
now: "Handle: tricky: parsing"
YAML

EDGE_OUTPUT=$(cd "$TEST_DIR" && python3 -c "
import re, pathlib
f = pathlib.Path('$TEST_HANDOFFS/edge-cases/2026-02-01_00-00_colon-test.yaml')
text = f.read_text()
match = re.search(r'^---\n(.*?)\n---', text, re.DOTALL)
front = {}
for line in match.group(1).splitlines():
    if ':' in line and not line.startswith('  '):
        key, _, val = line.partition(':')
        front[key.strip()] = val.strip().strip('\"')
print(front.get('mode', 'MISSING'))
print(front.get('outcome', 'MISSING'))
")

EDGE_MODE=$(echo "$EDGE_OUTPUT" | head -1)
EDGE_OUTCOME=$(echo "$EDGE_OUTPUT" | tail -1)

assert "frontmatter parses mode with colon-value neighbors" \
  "[[ '$EDGE_MODE' == 'checkpoint' ]]"

assert "frontmatter parses outcome correctly" \
  "[[ '$EDGE_OUTCOME' == 'PARTIAL_PLUS' ]]"

# Goal parsing with quotes
GOAL_OUTPUT=$(cd "$TEST_DIR" && python3 - "$TEST_HANDOFFS/edge-cases/2026-02-01_00-00_colon-test.yaml" <<'GOALPY'
import re, pathlib, sys
f = pathlib.Path(sys.argv[1])
text = f.read_text()
match = re.search(r"^---\n(.*?)\n---", text, re.DOTALL)
body = text[match.end():]
goal_match = re.search(r'^goal:\s*["\x27]?(.+?)["\x27]?\s*$', body, re.MULTILINE)
print(goal_match.group(1) if goal_match else "PARSE_FAILED")
GOALPY
)

assert "goal with colon parsed correctly" \
  "[[ '$GOAL_OUTPUT' == *'Test goal'* ]]"

# ============================================================
section "7. cc-artifact --stdout mode"
# ============================================================

STDOUT_OUTPUT=$(cd "$TEST_DIR" && "$CC_ARTIFACT" \
  --mode checkpoint \
  --stdout \
  --session-title "stdout-test" \
  --goal "Stdout test" \
  --now "Testing" \
  --outcome SUCCEEDED 2>&1)

assert "--stdout outputs YAML to stdout" \
  "echo '$STDOUT_OUTPUT' | grep -q 'schema_version'"

assert "--stdout includes mode" \
  "echo '$STDOUT_OUTPUT' | grep -q 'mode: checkpoint'"

assert "--stdout does not create a file" \
  "[[ ! -d '$TEST_DIR/thoughts/shared/handoffs/stdout-test' ]]"

# ============================================================
section "8. cc-artifact --output override"
# ============================================================

CUSTOM_PATH="$TEST_DIR/custom-output.yaml"
cd "$TEST_DIR" && "$CC_ARTIFACT" \
  --mode checkpoint \
  --no-edit \
  --output "$CUSTOM_PATH" \
  --session-title "custom-path" \
  --goal "Custom path test" \
  --now "Testing --output" \
  --outcome SUCCEEDED >/dev/null 2>&1

assert "--output creates file at custom path" \
  "[[ -f '$CUSTOM_PATH' ]]"

# ============================================================
section "9. Real project discovery (integration)"
# ============================================================

# Run discovery against the actual project directory
REAL_COUNT=$(cd "$PROJECT_DIR" && python3 -c "
import os, pathlib
project = os.getcwd()
root = pathlib.Path(project) / 'thoughts' / 'shared' / 'handoffs'
if not root.exists():
    print('0')
else:
    count = sum(1 for f in root.rglob('*.yaml') if 'events' not in f.parts and '__test-' not in str(f))
    print(count)
")

assert "real project has artifacts discoverable (>0)" \
  "[[ '$REAL_COUNT' -gt 0 ]]"

echo -e "\n  (Found $REAL_COUNT real artifacts in project)"

# ============================================================
section "10. Symlink integrity"
# ============================================================

assert "resume-handoff skill symlinked to ~/.claude/skills/" \
  "[[ -L '$HOME/.claude/skills/cc3/resume-handoff/SKILL.md' || -f '$HOME/.claude/skills/cc3/resume-handoff/SKILL.md' ]]"

assert "create-handoff skill symlinked to ~/.claude/skills/" \
  "[[ -L '$HOME/.claude/skills/cc3/create-handoff/SKILL.md' || -f '$HOME/.claude/skills/cc3/create-handoff/SKILL.md' ]]"

assert "handoff command symlinked to ~/.claude/commands/" \
  "[[ -L '$HOME/.claude/commands/handoff.md' || -f '$HOME/.claude/commands/handoff.md' ]]"

assert "checkpoint command symlinked to ~/.claude/commands/" \
  "[[ -L '$HOME/.claude/commands/checkpoint.md' || -f '$HOME/.claude/commands/checkpoint.md' ]]"

assert "finalize command symlinked to ~/.claude/commands/" \
  "[[ -L '$HOME/.claude/commands/finalize.md' || -f '$HOME/.claude/commands/finalize.md' ]]"

# ============================================================
section "11. Content consistency"
# ============================================================

# Verify no underscore typos remain
UNDERSCORE_HANDOFF=$(grep -c "resume_handoff" "$HOME/.agent-config/commands/handoff.md" 2>/dev/null || true)
UNDERSCORE_CHECKPOINT=$(grep -c "resume_handoff" "$HOME/.agent-config/commands/checkpoint.md" 2>/dev/null || true)

assert "handoff.md has no /resume_handoff typo" \
  "[[ '$UNDERSCORE_HANDOFF' == '0' ]]"

assert "checkpoint.md has no /resume_handoff typo" \
  "[[ '$UNDERSCORE_CHECKPOINT' == '0' ]]"

# Verify no $EDITOR in command Python blocks
EDITOR_HANDOFF=$(grep -c 'EDITOR' "$HOME/.agent-config/commands/handoff.md" 2>/dev/null || true)
EDITOR_CHECKPOINT=$(grep -c 'EDITOR' "$HOME/.agent-config/commands/checkpoint.md" 2>/dev/null || true)
EDITOR_FINALIZE=$(grep -c 'EDITOR' "$HOME/.agent-config/commands/finalize.md" 2>/dev/null || true)

assert "handoff.md has no EDITOR references" \
  "[[ '$EDITOR_HANDOFF' == '0' ]]"

assert "checkpoint.md has no EDITOR references" \
  "[[ '$EDITOR_CHECKPOINT' == '0' ]]"

assert "finalize.md has no EDITOR references" \
  "[[ '$EDITOR_FINALIZE' == '0' ]]"

# Verify create-handoff is deprecated
DEPRECATED=$(grep -c "DEPRECATED" "$HOME/.agent-config/skills/cc3/create-handoff/SKILL.md" 2>/dev/null || true)

assert "create-handoff SKILL.md contains DEPRECATED notice" \
  "[[ '$DEPRECATED' -gt 0 ]]"

# ============================================================
# Report
# ============================================================

echo ""
echo -e "${BOLD}════════════════════════════════${NC}"
if [[ $FAIL -eq 0 ]]; then
  echo -e "${GREEN}${BOLD}ALL $TOTAL TESTS PASSED${NC}"
else
  echo -e "${RED}${BOLD}$FAIL of $TOTAL TESTS FAILED${NC}"
  echo ""
  echo "Failed tests:"
  for err in "${ERRORS[@]}"; do
    echo -e "  ${RED}- $err${NC}"
  done
fi
echo -e "${BOLD}════════════════════════════════${NC}"

exit $FAIL

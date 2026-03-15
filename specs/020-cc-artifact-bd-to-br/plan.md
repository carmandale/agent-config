---
title: "cc-artifact bd-to-br migration — Implementation Plan"
date: 2026-03-14
bead: .agent-config-324
---

<!-- plan:complete:v1 | harness: pi/claude-sonnet-4 | date: 2026-03-14T13:52:17Z -->

# Implementation Plan: cc-artifact bd-to-br migration gap

## Approach

Move Category 1 scripts from `~/.claude/scripts/` to `tools-bin/` in agent-config, rename with agent-agnostic names, fix `bd` → `br` references, make the artifact script self-validating, remove duplicated consumer validation, and add a structural test to prevent recurrence.

Selected Shape C from shaping. See `shaping-transcript.md` for alternatives considered.

## Scope Decisions (from planning collaboration)

| Item | Decision | Rationale |
|------|----------|-----------|
| cc-synthesize | **Deferred** — separate bead | Depends on `~/.claude/hooks/dist/synthesize-ledgers.mjs` at runtime. Moving to tools-bin/ would look managed but still reach back to Claude hooks at runtime — creating false sense of "managed." No shared consumers = no urgency. Spec updated to reflect this deferral with rationale. |
| Phantom scripts (aggregate-reasoning.sh, search-reasoning.sh) | **Update paths only** — separate bead for creation | Referenced by skills but don't exist on disk. Pre-existing breakage, not migration scope. Update path references so they work when scripts are eventually created in tools-bin/. Spec updated to reflect this deferral. |
| Category 2 scripts (project-relative via runtime harness) | **Out of scope** — separate bead | Different architectural problem (project-layout dependency vs user-home dependency). |

**Note on deferrals vs spec scope**: The original spec listed all Category 1 scripts in the "In scope" table. During planning collaboration (see `planning-transcript.md`), cc-synthesize and phantom scripts were deferred with documented rationale. The spec's scope table must be updated to match — deferrals are tracked via follow-up beads in tasks.md Phase 7.

## Architecture

### Before

```
~/.claude/scripts/cc-artifact  ← unmanaged, Claude-specific, uses bd
     ↑
commands/{finalize,handoff,checkpoint}.md  ← hardcoded path + broken inline validation
skills/{continuity-ledger,resume-handoff}  ← hardcoded path
```

### After

```
~/.agent-config/tools-bin/agent-artifact  ← tracked, agent-agnostic, uses br, self-validating
     ↑
commands/{finalize,handoff,checkpoint}.md  ← bare name, no inline validation (trust exit code)
skills/{continuity-ledger,resume-handoff}  ← bare name
```

## Detailed Changes

### Phase 1: Create agent-artifact in tools-bin/

**Source**: `~/.claude/scripts/cc-artifact` (367 lines)
**Destination**: `tools-bin/agent-artifact`

#### bd → br substitutions (6 occurrences, each verified)

| Line | Old | New | Verified |
|------|-----|-----|----------|
| 141 | `command -v bd` | `command -v br` | br is on PATH via Homebrew |
| 142 | `bd show "$PRIMARY_BEAD"` | `br show "$PRIMARY_BEAD"` | exit 3 on not-found, exit 0 on found |
| 144 | `"Run: bd list --status in_progress --json"` | `"Run: br list --status in_progress --json"` | br supports --json shorthand |
| 155 | `"bd"` (Python subprocess call) | `"br"` | br list --status in_progress --json → same output format, "id" field present |
| 169 | `"bd update $PRIMARY_BEAD --status=in_progress"` | `"br update $PRIMARY_BEAD --status=in_progress"` | br update syntax confirmed identical |
| 172 | `"Warning: bd not found; skipping bead validation."` | Hard error: `"Error: br not found. Install with: cargo install beads_rust"` + exit 1 | R1: no silent skip |

#### Behavior change: br not found → hard error (R1)

Current behavior (lines 140-173):
```bash
if command -v bd >/dev/null 2>&1; then
  # validate...
else
  echo "Warning: bd not found; skipping bead validation." >&2  # ← silent skip
fi
```

New behavior:
```bash
if ! command -v br >/dev/null 2>&1; then
  echo "Error: br not found. Install: cargo install beads_rust (or see configs/br-version.txt)" >&2
  exit 1
fi
# validate (no else branch — br must be present)
```

#### Robust br error handling (R4)

`br show` returns distinct exit codes: exit 0 (found), exit 3 (ISSUE_NOT_FOUND), exit 2 (DATABASE_ERROR). The script must distinguish these:

```bash
br show "$PRIMARY_BEAD" >/dev/null 2>&1
br_exit=$?
if [[ "$br_exit" -eq 3 ]]; then
  echo "Error: bead not found: $PRIMARY_BEAD" >&2
  echo "Run: br list --status in_progress --json" >&2
  exit 1
elif [[ "$br_exit" -eq 2 ]]; then
  echo "Error: beads database error while checking: $PRIMARY_BEAD" >&2
  echo "Check: is the .beads/*.db accessible? Try: br list" >&2
  exit 1
elif [[ "$br_exit" -ne 0 ]]; then
  echo "Error: br failed unexpectedly (exit $br_exit) checking bead: $PRIMARY_BEAD" >&2
  exit 1
fi
```

Three distinct branches: exit 3 (not-found → user error), exit 2 (database → infrastructure error), other non-zero (unexpected → bug report).

#### New: self-validation before printing path (R9)

Add path structure checks to the existing internal validation block (after line 365), before the final `echo "$FILE_PATH"`:

1. Verify file exists at `$FILE_PATH`
2. If `PRIMARY_BEAD` is set, verify bead ID appears in the directory component of `FILE_PATH`
3. Verify filename ends with `_${MODE}.yaml`

Exit non-zero with descriptive error if any check fails. This makes exit 0 + printed path a contract: if the script succeeds, the path is guaranteed correct.

### Phase 2: Move generate-reasoning.sh to tools-bin/

**Source**: `~/.claude/scripts/generate-reasoning.sh` (86 lines)
**Destination**: `tools-bin/generate-reasoning.sh`

Standalone script, no external dependencies beyond git and jq. No modifications needed beyond the move.

### Phase 3: Update consumer commands

Three files with nearly identical changes:

#### commands/finalize.md (5 path refs + validation removal)

| Line | Change |
|------|--------|
| 2 | Description: `~/.claude/scripts/cc-artifact` → `agent-artifact (via tools-bin/)` |
| 7 | Prose: `~/.claude/scripts/cc-artifact` → `agent-artifact` |
| 213 | Python: `os.path.expanduser("~/.claude/scripts/cc-artifact")` → `"agent-artifact"` (bare name, found via PATH via `shutil.which`) |
| 255-256 | Remove the "IMPORTANT" validation instruction — trust script exit code |

Remove the inline Python validation block (lines ~230-260 — the `path = pathlib.Path(...)` through `raise SystemExit`) that checks:
- `bead not in path.name` ← **currently broken** (bead is in directory name, not filename)
- `path.name.endswith("_finalize.yaml")`
- frontmatter mode/primary_bead checks

Replace with: "If the script exits non-zero, show the error and stop. If it exits 0, the printed path is the artifact — read and fill it in."

The Python invocation block itself needs updating: use `shutil.which("agent-artifact")` to resolve the bare name to an absolute path, then `subprocess.run(cmd, ...)`.

**Note on `--no-edit` contract**: The current consumer commands call `agent-artifact --no-edit` without passing `--goal`, `--now`, `--outcome`. The script rejects this combination (line 255). In practice, agents handle the error dynamically by retrying with the required fields. This is pre-existing behavior that our migration preserves — we do not change the `--no-edit` validation logic. The self-validation (R9) covers path structure correctness, not the `--no-edit` argument contract.

**PATH resolution safety**: In `.zshenv`, line 18 adds `tools-bin/` then line 19 prepends `~/.local/bin/` — so `~/.local/bin/` actually ends up BEFORE `tools-bin/` in the final PATH. To prevent shadowing by a rogue binary in `~/.local/bin/`, the consumer Python block resolves the path AND verifies it points to the expected location:

```python
import shutil, os

artifact_cmd = shutil.which("agent-artifact")
if not artifact_cmd:
    raise SystemExit("agent-artifact not found on PATH. Is ~/.agent-config/tools-bin/ on PATH?")

# Verify it resolves to the exact expected file in tools-bin/ (not a shadow)
expected_path = os.path.realpath(os.path.expanduser("~/.agent-config/tools-bin/agent-artifact"))
actual_path = os.path.realpath(artifact_cmd)
if actual_path != expected_path:
    raise SystemExit(
        f"agent-artifact resolved to {artifact_cmd} (real: {actual_path}) — "
        f"expected {expected_path}. "
        f"Check for shadowing binaries in earlier PATH entries."
    )
```

#### commands/handoff.md — same pattern as finalize.md

Same 5 path refs, same validation block removal. The broken `bead not in path.name` check is identical.

#### commands/checkpoint.md — similar, slightly different

Same path refs. Validation is simpler (no bead-in-path check since bead is optional for checkpoints), but still duplicates the frontmatter check. Remove it — same trust-exit-code pattern.

### Phase 4: Update skill files

| File | Line | Old | New |
|------|------|-----|-----|
| `skills/meta/continuity-ledger/SKILL.md` | 17 | `~/.claude/scripts/cc-artifact --mode ...` | `agent-artifact --mode ...` |
| `skills/meta/git-commits/SKILL.md` | 40 | `bash .claude/scripts/generate-reasoning.sh` | `generate-reasoning.sh` |
| `skills/workflows/commit/SKILL.md` | 35 | `bash .claude/scripts/generate-reasoning.sh` | `generate-reasoning.sh` |
| `skills/workflows/commit/SKILL.v6.md` | — | `bash .claude/scripts/generate-reasoning.sh` | `generate-reasoning.sh` |
| `skills/workflows/describe-pr/SKILL.md` | 37 | `bash .claude/scripts/aggregate-reasoning.sh` | `aggregate-reasoning.sh` (phantom — path update only) |
| `skills/workflows/recall-reasoning/SKILL.md` | 34, 52 | `bash .claude/scripts/search-reasoning.sh` | `search-reasoning.sh` (phantom — path update only) |
| `skills/workflows/resume-handoff/SKILL.md` | 284 | Example path containing `cc-artifact` | Leave as-is (historical artifact example, not an invocation) |

### Phase 5: Structural enforcement test (R8)

**File**: `tests/test-no-agent-specific-paths.sh`

Scan shared content for hardcoded agent-specific executable paths. Pattern:

**What to flag** (antipattern — user-home absolute paths to agent-specific script locations):
- `~/.claude/scripts/`
- `os.path.expanduser("~/.claude/`
- `$HOME/.claude/scripts/`
- Equivalent patterns for `~/.codex/scripts/`, `~/.pi/agent/scripts/`

**What NOT to flag**:
- `$CLAUDE_PROJECT_DIR/.claude/` — project-relative, Category 2 (out of scope)
- `./.claude/scripts/` — project-relative
- Paths inside `**/references/**` directories — third-party documentation
- `~/.claude/` in non-script contexts (e.g., `~/.claude/settings.json` in documentation about configuration)

**Scope**: `commands/*.md` and `skills/**/SKILL*.md` files (includes SKILL.md, SKILL.v6.md, etc. — skip reference subdirectories, READMEs, .bak files).

**Pattern**: Follow `test-symlink-parity.sh` structure — assert/pass/fail counting, colored output, descriptive error messages.

### Phase 6: Update existing tests

**File**: `tests/test-continuity-lifecycle.sh`

Line 16 hardcodes `CC_ARTIFACT="$HOME/.claude/scripts/cc-artifact"`. Update to:
```bash
CC_ARTIFACT="$(command -v agent-artifact)"
```

Run the test after updating to verify it still passes with the new path.

### Phase 7: Cleanup

1. Verify tools-bin/agent-artifact works: run with `--help` and test a real invocation
2. Verify all consumers reference the new bare name
3. Remove `~/.claude/scripts/cc-artifact` from laptop
4. Remove `~/.claude/scripts/generate-reasoning.sh` from laptop
5. Do NOT remove `~/.claude/scripts/cc-synthesize` — deferred, still in use at old location

## Blast Radius

| Area | Impact | Risk |
|------|--------|------|
| `/finalize`, `/handoff`, `/checkpoint` | Path + validation changes | Medium — most-used lifecycle commands |
| `agent-artifact` script | bd→br + self-validation | Low — isolated changes, verified CLI equivalents |
| `generate-reasoning.sh` | Move only, no code changes | Low |
| Skill files | Path string updates | Low — no logic changes |
| New test | Additive | None |
| Mini parity | Automatic via `git pull` | Low — tools-bin/ is already on PATH there |

## Requirement Traceability

| Req | Addressed by |
|-----|-------------|
| R0 | Phase 1: bd→br substitutions |
| R1 | Phase 1: hard error when br not found |
| R2 | Phase 3: remove broken consumer validation |
| R3 | Phase 1+2: scripts tracked in tools-bin/ |
| R4 | Phase 1: each substitution verified (exit codes, JSON format, flags) |
| R5 | Phase 1: all 6 bd refs replaced |
| R6 | Phase 3+4: bare name invocation |
| R7 | Phase 1+2: cc-artifact → agent-artifact, generate-reasoning.sh (no cc- prefix) |
| R8 | Phase 5: test-no-agent-specific-paths.sh |
| R9 | Phase 1 (self-validation) + Phase 3 (remove consumer validation) |

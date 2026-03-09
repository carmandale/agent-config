# 011: Machine Parity Verification — Planning Transcript

**Proposer:** SwiftKnight2 (pi/claude-opus-4-6)
**Challenger:** YoungKnight (pi/claude-sonnet-4-6, crew-challenger)
**Date:** 2026-03-09

## Research Phase (SwiftKnight2)

Investigated:
- Existing scripts in `~/.agent-config/scripts/` (6 scripts, setup.sh pattern)
- Exact command outputs on both machines for all planned checks
- pi list output format (multiline, spaces in laptop path)
- Homebrew formula counts (289 laptop vs 84 mini) → Brewfile approach (20 canonical packages)
- SSH heredoc key=value batching (tested live)
- pi-messenger path resolution on both machines (tested live)

## Challenge Round 1 (YoungKnight → SwiftKnight2)

5 bugs found with concrete verification:

1. **CRITICAL**: `codex --version` produces WARNING on stderr + version on second line → breaks key=value parser. Fix: `2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1`

2. **CRITICAL**: `set -euo pipefail` doesn't abort inside `$()` — missing tools silently captured as "command not found". Fix: `is_missing()` helper with pattern detection.

3. **HIGH**: Brewfile tap-qualified names (`steipete/tap/peekaboo`) don't match `brew list` output (`peekaboo`). Fix: `${pkg##*/}` normalization.

4. **HIGH**: pi-messenger path extraction underspecified, breaks on spaces in laptop path. Fix: `grep "messenger" | grep -E '^\s+/' | tail -1 | xargs`

5. **MODERATE**: No SSH timeout violates R8. Fix: `ConnectTimeout=5`, `BatchMode=yes`, exit code 2 for SSH failure.

All 5 accepted with concrete fixes.

## Challenge Round 2 (YoungKnight → SwiftKnight2)

3 additional issues:

6. **BLOCK**: `--json` via bash string interpolation produces invalid JSON on values with quotes. Fix: `jq -n --arg` only. jq is in Brewfile.

7. **WARN**: `grep -A1 "messenger" | tail -1` fragile if multiple messenger packages. Fix: hardened grep form in implementation.

8. **WARN**: openclaw beta suffix stripped by semver regex. Fix: raw `head -1` for openclaw (no regex normalization). Documented as known limitation.

All 3 accepted. Plan incorporates all 8 fixes.

## Agreement

Both agents agreed plan is solid after all 8 issues were addressed. Plan.md and tasks.md written.

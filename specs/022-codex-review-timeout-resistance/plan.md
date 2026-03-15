---
title: "Plan — Codex review timeout resistance"
date: 2026-03-14
bead: .agent-config-1ek
---

<!-- plan:complete:v1 | harness: pi/claude-opus-4-6 | date: 2026-03-14T15:41:35Z -->

# Plan — Wrapper script for codex review invocation

## Selected approach

**Wrapper script in `tools-bin/`** that encapsulates the entire codex exec invocation. Agents never run codex directly — they write the prompt file (which they're good at), call the script (one short command), and read the output file.

This eliminates the agent's opportunity to add bash tool timeouts, `| tail` pipes, or any other invocation-mangling behavior. The script handles everything the agent is bad at; the agent handles everything it's good at.

### Why wrapper script over template-only fix

Spec 017 tried the template-only approach. It added anti-patterns saying "don't use timeout." MintWolf's session (2026-03-14, d7013d18) proved it insufficient: agent set `"timeout": 300` on the bash tool parameter — technically different from the shell `timeout` command the anti-pattern prohibited, functionally identical. Template-only fixes cannot control tool call parameters.

## Architecture

### Script location: `tools-bin/codex-review-exec`

`~/.agent-config/tools-bin` is already on PATH. The script is callable as `codex-review-exec` from any project directory — no path resolution needed. Follows the same convention as `agent-config-parity` in `tools-bin/`.

### Script interface

```
codex-review-exec \
  --prompt /tmp/codex-prompt-XXXX.md \
  --output /tmp/codex-review-XXXX.md \
  [--model MODEL]              # optional — omit to use codex config.toml default
  [--session SESSION_ID]       # optional — for resume mode
```

### Script internals (what it does)

1. **Validate inputs**: prompt file exists and is non-empty. Fail with diagnostic if not.
2. **Remove stale output**: `rm -f "$OUTPUT_FILE"`
3. **Disable `set -e`**: `set +e` before the codex invocation so a non-zero exit from codex doesn't kill the script before diagnostics run.
4. **Run codex**:
   - If `--session` provided: `codex exec resume "$SESSION_ID" -s read-only -o "$OUTPUT_FILE" - < "$PROMPT_FILE"`
   - If `--session` AND `--model` both provided: ignore `--model`, print warning to stderr ("--model ignored in resume mode")
   - Else if `--model` provided: `codex exec -m "$MODEL" -s read-only -o "$OUTPUT_FILE" - < "$PROMPT_FILE"`
   - Else: `codex exec -s read-only -o "$OUTPUT_FILE" - < "$PROMPT_FILE"`
5. **Capture exit code**: `CODEX_EXIT=$?`
6. **Re-enable `set -e`**: `set -e`
5. **Validate output**: check file exists (`-f`) AND non-empty (`-s`)
6. **Exit**:
   - Exit 0 if output file valid — print `SUCCESS: <bytes> bytes written to <output_file>`
   - Exit 1 if codex failed or output missing — print diagnostics (exit code, file existence, troubleshooting hints)

### What the script does NOT do

- **No timeout.** No `timeout` command, no signal traps on timers, nothing.
- **No stderr capture.** Codex stderr flows directly to the caller's terminal. The agent's bash tool captures it in its output, where the session ID appears. The script does not parse, tee, grep, or intercept stderr.
- **No session ID parsing.** The agent extracts the session ID from the bash tool output as it does today. The script is not responsible for session ID management.
- **No model default.** If `--model` is omitted, the script does not pass `-m` to codex. Codex uses its own `~/.codex/config.toml` default.

## Changes to `commands/codex-review.md`

### Anti-patterns section update

Add one new anti-pattern to the existing 4:

```markdown
- ❌ **Do NOT set a `timeout` parameter on the bash tool call.** Not 300 seconds, not 600, not any value. Codex reviews take 5-30 minutes depending on codebase size. This is normal — there is no hang to protect against.
```

### Step 3 rewrite (initial invocation)

**Current**: Three sub-steps (A: write prompt file, B: run codex one-liner, C: error check block)

**Revised**: Two sub-steps:
- **Step A**: Write prompt file to `/tmp/codex-prompt-${REVIEW_ID}.md` using file-write tool (unchanged)
- **Step B**: Run wrapper script:

```bash
codex-review-exec --prompt /tmp/codex-prompt-${REVIEW_ID}.md --output /tmp/codex-review-${REVIEW_ID}.md
```

If script exits non-zero, STOP. Diagnostics are in the script output.

If script exits 0, capture the session ID from the bash tool output — look for `session id: <uuid>` in the terminal output from the script call. Store as `CODEX_SESSION_ID`.

**Step C (error check block) is eliminated** — the script handles validation internally.

### Step 4 update (text)

Remove session ID capture guidance that's now redundant with Step 3B. Keep all verdict checking, adversarial gate, and branching logic unchanged.

### Step 5 rewrite (resume invocation)

**Current**: Three sub-steps (A: write resume prompt, B: codex exec resume one-liner, C: error check)

**Revised**: Two sub-steps:
- **Step A**: Write resume prompt to `/tmp/codex-prompt-${REVIEW_ID}.md` (unchanged)
- **Step B**: Run wrapper script with session:

```bash
codex-review-exec --prompt /tmp/codex-prompt-${REVIEW_ID}.md --output /tmp/codex-review-${REVIEW_ID}.md --session ${CODEX_SESSION_ID}
```

If non-zero, fall back to fresh exec (also via script, without `--session`).

**Step C (error check block) is eliminated.**

### Step 6 update (cleanup)

No change to cleanup logic. The cleanup command already lists all three temp files. The `gate.sh record` and `gate.sh verify` calls remain.

### Model override

The current template says agents should use `gpt-5.3-codex` as default. With the wrapper script:
- Default (no override): `codex-review-exec --prompt ... --output ...` — codex uses its config.toml default
- User override (e.g., `/codex-review o4-mini`): `codex-review-exec --prompt ... --output ... --model o4-mini`

Update the template notes to reflect that `--model` is optional and defaults to codex's own config.

## Risk analysis

| Risk | Severity | Mitigation |
|------|----------|------------|
| Agent still adds `timeout` to script call | Low | Script call is short/simple — less tempting than raw codex. Anti-pattern explicitly calls out bash tool timeout parameter. |
| Script not on PATH in some environment | Low | `tools-bin/` is added to PATH by `install.sh`. If missing, `codex-review-exec` fails loudly — not silently. |
| Codex changes session ID output format | None (for script) | Script doesn't parse session ID. Agent does, same as today. |
| Agent forgets to pass `--session` on resume | Low | Script runs fresh exec instead of resume — still works, just loses conversation context. |
| Agent doesn't write prompt file | Low | Script validates prompt file exists — fails immediately with clear diagnostic. |

## Files touched

1. **`tools-bin/codex-review-exec`** — NEW (~60-80 lines bash)
2. **`commands/codex-review.md`** — MODIFIED (Steps 3, 5 rewritten; anti-patterns updated; model notes updated)

## Verification

1. Run `codex-review-exec --prompt /tmp/test-prompt.md --output /tmp/test-output.md` with a simple prompt — verify output file written, exit 0.
2. Run with missing prompt file — verify exit 1 with diagnostic.
3. Run with `--session` (resume) — verify codex resumes in context.
4. Run with `--model o4-mini` — verify model override works.
5. Verify `codex-review-exec` is callable from a different project directory (e.g., `cd ~/dev/hsbc && codex-review-exec --help`).
6. Full `/codex-review` smoke test against an existing spec — verify the end-to-end loop works with the wrapper.

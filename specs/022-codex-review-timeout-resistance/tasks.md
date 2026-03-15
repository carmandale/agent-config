---
title: "Tasks — Codex review timeout resistance"
date: 2026-03-14
bead: .agent-config-1ek
---

<!-- plan:complete:v1 | harness: pi/claude-opus-4-6 | date: 2026-03-14T15:41:35Z -->

# Tasks

Two files changed. Script first, then command template update referencing the script.

## Checklist

- [x] **Task 1: Create `tools-bin/codex-review-exec`**
  New bash script (~60-80 lines). Portable bash, `set -euo pipefail`, no exotic dependencies.

  Interface: `--prompt FILE --output FILE [--model MODEL] [--session SESSION_ID]`

  Implementation:
  1. Parse args with while/case loop
  2. Validate: `--prompt` and `--output` required. Prompt file must exist and be non-empty.
  3. `rm -f "$OUTPUT_FILE"`
  4. `set +e` — disable errexit so codex non-zero exit doesn't kill script before diagnostics
  5. Build and run codex command (NO timeout, stderr passes through to caller):
     - With `--session`: `codex exec resume "$SESSION_ID" -s read-only -o "$OUTPUT_FILE" - < "$PROMPT_FILE"`
     - With `--model`: `codex exec -m "$MODEL" -s read-only -o "$OUTPUT_FILE" - < "$PROMPT_FILE"`
     - Neither: `codex exec -s read-only -o "$OUTPUT_FILE" - < "$PROMPT_FILE"`
     - Both `--session` and `--model`: ignore `--model`, print warning to stderr: `"WARNING: --model ignored in resume mode (codex resume uses the original session's model)"`
  6. `CODEX_EXIT=$?`
  7. `set -e` — re-enable errexit
  7. Check output: `[ -s "$OUTPUT_FILE" ]`
  8. Exit 0 + success message if valid. Exit 1 + diagnostics if not.
  9. `chmod +x tools-bin/codex-review-exec`

- [x] **Task 2: Add bash tool timeout anti-pattern** — depends: none (parallel with task 1)
  In `commands/codex-review.md`, add 5th anti-pattern bullet after the existing 4 in the "INVOCATION ANTI-PATTERNS" section (after line 63):

  ```markdown
  - ❌ **Do NOT set a `timeout` parameter on the bash tool call.** Not 300 seconds, not 600, not any value. Codex reviews take 5-30 minutes depending on codebase size. This is normal — there is no hang to protect against.
  ```

- [x] **Task 3: Rewrite Step 3 (initial invocation)** — depends: task 1
  Replace the current Step 3 sub-steps B and C (the codex one-liner + error check block, approximately lines 152-175) with:

  Step B — single bash block calling wrapper:
  ```bash
  codex-review-exec --prompt /tmp/codex-prompt-${REVIEW_ID}.md --output /tmp/codex-review-${REVIEW_ID}.md
  ```
  (Add `--model MODEL` only if user specified a model override.)

  Below it: "If script exits non-zero, STOP. Diagnostics are in the script output. If exit 0, capture the session ID — look for `session id: <uuid>` in the terminal output from the script call. Store as `CODEX_SESSION_ID`."

  Remove the standalone Step C error check block entirely.

  Update the Notes section below Step 3 to explain that `--model` is optional (codex uses config.toml default when omitted).

- [x] **Task 4: Remove redundant session ID guidance from Step 4** — depends: task 3
  The current Step 3 has a "Capture the Codex session ID" paragraph and a "Note: The session ID appears..." paragraph. These are now covered in Step 3B's wrapper instructions. Remove the standalone paragraphs that duplicated this guidance. Keep all verdict checking, adversarial gate, and branching logic unchanged.

- [x] **Task 5: Rewrite Step 5 Part B (resume invocation)** — depends: task 3
  Replace the current Step 5 sub-steps B and C (the resume one-liner + error check block) with:

  Step B — single bash block calling wrapper:
  ```bash
  codex-review-exec --prompt /tmp/codex-prompt-${REVIEW_ID}.md --output /tmp/codex-review-${REVIEW_ID}.md --session ${CODEX_SESSION_ID}
  ```

  Below it: "If script exits non-zero, STOP. Diagnostics are in the script output."

  Update fallback guidance: "If resume fails (e.g., session expired), fall back to a fresh exec — also via `codex-review-exec`, without `--session`."

  Remove the standalone Step C error check block.

- [x] **Task 6: Update revision metadata** — depends: task 5
  Bump frontmatter: `revision: 3` → `revision: 4`, `revision_date: 2026-03-12` → `revision_date: 2026-03-14`.

- [x] **Task 7: Verification** — depends: all above
  Two-part verification:

  **Part A — Script standalone:**
  1. Write a simple test prompt to `/tmp/test-prompt.md`
  2. Run: `codex-review-exec --prompt /tmp/test-prompt.md --output /tmp/test-output.md`
  3. Verify: exit 0, output file exists and non-empty, session ID visible in terminal output
  4. Run with missing prompt: `codex-review-exec --prompt /tmp/nonexistent.md --output /tmp/test-output.md` — verify exit 1 with diagnostic
  5. Run from different directory: `cd ~/dev/hsbc && codex-review-exec --prompt /tmp/test-prompt.md --output /tmp/test-output2.md` — verify script is on PATH
  6. Cleanup test files

  **Part B — Template review:**
  1. Read the updated `commands/codex-review.md`
  2. Verify: no raw `codex exec` commands remain in Steps 3 or 5
  3. Verify: 5 anti-patterns present (including bash tool timeout)
  4. Verify: Step 3C and Step 5C error check blocks are gone
  5. Verify: revision bumped to 4, date to 2026-03-14
  6. Verify: review loop logic (Steps 4, 6) unchanged

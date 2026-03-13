<!-- Codex Review: APPROVED after 2 rounds | model: gpt-5.3-codex | date: 2026-03-12 -->
<!-- Status: REVISED -->
<!-- Revisions: Task 1 renamed to "INVOCATION anti-patterns" with duplication note; Task 8 split into Part A (initial exec) + Part B (forced resume) with AC-to-check mapping; dependency chain justification added; AC1-AC6 verification added -->
---
title: "Tasks — Fix /codex-review fragile Codex CLI invocation"
date: 2026-03-12
bead: .agent-config-ybl
---

# Tasks

Target file: `commands/codex-review.md` (291 lines, single file)

All tasks edit the same file. Sequential dependency chain is required — not because of logical dependencies between tasks (the line ranges are disjoint), but because the edit tool matches exact text. Earlier insertions shift line positions, causing later edits to fail if they run against stale file state. Cost of sequential: minutes. Cost of a lost write: full redo.

## Checklist

- [x] **Task 1: Add INVOCATION anti-patterns section (D6)**
  Insert after HARD CONSTRAINT `---` divider (line 37), before "## When to Invoke" (line 39). Four bullet points with ❌ prefix: no inline prompts, no timeout wrapping, no `| tail` piping, no heredocs. Each with a one-line "why."
  NOTE: This is DISTINCT from the existing review-loop anti-patterns on lines 21-35 (which cover "don't skip re-submission" and "don't do shallow revisions"). The new section covers invocation mechanics only.

- [x] **Task 2: Update Step 1 (D11)** — depends: task-1
  After `REVIEW_ID` generation (line 54), add umask 077 security note and update temp file list to mention all 3 files: `claude-plan-`, `codex-review-`, `codex-prompt-`.

- [x] **Task 3: Rewrite Step 3 — main invocation (D1, D2, D4, D7)** — depends: task-2
  Replace the 25-line inline-prompt bash block (lines 94–120) with three-step pattern:
  - Step A: Show review prompt as markdown content block (not bash). Instruct agent to write it to `/tmp/codex-prompt-${REVIEW_ID}.md` using their file-write tool.
  - Step B: One-liner bash: `rm -f` stale output + `codex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md`
  - Step C: Fail-safe error check: capture `CODEX_EXIT=$?`, check exit code + file existence + non-empty, print diagnostic, instruct agent to STOP (do not proceed to Step 4).
  - D7: Add session ID guidance note: "The session ID appears in the bash tool's stdout/stderr output. It is NOT in the `-o` output file — that file contains only Codex's review text."
  Review prompt content itself (adversarial gate questions, verdict instructions) is unchanged — just moved from bash to file write.

- [x] **Task 4: Fix Step 4 text (D8)** — depends: task-3
  Line 133: remove `(or stdout for resumed sessions)` — resume now uses `-o` consistently.

- [x] **Task 5: Rewrite Step 5 Part B — resume invocation (D3, D5, D5.1, D5.2)** — depends: task-4
  Replace the inline-prompt resume block (lines 175–186) with the same three-step pattern as Task 3:
  - Step A: Agent writes revision summary prompt to `/tmp/codex-prompt-${REVIEW_ID}.md` (overwrites previous).
  - Step B: One-liner bash: `rm -f` stale output + `codex exec resume ${CODEX_SESSION_ID} -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md`
  - Step C: Same fail-safe error check as Task 3 Step C (CODEX_EXIT capture, file checks, STOP instruction).
  Remove entirely:
  - `| tail -80` piping (D5.1)
  - False claim "codex exec resume does NOT support -o flag" on line 186 (D3)
  Update fallback path (line 188): when resume fails, fallback ALSO uses prompt-file + one-liner + error check pattern (D5.2).

- [x] **Task 6: Update Step 6 (D9, D10)** — depends: task-5
  - D9: Fix receipt description (line 260): change "contains Codex's actual words, session ID, verdict, and round-by-round feedback" to clarify that the `-o` file contains Codex's review text and verdict; session ID appears in bash stdout; round-by-round feedback is captured by the orchestrating agent.
  - D10: Update cleanup (line 257): add `/tmp/codex-prompt-${REVIEW_ID}.md` to the rm command.

- [x] **Task 7: Update frontmatter** — depends: task-6
  - Bump `revision: 2` → `revision: 3`
  - Update `revision_date: 2026-03-07` → `revision_date: 2026-03-12`

- [x] **Task 8: Verification — acceptance criteria** — depends: task-7
  Two-part verification:

  **Part A — Initial exec (covers AC1, AC3, AC4, AC5, AC7):**
  1. Write a test prompt to `/tmp/codex-prompt-test.md` using file-write tool
  2. Run: `rm -f /tmp/codex-review-test.md && codex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-test.md - < /tmp/codex-prompt-test.md`
  3. Verify: exit code 0, `/tmp/codex-review-test.md` exists and non-empty, session ID visible in bash output, no `| tail` in command, no `timeout` wrapper
  4. Run error check block from revised template — verify diagnostic fires when given wrong input path

  **Part B — Resume exec (covers AC2, AC6):**
  1. Using session ID from Part A, write a follow-up prompt to `/tmp/codex-prompt-test.md`
  2. Run: `rm -f /tmp/codex-review-test.md && codex exec resume ${SESSION_ID} -o /tmp/codex-review-test.md - < /tmp/codex-prompt-test.md`
  3. Verify: exit code 0, output file exists and non-empty, `-o` used (not stdout), review loop semantics intact (Codex responds in context)
  4. Run error check with bad prompt path on resume — verify diagnostic fires (AC3 on resume path)
  5. Cleanup: `rm -f /tmp/codex-prompt-test.md /tmp/codex-review-test.md`

  **AC-to-check mapping:**
  | AC | Verified in | Check |
  |----|-------------|-------|
  | AC1 | Part A.3 | Output file exists and non-empty from prompt-file + stdin pattern |
  | AC2 | Part B.3 | Resume uses `-o` successfully |
  | AC3 | Part A.4 + B.4 | Error check fires on bad input (both paths) |
  | AC4 | Part A.3 | No `| tail` in command |
  | AC5 | Part A.3 | No `timeout` wrapper |
  | AC6 | Part B.3 | Resume responds in context (loop semantics intact) |
  | AC7 | Part A + B | Full smoke test across both paths |

## D-part to Task mapping

| D-part | Task |
|--------|------|
| D1 (prompt as file write) | Task 3 |
| D2 (one-liner bash) | Task 3 |
| D3 (fix false -o claim) | Task 5 |
| D4 (error check block) | Task 3 |
| D5/D5.1/D5.2 (resume) | Task 5 |
| D6 (invocation anti-patterns) | Task 1 |
| D7 (session ID guidance) | Task 3 |
| D8 (Step 4 text fix) | Task 4 |
| D9 (Step 6 receipt desc) | Task 6 |
| D10 (cleanup 3rd file) | Task 6 |
| D11 (umask security note) | Task 2 |

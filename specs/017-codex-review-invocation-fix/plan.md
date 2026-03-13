<!-- Codex Review: APPROVED after 2+2 rounds | model: gpt-5.3-codex | date: 2026-03-12 -->
<!-- Status: REVISED -->
<!-- Revisions: Round 1-2: variable mismatch fix, fail-safe error handling, Step 4/6 text consistency, fallback path, umask 077, scope clarification. Round 3-4: tasks reviewed — Task 1 duplication fix, Task 8 split into 2-path verification with AC mapping, dependency chain justification -->

# Plan — Shape D: Prompt-file via native write tool

## Selected Shape

After shaping with fit checks across 4 alternatives:
- **Shape A (Heredoc stdin)** — passes all requirements but agents also mangle heredocs
- **Shape B (Prompt-file indirection)** — initially killed on R5 but that was wrong
- **Shape C (Wrapper script)** — fails R5, adds deployment/PATH dependency
- **Shape D (Prompt-file via native write tool)** — **SELECTED** — passes all requirements

**Core insight:** Move prompt content from bash (where agents are weak) to file writing (where agents are strong). The agent writes the prompt as a file using their native tool, then runs a one-line bash command with zero prompt content.

## Shape D: Detailed Parts

| Part | Mechanism |
|------|-----------|
| **D1** | Template shows the review prompt as a markdown content block (not inside a bash block). Tells the agent: "Write this content to `/tmp/codex-prompt-${REVIEW_ID}.md`" |
| **D1.1** | The plan content write (Step 2) already works this way — agents write `/tmp/claude-plan-${REVIEW_ID}.md` using file tools. D1 makes the review prompt follow the same pattern. |
| **D2** | Codex invocation is a single-line bash command: `codex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md` |
| **D3** | Use `-o` for both `exec` and `exec resume` (fix the false claim on line 186) |
| **D4** | Add post-invocation error check block: delete stale output before run, capture exit code, check file existence and non-emptiness. Instruct agent to STOP and diagnose on failure — do NOT proceed to Step 4. |
| **D5** | Resume prompt also written to file via native write, then one-liner: `codex exec resume ${CODEX_SESSION_ID} -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md` |
| **D5.1** | Remove `| tail -80` piping from resume. Output captured via `-o`. |
| **D5.2** | Fallback path (when resume fails): also uses prompt-file + one-liner + error check pattern |
| **D6** | Anti-patterns section between the Hard Constraint and Step 1: no `timeout`, no `| tail`, no inline prompts, no heredocs. Each with a one-line "why." |
| **D7** | Session ID capture guidance: "The session ID appears in the bash tool output (stdout/stderr). It is NOT in the `-o` output file — that file contains only Codex's review text." |
| **D8** | Step 4 text update: remove "or stdout for resumed sessions" since resume now uses `-o` |
| **D9** | Step 6 text update: clarify that `codex-review.md` contains "Codex's review text and verdict" — not session ID or round-by-round feedback |
| **D10** | Step 6 cleanup update: add `/tmp/codex-prompt-${REVIEW_ID}.md` to the cleanup list |
| **D11** | Security note: add `umask 077` recommendation before temp file creation for sensitive plan content |

## What Changes — Detailed

### Step 3: Main Invocation (CHANGED)

**Current (lines 94–120):** 25-line bash block with entire review prompt as inline double-quoted string argument.

**Planned:** Three-step pattern:

Step A — Template shows prompt content as markdown (not bash). Agent writes it to `/tmp/codex-prompt-${REVIEW_ID}.md` using their native file write tool. Prompt content is the same text, unchanged.

Step B — Delete stale output, then one-liner:
```bash
rm -f /tmp/codex-review-${REVIEW_ID}.md
codex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md
```

Step C — Fail-safe error check:
```bash
CODEX_EXIT=$?
if [ "$CODEX_EXIT" -ne 0 ] || [ ! -s /tmp/codex-review-${REVIEW_ID}.md ]; then
  echo "ERROR: Codex invocation failed."
  echo "Exit code: $CODEX_EXIT"
  echo "Output file exists: $([ -f /tmp/codex-review-${REVIEW_ID}.md ] && echo yes || echo no)"
  echo "Check: Is codex installed? Is OPENAI_API_KEY set? Did the prompt file get written to /tmp/codex-prompt-${REVIEW_ID}.md?"
  echo "STOP: Do not proceed to Step 4. Diagnose the failure first."
fi
```

Agent instruction: **If the error check fires, STOP. Do not proceed to Step 4 with missing or empty output. Diagnose the failure and retry the invocation.**

### Step 4: Read Response (TEXT UPDATE)

**Current line 133:** `Read /tmp/codex-review-${REVIEW_ID}.md (or stdout for resumed sessions)`

**Planned:** Remove "(or stdout for resumed sessions)" — resume now uses `-o` consistently.

### Step 5 Part B: Resume (CHANGED)

**Current (lines 175–186):** Inline prompt + `2>&1 | tail -80`, false claim about `-o`.

**Planned:** Same three-step pattern as Step 3:

Step A — Agent writes revision summary prompt to `/tmp/codex-prompt-${REVIEW_ID}.md` (overwrites previous prompt file).

Step B — Delete stale output, then one-liner:
```bash
rm -f /tmp/codex-review-${REVIEW_ID}.md
codex exec resume ${CODEX_SESSION_ID} -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md
```

Step C — Same fail-safe error check as Step 3.

**Fallback path:** When `resume` fails (session expired), the template already says to fall back to a fresh `codex exec` call. The revised template specifies: the fallback ALSO uses the prompt-file + one-liner + error check pattern. Write the fallback prompt (including prior round context) to the prompt file, then run the standard one-liner.

**Remove entirely:**
- The `| tail -80` piping
- The false claim "codex exec resume does NOT support -o flag"

### Step 6: Cleanup (TEXT UPDATE + CLEANUP UPDATE)

**Current line 260:** Claims the `codex-review.md` file "contains Codex's actual words, session ID, verdict, and round-by-round feedback."

**Planned:** Clarify: the `-o` output file contains Codex's review text and verdict for the last round. Session ID appears in the bash tool's stdout during invocation. Round-by-round feedback is captured by the orchestrating agent throughout the loop and presented to the user in conversation.

**Cleanup update (line 257):**
```bash
rm -f /tmp/claude-plan-${REVIEW_ID}.md /tmp/codex-review-${REVIEW_ID}.md /tmp/codex-prompt-${REVIEW_ID}.md
```

### New: Anti-Patterns Section (ADDED)

New section after "HARD CONSTRAINT — Read This First", before Step 1:

```markdown
## INVOCATION ANTI-PATTERNS — Do Not Do These

- ❌ **Do NOT pass the review prompt as an inline bash argument.** Write it to a file using your file-write tool and use `- < file` to feed it to codex via stdin. Inline prompts break on shell metacharacters.
- ❌ **Do NOT wrap `codex exec` in `timeout`.** Codex manages its own execution. Shell timeouts kill the process before `-o` can write the output file.
- ❌ **Do NOT pipe codex output through `| tail -N`.** This discards the session ID and diagnostic information. Use `-o` to capture output to a file.
- ❌ **Do NOT use heredocs (`<<PROMPT`).** Agents frequently mangle closing delimiters. Write prompt to a file instead.
```

### New: Security Note (ADDED)

In Step 1, after generating `REVIEW_ID`, add:

```markdown
**Note:** Plan content may contain sensitive information. Consider running `umask 077` before creating temp files to restrict permissions to the current user.
```

## Risk Analysis

| Risk | Severity | Mitigation |
|------|----------|------------|
| Agent forgets to write prompt file | Low | Codex errors on missing stdin — visible, not silent |
| Agent drops `- <` from one-liner | Low | Codex hangs; error check catches empty output |
| Agent uses `cat file \| codex ...` instead of `<` | None | Functionally equivalent |
| Session ID in bash output, not `-o` file | Medium | D7 adds explicit callout |
| Stale output from previous run | Low | `rm -f` before each invocation |

## File Touched

Only one file: `commands/codex-review.md` (291 lines)

## Verification

Manual smoke test: Run `/codex-review` against an existing spec and confirm:
1. Prompt file written successfully
2. One-liner bash produces output file
3. Output file contains Codex review with VERDICT
4. Session ID visible in bash output
5. Error check block functions on deliberate failure (e.g., wrong file path)
6. Resume with `-o` works (round 2)
7. Cleanup removes all three temp files

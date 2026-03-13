---
name: codex-review
description: Send the current plan to OpenAI Codex CLI for iterative review. Claude and Codex go back-and-forth until Codex approves the plan.
revision: 3
revision_date: 2026-03-12
user_invocable: true
gate_requires: spec.md, plan.md
gate_sentinels: plan:complete:v1
gate_creates: codex-review.md
gate_must_not_create: spec.md, plan.md, tasks.md
---

# Codex Plan Review (Iterative)

Send the current implementation plan to OpenAI Codex for review. Claude revises the plan based on Codex's feedback and re-submits until Codex approves. Max 5 rounds.

---

## HARD CONSTRAINT — Read This First

**Only Codex can approve the plan.** The loop ends ONLY when Codex's response contains `VERDICT: APPROVED` — or when 5 rounds are exhausted.

Claude making revisions is NOT approval. Claude believing the revisions are sufficient is NOT approval. The revised plan MUST be sent back to Codex every time.

**Anti-pattern (DO NOT DO THIS):**
> ❌ Read Codex feedback → revise plan → tell user "the plan is now approved" or "the concerns have been addressed"

**Correct pattern:**
> ✅ Read Codex feedback → revise plan → send revised plan back to Codex → read Codex's new verdict

If you catch yourself about to tell the user the plan is approved without Codex's `VERDICT: APPROVED` in the current round's output, STOP — you are skipping the re-submission step.

**Anti-pattern #2 — Shallow revisions (DO NOT DO THIS):**
> ❌ Codex says "missing error handling for X" → add a comment "// TODO: handle X errors" or a vague sentence "error handling will be added"

**Correct revision pattern:**
> ✅ Codex says "missing error handling for X" → add the actual error handling logic, code paths, and recovery strategy to the plan

Revisions must be substantive. If Codex raised a specific technical concern, the revision must contain a specific technical solution — not a hand-wave, TODO, or acknowledgment that the issue exists.

---

## INVOCATION ANTI-PATTERNS — Do Not Do These

- ❌ **Do NOT pass the review prompt as an inline bash argument.** Write it to a file using your file-write tool and use `- < file` to feed it to codex via stdin. Inline prompts break on shell metacharacters.
- ❌ **Do NOT wrap `codex exec` in `timeout`.** Codex manages its own execution. Shell timeouts kill the process before `-o` can write the output file.
- ❌ **Do NOT pipe codex output through `| tail -N`.** This discards the session ID and diagnostic information. Use `-o` to capture output to a file.
- ❌ **Do NOT use heredocs (`<<PROMPT`).** Agents frequently mangle closing delimiters. Write the prompt to a file instead.

---

## When to Invoke

- When the user runs `/codex-review` during or after plan mode
- When the user wants a second opinion on a plan from a different model

## Agent Instructions

When invoked, perform the following iterative review loop:

### Step 1: Generate Session ID

Generate a unique ID to avoid conflicts with other concurrent Claude Code sessions:

```bash
REVIEW_ID=$(uuidgen | tr '[:upper:]' '[:lower:]' | head -c 8)
```

Use this for all temp file paths: `/tmp/claude-plan-${REVIEW_ID}.md`, `/tmp/codex-review-${REVIEW_ID}.md`, and `/tmp/codex-prompt-${REVIEW_ID}.md`.

**Note:** Plan content may contain sensitive information. Consider running `umask 077` before creating temp files to restrict permissions to the current user.

### Step 2: Locate and Capture the Plan

**What to review:** The **spec** (intent/requirements) and the **plan** (implementation strategy). NOT tasks — they're derivative and dilute the review.

Resolve the plan to review using this priority:

1. **If arguments were provided** (e.g., `/codex-review 036-profile-switch-gmp-wiring`):
   - Search for a matching spec directory: `specs/<arg>/` or `specs/*<arg>*/`
   - Read `spec.md` (or `shaping.md`) for the requirements/problem definition
   - Read `plan.md` for the implementation strategy
   - Do NOT include `tasks.md` — task breakdown is project management, not what Codex reviews
   - If the directory doesn't exist, tell the user and list available specs via `ls specs/`

2. **If no arguments but a plan exists in the current conversation context** (from plan mode, shaping, or prior discussion):
   - Use that plan directly

3. **If neither** — ask the user what they want reviewed

Write the combined content to `/tmp/claude-plan-${REVIEW_ID}.md` structured as:

```markdown
# Spec (Requirements)
[Contents of spec.md — the problem, constraints, acceptance criteria]

# Plan (Implementation)
[Contents of plan.md — the proposed solution, code changes, architecture]
```

This gives Codex both the *what* and the *how*, so it can verify the plan actually fulfills the spec — not just check internal consistency.

Include relevant source code context if the plan references specific files — Codex reviews are better when it can cross-reference against the actual codebase.

### Step 3: Submit to Codex (Round 1)

**Step A — Write the review prompt to a file.** Using your file-write tool (not bash), write the following content to `/tmp/codex-prompt-${REVIEW_ID}.md`:

```markdown
Review the spec and implementation plan in /tmp/claude-plan-${REVIEW_ID}.md. The file contains two sections: the Spec (requirements/problem definition) and the Plan (proposed implementation).

Review the plan AGAINST the spec. Focus on:
1. Completeness - Does the plan address every requirement in the spec?
2. Correctness - Will this plan actually achieve the stated goals?
3. Risks - What could go wrong? Edge cases? Data loss?
4. Missing steps - Is anything forgotten between spec and plan?
5. Alternatives - Is there a simpler or better approach?
6. Security - Any security concerns?

ADVERSARIAL GATE — answer these BEFORE giving your verdict:
7. Identify the 3 riskiest assumptions this plan makes. For each, did you verify it against the source code context? Cite specific files and lines.
8. What would a skeptical senior engineer's first objection be?
9. What does this plan NOT address that a production system would need?
10. Where does the plan's scope differ from the spec's scope? What changed, expanded, or was dropped?

If you found no issues with the plan, do not just say APPROVED — show your work: which files you read, which assumptions you tested, what you counted. If an assumption is not directly verifiable from source context, state why.

Be specific and actionable. If the plan is solid and ready to implement, end your review with exactly: VERDICT: APPROVED

If changes are needed, end with exactly: VERDICT: REVISE
```

**Step B — Run Codex.** Execute this one-liner:

```bash
rm -f /tmp/codex-review-${REVIEW_ID}.md
codex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md
```

**Step C — Verify the invocation succeeded:**

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

**If the error check fires, STOP.** Do not proceed to Step 4 with missing or empty output. Diagnose the failure and retry the invocation.

**Capture the Codex session ID** from the bash tool's stdout/stderr output — look for the line that says `session id: <uuid>`. Store this as `CODEX_SESSION_ID`. You MUST use this exact ID to resume in subsequent rounds (do NOT use `--last`, which would grab the wrong session if multiple reviews are running concurrently).

**Note:** The session ID appears in the bash tool's stdout/stderr output. It is NOT in the `-o` output file — that file contains only Codex's review text.

**Notes:**
- Use `-m gpt-5.3-codex` as the default model (configured in `~/.codex/config.toml`). If the user specifies a different model (e.g., `/codex-review o4-mini`), use that instead.
- Use `-s read-only` so Codex can read the codebase for context but cannot modify anything.
- Use `-o` to capture the output to a file for reliable reading.

Then go to **Step 4**.

### Step 4: Read Codex's Response & Branch on Verdict

1. Read `/tmp/codex-review-${REVIEW_ID}.md`
2. Present Codex's review to the user:

```
## Codex Review — Round N (model: gpt-5.3-codex)

[Codex's feedback here]
```

3. **Check the adversarial gate answers.** If Codex's response contains `VERDICT: APPROVED` but the adversarial gate questions (7-10) are vague, missing, or don't cite specific files/lines — **treat it as `VERDICT: REVISE`** and re-submit: "Your adversarial gate answers lack specifics. Cite the actual files and lines you examined. Re-review with concrete evidence." A rubber-stamp approval is not an approval.

4. **Check for the literal string `VERDICT: APPROVED` in Codex's response:**
   - **Present AND adversarial gate answered with specifics** → go to Step 6 (Done)
   - **Present BUT adversarial gate vague/missing** → treat as REVISE, go to Step 5
   - **Absent** (including `VERDICT: REVISE`, unclear verdict, or no verdict) → go to Step 5
   - **Max rounds (5) reached** → go to Step 6 with a note that max rounds hit

**There is no other way to reach Step 6 (Done) besides Codex's explicit approval or exhausting 5 rounds.**

### Step 5: Revise Plan AND Re-submit to Codex (Atomic Step)

This step has two parts that MUST both execute. Do not stop after part A.

**Part A — Revise the plan:**

Based on Codex's feedback, revise the plan. Update the plan content in the conversation context and rewrite `/tmp/claude-plan-${REVIEW_ID}.md` with the revised version.

Briefly summarize what you changed for the user:

```
### Revisions (Round N)
- [What was changed and why, one bullet per Codex issue addressed]
```

If a revision contradicts the user's explicit requirements, skip that revision and note it for the user.

**Part B — Immediately re-submit to Codex:**

Do this now. Do not present the revisions as final. Do not ask the user if they want to continue. Do not say the plan is approved.

Resume the existing Codex session using the same prompt-file pattern as Step 3:

**Step A — Write the resume prompt to a file.** Using your file-write tool (not bash), write the following content to `/tmp/codex-prompt-${REVIEW_ID}.md` (this overwrites the previous prompt file):

```markdown
I've revised the plan based on your feedback. The updated plan is in /tmp/claude-plan-${REVIEW_ID}.md.

Here's what I changed:
[List the specific changes made]

Please re-review. If the plan is now solid and ready to implement, end with: VERDICT: APPROVED
If more changes are needed, end with: VERDICT: REVISE
```

**Step B — Run Codex resume:**

```bash
rm -f /tmp/codex-review-${REVIEW_ID}.md
codex exec resume ${CODEX_SESSION_ID} -o /tmp/codex-review-${REVIEW_ID}.md - < /tmp/codex-prompt-${REVIEW_ID}.md
```

**Step C — Verify the invocation succeeded** (same check as Step 3):

```bash
CODEX_EXIT=$?
if [ "$CODEX_EXIT" -ne 0 ] || [ ! -s /tmp/codex-review-${REVIEW_ID}.md ]; then
  echo "ERROR: Codex resume invocation failed."
  echo "Exit code: $CODEX_EXIT"
  echo "Output file exists: $([ -f /tmp/codex-review-${REVIEW_ID}.md ] && echo yes || echo no)"
  echo "Check: Did the prompt file get written to /tmp/codex-prompt-${REVIEW_ID}.md? Is the session ID correct?"
  echo "STOP: Do not proceed to Step 4. Diagnose the failure first."
fi
```

**If the error check fires, STOP.** Do not proceed to Step 4 with missing or empty output. Diagnose the failure and retry.

**If `resume ${CODEX_SESSION_ID}` fails** (e.g., session expired), fall back to a fresh `codex exec` call with context about the prior rounds included in the prompt. The fallback ALSO uses the prompt-file pattern: write the fallback prompt (including prior round context) to `/tmp/codex-prompt-${REVIEW_ID}.md`, then run the standard Step 3 one-liner with the same error check.

After Codex responds, go back to **Step 4**.

### Step 6: Present Final Result & Cleanup

Once approved (or max rounds reached):

**If Codex approved:**
```
## Codex Review — Final (model: gpt-5.3-codex)

**Status:** ✅ Approved by Codex after N round(s)

[Final Codex feedback / approval message]

---
**The plan has been reviewed and approved by Codex. Ready for your approval to implement.**
```

**If max rounds reached without approval:**
```
## Codex Review — Final (model: gpt-5.3-codex)

**Status:** ⚠️ Max rounds (5) reached — not fully approved by Codex

**Remaining concerns:**
[List unresolved issues from last Codex review]

---
**Codex still has concerns. Review the remaining items and decide whether to proceed or continue refining.**
```

**Writeback — update ALL spec files on disk:**

If the plan was loaded from a spec directory (Step 2, option 1), update every artifact with a review header and any revisions. When someone opens any file in the spec directory, they should immediately know: was this reviewed, was it revised, and when.

**Header format** — add to the top of each file:

```markdown
<!-- Codex Review: APPROVED after N rounds | model: gpt-5.3-codex | date: YYYY-MM-DD -->
<!-- Status: [REVISED | UNCHANGED] -->
<!-- Revisions: [brief list of what changed, or "none"] -->
```

**File-by-file:**

1. **`plan.md`** — Overwrite with the Codex-approved version. Add header with `Status: REVISED` and list the key revisions made across all rounds.

2. **`tasks.md`** — If it exists, reconcile to match the revised plan. Old tasks may reference steps, code changes, or approaches that were revised during review. Read the current `tasks.md` to preserve its format and structure, then update task content to align with the approved plan. If a task no longer applies, remove it. If the plan added new work, add new tasks. Add header with `Status: REVISED` if tasks changed, or `Status: RECONCILED` if only re-aligned to match the revised plan.

3. **`spec.md`** (or `shaping.md`) — Do NOT modify content unless a Codex finding revealed an actual spec ambiguity that was clarified during revision. Add header with `Status: UNCHANGED` (or `Status: REVISED` if an ambiguity was clarified, with the revision noted). The spec is the user's intent — plan revisions should conform to the spec, not the other way around.

**The files on disk must match what was approved.** Every file in the spec directory should tell the same story: reviewed, approved, and current.

**Post-approval honesty check** — before presenting to the user, ask yourself:
- Did I water down any revision to get Codex to approve faster?
- Did I add vague language ("will be handled", "as needed") instead of concrete solutions?
- Did I skip or gloss over any Codex finding across all rounds?

If yes to any, disclose it: "Note: I took a shortcut on [X] — here's what a proper revision would look like: [...]"

**Save the review transcript** — this is the proof that Codex actually ran. Copy it to the spec directory as a permanent, committed artifact:

```bash
# Save to spec directory (if reviewing a spec)
cp /tmp/codex-review-${REVIEW_ID}.md specs/<NNN>-<slug>/codex-review.md

# Clean up temp files
rm -f /tmp/claude-plan-${REVIEW_ID}.md /tmp/codex-review-${REVIEW_ID}.md /tmp/codex-prompt-${REVIEW_ID}.md
```

The `codex-review.md` file in the spec directory is the receipt. It contains Codex's review text and verdict. The session ID appears in the bash tool's stdout during invocation. Round-by-round feedback is captured by the orchestrating agent throughout the loop and presented to the user in conversation. Commit it with the spec. If this file doesn't exist, the review didn't happen.

## Loop Summary

```
Round 1: Claude sends plan → Codex reviews → VERDICT: REVISE
Round 2: Claude revises + sends back → Codex re-reviews → VERDICT: REVISE
Round 3: Claude revises + sends back → Codex re-reviews → VERDICT: APPROVED ✅
```

Max 5 rounds. Each round preserves Codex's conversation context via session resume.

## Rules

1. **ONLY Codex can approve.** Claude NEVER declares the plan approved. The string `VERDICT: APPROVED` must appear in Codex's output for that round.
2. **Revise + re-submit is one atomic step.** Never revise without re-submitting. Never present revisions as the final result.
3. Default model is `gpt-5.3-codex`. Accept model override from the user's arguments (e.g., `/codex-review o4-mini`).
4. Always use read-only sandbox mode — Codex should never write files.
5. Max 5 review rounds to prevent infinite loops.
6. Show the user each round's feedback and revisions so they can follow along.
7. If Codex CLI is not installed or fails, inform the user and suggest `npm install -g @openai/codex`.
8. If a revision contradicts the user's explicit requirements, skip that revision and note it for the user.

## Log it

Append lines to `log.md` in the spec directory (create if needed). Log each round and the final verdict. Format:

```
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /codex-review | round N — VERDICT: <REVISE|APPROVED>
```

The Codex agent's identity goes in its own log line if you know it (e.g., `codex/gpt-5.3-codex`). Your identity (the Claude side orchestrating) goes in yours.

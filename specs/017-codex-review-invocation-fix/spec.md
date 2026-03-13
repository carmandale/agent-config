<!-- Codex Review: APPROVED after 2+2 rounds | model: gpt-5.3-codex | date: 2026-03-12 -->
<!-- Status: UNCHANGED -->
<!-- Revisions: none (spec unchanged across both review passes) -->
---
title: "Fix /codex-review fragile Codex CLI invocation"
date: 2026-03-12
bead: .agent-config-ybl
---

# Fix /codex-review fragile Codex CLI invocation

## Problem

The `/codex-review` command template (`commands/codex-review.md`) includes bash code blocks that agents are meant to follow when invoking `codex exec`. In practice, agents mangle these invocations, producing commands that fail silently — no output file, no error, no review.

### Observed failure (from user report)

```bash
codex exec \
  -m gpt-5.3-codex \
  -s read-only \
  -o /tmp/codex-review-de69d6cf.md \
  Review the implementation plan in /tmp/claude-plan-de69d6cf.md against its spec requirements. Focus on completeness, correctness, risks, missing steps.

  ADVERSARIAL GATE:
  1. Identify the 3 riskiest assumptions — cite specific files/lines from source context.
  2. What would a senior engineer object to first?
  3. What does this plan NOT address for production?
  4. Scope drift between spec and plan?

  End with exactly VERDICT: APPROVED or VERDICT: REVISE 2>&1 | tail -10 (timeout 600s)
```

Result: no output file written. Review never happened.

### Root cause analysis

The symptom is "no output file from codex exec." The root cause is that the command template gives agents a fragile invocation pattern that breaks in multiple ways when agents reconstruct it:

1. **Unquoted multi-line prompt** — The template shows the prompt inside double quotes in a markdown code block, but agents frequently drop the quotes when constructing the actual bash command. Without quotes, the shell splits the prompt on whitespace and interprets metacharacters (`?`, `!`, `(`, `)`, `—`, newlines). The codex CLI may receive a truncated or garbled prompt, or the shell may error before codex even starts.

2. **Invalid timeout syntax** — Agents append `(timeout 600s)` as an afterthought. This is not valid bash. The correct syntax is `timeout 600 codex exec ...` at the *start*. But more fundamentally, shell timeouts kill the process without giving codex a chance to write the `-o` output file.

3. **Incorrect claim about `resume` flags** — The template says "codex exec resume does NOT support -o flag." This is wrong — `codex exec resume --help` shows `-o, --output-last-message <FILE>` is supported. This false claim forces agents to pipe through `tail -80` instead, losing structured output capture.

4. **`-o` only writes on success** — If codex crashes, times out, or the prompt fails to parse, the output file is never written. The command has zero error handling — no exit code check, no fallback, no "if the file doesn't exist, here's what went wrong."

5. **Pipe through `tail` discards output** — `2>&1 | tail -10` and `| tail -80` discard most of codex's output, including the session ID needed for `resume`, diagnostic information, and potentially the review itself if it's long.

### Why agents mangle this

The template embeds a ~20-line prompt as an inline string argument in a bash code block. This is the most fragile possible delivery mechanism for a multi-line prompt:

- Agents must preserve exact quoting across dozens of lines
- Double quotes inside double-quoted strings need escaping
- Shell history expansion (`!`) can trigger inside double quotes
- Newlines in command-line arguments are fragile in many shell contexts
- Agents are pattern-matchers — they see a long block and reconstruct it "roughly right" rather than copying it exactly

The fix is to eliminate the fragility, not to tell agents to "be more careful with quoting."

## Requirements

### R1: Use stdin for prompt delivery

Replace inline prompt arguments with heredoc or file-based stdin delivery:

```bash
cat <<'REVIEW_PROMPT' | codex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-${REVIEW_ID}.md -
Review the spec and implementation plan in /tmp/claude-plan-${REVIEW_ID}.md.
...
REVIEW_PROMPT
```

The key insight: `codex exec` accepts `-` to read the prompt from stdin. Heredocs with single-quoted delimiters (`<<'PROMPT'`) prevent all shell expansion — no quoting issues, no metacharacter problems, no escaping needed. This pattern is agent-proof.

### R2: Use `-o` for both initial and resume invocations

Fix the incorrect claim. Both `codex exec` and `codex exec resume` support `-o`. Use it consistently for all invocations.

### R3: Add error handling after every codex invocation

After every `codex exec` call, check:
1. Exit code (`$?` — non-zero means failure)
2. Output file existence (`[ -f /tmp/codex-review-${REVIEW_ID}.md ]`)
3. Output file non-empty (`[ -s /tmp/codex-review-${REVIEW_ID}.md ]`)

If any check fails, provide a diagnostic message and retry strategy — not silent failure.

### R4: Remove pipe-through-tail advice

Do not pipe codex output through `tail`. Capture via `-o` (the file gets only the last agent message — clean and reliable). Let stderr flow to the terminal for diagnostics. The session ID appears in stderr and should not be discarded.

### R5: Add explicit anti-patterns for agent timeout

Add a warning: "Do NOT wrap codex exec in `timeout`. Codex manages its own execution time. Shell timeouts kill the process before `-o` can write."

### R6: Preserve all existing review logic

The review loop logic (rounds, verdict checking, adversarial gate, writeback, session resume) is correct and battle-tested. Only the invocation mechanics change. Do not alter the review protocol, the adversarial gate questions, the verdict checking logic, or the writeback/cleanup steps.

## Acceptance criteria

1. An agent following the revised template can invoke `codex exec` with a multi-line prompt and reliably get an output file — even if the agent doesn't perfectly follow every instruction (the pattern itself must be robust).
2. The `resume` invocation uses `-o` correctly.
3. Every codex invocation has exit-code and file-existence checks.
4. No `| tail -N` piping of codex output.
5. No shell timeout wrapping advice.
6. The review loop semantics (rounds, verdicts, writeback, cleanup) are unchanged.
7. The command passes a manual smoke test: run `/codex-review` against an existing spec and get a complete round-1 review with output file.

## Scope

### In scope
- Rewriting bash invocation patterns in `commands/codex-review.md`
- Fixing the incorrect `-o` claim for `resume`
- Adding error handling guidance
- Adding anti-patterns section

### Out of scope
- Changing the review loop logic or adversarial gate protocol
- Changing the writeback or cleanup steps
- Wrapper scripts or external tooling — the fix is to the command template itself
- Changing the default model or sandbox mode
- Pi-messenger / two-agent gate enforcement (that's spec 016's domain)

## Constraints

- This is a markdown command file, not code. The "implementation" is rewriting prose and code blocks that agents follow. The fix must be clear enough that agents of varying capability (Claude, Pi, Gemini) can follow it.
- Heredoc pattern must use single-quoted delimiter (`<<'PROMPT'`) to prevent shell expansion.
- The command must still work for agents running inside pi, Claude Code, Codex orchestration, or any harness that provides a bash tool.

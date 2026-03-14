---
title: "Codex review timeout resistance — eliminate bash tool timeout kills"
date: 2026-03-14
bead: .agent-config-1ek
parent: .agent-config-ybl
---

<!-- issue:complete:v1 | harness: pi/claude-opus-4-6 | date: 2026-03-14T14:15:51Z -->

# Codex review timeout resistance

## Problem

Spec 017 (`.agent-config-ybl`) fixed `/codex-review` invocation fragility: inline prompts → prompt files, added error handling, added an anti-patterns section that explicitly says **"Do NOT wrap `codex exec` in `timeout`."** All tasks complete, reviewed, approved.

It didn't work. MintWolf ran `/codex-review` today (2026-03-14) in the hsbc project and hit the exact same failure mode — codex killed mid-work, `-o` output file never written, valuable review lost.

### What actually happened (from MintWolf's session d7013d18)

**Attempt 1** — MintWolf followed the spec 017 template correctly (prompt file, `- <` stdin, `-o`, error check) but passed `"timeout": 300` to pi's bash tool:

```json
{
  "name": "bash",
  "arguments": {
    "command": "rm -f /tmp/codex-review-9889edcb.md\ncodex exec -m gpt-5.3-codex -s read-only -o /tmp/codex-review-9889edcb.md - < /tmp/codex-prompt-9889edcb.md 2>&1\n...",
    "timeout": 300
  }
}
```

Result: Pi killed the bash process after 300s. Codex was mid-analysis (1179 lines of output showing deep file-level validation). Output file empty.

**Attempt 2** — MintWolf bumped timeout to 600s AND added `| tail -5` (violating another anti-pattern):

```json
{
  "name": "bash",
  "arguments": {
    "command": "... codex exec ... 2>&1 | tail -5\n...",
    "timeout": 600
  }
}
```

Result: Same — killed at 600s. Still no output.

**Attempt 3** — MintWolf adapted to `nohup` + polling loop with `sleep 15` checks. Creative, but still has a `"timeout": 660` on the polling loop itself. And orphaned codex processes from earlier kills are still running (`pgrep` found 3 codex PIDs).

### Root cause analysis (5 whys)

**Symptom:** Codex review output file never written.

1. **Why?** Pi's bash tool killed the codex process before it finished.
2. **Why did the bash tool kill it?** The agent passed `"timeout": 300` in the tool call arguments.
3. **Why did the agent add a timeout?** Agents are trained to add timeouts to "long-running" bash commands as a safety measure. This is default LLM behavior, not a deliberate choice.
4. **Why didn't the anti-pattern prevent this?** The anti-pattern says "Do NOT wrap `codex exec` in `timeout`" — referring to the shell `timeout` command. The agent didn't use the shell `timeout` command. It used the bash tool's own `timeout` parameter. Different layer, same effect.
5. **Why was the anti-pattern layer-specific?** Spec 017 treated the problem as a command template issue. The real problem is architectural: `codex exec` is a long-running process (5-20+ minutes) being run through a tool designed for short-lived commands, and agents default to adding timeouts on anything that takes more than a few minutes.

### Why spec 017's fix was insufficient

Spec 017 fixed real problems (inline prompts, missing error handling, `| tail` piping, false `-o` claims). Those fixes are good and should stay. But:

1. **Anti-pattern addressed the wrong layer.** "Don't use `timeout` command" ≠ "Don't set timeout on your bash tool call." The agent technically complied with the letter of the anti-pattern while violating its intent.
2. **Negative instructions are unreliable.** "Don't do X" is the weakest form of agent instruction. Agents follow positive instructions better than prohibitions, especially when their training predisposes them toward the prohibited behavior.
3. **The architectural mismatch was out of scope.** Spec 017 explicitly excluded wrapper scripts and external tooling. But a template-only fix cannot prevent agents from adding timeout parameters to tool calls — that's outside the template's control surface.

## Requirements

### R1: Eliminate ALL timeout mechanisms from codex exec invocations

The `/codex-review` command must explicitly instruct agents: **"Do NOT set a timeout parameter on this bash command. Codex exec may run for 15-30 minutes on large codebases. This is normal. No timeout of any kind."**

The anti-pattern must cover ALL timeout mechanisms, not just the shell `timeout` command:
- Shell `timeout` command wrapper
- Bash tool `timeout` parameter (pi, Claude Code, any harness)
- Any other mechanism that would kill the process on a timer

### R2: Positive framing over negative prohibition

Instead of just "don't do this," give the agent a positive instruction that makes the right thing obvious:

> "Run this command with NO timeout. Codex reviews take 5-30 minutes depending on codebase size. The process is working correctly as long as codex is running — there is no hang to protect against."

### R3: Evaluate wrapper script approach

Spec 017 excluded wrapper scripts. Re-evaluate this decision given that:
- Template-only anti-patterns proved insufficient
- A wrapper script moves the bash invocation complexity out of the agent's control entirely
- The agent's job becomes: (1) write prompt file, (2) call `scripts/codex-review-exec.sh`, (3) read output file
- There is no opportunity to add a timeout if the invocation is a single-line script call

If a wrapper script is the right approach, the script should:
- Accept `--prompt`, `--output`, `--model`, `--session` parameters
- Handle `rm -f` of stale output
- Run `codex exec` with correct flags
- Perform exit code and file existence checks
- Support `resume` mode
- Print clear diagnostics on failure
- Exit 0 only when the output file exists and is non-empty

### R4: Handle the `| tail` regression

MintWolf added `| tail -5` on the retry despite the anti-pattern being present. This suggests the anti-patterns section is either:
- Not being read (positioned wrong, too far from the invocation)
- Not compelling enough (agents override prohibitions under pressure)
- Needs repetition at the point of use (near the actual bash command)

The fix must place the "no timeout, no tail" instruction immediately adjacent to the bash command block, not in a separate section that may be skimmed.

### R5: Orphaned process handling

When a bash tool timeout kills the parent shell but codex continues running as an orphan (observed: `pgrep` found 3 codex processes after timeout), the output file may never be written because codex's stdout/stdin pipes are broken. Address this either by:
- Preventing the timeout from happening (R1-R3)
- Documenting that if timeout occurs, orphaned codex processes should be killed before retrying

## Acceptance criteria

1. An agent running `/codex-review` against a large codebase (5+ minute codex runtime) completes without timeout kills — observed as output file written successfully.
2. The codex-review.md command file contains explicit prohibition of ALL timeout mechanisms (bash tool timeout parameter, shell timeout command, etc.) — not just one.
3. If a wrapper script approach is chosen: the script exists, is tested, and the command file references it instead of inline bash.
4. Anti-timeout instructions appear immediately adjacent to every bash code block in the command, not just in a separate section.
5. The `| tail` prohibition is reinforced at point of use.

## Scope

### In scope
- Updating `commands/codex-review.md` anti-patterns and invocation blocks
- Evaluating and potentially implementing a wrapper script (`scripts/codex-review-exec.sh`)
- Adding point-of-use timeout prohibition adjacent to bash blocks

### Out of scope
- Changes to pi's bash tool itself (that's upstream)
- Changes to the review loop logic, adversarial gate, or verdict checking
- Changes to other commands (though learnings may apply)

## Constraints

- Must not break any existing `/codex-review` functionality
- Must preserve the review loop semantics (rounds, verdicts, writeback)
- If wrapper script approach is chosen, it must be portable (bash, no exotic dependencies) and work from any project directory
- Spec 017's fixes (prompt files, `-o` for both exec/resume, error handling) must be preserved

## Prior art

- **Spec 017** (`.agent-config-ybl`): Fixed invocation template. All tasks complete. Anti-pattern for `timeout` command present but proved insufficient against bash tool timeout parameter.
- **Napkin pattern (Prompt & Command Craft #1)**: "Over-structuring commands kills agent performance." But also: "Agents follow positive instructions better than prohibitions."
- **Napkin pattern (Prompt & Command Craft #2)**: "Use the skill ≠ the agent actually following the skill." Anti-patterns are read but not reliably followed under pressure.

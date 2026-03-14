<!-- plan:complete:v1 | harness: pi/claude-opus-4-6 | date: 2026-03-14T15:41:35Z -->

# Planning Transcript — Spec 022: Codex review timeout resistance

**Date:** 2026-03-14
**Participants:** WildStorm (pi/claude-opus-4-6, agent-config) + RedViper (pi/claude-opus-4-6, hsbc)
**Method:** pi_messenger async collaboration

## Round 1: WildStorm proposes plan

WildStorm sent the initial plan to RedViper covering:
- Wrapper script `scripts/codex-review-exec.sh` encapsulating codex exec
- Interface: `--prompt`, `--output`, `--model`, `--session`
- Script handles: input validation, stale output removal, codex execution, exit code capture, output validation, session ID extraction via grep/sed
- Command template update: replace Steps 3/5 bash blocks, update anti-patterns
- Identified risk: script discoverability from other project directories

## Round 1.5: WildStorm resolves discoverability

Before RedViper responded, WildStorm investigated and found:
- `~/.agent-config/tools-bin` is already on PATH
- MintWolf tried `scripts/gate.sh` from hsbc → "not found" (confirms relative paths don't work)
- Decision: script goes in `tools-bin/codex-review-exec` (no .sh extension), callable as bare command

## Round 2: RedViper adversarial review — 5 findings

**🔴 ISSUE 1: Session ID parsing fragile and unnecessary**
- Script parsing stderr via grep/sed adds fragility
- Two options: (a) pass stderr through unchanged, agent extracts session ID from bash output as today, (b) script parses and emits structured line
- RedViper recommended (a) — simpler, less fragile
- **WildStorm accepted: option (a), no session ID parsing in script**

**🔴 ISSUE 2: Template still has raw bash blocks for error checks**
- Steps 3C and 5C are standalone error check blocks — agents could add timeout to those too
- If script handles validation internally, these blocks are eliminated
- **WildStorm accepted: script handles full validation, Steps 3C/5C removed from template**

**🟡 ISSUE 3: Model default conflict with config.toml**
- Script hardcoding `gpt-5.3-codex` could conflict with codex config
- **WildStorm accepted: if --model not passed, don't pass -m to codex at all**

**🟡 ISSUE 4: Per-block timeout warnings overkill with wrapper**
- Wrapper script makes per-block warnings less necessary — the call looks simple, not like a raw long-running command
- **WildStorm accepted: one global anti-pattern, no per-block warnings**

**🟡 ISSUE 5: Session ID sourcing for resume**
- Agent still needs to extract session ID from Step 3 bash output
- Template needs explicit guidance that session ID appears in script call output
- **WildStorm accepted: Step 3B text clarifies session ID sourcing**

## Round 3: Plan + tasks written, sent for review

WildStorm wrote `plan.md` and `tasks.md` with all 5 findings incorporated. Sent to RedViper for review pass.

## Round 4: RedViper review of plan.md + tasks.md — 2 findings

**🔴 ISSUE: `set -euo pipefail` kills script before exit code capture**
- With `set -e`, if codex exits non-zero, script dies at the codex line
- Never reaches `CODEX_EXIT=$?` or diagnostic output
- **Fix accepted: `set +e` before codex invocation, `set -e` after capture**

**🟡 NOTE: --session + --model warning**
- When both provided, script ignores --model but should log warning to stderr
- **Accepted: stderr warning added to prevent silent confusion**

**RedViper verdict:** Plan ready after set -e fix. Ship it.

## Final state

- plan.md: updated with both round 4 fixes (set +e/+e around codex, --model warning in resume)
- tasks.md: updated with both fixes in Task 1 implementation steps
- All 7 findings (5 from round 2 + 2 from round 4) incorporated

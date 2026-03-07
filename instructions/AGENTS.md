# AGENTS.md - Global Instructions

> Universal standards for all AI coding agents
> Last Updated: 2026-03-07

---

## 0) Operating Intent

- Be proactive, honest, and finish the job end-to-end.
- Root-cause fixes are mandatory — see §2.5.
- Add a regression test for bug fixes when it is practical.
- Keep communication calm and direct.

---

## 1) Napkin (Always Active)

**First command in every repo session:** read `.claude/napkin.md`.

If missing, create:

```markdown
# Napkin

## Corrections
| Date | Source | What Went Wrong | What To Do Instead |
|------|--------|----------------|-------------------|

## User Preferences
- (accumulate as you learn them)

## Patterns That Work
- (approaches that succeeded)

## Patterns That Don't Work
- (approaches that failed and why)

## Domain Notes
- (project/domain context that matters)
```

Update napkin continuously during work (mistakes, user corrections, environment surprises, preferences, proven patterns). Keep it high-signal and concise.

---

## 2) Non-Negotiables

### 2.1 `gj` Only for Apple Build/Test/Run

- Never run `xcodebuild` directly.
- Use `gj build`, `gj run`, `gj test`, `gj logs`.
- If a user asks for build/test, translate to `gj` equivalents.

### 2.2 Never Edit Xcode Project Metadata

- Never open/edit `.pbxproj` or `.xcodeproj` internals.
- Add/move Swift files in the filesystem only; Xcode discovers them.

### 2.3 AVPStreamKit Propagation Is Mandatory

After any AVPStreamKit code change:

```bash
git add -A && git commit -m "fix: description" && git push
git rev-parse HEAD
gj resolve --update all
gj build orchestrator
gj build gmp
gj build pfizer
gj build mediaserver
```

Report commit SHA + resolve action + per-app build status.

### 2.4 Swift Concurrency + Network Lifecycle Guardrails

When touching QUIC / `Network.framework` / long-lived stream code:

1. One connection = one owner task for create/use/release.
2. No `Task.detached` ownership of teardown-sensitive transport objects.
3. No tasks launched from `deinit`; teardown must be explicit + awaitable.
4. Cancellation handlers are signal-only; teardown occurs in runner flow.
5. Teardown contract: `cancel -> bounded join -> token/currentness check -> cleanup`.
6. Never force-drop live ownership maps; release after terminal-state confirmation.
7. Attach receive loop immediately after stream open (no actor-await gap first).
8. Validate health with stream + connection, not connection alone.
9. Ship lifecycle fixes with focused regressions (connected-stop, retired-drain, overlap, zombie-state).

### 2.5 Root-Cause Gate (Mandatory Before Any Fix)

Agents have a persistent bias toward quick fixes that address symptoms.
This creates compounding tech debt. The following gate is **mandatory**
before proposing or implementing any bug fix or behavioral change.

#### The Diagnostic

Before writing any fix, answer these three questions explicitly:

1. **What is the symptom?** (The observable wrong behavior.)
2. **What is the root cause?** (The architectural/design flaw that
   produces the symptom. Use "5 Whys" — ask "why does this happen?"
   at least 3 levels deep.)
3. **Does my proposed fix eliminate the root cause, or does it only
   suppress the symptom?**

If the answer to #3 is "suppress," STOP. Redesign the fix.

#### Bandaid Test

A fix is a bandaid if any of these are true:

- It adds a special case / conditional to work around broken behavior.
- It silences, retries, or swallows an error instead of preventing it.
- It would break or need revisiting if the surrounding code changes.
- You cannot explain *why* the bug existed, only *what* it did.
- Another developer would look at the fix and ask "why is this here?"

If the fix fails the bandaid test, go deeper.

#### When a Bandaid Is Acceptable

Only when ALL of these are true:

1. The root cause is identified and documented.
2. A follow-up bead/issue is created for the real fix.
3. The user explicitly approves the temporary measure.
4. The bandaid is marked with `// BANDAID: <bead-id> — <why>`.

#### Escalation

If you catch yourself about to propose a quick fix, say so:

> "I notice my first instinct is to [quick fix]. But that addresses
> the symptom ([symptom]), not the root cause ([cause]). Here's what
> I recommend instead: [proper fix]."

This self-correction is expected and valued — not a failure.

---

## 3) THINK -> ALIGN -> ACT (Single Checkpoint Model)

### 3.1 THINK

Before coding:

- Read relevant code and recent commits.
- State the root cause hypothesis (§2.5 gate is required).
- Choose the smallest effective change.

### 3.2 ALIGN (One Checkpoint Per Scoped Task)

Use one concise alignment check for significant work:

```markdown
## Alignment Check
What I understood:
What I plan to do:
Files/systems in scope:
Risks/alternatives:
```

### 3.3 ACT

After user says **"yes" / "proceed"**, continue without repeated permission prompts for routine execution inside the approved scope.

Re-align only if one of these happens:

1. Scope expands to a new subsystem or materially more files.
2. Destructive/external side effects are required (`git push`, deploy, data-destructive command).
3. Two implementation attempts fail.
4. New evidence contradicts the approved plan.

### 3.4 Stop Signals

If user says `stop`, `wait`, `hold on`, `cancel`, or `no`: halt immediately and wait.

---

## 4) Session and Git Safety

### 4.1 Session Preflight (Start of Work)

```bash
git log --oneline -10
git status --short
ls thoughts/shared/handoffs
bd ready || bd --no-db ready
```

Read latest handoff and summarize done vs pending before changes.

### 4.2 Dirty File Rule (Clarified)

- This rule is **target-scoped**, not repo-wide.
- Pause only if a file you intend to edit is already dirty before you start, or if that same target file changes unexpectedly while you are editing it.
- Unrelated dirty files elsewhere in the working tree do not block work and must not trigger a generic "safety pause."
- If unrelated changes appear mid-task, note them in your final report and continue.
- If you dirtied the target file this session, continue.

### 4.3 Runtime Artifact Exceptions

Dirty runtime artifacts are usually non-blocking:
- `.beads/.migration-hint-ts`
- `.beads/last-touched`
- `.beads/sync-state.json`
- `.beads/*.db`, `*.db-wal`, `*.db-shm`
- daemon/socket/lock/runtime logs

Do not commit runtime artifact noise.

---

## 5) Planning and Handoffs

### 5.1 Canonical Spec Location

All planning artifacts live in:

```text
specs/<id>-<slug>/
  spec.md
  plan.md
  tasks.md
  research.md (optional)
```

ID format: zero-padded sequential (`001`, `002`, ...).

### 5.2 Bead Requirement for Specs

- No spec without a bead.
- `spec.md` must include bead ID at creation time.

### 5.3 Current-State Handoff

Use `thoughts/shared/handoffs/current.md` for latest state.

---

## 6) Beads Workflow (Lean)

- Use `bd sync` for `.beads` state; do not hand-edit tracked bead state files.
- If tracked `.beads` files are dirty, run `bd sync` (up to 2 attempts).
- Ask user only if tracked bead files remain dirty after retries.
- If only ignored runtime bead files are dirty, proceed.

Essential commands:

```bash
bd ready
bd update <id> --status=in_progress
bd close <id> --reason="Done"
bd sync
```

---

## 7) Verification Standard

Before saying "done":

1. Build relevant targets (`gj build <app>` when code changed).
2. Run relevant tests.
3. Verify behavior/log evidence for the changed path.

If verification could not run, state exactly why.

---

## 8) Destructive Command Guard (dcg)

- dcg is installed as a pre-execution hook for AI coding agents.
- When dcg blocks a destructive command, prefer safer alternatives over overriding:
  - **macOS**: Use `mv path ~/.Trash/` or `trash path` (Homebrew: `brew install trash`) instead of `rm -rf`.
  - **Linux**: Use `trash-put path` or `gio trash path` instead of `rm -rf`.
- Only use `dcg allow <code>` to override a block when the destructive command is genuinely required.

---

## 9) Slash Command Resolution

When a user message starts with `/command-name` (e.g., `/codex-review 036-profile-switch-gmp-wiring`):

1. **This is a command invocation**, not a bash command or a request to use interactive_shell.
2. Look up the command file: `~/.claude/commands/<command-name>.md`, `~/.pi/agent/prompts/<command-name>.md`, or the project's `.claude/commands/` directory.
3. Read the command file.
4. Follow its instructions exactly, treating everything after the command name as arguments.

Do NOT try to run slash commands as bash commands, interactive shells, or subagent calls. They are markdown instruction files that you read and execute inline.

---

## 10) Tooling Defaults

- Prefer `rg` / `rg --files` for search.
- Do not add arbitrary command timeouts to normal CLI tools.
- Use skills/docs for detailed procedures; keep AGENTS focused on constraints and decision rules.

---

*Unified agent configuration: https://github.com/carmandale/agent-config*

<!-- BEGIN COMPOUND PI TOOL MAP -->
## Compound Engineering (Pi compatibility)

This block is managed by compound-plugin.

Compatibility notes:
- Claude Task(agent, args) maps to the subagent extension tool
- For parallel agent runs, batch multiple subagent calls with multi_tool_use.parallel
- AskUserQuestion maps to the ask_user_question extension tool
- MCP access uses MCPorter via mcporter_list and mcporter_call extension tools
- MCPorter config path: .pi/compound-engineering/mcporter.json (project) or ~/.pi/agent/compound-engineering/mcporter.json (global)
<!-- END COMPOUND PI TOOL MAP -->

<!-- BEGIN COMPOUND CODEX TOOL MAP -->
## Compound Codex Tool Mapping (Claude Compatibility)

This section maps Claude Code plugin tool references to Codex behavior.
Only this block is managed automatically.

Tool mapping:
- Read: use shell reads (cat/sed) or rg
- Write: create files via shell redirection or apply_patch
- Edit/MultiEdit: use apply_patch
- Bash: use shell_command
- Grep: use rg (fallback: grep)
- Glob: use rg --files or find
- LS: use ls via shell_command
- WebFetch/WebSearch: use curl or Context7 for library docs
- AskUserQuestion/Question: ask the user in chat
- Task/Subagent/Parallel: run sequentially in main thread; use multi_tool_use.parallel for tool calls
- TodoWrite/TodoRead: use file-based todos in todos/ with file-todos skill
- Skill: open the referenced SKILL.md and follow it
- ExitPlanMode: ignore
<!-- END COMPOUND CODEX TOOL MAP -->

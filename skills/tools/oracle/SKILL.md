---
name: oracle
description: Consult Oracle (GPT-5 Pro) for complex debugging, architecture questions, or code review. Use when stuck on a problem, need a second opinion, or want deep analysis of code. Invoked when user says "ask the oracle" or similar.
---

# Oracle Skill

Consult GPT-5.2 Pro via browser automation for complex problems. Oracle bundles your prompt + files and sends them to another AI for deep analysis.

---

## 🚨 CRITICAL: READ THIS FIRST 🚨

### 1. Oracle takes 15-20 MINUTES (not seconds)

Real measured durations from production:
- `apr-ralph-reliabilit-round-9`: **16m38s**
- `apr-ralph-reliabilit-round-8`: **15m37s**
- `apr-ralph-reliabilit-round-7`: **15m46s**

**You MUST set `timeout: 1800` (30 minutes) on the bash tool call.**

### 2. Oracle BLOCKS - it does NOT run in background

The command will not return until oracle completes. This 15+ minute wait is normal.

### 3. Pre-flight checklist (DO ALL OF THESE)

```bash
# 1. Check no other oracle is running
oracle status --hours 1

# 2. Verify your files exist and check token count
oracle --dry-run summary -p "test" --file "your/file.swift"

# 3. THEN run with timeout: 1800
oracle -p "your prompt" --file "your/file.swift" --slug "descriptive-name"
```

---

## Common Failure Modes (Why Agents Fail)

### ❌ Failure 1: Timeout too short

| Timeout | Result |
|---------|--------|
| Default/none | ❌ Fails immediately |
| 600 (10 min) | ❌ Too short - real queries take 15+ min |
| 900 (15 min) | ⚠️ Borderline - may timeout |
| **1800 (30 min)** | ✅ **USE THIS** |

### ❌ Failure 2: File paths with spaces

```bash
# WRONG - spaces break the command
--file /Users/me/Groove Jones Dropbox/Projects/file.swift

# CORRECT - quote paths with spaces
--file "/Users/me/Groove Jones Dropbox/Projects/file.swift"
```

### ❌ Failure 3: Wrong relative paths across repos

```bash
# WRONG - missing nested directory
--file ../orchestrator/Sources/Networking/File.swift

# CORRECT - check actual path structure
--file ../orchestrator/orchestrator/Sources/Networking/File.swift
```

**Always verify paths exist first:**
```bash
ls -la "../orchestrator/orchestrator/Sources/Networking/File.swift"
```

### ❌ Failure 4: Skipping dry-run

If files don't exist or exceed token limit, you won't know until oracle fails.

```bash
# ALWAYS do this first (instant, no timeout needed)
oracle --dry-run summary -p "test" --file "path/to/file.swift"
```

### ❌ Failure 5: Forgetting --slug

Without a slug, recovery is harder if something goes wrong.

```bash
# WRONG
oracle -p "prompt" --file file.swift

# CORRECT
oracle -p "prompt" --file file.swift --slug "descriptive-session-name"
```

### ❌ Failure 6: Chrome browser not open

Oracle uses browser automation. Chrome must be running.

### ❌ Failure 7: Running multiple oracle queries

Oracle can only handle one query at a time. Check status first:

```bash
oracle status --hours 1
# If any show "running", wait for them to complete
```

---

## The Correct Workflow

### Step 1: Pre-flight checks

```bash
# Check no oracle currently running
oracle status --hours 1

# Verify files exist (especially paths with spaces or across repos)
ls -la "path/to/file.swift"
ls -la "../other-repo/path/to/file.swift"

# Preview token count and file validity
oracle --dry-run summary \
  -p "Your prompt here" \
  --file "path/to/file1.swift" \
  --file "path/to/file2.swift"
```

### Step 2: Run oracle (timeout: 1800)

```bash
oracle \
  -p "## Context
Project: [name]
Stack: [language/framework]

## Problem
[Exact error or issue]

## Question
[Specific question]" \
  --file "path/to/file1.swift" \
  --file "path/to/file2.swift" \
  --slug "descriptive-session-name"
```

**This command will block for 15-20 minutes. That's normal. Do not interrupt.**

### Step 3: If interrupted, recover the result

```bash
# Check if it completed
oracle status --hours 4

# Get the response
oracle session <slug> --render
```

---

## Prompt Structure

Oracle has ZERO context about your project. Always include:

```markdown
## Project Context
- Project: [repo name]
- Stack: [Swift/visionOS, TypeScript/Node, etc.]
- Build: [how to build - e.g., "gj build orchestrator"]
- Purpose: [what this code does]

## The Problem
[Exact error message or unexpected behavior]
[Include relevant log output]

## What I've Tried
- [Attempt 1 and result]
- [Attempt 2 and result]

## Specific Question
[One clear, answerable question]

## Constraints
- [Don't change X]
- [Must maintain Y compatibility]
```

---

## File Selection

**Fewer files = better results.** Pick only what's needed:

```bash
--file src/auth/login.swift           # Single file
--file src/auth/                       # Directory (all files)
--file "src/**/*.swift"               # Glob pattern
--file "src/**" --file "!**/*.test.*" # Exclude tests
```

**Check token count before running:**
```bash
oracle --dry-run summary --files-report -p "test" --file "src/**"
```

Stay under ~196k tokens.

---

## npx vs oracle

The SKILL.md previously recommended `npx -y @steipete/oracle@latest`. 

**In practice, just `oracle` works if it's installed.** Use whichever works:

```bash
# If oracle is in PATH (typical)
oracle -p "prompt" --file file.swift

# If oracle is not in PATH, use npx
npx -y @steipete/oracle@latest -p "prompt" --file file.swift
```

---

## Recovery Pattern

If your command timed out or was interrupted:

```bash
# 1. Check session status
oracle status --hours 4

# 2. If "completed", get the response
oracle session <slug> --render

# 3. If "running", either:
#    - Wait and check again
#    - The browser session is still working; let it finish

# 4. If "error", check what went wrong
oracle session <slug> --render
```

---

## Manual Fallback (If Browser Automation Fails)

```bash
# Generate bundle and copy to clipboard
oracle --render --copy \
  -p "YOUR PROMPT" \
  --file src/relevant.swift

# Then manually paste into ChatGPT web interface
```

---

## Key Facts

| Fact | Value |
|------|-------|
| Config | `~/.oracle/config.json` |
| Sessions | `~/.oracle/sessions/` |
| Model | GPT-5.2 Pro (browser mode) |
| **Behavior** | **BLOCKS until complete** |
| **Typical duration** | **15-17 minutes** |
| **Required timeout** | **1800 (30 minutes)** |

---

## Complete Example

User: "Ask the oracle about this TLS certificate error"

```bash
# 1. Pre-flight: Check status
oracle status --hours 1
# Output: No running sessions

# 2. Pre-flight: Verify files exist
ls -la "../AVPStreamKit/Sources/AVPStreamCore/TLSIdentity.swift"
# Output: file exists

# 3. Pre-flight: Dry run
oracle --dry-run summary \
  -p "## Context
Project: groovetech-media-server + orchestrator
Stack: Swift/macOS/visionOS, Network.framework QUIC

## Problem
TLS handshake fails with -9808 bad certificate format

## Question
Is the SAN mismatch the cause?" \
  --file "../AVPStreamKit/Sources/AVPStreamCore/TLSIdentity.swift" \
  --file "Sources/Networking/CommandServer.swift"
# Output: ~2k tokens, 2 files - OK

# 4. Run with timeout: 1800 (THIS WILL TAKE 15+ MINUTES)
oracle \
  -p "## Context
Project: groovetech-media-server + orchestrator  
Stack: Swift/macOS/visionOS, Network.framework QUIC

## Problem
TLS handshake fails with -9808 bad certificate format

## Question
Is the SAN mismatch the cause?" \
  --file "../AVPStreamKit/Sources/AVPStreamCore/TLSIdentity.swift" \
  --file "Sources/Networking/CommandServer.swift" \
  --slug "tls-certificate-debug"

# 5. Response arrives after ~15 minutes
```

---

## If Your Agent Session Times Out

If you're running in Codex, Claude, or another agent and your SESSION times out while waiting for oracle:

**The oracle query is still running in the browser.** It doesn't stop just because your agent died.

### Recovery in a new session:

```bash
# 1. Check what oracle sessions exist
oracle status --hours 4

# 2. Find your session by slug or timestamp
# Look for "completed" status

# 3. Get the result
oracle session <your-slug> --render
```

### Tell the user:

If oracle is taking a long time, tell the user:
> "Oracle is processing (typically takes 15-17 minutes). If this session times out, 
> you can recover the result with: `oracle session <slug> --render`"

---

## When NOT to Use Oracle

Oracle is expensive (time). Don't use it for:

- Simple questions you can answer yourself
- Syntax errors (just read the error)
- Questions about your own codebase (you have the files)
- Quick debugging (try logs first)

**Use oracle for:**
- Complex architectural questions
- Debugging issues after you've tried everything
- Code review of tricky logic
- Cross-referencing multiple codebases
- Questions requiring deep reasoning

---

## Anti-Patterns

| ❌ Don't | ✅ Do |
|---------|------|
| Use timeout < 1800 | **timeout: 1800** |
| Skip dry-run | **Always dry-run first** |
| Skip path verification | **ls -la files first** |
| Forget --slug | **Always use --slug** |
| Unquoted paths with spaces | **Quote all paths** |
| Run multiple oracles | **One at a time** |
| Expect quick response | **Expect 15-20 min wait** |
| Interrupt the command | **Let it complete** |
| Use for simple questions | **Only for complex problems** |

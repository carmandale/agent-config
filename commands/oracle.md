---
description: Consult GPT-5 Pro (Oracle) for complex debugging, architecture questions, or code review
---

Consult Oracle (GPT-5 Pro) for a second opinion on complex problems.

## Usage

```
/oracle <question or topic>
```

Example: `/oracle why is this TLS handshake failing`

## CRITICAL: Oracle runs detached

Oracle takes 15 minutes to 1+ hour. **ALWAYS run detached** with `nohup ... &` so it survives if this session ends.

## Step 1: Pre-flight Checks

```bash
# Check no oracle currently running
oracle status --hours 1
```

If one is running, either wait or attach to see its progress.

## Step 2: Identify Relevant Files

Based on the user's question and current context:
- What files are relevant to this question?
- Verify they exist before attaching

```bash
# Verify files exist (adjust paths as needed)
ls -la "path/to/relevant/file.swift"
```

## Step 3: Dry Run (Check Token Count)

```bash
oracle --dry-run summary \
  -p "test prompt" \
  --file "path/to/file1" \
  --file "path/to/file2"
```

Stay under ~196k tokens.

## Step 4: Build the Prompt

Oracle has ZERO context. Include:

```markdown
## Project Context
- Project: [repo name]
- Stack: [Swift/visionOS, TypeScript/Node, etc.]
- Build: [how to build]

## The Problem
[Exact error or issue from user's question]
[Include relevant log output if available]

## What We've Tried
[Any prior attempts mentioned]

## Specific Question
[Clear, answerable question based on user's input]
```

## Step 5: Run Oracle DETACHED

Generate a short slug from the question (3-5 words, lowercase, hyphens).

**Use `nohup bash -lc`** - this works in both Pi and Codex environments:

```bash
nohup bash -lc 'oracle \
  -p "## Project Context
Project: [name]
Stack: [stack]

## Problem
[problem description]

## Question
[specific question]" \
  --file "relevant/file1.swift" \
  --file "relevant/file2.swift" \
  --slug "descriptive-slug-here"' \
  > /tmp/oracle-descriptive-slug-here.log 2>&1 &

echo "✅ Oracle started in background"
echo "📊 Check status: oracle status --hours 1"
echo "📖 Get result:   oracle session descriptive-slug-here"
echo "📄 View log:     cat /tmp/oracle-descriptive-slug-here.log"
```

## Step 6: Report to User

Tell the user:

```
Oracle is now running in the background (typically 15-20 min, up to 1hr for complex questions).

**Check status:** `oracle status --hours 1`
**Get result:** `oracle session <slug>`

I'll continue working. Let me know when you want to check the Oracle's response.
```

## When Oracle Completes

To retrieve and present the response:

```bash
oracle session <slug>
```

Summarize the key insights for the user.

## Recovery

If interrupted or session ended:

```bash
# Find the session
oracle status --hours 4

# Get the response
oracle session <slug>
```

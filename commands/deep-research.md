---
description: Run deep multi-agent research on a complex question
---

Deep research mode. Spawn a hierarchical agent swarm to explore a question from multiple angles, then synthesize findings.

## Usage

```
/deep-research <question>
/deep-research <question> --no-web
/deep-research <question> --model sonnet --researcher haiku
```

**Note:** Web search is ENABLED by default. Use `--no-web` to disable.

The input is: $ARGUMENTS

## Step 1: Parse Arguments

Extract from `$ARGUMENTS`:
- `--model` or `-m` → ORCHESTRATOR (default: opus)
- `--researcher` or `-r` → RESEARCHER (default: sonnet)
- `--no-web` → NO_WEB_FLAG (disables web search; web is ON by default)
- Everything else → QUESTION

**Web search is enabled by default** to ensure comprehensive research.

If no question provided, ask:
```
What question do you want to research? Include any context that would help focus the exploration.
```

## Step 2: Validate

Check Claude CLI is available:
```bash
which claude || echo "ERROR: Claude CLI not found"
```

## Step 3: Execute Deep Research

Build and run the command:

```bash
cd "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/deep-research" && \
./deep-research.sh \
  ${MODEL_FLAG:+-m "$ORCHESTRATOR"} \
  ${RESEARCHER_FLAG:+-r "$RESEARCHER"} \
  ${NO_WEB_FLAG:---web} \
  "$QUESTION"
```

**Note:** `--web` is passed by default unless `--no-web` was specified.

**Inform the user:**
```
## Deep Research Started

**Question:** <question>
**Orchestrator:** <model>
**Researchers:** <model>
**Web Search:** <enabled/disabled>

⏳ This typically takes 1-5 minutes depending on complexity...

Agents are spawning and exploring. The orchestrator will:
1. Break down your question into sub-angles
2. Spawn parallel researchers for each angle
3. Researchers may spawn their own sub-researchers
4. Results synthesize back up the chain
```

## Step 4: Find the Report

After completion, find the most recent report:

```bash
ls -td "/Users/dalecarman/Groove Jones Dropbox/Dale Carman/Projects/dev/deep-research/reports/"*/ 2>/dev/null | head -1
```

The synthesis file is at: `<report_dir>/SYNTHESIS.md`

## Step 5: Read and Present Synthesis

Read the full SYNTHESIS.md file and present it to the user.

Format the output:
```
## Deep Research Complete

**Report:** <full path to SYNTHESIS.md>

---

<SYNTHESIS.md contents>

---

## Next Steps

- The full report is saved at: `<path>`
- Want me to apply any of these insights to your current work?
- Should I create a bead to track follow-up actions?
```

## Model Reference

| Config | Depth | Speed | Cost | Best For |
|--------|-------|-------|------|----------|
| `-m opus -r sonnet` | Deep | Slow | $$$ | Best quality (default) |
| `-m sonnet -r sonnet` | Deep | Medium | $$ | Good balance |
| `-m sonnet -r haiku` | Shallow | Fast | $ | Quick answers |
| `-m opus -r opus --web` | Maximum | Slowest | $$$$ | Comprehensive current events |

## Notes

- **Haiku stops recursion** - researchers answer directly, no sub-agents
- **Web search is ON by default** - use `--no-web` to disable for purely local/codebase research
- **Cost varies wildly** - simple with haiku: $1-2, complex with opus: $20-50+
- **Reports persist** - all reports saved in `deep-research/reports/`

## Context Passing

When running from within a project, the command automatically has access to:
- Current working directory context
- Any files you've been discussing in the session
- The question should include relevant file paths or code snippets if needed

For codebase-specific research, include paths like:
```
/deep-research "Why is DeviceRowView stuck in Initializing state? Check orchestrator/Models/AppUIModel+CapabilitiesAck.swift and Shared Types/HeadsetViewState.swift"
```

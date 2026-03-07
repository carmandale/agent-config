---
description: Create a bead and numbered spec/plan/tasks for an issue or feature — the canonical way to start tracked work
---

Create a bead for this work and a numbered spec in `specs/`. This is non-negotiable structure — every piece of tracked work gets a bead and a spec directory.

**The issue:** $ARGUMENTS

## What you must do

1. **Create the bead** using `bd create --title "<concise title>"` with a description derived from the issue. Mark it in_progress.

2. **Determine the next spec number.** Count existing `specs/[0-9]*` directories and increment. Zero-pad to 3 digits. Pick a short, descriptive kebab-case slug (3-5 words, not "thing" or "stuff").

3. **Create the spec directory and all three files:**

```
specs/<NNN>-<slug>/
├── spec.md      # Requirements, acceptance criteria, the "what and why"
├── plan.md      # Implementation approach, architecture decisions, the "how"
└── tasks.md     # Ordered checkable task list, the "do this"
```

4. **Every file gets YAML frontmatter** with at minimum:
```yaml
---
title: "..."
date: YYYY-MM-DD
bead: <bead-id>
---
```

5. **Do the actual thinking.** Read relevant code. Understand the problem space. Research existing patterns in the codebase. The spec should reflect real understanding, not boilerplate. Use the workflows-plan skill's research approach if the problem is non-trivial — run repo-research-analyst and learnings-researcher to build context.

6. **Tell me** the bead ID and spec path when done. Suggest next steps — usually `/codex-review <spec>` or `/implement <spec>` depending on complexity.

## Rules

- The `specs/` directory structure is sacred. Do not invent alternative formats. No PRDs, no loose plan files, no docs/plans/ directories. It's `specs/<NNN>-<slug>/` with spec.md, plan.md, tasks.md. Period.
- The bead ID must appear in every file's frontmatter. No spec without a bead (§5.2 of AGENTS.md).
- If shaping was done first (look for a shaping doc in the conversation, or a `shaping-transcript.md` in the spec directory), use its selected shape, requirements, and fit check as the foundation. Don't re-derive what shaping already decided. If there's a transcript, move it into the spec directory.
- If no shaping was done and the problem is complex or ambiguous, say so: "This might benefit from `/shape` first — want to do that, or should I proceed with what we have?"

$ARGUMENTS
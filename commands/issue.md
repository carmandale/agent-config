---
description: Create a bead and numbered spec for an issue or feature — the canonical way to start tracked work
gate_creates: spec.md, log.md
gate_must_not_create: plan.md, tasks.md, codex-review.md, shaping-transcript.md, planning-transcript.md
---

Create a bead for this work and a numbered spec in `specs/`. This is non-negotiable structure — every piece of tracked work gets a bead and a spec directory.

**The issue:** $ARGUMENTS

## What you must do

1. **Create the bead** using `br create --title "<concise title>"` with a description derived from the issue. Mark it in_progress.

2. **Determine the next spec number.** Count existing `specs/[0-9]*` directories and increment. Zero-pad to 3 digits. Pick a short, descriptive kebab-case slug (3-5 words, not "thing" or "stuff").

3. **Create the spec directory and spec.md:**

```
specs/<NNN>-<slug>/
└── spec.md      # Requirements, acceptance criteria, the "what and why"
```

4. **spec.md gets YAML frontmatter** with at minimum:
```yaml
---
title: "..."
date: YYYY-MM-DD
bead: <bead-id>
---
```

5. **Do the actual thinking.** Read relevant code. Understand the problem space. The spec should reflect real understanding, not boilerplate — requirements, acceptance criteria, constraints, what's in scope and what's not.

6. **Tell me** the bead ID and spec path when done. Suggest next steps — typically `/plan <spec>` to build the implementation plan, or `/shape <problem>` first if the problem is complex or ambiguous and hasn't been shaped yet.

## Rules

- The `specs/` directory structure is sacred. Do not invent alternative formats. No PRDs, no loose plan files, no docs/plans/ directories. It's `specs/<NNN>-<slug>/`. Period.
- The bead ID must appear in spec.md frontmatter. No spec without a bead (§5.2 of AGENTS.md).
- If shaping was done first (look for a shaping doc in the conversation, or a `shaping-transcript.md` in the spec directory), use its selected shape, requirements, and fit check as the foundation. Don't re-derive what shaping already decided. If there's a transcript, move it into the spec directory.
- If no shaping was done and the problem is complex or ambiguous, say so: "This might benefit from `/shape` first — want to do that, or should I proceed with what we have?"
- Do not create plan.md or tasks.md — that's `/plan`'s job with a two-agent session.

## Log it

Append a line to `log.md` in the spec directory (create the file if it doesn't exist). Format:

```
YYYY-MM-DD HH:MM | <mesh-name or "—"> | <harness>/<model> | /issue | bead <id> — spec.md created
```

Harness is what's running you (pi, claude-code, codex, gemini, etc.). Model is your current model (claude-opus-4-6, gpt-5.3-codex, etc.). Mesh name is your pi_messenger identity if you've joined the mesh, or `—` if not.

## After completion

Run `scripts/gate.sh record issue specs/<NNN>-<slug>/ --harness "<harness>/<model>"` to write provenance sentinel into spec.md and update the pipeline state trail.

$ARGUMENTS
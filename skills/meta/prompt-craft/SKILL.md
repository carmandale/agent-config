---
name: prompt-craft
description: Write effective slash commands, skills, and prompts for AI coding agents. Use when creating or editing commands in commands/, writing SKILL.md files, or crafting prompts that agents will execute. Prevents the common mistake of over-structuring prompts into process documents that kill agent performance.
---

# Prompt Craft

How to write slash commands, skills, and prompts that actually work — learned the hard way across thousands of sessions.

## The Core Insight

There are two attention pathways in LLMs:

1. **System prompt / injected context** — content loaded before the conversation starts. The agent has it, but treats it like wallpaper. Low attention weight. It "technically read it" the way you technically read the safety card on your 500th flight.

2. **Explicit tool-call results** — content that arrives because the user or command asked for it. High attention weight. The agent processes it as "this matters right now."

This means: telling an agent to "read this file" produces dramatically better compliance than having the same content pre-loaded in its context. The content is identical — the salience is completely different.

When writing commands and skills, exploit this gap deliberately. Force explicit reads of critical files rather than assuming the agent absorbed injected instructions.

## Rules for Writing Commands

**Write like a person talking, not like a process document.** The agent should feel like it's receiving direct, urgent instructions from a human — not executing a specification.

**Keep emotional intensifiers.** Words like "super careful," "go deep," "meticulously" are not fluff — they increase attention weight on the behavior you want. Sanitizing them into clinical language reduces compliance.

**Use open-ended language.** "bugs, problems, errors, issues, silly mistakes, etc." keeps the search space open. Categorized taxonomies ("Logic errors, Security issues, Reliability problems...") close it. The agent checks boxes in your list instead of actually looking. The "etc." is doing real work.

**No output templates.** Don't specify report formats with markdown tables and headers. The agent will spend tokens conforming to your template instead of thinking deeply. Let it decide how to report based on what it finds.

**Deliberate repetition is a feature.** Stating a critical rule at both the start and end of a command creates behavioral brackets. Don't "clean it up" to say it once. The repetition increases compliance.

**Keep commands short.** The user's original prompts that work are single paragraphs. Every header, sub-bullet, and code block you add dilutes the signal. If the command is longer than the prompt it replaces, you probably over-structured it.

**Preserve casual phrasing.** "Sort of randomly explore" gives the agent permission to wander without a plan. "Systematically investigate using a randomized sampling approach" constrains the same behavior into a method. The casualness is the feature.

## Anti-Patterns That Kill Agent Performance

**Step-by-step process headers.** "Step 1: ... Step 2: ... Step 3: ..." turns investigators into form-fillers. The agent executes the checklist instead of thinking. Use steps only when the output is concrete artifact creation (like creating specific files in a specific format), not for open-ended exploration or review.

**Pre-specified categories of things to find.** Naming what to look for narrows the search space. The agent scans for items in your list instead of discovering things with genuinely fresh eyes.

**Bash scaffolding for things the agent knows how to do.** Adding code blocks for `mkdir -p` and `git log` is hand-holding that adds tokens without adding value and subtly tells the agent "just follow these commands" instead of "think and act."

**Output format templates.** Markdown report structures with `## Summary`, tables, and placeholder fields are token sinks that consume effort on formatting instead of investigation.

**Stripping the voice.** If the user's original prompt has urgency, directness, and personality — keep it. Don't refactor it into neutral technical documentation. The voice carries behavioral weight.

## When Structure IS Appropriate

Structure is correct when you're defining non-negotiable artifact formats — "create exactly these files in exactly this layout." The `/issue` command legitimately needs numbered steps and a directory tree because the output is a specific set of files. The `/sweep` command does NOT need numbered steps because the output is whatever the agent finds.

The test: **Is this command defining what to create, or what to discover?** Creation benefits from structure. Discovery is harmed by it.

## Forcing Skill Execution

When a command references a skill, agents often read the description and wing it instead of following the actual protocol. To prevent this:

1. **Point to the literal file path.** Not "use the shaping skill" but "Read the file at /full/path/to/SKILL.md completely. Follow its protocol exactly."

2. **Name the specific failure mode.** "DO NOT paraphrase or improvise your own version. If you find yourself [doing the shortcut], STOP — you skipped [the real thing]."

3. **Don't rely on artifact gating** where the agent checks its own work against a checklist. The agent is both executor and gatekeeper — it'll produce artifacts that technically satisfy the checklist without having done the real work. The human is the best gatekeeper.

## Instructions Are Code

Agent instructions execute top-to-bottom like code. Agents don't re-read a command file looking for preconditions buried in later sections — they process sequentially and stop at the first match. Three specific failure modes:

**Ordering is execution order.** If a check appears in section 3 but must fire before section 1, it won't. Example: a `/ground` command listed "force flag" as a Tier 3 entry condition. But the agent evaluates Tier 1 first — if Tier 1 matches, Tier 3's conditions are never read. The force flag was silently ignored. Fix: move the force pre-check to the preamble, before any tier evaluation.

**Preconditions before operations.** If step 3 writes a file and step 4 creates the directory, the write fails on a fresh machine. Agents follow the numbered order literally. Example: cache write instructions said "write to `.claude/ground-cache.tmp`" in step 2 and "if `.claude/` doesn't exist, create it" in step 4. On a repo with no `.claude/` directory, step 2 fails. Fix: directory creation must be step 1.

**Constraints in ALL branches.** If a data hygiene rule appears in one code path but not another, the unguarded path produces dirty output. Example: a "4KB cap, no secrets" rule was stated for Tier 3's cache write but omitted from Tier 2's cache rewrite. Tier 2 could produce an oversized or sensitive cache. Fix: state the constraint in every branch that produces the artifact, even if it feels redundant.

**The test:** Read your command file as if you're an agent seeing it for the first time, top-to-bottom, and you'll stop at the first section that matches your situation. Does every possible execution path encounter all the preconditions and constraints it needs? If a constraint lives in a section the agent might not reach, it's dead code.

## Preventing Process Theater

Agents will sometimes "perform" a workflow — producing plausible-looking artifacts without having done the actual work. This is especially common with complex skills (shaping, deep review) where the output format is known but the work is hard. Theater happens because it's cheaper to reverse-engineer the deliverables from the format than to go through the process.

**Require specific citations.** Every finding, claim, or decision must reference specific file paths, line numbers, and actual code. Vague claims ("there might be issues in the networking layer") are the signature of theater. Specific citations ("line 47 of transport.swift has an off-by-one") force the agent to have actually read the code. Add this requirement to any command that produces findings or analysis.

**Cross-model verification.** The agent that did the work should never be the only agent that judges the work. Use a different model (e.g., codex-review) to verify critical outputs. Different models have different biases and won't rubber-stamp each other's theater.

**Interactive over autonomous.** Commands that require real human input at multiple points are naturally theater-resistant — the agent can't fake a conversation. Fire-and-forget commands are where theater thrives. When designing workflows, prefer interactive checkpoints over autonomous end-to-end execution for critical phases.

**Spot-check with "prove it."** After an agent produces findings, pick one at random and ask it to walk you through the code. Agents that did real work can do this. Agents that faked it can't. This is cheap and devastatingly effective.

## Anchor Trust in Artifacts, Not Words

The strongest anti-theater measure isn't better prompt language — it's requiring **mechanical proof that an external process actually ran.** Agent claims are unfalsifiable. File artifacts from external tools are not.

The principle: every critical verification gate should produce a non-fakeable artifact that gets committed to the repo.

- **Codex review** → save the session transcript (`codex-review.md`) in the spec directory. Contains Codex's actual words, session ID, verdict. If the file doesn't exist, the review didn't happen.
- **Bead creation** → `bd create` changes `.beads/` state. The bead exists or it doesn't.
- **Shaping** → requires two participants (user + agent, or agent + agent). One agent solo is theater. Save two-agent transcripts to `shaping-transcript.md` in the spec directory. If the user was present, their presence is the proof. If autonomous, the transcript is the proof.
- **Implementation** → git commits exist in the log or they don't.

When designing commands and workflows: prefer external tool artifacts over agent self-reporting. The question isn't "did the agent say it did the thing" — it's "does the artifact exist."

A fully verified spec directory is its own dashboard:

```
specs/<NNN>-<slug>/
  spec.md                  ← spec exists
  plan.md                  ← plan exists
  tasks.md                 ← tasks exist
  shaping-transcript.md    ← real shaping happened (two participants)
  codex-review.md          ← codex actually ran
```

No file = didn't happen. Glanceable across projects with `ls specs/*/codex-review.md`. Design for file-existence checks, not reading file contents.

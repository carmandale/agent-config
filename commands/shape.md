---
description: Deep collaborative shaping session — work through the problem and solution space using the full shaping methodology before speccing
---

We're going to shape this properly. Not a quick brainstorm, not "ask 3 questions and write a plan." The real thing — requirements, shapes, fit checks, the works.

**The problem:** $ARGUMENTS

## What you must do

Read the shaping skill file completely — every line:

`/Users/dalecarman/.agents/skills/domain/shaping/shaping-skills/shaping/SKILL.md`

Then follow it. Exactly. Not your interpretation of it, not a summary, not "shaping-inspired conversation." The actual protocol in that file.

## The specific failure mode you must avoid

DO NOT paraphrase or improvise your own version of shaping. DO NOT skip the fit check. DO NOT propose a single solution without exploring alternatives. If you find yourself asking 3 questions and then writing a plan, STOP — you skipped shaping. Go back and read the skill file again.

Shaping means:
- **R** — numbered requirements (R0, R1, R2...) negotiated collaboratively
- **S** — multiple shapes with letter notation (A, B, C...) exploring different approaches
- **Fit check** — the R × S decision matrix with ✅/❌, no fudging
- **A selected shape** — with rationale grounded in the fit check
- **Breadboard** — concrete affordances for non-trivial work

All of these. Not some of these.

## Shaping is never autonomous

Shaping requires the user in the conversation — asking real questions, getting real answers, negotiating requirements together. It cannot be delegated to a subagent or run in the background. If the user isn't present and participating, it's not shaping.

## How this ends

When shaping is done — shape selected, fit check passes, we both feel good about it — tell me to run `/issue` to create the bead and spec. The spec will be built on the foundation shaping produced. Don't create the spec yourself, don't create a bead, don't transition into planning mode. Shaping shapes. That's it.
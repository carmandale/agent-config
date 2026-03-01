---
name: full-pipeline
description: Complete development pipeline - scout, plan, implement, review
---

## scout
output: context.md

Gather comprehensive context for {task}. Identify key files, patterns, dependencies, and potential challenges.

## planner
reads: context.md
output: plan.md

Create a detailed implementation plan based on {previous}. Include prerequisites, ordered steps, and testing strategy.

## implementer
reads: plan.md
progress: true

Execute the implementation plan. Update progress.md as you complete each step. {previous}

## reviewer
reads: progress.md
output: review.md

Review all changes made. Check for correctness, style, security, and adherence to the plan. {previous}

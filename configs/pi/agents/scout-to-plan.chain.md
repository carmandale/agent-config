---
name: scout-to-plan
description: Scout the codebase then create an implementation plan
---

## scout
output: context.md

Analyze the codebase for {task}. Focus on relevant files, patterns, and existing implementations that relate to this task.

## planner
reads: context.md
output: plan.md

Create an implementation plan based on {previous}. Be specific about files to create/modify and the order of operations.

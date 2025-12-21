# CLAUDE.md

> Agent OS User Standards
> Last Updated: 2025-09-15

## Purpose

This file directs Claude Code to use your personal Agent OS standards for all development work. These global standards define your preferred way of building software across all projects.

## Global Standards

### Development Standards
- **Tech Stack Defaults:** @~/.agent-os/standards/tech-stack.md
- **Code Style Preferences:** @~/.agent-os/standards/code-style.md
- **Best Practices Philosophy:** @~/.agent-os/standards/best-practices.md

### Agent OS Instructions
- **Initialize Products:** @~/.agent-os/instructions/plan-product.md
- **Plan Features:** @~/.agent-os/instructions/create-spec.md
- **Execute Tasks:** @~/.agent-os/instructions/execute-tasks.md
- **Analyze Existing Code:** @~/.agent-os/instructions/analyze-product.md

## How These Work Together

1. **Standards** define your universal preferences that apply to all projects
2. **Instructions** guide the agent through Agent OS workflows
3. **Project-specific files** (if present) override these global defaults

## Using Agent OS Commands

You can invoke Agent OS commands directly:
- `/plan-product` - Start a new product
- `/create-spec` - Plan a new feature
- `/execute-task` - Build and ship code
- `/analyze-product` - Add Agent OS to existing code

## Important Notes

- These are YOUR standards - customize them to match your preferences
- Project-specific standards in `.agent-os/product/` override these globals
- Update these files as you discover new patterns and preferences

---

*Using Agent OS for structured AI-assisted development. Learn more at [buildermethods.com/agent-os](https://buildermethods.com/agent-os)*
- NEVER go out of scope.
- NEVER add old iOS patterns like UIKit to visionOS apps
- ONLY work on what you are asked to work on
- CRITICAL WORK STANDARD: When asked to check status against requirements, specifications, or documents - you MUST find, read, and verify against the actual source document. NEVER rely on memory, assumptions, or prior knowledge. If
   you cannot locate the document, explicitly state this and ask for the path/location. Making claims about completeness or status without reading the actual requirements is a fundamental failure that wastes time and erodes trust. 
  Always say 'Let me find and read [document name]' before making any status assessments.
---
description: Multi-perspective code review (simplicity, security, performance, architecture)
---

Perform a thorough code review of: **$@**

If no target specified, review changes on current branch vs main.

## Instructions

Load and follow the review skill:

```
skill: review
```

Use the skill's methodology to run multiple review passes:

1. **Gather context** - Identify what's being reviewed (PR, branch, files)
2. **Simplicity pass** - Is it as simple as it can be?
3. **Security pass** - Any vulnerabilities?
4. **Performance pass** - Will it scale?
5. **Architecture pass** - Does it fit the codebase?
6. **Language-specific pass** - Following best practices?
7. **Test coverage pass** - Is it tested?

## Output

Synthesize findings into prioritized report:

```markdown
## Review Summary

**Target**: [what was reviewed]
**Verdict**: [Approve / Request Changes / Comment]

### 🔴 Critical
[blocking issues]

### 🟡 Important  
[should fix]

### 🔵 Suggestions
[nice to have]

### ✅ What's Good
[positive observations]
```

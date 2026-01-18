---
description: Execute a work plan efficiently and ship complete features
---

Execute the work plan: **$@**

If no file specified, look for the most recent plan in `plans/` directory.

## Instructions

Load and follow the work skill:

```
skill: work
```

Use the skill's methodology:

1. **Clarify** - Read the plan completely, ask questions if unclear
2. **Setup** - Create branch, verify environment, create task list
3. **Execute** - Implement following existing patterns, test continuously
4. **Quality** - Run lints, self-review, verify acceptance criteria
5. **Ship** - Commit, push, create PR

## Key Principles

- **Ask questions first** - Don't build the wrong thing
- **Follow existing patterns** - The codebase is your guide
- **Test as you go** - Don't wait until the end
- **Ship complete features** - 100% done beats 80% done

## Output

When complete:

```markdown
## Work Complete

**Plan**: [plan file]
**Branch**: [branch name]
**PR**: [PR link]

**Completed**:
- [x] [task 1]
- [x] [task 2]

**Acceptance Criteria**:
- [x] [criterion 1] - verified
- [x] [criterion 2] - verified
```

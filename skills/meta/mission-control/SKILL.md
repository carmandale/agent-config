---
name: mission-control
description: Multi-agent workflow orchestration for building features Interview → Plan → Implement → Review with Ralph Orchestrator integration
allowed-tools: [Bash, Read, Write]
---

# Mission Control Skill

Multi-agent workflow orchestration inspired by Todd Anderson's Mission Control and Nico's pi-interview patterns. Integrates with Ralph Orchestrator for interactive planning.

## The Flow

```
Interview (pi-interview) → Plan (Ralph interactive) → Implement → Review
```

## Ralph Integration

Mission Control integrates with **Ralph Orchestrator** for:

1. **Interactive Planning** — `ralph plan` for SOP-driven planning sessions
2. **Real-time TUI** — `ralph run --tui` for monitoring
3. **Session Tracking** — Sessions stored in `~/.ralph-o/sessions/`

## Commands

| Command | Description |
|---------|-------------|
| `mission-control start "<name>"` | Create new project |
| `mission-control status` | Show all projects |
| `mission-control status "<name>"` | Show project details |
| `mission-control interview "<name>"` | Prepare interview phase |
| `mission-control plan "<name>"` | Create Ralph session for planning |
| `mission-control tui "<name>"` | Open Ralph TUI |
| `mission-control implement "<name>"` | Run implementation |
| `mission-control review "<name>"` | Run review |
| `mission-control done "<name>"` | Mark complete |
| `mission-control restore "<session>"` | Import Ralph session |

## Interactive Planning with Ralph

### The Planning Flow

```bash
# 1. Start project
mission-control start "Feature Name"

# 2. Run interview
mission-control interview "Feature Name"

# 3. Create Ralph session for planning
mission-control plan "Feature Name"

# 4. Interactive planning (in Ralph session)
cd ~/.ralph-o/sessions/feature-name
ralph plan "Feature description"

# 5. Run TUI during implementation
mission-control tui "Feature Name"
```

### Ralph Commands Reference

| Command | Description |
|---------|-------------|
| `ralph plan` | Interactive SOP-driven planning |
| `ralph run` | Autonomous mode |
| `ralph run --tui` | Real-time TUI monitoring |
| `ralph task` | Generate code tasks from plan |
| `ralph events` | View event history |

### Ralph Session Structure

```
~/.ralph-o/sessions/<project-name>/
  plan/
    rough-idea.md          # Initial idea
    idea-honing.md         # Refined ideas
    prd.md                 # Product Requirements Doc
  tasks/                    # Generated code tasks
  prd.json                  # Structured plan
```

## Ralph Tenets (From AGENTS.md)

1. **Fresh Context Is Reliability** — Each iteration clears context
2. **Backpressure Over Prescription** — Don't prescribe how; create gates
3. **The Plan Is Disposable** — Regeneration costs one planning loop
4. **Disk Is State, Git Is Memory** — Files are the handoff mechanism
5. **Steer With Signals, Not Scripts** — Add signs for next time

## Code Tasks

Use `/code-task-generator` to create structured task files from plans:

```bash
/code-task-generator .sop/planning/design/detailed-design.md --step 1
```

Use `/code-assist` to implement tasks:

```bash
/code-assist tasks/step01/task-01.code-task.md
```

## Workflow Stages

| Stage | Icon | Command | Description |
|-------|------|---------|-------------|
| new | 📦 | `start` | Project created |
| interview | 📋 | `interview` | Requirements gathering |
| plan | 📝 | `plan` + `ralph plan` | Interactive planning |
| implementation | 🛠️ | `implement` + `ralph run --tui` | Building |
| review | 👁️ | `review` | Reviewing |
| done | ✅ | `done` | Complete |

## Files Created

```
chipbot/
  tools/
    mission-control.sh
  data/
    mission-control/
      projects/
        <project-name>/
          project.json      # Project metadata
          state.json        # Current stage
          interview.json   # Requirements interview
          plan.json        # Plan reference
          activity.jsonl   # Activity log

~/.ralph-o/sessions/
  <project-name>/
    plan/
      rough-idea.md
      idea-honing.md
      prd.md
    tasks/
      stepNN/
        task-NN.code-task.md
```

## Usage Patterns

### Pattern 1: Full Ralph Integration

```bash
# Start
mission-control start "New Feature"

# Interview
mission-control interview "New Feature"

# Interactive planning
mission-control plan "New Feature"
cd ~/.ralph-o/sessions/new-feature
ralph plan "Build a REST API for users"

# Implementation with TUI
mission-control tui "New Feature"

# Review
mission-control review "New Feature"
mission-control done "New Feature"
```

### Pattern 2: Quick Feature

```bash
mission-control start "Quick Fix"
mission-control plan "Quick Fix"
ralph run  # Autonomous mode
mission-control done "Quick Fix"
```

### Pattern 3: Import Existing Ralph Session

```bash
# Already have a Ralph session?
mission-control restore my-existing-session
```

## Ralph Presets

Ralph includes 20+ presets for different workflows:

```bash
ralph init --preset tdd-red-green      # TDD workflow
ralph init --preset spec-driven         # Spec-first development
ralph init --preset review             # Code review workflow
ralph init --preset debug             # Bug investigation

# Use with Mission Control
mission-control plan "Feature"
ralph init --preset tdd-red-green --force
ralph run --tui
```

## Monitoring

### Check Status

```bash
mission-control status
mission-control status "My Feature"
```

### Ralph TUI

```bash
mission-control tui "My Feature"
# Or directly:
ralph run --tui
```

### View Events

```bash
ralph events  # Event history
ralph jobs   # Running jobs
```

## References

- [Todd Anderson's Mission Control](https://x.com/_toddanderson/status/2020911081179222017)
- [Nico's pi-interview pattern](https://x.com/nicopreme/status/2021343925425013196)
- [Kol Tregaskes Mission Control](https://x.com/koltregaskes/status/2018029594524496165)
- [Ralph Orchestrator](https://github.com/mikeyobrien/ralph-orchestrator)
- [Ralph Presets](https://github.com/mikeyobrien/ralph-orchestrator#presets)

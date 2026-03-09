# Installer Hygiene

CLI tool installers frequently drop uninvited files into agent skill/config directories. When your skill directories are symlinked (as in agent-config), these files pollute ALL agents across ALL repos.

## Pattern

After installing any CLI tool via `curl | bash` or package manager:

1. **Check git status immediately** — `git status --short` in agent-config
2. **Check skill directories** — `ls ~/.claude/skills/ ~/.codex/skills/ ~/.agents/skills/` for unexpected additions
3. **Remove installer artifacts** before committing

## Known Offenders

| Tool | What it drops | Where |
|------|-------------|-------|
| `br` (beads_rust) | `bd-to-br-migration/` skill (8 files), `mini-db-sync/` skill, modifies `mini-sync/SKILL.md` | `~/.claude/skills/`, `~/.codex/skills/`, project `skills/` |

## DO
- Run `git status` after every CLI install
- Clean up installer-dropped files before any commit
- Use `trash` (not `rm`) for cleanup per §8

## DON'T
- Assume installers only modify their own binary
- Commit without checking for installer side-effects
- Let installer artifacts reach your skill discovery paths

## Source Sessions
- spec-010-beads-backend-evaluation (2026-03-09): br installer dropped 8 files into skills directory + modified existing SKILL.md

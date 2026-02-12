# Napkin

## Corrections
| Date | Source | What Went Wrong | What To Do Instead |
|------|--------|----------------|-------------------|
| 2026-02-10 | User | Proposed solutions without seeing complete architecture - kept stumbling and contradicting myself | Step back, map the COMPLETE picture first (all agents, all paths, all sources) before proposing solutions |
| 2026-02-10 | User | Suggested symlinks that would cause duplication for Claude Code | Ask "will this cause duplicates?" before proposing any symlink architecture |
| 2026-02-10 | User | Hardcoded version number (2.28.0) in symlink path | Use `installed_plugins.json` installPath modification or version-agnostic approaches |
| 2026-02-10 | User | Removed plugin from installed_plugins.json but left cached files | When uninstalling plugins, remove: (1) entry from installed_plugins.json, (2) cache directory, (3) marketplaces directory |
| 2026-02-10 | Self | Kept proposing partial solutions without thinking through implications | When user says "you are not thinking" - STOP, step back, map everything before continuing |

## User Preferences
- Uses `~/.agent-config` as central distribution hub for all agents (pi-agent, codex, opencode, claude code)
- Prefers symlinks to repo for instant `git pull` updates over native plugin systems
- Wants unified architecture - all agents should get content from same source
- Values "no duplication" as a hard requirement
- Asks probing questions to guide to better solutions rather than giving answers directly

## Patterns That Work
- **Multi-agent symlink architecture**:
  ```
  REPO (source of truth)
  └── plugins/compound-engineering/{skills,commands,agents}
           ↓
  ~/.agent-config (distribution hub)
  ├── skills/compound → repo/skills
  ├── commands/compound → repo/commands  
  └── agents/compound → repo/agents
           ↓
  Each agent symlinks to ~/.agent-config
  ```
- Directory symlinks (not individual file symlinks) - new files automatically appear
- For Claude Code: uninstall native plugin, use symlinks via ~/.agent-config
- For agents: `~/.claude/agents/compound` → `~/.agent-config/agents/compound` (add inside existing directory)

## Patterns That Don't Work
- Individual per-skill symlinks - get stale when new skills are added to repo
- Native plugin + symlinks together - causes duplication
- Modifying installPath without removing cached files - duplicates remain
- Proposing solutions before understanding complete architecture

## Domain Notes
- **Claude Code plugins** provide: skills/, commands/, agents/, CLAUDE.md, .claude-plugin/
- **Plugin locations**: 
  - installed_plugins.json tracks what's installed
  - cache/ contains versioned copies
  - marketplaces/ contains marketplace clones
- **All three must be cleaned** when fully uninstalling a plugin
- Pi-agent uses `prompts/` (not commands/) for slash commands
- OpenCode has both `skill/` and `skills/`, `command/` and `commands/` directories
- Codex uses `prompts/` for commands

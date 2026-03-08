# Napkin

## Corrections
| Date | Source | What Went Wrong | What To Do Instead |
|------|--------|----------------|-------------------|
| 2026-02-10 | User | Proposed solutions without seeing complete architecture - kept stumbling and contradicting myself | Step back, map the COMPLETE picture first (all agents, all paths, all sources) before proposing solutions |
| 2026-02-10 | User | Suggested symlinks that would cause duplication for Claude Code | Ask "will this cause duplicates?" before proposing any symlink architecture |
| 2026-02-10 | User | Hardcoded version number (2.28.0) in symlink path | Use `installed_plugins.json` installPath modification or version-agnostic approaches |
| 2026-02-10 | User | Removed plugin from installed_plugins.json but left cached files | When uninstalling plugins, remove: (1) entry from installed_plugins.json, (2) cache directory, (3) marketplaces directory |
| 2026-02-10 | Self | Kept proposing partial solutions without thinking through implications | When user says "you are not thinking" - STOP, step back, map everything before continuing |
| 2026-02-22 | User | Wording allowed agents to infer bead linkage starts at implementation, not spec creation | State as hard gate: "No bead, no spec", require bead ID in `spec.md` at creation time, and add override in pre-flight checklist |
| 2026-02-26 | User | Agents stopped on unrelated working-tree changes with generic safety pause | Only pause for unexpected changes in files in the active edit scope; unrelated dirty files are non-blocking |
| 2026-02-28 | Self | Non-interactive SSH sessions on mini still resolved Apple `/usr/bin/git` and `/bin/bash` despite `.zshenv` edits | For zsh login SSH sessions, set Homebrew PATH precedence in `~/.zprofile` (path_helper runs later) and re-verify with `command -v` |
| 2026-03-01 | User | Deployed settings.json to Mini via bootstrap but never checked that the 28 hook files it references existed there. Declared "done" after shallow checks (file content match + syntax). Mini sessions broken on every hook. | Never verify a config file in isolation. Always verify its DEPENDENCIES resolve on the target. For settings.json: parse hook paths and confirm each file exists. More broadly: if a tracked config references external files, those files must also be tracked or the setup is incomplete. One clone + one setup = everything works, no exceptions. |
| 2026-03-03 | User | Wrongly claimed Codex has no native skill system; slapped bandaid symlink instead of fixing install.sh | Read the actual docs/source before making claims about tool capabilities. Fix root causes in the canonical scripts, not one-off symlinks. |
| 2026-03-03 | Self | install.sh was creating skills symlink at `~/.codex/skills` but Codex uses `~/.agents/skills` | Codex + Gemini both discover skills from `~/.agents/skills/`, not their own home dirs |
| 2026-03-03 | Self | TOML converter used basic strings (`"""`) which treat `\` as escape chars — broke commands with regex/globs | Use TOML literal strings (`'''`) for prompt field — backslashes are literal |
| 2026-03-03 | Self | sed frontmatter parser matched ALL `---` pairs in a file, not just the first | Use awk with a counter for reliable first-block-only frontmatter extraction |

## Agent Collaboration (Critical)
1. **[2026-03-07] Agents will try subagent, interactive_shell, or bash to spawn collaborators — they MUST be told to use pi_messenger**
   Do instead: Every command with a two-agent gate must include explicit pi_messenger instructions with exact tool call syntax. Agents don't infer the right mechanism — they invent wrong ones. Name the wrong tools explicitly ("do NOT use subagent, interactive_shell, or bash") and give the exact right tool call.
2. **[2026-03-07] "Two participants required" is not specific enough**
   Do instead: Tell the agent: (1) run pi_messenger list, (2) send a message to the named collaborator, (3) wait for reply via steering prompt, (4) if nobody is on the mesh, ask the user to start one. Do not proceed solo.
3. **[2026-03-07] Agents skip workflow gates under forward momentum**
   Do instead: JadeGrove skipped /codex-review and went straight from /plan to /implement. Even the agent that wrote the workflow commands will skip gates when excited about progress. Gates must be enforced structurally, not relied on by memory.
4. **[2026-03-07] Message budget (default 10) is too low for real collaboration**
   Fixed: ~/.pi/agent/pi-messenger.json now has chatty: 100. The spawn/dismiss feature (spec 008) will properly exempt collaborators from budget entirely.

## Prompt & Command Craft (Highest Priority)
1. **[2026-03-07] Over-structuring commands kills agent performance**
   Do instead: Write commands like a person talking — conversational, emotionally weighted, short. No step-by-step headers for exploratory tasks, no output templates, no bash scaffolding for things the agent knows. Keep intensifiers ("super careful", "go deep"), open-ended language ("etc."), and deliberate repetition. Structure is only correct for artifact creation (specific files in specific formats), never for discovery/review.
2. **[2026-03-07] "Use the skill" ≠ the agent actually following the skill**
   Do instead: Point to the literal file path and say "read this file completely and follow it exactly." Name the specific shortcut failure mode. Never rely on the agent self-checking artifact compliance.
3. **[2026-03-07] Forced file reads beat injected context**
   Do instead: When compliance with a file matters (AGENTS.md, SKILL.md, etc.), explicitly instruct the agent to read it via tool call. System prompt content gets wallpaper treatment; tool-call results get high attention.
4. **[2026-03-07] Actually run the skill — don't wing your own version**
   Do instead: When a command says "use the workflows-plan skill" or any skill, READ the actual SKILL.md file and follow its protocol. You will be tempted to skip this because you "know how to do it." That's the exact failure mode. The skill exists because winging it produces shallow results on hard problems.
5. **[2026-03-07] Anchor trust in file existence, not agent words**
   Do instead: Every critical gate (codex review, shaping, bead creation) must produce a file artifact in the spec directory. Verification = `ls specs/*/codex-review.md`. No file = didn't happen. Shaping is never solo (one agent with itself) but CAN be two agents autonomously — save transcript to `shaping-transcript.md`.

6. **[2026-03-07] Two-agent gates enforce skill compliance**
   Do instead: `/shape`, `/plan`, `/codex-review`, and `/implement` all require two participants. The second perspective is what prevents corner-cutting. One agent doing everything then sending to another for review is NOT collaborative — engage the second agent BEFORE writing artifacts.
7. **[2026-03-07] Bead + numbered spec is non-negotiable tracking**
   Do instead: Every piece of tracked work gets a bead and a `specs/NNN-slug/` directory via `/issue`. `/plan` and `/implement` refuse to proceed without them. `/issue` can happen before or after `/shape`, but it MUST happen.
8. **[2026-03-07] Audit log in spec directory**
   Do instead: Every workflow command appends to `log.md` in the spec directory: timestamp, mesh name, harness/model, command, event. `cat specs/*/log.md` is the cross-project activity feed.
9. **[2026-03-07] Adversarial review requires evidence, not opinions**
   Do instead: When reviewing, the anti-rubber-stamp mechanism is concrete verification (counts, diffs, file checks) — not "raise one concern." Requiring concerns produces theater. Requiring evidence produces investigation. The "What I Verified" section must contain specifics from the implementation. Reference case: RedEagle said 9/9 PASS but never diffed flake-skip.conf against the committed version — would have caught 74 suppressed methods. See spec 009.

## User Preferences
- Uses `~/.agent-config` as central distribution hub for all agents (pi-agent, codex, opencode, claude code)
- Prefers symlinks to repo for instant `git pull` updates over native plugin systems
- Wants unified architecture - all agents should get content from same source
- Values "no duplication" as a hard requirement
- Asks probing questions to guide to better solutions rather than giving answers directly
- Wants important generated artifacts (especially `/finalize` outputs in `thoughts/`) committed and tracked, not left uncommitted
- Wants spec directories numbered sequentially with 3-digit IDs (`001-*`, `002-*`, ...) and each spec linked to an associated bead
- Wants dirty-file safety checks to be scoped to files being edited, not unrelated working-tree changes
- Does not want laptop state treated as gospel during parity migrations; use repo-defined standards and clean up laptop drift

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
- For cross-machine setup, capture and diff a symlink/dir matrix between source and target machines before declaring parity
- Use `tools-bin/agent-config-parity` snapshots plus `compare` to validate parity and external-surface/tool-version drift
- Upgrade toolchain on both machines from Homebrew before parity snapshots when strict version sync matters

## Patterns That Don't Work
- Individual per-skill symlinks - get stale when new skills are added to repo
- Native plugin + symlinks together - causes duplication
- Modifying installPath without removing cached files - duplicates remain
- Proposing solutions before understanding complete architecture
- Assuming README install behavior is fully current without checking `install.sh` and `install-all.sh` directly
- Checking config file content matches baseline without verifying what that config DEPENDS ON (e.g., settings.json → hooks). Shallow verification creates false confidence.

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
- In this repo, core architecture is a thin orchestration layer: `install.sh` wires canonical content (`commands/`, `instructions/`, `skills/`) into all agent homes via directory-level symlinks, while `tools-bin/` and `commands/` provide execution surfaces.
- Succeeded: Added shaping skills via ~/.agent-config shared skill root so Claude/Codex/Pi/opencode automatically pick them up.
- Caveat: shaping hook configured only in ~/.claude/settings.json (other agents don't have Claude-style hooks in this environment).
- **Skill discovery paths by agent:**
  - Claude Code: `~/.claude/skills/`
  - Pi: `~/.pi/agent/skills/`
  - Codex + Gemini: `~/.agents/skills/` (shared)
- **Gemini CLI config architecture:**
  - Instructions: `~/.gemini/GEMINI.md` (supports `context.fileName` override in settings.json)
  - Skills: `~/.agents/skills/` (shared with Codex)
  - Commands: `~/.gemini/commands/*.toml` (TOML format, NOT Markdown — requires conversion)
  - Commands use `prompt = '''...'''` (literal strings) and optional `description = "..."`
- **Mini SSH**: `ssh mini-ts` (user `chipcarman`, host `chips-mac-mini`)
- **Mini update procedure**: `ssh mini-ts "cd ~/.agent-config && git pull --ff-only && ./install.sh"`

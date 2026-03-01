#==============================================================================
# Brewfile - Machine-level packages for agent-config
#
# Usage:
#   brew bundle --file=Brewfile --no-lock
#
# Tiered: Required tools are referenced by skills/commands,
# Recommended tools enhance the dev experience.
#==============================================================================

#──────────────────────────────────────────────────────────────────────────────
# Required — tools referenced by agent-config skills/commands
#──────────────────────────────────────────────────────────────────────────────
brew "ripgrep"                   # rg — fast code search (AGENTS.md default)
brew "fd"                        # fd — fast file finder
brew "bat"                       # bat — syntax-highlighted cat
brew "eza"                       # eza — modern ls replacement
brew "jq"                        # jq — JSON processor
brew "trash"                     # trash — Finder-integrated rm alternative
brew "gh"                        # gh — GitHub CLI
brew "tree"                      # tree — directory tree display
brew "tmux"                      # tmux — terminal multiplexer (ntm skill)
brew "glow"                      # glow — terminal markdown renderer
brew "starship"                  # starship — cross-shell prompt
brew "uv"                        # uv — fast Python package manager
brew "yt-dlp"                    # yt-dlp — video/audio downloader
brew "shellcheck"                # shellcheck — shell script linter
brew "zsh-autosuggestions"       # zsh plugin — history-based suggestions
brew "zsh-syntax-highlighting"   # zsh plugin — command syntax coloring
brew "zsh-completions"           # zsh plugin — additional completions

#──────────────────────────────────────────────────────────────────────────────
# Recommended — agent ecosystem and quality-of-life tools
#──────────────────────────────────────────────────────────────────────────────

# Third-party taps
tap "steipete/tap"
tap "oven-sh/bun"

brew "steipete/tap/bird"         # bird — X/Twitter CLI (bird skill)
brew "steipete/tap/peekaboo"     # peekaboo — macOS UI automation (peekaboo skill)
brew "steipete/tap/sag"          # sag — ElevenLabs TTS CLI (sag skill)
brew "oven-sh/bun/bun"           # bun — fast JS runtime + package manager

#──────────────────────────────────────────────────────────────────────────────
# NOT in Brewfile — installed separately via their own methods:
#   claude     — npm install -g @anthropic-ai/claude-code
#   codex      — npm install -g @openai/codex
#   pi         — pip install pi-agent (or similar)
#   openclaw   — curl installer
#   gj         — custom build tool (~/bin/gj)
#──────────────────────────────────────────────────────────────────────────────

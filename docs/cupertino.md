# Cupertino - Apple Documentation MCP Server

**Version:** 0.9.1
**Binary:** `/usr/local/bin/cupertino`
**Database:** `~/.cupertino/search.db` (2.6 GB, 307 frameworks, 302K+ docs)

## Quick Reference

```bash
# Search documentation
cupertino search "query"                    # Basic search
cupertino search "query" --limit 10         # More results
cupertino search "query" --source samples   # Search sample code
cupertino search "query" --min-visionos 1.0 # Filter by platform

# Read full document
cupertino read "apple-docs://framework/page" --format markdown

# Health check
cupertino doctor
```

## Search Sources

| Source | Flag | Contents |
|--------|------|----------|
| Apple Docs | `--source apple-docs` | 302K+ pages, 307 frameworks |
| Samples | `--source samples` | 606 Apple sample projects |
| HIG | `--source hig` | Human Interface Guidelines |
| Swift Evolution | `--source swift-evolution` | ~429 proposals |
| Swift.org | `--source swift-org` | Swift language docs |
| Packages | `--source packages` | 9,699 Swift packages |
| Archive | `--source apple-archive` | Legacy pre-2016 guides |
| All | `--source all` | Search everything |

## Platform Filters

```bash
--min-ios 17.0
--min-macos 14.0
--min-visionos 1.0
--min-tvos 17.0
--min-watchos 10.0
```

## MCP Configuration

### Claude Code
```bash
claude mcp add cupertino --scope user -- /usr/local/bin/cupertino serve
```

### Claude Desktop
`~/Library/Application Support/Claude/claude_desktop_config.json`:
```json
{
  "mcpServers": {
    "cupertino": {
      "command": "/usr/local/bin/cupertino",
      "args": ["serve"]
    }
  }
}
```

### Cursor
`.cursor/mcp.json`:
```json
{
  "mcpServers": {
    "cupertino": {
      "command": "/usr/local/bin/cupertino",
      "args": ["serve"]
    }
  }
}
```

### VS Code (Copilot)
`.vscode/mcp.json`:
```json
{
  "servers": {
    "cupertino": {
      "type": "stdio",
      "command": "/usr/local/bin/cupertino",
      "args": ["serve"]
    }
  }
}
```

### Codex
`~/.codex/config.toml`:
```toml
[mcp_servers.cupertino]
command = "/usr/local/bin/cupertino"
args = ["serve"]
```

### opencode
`opencode.jsonc`:
```json
{
  "mcp": {
    "cupertino": {
      "type": "local",
      "command": ["/usr/local/bin/cupertino", "serve"]
    }
  }
}
```

## MCP Tools

| Tool | Purpose |
|------|---------|
| `search_docs` | Full-text search all documentation |
| `search_hig` | Search Human Interface Guidelines |
| `search_samples` | Search sample code projects |
| `search_symbols` | AST symbol search |
| `search_property_wrappers` | Find @State, @Observable usage |
| `search_concurrency` | Find async/await, actor patterns |
| `search_conformances` | Find types by protocol |
| `list_frameworks` | List available frameworks |
| `list_samples` | List sample projects |
| `read_document` | Read document by URI |
| `read_sample` | Read sample README |
| `read_sample_file` | Read sample source file |

## Common Searches

```bash
# SwiftUI
cupertino search "SwiftUI @State property wrapper"
cupertino search "SwiftUI NavigationStack"

# visionOS / RealityKit
cupertino search "RealityKit ImmersiveSpace" --min-visionos 1.0
cupertino search "visionOS window placement"

# Networking
cupertino search "NWConnection QUIC"
cupertino search "URLSession async await"

# Concurrency
cupertino search "Swift actor isolation"
cupertino search "TaskGroup" --source swift-evolution
```

## ⚠️ CRITICAL: Never Run `cupertino save`

**DO NOT run `cupertino save`** - this rebuilds the database from local markdown files (which you don't have). It destroys the 2.4GB pre-built index.

If database is corrupted (shows 0 frameworks or tiny size):
```bash
cupertino setup --force   # Re-download pre-built databases
```

## Troubleshooting

```bash
# Check installation
which cupertino
cupertino --version
cupertino doctor

# Verify MCP config
cat ~/.claude.json | grep -A5 cupertino

# Re-download databases
cupertino setup --force
```

## Installation

```bash
# One-command install
bash <(curl -sSL https://raw.githubusercontent.com/mihaelamj/cupertino/main/install.sh)

# Or Homebrew
brew tap mihaelamj/tap && brew install cupertino && cupertino setup
```

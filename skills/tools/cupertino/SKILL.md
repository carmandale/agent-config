---
name: cupertino
description: Search Apple Developer Documentation, Swift Evolution, HIG, and sample code via MCP. Use when asked about Apple APIs, frameworks, SwiftUI, UIKit, RealityKit, visionOS, or any Apple platform documentation. 302K+ indexed pages across 307 frameworks.
allowed-tools: Bash, Read
---

# Cupertino - Apple Documentation MCP Server

Search Apple's complete developer documentation locally via MCP. **302,424+ pages across 307 frameworks** with full-text search, platform filtering, and sample code access.

## When to Use

- User asks about Apple APIs or frameworks
- Need accurate documentation for SwiftUI, UIKit, RealityKit, AVFoundation, etc.
- Looking up Swift Evolution proposals
- Finding Apple sample code
- Checking Human Interface Guidelines
- Platform-specific API availability (iOS/macOS/visionOS version requirements)
- Any question where AI hallucination about Apple APIs is a risk

## MCP Tools Available

When the Cupertino MCP server is running, these tools are available:

### Documentation Search

| Tool | Purpose |
|------|---------|
| `search_docs` | Full-text search across all 302K+ pages |
| `search_hig` | Search Human Interface Guidelines |
| `list_frameworks` | List available frameworks with doc counts |
| `read_document` | Read full document content by URI |

### Sample Code Search

| Tool | Purpose |
|------|---------|
| `search_samples` | Search 606 Apple sample code projects |
| `list_samples` | List all indexed sample projects |
| `read_sample` | Read sample project README |
| `read_sample_file` | Read specific source file from sample |

### Semantic Code Search (AST-powered)

| Tool | Purpose |
|------|---------|
| `search_symbols` | Search by symbol type (class, struct, actor, function) |
| `search_property_wrappers` | Find @State, @Observable, @MainActor usage |
| `search_concurrency` | Find async/await, actor, Sendable patterns |
| `search_conformances` | Find types by protocol (View, Codable, etc.) |

## CLI Usage

If MCP tools aren't available, use the CLI directly:

### Search Documentation

```bash
# Basic search
cupertino search "SwiftUI State management"

# Limit results
cupertino search "RealityKit Entity" --limit 10

# Filter by source
cupertino search "async await" --source swift-evolution
cupertino search "button design" --source hig
cupertino search "camera capture" --source samples

# Filter by platform availability
cupertino search "ImmersiveSpace" --min-visionos 1.0
cupertino search "SwiftUI Observable" --min-ios 17.0
cupertino search "Metal" --min-macos 14.0
```

### Source Options

| Source | Description |
|--------|-------------|
| `apple-docs` | Apple Developer Documentation (default) |
| `samples` | Apple sample code projects |
| `hig` | Human Interface Guidelines |
| `swift-evolution` | Swift Evolution proposals |
| `swift-org` | Swift.org documentation |
| `swift-book` | The Swift Programming Language book |
| `packages` | Swift package metadata |
| `apple-archive` | Legacy pre-2016 programming guides |
| `all` | Search all sources |

### Read Full Documents

```bash
# Read by URI (from search results)
cupertino read "apple-docs://swiftui/documentation_swiftui_state"

# Output formats
cupertino read "URI" --format json      # Structured data (default)
cupertino read "URI" --format markdown  # Human-readable
```

### Health Check

```bash
cupertino doctor    # Check server health and database status
cupertino --version # Show version
```

## Common Search Patterns

### SwiftUI

```bash
cupertino search "SwiftUI @State property wrapper"
cupertino search "SwiftUI NavigationStack"
cupertino search "SwiftUI Observable macro" --min-ios 17.0
```

### visionOS / RealityKit

```bash
cupertino search "RealityKit ImmersiveSpace" --min-visionos 1.0
cupertino search "visionOS window placement"
cupertino search "RealityView attachments"
cupertino search "spatial computing hand tracking"
```

### Networking

```bash
cupertino search "URLSession async await"
cupertino search "NWConnection QUIC"
cupertino search "Network framework WebSocket"
```

### Concurrency

```bash
cupertino search "Swift actor isolation"
cupertino search "async let parallel"
cupertino search "TaskGroup" --source swift-evolution
```

### Sample Code

```bash
cupertino search "sample code ARKit" --source samples
cupertino search "RealityKit tutorial" --source samples
```

## URI Patterns

Search results include URIs for reading full content:

| Pattern | Example |
|---------|---------|
| `apple-docs://{framework}/{page}` | `apple-docs://swiftui/documentation_swiftui_view` |
| `swift-evolution://{proposal}` | `swift-evolution://SE-0401` |
| `hig://{category}/{page}` | `hig://ios/buttons` |
| `samples://{project-id}` | `samples://swiftui-tutorial` |

## Database Location

All data stored in `~/.cupertino/`:

| File | Size | Contents |
|------|------|----------|
| `search.db` | ~2.6 GB | Main FTS5 documentation index |
| `samples.db` | ~50 MB | Sample code index |

## ⚠️ CRITICAL: Never Run `cupertino save`

**DO NOT run `cupertino save`** - this rebuilds the database from scratch using only local files (which you don't have). It will destroy the 2.4GB pre-built index and leave you with an empty database.

If the database gets corrupted or shows 0 frameworks:
```bash
cupertino setup --force   # Re-download the pre-built databases
```

## Troubleshooting

### MCP Not Connected

If MCP tools aren't available, the server may not be running or configured:

```bash
# Check if cupertino is installed
which cupertino
cupertino --version

# Test the server
cupertino doctor

# Verify Claude Code MCP config
cat ~/.claude.json | grep -A5 cupertino
```

### Database Missing

```bash
# Re-download databases
cupertino setup --force
```

### Slow Searches

Searches should be <100ms. If slow:
- Ensure database is on local SSD (not network drive)
- Check disk space (`df -h ~/.cupertino`)

## Integration Status

Cupertino is configured as an MCP server for:
- **Claude Code**: `~/.claude.json` (user scope)

To add to other tools:

```bash
# Cursor: .cursor/mcp.json
# VS Code: .vscode/mcp.json  
# Zed: settings.json context_servers
```

## Framework Coverage

Top frameworks by document count:

| Framework | Documents |
|-----------|----------:|
| Kernel | 39,396 |
| Matter | 24,320 |
| Swift | 17,466 |
| AppKit | 12,443 |
| Foundation | 12,423 |
| UIKit | 11,158 |
| Accelerate | 9,114 |
| SwiftUI | 7,062 |
| RealityKit | 3,500+ |
| ARKit | 2,800+ |
| **Total: 307 frameworks** | **302,424** |

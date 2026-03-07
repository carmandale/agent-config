<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Status: REVISED -->
<!-- Revisions: Tier-1 sentinel (unique HTML comment + assistant-role check), Tier-2 cache rewrite + full block reconstruction, cache corruption fallback, hash fallback order, data hygiene (no-secrets + 4KB cap), Tier-3 announcement, risk section -->
---
spec: 007-ground-session-cache
bead: .agent-config-cml
date: 2026-03-07
collaborator: HappyQuartz (Mode 2 autonomous challenger)
codex-review: APPROVED after 3 rounds (gpt-5.3-codex, 2026-03-07)
---

# Plan: /ground Session-Awareness and Tiered Caching — Revision 2 (Codex-Approved)

## Overview

Replace the current unconditional full-grounding `/ground` command with a 3-tier caching system expressed entirely as agent instructions in `commands/ground.md`. No code, no external dependencies — just smarter instructions that let the agent skip redundant work.

## Architecture

The entire implementation is a rewrite of one file: `commands/ground.md`. The agent evaluates tiers top-down and takes the first match.

```
Tier 1: Same-session skip
  Condition: agent previously emitted <!-- ground:complete:v1 --> as final line of a /ground execution
  Action: announce skip, done

Tier 2: Cross-session light ground
  Condition: `.claude/ground-cache` exists AND is parseable AND is fresh
  Action: load cached summary, run delta check, rewrite cache with updated timestamp, done

Tier 3: Full ground (current behavior)
  Condition: no cache, stale cache, malformed cache, or force flag
  Action: announce tier, run all 6 steps as today, write cache, done
```

### Tier 1: Same-Session Detection

The agent checks whether IT (the assistant) previously emitted the sentinel marker `<!-- ground:complete:v1 -->` as the final line of a `/ground` execution in this conversation. The check is: did the agent itself produce a `## Grounded` summary block that ended with the sentinel, in response to a `/ground` invocation? Mentions of the sentinel in user messages, plan documents, specs, or discussion text do NOT count — only agent-authored grounding output.

If found:
1. Announce: "Already grounded this session — skipping"
2. Done. No file I/O.

### Cache File: `.claude/ground-cache`

Location: `.claude/ground-cache` (not repo root — `.claude/` is already agent-managed).

Format: key=value header (not markdown — less fragile to parse), then separator, then summary body.

```
timestamp=2026-03-07T10:25:00Z
head_sha=abc123def456
napkin_hash=sha256:a1b2c3...
handoff_hash=sha256:d4e5f6...
project_readme_hash=sha256:...
project_instructions_hash=sha256:...
global_instructions_hash=sha256:...
---
## Grounded

**Project**: example — one-line purpose
**Architecture**: key architectural pattern
**Key modules**: list of core areas
**Recent focus**: what recent commits suggest
**Active constraints**: non-obvious rules
```

**Data hygiene**: The cached summary must NOT contain secrets, tokens, API keys, or credentials. It is a structural/architectural summary only.

**Size cap**: If the cached summary exceeds 4KB, truncate to 4KB.

### Cache Key: 6 Content Hashes + HEAD

The cache is fresh when ALL match current state:

| Key | What it hashes |
|-----|---------------|
| `head_sha` | `git rev-parse HEAD` |
| `napkin_hash` | `.claude/napkin.md` content |
| `handoff_hash` | `thoughts/shared/handoffs/current.md` content |
| `project_readme_hash` | `./README.md` content |
| `project_instructions_hash` | Sorted concat of `.claude/CLAUDE.md`, repo `AGENTS.md`, `.cursor/rules/*` |
| `global_instructions_hash` | `~/.agent-config/instructions/AGENTS.md` content |

**Deterministic ordering**: Sort all found file paths lexicographically before concatenating for multi-file hash.

**Hash command fallback order**: `sha256sum` → `shasum -a 256` → `openssl dgst -sha256`. Use the first available. If none exists, skip cache entirely and run Tier 3 without writing a cache file.

**Missing files**: Use literal string `MISSING` as hash value.

**Working-tree coverage**: Hashes are computed on actual file content on disk, not committed versions. Uncommitted edits to files `/ground` reads are automatically detected. For codebase structural changes, HEAD is the proxy; `force` flag covers edge cases.

### Cache Corruption / Parse Failure

If `.claude/ground-cache` exists but:
- Is missing any required key
- Has no `---` separator
- Has an empty summary section below the separator
- Summary is missing any required `## Grounded` fields (Project, Architecture, Key modules, Recent focus, Active constraints)
- Cannot be read (permission error, binary content, etc.)

Then **ignore the cache entirely** and run Tier 3. The Tier 3 cache write overwrites the malformed file.

### Atomic Cache Writes

Write to `.claude/ground-cache.tmp`, then `mv` to `.claude/ground-cache`. Same directory = atomic on same filesystem.

### Force Flag

If `$ARGUMENTS` contains the literal word `force`, skip directly to Tier 3.

### Tier 2: Delta Check (Light Ground)

When cache is fresh AND parseable:
1. Load cached `## Grounded` summary from below the `---` separator
2. Run `git log --oneline -5` (activity since last ground)
3. Run `git status --short` (uncommitted work)
4. Check for new handoff files
5. **Reconstruct the full `## Grounded` block** — all required fields (Project, Architecture, Key modules, Recent focus, Active constraints) with cached values, plus a `**Delta since last ground**` section with fresh git log/status/handoff info.
6. **Rewrite the cache file** with updated timestamp, same hash keys, and reconstructed summary. Atomic tmp+mv.
7. Emit the sentinel `<!-- ground:complete:v1 -->` at the end.
8. Announce: "Light ground (cache hit, checking delta)"

### Tier 3: Full Ground

Announce: "Full ground (no cache / stale cache / force override)"

All 6 original steps execute exactly as today. After the `## Grounded` summary is emitted:
1. Compute all 6 content hashes + HEAD SHA
2. Write the cache file via atomic tmp+mv
3. Emit the sentinel `<!-- ground:complete:v1 -->` at the end

### What Stays Unchanged

- Tier 3 identical to today's grounding steps
- Forced AGENTS.md re-read via tool call preserved in Tier 3 (napkin rule #3)
- `## Grounded` summary format and required fields unchanged
- `$ARGUMENTS` passthrough (with `force` intercepted)
- Cross-agent compatibility (Pi, Claude Code, Codex, Gemini)

### Risk

**Low overall, with managed side effects.**

- **Cache writes**: `.claude/ground-cache` created/modified. Mitigated by: atomic writes, .gitignore, data hygiene, corruption fallback.
- **Stale cache**: Could mislead orientation. Mitigated by: 6-hash freshness check + `force` flag.
- **Worst case**: Agent can't parse cache or no hash command → Tier 3 (today's behavior). No degradation.

## Design Decisions

1. **Unique sentinel over heading match** — `<!-- ground:complete:v1 -->` + assistant-role check eliminates false positives
2. **Cache in `.claude/`** — already agent-managed, no .gitignore ownership questions
3. **key=value not markdown** — deterministic parsing, explicit corruption fallback
4. **6 hashes** — covers all files `/ground` reads
5. **Sorted concat** — prevents filesystem-dependent ordering from causing false busts
6. **Hash fallback order** — `sha256sum` → `shasum -a 256` → `openssl dgst -sha256` → skip cache
7. **Content hashes on disk** — dirty instruction files automatically bust cache
8. **`current.md` only** — matches what `/ground` actually reads
9. **Atomic tmp+mv** — prevents concurrent session races
10. **`force` literal word** — simple, discoverable
11. **Tier-2 reconstructs full block** — identical output quality to Tier 3
12. **Tier-2 rewrites cache** — satisfies "written after every full or light ground"
13. **4KB summary cap** — prevents bloat
14. **No secrets in summary** — data hygiene for persistent file
15. **All tiers announce** — R5 transparency fully satisfied

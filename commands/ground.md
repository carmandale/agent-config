---
description: Ground yourself in this project - deeply read instructions and investigate the codebase before doing anything else
---

Before doing any work, fully orient yourself in this project. This is not optional and must not be skimmed.

But first — check whether grounding is even necessary.

**Force override**: If `$ARGUMENTS` contains the literal word `force`, skip directly to Tier 3. Do not evaluate Tier 1 or Tier 2.

Otherwise, evaluate the three tiers below **in order** and take the first match.

---

## Tier 1: Same-Session Skip

Check your own conversation history: did **you** (the assistant) previously produce a `## Grounded` summary block that ended with the marker `<!-- ground:complete:v1 -->`, in response to a `/ground` invocation in this conversation?

**Only your own grounding output counts.** The marker appearing in user messages, plan documents, specs, code, or discussion text does NOT satisfy this check. You are looking for: you ran `/ground` earlier in this conversation, you emitted the full grounding summary, and it ended with the sentinel.

If yes:
1. Say: **"Already grounded this session — skipping."**
2. Stop here. You're done.

If no — continue to Tier 2.

---

## Tier 2: Cross-Session Light Ground

Check whether a cache file exists at `.claude/ground-cache`.

### 2a. Read and validate the cache

Read `.claude/ground-cache`. It must have this format — a key=value header, a `---` separator on its own line, and a summary body below:

```
timestamp=...
head_sha=...
napkin_hash=...
handoff_hash=...
project_readme_hash=...
project_instructions_hash=...
global_instructions_hash=...
---
## Grounded
...
```

**Validation rules — if ANY fail, skip to Tier 3:**
- All 7 keys above must be present in the header
- There must be a `---` separator line
- The summary below the separator must not be empty
- The summary must contain all 5 required fields: **Project**, **Architecture**, **Key modules**, **Recent focus**, **Active constraints**
- If the file can't be read (missing, permissions, binary), skip to Tier 3

### 2b. Compute current content hashes and compare

Compute a SHA-256 hash for each of these. Use the first available hash command in this order: `sha256sum`, then `shasum -a 256`, then `openssl dgst -sha256`. If none is available, skip to Tier 3 without writing a cache.

| Cache key | What to hash |
|-----------|-------------|
| `head_sha` | Output of `git rev-parse HEAD` (compare directly, no hashing needed) |
| `napkin_hash` | Content of `.claude/napkin.md` |
| `handoff_hash` | Content of `thoughts/shared/handoffs/current.md` |
| `project_readme_hash` | Content of `./README.md` |
| `project_instructions_hash` | Concatenated content of all project instruction files: `.claude/CLAUDE.md`, repo-root `AGENTS.md`, and all files matching `.cursor/rules/*`. **Sort all found file paths lexicographically before concatenating.** This prevents filesystem-dependent glob ordering from producing different hashes on different platforms. |
| `global_instructions_hash` | Content of `~/.agent-config/instructions/AGENTS.md` |

**If a file doesn't exist**, use the literal string `MISSING` as its hash value. This is stable — the same missing file always produces the same "hash," and creating the file later will trigger a cache bust.

Compare each computed value against the cached value. **If ALL match** — the cache is fresh. Continue to 2c.

**If ANY differ** — the cache is stale. Skip to Tier 3.

### 2c. Light ground with delta check

The cache is fresh. Do a quick delta check to catch what's happened since the last grounding:

1. Run `git log --oneline -5` to see recent commits
2. Run `git status --short` to see uncommitted work
3. Check for new or changed handoff files in `thoughts/shared/handoffs/`

Now **reconstruct the full `## Grounded` block**. Do NOT just append delta notes to the cached text. Produce the complete summary with all 5 required fields using the cached values, then add a `**Delta since last ground**` section with the fresh git log, git status, and any handoff changes.

The output quality must be identical to a full ground — same fields, same structure, same level of detail. If you can't reconstruct a complete summary from the cache (e.g., cached summary is truncated or fields are garbled), abandon Tier 2 and fall through to Tier 3.

### 2d. Rewrite the cache and finish

After producing the summary, rewrite the cache file with the updated timestamp and reconstructed summary:

1. Write to `.claude/ground-cache.tmp` with the current timestamp, same hash key values, `---` separator, and the reconstructed summary (max 4KB, no secrets/tokens/API keys)
2. `mv .claude/ground-cache.tmp .claude/ground-cache` (atomic — same directory, same filesystem)

Say: **"Light ground (cache hit, checking delta)."**

Output the reconstructed `## Grounded` block, then emit the sentinel on its own line at the very end:

`<!-- ground:complete:v1 -->`

Stop here. You're done.

---

## Tier 3: Full Ground

If you reach this tier — because there's no cache, the cache is stale, the cache is malformed, no hash command is available, or the force override triggered — run the full grounding process.

Say: **"Full ground (no cache / stale cache / force override)."**

### Step 1: Read Global Instructions

Read the ENTIRE `~/.agent-config/instructions/AGENTS.md` file carefully. Do not skim. Internalize the non-negotiables, workflows, and guardrails. They apply to everything you do in this session.

### Step 2: Read Project README

Read the repo's `./README.md` (or equivalent top-level documentation) end to end. Understand:
- What this project is and why it exists
- How it's structured
- Key concepts and terminology

### Step 3: Read Project-Level Agent Instructions

Check for and read any project-specific instruction files:
- `.claude/CLAUDE.md`
- `AGENTS.md` (in repo root)
- `.cursor/rules/`
- Any other agent configuration in the repo

### Step 4: Investigate the Codebase

Use your code investigation capabilities to build a real understanding of the technical architecture:

1. **Map the structure** — directory layout, key entry points, module boundaries
2. **Identify the core abstractions** — what are the main types, protocols, services?
3. **Understand the data flow** — how does information move through the system?
4. **Note the conventions** — naming patterns, error handling, testing approach
5. **Check recent activity** — `git log --oneline -15` to see what's been happening

### Step 5: Read Napkin & Handoffs

```bash
cat .claude/napkin.md 2>/dev/null || echo "No napkin found"
ls thoughts/shared/handoffs/ 2>/dev/null && cat thoughts/shared/handoffs/current.md 2>/dev/null || echo "No handoffs found"
```

### Step 6: Confirm Grounding

Once complete, output a brief grounding summary:

```markdown
## Grounded

**Project**: [name] — [one-line purpose]
**Architecture**: [key architectural pattern in 1-2 sentences]
**Key modules**: [list 3-5 core areas]
**Recent focus**: [what recent commits suggest is active work]
**Active constraints**: [any non-obvious rules from AGENTS.md or project config that are especially relevant here]
```

### Step 7: Write Cache and Finish

After producing the `## Grounded` summary:

1. If the `.claude/` directory doesn't exist, create it: `mkdir -p .claude`
2. Compute all 6 content hashes + HEAD SHA using the hash command fallback order described in Tier 2b
3. Write to `.claude/ground-cache.tmp`:
   ```
   timestamp=[current ISO 8601 timestamp]
   head_sha=[HEAD SHA]
   napkin_hash=[hash or MISSING]
   handoff_hash=[hash or MISSING]
   project_readme_hash=[hash or MISSING]
   project_instructions_hash=[hash or MISSING]
   global_instructions_hash=[hash or MISSING]
   ---
   [your ## Grounded summary — max 4KB, no secrets/tokens/API keys]
   ```
4. `mv .claude/ground-cache.tmp .claude/ground-cache`

Emit the sentinel on its own line at the very end:

`<!-- ground:complete:v1 -->`

Then ask: "What are we working on?" For new work, you'd typically start with `/shape` to explore the problem or `/issue` to create a tracked spec. For bug hunting, try `/sweep`. For reviewing agent-written code, try `/audit-agents`.

$ARGUMENTS

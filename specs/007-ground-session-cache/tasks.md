<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Status: RECONCILED — tasks updated to match Codex-revised plan -->
---
spec: 007-ground-session-cache
bead: .agent-config-cml
date: 2026-03-07
---

# Tasks: /ground Session-Awareness and Tiered Caching

## Phase 1: Rewrite ground.md

- [x] **Task 1.1**: Write the new `commands/ground.md` with 3-tier caching logic
  - Preserve existing frontmatter (description field)
  - **Tier 1**: Check for agent-authored `<!-- ground:complete:v1 -->` sentinel in conversation (NOT any mention — only assistant-role grounding output). Announce skip.
  - **Tier 2**: Read `.claude/ground-cache`, validate format (all required keys, separator, non-empty summary with all 5 Grounded fields). Compute 6 hashes + HEAD. Compare. If fresh: load summary, run delta (git log -5, git status, handoffs), reconstruct full `## Grounded` block with delta section, rewrite cache (atomic tmp+mv), emit sentinel, announce light ground.
  - **Tier 3**: Announce "Full ground". Run all 6 original steps unchanged. After `## Grounded` summary: compute hashes, write cache (atomic tmp+mv), emit sentinel.
  - **Force flag**: If `$ARGUMENTS` contains literal `force`, skip to Tier 3.
  - **Cache format**: key=value header + `---` separator + summary body. Location: `.claude/ground-cache`.
  - **Hash fallback order**: `sha256sum` → `shasum -a 256` → `openssl dgst -sha256` → skip cache, run Tier 3 without write.
  - **Missing files**: Use `MISSING` as hash value.
  - **Deterministic sort**: Sort file paths lexicographically before concat for multi-file hash.
  - **Data hygiene**: No secrets in cached summary. 4KB summary cap.
  - **Corruption fallback**: Missing keys, no separator, empty summary, missing Grounded fields, read errors → ignore cache, run Tier 3.
  - **Atomic writes**: `.claude/ground-cache.tmp` then `mv` to `.claude/ground-cache`.

- [x] **Task 1.2**: Add `.claude/ground-cache` and `.claude/ground-cache.tmp` to `.gitignore`
  - Cache is per-machine state — must not be committed

## Phase 2: Validate via /codex-review (DONE)

- [x] **Task 2.1**: Codex review of plan — APPROVED after 3 rounds
  - Round 1: 8 findings (sentinel, cache rewrite, quality, working-tree, corruption, hygiene, portability, risk)
  - Round 2: 2 findings (sentinel false-positive tightening, Tier-3 announcement)
  - Round 3: Approved — all requirements covered

## Phase 3: Test

- [x] **Task 3.1**: Manual test — full ground (no cache) ✅ 2026-03-09
  - Run `/ground` in a fresh session with no `.claude/ground-cache`
  - Verify all 6 steps execute and "Full ground" announced
  - Verify `.claude/ground-cache` written with correct key=value format
  - Verify `## Grounded` summary and sentinel emitted
  - **Result**: Tested on GMP repo (pi v0.57.1, claude-opus-4-6). All 6 steps executed in order. Tier 3 announced correctly. Cache written with all 7 keys, separator, and complete summary. Sentinel emitted. Context usage 35.9% vs 56.8% on original (−37% on worst-case tier). Summary quality maintained with all 5 required fields.

- [ ] **Task 3.2**: Manual test — same-session skip (Tier 1)
  - Run `/ground` again in the same session
  - Verify "Already grounded this session — skipping" appears
  - Verify no file reads occur

- [ ] **Task 3.3**: Manual test — light ground (Tier 2)
  - Start a new session (clear conversation)
  - Run `/ground` — should detect fresh cache
  - Verify cached summary loaded, delta check runs
  - Verify full `## Grounded` block reconstructed (not just appended)
  - Verify cache rewritten with updated timestamp
  - Verify "Light ground" announced

- [ ] **Task 3.4**: Manual test — cache bust
  - Make a commit (HEAD changes)
  - Run `/ground` in new session
  - Verify "Full ground" runs (cache stale)
  - Verify new cache written

- [ ] **Task 3.5**: Manual test — force flag
  - With fresh cache, run `/ground force`
  - Verify "Full ground" runs despite valid cache

- [ ] **Task 3.6**: Manual test — malformed cache
  - Corrupt `.claude/ground-cache` (remove separator or a key)
  - Run `/ground` in new session
  - Verify falls through to "Full ground" and rewrites cache

## Phase 4: Close

- [x] **Task 4.1**: Commit all changes (002c87be, aa8de0ac)
- [x] **Task 4.2**: Update log.md with implementation record
- [ ] **Task 4.3**: Close bead `.agent-config-cml`

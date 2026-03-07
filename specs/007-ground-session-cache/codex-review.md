<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-07 -->
<!-- Session ID: 019cc92f-97d5-7222-b1ee-bf01138dc5ac -->

# Codex Review: 007-ground-session-cache

## Round 1 — VERDICT: REVISE

8 findings (1 critical, 3 high, 3 medium, 1 low):

1. **Critical: Tier-1 skip condition too brittle.** `## Grounded` heading can appear in user text/docs. Action: Use unique sentinel `<!-- ground:complete:v1 -->`.

2. **High: Tier-2 missing cache rewrite.** Spec requires "cache written after every full or light ground" but Tier-2 flow had no write step. Action: Add explicit cache rewrite in Tier-2 with atomic tmp+mv.

3. **High: "Identical quality regardless tier" under-specified.** Tier-2 said "append delta to cached summary" — vague. Action: Define strict output template reconstructing full `## Grounded` block; force Tier-3 if required fields missing in cache.

4. **High: Freshness check misses working-tree state.** Cache key doesn't include uncommitted changes. Action: Addressed by noting file content hashes are on-disk (catch dirty files); HEAD proxies for structural changes; `force` flag covers edge cases.

5. **Medium: Cache corruption/parse-failure path unspecified.** Action: Add rule — missing keys, malformed separator, empty summary, or read errors → ignore cache, run Tier-3.

6. **Medium: Security and data-hygiene controls missing.** Cache stores grounding summary that may include sensitive content. Action: Add no-secrets rule, 4KB summary cap, ensure .gitignore.

7. **Medium: Cross-agent portability not fully operationalized.** "Pick whichever SHA-256 command" lacks fallback order. Action: Add deterministic order: `sha256sum` → `shasum -a 256` → `openssl dgst -sha256` → skip cache.

8. **Low: Risk section understates side effects.** "No side effects" incorrect — cache writes are side effects. Action: Update risk section with managed side effects and mitigations.

**Solid points acknowledged:** Tiered structure maps cleanly to R1-R5; atomic write via same-directory tmp+mv is good; `MISSING` sentinel for absent files is clean.

## Round 2 — VERDICT: REVISE

2 remaining findings (down from 8):

1. **High: Tier-1 still has false-positive path.** The sentinel `<!-- ground:complete:v1 -->` appears in plan/review text itself, so "exists anywhere in conversation" is still too loose. Action: Tighten to "the sentinel was emitted by the agent (assistant role) as the final line of a /ground execution."

2. **Medium: R5 transparency not mandated for Tier-3.** Tier-1 and Tier-2 have explicit announce strings but Tier-3 does not. Action: Add explicit Tier-3 announcement.

**Everything else confirmed solid.**

## Round 3 — VERDICT: APPROVED

> No blocking findings. The revised plan now covers all stated requirements (R1–R5), closes the prior correctness gaps on Tier-1 detection and Tier-3 transparency, and includes concrete mitigations for corruption, cache hygiene, and fallback behavior.
>
> Residual implementation risk is mostly execution drift when rewriting `commands/ground.md` (for example, if the final command text follows the short architecture snippet instead of the stricter Tier-1 rules), so implementation should copy the detailed Tier sections verbatim.

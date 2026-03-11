# Codex Review: 014 — Parity Tool Drift

**Session ID**: `019cda28-f255-7802-a3c6-9b48c861c4a5`
**Model**: gpt-5.3-codex
**Verdict**: ✅ APPROVED after 2 rounds
**Date**: 2026-03-10

---

## Round 1 — VERDICT: REVISE

### Findings (Ordered by Severity)

1. **High: The plan does not remove the stated root cause; it accepts continued drift risk.**
   The spec says the root cause is independent path lists with no coupling. The plan explicitly chooses manual sync over structural coupling. Repo evidence shows this drift surface is already real across multiple lists: parity tool, installer, bootstrap checks, and README maps. Action: add an automated coupling guard (best: extend the existing parity test) instead of comment-only coupling.

2. **High: Verification plan is not sufficient for a cross-machine parity tool.**
   Planned verification is local-only snapshot/report plus bootstrap check; it never requires a two-machine `compare` proof or a negative test (intentionally broken symlink should be detected). Given the tool's purpose is laptop↔mini comparison, this is a correctness gap.

3. **Medium: Managed key renames are a schema change, but no compatibility/versioning step is planned.**
   Plan renames managed keys (`pi_commands`→`pi_prompts`, etc.). Tool snapshot schema version stays fixed at `1`. Existing artifacts already encode old key names. Action: bump schema version or provide temporary alias keys/migration note.

4. **Medium: Plan/source path references are partially inaccurate and skip known adjacent drift.**
   README still documents `~/.pi/agent/skills` as managed while install explicitly says not to create it. Action: include README sync in scope or explicitly mark as deferred.

5. **Low (Security/Bypass): Extension hardening is underspecified.**
   Current normalization can miss edge forms (e.g. `@~/...`) because it strips `@` after testing for `~/`. Plan only mentions replacing hardcoded home path, not canonicalization order/resolve behavior. Action: canonicalize in strict order (`@` strip → `~` expand → resolve/realpath).

### Adversarial Gate

**3 riskiest assumptions:**
1. "bootstrap/install are already aligned" — **Verified** against source
2. "Manual sync risk is low enough; comments are sufficient" — **Not verified** (source suggests opposite — existing `test-symlink-parity.sh` should be extended)
3. "`os.homedir()` conversion fully solves extension behavior on mini" — **Partially verified** (mini path layout not directly verifiable from source)

---

## Round 2 — VERDICT: APPROVED

Codex verified all 5 revisions against source code:
- Structural coupling is now test-enforced: adding parity-tool extraction to `tests/test-symlink-parity.sh` is the right root-cause fix direction
- Managed-path corrections align with install.sh and bootstrap.sh reality
- Snapshot schema bump to `2` is the correct compatibility signal for key renames
- README drift fix is explicitly in scope
- Extension normalization order is materially better for bypass resistance

No remaining blocking issues. Non-blocking future enhancement: add a two-machine `snapshot + compare` smoke check in rollout evidence.

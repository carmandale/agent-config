---
shaping: true
---

# 010 — Beads Backend Evaluation: Shaping

**Participants:** OakJaguar (pi/claude-sonnet-4, proposer) × GoldRaven (pi/claude-sonnet-4-6, challenger)
**Date:** 2026-03-09
**Bead:** .agent-config-17q

---

## Shape B Elimination

Shape B (bd v0.59.0+ with Dolt) is eliminated before the fit check by hard evidence:

- **Open bug [#2433](https://github.com/steveyegge/beads/issues/2433):** `bd init --from-jsonl` fails on fresh clones — our exact multi-machine scenario
- **Closed bug [#2251](https://github.com/steveyegge/beads/issues/2251):** Dolt migration in one clone causes data loss in other clones — our laptop+mini topology
- **Daemon requirement:** `dolt sql-server` must run as a process — operational overhead we reject
- **SQLite removed entirely** in v0.59.0 — no fallback to current architecture

---

## Requirements (R)

Negotiated through 5 rounds of challenge/revise between OakJaguar and GoldRaven.

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | If migration is required, existing issues and JSONL history transfer without data loss or manual transformation | Must-have |
| R1 | Tool covers our operational behavior surface | Must-have |
| R1.1 | Create issues with random hash IDs | Must-have |
| R1.2 | List and filter issues by status, priority | Must-have |
| R1.3 | Update issue status (open → in_progress → closed) | Must-have |
| R1.4 | Close with reason text | Must-have |
| R1.5 | Export DB → JSONL for git commit (explicit, never auto-commits) | Must-have |
| R1.6 | Import JSONL → DB after git pull | Must-have |
| R1.7 | Detect and surface data drift, corruption, or stale state | Must-have |
| R2 | Tool receives platform fixes from upstream, OR codebase is under 50K lines, read-and-patch readable, with permissive license for critical patches | Must-have |
| R3 | Pre-built binaries available for macOS arm64 | Must-have |
| R4 | Concurrent updates to the same issue from different clones produce a recoverable state, not silent data loss | Must-have |

**R2 note:** Our Rust capability is read-and-patch, not develop. Self-patch covers platform breakage (build failures, path changes), not architectural bugs. br's MIT license and 699-star community provide fallback that bd's 276K Go + Dolt dependency does not.

### Key Challenges That Shaped R

1. **R0 was originally redundant** (GoldRaven) — "works reliably without data loss" was split across R1+R3 already. Eliminated, renumbered.
2. **R3 (behavior surface) was a blob** (GoldRaven) — 7 behaviors in one cell makes the fit check unjudgeable. Split into R1.1–R1.7.
3. **R4/R5 (maintenance) had tautological OR logic** (GoldRaven) — "actively developed OR small enough to fork" is trivially true for any abandoned 20K-line project. Restated with a falsifiable 50K-line threshold and honest self-patch capability assessment.
4. **Bus factor risk was concealed** (GoldRaven) — br's single maintainer + no outside PRs is a real risk. Addressed in R2 note rather than hidden behind "24 releases."
5. **Concurrent same-issue updates were unaddressed** (GoldRaven) — R4 added to cover the two-machine divergent-update scenario.
6. **B-eliminator requirements cluttered the fit check** (GoldRaven) — R0/R1/R2 (old numbering) were vestigial once B was eliminated. Moved to a separate section.
7. **R1.4 and R0 were assumed, not verified** (GoldRaven) — Spiked both: br source confirms `close_reason: Option<String>` and serde field-level compatibility with our JSONL.

---

## Shape A: Stay pinned on bd v0.50.3

| Part | Mechanism |
|------|-----------|
| A1 | Keep current bd binary (v0.50.3) at ~/.local/bin/bd |
| A2 | Pin version by not running install/upgrade scripts |
| A3 | Continue using existing .beads/ directory, SQLite DB, JSONL export unchanged |
| A4 | No upstream SQLite fixes or features (upstream moved to Dolt-only in v0.59.0) |

## Shape C: Migrate to br (beads_rust)

| Part | Mechanism |
|------|-----------|
| C1 | Install br via curl install script (pre-built darwin_arm64 binary) |
| C2 | Initialize br in .beads/: `br init`, then `br sync --import-only` to read existing JSONL |
| C3 | Update AGENTS.md §6 to reference `br` instead of `bd` |
| C4 | Update napkin and workflow commands (bd → br) |
| C5 | Test on laptop first, then repeat on mini |
| C6 | Keep bd 0.50.3 binary as fallback during transition (commands don't collide — `br` vs `bd`) |

---

## Fit Check: A vs C

| Req | Requirement | Status | A | C |
|-----|-------------|--------|---|---|
| R0 | If migration required, JSONL transfers without data loss or manual transformation | Must-have | ✅ | ✅ |
| R1 | Tool covers our operational behavior surface | Must-have | ✅ | ✅ |
| R1.1 | Create issues with random hash IDs | Must-have | ✅ | ✅ |
| R1.2 | List and filter by status, priority | Must-have | ✅ | ✅ |
| R1.3 | Update issue status | Must-have | ✅ | ✅ |
| R1.4 | Close with reason text | Must-have | ✅ | ✅ |
| R1.5 | Export DB → JSONL (explicit, no auto-commit) | Must-have | ✅ | ✅ |
| R1.6 | Import JSONL → DB after pull | Must-have | ✅ | ✅ |
| R1.7 | Detect and surface data drift, corruption, stale state | Must-have | ✅ | ✅ |
| R2 | Platform fixes from upstream OR self-patchable codebase | Must-have | ❌ | ✅ |
| R3 | Pre-built macOS arm64 binaries | Must-have | ✅ | ✅ |
| R4 | Concurrent same-issue updates produce recoverable state | Must-have | ✅ | ✅ |

### Notes

- **R0 A:** No migration needed — passes trivially.
- **R0 C:** Schema-level compatibility verified via source code. All our JSONL fields (id, title, description, status, priority, issue_type, owner, created_at, created_by, updated_at) exist in br's Issue struct with matching names and types. Priority serializes as bare integer via `#[serde(transparent)]`, matching our JSONL format. Extra br fields use `serde(default)` — they default to None when absent. Empirical import test deferred to first-machine implementation.
- **R1.4 C:** `br close <id> --reason "text"` confirmed in source code (`CloseArgs.reason: Option<String>`) and README examples.
- **R1.7 C:** `br doctor` checks: merge artifacts, sync path validation, conflict markers, JSONL parsing, schema table/column integrity, SQLite integrity_check, DB-vs-JSONL count mismatch, sync metadata. (Spike: examined `src/cli/commands/doctor.rs` and test baseline.)
- **R2 A: FAILS** — Upstream (Yegge) dropped SQLite in v0.59.0. No new arm64 binaries for SQLite-based bd will ship. The 276K Go + Dolt codebase is not self-patchable at our skill level. If macOS breaks the v0.50.3 binary, no remediation path exists.
- **R2 C:** br ships arm64 binaries regularly (24 releases, v0.1.24 confirmed darwin_arm64). If upstream stops, 20K Rust + MIT license is within read-and-patch range for platform breakage.
- **R3 A:** Passes trivially (binary already installed). But no future binaries will come — this is R2's concern.
- **R4 A:** bd has built-in LWW merge via `bd sync --resolve` with ours/theirs/manual strategies.
- **R4 C:** br relies on git's line-based JSONL merge + manual conflict resolution + `br sync --import-only`. `br doctor` detects conflict markers, so bad state is caught rather than silently consumed. Both approaches produce recoverable state.

---

## Selected Shape: C — Migrate to br (beads_rust)

### Rationale

R2 is the sole discriminator. Shape A fails it — staying on a dead-end binary with no remediation path is a time bomb that grows riskier with every macOS update. Shape C passes it with evidence: actively maintained, pre-built binaries, and a codebase small enough to fork if needed.

The switching cost is low:
- Same JSONL format (schema-level compatibility verified)
- Commands don't collide (`br` vs `bd`) — both can coexist during transition
- Same .beads/ directory structure
- Test one machine at a time

The risk of NOT switching grows monotonically. The risk of switching is bounded and front-loaded (one-time import verification).

### Priority field verification

Our JSONL stores priority as bare integers (e.g., `"priority": 2`). br's `Priority` type uses `#[serde(transparent)]` wrapping `i32`, serializing identically. Confirmed: no type mismatch risk.

---

## What's Next

Shaping is done. Shape C selected, fit check passes, both participants agree.

Next step: user runs `/issue` to create the bead and spec built on this foundation, then `/plan` to break Shape C into implementation tasks.

# Shaping Transcript — 019 Command Compliance Gates

**Date:** 2026-03-12
**Participants:** IronQuartz (pi/claude-sonnet-4-thinking, driver) + user + RedGrove (crew-challenger)
**Outcome:** Shape D selected (scripts + structured command headers + layered enforcement)

---

## Phase 1: Requirements (IronQuartz + User)

Initial R0-R8 proposed by IronQuartz, negotiated with user.

Key evolution: R7 originally said "works within markdown command templates — no runtime code." User shared tweet from @jordymaui arguing "code is deterministic, language isn't — a 10-line python file that checks output beats a paragraph of instructions." User agreed: "we have to have scripts that protect the agents from themselves." R7 flipped to "gate enforcement is deterministic code (scripts), not prose." R9 added as consequence (validation logic centralized).

Final requirements after shaping (R0-R10):

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | Agents cannot proceed without verified prior-stage artifacts | Core goal |
| R1 | Each command declares artifact ownership | Must-have |
| R2 | Downstream commands verify provenance via sentinels | Must-have |
| R3 | Pre-flight checks structured and at top of command | Must-have |
| R4 | Pipeline state recorded as append-only trail | Must-have |
| R5 | Existing workflow semantics unchanged | Must-have |
| R6 | Existing specs remain implementable | Must-have |
| R7 | Gate enforcement is deterministic code, not prose | Must-have |
| R8 | Commands prohibit creating artifacts owned by other commands | Must-have |
| R9 | Validation logic lives in one place | Must-have |
| R10 | Gate failure = full stop with HARD CONSTRAINT block | Must-have |

## Phase 2: Shapes (IronQuartz)

Four shapes explored:

### A: Central gate script
One script (`scripts/gate.sh`) that every command calls. Knows all prerequisites. Agent's only job: "run this, stop if it fails."

### B: Workflow state machine
Richer abstraction — a script managing pipeline state as explicit transitions. Commands ask the state machine "can I run?"

### C: Hook-based automatic enforcement
Agent harness hooks intercept commands before delivery. Agent can't opt out. Two flagged unknowns: post-command completion detection (⚠️), cross-fleet hook support (⚠️).

### D: Scripts + structured command headers (SELECTED)
Hybrid — scripts handle deterministic gate checks, commands get structured frontmatter keys that the agent reads and the script validates.

## Phase 3: Fit Check (IronQuartz)

| Req | A | B | C | D |
|-----|---|---|---|---|
| R0 | ✅ | ✅ | ✅ | ✅ |
| R1 | ❌ | ❌ | ❌ | ✅ |
| R2 | ✅ | ✅ | ✅ | ✅ |
| R3 | ❌ | ❌ | ✅ | ✅ |
| R4 | ✅ | ✅ | ✅ | ✅ |
| R5 | ✅ | ✅ | ✅ | ✅ |
| R6 | ✅ | ✅ | ✅ | ✅ |
| R7 | ✅ | ✅ | ✅ | ✅ |
| R8 | ❌ | ❌ | ❌ | ✅ |
| R9 | ✅ | ✅ | ✅ | ✅* |

*R9 initially failed for D (YAML block + script = two sources), fixed by having gate.sh read the command's frontmatter directly.

A/B failed R1, R3, R8: ownership and pre-flight rules invisible to agents.
C failed R1, R8 + had two flagged unknowns (cross-fleet hooks, completion detection).
D was the only shape satisfying all requirements after the R9 fix.

## Phase 4: Adversarial Challenge (RedGrove)

RedGrove raised four challenges:

### FATAL #1: Scope contradiction (RESOLVED)
Spec said "wrapper scripts out of scope" but Shape D is entirely scripts. Resolution: amend spec scope with documented rationale (R7 changed, scope must follow).

### FATAL #2: gate.sh invocation is voluntary (RESOLVED)
"Run gate.sh which checks for X" vs. "check for X" — same decision point. Resolution: layered enforcement:
- Layer 1: gate.sh (works everywhere, observably present/absent)
- Layer 2: hooks on pi/Claude Code (structural, agent can't opt out)
- Layer 3: sentinel verification at next stage (self-healing)
Plus R10: HARD CONSTRAINT block naming the exact rationalization to prevent.

### HARD #3: YAML-in-markdown parsing fragility (RESOLVED)
Nested YAML in markdown with bash code blocks is fragile. Resolution: flat `gate_*` keys in standard YAML frontmatter. `grep + cut + tr + xargs` parsing. No nested structures, no yq dependency.

### HARD #4: Sentinel forgery under momentum (ACCEPTED LIMITATION)
Sentinels are self-attestation — a motivated agent will forge them. Resolution: script-written sentinels (agent calls `gate.sh record`, script writes the sentinel) + layered verification (sentinel + state trail + log.md + git history). Forgery requires coordinated multi-artifact lying. Accepted: sentinels catch lazy bypass, not motivated forgery. Documented as known limitation.

### Additional items from RedGrove:

1. **HARD CONSTRAINT language** — R10 added. Every command calling gate.sh must include text naming the exact rationalization ("Do NOT create missing files. Do NOT offer to create them.").

2. **Harness-dependency disclosure** — enforcement is harness-dependent. Pi/Claude Code get structural hooks. Codex/Gemini get observability only. Spec must state this.

3. **Two-agent participation gap** — sentinels prove command ran, not that two agents participated. Documented as known limitation with future direction (mesh-level attestation).

## Phase 5: Agreement

RedGrove moved to [PHASE:agree] after all three remaining items were resolved with specific requirement language (R10) and spec constraint text.

## Selected Shape: D (revised)

| Part | Mechanism |
|------|-----------|
| **D1** | `scripts/gate.sh <command> <spec-dir>` — central script, reads prereqs from command frontmatter |
| **D2** | Flat `gate_*` keys in each command's YAML frontmatter |
| **D3** | gate.sh parses frontmatter to know what to check — command is single source of truth |
| **D4** | `gate.sh record <command> <spec-dir>` writes sentinels into artifacts and appends to pipeline state trail |
| **D5** | HARD CONSTRAINT block in every command: gate.sh FAIL = full stop, no fabrication |
| **D6** | Layer 2 hooks (pi/Claude Code) call gate.sh automatically where harness supports it |
| **D7** | Commands structured: frontmatter → HARD CONSTRAINT gate check → guidance prose |

## Known Limitations

1. Enforcement is harness-dependent (Layer 2 hooks only on pi/Claude Code)
2. Sentinels cannot verify two-agent participation (honor-system for now)
3. Motivated forgery leaves evidence but isn't structurally prevented

## Implementation Notes (from RedGrove)

- Comma-split parsing needs `| xargs` to trim whitespace
- `gate.sh record` voluntary invocation is self-healing: if forgotten, next stage's gate fails — pipeline is self-auditing

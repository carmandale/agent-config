---
shaping: true
bead: .agent-config-6on
---

# Hooks in Repo — Shaping

## Source

> why wasn't this part of your setup process? and testing and verification process? how can you say that everything is complete with such a big miss?
>
> did you do root cause work, or symptom work? is it fixed at source so that this can't happen again? are there tests and verification processes in place to catch these issues?
>
> what is the purpose and goal of .agent-config?
>
> To make any machine a fully working agent environment from a single repo. One clone, one setup, everything works.

---

## Problem

`settings.json` is tracked in agent-config. It references 28 hook files at `~/.claude/hooks/dist/*.mjs` plus gitnexus, python, and shell hooks. But the hooks source (~90 files: TypeScript src, shell wrappers, python scripts, package.json, build config) lives in `~/.claude/hooks/` on one machine with no mechanism to propagate.

A fresh machine that runs `setup.sh` gets a working settings.json that points to hooks that don't exist. Every Claude session on that machine errors on every hook invocation.

The symptom was patched (rsync'd hooks to Mini, added hook-file-exists checks to bootstrap). But the root cause remains: **a tracked config's dependencies are not tracked**.

---

## Outcome

A fresh machine reaches full working state — including all Claude hooks — from `git clone` + `scripts/setup.sh` alone. No rsync from another machine. No manual steps beyond adding API keys.

Additionally: the setup process includes integration-level verification that catches dependency gaps like this — not just "does this file's content match?" but "does everything this file needs actually exist and work?"

---

## Requirements (R)

| ID | Requirement | Status |
|----|-------------|--------|
| R0 | One clone + one setup = fully working Claude hooks on any machine | Core goal |
| R1 | Hooks source tracked in agent-config repo | Must-have |
| R2 | `bootstrap.sh apply` copies hooks source and builds dist/ | Must-have |
| R3 | `bootstrap.sh check` verifies all hook dependencies resolve (already done) | Must-have |
| R4 | `setup.sh` handles hooks end-to-end without manual steps | Must-have |
| R5 | Hook build is idempotent — safe to run repeatedly, only rebuilds when source is newer | Must-have |
| R6 | Machine-specific hook content (broken symlinks, laptop paths) handled gracefully | Must-have |
| R7 | Integration test: fresh-machine simulation verifies a Claude session can start without hook errors | Nice-to-have |
| R8 | No duplication — hooks source exists in exactly one place | Must-have |
| R9 | Hook development workflow: edit in repo, test, deploy to ~/.claude/hooks/ | Undecided |

---

## Shapes

### A: Track hooks source in `configs/claude/hooks/`

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **A1** | Copy `~/.claude/hooks/{src/,package.json,tsconfig.json}` into `configs/claude/hooks/` | |
| **A2** | Copy non-TS hooks (*.sh, *.py, gitnexus/) into `configs/claude/hooks/` | |
| **A3** | `bootstrap.sh apply` copies `configs/claude/hooks/` → `~/.claude/hooks/`, runs `npm install && npm run build` | |
| **A4** | `bootstrap.sh check` verifies dist/ files exist and match settings.json references | |
| **A5** | Handle machine-specific content: `shaping-ripple.sh` copied as file (not symlink), paths use `$HOME` not hardcoded | |
| **A6** | `.gitignore` excludes `configs/claude/hooks/node_modules/` and `configs/claude/hooks/dist/` | |
| **A7** | Integration test script: `scripts/verify-hooks.sh` — parses settings.json, checks every referenced path, optionally runs a dry-run hook invocation | ⚠️ |

### B: Track hooks as git submodule

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **B1** | Create separate `claude-hooks` repo from current `~/.claude/hooks/` | |
| **B2** | Add as submodule at `configs/claude/hooks/` | |
| **B3** | `bootstrap.sh apply` syncs submodule, copies to `~/.claude/hooks/`, builds | |
| **B4** | Same check/verify as A4, A7 | |
| **B5** | Hook development: edit in submodule repo, push, update submodule ref in agent-config | ⚠️ |

### C: Hooks as standalone installable package

| Part | Mechanism | Flag |
|------|-----------|:----:|
| **C1** | Publish `claude-hooks` as npm package or tarball | ⚠️ |
| **C2** | `setup.sh` installs the package to `~/.claude/hooks/` | ⚠️ |
| **C3** | Version pinning in agent-config ensures reproducibility | ⚠️ |

---

## Fit Check

| Req | Requirement | Status | A | B | C |
|-----|-------------|--------|---|---|---|
| R0 | One clone + one setup = working hooks | Core goal | ✅ | ✅ | ✅ |
| R1 | Hooks source tracked in agent-config | Must-have | ✅ | ✅ | ❌ |
| R2 | bootstrap.sh apply copies + builds | Must-have | ✅ | ✅ | ❌ |
| R3 | bootstrap.sh check verifies deps | Must-have | ✅ | ✅ | ✅ |
| R4 | setup.sh handles hooks end-to-end | Must-have | ✅ | ✅ | ✅ |
| R5 | Idempotent build | Must-have | ✅ | ✅ | ✅ |
| R6 | Machine-specific content handled | Must-have | ✅ | ✅ | ❌ |
| R7 | Integration test | Nice-to-have | ❌ | ❌ | ❌ |
| R8 | No duplication | Must-have | ✅ | ✅ | ✅ |
| R9 | Hook dev workflow | Undecided | ✅ | ❌ | ❌ |

**Notes:**
- C fails R1, R2: hooks are outside the repo, npm publish adds complexity without benefit for a single-user project
- B fails R9: submodule indirection makes editing hooks harder (commit in submodule, update ref in parent — two-step workflow for every change)
- A7 is flagged: integration test mechanism TBD — could be a script that invokes each hook with mock input, or just verifies file existence + node syntax check
- A passes R9: edit source directly in `configs/claude/hooks/src/`, run `bootstrap.sh apply` to deploy. Simple.

---

## Open Questions

1. **Test fixtures**: Some hooks import from `src/shared/` — need to verify the esbuild bundling handles all internal imports when source is at `configs/claude/hooks/` instead of `~/.claude/hooks/`
2. **Hook tests**: The hooks project has vitest tests (`npm test`). Should `bootstrap.sh check` run them? Or just verify build succeeds?
3. **shaping-ripple.sh**: Currently a symlink to `~/dev/shaping-skills/hooks/`. Should it be tracked in agent-config directly, or remain a per-machine symlink? (It's a 10-line script.)
4. **gitnexus**: The `gitnexus/` subdirectory has a `.cjs` file. Is this also a build artifact, or standalone? Need to check if it has its own build step.

---

## Recommendation

**Shape A** (track in `configs/claude/hooks/`). It's the simplest approach that satisfies the core promise. No extra repos, no submodule ceremony, no publish step. Edit → apply → done. The integration test (A7) can start as a simple file-existence + syntax check and grow from there.

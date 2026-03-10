<!-- Codex Review: APPROVED after 3 rounds | model: gpt-5.3-codex | date: 2026-03-10 -->
<!-- Status: RECONCILED -->
<!-- Revisions: tasks updated to match plan revisions from Codex rounds 1-3: ID-set integrity check format, empty repo init, fleet manifest counts, verification scope expanded, task renumbering (53 tasks) -->
---
title: "Tasks: Fleet-wide br migration"
date: 2026-03-10
bead: .agent-config-2gy
---

# Tasks: Fleet-wide br migration

## Phase 1: Build migration artifacts + dry-run testing

### Fleet manifest

- [x] 1. Generate fleet manifest: run `find` for `.beads/` dirs under laptop dev root, write `specs/013-br-fleet-migration/fleet-manifest.txt` with one repo per line + status annotation (working/schema-drift/dolt-nag/bricked/empty/no-jsonl/already-migrated)
- [x] 2. Verify manifest matches known counts: 1 already-migrated + 24 working + 6 schema-drift + 4 Dolt-nag + 1 bricked (GMP) + 4 empty/no-JSONL = 40 total laptop repos. Mini: 3 repos (1 already-migrated + 2 to migrate). Grand total: 43 repos across both machines.

### Migration script

- [x] 3. Write `scripts/migrate-to-br.sh` — manifest-driven (reads `fleet-manifest.txt`), NOT recursive discovery. `--discover` flag available only for initial manifest generation.
- [x] 4. Script preflight: read `configs/br-version.txt`, compare with `br --version`. Hard-fail if mismatch: "br version mismatch — expected X.Y.Z, got A.B.C."
- [x] 5. Implement per-repo procedure in order: (a) detect already-br-compatible (`br list` succeeds without DATABASE_ERROR → skip entire repo), (b) pre-flush (`bd sync --flush-only` — **hard-fail on non-zero exit code if `beads.db` exists with data**), (c) backup (`mv beads.db beads.db.bd-backup`), (d) `br init --prefix "$(basename $PWD)" --force`, (e) `br sync --import-only` (+ `--rename-prefix` for GMP), (f) ID-set integrity check: `sqlite3 .beads/beads.db "SELECT id FROM issues ORDER BY id;"` vs `jq -r '.id' .beads/issues.jsonl | sort` — diff must be empty (sqlite3 used because br list --all --json caps at 50), (g) `br doctor` informational check
- [x] 6. Implement GMP special case: hardcoded repo name match (`groovetech-media-player`) → add `--rename-prefix` to import step unconditionally. Pre-flush failure is expected (known-bricked), proceed using existing JSONL.
- [x] 7. Implement empty/no-JSONL repo handling: run `br init --prefix "$(basename $PWD)" --force` (no import step) so `br ready` and `br list` work immediately. Add to "INITIALIZED (no data)" summary section.
- [x] 8. Add `--dry-run` flag to script (log actions without executing)
- [x] 9. Error handling: per-repo hard-fail on flush failure (with beads.db) or ID-set mismatch. Continue to next repo. Summary at end listing (a) repos migrated, (b) repos skipped (already done), (c) repos skipped (empty/no-JSONL), (d) repos FAILED (with error details), (e) repos with JSONL changes needing manual git commit
- [x] 10. Script does NOT auto-commit to arbitrary repos. Summary lists repos with dirty JSONL for operator review.

### Hook replacement

- [x] 11. Write `configs/claude/hooks/br-prime.sh` — translate all 13 bd commands to br equivalents
- [x] 12. First line of output: sync direction warning (`⚠️ CRITICAL: br sync (bare) = IMPORT. Use br sync --flush-only to EXPORT.`)
- [x] 13. Verify br-prime.sh output: run it, diff semantically against `bd prime` output, confirm all 13 command mappings correct. Critical checks: `bd sync` → `br sync --flush-only`, `bd tag` → `br label add`, `bd create --tags` → `br create --labels`, `bd update -d` → `br update --description`

### Version governance

- [x] 14. Create `configs/br-version.txt` containing `0.1.24`

### Dry-run test matrix (throwaway copies)

- [x] 15. Test (a): Schema-drift repo — pre-flush + init + import. Verify ID-set integrity (sorted diff = empty).
- [x] 16. Test (b): Already-migrated repo (agent-config) — detection + skip. Verify no re-init, no bd sync attempted.
- [x] 17. Test (c): GMP special case — init + import with `--rename-prefix`. Verify all issues have `groovetech-media-player-*` prefix. Verify count ≥ 148. Verify ID-set integrity.
- [x] 18. Test (d): Empty/no-JSONL repo — no-op. Verify no errors.
- [x] 19. Test (e): Working repo — standard path. Verify ID-set integrity.
- [x] 20. Test (f): br-prime.sh output correctness — all 13 command mappings verified, sync direction warning present.
- [x] 21. Test (g): Version mismatch — temporarily edit br-version.txt to wrong version, verify script hard-fails at preflight.

### Commit migration artifacts

- [x] 22. Commit `scripts/migrate-to-br.sh` + `configs/br-version.txt` + `configs/claude/hooks/br-prime.sh` + `specs/013-br-fleet-migration/fleet-manifest.txt` to agent-config, push to origin. Mini needs to pull the script before Phase 2.

## Phase 2: Execute migration

### Laptop fleet (38 remaining repos + 1 already-migrated + 1 bricked)

- [x] 23. Run `scripts/migrate-to-br.sh` on laptop
- [x] 24. Review script summary: check repos migrated, skipped, failed. **Zero failures required to proceed** (any failure = investigate + fix + rerun before continuing).
- [x] 25. Spot-check 5+ repos: `br ready` AND `br list` works. Must include: GMP, 1 schema-drift, 1 Dolt-nag, 1 working, 1 high-issue repo (orchestrator or dcg)
- [x] 26. GMP specific: verify `br list --all` shows issues with `groovetech-media-player-*` prefixes, count ≥ 148
- [x] 27. For repos listed in script summary as "JSONL changes needing commit": review changes, `cd <repo> && git add .beads/issues.jsonl && git commit -m "chore: pre-br-migration bd flush" && git push`

### Mac mini (2 remaining repos)

- [ ] 28. SSH to mini: `cd ~/.agent-config && git pull --ff-only` (gets migration script + manifest)
- [ ] 29. Run `scripts/migrate-to-br.sh` (mini uses its own manifest or `--discover` mode for 3-repo fleet)
- [ ] 30. Verify: openclaw (9 issues) and chip-voice (2 issues) accessible via `br ready` AND `br list`
- [ ] 31. Agent-config on mini: verify detection + skip (already migrated in spec 010)

### Post-migration reminder

- [x] 32. Create bead for 30-day cleanup with due date 2026-04-10: "Remove bd binary, bd-backup files, bd from parity tool"

## Phase 3: Deploy hooks + docs

### Hook deployment

- [x] 33. Update `configs/claude/settings.json`: lines 87 and 249 — `"command": "bd prime"` → `"command": "~/.claude/hooks/br-prime.sh"` (matches existing .sh hook format)
- [x] 34. Run `bootstrap.sh check` on laptop — verify no missing hooks
- [x] 35. Run `bootstrap.sh apply` on laptop — deploys br-prime.sh + updated settings.json
- [x] 36. Run `bootstrap.sh check` on laptop — verify all hooks present including br-prime.sh
- [ ] 37. SSH to mini: `cd ~/.agent-config && git pull --ff-only`, then `bootstrap.sh check`, `bootstrap.sh apply`, `bootstrap.sh check`

### Documentation updates

- [x] 38. Delete `instructions/AGENTS_v1.md` (28 stale bd references)
- [x] 39. Update `instructions/AGENTS.md` §6: add line "Never run `br upgrade` without `--version <X.Y.Z>`. Both machines must be updated together."
- [x] 40. Update `tools-bin/agent-config-parity`: add `record_tool br` at line 220 (keep `record_tool bd` for 30-day window)

### Verification

- [x] 41. `rg '\bbd\b' instructions/AGENTS.md` — zero hits
- [x] 42. `grep "bd prime" configs/claude/settings.json` — zero hits
- [x] 43. `grep "bd prime" ~/.claude/settings.json` — zero hits on BOTH machines (repo config AND live deployed config)
- [x] 44. `rg '\bbd\b' configs/claude/settings.json configs/claude/hooks/` — zero hits (no stale bd references in hook configs)
- [ ] 45. `rg '\bbd\b' ~/.claude/settings.json` AND `rg '\bbd\b' ~/.claude/hooks/` — zero hits on BOTH machines (live deployed state)
- [x] 46. Run `agent-config-parity snapshot` on laptop → verify `tool.br.version` = `0.1.24`

### Commit + push

- [x] 47. Commit all Phase 3 changes: settings.json update, AGENTS_v1.md deletion, AGENTS.md §6 update, parity tool update
- [ ] 48. Push to origin. Mini pulls + applies.

## Phase 4: 30-day cleanup (2026-04-10)

- [ ] 49. Remove `record_tool bd` from `tools-bin/agent-config-parity`
- [ ] 50. Remove bd binary: laptop (`/opt/homebrew/bin/bd` symlink + `~/.local/bin/bd`), mini (equivalent paths)
- [ ] 51. Delete `beads.db.bd-backup` files across all repos (both machines)
- [ ] 52. Close the 30-day cleanup bead
- [ ] 53. Update napkin: remove "bd binary stays installed" note, mark migration fully complete

## Dependencies

```
Phase 1 (build + test) → Phase 2 (execute migration) → Phase 3 (deploy hooks + docs) → Phase 4 (30-day cleanup)
```

All phases strictly sequential. Phase 3 MUST NOT deploy before Phase 2 completes — deploying br hooks before migration creates a poison window where agents get br commands that fail on bd-schema databases.

Phase 4 is calendar-gated (30 days post-migration), not blocked by Phase 3 completion.

Mini depends on task 22 (script committed + pushed) before task 28 (mini pulls).

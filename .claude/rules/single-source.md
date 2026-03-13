# Single Source — Never Duplicate, Always Reference

When the same content, config, or registration exists in two places, one **will** drift. The fix is never "keep them in sync" — it's **eliminate the duplicate**.

## Pattern

One canonical source. Reference it (symlink, path, import). Don't copy it.

## DO

- Use symlinks instead of file copies (e.g., `core.hooksPath hooks` instead of copying to `.git/hooks/`)
- Register extensions/packages in ONE discovery path, not multiple
- When a fix lands on a branch, merge or cherry-pick to the branch that runs — don't leave it stranded
- When uninstalling, remove ALL copies (config entry + cache + marketplace clone)

## DON'T

- Copy a file to a second location "for convenience" — it will drift
- Register the same extension in both `packages[]` AND `extensions/` directories
- Deploy a config file without also deploying what it references
- Mark a fix as "done" when it's committed but not on the active branch

## Diagnostic

When you see a conflict or unexpected behavior, ask:
> "Is this thing registered or present in more than one place?"

If yes, eliminate all but one. Choose the most explicit/canonical source.

## Relationship to structural-coupling.md

`structural-coupling.md` covers the case where multiple sources MUST coexist and need enforced agreement (tests, diffs). This rule covers the upstream question: **should a second source exist at all?** Usually, no.

## Source Sessions

- 2026-02-10: Plugin duplication — native plugin + symlinks = double content
- 2026-02-10: Plugin cache left behind after uninstall — stale copy
- 2026-03-01: settings.json deployed to Mini but 28 hook files it references missing
- 2026-03-03: Codex skills symlink at wrong path — copy in wrong discovery location
- 2026-03-07: Fix committed on feature branch, spec marked complete, but main never got it
- 2026-03-12: pi-messenger in both packages[] and extensions/ — recurring conflict
- 2026-03-12: .git/hooks/post-commit was stale copy of hooks/post-commit

# Structural Coupling — When Multiple Sources Must Agree

When two or more files must stay in sync (same paths, same keys, same values), enforce agreement **structurally** — not with comments, documentation, or manual discipline.

Comments get ignored. Documentation drifts. Manual discipline fails under forward momentum. The only reliable coupling is one that breaks when sync is lost.

## Three Proven Approaches

### 1. Shared Source File
When multiple consumers need the same logic, extract to a shared library. Each consumer sources it.

```bash
# scripts/lib/collision-check.sh — sourced by install.sh AND bootstrap.sh
# One file, zero duplicate logic. Drift eliminated.
```
*Source: spec 012 — bootstrap.sh and install.sh had duplicated collision logic*

### 2. Automated Diff Test
When sources can't share code (different formats/languages), write a test that extracts the common data from each and diffs them.

```bash
# tests/test-symlink-parity.sh — extracts paths from 4 sources, diffs them
# install.sh ↔ bootstrap.sh ↔ README.md ↔ parity tool
# Any new source must be added here. Test fails if sources disagree.
```
*Source: spec 014 — parity tool had 3 wrong paths because no test enforced agreement*

### 3. Single Source of Truth + Generation
When one source is authoritative, generate the others from it. The generated files are never hand-edited.

```bash
# commands/*.md → scripts/convert-commands-gemini.sh → ~/.gemini/commands/*.toml
# Markdown is source of truth. TOML is generated. No sync needed.
```

## DO

- When adding a new managed path/key/config: update ALL consumers AND the test that verifies them
- When you see a "keep in sync" comment: replace it with a test or shared source
- When Codex/navigator review says "this is comment-only coupling": they're right — add structural enforcement

## DON'T

- Add `# COUPLED: also update X` comments as your only sync mechanism
- Assume documentation (README, plan.md) stays in sync with implementation
- Skip the coupling test because "the list rarely changes" — that's exactly when drift goes unnoticed

## Detection

If you find yourself writing `# Also update X when changing this`, stop — that's the smell. Replace with one of the three approaches above.

## Source Sessions

- spec 012: Shared helper for collision check (2 consumers → 1 shared lib)
- spec 014: Parity tool drift (4 sources → automated diff test)
- spec 014 Codex Review R1: Rejected "comment-only coupling" — required test guard

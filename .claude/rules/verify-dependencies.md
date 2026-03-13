# Verify Dependencies — Not Just the Artifact

A config file, script, or deployment is only correct if everything it **depends on** also resolves on the target. Verifying the artifact in isolation creates false confidence.

## Pattern

When verifying any artifact, trace its dependency graph and confirm each dependency exists and resolves.

## DO

- After deploying `settings.json`, parse it and confirm every hook path it references exists
- After editing a hook source file, confirm the active hook (the one git actually runs) reflects the change
- After installing a skill/extension, confirm its imports and referenced files resolve
- After setting up a new machine, run the full app/agent — don't just diff config files

## DON'T

- Verify config content matches baseline without checking what the config REFERENCES
- Declare "deployed" after copying one file when it depends on 28 others
- Trust "file matches expected" when the file is a pointer to things that might not exist

## Diagnostic

After any deployment or setup step, ask:
> "What does this artifact reference, import, or depend on? Do those things exist on the target?"

If you can't answer — you haven't verified.

## Source Sessions

- 2026-03-01: settings.json deployed to Mini — content matched baseline, syntax valid, but 28 hook files it references were missing. Mini sessions broken on every hook invocation.
- 2026-03-12: hooks/post-commit edited in repo, but .git/hooks/post-commit (the file git actually runs) was a stale copy. Edit had no effect until manually synced.

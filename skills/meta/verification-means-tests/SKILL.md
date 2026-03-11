---
name: verification-means-tests
description: Verification checklist items should have corresponding automated tests where practical. "Deploy and check manually" alone is not sufficient verification — pair it with tests. Use when writing verification checklists, defining "done" criteria, or reviewing plans that rely solely on manual verification.
---

# Verification Means Tests

## The Rule

If a behavior matters enough to put on a verification checklist, it almost always matters enough to have an automated test. A checklist item without a test is hard to reproduce, can't catch regressions, and won't run in CI.

Manual verification (log evidence, deploy checks, visual inspection) is still valid — especially for runtime behavior, integration environments, and UI. But it should **complement** automated tests, not replace them. Per AGENTS.md §7: verify with build + tests + behavior/log evidence.

## When This Fires

- You write `## Verification Checklist` in a spec or plan
- You write "manually verify" or "deploy and check" or "hit the endpoint" as the *only* verification
- You mark a verification item as complete without pointing to a test or documented evidence
- A plan says "run X with `--dry-run` and eyeball the output"

## What to Do

For every verification item, ask: **"What test would fail if this was broken?"**

| Checklist says... | Test should be... | Manual still useful? |
|---|---|---|
| "Hit all API endpoints" | Handler tests with mock req/res: method, status codes, response shape | Yes — smoke test on preview |
| "Verify funnel against manual deal count" | Fixture-based test with realistic data: assert on specific counts | Yes — spot check against prod |
| "Run script with --dry-run, verify output" | Unit test of the logic the script runs, with mock inputs | Only if no test exists yet |
| "Test webhook with/without secret via curl" | Handler test: 401 without secret, 200 with correct header | No — test covers it completely |

## When Manual-Only Is Acceptable

Some things genuinely resist automation:
- Visual/UI appearance (use screenshot comparison if possible, but human eye may be needed)
- Third-party service integration in production (test the handler, mock the service)
- Performance under real load (test the logic, benchmark separately)
- Hardware-specific behavior (document the manual check clearly)

When manual-only is the right call, document it explicitly: *"Manual: [what to check], because [why no test]."*

## The Anti-Pattern

```markdown
## Verification Checklist
- [ ] Deploy to preview, hit all API endpoints
- [ ] Verify conversion funnel against manual count
- [ ] Run scripts with --dry-run, verify output
- [ ] Test webhook with/without secret via curl
- [ ] npm test passes
```

Only 1 of 5 items has an automated test. The other 4 are manual actions that won't run in CI and can't catch regressions.

## The Correct Pattern

```markdown
## Verification Checklist
- [x] Handler auth flow — 4 tests: reject missing/wrong secret, accept correct, method rejection
- [x] Conversion funnel — fixture with 10 records: stage-by-stage count assertions
- [x] Alias resolution — 10 tests: canonical, legacy fallback, mixed, duplicate prevention
- [x] Webhook auth — handler mock: 401 without secret, 200 with header
- [x] npm test passes — 36 JS + 10 Python tests
- [x] Manual: deploy preview, smoke test 3 key endpoints (integration sanity check)
```

Every automatable item has a test. The one manual item is explicitly documented with rationale.

## Source

Observed across multiple projects: verification checklists with 5 manual items, 1 automated test. After converting, 46 automated tests replaced 4 of 5 manual items. The remaining manual check was documented with rationale.

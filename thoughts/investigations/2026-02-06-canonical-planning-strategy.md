# Canonical Planning Strategy — Ready to Add to AGENTS.md

## For Master AGENTS.md (~/.agent-config/instructions/AGENTS.md)

Add this section after Section 0 (Napkin) or as a new Section 1.5:

---

```markdown
## 1.5) Canonical Planning Artifacts

### Default: Use `specs/` for Feature Delivery

Every feature, fix, or improvement that requires planning goes in:

```
specs/<id>/
├── spec.md     # Requirements + acceptance scenarios (source of truth)
├── plan.md     # Implementation approach + architecture decisions
├── tasks.md    # Ordered, checkable execution list
└── research.md # Optional - only when unknowns need investigation
```

**ID format:** `<number>-<short-slug>` (e.g., `001-improve-app-loading`, `042-quic-teardown-fix`)

This is self-contained, diff-friendly, and PR-reviewable. Start here by default.

### Opt-In: Use OpenSpec for High-Rigor Proposals

Escalate to `openspec/changes/` when you need explicit proposal approval:

- Breaking changes (API/schema/protocol)
- Cross-repo behavior contracts
- Security/privacy/auth flows
- Operationally risky changes (fleet-scale, data loss risk)

OpenSpec is for **approval rigor**, not everyday delivery.

### Non-Canonical: Scratch Notes

- `plans/` — Working drafts, explorations (not source of truth)
- `.agent-os/planning/` — Scratch notes only
- `thoughts/shared/plans/` — Session-specific thinking

These are explicitly **not canonical**. Real work lives in `specs/`.

### Canonical Handoff Ledger

`thoughts/shared/handoffs/current.md` is THE place for "what's the current state?"

Every repo should have this file. Update it when handing off or resuming work.

### Deprecations (Archive-Only)

| Path | Status |
|------|--------|
| `.agent-os/specs/` | Archive-only — no new work |
| `.handoff/` | Migrate to `thoughts/shared/handoffs/` |
| Scattered `PLAN-*.md` | Migrate to `specs/<id>/plan.md` |

### Lane Selection (Quick Reference)

| Scenario | Use This Lane |
|----------|---------------|
| New feature work | `specs/<id>/` |
| Bug fix with planning | `specs/<id>/` |
| Breaking API change | `openspec/changes/` |
| Cross-repo contract | `openspec/changes/` |
| Quick exploration | `plans/` (scratch) |
| Session state | `thoughts/shared/handoffs/current.md` |
```

---

## For Each Repo's AGENTS.md

Add this short section near the top:

---

```markdown
## Planning Lanes (This Repo)

- **Feature delivery:** `specs/<id>/{spec,plan,tasks}.md` (canonical)
- **High-rigor proposals:** `openspec/changes/` (when needed)
- **Handoff ledger:** `thoughts/shared/handoffs/current.md`

ID format: `<number>-<short-slug>` (e.g., `001-improve-app-loading`)

See global AGENTS.md for full lane-selection criteria.
```

---

## Migration Checklist (Per Repo)

### orchestrator
- [ ] Add "Planning Lanes" section to `orchestrator/AGENTS.md`
- [ ] Stop new `.agent-os/specs/` items
- [ ] New work → `specs/<id>/`
- [ ] Active `thoughts/shared/plans/*.md` that represent real work → migrate to `specs/`
- [ ] Keep `Docs/Plans/` for durable architecture docs only

### PfizerOutdoCancerV2
- [ ] Already uses `specs/` ✓
- [ ] Add "Planning Lanes" section to confirm convention
- [ ] Consolidate `.agent-os/planning/` → scratch only
- [ ] Consider migrating `plans/*.md` → `specs/` if real work

### groovetech-media-server
- [ ] Add "Planning Lanes" section to `AGENTS.md`
- [ ] Create `specs/` directory
- [ ] Migrate `.handoff/*.md` → `thoughts/shared/handoffs/`
- [ ] Keep OpenSpec active (mature in this repo)
- [ ] Stop new `.agent-os/specs/` items

### groovetech-media-player
- [ ] Add "Planning Lanes" section to `AGENTS.md`
- [ ] Create `specs/` directory
- [ ] Migrate `Docs/PLAN-*.md` → `specs/<id>/plan.md`
- [ ] Keep OpenSpec available (skeleton exists)
- [ ] Stop new `.agent-os/specs/` items

---

## Verification Checklist

After migration, every repo should have:

- [ ] `AGENTS.md` with "Planning Lanes" section
- [ ] `specs/` directory (may be empty initially)
- [ ] `thoughts/shared/handoffs/current.md` exists
- [ ] No new items in `.agent-os/specs/`
- [ ] `.handoff/` migrated (if existed)

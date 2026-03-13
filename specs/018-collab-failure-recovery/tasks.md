---
title: "Collaboration Failure Recovery Protocol — Tasks"
date: 2026-03-12
bead: .agent-config-1vk
---

# Tasks — 018 Collaboration Failure Recovery Protocol

> **Dependency gate:** Do not start these tasks until pi-messenger specs 004 + 005 have merged to main. Verify: `stall` error type exists in pi-messenger's collaborator poll results.

All tasks below are a **single atomic commit** to `docs/agent-collaboration.md`. Do not commit any task independently.

- [x] **Task 1: Update spawn return type (line 62)**
  Updated error union: `"timeout" | "crashed" | "cancelled"` → `"stalled" | "collaborator_crashed" | "mesh_timeout" | "cancelled"`. Added `name` to error result shape. Error strings verified against pi-messenger runtime code (collab.ts, handlers.ts).

- [x] **Task 2: Replace error handling section (lines 102–110)**
  Removed 3-row error table and bold "On ANY collaboration failure" override. Replaced with 6-row graduated recovery table covering stalled/spawn, stalled/send, collaborator_crashed/spawn, collaborator_crashed/send, mesh_timeout/spawn, cancelled/any. Includes rewritten two-agent gate paragraph. Also updated § 5 (If spawn fails) to cross-reference recovery table instead of contradicting it.

- [x] **Task 3: Add context accumulation section**
  Added "Context accumulation for respawn" section with phase completion rules (completed vs. partial), summary construction guidance (2–4 bullets per phase), and worked example (stall-at-challenge scenario).

- [x] **Task 4: Add max rounds guard interaction note**
  Added full sentence from plan.md: "Respawning resets the count — the fresh collaborator hasn't seen the prior exchanges and needs a full round budget to be effective."

- [x] **Task 5: Verify internal consistency**
  Grepped for stale `timeout` — only `mesh_timeout` (new type), zero stale references. Grepped for bare `"crashed"` — zero results. All 6 recovery table rows use runtime-matching error strings. § 5 cross-references recovery table correctly (retryable vs. config errors match table).

- [x] **Task 6: Commit (single atomic commit)**
  Staged `docs/agent-collaboration.md` only. Commit message: `docs: graduated recovery protocol for collaboration failures (spec 018)`.

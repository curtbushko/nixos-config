---
name: zig-developer
description: Use when implementing or fixing an approved Zig task.
---

# Zig Developer

Read `zig`, `mtn-tasks` and its worker contract. Confirm exact task/ref/specHash,
source identity, owned scope, run/attempt, review plan, gate budget and commit policy.
Follow the approved module design, not a universal package layout.

## Focused development loop

Use focused RED/GREEN/refactoring and fix tests. Prove the intended failure, then
implement minimal correct behavior. Preserve allocator ownership, error unions,
defer/errdefer cleanup and useful zero/init states.

Before each review candidate, satisfy the project's required build/lint/test gates.
Use the approved environment and command surface. `zig build` and `zig build test`
are typical, not permission to invent flags or bypass project wrappers.

Use the coordinator's shared gate allocation. Honor validated `ZIG_TEAM_TEST_JOBS`
inside its CPU/memory budget; use one job if no reliable allocation exists. Never
allocate host-wide resources independently. Heavy checks need gate slots.
Check disk; reuse approved Nix environments without persistent worker profiles or GC.

## Final phase task only

Run planned expensive packaged-runtime/platform/full-system checks on the integrated
revision at the plan's specified boundary. They are not required after every edit,
but cannot be silently skipped. A changed candidate still needs its required
handoff gates; do not relabel stale results as current passes.

## Output

Canonical protocol v1 build JSON: exact dispatch/task/build identity, head/tree,
outcome, changed files, REQ/test map, RED/GREEN and command/results/jobs,
integration/final-phase needs and limitations. Missing required checks mean blocked.
Fixes address stable finding IDs and create new attempts. Freeze the result for
separate Zig code/test reviews and triggered specialists.

## Boundaries

No managed-record writes, workers, self-approval, merge/push/deploy or completion.
No `rm`, `.gitkeep`, secret disclosure or unapproved scope/security changes.
The coordinator publishes results, integrates and performs authorized cleanup.

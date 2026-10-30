# Shared Resources and Environment Lifecycle

## Separate limits

`mtn-workflow --repo "$REPO_ROOT" budget` calculates one coordinator-owned CPU and
available-memory budget with OS headroom, then separate builder, reviewer, heavy-gate
and integration limits. Defaults are conservative (up to two builders/reviewers,
one heavy gate, one integration). Overrides must be positive and fit detected
resources. Unknown resources fall back conservatively; Darwin uses free/reclaimable
pages, not `hw.memsize` as though total RAM were available.

Ownership reservations remain active through review/integration for conflict
checking. They do NOT consume builder slots while no builder is running. Maintain
separate live usage for builders, reviewer processes, heavy checks and integration.
The `ready_batch` guard accepts limits plus optional live `usage.builders`; existing
reserved/building work counts conservatively until host reconciliation proves stopped.

ALL compile/full-test/Nix-build commands consume a heavy-gate slot, including those
run by reviewers. The coordinator admits at most `limits.gates` simultaneously and
hands out `perGate.cpu`, `perGate.memoryGiB` and `perGate.zigJobs`. Their aggregate
allocation cannot exceed the shared budget. Builder/reviewer caps are NOT separate
full-machine CPU grants. Recompute at phase boundaries or resource-pressure events,
not independently inside every worker. Leave additional headroom for containers/VMs.

Pass the allocation as `ZIG_TEAM_TEST_JOBS`, `GOMAXPROCS`, applicable test-worker
limits and Nix `--cores`/`--max-jobs` settings. Explicit user overrides are capped by
admitted resources, never silently increased. The shell helper calculates limits;
host admission/reconciliation remains the coordinator's responsibility—it is not a
cross-process resource semaphore. Do not advertise that distinction as enforced locking.

## Disk preflight

Run `mtn-workflow --repo "$REPO_ROOT" disk` before preparing environments and heavy
commands. It checks repository and Nix-store filesystems, which may differ. If
`canStartHeavyWork` is false, stop new heavy work and propose cleanup. Do not wait for
a compiler/build to fill the disk. `MTN_WORKFLOW_MIN_FREE_GIB` controls the reserve.

Nix store objects are shared for the same pinned inputs; a worktree does not inherently
need a duplicate closure. Nevertheless, nix-direnv/devenv roots, profile generations,
result links, source snapshots, build outputs, per-worktree language caches and
retained worktrees can accumulate substantial disk usage. Exiting a shell is not GC,
and persistent GC roots can keep old closures alive indefinitely.

Reuse one approved flake.lock/shell/system environment where compatible. Do not update
inputs or run nested `nix develop --profile` per agent/attempt. Changed inputs require
a newly approved environment. Avoid copying `.direnv`, `.devenv`, profiles, caches or
GC-root links into worktrees. Keep a coordinator inventory of any automation-owned
root/cache/worktree it creates; record ownership and release conditions in evidence.

## Cleanup is part of completion

At phase completion/interruption, stop and confirm workers, preserve source/evidence,
and run `mtn-workflow --repo "$REPO_ROOT" cleanup-plan`. Review retained worktrees,
profiles/roots and cache sizes. Release only explicitly selected automation-owned
resources after checking no live consumers remain. Ask approval for deletion of user
roots/profiles, history/generations, store GC or any global cleanup. Never run sudo
GC, wipe system/Home Manager generations, or delete `/nix/store` paths as a fix.

Useful inspections: `df`, `git worktree list`, `nix-store --gc --print-roots`, and
`nix-store --gc --print-dead`. These report state; collecting garbage is a separate
approved action. Follow existing repository system-GC policy instead of adding a
second competing schedule. No cleanup command runs as part of the skill tests.

Moving files/root links to `.trash/` preserves data but does not itself reclaim
space and may retain roots. Do not claim disk was freed; verify root reachability
and filesystem free space after approved maintenance. Keep failed work and recovery
evidence; stale environments are not an excuse to discard user work.

# Go Delivery Example

Read `mtn-tasks` and protocol v1. An approved PRD owns REQ IDs; optional RFC owns
interfaces. `to-phases` records an approved dependency graph. Independent ready
phases can overlap; order is a tie-breaker, not a barrier.

Task Manager workers propose task specs, ownership and coverage without mutating
records. Coordinator publishes/approves their manifests through mtn. Two tasks owning
`internal/parser` and `internal/formatter` can run in separate worktrees if interfaces,
prerequisites and resources are independent. Shared build wiring is serialized.

Each Go builder receives exact root/ref/spec hash, base/target/worktree and dispatch
identity, runs TDD plus Taskfile/architecture gates, commits only scoped source, and
returns a v1 build payload. Coordinator publishes it and freezes that checkout.
Combined reviewer checks spec then quality/semantic dead code and independently runs
lint against that exact build. Coordinator publishes its v1 review payload.

CHANGES_NEEDED produces a new dispatch/build attempt and fresh explicit review.
APPROVED means ready for serialized integration, not completion. Coordinator integrates,
runs combined-target checks, records actual integrated commit/tree and review IDs,
verifies ancestry, then records completion and native-completes the task.

On interruption after approval, reconstruct state from mtn and resume integration;
do not rebuild or launch a duplicate worker. Preserve worktrees/evidence. Completed
parents require final combined-revision gates and requirement coverage. Migration
of existing project formats still requires explicit approval.

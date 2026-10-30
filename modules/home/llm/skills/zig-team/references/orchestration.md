# Zig Team Orchestration

Read `mtn-tasks`, its commands, migration rules, and shared execution reference
`../../mtn-tasks/references/execution.md` completely. It owns the selection/resume,
single-writer, lifecycle, supervision, and completion loop. Keep the coordinator
focused on graph/status/evidence metadata, not source or full specifications.

## Task Manager

Pass the absolute collection root and exact phase/project refs. The planner reads
phase/approved PRD/design descriptions through mtn, explores code/module boundaries/tests, and
proposes `workflowKind: task`, `workflowLanguage: zig`, and phase-scoped integer
`workflowOrder` records. Work inside out: domain → ports → app → adapters → wiring.
Each task states files, criteria, tests, constraints, and its own TDD cycle.
Return proposed native links, ownership/interface boundaries and REQ coverage.
Coordinator validates and serially publishes the approved v1 plan manifest; planners
never mutate the collection. Mark final gates in the task graph with dependencies
on ALL required phase work, not merely the highest task number.

## Verification Strategy

Run the narrowest relevant test first during RED, GREEN, and each fix cycle.
Run the full test suite once after the implementation is ready for review.
Re-run the full test suite after a fix only when the fix has broad impact
(shared infrastructure, public contracts, build wiring, persistence, concurrency,
or multiple capabilities), or a reviewer explicitly requests it. Otherwise record
why prior full-suite evidence still applies to the reviewed revision.

Reserve exhaustive project-specific, packaged-runtime, and full-system gates for the final task of the phase.
Earlier tasks run focused tests plus standard build/full suite; the final task
records all release-matrix evidence for final review.

Select/export `ZIG_TEAM_TEST_JOBS` from the coordinator's shared per-gate allocation
(`mtn-workflow budget`), not full host resources per worker. Validate/cap explicit
overrides; use one job if no reliable allocation exists. Heavy commands share the
same gate slots across builders AND reviewers. Check `mtn-workflow disk` before
preparing Nix environments/builds; keep cleanup planning in the phase completion flow.

```bash
zig build
zig build test -j"$ZIG_TEAM_TEST_JOBS"
```

Use actual project-defined focused test targets/filters, not guessed Zig flags.
Record exact commands, job count, RED failure, GREEN success, and full-suite result
in protocol v1 build payloads. Fixes are new dispatch/build attempts. Coordinator
publishes ALL evidence; workers never mutate the collection or complete native tasks.

## Build and Review

Builder handoff: `mtn-tasks`, `zig-builder`, `zig`, exact task/phase refs, absolute
collection root, isolated worktree/base/head/target branch, allowed ownership scope,
interfaces, verification/integration gates, attempt/run ID, spec hash and commit policy.

Dispatch all four initial reviewers in parallel against the same frozen code revision
only if the allocated reviewer limit permits four. Otherwise queue fresh independent
contexts within that limit; heavy commands still consume shared gate slots. Each reads `mtn-tasks` and `zig-reviewer` plus:

| Specialty | Additional skills | Evidence role |
|---|---|---|
| Code | `zig-code-reviewer`, `zig-code-review`, `zig` | code |
| Comment | `zig-comment-reviewer` | comment |
| Architecture | `zig-architecture-reviewer`, `zig` | architecture |
| Test | `zig-test-reviewer`, `zig` | test |

Reviewers are read-only for source and managed records. Return full review payloads;
the coordinator serially publishes each using `agent note` category `review`, with
role, attempt, revision, findings, and verdict. Do not concurrently append to one
record. Confirm all four evidence entries survived with `show` before proceeding.

All four reviewers MUST return `APPROVED` for the accepted revision.
`NON_BLOCKING_SUGGESTIONS` are preserved as follow-up evidence, not blocking findings.
Conflicting blockers require focused reviewer reconciliation; unresolved conflicts
or scope-changing remedies require user decision before further implementation.

## Fix, Resume, Complete

Fix workers read every published specialty finding through mtn and return a new v1
build attempt after required verification; the coordinator publishes it. Re-dispatch only reviewers whose concerns could be affected
by the fix; broad changes to architecture, behavior, shared infrastructure, or several
capabilities require all four. Every required specialty must issue a fresh explicit v1 verdict for the NEW build
ID/head/tree; unchanged reasoning may be reused by its reviewer, not by the coordinator.
Never mix approvals across builds. Ten cycles without resolution require user escalation.

Only the coordinator serially integrates approved results, checks the combined
revision, publishes integration/completion events and verifies target history before
native task completion. After ALL required integrations, run phase-final gates and
REQ coverage checks before completing nonempty parents. Do not keep manual counters.

## Progress and Recovery

PROGRESS_INTERVAL = 2 minutes

While long work runs, report stage, exact command, elapsed time, and fresh evidence.
Use host-native automatic delivery, not polling loops on event-driven hosts. Follow
the shared recovery thresholds; confirm a writer stopped before replacement.
An alive process is not proof of progress; fresh output is not a reason to interrupt.

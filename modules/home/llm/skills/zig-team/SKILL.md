---
name: zig-team
description: Use when implementing Zig project phases with a Task Manager, TDD Builder, and independent code, comment, architecture, and test reviewers. Coordinates mtn records and evidence in the repository-local .tasks collection.
---

# Zig Team

Read `mtn-tasks`, its delivery protocol, and `references/orchestration.md` completely before dispatch.
The coordinator dispatches and tracks metadata, graph readiness, and persisted
verdicts; workers read source and detailed descriptions. Worker skill bodies and
worked examples are not normal coordinator context.

## Pi / Rex startup

Use Pi for every agent. Before dispatch, read
`../mtn-tasks/references/rex.md` completely. Unless `MTN_REX_COORDINATOR_RUN`
is already set for this collection, hand off to a new coordinator Pi in a Rex
session named for the orchestration worktree. Stop coordinating after handoff;
do not also execute the team in this caller. The handed-off coordinator launches
all planners/builders/reviewers as named Rex windows through `mtn-rex`.
Never substitute hidden/background subagents or start another coordinator.

## Invocation

- No arguments: select dependency-ready tasks across all eligible phases in the
  chosen project; phase/task order is a preference, not a barrier.
- `phase=<N or exact ref>`: select a phase within that project.
- `task=<N or exact ref>`: select one task within that phase; never bypass dependencies.

Ambiguous projects/numbers require clarification. All children receive the absolute
collection root and exact refs; no child initializes a competing collection.

## Roles

| Role | Required skills |
|---|---|
| Task Manager | `mtn-tasks`, Zig architecture context |
| Builder | `mtn-tasks`, `zig-builder`, `zig` |
| Code reviewer | `mtn-tasks`, `zig-reviewer`, `zig-code-reviewer`, `zig-code-review`, `zig` |
| Comment reviewer | `mtn-tasks`, `zig-reviewer`, `zig-comment-reviewer` |
| Architecture reviewer | `mtn-tasks`, `zig-reviewer`, `zig-architecture-reviewer`, `zig` |
| Test reviewer | `mtn-tasks`, `zig-reviewer`, `zig-test-reviewer`, `zig` |

Independent builders run in isolated worktrees with approved nonconflicting scopes.
Four initial reviews inspect each frozen worktree revision in parallel when capacity
and check-output isolation permit. Coordinator serializes ALL collection writes and
integrations, requiring all four current APPROVED verdicts for each build. In mixed
projects select each task's language; Zig supplies defaults, not a language override. Reconcile conflicting blockers and ask the
user before scope-changing architectural remedies.

## Invariants

- All managed files, frontmatter, descriptions, relationships, and lifecycle writes
  use mtn. No hand-edited state or duplicate result store.
- Native membership is hierarchy; explicit dependencies are prerequisites.
- Preserve focused RED/GREEN loops, configurable test jobs, one full-suite run
  before review, and phase-final exhaustive gates.
- Dependencies flow adapters → app → ports → domain, enforced by `build.zig`
  modules. Domain has no I/O/external dependencies. Resource-owning adapters have
  explicit `init`/`deinit`; allocator ownership is explicit.
- Require approved document/plan fingerprints and REQ-to-task/test coverage.
- Complete only after current reviews, successful target integration and combined-
  revision checks; no missing evidence, failing tests or stale/negative approvals.
- Keep records and evidence for history; migration requires explicit approval.

`to-prd`, `to-phases`, and `write-phase` prepare records; this skill executes them.

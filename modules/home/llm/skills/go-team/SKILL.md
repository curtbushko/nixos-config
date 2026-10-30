---
name: go-team
description: Use when implementing Go project phases with a Task Manager, TDD Builder, and spec/quality Reviewer. Coordinates native mtn records and evidence in the repository-local .tasks collection.
---

# Go Team

Read `mtn-tasks`, its delivery protocol, and `references/orchestration.md` completely before dispatch.
The coordinator dispatches and tracks metadata, graph readiness, and persisted
verdicts; workers read source and detailed descriptions. Do not load worker skill
bodies into coordinator context unless diagnosing a workflow problem.

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

| Role | Required skills | Outcome |
|---|---|---|
| Task Manager | `mtn-tasks`, Go architecture context | Proposed native task graph, ownership and requirement coverage |
| Builder | `mtn-tasks`, `go-builder`, `golang` | TDD implementation and revision-bound build/fix payload |
| Reviewer | `mtn-tasks`, `go-reviewer`, `go-code-review`, `golang` | Spec then quality verdict and findings |

Run independent builders in isolated worktrees within approved ownership/resource
limits. Coordinator serializes ALL mtn mutations and Git integrations. Workers
return versioned result/proposal payloads. Use each task's language in mixed projects;
this team supplies Go defaults, not permission to overwrite task metadata. Code review never implies
permission to modify source. Use host-native delivery and explicit model/thinking
choices when supported; follow the shared execution reference for supervision.

## Invariants

- All managed files, frontmatter, descriptions, relationships, and lifecycle writes
  use mtn. No raw status/checklist edits or duplicate result store.
- Native membership is hierarchy, native dependencies are prerequisites.
- Require approved PRD/design/plan fingerprints and REQ-to-task/test coverage.
- Tasks complete only after current review, integration into target history and
  checks on the combined target revision. Branch approval alone is not completion.
- Follow Go hexagonal architecture, Cobra/Viper, testify, and Taskfile quality gates.
- Keep phase/task records and evidence for history; migration requires explicit approval.

`to-prd`, `to-phases`, and `write-phase` prepare records; this skill executes them.
Worked recovery examples live in `references/examples.md` for workers/operators.

---
name: go-team
description: Use when executing approved Go project phases or tasks through delegated workers.
---

# Go Team

Read `delivery-coordinator`, `mtn-tasks`, and
[Go orchestration](references/orchestration.md) before dispatch.
This is the Go entry point, not a second coordinator or language handbook.

## Pi / Rex startup

Read `../mtn-tasks/references/rex.md` completely. Unless
`MTN_REX_COORDINATOR_RUN` is already set for this collection, hand off once to
the required new coordinator Pi process and stop coordinating in this caller.
Use one Rex session per execution/worktree, not per phase.
Use one lowercase hyphenated agent identity with the exact supplied run/session
identity and role labels defined in that reference. Do not rename historical runs,
substitute background agents or recreate launcher-owned Rex resources.

## Selection

- No arguments: select dependency-ready tasks in the chosen project.
- `phase=<N or exact ref>`: restrict phase scope.
- `task=<N or exact ref>`: restrict task scope; never bypass prerequisites.

Ambiguous refs need clarification. Existing approved work needs no repeated approval.
Use task languages in mixed projects; this team does not overwrite metadata.

## Roles and evidence

| Role | Skills |
|---|---|
| Coordinator | `delivery-coordinator`, `mtn-tasks` |
| Task planner | `mtn-tasks`, Go project context |
| Developer | `go-developer`, `golang`, `mtn-tasks` |
| Code reviewer | `go-code-reviewer`, `go-reviewer`, `golang` |
| Test reviewer | `go-test-reviewer`, `go-reviewer`, `golang` |

Shared product/design/security/maintenance/usability roles provide input when relevant.
Use an approved review plan for every new task. Every materially affected language
needs its separate code/test reviewers; triggered specialists independently review
their concerns. All current scopes govern the same frozen build. A legacy
combined verdict cannot replace them. Coordinator serializes managed-record writes,
integration and combined-target verification. A worker never approves its own work,
pushes, integrates or completes native status.

Perform [Task cleanup](../mtn-tasks/references/execution.md#task-cleanup) after
each delivered task. Preserve unsafe resources and report actual blockers.
Recovery examples are in [examples](references/examples.md).

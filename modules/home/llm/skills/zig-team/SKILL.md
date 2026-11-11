---
name: zig-team
description: Use when executing approved Zig project phases or tasks through delegated workers.
---

# Zig Team

Read `delivery-coordinator`, `mtn-tasks`, and
[Zig orchestration](references/orchestration.md) before dispatch.
This is the Zig entry point, not a second coordinator or language handbook.

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
| Task planner | `mtn-tasks`, Zig project context |
| Developer | `zig-developer`, `zig`, `mtn-tasks` |
| Code reviewer | `zig-code-reviewer`, `zig-reviewer`, `zig` |
| Test reviewer | `zig-test-reviewer`, `zig-reviewer`, `zig` |

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

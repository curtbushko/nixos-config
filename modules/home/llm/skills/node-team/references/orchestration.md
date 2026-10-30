# Node Team Orchestration

Read `mtn-tasks`, its commands, migration rules, and shared execution reference
`../../mtn-tasks/references/execution.md` completely. That reference defines the
selection, resume, supervision, single-writer, review/fix, and completion loop.
Do not substitute hand-edited state or a separate task/result format.

## Task Manager

Give the planner the exact phase ref and absolute collection root. It reads phase
and approved PRD/design descriptions through mtn, explores code, and proposes task records with
`workflowKind: task`, `workflowLanguage: node`, and phase-scoped `workflowOrder`.
Identify affected components, routes/controllers, services, repositories, middleware,
configuration, errors, and tests. Each task has independently verifiable acceptance
criteria, allowed files, a reviewable diff, and its own RED/GREEN/refactor cycle.
Return proposed native memberships/dependencies, bounded ownership/interfaces and
REQ coverage. Coordinator validates, publishes serially and obtains actual plan
approval. The planner does not mutate the collection.

## Builder Handoff

Pass exact refs, allowed files, commit policy, and required skills:
`mtn-tasks`, `node-builder`. The worker reads task description via `show`, follows
TDD, ES modules, Zod validation, component boundaries, and isolated AAA tests.
Required verification:

```bash
npm test
npm run lint
# Also use the project's quality target when present:
make lint  # if Makefile exists
# Otherwise, if Taskfile exists:
task lint
```

Builder works in its supplied isolated worktree and returns a protocol v1 build
payload: dispatch ID, exact commit/tree/spec identity, commands, tests, files and
limitations. Fixes are new dispatch/build attempts. Coordinator publishes evidence;
workers never mutate the collection or complete tasks. Ready-for-review and blocked
are payload outcomes; clarification is blocker evidence. Do not weaken checks.

## Reviewer Handoff

Use a fresh context with `mtn-tasks` and `node-reviewer`. Provide exact task ref,
build attempt, revision/diff identity, and read-only source scope. Review spec
compliance first, then quality/security/resources only if spec passes.
Independently run `npm run lint` and the project's applicable lint target.
Reviewer returns the combined evidence payload defined by mtn-tasks. The coordinator
serially appends it as a `review` note and confirms publication through `show`.
Missing/stale evidence, negative findings, and lint failures prevent approval.

## Fix and Complete

On CHANGES_NEEDED, dispatch the builder with task ref and review attempt IDs.
Workers read published findings, fix blockers and rerun gates, then return a NEW v1
build payload with finding references. Coordinator publishes it and requests a
new current review. Maximum 10 cycles before escalation.
Only the coordinator serially integrates approved work and runs checks on the
combined target revision. Persist v1 integration/completion events and verify target
history before native completion. Then check nonempty parent scope, final gates and
REQ coverage. Current approval alone never completes an unintegrated task.
Preserve history; never archive completed tasks simply to start another phase.

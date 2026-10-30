# Go Team Orchestration

Read `mtn-tasks`, its commands, migration rules, and shared execution reference
`../../mtn-tasks/references/execution.md` completely. That reference defines the
selection, resume, supervision, single-writer, review/fix, and completion loop.
Do not substitute hand-edited state or a separate task/result format.

## Task Manager

Give the planner the exact phase ref and absolute collection root. It reads phase
and approved PRD/design descriptions through mtn, explores code, and proposes task records with
`workflowKind: task`, `workflowLanguage: go`, and phase-scoped `workflowOrder`.
Use inside-out implementation order: domain → ports → application → adapters →
wiring. Every task has independently verifiable acceptance criteria, a reviewable
diff, affected files, test scenarios, and its own TDD cycle. Native dependencies,
not numbering, enforce prerequisite work. Return the graph, ownership/interface boundaries and REQ coverage for coordinator
publication and actual approval as a v1 plan manifest. Do not mutate the collection.

## Builder Handoff

Pass exact refs, allowed files, commit policy, and required skills:
`mtn-tasks`, `go-builder`, `golang`. The worker reads task description via `show`,
follows RED/GREEN/refactor, then runs:

```bash
task build
task test
task lint
# Required when .go-arch-lint.yml exists:
go-arch-lint check
```

Missing Taskfile is a blocker. Do not change lint rules, disable checks, add
`//nolint:`, or weaken tests to pass. Builder works in its supplied isolated worktree and returns a protocol v1 build
payload with dispatch ID, exact commit/tree/spec fingerprint and validation. Fixes
are new dispatch/build attempts. Coordinator publishes all evidence; workers never
mutate the collection or complete native status. Return ready-for-review or blocked;
clarification is blocker evidence. Record allowed scope and integration commands.

## Reviewer Handoff

Use a fresh context with `mtn-tasks`, `go-reviewer`, `go-code-review`, and `golang`.
Provide task ref, build attempt, revision/diff identity, and read-only source scope.
First check every acceptance criterion and under/over-building. Only after spec
compliance, review quality, architecture, error handling, concurrency, resources,
security, tests, and semantic dead code. Independently run `task lint`.

Reviewer returns a combined review payload defined by mtn-tasks, including verdict,
findings, command evidence, and revision. The coordinator serially publishes the
payload as a `review` note and confirms it through `show`. Never complete from an
unpublished two-line summary. All required checks must pass for APPROVED.

## Fix and Complete

On CHANGES_NEEDED, dispatch the builder with exact task ref and review attempt IDs.
Workers read findings through mtn, fix blockers and rerun gates, then return a NEW
v1 build payload with finding references. Coordinator publishes it and requests a
new current review. Maximum 10 cycles before user escalation.
Only the coordinator serially integrates approved work and runs checks on the
combined target revision. Persist v1 integration/completion events and verify target
history before native completion. Then check nonempty parent scope, final gates and
REQ coverage. Current approval alone never completes an unintegrated task.
Preserve history; never archive completed tasks simply to start another phase.

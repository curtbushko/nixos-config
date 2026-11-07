---
name: mtn-tasks
description: Use when planning documents, phases or delegated tasks in one repository-local .tasks mtn collection. Coordinates reviewed delivery with native relationships and shell-based workflow helpers.
---

# Repository Delivery

**Workers:** read only [worker contract](references/worker.md) plus the assigned
language/specialty skill and exact task. Do not load coordinator references or the
whole task history.

**Coordinator:** read [protocol](references/protocol.md), [execution](references/execution.md),
[resources](references/resources.md), [data model](references/data-model.md) and [Bash facade](references/facade.md).
Migration requires
**explicit approval**; see [migration](references/migration.md). The kernel-lock
[proposal](references/locking-proposal.md) is not enabled yet.

Team execution uses Pi in Rex: read [Rex/Pi execution](references/rex.md).
Persist coordinator and worker locators as `runtime` evidence through mtn; these
notes never count as review, completion, or proof of a live process.
Keep routine coordinator commentary to concise status summaries and artifact paths,
not task Markdown or full payload dumps. Worker Rex terminals still show live Pi
assistant/tool/error activity; only prompts, task Markdown, and durable payload dumps
are suppressed. Save machine-readable mutation responses and worker results to files.
Successful worker windows close automatically; the coordinator must verify closure
and remove eligible task worktrees after each delivered task using
[Task cleanup](references/execution.md#task-cleanup), not merely plan phase-end cleanup.
Active records retain only the
current delivery state and small file/ref pointers; completed task/phase records
are compacted to one coordinator-authored delivery summary. Failed or blocked work
retains only the current blocker and recovery inputs needed to resume. See the Rex
reference for exact closure and recovery rules.

Use `mtn-workflow --repo "$REPO_ROOT" status|task|snapshot|fingerprint REF`, `ready PROJECT`,
`compact REF SUMMARY.json`,
`paths PATH...`, `budget`, `disk`, and `cleanup-plan`. Only the authorized coordinator
publishes events. Automation is Bash plus Unix tools/jq, never JS or Python.

`.tasks/` is the single source of workflow truth. Do not hand-edit managed records.
Native calls always use `mtn --path "$TASK_ROOT"`. Diagnose before initialization;
never use --force. Workflow records follow [data-model](references/data-model.md):
identity (UUID and stable typed ID; for example `identity.kind` and `identity.taskID`), presentation, structure (including `structure.order`), scope, lifecycle,
execution, and implementation are distinct. New code must use those grouped fields exclusively. `RunID` identifies one
execution only; display names and provider resource IDs are never work-item or run
identity. Native memberships and explicit dependencies are distinct. Prefer task
edges; phase edges mean a genuine whole-milestone barrier.

A single writer serializes collection mutations and target integration. Independent
builders use worktrees and bounded ownership. Separate builder/reviewer/gate limits
share one CPU/memory/disk budget; agentEligible is not a claim. Preserve unresolved
blockers across revisions. Only reviewed, integrated, verified work completes.

Approval policy permits bounded autonomy within approved scope; semantic changes
escalate. Administrative title/order edits do not invalidate reviews. No automatic
GC, generation deletion, user-root cleanup, migration or lock takeover.

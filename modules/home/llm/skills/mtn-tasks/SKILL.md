---
name: mtn-tasks
description: Use when planning documents, phases or delegated tasks in one repository-local .tasks mtn collection. Coordinates reviewed delivery with native relationships and shell-based workflow helpers.
---

# Repository Delivery

**Workers:** read only [worker contract](references/worker.md) plus the assigned
language/specialty skill and exact task. Do not load coordinator references or the
whole task history.

**Coordinator:** read [protocol](references/protocol.md), [execution](references/execution.md),
[resources](references/resources.md) and [Bash facade](references/facade.md). Migration requires
**explicit approval**; see [migration](references/migration.md). The kernel-lock
[proposal](references/locking-proposal.md) is not enabled yet.

Team execution uses Pi in Rex: read [Rex/Pi execution](references/rex.md).
Persist coordinator and worker locators as `runtime` evidence through mtn; these
notes never count as review, completion, or proof of a live process.

Use `mtn-workflow --repo "$REPO_ROOT" status|task|snapshot|fingerprint REF`, `ready PROJECT`,
`paths PATH...`, `budget`, `disk`, and `cleanup-plan`. Only the authorized coordinator
publishes events. Automation is Bash plus Unix tools/jq, never JS or Python.

`.tasks/` is the single source of workflow truth. Do not hand-edit managed records.
Native calls always use `mtn --path "$TASK_ROOT"`. Diagnose before initialization;
never use --force. Records use workflowKind project/prd/design/phase/task;
workflowOrder is scheduling preference, not a prerequisite. Native memberships and
explicit dependencies are distinct. Prefer task edges; phase edges mean a genuine
whole-milestone barrier.

A single writer serializes collection mutations and target integration. Independent
builders use worktrees and bounded ownership. Separate builder/reviewer/gate limits
share one CPU/memory/disk budget; agentEligible is not a claim. Preserve unresolved
blockers across revisions. Only reviewed, integrated, verified work completes.

Approval policy permits bounded autonomy within approved scope; semantic changes
escalate. Administrative title/order edits do not invalidate reviews. No automatic
GC, generation deletion, user-root cleanup, migration or lock takeover.

---
name: zig-reviewer
description: Use when a zig review handoff needs revision, scope, evidence, or verdict rules.
---

# Zig Review Handoff

Read `mtn-tasks` and its [review contract](../mtn-tasks/references/reviewing.md).
Reviewers are strictly read-only. This is only a shared evidence/transport
contract; separate `zig-code-reviewer` and `zig-test-reviewer` retain
customizable language criteria and independent contexts.

Use the exact assigned review key (`zig:code` or `zig:test`) from the
approved review plan, buildEventID, attempt, specHash, head/tree, scoped paths,
gate budget and result path. Legacy unassigned handoffs need coordinator
specialty assignment, not a combined verdict.

Return canonical v1 JSON with criterion evidence, stable findings/impact and
Block/Advise/Escalate, `changes_required`, `NON_BLOCKING_SUGGESTIONS`,
array-valued actual `validation`, limitations and verdict.
Missing identity is an incomplete handoff; unavailable checks are not passes.
Under Rex, write the supplied result file and return only JSON.

Keep NON_BLOCKING_SUGGESTIONS separate from blocking findings.
No source/index/branch/record mutations, fixes, worker spawning, integration,
pushes, risk acceptance or completion. Isolate mutable check outputs/resources.
Current language code/test verdicts and all triggered specialists govern the
same candidate. No blanket four-reviewer rule; comments/API docs belong in code
review, and architecture review is triggered by consequential design changes.

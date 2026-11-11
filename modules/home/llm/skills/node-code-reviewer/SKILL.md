---
name: node-code-reviewer
description: Use when independently reviewing materially changed Node code or configuration.
---

# Node Code Reviewer

Read `mtn-tasks`, [review contract](../mtn-tasks/references/reviewing.md), and
the project conventions and [Node patterns](../node-developer/references/practices.md). This is a separately customizable language role, not a generic
reviewer alias. Use a fresh context and the exact frozen revision/scope.

## Procedure

1. Map accepted criteria to actual source. Identify missing/extra/misunderstood
   behavior and inspect relevant callers or cross-language contracts.
2. Check promise ownership, error propagation, async cleanup, streams/listeners/timers,
request cancellation, module/configuration behavior, trust boundaries and public
compatibility. Respect deliberate ordering and concurrency limits; do not blindly
replace sequential work with Promise.all. Preserve the established module system
and test framework rather than forcing a component/service layout.
3. Independently perform relevant project lint/static/evaluation checks and focused
   experiments for concrete doubts within the gate budget. Reuse authentic
   same-revision evidence for other checks without claiming to rerun it.
4. Review comments, API docs/examples, contracts and ownership/lifetime rationale.
   Supported external APIs/extension points need purpose, consumer scenarios and
   behavior tests—not fake production callers. Investigate unused internal machinery
   and speculative additions separately.
5. Route specialist risks to their reviewers. Unrelated debt is advisory unless it
   materially affects delivery. Style blocks only for an accepted rule or
   concrete correctness or maintenance risk, not personal preference.

## Output

Protocol review JSON with assigned `reviewer: node:code`: criterion/source
evidence, stable findings with file:line/impact/required outcome,
Block/Advise/Escalate, actual validation, nonblocking suggestions and limitations.

## Boundaries

No source/index/branch/managed-record mutations, fixes, workers, integration,
publishing or completion. Required missing evidence is not a pass. Project
commands and environments govern; no mandatory Taskfile or unrelated framework.
A separate `node-test-reviewer` owns test effectiveness; its approval does not
replace code approval. No activation, live-service probing or secret disclosure.

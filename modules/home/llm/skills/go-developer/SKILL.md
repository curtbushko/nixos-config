---
name: go-developer
description: Use when implementing or fixing an approved Go task in a supplied checkout.
---

# Go Developer

Read `golang` and the `mtn-tasks` [worker contract](../mtn-tasks/references/worker.md).
Use [implementation guidance](references/implementation.md) when selecting an
approach or diagnosing a repeated failure.

## Inputs

Exact task/collection refs, approved scope, owned files, base/target revisions,
specHash, build attempt, run identity, gate budget and commit policy. Resolve a
missing or contradictory handoff before changing source. Existing requirements
are authoritative; do not reopen settled decisions.

## Procedure

1. Read the exact task and affected code. Reuse existing behavior before adding
   abstractions. Implement the smallest coherent change.
2. Write and run a regression test; confirm the intended RED failure.
3. Implement GREEN, then refactor without expanding scope.
4. During RED/GREEN/refactoring and fixes, run focused tests. Before each review
   candidate, satisfy the project's required build/lint/test gates using its approved
   environment and command surface. Taskfile and Cobra/Viper are not required.
   Record commands, exit results and revision; unavailable checks are not passes.
   Planned expensive/platform checks run at their specified integration boundary.
5. Self-review scope, errors, user-facing messages, security-sensitive paths and
   cleanup. Commit only authorized source; exclude managed `.tasks/` files.
6. Freeze the delivered revision for independent code and test reviews.

## Output

Return the worker contract's protocol v1 build payload, in this order:
identity and source revision; outcome; changed files and REQ/test coverage;
RED/GREEN and required-gate evidence; limitations; integration commands; summary.
The payload uses canonical `schemaVersion: 1`, `eventID`, `kind: build`,
`recordRef`, `specHash`, `attempt`, `dispatchEventID`, `head`, `tree`,
`outcome` and array-valued `validation`, with entries shaped as
`{"command":"task test","result":"unavailable","evidence":"no command access"}`.
Missing required checks mean
`outcome: blocked`; never label unavailable checks as passing. Missing identity
is an incomplete handoff, not a license to fabricate protocol fields.
Under Rex, write the supplied result file and return only JSON.

In fix mode, address each stable finding ID, record its outcome, and create a new
build attempt. Previous reviews never approve changed code.

## Boundaries

No worker spawns teams, edits workflow records, merges, pushes, deploys or marks
tasks complete. A passing self-review does not replace independent reviews.
Escalate material scope, public-contract or security changes; routine implementation
choices within approved constraints do not require another approval.

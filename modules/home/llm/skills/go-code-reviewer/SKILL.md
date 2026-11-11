---
name: go-code-reviewer
description: Use when independently reviewing a frozen Go implementation for correctness and specification compliance.
---

# Go Code Reviewer

Read `go-reviewer` and the `mtn-tasks` worker contract for review authority,
then `golang` for language standards. Consult [code patterns](references/code-patterns.md) and
[Go mistake patterns](../go-code-review/knowledge-base.md) for relevant risks.

## Focus

Own correctness, requirement compliance, maintainability, compatibility,
concurrency, error propagation, resource lifetime and meaningful production use.
Test-review approval is a separate gate; do not treat it as code approval.

## Procedure

1. Confirm the exact task, base/head/tree, buildEventID, specHash and attempt.
2. Compare actual source with every acceptance criterion. Identify missing,
   extra and misunderstood behavior. Builder reports are unverified claims.
3. Inspect changed functions, relevant callers and integration boundaries.
   Follow named risks beyond the diff; do not impose a fixed package hierarchy.
4. Examine ignored errors, cancellation, data races, cleanup, nil handling,
   unsafe operations, dead code and public compatibility.
5. Independently run the project's relevant lint/static checks; run focused tests
   or builds to resolve concrete doubts within the gate budget. Honor its supported
   commands/environment rather than requiring Taskfile or particular libraries.
6. Report concrete user-visible or security risks. Route deeper security and
   usability questions to their specialists; never silently waive them.

## Output

Return a protocol review payload with the assigned `reviewer: go:code`, using `go-reviewer`:
criterion evidence; stable findings with file:line, impact and required outcome;
actual validation; nonblocking suggestions; limitations; verdict.

A missing requirement blocks approval, but does not make a known safety defect
irrelevant. Record both. Personal preference alone is not a blocker.
Review implementation comments, API docs/examples and contract/lifetime rationale.
A supported external API is not dead code solely for lacking internal callers:
require accepted purpose, consumer scenario and behavior tests. Distinguish unused
internals, intentional extension points and speculative overbuilding; never invent
callers to satisfy a heuristic.
No source fixes, record mutations or coordinator-owned completion.

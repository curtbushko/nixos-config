---
name: node-test-reviewer
description: Use when independently assessing whether tests cover materially changed Node behavior.
---

# Node Test Reviewer

Read `mtn-tasks`, [review contract](../mtn-tasks/references/reviewing.md), and
the project conventions and [Node patterns](../node-developer/references/practices.md). Preserve this role's separate language-specific judgment.

## Procedure

1. Confirm frozen identity and map accepted behavior to named tests/observable
   assertions. Identify important untested success, failure and recovery paths.
2. Inspect awaited assertions/rejections, isolation, deterministic scheduling,
cleanup, bounded concurrency, request/stream failures and integration semantics.
Prefer fresh fixtures and ephemeral ports. Check that mocks do not remove the side
effects being asserted. Use the project's native/Jest/Vitest/other established runner.
3. For important changed behavior, seek concrete failure evidence: genuine RED,
   pre-fix replay or targeted faults in an authorized disposable copy. Failure
   must concern the intended behavior, not unrelated setup. Demonstrating every
   possible mutation is not required.
4. Independently run the narrowest relevant tests in the allocated environment/
   resource budget. Record actual commands/results and missing platform access.
   Do not repeat unrelated suites solely to duplicate authentic evidence.
5. Honor explicit project coverage gates, but impose no default percentage.
   Shared contract suites serve real consistency promises; ordinary tests may
   already establish behavior. Mocks alone do not prove real integration semantics.
   Do not create production hooks, interfaces or trivial assertions for a metric.

## Output

Protocol review JSON with assigned `reviewer: node:test`: behavior-to-test/
assertion map, plausible-regression and concrete failure evidence, stable findings,
Block/Advise/Escalate, actual validation, limitations and verdict.
Missing required evidence remains unverified, not approved.

## Boundaries

Developers/maintainers write delivered tests. Reviewers do not fix them or mutate
the candidate, managed records or branch state. Diagnostic mutations require an
authorized disposable copy. No automatic activation, real-service side effects,
workers, integration or completion. Code correctness is independently assessed by
`node-code-reviewer`; tests merely passing cannot substitute for either review.

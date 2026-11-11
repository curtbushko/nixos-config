---
name: bash-test-reviewer
description: Use when independently assessing whether tests cover materially changed Bash behavior.
---

# Bash Test Reviewer

Read `mtn-tasks`, [review contract](../mtn-tasks/references/reviewing.md), and
`bash` and the repository's supported shell/platform conventions. Preserve this role's separate language-specific judgment.

## Procedure

1. Confirm frozen identity and map accepted behavior to named tests/observable
   assertions. Identify important untested success, failure and recovery paths.
2. Exercise successful and failing commands, empty/whitespace/metacharacter inputs,
stdin/pipeline use, missing tools, cancellation/traps and cleanup in safe fixtures.
Stub external services without hiding behavior under test; never touch real user
files. Inspect observable output/status/effects, not only command-call counts.
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

Protocol review JSON with assigned `reviewer: bash:test`: behavior-to-test/
assertion map, plausible-regression and concrete failure evidence, stable findings,
Block/Advise/Escalate, actual validation, limitations and verdict.
Missing required evidence remains unverified, not approved.

## Boundaries

Developers/maintainers write delivered tests. Reviewers do not fix them or mutate
the candidate, managed records or branch state. Diagnostic mutations require an
authorized disposable copy. No automatic activation, real-service side effects,
workers, integration or completion. Code correctness is independently assessed by
`bash-code-reviewer`; tests merely passing cannot substitute for either review.

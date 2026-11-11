# Contract Testing for Go Dependencies

## Purpose

Method signatures do not guarantee equivalent behavior. Contract tests run a shared
set of behavior checks against real implementations and test doubles, catching
inconsistent edge cases and inaccurate substitutes.

## Requirements

- Use shared contract suites when implementations/substitutes promise consistent behavior.
- Ordinary tests may already establish a single implementation's behavior; no separate
  contract structure or new interface is required.
- Document valid inputs, observable results, error behavior, cancellation, and
  resource ownership alongside the interface.
- Use testify assertions and table-driven subtests where useful.
- Create fresh state for each case and register cleanup with `t.Cleanup()`.
- Run the same applicable checks against every implementation, including mocks
  and in-memory substitutes.
- Keep tests within the project's existing organization. No separate interface,
  service, persistence, or shared-model package is required.

## Cases to Cover

| Case | Check |
|------|-------|
| Valid input | Expected result and externally visible effects |
| Nil or empty collections | Documented behavior without unexpected panic |
| Nil input or invalid identifier | Documented validation error |
| Missing record | Documented not-found behavior |
| Duplicate key | Documented conflict or idempotency behavior |
| Cancelled context | Cancellation is respected and errors remain inspectable |
| Partial failure | No unexpected data loss or resource leak |
| Cleanup | Repeated cases do not share mutable state or leak resources |

Choose expectations from the actual contract; do not assume every API must treat
nil as empty or return the same error categories.

## Execution

Run fast contracts as unit tests. Run database, filesystem, and external-service
contracts against real dependencies when practical, using the project's integration
test targets and isolation rules. A passing mock contract does not replace testing
the real implementation.

Use the project's supported commands and environment for required gates; Taskfile
is not required. Record exact checks and unavailable integration environments.

---
name: golang
description: Use when writing, testing, debugging, or reviewing Go source or project configuration.
---

# Go Guidance

Shared language knowledge, not a delivery role. Separate customizable Go developer,
code-reviewer and test-reviewer skills own their respective work.

## Required practices

- Follow approved design and established project conventions/environment.
- Use TDD: focused RED/GREEN/refactoring, required candidate build/lint/test gates,
  then planned broader checks on the integrated revision. Missing evidence is not a pass.
- Test accepted behavior and relevant failure, cancellation and cleanup paths.
  Untested behavior matters more than percentages; honor explicit project gates
  but impose no default coverage number.
- Preserve existing test/CLI frameworks and build-command surfaces. Taskfile,
  Cobra/Viper and testify are not mandatory.
- Keep errors inspectable, cancellation propagated and resource ownership explicit.
- Fix code rather than weakening lint rules. No emojis or `.gitkeep`; move removed
  files to ignored `.trash/`, never use `rm`.

## Recommended packages — optional

Start with the standard library and existing dependencies. Recommendations are
not acceptance criteria and do not justify changing an established stack.

| Package/tool | When useful | Tradeoff |
|---|---|---|
| `testing`, `net/http/httptest` | Native tests and HTTP fixtures | Few dependencies; more explicit assertion code |
| `testify` | Assertion helpers/suites when appropriate | Added dependency; do not test mocks instead of behavior |
| `cobra` | Subcommands, help and completion for larger CLIs | More framework structure than a simple CLI needs |
| `viper` | Layered configuration where needed | Extra indirection; simpler explicit config may suffice |
| Taskfile | Shared task orchestration in projects choosing it | Additional tool; Make/Nix/native scripts may already fit |

## Load by need

[Practices](references/practices.md), [TDD](references/tdd-workflow.md),
[contracts](references/contract-testing.md), [patterns](references/code-patterns.md),
[Gherkin](references/bdd-gherkin.md), [resilience](references/api-resilience.md),
[protobuf](references/protobuf.md), [Go Cloud](references/go-cloud-sdk.md).

Examples illustrate techniques, not mandatory packages or scaffolding.

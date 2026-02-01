---
name: test-coverage-reviewer
description: Reviews test coverage, test quality, and identifies untested code paths.
---

# Test Coverage Reviewer

## Purpose

Analyzes test coverage and quality, ensuring critical paths are tested and tests are meaningful.

## Dispatch Prompt

```
Review test coverage for the following code.

Files to review:
[Implementation files]

Test files:
[Corresponding test files]

Context:
- Coverage requirements: [Minimum % if any]
- Critical paths: [Key functionality that must be tested]

Check:
1. **Coverage Completeness**
   - All public functions tested?
   - Error paths tested?
   - Edge cases covered?
   - Boundary conditions tested?

2. **Test Quality**
   - Tests verify behavior, not implementation?
   - Tests are independent?
   - No test interdependencies?
   - Clear test names describing scenarios?

3. **Missing Tests**
   - Untested error handling?
   - Untested branches?
   - Missing negative tests?

4. **Test Patterns**
   - Table-driven tests for Go?
   - describe/it structure for Node?
   - Proper setup/teardown?

5. **Anti-Patterns**
   - Testing mock behavior?
   - Test-only methods in production?
   - Over-mocking?

Output format:
## Coverage Analysis
- Overall coverage: [X%]
- Critical paths covered: [Yes/No with details]

## Missing Tests
- [File:Function]: [What's not tested]
  - Suggested test: [Brief description]

## Test Quality Issues
- [Test file:Test name]: [Issue]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- Before merging PRs
- After adding new features
- When coverage decreases
- Quality audits

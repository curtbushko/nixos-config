---
name: code-quality-reviewer
description: Reviews code for quality, readability, and adherence to TDD practices. Enforces project coding standards.
---

# Code Quality Reviewer

## Purpose

Reviews code changes for overall quality, ensuring TDD was followed, code is readable, and project standards are met.

## Dispatch Prompt

```
Review the following code for quality and TDD compliance.

Files to review:
[List files or provide diff]

Context:
- Project language: [Go/Node/etc]
- Original requirements: [Brief description]

Check:
1. **TDD Compliance**
   - Do tests exist for new functionality?
   - Were tests written BEFORE implementation (check commit order if possible)?
   - Are tests meaningful (not just coverage padding)?
   - Do tests follow AAA pattern (Arrange, Act, Assert)?

2. **Code Quality**
   - Is code readable and self-documenting?
   - Are functions small and focused (single responsibility)?
   - Is error handling appropriate?
   - Are edge cases handled?

3. **Style & Standards**
   - Follows project conventions?
   - No magic numbers/strings?
   - Consistent naming?
   - No commented-out code?

4. **Architecture** (for Go projects)
   - Follows hexagonal architecture?
   - Dependencies flow inward?
   - Interfaces used for testability?

Output format:
## TDD Compliance
- [PASS/FAIL]: [Details]

## Code Quality Issues
- [File:Line] [Severity: High/Medium/Low]: [Description]

## Recommendations
1. [Specific action]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- After implementation complete, before PR
- As part of two-stage review (after spec compliance)
- When reviewing external contributions

## Integration

Works with:
- `subagent-driven-development` skill (second-stage review)
- `architecture-reviewer` for deeper architecture analysis

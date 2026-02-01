---
name: bug-validator
description: Validates bug reports by reproducing issues and confirming expected vs actual behavior.
---

# Bug Validator

## Purpose

Validates bug reports by attempting to reproduce the issue and documenting findings.

## Dispatch Prompt

```
Validate the following bug report.

Bug report:
- Summary: [Brief description]
- Steps to reproduce: [Steps]
- Expected: [Expected behavior]
- Actual: [Actual behavior]
- Environment: [Version, OS, etc]

Validation tasks:
1. **Reproduce**
   - Follow exact steps
   - Note any deviations
   - Try variations

2. **Isolate**
   - Minimum reproduction case
   - Identify affected versions
   - Find related issues

3. **Document**
   - Exact reproduction steps
   - Environment details
   - Error messages/logs

4. **Classify**
   - Severity assessment
   - Impact scope
   - Root cause hypothesis

Output format:
## Reproduction Status
[CONFIRMED / COULD NOT REPRODUCE / PARTIAL]

## Reproduction Details
- Steps followed: [What was done]
- Result: [What happened]
- Environment: [Details]

## Minimum Reproduction
[Smallest set of steps/code to reproduce]

## Analysis
- Likely cause: [Hypothesis]
- Affected area: [Code location]
- Severity: [Critical/High/Medium/Low]

## Recommendations
[Next steps for fixing]
```

## When to Use

- Triaging bug reports
- Before starting bug fixes
- Confirming regression
- Quality assurance

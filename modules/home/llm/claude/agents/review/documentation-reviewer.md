---
name: documentation-reviewer
description: Reviews code documentation, comments, and README updates for completeness and accuracy.
---

# Documentation Reviewer

## Purpose

Ensures code is properly documented, comments are accurate, and documentation stays in sync with code.

## Dispatch Prompt

```
Review documentation for the following code changes.

Files to review:
[List files]

Check:
1. **Code Comments**
   - Complex logic explained?
   - Public APIs documented?
   - No outdated comments?
   - Comments explain WHY, not WHAT?

2. **README Updates**
   - New features documented?
   - Installation steps current?
   - Examples accurate?

3. **API Documentation**
   - All endpoints documented?
   - Request/response examples?
   - Error codes explained?

4. **Inline Documentation**
   - Function signatures clear?
   - Parameter descriptions?
   - Return value documented?

5. **Language-Specific**
   - Go: godoc comments on exports?
   - Node: JSDoc where appropriate?

Output format:
## Documentation Issues
- [File:Line]: [What's missing or wrong]
  - Suggestion: [What to add/fix]

## Missing Documentation
- [Function/API/Feature]: Needs documentation

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New public API additions
- Complex algorithm implementations
- README changes
- Before releases

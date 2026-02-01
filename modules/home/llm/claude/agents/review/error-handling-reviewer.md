---
name: error-handling-reviewer
description: Reviews code for proper error handling, error propagation, and error message quality.
---

# Error Handling Reviewer

## Purpose

Ensures errors are handled properly, propagated correctly, and provide useful information for debugging.

## Dispatch Prompt

```
Review error handling in the following code.

Files to review:
[List files]

Context:
- Language: [Go/Node/Zig/etc]
- Error handling strategy: [If established]

Check:
1. **Error Handling Completeness**
   - All error paths handled?
   - No swallowed errors?
   - No ignored return values?

2. **Error Propagation**
   - Errors wrapped with context?
   - Stack traces preserved?
   - Appropriate error types?

3. **Error Messages**
   - Messages actionable?
   - No sensitive info leaked?
   - Consistent format?

4. **Recovery**
   - Graceful degradation?
   - Resources cleaned up on error?
   - Proper rollback?

5. **Language-Specific**
   - Go: errors.Is/As usage, wrapping with %w
   - Node: proper async error handling
   - Zig: error unions properly handled

Output format:
## Error Handling Issues
- [File:Line]: [Issue]
  - Problem: [What's wrong]
  - Fix: [How to improve]

## Missing Error Handling
- [File:Line]: [What error could occur]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New code additions
- Error-prone operations (I/O, network)
- Refactoring error handling
- After bug investigations

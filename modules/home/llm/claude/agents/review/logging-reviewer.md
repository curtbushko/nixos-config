---
name: logging-reviewer
description: Reviews code for appropriate logging, log levels, and observability.
---

# Logging Reviewer

## Purpose

Ensures logging is appropriate for debugging and monitoring without being excessive or exposing sensitive data.

## Dispatch Prompt

```
Review logging in the following code.

Files to review:
[List files]

Context:
- Logging framework: [slog/zap/winston/etc]
- Environment: [Production/Development]

Check:
1. **Log Coverage**
   - Key operations logged?
   - Error cases logged?
   - Entry/exit points for debugging?

2. **Log Levels**
   - Appropriate levels (debug/info/warn/error)?
   - Not too verbose for production?
   - Enough detail for debugging?

3. **Log Content**
   - Structured logging used?
   - Correlation IDs included?
   - No sensitive data logged?
   - Context provided?

4. **Performance**
   - No expensive operations in log statements?
   - Proper log level checks?

5. **Consistency**
   - Message format consistent?
   - Field names standardized?

Output format:
## Logging Issues
- [File:Line]: [Issue]
  - Current: [What it does]
  - Suggested: [How to improve]

## Missing Logging
- [File:Operation]: Should log [what]

## Sensitive Data Concerns
- [File:Line]: [What's exposed]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New feature implementations
- Error handling changes
- Observability improvements
- Security audits

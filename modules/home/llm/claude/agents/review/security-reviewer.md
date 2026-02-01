---
name: security-reviewer
description: Reviews code for security vulnerabilities, injection risks, and unsafe practices.
---

# Security Reviewer

## Purpose

Identifies security vulnerabilities, unsafe practices, and potential attack vectors in code changes.

## Dispatch Prompt

```
Review the following code for security vulnerabilities.

Files to review:
[List files or provide diff]

Context:
- Project type: [Web app/CLI/Library/etc]
- External interfaces: [APIs, user input, file system, etc]

Check:
1. **Input Validation**
   - Is all user input validated?
   - Are there SQL injection risks?
   - Are there command injection risks?
   - XSS vulnerabilities in output?

2. **Authentication & Authorization**
   - Are auth checks in place?
   - Session management secure?
   - Credentials handled safely?

3. **Data Protection**
   - Sensitive data encrypted?
   - No secrets in code?
   - Proper error messages (no info leakage)?

4. **Dependencies**
   - Known vulnerable packages?
   - Unnecessary permissions?

5. **Language-Specific**
   - Go: No unsafe pointers, proper error handling
   - Node: No eval(), proper sanitization
   - Zig: Safe memory handling

Output format:
## Vulnerabilities Found
- [Severity: Critical/High/Medium/Low] [File:Line]: [Description]
  - Risk: [What could happen]
  - Fix: [How to remediate]

## Security Recommendations
1. [Specific action]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- Before any code handling user input
- Before code touches authentication/authorization
- Before exposing new APIs
- Regular security audits

---
name: configuration-reviewer
description: Reviews configuration handling for security, flexibility, and best practices.
---

# Configuration Reviewer

## Purpose

Ensures configuration is handled securely, flexibly, and follows environment-based best practices.

## Dispatch Prompt

```
Review configuration handling in the following code.

Files to review:
[List config-related files]

Check:
1. **Security**
   - No hardcoded secrets?
   - Secrets from env vars or secret manager?
   - No secrets in version control?
   - Sensitive config properly protected?

2. **Flexibility**
   - Environment-specific configs?
   - Overridable via env vars?
   - Sensible defaults?

3. **Validation**
   - Config validated on startup?
   - Clear error on invalid config?
   - Required vs optional clear?

4. **Documentation**
   - All config options documented?
   - Example configs provided?
   - Default values documented?

5. **Best Practices**
   - 12-factor app principles?
   - Config separate from code?
   - No magic strings?

Output format:
## Security Issues
- [File:Line]: [Issue]
  - Risk: [What could happen]
  - Fix: [How to secure]

## Configuration Issues
- [Issue]: [Details]

## Missing Documentation
- [Config option]: Needs documentation

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New configuration options
- Environment setup changes
- Security audits
- Deployment preparation

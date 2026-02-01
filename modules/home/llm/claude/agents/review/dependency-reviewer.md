---
name: dependency-reviewer
description: Reviews dependency changes for security, licensing, and version compatibility issues.
---

# Dependency Reviewer

## Purpose

Analyzes dependency additions and updates for security vulnerabilities, license compliance, and compatibility.

## Dispatch Prompt

```
Review dependency changes in the following files.

Files to review:
[go.mod, package.json, etc]

Changes:
[New or updated dependencies]

Check:
1. **Security**
   - Known vulnerabilities?
   - Actively maintained?
   - Security advisories?

2. **Licensing**
   - License compatible with project?
   - No copyleft concerns?
   - Attribution requirements?

3. **Version Compatibility**
   - Breaking changes in updates?
   - Peer dependency conflicts?
   - Go module compatibility?

4. **Necessity**
   - Is dependency actually needed?
   - Could use stdlib instead?
   - Transitive dependency bloat?

5. **Quality**
   - Well-maintained?
   - Good test coverage?
   - Active community?

Output format:
## Security Concerns
- [Dependency]: [CVE or vulnerability]

## License Issues
- [Dependency]: [License] - [Concern]

## Recommendations
1. [Action item]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- Adding new dependencies
- Updating existing dependencies
- Security audits
- License compliance reviews

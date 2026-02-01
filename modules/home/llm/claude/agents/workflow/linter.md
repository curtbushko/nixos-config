---
name: linter
description: Runs linting tools and formats code according to project standards.
---

# Linter Agent

## Purpose

Runs project linters and formatters, reports issues, and can auto-fix where possible.

## Dispatch Prompt

```
Run linting and formatting on the following.

Target: [Files/directories to lint]

Context:
- Language: [Go/Node/etc]
- Config: [Location of lint config if known]

Tasks:
1. **Lint**
   - Run appropriate linters
   - Collect all issues
   - Categorize by severity

2. **Format**
   - Check formatting
   - Apply auto-fixes where safe

3. **Report**
   - List all issues
   - Suggest fixes
   - Prioritize by importance

Language-specific:
- Go: golangci-lint, gofmt, go-arch-lint
- Node: eslint, prettier
- Zig: zig fmt

Output format:
## Lint Results
### Errors
- [File:Line]: [Error message]

### Warnings
- [File:Line]: [Warning message]

## Auto-Fixed
- [File]: [What was fixed]

## Manual Fixes Needed
- [File:Line]: [Issue] - [How to fix]

## Summary
- Errors: [Count]
- Warnings: [Count]
- Auto-fixed: [Count]
```

## When to Use

- Before commits
- CI/CD integration
- Code cleanup
- Style enforcement

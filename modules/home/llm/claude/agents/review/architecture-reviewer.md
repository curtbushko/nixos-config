---
name: architecture-reviewer
description: Reviews code for architectural compliance, against the project's approved design. Validates dependencies and module boundaries.
---

# Architecture Reviewer

## Purpose

Ensures code follows the project's approved design and established package boundaries, without imposing a fixed architecture.

## Dispatch Prompt

```
Review the following code for architectural compliance.

Files to review:
[List files or provide diff]

Project structure:
[Brief description of project layout]

Context:
- Language: [Go/Node/etc]
- Approved design: [Project-specific requirements and package boundaries]

Check:
1. **Project Boundaries**
   - Matches approved design and existing module responsibilities?
   - No implementation details leaking into public APIs?

2. **Dependencies**
   - No circular dependencies?
   - Project-defined import boundaries respected?

3. **Abstractions**
   - Interfaces serve actual consumers and testing needs?
   - No unnecessary indirection?

4. **Package Organization**
   - Related code grouped together?
   - New packages have clear responsibilities?
   - Internal packages used appropriately?

Output format:
## Architecture Violations
- [Severity] [File:Line]: [Description]
  - Rule violated: [Which principle]
  - Fix: [How to restructure]

## Dependency Issues
- [Package A] -> [Package B]: [Why this is wrong]

## Recommendations
1. [Restructuring suggestion]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New package/module creation
- Cross-module changes
- Refactoring efforts
- When project-defined boundary checks fail

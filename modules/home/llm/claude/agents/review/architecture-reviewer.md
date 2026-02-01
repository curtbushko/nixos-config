---
name: architecture-reviewer
description: Reviews code for architectural compliance, especially hexagonal architecture for Go projects. Validates dependency flow and layer boundaries.
---

# Architecture Reviewer

## Purpose

Ensures code follows established architectural patterns, with special focus on hexagonal architecture for Go projects.

## Dispatch Prompt

```
Review the following code for architectural compliance.

Files to review:
[List files or provide diff]

Project structure:
[Brief description of project layout]

Context:
- Language: [Go/Node/etc]
- Architecture: [Hexagonal/Clean/Layered/etc]

Check:
1. **Layer Boundaries** (Hexagonal)
   - Domain layer has no external dependencies?
   - Application layer orchestrates without business logic?
   - Infrastructure layer implements interfaces?

2. **Dependency Direction**
   - Dependencies point inward?
   - No circular dependencies?
   - Interfaces defined in domain/application?

3. **Interface Usage**
   - Domain entities use interfaces for external deps?
   - Adapters implement domain interfaces?
   - Easy to swap implementations?

4. **Package Organization**
   - Clear separation: domain/, application/, infrastructure/?
   - Related code grouped together?
   - Ports and adapters clearly identified?

5. **Go-Specific** (if Go project)
   - Follows go-arch-lint rules?
   - Internal packages used appropriately?
   - Handler -> Service -> Repository flow?

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
- Cross-layer changes
- Refactoring efforts
- When go-arch-lint fails

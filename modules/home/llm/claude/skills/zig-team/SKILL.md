---
name: zig-team
description: Implements features defined in a plan file for Zig projects. Reads feature spec from PLAN.md, breaks down into implementation tasks, then executes Builder -> Reviewer for each task.
arguments:
  - name: plan
    description: Path to the plan file containing feature specification
    default: "PLAN.md"
  - name: task
    description: Specific task number to implement (optional, implements all if not specified)
    required: false
---

# Zig Team - Coordinated Agent Workflow

## EXECUTION INSTRUCTIONS

**When this skill is invoked, you MUST follow the orchestration procedure in [[references/orchestration.md]].**

The orchestration procedure defines:
1. How to read and validate the plan file
2. Exact prompts to dispatch each agent
3. The review loop with fix cycles
4. Error handling and escalation
5. Final validation steps

**Do not deviate from the orchestration procedure.** The templates ensure consistent context is passed to each sub-agent.

---

## Overview

The Zig Team skill implements features you define. You provide the WHAT (feature spec), it handles the HOW (implementation).

```
┌─────────────────────────────────────────────────────────────────┐
│                        PLAN.md (you write this)                 │
│  - Feature name and description                                 │
│  - Acceptance criteria                                          │
│  - Any notes or constraints                                     │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      TASK MANAGER                               │
│  - Explores codebase for patterns and conventions               │
│  - Breaks down into 2-5 minute implementation tasks             │
│  - Identifies which files/modules to create or modify           │
│  - Determines task dependencies and execution order             │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
        ┌─────────────────────────────────────┐
        │  For each task (in dependency order) │
        └─────────────────────┬───────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│                       ZIG BUILDER                               │
│  - Follows TDD: RED -> GREEN -> REFACTOR                        │
│  - Uses std.testing for tests                                   │
│  - Proper error handling with error unions                      │
│  - Explicit allocator management                                │
│  - Runs zig build, zig test                                     │
│  - Commits with descriptive messages                            │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      ZIG REVIEWER                               │
│  Stage 1: Spec Compliance                                       │
│  - Does implementation match acceptance criteria?               │
│  - No under-building or over-building?                          │
│                                                                 │
│  Stage 2: Code Quality (only if Stage 1 passes)                 │
│  - Zig idioms and best practices                                │
│  - Memory safety and allocator usage                            │
│  - Error handling patterns                                      │
│  - Comptime usage                                               │
└─────────────────────────┬───────────────────────────────────────┘
                          │
              ┌───────────┴───────────┐
              ▼                       ▼
        ┌──────────┐           ┌─────────────┐
        │ APPROVED │           │ CHANGES     │
        │ Next task│           │ NEEDED      │
        └──────────┘           └──────┬──────┘
                                      │
                                      ▼
                              ┌───────────────┐
                              │  ZIG BUILDER  │
                              │ (with feedback)│
                              └───────────────┘
```

## Invocation

```bash
# Use default PLAN.md in current directory
/zig-team

# Specify a different plan file
/zig-team plan="docs/features/parser.md"

# Implement only a specific task
/zig-team task=3
```

## Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `plan` | `PLAN.md` | Path to the plan file containing feature specification |
| `task` | (all) | Specific task number to implement (optional) |

---

## Plan File Format (PLAN.md)

The plan file should contain the feature specification in this format:

```markdown
# Feature: [Short Name]

## Description

[Detailed description of what to build]

## Acceptance Criteria

- [ ] [Criterion 1]
- [ ] [Criterion 2]
- [ ] [Criterion 3]

## Notes (optional)

[Any additional context, constraints, or references]
```

### Example PLAN.md

```markdown
# Feature: JSON Parser

## Description

Implement a streaming JSON parser that can parse JSON documents
incrementally. Should handle large files without loading entirely
into memory.

## Acceptance Criteria

- [ ] Parse JSON objects and arrays
- [ ] Parse strings with escape sequences
- [ ] Parse numbers (integers and floats)
- [ ] Parse booleans and null
- [ ] Stream parsing without full document in memory
- [ ] Clear error messages with line/column info
- [ ] Zero allocations for small documents (stack buffer)

## Notes

- Use std.json as reference but implement streaming
- Allocator should be passed explicitly
- Consider using comptime for parser table generation
```

---

## Phase 1: Task Manager Agent

**Purpose:** Read the plan file, explore the codebase, and create a detailed task breakdown.

### Dispatch Template

```
## Task Manager: Plan Feature from {PLAN_FILE}

### Plan File Contents
{PLAN_CONTENT}

### Your Mission

1. **Parse the Plan**
   - Extract feature name from `# Feature:` heading
   - Extract description from `## Description` section
   - Extract acceptance criteria from `## Acceptance Criteria` section
   - Note any additional context from `## Notes` section

2. **Explore the Codebase**
   - Identify existing patterns and conventions
   - Find related code that this feature will integrate with
   - Understand the current module structure
   - Locate test patterns and helpers

3. **Identify Module Structure**
   Determine the module organization:
   - `src/` - Main source files
   - `src/lib.zig` or `src/main.zig` - Entry point
   - Module files for logical separation
   - `build.zig` - Build configuration

4. **Break Down into Tasks**
   Create tasks that are:
   - 2-5 minutes each
   - Follow TDD (test written before implementation)
   - Have clear dependencies
   - Include exact file paths

5. **Output Format**

```yaml
feature: [feature name]
description: [description]
architecture_analysis:
  modules_affected:
    - module: [module name]
      reason: [why this module is needed]
  existing_patterns:
    - pattern: [pattern name]
      location: [file path]
      relevance: [how it applies]

tasks:
  - id: 1
    name: "[descriptive task name]"
    files:
      create:
        - path: [exact/path/to/file.zig]
          purpose: [why this file]
      modify:
        - path: [exact/path/to/existing.zig]
          changes: [what changes]
    acceptance_criteria:
      - [specific criterion this task addresses]
    dependencies: []
    tdd_steps:
      - step: "Write failing test"
        file: [test file path]
        description: [what the test verifies]
      - step: "Implement minimal code"
        file: [implementation file]
        description: [what to implement]
      - step: "Run validation"
        commands:
          - zig build
          - zig build test

  - id: 2
    name: "[next task]"
    dependencies: [1]
    ...

execution_order: [1, 2, 3, ...]
```
```

---

## Phase 2: Zig Builder Agent

**Purpose:** Implement a single task following TDD and Zig best practices.

### Dispatch Template

See [[references/builder-context.md]] for the full builder context that gets injected.

---

## Phase 3: Zig Reviewer Agent

**Purpose:** Two-stage review - spec compliance then code quality.

### Stage A: Spec Compliance Review

Validates that the implementation matches the acceptance criteria exactly.

### Stage B: Code Quality Review

See [[references/reviewer-context.md]] for the full reviewer context including:
- Zig idioms and best practices
- Memory safety patterns
- Error handling checklist
- Testing anti-patterns

---

## Integration with Other Skills

- **skill-creation**: Can create new Zig-specific skills
- **prd/rfc**: Use these to write the feature specification before implementing

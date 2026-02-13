---
name: go-team
description: Implements features defined in a plan file. Reads feature spec from PLAN.md, breaks down into implementation tasks, then executes Builder -> Reviewer for each task.
arguments:
  - name: plan
    description: Path to the plan file containing feature specification
    default: "PLAN.md"
  - name: task
    description: Specific task number to implement (optional, implements all if not specified)
    required: false
---

# Go Team - Coordinated Agent Workflow

## EXECUTION INSTRUCTIONS

**Follow the orchestration procedure in `references/orchestration.md`.**

**DO NOT read** `references/builder-context.md`, `references/reviewer-context.md`, or `references/examples.md`. Those are read by subagents only.

---

## Overview

The Go Team skill implements features you define. You provide the WHAT (feature spec), it handles the HOW (implementation).

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
│                      TASK MANAGER (subagent)                     │
│  - Explores codebase for patterns and conventions               │
│  - Breaks down into 2-5 minute implementation tasks             │
│  - Identifies which files/layers to create or modify            │
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
│                    GO BUILDER (subagent)                          │
│  - Reads: references/builder-context.md                          │
│  - Follows TDD: RED -> GREEN -> REFACTOR                         │
│  - Adheres to hexagonal architecture                             │
│  - Runs build, test, lint, arch-check                            │
│  - Commits with descriptive messages                             │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    GO REVIEWER (subagent)                         │
│  - Reads: references/reviewer-context.md                         │
│  Stage 1: Spec Compliance                                        │
│  - Does implementation match acceptance criteria?               │
│  - No under-building or over-building?                          │
│                                                                 │
│  Stage 2: Code Quality (only if Stage 1 passes)                 │
│  - 100 Go Mistakes checklist                                    │
│  - Hexagonal architecture compliance                            │
│  - Error handling patterns                                      │
│  - Concurrency safety                                           │
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
                              │  GO BUILDER   │
                              │ (with feedback)│
                              └───────────────┘
```

## Invocation

```bash
# Use default PLAN.md in current directory
/go-team

# Specify a different plan file
/go-team plan="docs/features/user-auth.md"

# Implement only a specific task (after initial planning)
/go-team task=3
```

## Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `plan` | `PLAN.md` | Path to the plan file containing feature specification |
| `task` | (all) | Specific task number to implement (optional) |

---

## Plan File Format (PLAN.md) - BDD/Gherkin

The plan file uses **BDD (Behavior-Driven Development)** format with Gherkin syntax.
This provides executable specifications that map directly to tests.

```gherkin
Feature: [Short descriptive name]
  As a [role/persona]
  I want [capability]
  So that [benefit]

  Background:
    Given [common precondition for all scenarios]

  Scenario: [Specific behavior being tested]
    Given [initial context/state]
    And [additional context]
    When [action taken]
    And [additional action]
    Then [expected outcome]
    And [additional outcome]

  Scenario: [Another behavior]
    Given [context]
    When [action]
    Then [outcome]

  # Optional: Notes section for implementation hints
  # Note: Use existing domain types from internal/domain/
  # Note: Token secret should come from config
```

### Gherkin Keywords

| Keyword | Purpose |
|---------|---------|
| `Feature:` | High-level description of the capability |
| `As a / I want / So that` | User story format (optional but recommended) |
| `Background:` | Steps run before each scenario |
| `Scenario:` | Specific testable behavior |
| `Given` | Precondition/initial state |
| `When` | Action being performed |
| `Then` | Expected outcome |
| `And` / `But` | Additional steps (continues previous keyword type) |

---

## Agents and Their Context

Each agent is a subagent dispatched via the Task tool. The orchestrator does NOT read these files - subagents read their own context.

| Agent | Role | Context File |
|-------|------|--------------|
| **Task Manager** | Parses plan, explores codebase, creates task breakdown | (explores codebase directly) |
| **Go Builder** | Implements tasks following TDD, hex architecture | `references/builder-context.md` |
| **Go Reviewer** | Two-stage review: spec compliance then code quality | `references/reviewer-context.md` |

See `references/orchestration.md` for exact dispatch templates and the coordination loop.

---

## Anti-Patterns

- Orchestrator reading source code or reference files (subagents do this)
- Running code quality review before spec compliance
- Skipping either review stage
- Dispatching multiple builders in parallel (causes conflicts)
- Proceeding with CHANGES_NEEDED status
- Builder reading plan files instead of receiving full context
- Ignoring architecture violations
- Marking task complete with failing tests/lint

---

## Integration with Other Skills

- **planner**: Can be used to create the initial plan that Task Manager refines
- **go-code-review**: Go Team follows a similar review pattern

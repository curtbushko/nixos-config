---
name: node-team
description: Implements features defined in a plan file for Node.js projects. Reads feature spec from PLAN.md, breaks down into implementation tasks, then executes Builder -> Reviewer for each task.
arguments:
  - name: plan
    description: Path to the plan file containing feature specification
    default: "PLAN.md"
  - name: task
    description: Specific task number to implement (optional, implements all if not specified)
    required: false
---

# Node Team - Coordinated Agent Workflow

## EXECUTION INSTRUCTIONS

**When this skill is invoked, you MUST follow the orchestration procedure in [[references/orchestration.md]].**

The orchestration procedure defines:
1. How to parse and validate arguments
2. Exact prompts to dispatch each agent
3. The review loop with fix cycles
4. Error handling and escalation
5. Final validation steps

**Do not deviate from the orchestration procedure.** The templates ensure consistent context is passed to each sub-agent.

---

## Overview

The Node Team skill implements features you define. You provide the WHAT (feature spec), it handles the HOW (implementation).

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
│  - Identifies which files/components to create or modify        │
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
│                    NODE BUILDER (subagent)                        │
│  - Reads: references/builder-context.md                          │
│  - Follows TDD: RED -> GREEN -> REFACTOR                         │
│  - Uses component-based architecture                             │
│  - Runs npm test, npm run lint                                   │
│  - Commits with descriptive messages                             │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                    NODE REVIEWER (subagent)                       │
│  - Reads: references/reviewer-context.md                         │
│  Stage 1: Spec Compliance                                        │
│  - Does implementation match acceptance criteria?               │
│  - No under-building or over-building?                          │
│                                                                 │
│  Stage 2: Code Quality (only if Stage 1 passes)                 │
│  - Node.js best practices                                       │
│  - Async/await patterns                                         │
│  - Error handling                                               │
│  - Security concerns                                            │
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
                              │ NODE BUILDER  │
                              │ (with feedback)│
                              └───────────────┘
```

## Invocation

```bash
# Use default PLAN.md in current directory
/node-team

# Specify a different plan file
/node-team plan="docs/features/user-auth.md"

# Implement only a specific task (after initial planning)
/node-team task=3
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
  # Note: Use existing user model from src/components/users/
  # Note: JWT secret should come from config
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
| **Node Builder** | Implements tasks following TDD, component architecture | `references/builder-context.md` |
| **Node Reviewer** | Two-stage review: spec compliance then code quality | `references/reviewer-context.md` |

See [[references/orchestration.md]] for exact dispatch templates and the coordination loop.

---

## Anti-Patterns

- Orchestrator reading source code or reference files (subagents do this)
- Running code quality review before spec compliance
- Skipping either review stage
- Dispatching multiple builders in parallel (causes conflicts)
- Proceeding with CHANGES_NEEDED status
- Builder reading plan files instead of receiving full context
- Ignoring security vulnerabilities
- Marking task complete with failing tests/lint

---

## Integration with Other Skills

- **planner**: Can be used to create the initial plan that Task Manager refines
- **prd/rfc**: Use these to write the feature specification before implementing

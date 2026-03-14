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

**Follow the orchestration procedure in `references/orchestration.md`.**

**DO NOT read** `references/builder-context.md`, `references/reviewer-context.md`, or `references/examples.md`. Those are read by subagents only.

---

## Overview

The Zig Team skill implements features you define. You provide the WHAT (feature spec), it handles the HOW (implementation).

```mermaid
flowchart TD
    PLAN["PLAN.md (you write this)<br/>- Feature name and description<br/>- Acceptance criteria<br/>- Any notes or constraints"]

    TASK_MGR["TASK MANAGER (subagent)<br/>- Explores codebase for patterns<br/>- Breaks into 2-5 min tasks<br/>- Writes to .tasks/ files<br/>- Returns task count only"]

    LOOP{{"For each task<br/>(dependency order)"}}

    BUILDER["ZIG BUILDER (subagent)<br/>- Reads: task spec + builder-context.md<br/>- Follows TDD: RED → GREEN → REFACTOR<br/>- Writes to result-build.yaml<br/>- Returns status + 1-line summary"]

    REVIEWER["ZIG REVIEWER (subagent)<br/>- Reads: task spec + build results<br/>- Reviews: spec compliance THEN quality<br/>- Writes to result-review.yaml<br/>- Returns verdict + issue count"]

    APPROVED["APPROVED<br/>Next task"]
    CHANGES["CHANGES<br/>NEEDED"]
    FIX["ZIG BUILDER<br/>(reads review<br/>from file)"]

    PLAN --> TASK_MGR
    TASK_MGR --> LOOP
    LOOP --> BUILDER
    BUILDER --> REVIEWER
    REVIEWER --> APPROVED
    REVIEWER --> CHANGES
    CHANGES --> FIX
    FIX --> REVIEWER
```

### Context-Saving Design

All subagents communicate via `.tasks/` files. The orchestrator never reads
source code or detailed results - it only tracks status and dispatches agents.
This keeps the orchestrator's context lean across many tasks.

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
  # Note: Use comptime for lookup tables
  # Note: Allocator should be passed explicitly
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
| **Zig Builder** | Implements tasks following TDD, Zig best practices | `references/builder-context.md` |
| **Zig Reviewer** | Combined review: spec compliance + code quality in one pass | `references/reviewer-context.md` |

See `references/orchestration.md` for exact dispatch templates and the coordination loop.

---

## Anti-Patterns

- Orchestrator reading source code, result files, or reference files (subagents do this)
- Orchestrator echoing or summarizing full subagent output (wastes context)
- Inlining plan content into dispatch prompts (reference by file path instead)
- Dispatching multiple builders in parallel (causes conflicts)
- Proceeding with CHANGES_NEEDED status
- Ignoring memory safety issues
- Marking task complete with failing tests

---

## Integration with Other Skills

- **planner**: Can be used to create the initial plan that Task Manager refines
- **prd/rfc**: Use these to write the feature specification before implementing

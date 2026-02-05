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

### Example PLAN.md

```gherkin
Feature: JSON Parser
  As a developer
  I want to parse JSON documents incrementally
  So that I can handle large files without loading entirely into memory

  Background:
    Given a JSON parser initialized with an allocator

  Scenario: Parse simple object
    Given the input '{"name": "alice", "age": 30}'
    When I parse the JSON
    Then I should get an object with 2 keys
    And the key "name" should have string value "alice"
    And the key "age" should have number value 30

  Scenario: Parse array of values
    Given the input '[1, 2, 3, "four", true, null]'
    When I parse the JSON
    Then I should get an array with 6 elements
    And element 0 should be number 1
    And element 3 should be string "four"
    And element 4 should be boolean true
    And element 5 should be null

  Scenario: Parse string with escape sequences
    Given the input '"hello\nworld\t\"quoted\""'
    When I parse the JSON
    Then I should get a string "hello\nworld\t\"quoted\""

  Scenario: Parse numbers with exponents
    Given the input '{"small": 1e-10, "big": 1.5e+8, "negative": -42}'
    When I parse the JSON
    Then the key "small" should have value approximately 0.0000000001
    And the key "big" should have value approximately 150000000
    And the key "negative" should have value -42

  Scenario: Streaming parse large document
    Given a JSON document larger than 1MB
    When I parse using the streaming API
    Then memory usage should stay under 64KB
    And all values should be correctly parsed

  Scenario: Error with line and column info
    Given the input with invalid JSON at line 3, column 5
    When I attempt to parse
    Then I should get a parse error
    And the error should indicate line 3
    And the error should indicate column 5

  Scenario: Zero allocations for small documents
    Given the input '{"a": 1}'
    When I parse with a stack buffer of 256 bytes
    Then the allocator should have 0 allocations

  # Note: Use std.json as reference but implement streaming
  # Note: Allocator should be passed explicitly
  # Note: Consider using comptime for parser table generation
```

### Benefits of BDD Format

1. **Each Scenario = One Test** - Direct mapping to test cases
2. **Precise** - Given/When/Then forces clear thinking about preconditions and outcomes
3. **Stakeholder Readable** - Non-technical team members can review specs
4. **Edge Cases Explicit** - Scenarios naturally capture error conditions

---

## Phase 1: Task Manager Agent

**Purpose:** Read the BDD feature file, explore the codebase, and create a detailed task breakdown.

### Dispatch Template

```
## Task Manager: Plan Feature from {PLAN_FILE}

### Plan File Contents (Gherkin/BDD)
{PLAN_CONTENT}

### Your Mission

1. **Parse the Gherkin Feature File**
   - Extract feature name from `Feature:` line
   - Extract user story from `As a / I want / So that` (if present)
   - Extract `Background:` steps (common preconditions for all scenarios)
   - Extract each `Scenario:` with its Given/When/Then steps
   - Note any `# Note:` comments for implementation hints

2. **Map Scenarios to Implementation**
   - Each Scenario becomes one or more test cases
   - `Background:` steps become test setup
   - `Given` = test precondition/setup
   - `When` = action under test
   - `Then` = assertion (use std.testing.expect*)

3. **Explore the Codebase**
   - Identify existing patterns and conventions
   - Find related code that this feature will integrate with
   - Understand the current module structure
   - Locate test patterns

5. **Identify Module Structure**
   Determine the module organization:
   - `src/` - Main source files
   - `src/lib.zig` or `src/main.zig` - Entry point
   - Module files for logical separation
   - `build.zig` - Build configuration

6. **Break Down into Tasks**
   Create tasks that are:
   - 2-5 minutes each
   - Follow TDD (test written before implementation)
   - Have clear dependencies
   - Include exact file paths
   - Reference specific scenarios they implement

7. **Output Format**

```yaml
feature: [feature name]
user_story: "As a ... I want ... So that ..."
background_setup: "[common test setup from Background:]"

scenarios:
  - name: "[Scenario name]"
    given: ["step 1", "step 2"]
    when: ["action"]
    then: ["outcome 1", "outcome 2"]

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
    scenarios_covered:
      - "[Scenario name this task implements]"
    files:
      create:
        - path: [exact/path/to/file.zig]
          purpose: [why this file]
      modify:
        - path: [exact/path/to/existing.zig]
          changes: [what changes]
    test_cases:
      - scenario: "[Scenario name]"
        test_name: "test [scenario in snake_case]"
        given_setup: "[how to implement Given steps]"
        when_action: "[how to implement When step]"
        then_assert: "[std.testing assertions to use]"
    dependencies: []
    tdd_steps:
      - step: "Write failing test for scenario"
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
    scenarios_covered:
      - "[Another scenario]"
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

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
│                      TASK MANAGER                               │
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
│                      NODE BUILDER                               │
│  - Follows TDD: RED -> GREEN -> REFACTOR                        │
│  - Uses component-based architecture                            │
│  - Runs npm test, npm run lint                                  │
│  - Commits with descriptive messages                            │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      NODE REVIEWER                              │
│  Stage 1: Spec Compliance                                       │
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

### Example PLAN.md

```gherkin
Feature: JWT Authentication
  As an API consumer
  I want requests to be authenticated via JWT
  So that only authorized users can access protected endpoints

  Background:
    Given the JWT secret is configured
    And the authentication middleware is enabled

  Scenario: Valid token grants access
    Given I have a valid JWT token for user "alice"
    When I make a request to a protected endpoint
    Then the request should succeed
    And the user context should contain user ID "alice"

  Scenario: Expired token is rejected
    Given I have an expired JWT token
    When I make a request to a protected endpoint
    Then I should receive a 401 Unauthorized response
    And the response body should contain error "token expired"

  Scenario: Malformed token is rejected
    Given I have a malformed JWT token "not-a-valid-jwt"
    When I make a request to a protected endpoint
    Then I should receive a 401 Unauthorized response
    And the response body should contain error "invalid token"

  Scenario: Missing token is rejected
    Given I make a request without an Authorization header
    When I access a protected endpoint
    Then I should receive a 401 Unauthorized response
    And the response body should contain error "missing token"

  Scenario: Health check bypasses authentication
    Given I make a request without an Authorization header
    When I access the "/health" endpoint
    Then the request should succeed

  # Note: Use existing user model from src/components/users/
  # Note: Token secret should come from config, not hardcoded
  # Note: Use jsonwebtoken package
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
   - `Background:` steps become test setup/fixtures (beforeEach)
   - `Given` = test precondition/setup (Arrange)
   - `When` = action under test (Act)
   - `Then` = assertion (Assert)

3. **Explore the Codebase**
   - Identify existing patterns and conventions
   - Find related code that this feature will integrate with
   - Understand the current architecture (expect component-based)
   - Locate test patterns and helpers

4. **Identify Component Structure**
   Determine which components/layers this feature touches:
   - `src/components/[name]/` - Business domain modules
   - `src/middleware/` - Express/Fastify middleware
   - `src/config/` - Configuration management
   - `src/errors/` - Custom error classes
   - `src/utils/` - Shared utilities
   - `tests/` - Integration/E2E tests

5. **Break Down into Tasks**
   Create tasks that are:
   - 2-5 minutes each
   - Follow TDD (test file created before implementation)
   - Have clear dependencies
   - Include exact file paths
   - Reference specific scenarios they implement

6. **Output Format**

```yaml
feature: {{feature}}
user_story: "As a ... I want ... So that ..."
background_setup: "[common test setup from Background:]"

scenarios:
  - name: "[Scenario name]"
    given: ["step 1", "step 2"]
    when: ["action"]
    then: ["outcome 1", "outcome 2"]

architecture_analysis:
  components_affected:
    - component: [component name]
      reason: [why this component is needed]
  existing_patterns:
    - pattern: [pattern name]
      location: [file path]
      relevance: [how it applies]
  integration_points:
    - file: [path]
      description: [what needs to connect]

tasks:
  - id: 1
    name: "[descriptive task name]"
    component: [component name]
    scenarios_covered:
      - "[Scenario name this task implements]"
    files:
      create:
        - path: [exact/path/to/file.js]
          purpose: [why this file]
        - path: [exact/path/to/file.test.js]
          purpose: test file
      modify:
        - path: [exact/path/to/existing.js]
          changes: [what changes]
    test_cases:
      - scenario: "[Scenario name]"
        test_name: "should [behavior in lowercase]"
        given_setup: "[how to implement Given steps]"
        when_action: "[how to implement When step]"
        then_assert: "[how to implement Then assertions]"
    dependencies: []  # task IDs this depends on
    tdd_steps:
      - step: "Write failing test for scenario"
        file: [test file path]
        description: [what the test verifies]
      - step: "Implement minimal code"
        file: [implementation file]
        description: [what to implement]
      - step: "Run validation"
        commands:
          - npm test
          - npm run lint

  - id: 2
    name: "[next task]"
    scenarios_covered:
      - "[Another scenario]"
    dependencies: [1]  # depends on task 1
    ...

execution_order: [1, 2, 3, ...]  # respecting dependencies
```

### Constraints

- Tasks MUST follow component-based architecture
- Business logic MUST live in service layer, not controllers
- Each task MUST have a test file
- Each scenario MUST map to at least one test case
- Dependencies flow: routes -> controllers -> services -> repositories
- Use existing patterns found in codebase
```

---

## Phase 2: Node Builder Agent

**Purpose:** Implement a single task following TDD and Node.js best practices.

### Dispatch Template

See [[references/builder-context.md]] for the full builder context that gets injected.

---

## Phase 3: Node Reviewer Agent

**Purpose:** Two-stage review - spec compliance then code quality.

### Stage A: Spec Compliance Review

Validates that the implementation matches the acceptance criteria exactly.

### Stage B: Code Quality Review

See [[references/reviewer-context.md]] for the full reviewer context including:
- Node.js best practices
- Async/await patterns
- Error handling checklist
- Security review
- Testing anti-patterns

---

## Orchestration Flow

### Main Loop

```
1. If skip_planning != "true":
   - Dispatch Task Manager
   - Wait for task breakdown
   - Create TaskList entries for each task

2. For each task in execution_order:
   a. Mark task as in_progress
   b. Dispatch Node Builder with task context
   c. If Builder returns blocked/needs_clarification:
      - Handle blocker
      - Re-dispatch Builder
   d. Dispatch Node Reviewer (Stage A: Spec Compliance)
   e. If Stage A returns CHANGES_NEEDED:
      - Dispatch Builder with feedback
      - Re-run Stage A
      - Repeat until APPROVED
   f. Dispatch Node Reviewer (Stage B: Code Quality)
   g. If Stage B returns CHANGES_NEEDED:
      - Dispatch Builder with feedback
      - Re-run Stage B
      - Repeat until APPROVED
   h. Mark task as completed
   i. Continue to next task

3. After all tasks complete:
   - Run full test suite
   - Run full lint check
   - Report summary
```

### Error Recovery

If a task fails repeatedly (3+ review cycles):
1. Stop the loop
2. Report the stuck task
3. Ask for human intervention

---

## Quick Reference

### Dispatch Task Manager
```
subagent_type: "general-purpose"
description: "Plan {{feature}}"
prompt: [Task Manager Template with arguments injected]
```

### Dispatch Node Builder
```
subagent_type: "general-purpose"
description: "Build task {{task.id}}"
prompt: [Node Builder Template with task context injected]
```

### Dispatch Node Reviewer (Spec)
```
subagent_type: "general-purpose"
description: "Review spec {{task.id}}"
prompt: [Spec Compliance Template with task and builder output]
```

### Dispatch Node Reviewer (Quality)
```
subagent_type: "code-quality-reviewer"
description: "Review quality {{task.id}}"
prompt: [Code Quality Template with task context]
```

---

## Anti-Patterns

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

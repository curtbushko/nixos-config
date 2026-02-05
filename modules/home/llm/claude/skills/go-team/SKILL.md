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
│                      TASK MANAGER                               │
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
│                       GO BUILDER                                │
│  - Follows TDD: RED -> GREEN -> REFACTOR                        │
│  - Adheres to hexagonal architecture                            │
│  - Runs build, test, lint, arch-check                           │
│  - Commits with descriptive messages                            │
└─────────────────────────┬───────────────────────────────────────┘
                          │
                          ▼
┌─────────────────────────────────────────────────────────────────┐
│                      GO REVIEWER                                │
│  Stage 1: Spec Compliance                                       │
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
  # Note: Use existing domain types from internal/core/domain/
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

  # Note: Use existing `internal/core/domain/user.go` for User type
  # Note: Token secret should come from config, not hardcoded
  # Note: Consider using godog for BDD test execution
```

### Benefits of BDD Format

1. **Each Scenario = One Test** - Direct mapping to test cases
2. **Executable** - Can use `godog` to run Gherkin specs directly
3. **Precise** - Given/When/Then forces clear thinking about preconditions and outcomes
4. **Stakeholder Readable** - Non-technical team members can review specs

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
   - `Background:` steps become test setup/fixtures
   - `Given` = test precondition/setup
   - `When` = action under test
   - `Then` = assertion
   - Consider using godog for BDD test execution

3. **Explore the Codebase**
   - Identify existing patterns and conventions
   - Find related code that this feature will integrate with
   - Understand the current architecture (expect hexagonal/onion)
   - Locate test patterns and helpers

4. **Identify Architectural Layer**
   Determine which layers this feature touches:
   - `internal/core/domain/` - Entities, value objects, domain errors
   - `internal/core/ports/` - Interface definitions
   - `internal/core/services/` - Business logic / use cases
   - `internal/adapters/handlers/` - HTTP/gRPC handlers
   - `internal/adapters/repositories/` - Database implementations

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
  layers_affected:
    - layer: [domain|ports|services|adapters]
      reason: [why this layer is needed]
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
    layer: [domain|ports|services|adapters]
    scenarios_covered:
      - "[Scenario name this task implements]"
    files:
      create:
        - path: [exact/path/to/file.go]
          purpose: [why this file]
        - path: [exact/path/to/file_test.go]
          purpose: test file
      modify:
        - path: [exact/path/to/existing.go]
          changes: [what changes]
    test_cases:
      - scenario: "[Scenario name]"
        test_name: "Test[ScenarioInPascalCase]"
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
          - go build ./...
          - go test ./[package]/...
          - golangci-lint run ./[package]/...

  - id: 2
    name: "[next task]"
    scenarios_covered:
      - "[Another scenario]"
    dependencies: [1]  # depends on task 1
    ...

execution_order: [1, 2, 3, ...]  # respecting dependencies
```

### Constraints

- Tasks MUST follow hexagonal architecture
- Domain layer MUST NOT import from adapters
- Each task MUST have a test file
- Each scenario MUST map to at least one test case
- Dependencies flow: handlers -> services -> domain
- Use existing patterns found in codebase
```

---

## Phase 2: Go Builder Agent

**Purpose:** Implement a single task following TDD and Go best practices.

### Dispatch Template

```
## Go Builder: Implement Task {{task.id}} - {{task.name}}

### Task Context
Feature: {{feature}}
Layer: {{task.layer}}
Dependencies completed: {{task.dependencies}}

### Files to Work With
{{#if task.files.create}}
**Create:**
{{#each task.files.create}}
- {{this.path}} ({{this.purpose}})
{{/each}}
{{/if}}

{{#if task.files.modify}}
**Modify:**
{{#each task.files.modify}}
- {{this.path}}: {{this.changes}}
{{/each}}
{{/if}}

### Scenarios to Implement
{{#each task.scenarios_covered}}
- {{this}}
{{/each}}

### Test Cases (from Gherkin scenarios)
{{#each task.test_cases}}
**{{this.scenario}}** → `{{this.test_name}}`
- Setup (Given): {{this.given_setup}}
- Action (When): {{this.when_action}}
- Assert (Then): {{this.then_assert}}
{{/each}}

### TDD Steps
{{#each task.tdd_steps}}
{{@index}}. {{this.step}}
   - File: {{this.file}}
   - Description: {{this.description}}
{{/each}}

---

## MANDATORY: Go Development Standards

### Build Quality (NON-NEGOTIABLE)
Before completing, ALL must pass:
- `go build ./...`
- `go test ./...`
- `golangci-lint run`
- `go-arch-lint check` (if config exists)

### TDD Workflow (NON-NEGOTIABLE)
1. **RED**: Write failing test FIRST
   - Run test, confirm it FAILS
   - This validates the test can detect failures

2. **GREEN**: Write MINIMAL code to pass
   - Only enough to make test pass
   - No extra features

3. **REFACTOR**: Clean up while green
   - Improve naming, structure
   - Run tests after each change

### Hexagonal Architecture (NON-NEGOTIABLE)
```
Dependencies flow INWARD:
  adapters/handlers -> core/services -> core/domain
  adapters/repositories -> core/ports <- core/services

Domain layer has NO external dependencies
```

### Code Patterns

**Error Handling:**
```go
// Wrap with context
return fmt.Errorf("operation failed: %w", err)

// Check wrapped errors
errors.As(err, &targetType)
errors.Is(err, sentinelErr)
```

**Interfaces:**
```go
// Define where used, not where implemented
// Keep small (1-3 methods)
// Name with -er suffix for single method
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}
```

**Table-Driven Tests:**
```go
func TestFeature(t *testing.T) {
    tests := []struct {
        name    string
        input   Input
        want    Output
        wantErr bool
    }{
        {"valid input", validInput, expectedOutput, false},
        {"empty input", emptyInput, Output{}, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Feature(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %v, want %v", got, tt.want)
            }
        })
    }
}
```

### Common Lint Fixes

| Error | WRONG Fix | CORRECT Fix |
|-------|-----------|-------------|
| `defer in loop` | Remove defer | Extract to helper function |
| `error ignored` | Add `_ = err` | Handle or wrap and return |
| `GetX() naming` | Rename to `GetterX()` | Rename to `X()` (drop Get) |

---

## Output Format

```yaml
task_id: {{task.id}}
task_name: {{task.name}}
status: complete|blocked|needs_clarification

files_created:
  - path: [file path]
    purpose: [why created]
    lines: [line count]

files_modified:
  - path: [file path]
    changes: [summary of changes]

tests_added:
  - name: [test name]
    file: [test file path]
    covers: [what it tests]

validation:
  build: pass|fail
  test: pass|fail
  lint: pass|fail
  arch: pass|fail|skipped

commits:
  - hash: [short hash]
    message: [commit message]

summary: [1-2 sentence summary of what was implemented]

{{#if blocked}}
blockers:
  - [description of what's blocking]
{{/if}}
```
```

---

## Phase 3: Go Reviewer Agent

**Purpose:** Two-stage review - spec compliance then code quality.

### Stage A: Spec Compliance Review

```
## Go Reviewer: Spec Compliance - Task {{task.id}}

### Original Specification
Feature: {{feature}}
Task: {{task.name}}

### Scenarios This Task Must Implement
{{#each task.scenarios_covered}}
- {{this}}
{{/each}}

### Test Cases Required
{{#each task.test_cases}}
- {{this.test_name}}: {{this.scenario}}
{{/each}}

### Builder Output
{{builder_output}}

### Files to Review
{{#each task.files.create}}
- {{this.path}}
{{/each}}
{{#each task.files.modify}}
- {{this.path}}
{{/each}}

---

## Review Checklist

### 1. Scenario Coverage
For each scenario in `scenarios_covered`:
- Is there a test case implementing this scenario?
- Does the test follow Given/When/Then structure?
- Are all Then assertions verified?

### 2. Under-Building Check
- Are any scenarios partially implemented?
- Are any scenarios missing entirely?
- Are there TODO comments for unfinished work?

### 3. Over-Building Check
- Is there code not required by any scenario?
- Are there extra features added beyond the Feature spec?
- Is there premature optimization?

### 4. Test Quality
- Does each scenario have a corresponding test?
- Do tests follow the Given/When/Then mapping?
- Are error scenarios tested (scenarios with "should get error")?

---

## Output Format

```yaml
review_type: spec_compliance
task_id: {{task.id}}
status: APPROVED|CHANGES_NEEDED

scenario_assessment:
{{#each task.scenarios_covered}}
  - scenario: "{{this}}"
    status: implemented|partial|missing
    test_name: "[test that implements this scenario]"
    given_verified: true|false
    when_verified: true|false
    then_verified: true|false
    notes: "[if not fully implemented]"
{{/each}}

under_building:
  found: true|false
  issues:
    - scenario: "[which scenario is missing/incomplete]"
      severity: critical|major
      suggestion: "[how to fix]"

over_building:
  found: true|false
  issues:
    - description: "[what's extra beyond scenarios]"
      files: "[affected files]"
      recommendation: remove|keep_with_justification

test_quality:
  adequate: true|false
  missing_tests:
    - scenario: "[scenario without test]"
      suggested_test: "[test description with Given/When/Then]"

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
    scenario: "[which scenario]"
    files: "[which files]"
```
```

### Stage B: Code Quality Review (only after Stage A passes)

```
## Go Reviewer: Code Quality - Task {{task.id}}

### Context
Feature: {{feature}}
Task: {{task.name}}
Spec Review: APPROVED

### Files to Review
{{#each task.files.create}}
- {{this.path}}
{{/each}}
{{#each task.files.modify}}
- {{this.path}}
{{/each}}

---

## Code Quality Checklist

### 1. Error Handling (Critical)
- [ ] No ignored errors (mistake #53)
- [ ] Errors wrapped with context (mistake #49)
- [ ] `errors.Is`/`errors.As` used for comparison (mistakes #50, #51)
- [ ] Errors handled once - logged OR returned (mistake #52)

### 2. Concurrency Safety (Critical)
- [ ] No data races (mistake #58)
- [ ] Mutex scope covers entire operation (mistake #70)
- [ ] No sync type copying (mistake #74)
- [ ] Goroutines have stop mechanism (mistake #62)

### 3. Resource Management (Critical)
- [ ] Resources closed with defer (mistake #79)
- [ ] No defer in loops (mistake #35)
- [ ] `time.After` not leaking (mistake #76)

### 4. Architecture Compliance (Major)
- [ ] Code in correct layer (domain/ports/services/adapters)
- [ ] Domain has no external imports
- [ ] Dependencies flow inward
- [ ] Interfaces defined where used (mistake #6)

### 5. Interface Design (Major)
- [ ] Interfaces small (1-3 methods) (mistake #5)
- [ ] No premature interfaces
- [ ] Returns concrete types (mistake #7)

### 6. Naming & Style (Minor)
- [ ] No Get prefix on getters (effective Go)
- [ ] Package names short and clear
- [ ] Function names simple (no edge cases in names)

### 7. Testing Quality (Major)
- [ ] TDD followed (test written first)
- [ ] Table-driven tests used (mistake #85)
- [ ] No sleep in tests (mistake #86)
- [ ] Race flag compatibility (mistake #83)

### 8. Performance Patterns (Minor)
- [ ] Slices/maps preallocated when size known (mistakes #21, #27)
- [ ] strings.Builder used in loops (mistake #39)
- [ ] No unnecessary allocations in hot paths

---

## 100 Go Mistakes Quick Reference

| Category | Key Checks |
|----------|------------|
| Errors (#48-54) | Wrap with context, use Is/As, handle once |
| Concurrency (#58-74) | Race detector, mutex scope, goroutine lifecycle |
| Resources (#26,28,76,79) | Close with defer, avoid leaks |
| Interfaces (#5-7) | Small, consumer-side, return concrete |
| Testing (#83,86) | Race flag, no sleep |

---

## Output Format

```yaml
review_type: code_quality
task_id: {{task.id}}
status: APPROVED|CHANGES_NEEDED

findings:
  critical:
    - issue: [description]
      location: [file:line]
      mistake_ref: [#number from 100 Go Mistakes]
      fix: [how to fix]

  major:
    - issue: [description]
      location: [file:line]
      mistake_ref: [#number if applicable]
      fix: [how to fix]

  minor:
    - issue: [description]
      location: [file:line]
      suggestion: [improvement]

architecture:
  compliant: true|false
  violations:
    - layer: [which layer]
      issue: [what's wrong]
      fix: [how to fix]

testing:
  tdd_followed: true|false
  coverage_adequate: true|false
  issues:
    - [testing issue]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1  # critical first
    description: [what to fix]
    location: [file:line]
```
```

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
   b. Dispatch Go Builder with task context
   c. If Builder returns blocked/needs_clarification:
      - Handle blocker
      - Re-dispatch Builder
   d. Dispatch Go Reviewer (Stage A: Spec Compliance)
   e. If Stage A returns CHANGES_NEEDED:
      - Dispatch Builder with feedback
      - Re-run Stage A
      - Repeat until APPROVED
   f. Dispatch Go Reviewer (Stage B: Code Quality)
   g. If Stage B returns CHANGES_NEEDED:
      - Dispatch Builder with feedback
      - Re-run Stage B
      - Repeat until APPROVED
   h. Mark task as completed
   i. Continue to next task

3. After all tasks complete:
   - Run full test suite
   - Run full lint check
   - Run architecture check
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

### Dispatch Go Builder
```
subagent_type: "general-purpose"
description: "Build task {{task.id}}"
prompt: [Go Builder Template with task context injected]
```

### Dispatch Go Reviewer (Spec)
```
subagent_type: "general-purpose"
description: "Review spec {{task.id}}"
prompt: [Spec Compliance Template with task and builder output]
```

### Dispatch Go Reviewer (Quality)
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
- Ignoring architecture violations
- Marking task complete with failing tests/lint

---

## Integration with Other Skills

- **writing-plans**: Can be used to create the initial plan that Task Manager refines
- **subagent-driven-development**: Go Team follows the same two-stage review pattern
- **execute-plan**: Can execute Go Team's task output in batch mode

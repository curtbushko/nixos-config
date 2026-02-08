# Node Team Orchestration Procedure

This document defines the automated dispatch loop for the Node Team skill.

## Context Files to Inject

When dispatching agents, inject the appropriate context from these reference files:

| Agent | Context File | Contents |
|-------|--------------|----------|
| **Node Builder** | `[[builder-context.md]]` | TDD workflow, component architecture, code patterns, async patterns, error handling, testing patterns |
| **Node Reviewer** | `[[reviewer-context.md]]` | AI code problems checklist, Node.js anti-patterns, security review, testing anti-patterns, output formats |
| **Task Manager** | (inline in template) | Component structure guidelines, task breakdown rules |

**IMPORTANT:** The full content of the relevant context file MUST be included in each agent's dispatch prompt. Do not just reference the file - paste the content.

---

## Orchestration Overview

```
┌────────────────────────────────────────────────────────────────────┐
│                        ORCHESTRATOR                                │
│  (Main agent following this procedure)                             │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│ STEP 1: Read Plan File                                             │
│ - Read PLAN.md (or specified plan file)                            │
│ - Validate it contains feature spec + acceptance criteria          │
│ - Check for specific task number argument                          │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│ STEP 2: Task Breakdown (if no specific task specified)             │
│ - Dispatch Task Manager to break down into implementation tasks    │
│ - Parse YAML output into task list                                 │
│ - Create TaskList entries for tracking                             │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│ STEP 3: Execution Loop                                             │
│ For each task in execution_order:                                  │
│   ├── 3a: Dispatch Node Builder                                    │
│   ├── 3b: Dispatch Spec Reviewer → fix loop if needed              │
│   ├── 3c: Dispatch Quality Reviewer → fix loop if needed           │
│   └── 3d: Mark task complete                                       │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│ STEP 4: Final Validation                                           │
│ - Run full test suite                                              │
│ - Run lint check                                                   │
│ - Generate summary report                                          │
└────────────────────────────────────────────────────────────────────┘
```

---

## Step 1: Read Plan File

When the skill is invoked:

```
PLAN_FILE = args.plan or "PLAN.md"        # Default to PLAN.md
SPECIFIC_TASK = args.task or null         # Optional specific task number

# Read the plan file
PLAN_CONTENT = Read(PLAN_FILE)

# Validate plan file exists and has content
if PLAN_CONTENT is empty:
    error "Plan file not found or empty: {PLAN_FILE}"
```

**Expected Plan File Format (BDD/Gherkin):**
```gherkin
Feature: [Short Name]
  As a [role]
  I want [capability]
  So that [benefit]

  Background:
    Given [common precondition]

  Scenario: [Behavior 1]
    Given [context]
    When [action]
    Then [outcome]

  Scenario: [Behavior 2]
    Given [context]
    When [action]
    Then [outcome]
```

---

## Step 2: Task Manager Dispatch

**Skip if:** `SPECIFIC_TASK` is set (tasks already exist from previous run)

### 2.1 Dispatch Task Manager

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Plan feature from {PLAN_FILE}"
  prompt: |
    ## Task Manager: Plan Feature

    ### Plan File: {PLAN_FILE}

    ### Plan Contents
    ```markdown
    {PLAN_CONTENT}
    ```

    ### Your Mission

    1. **Parse the Gherkin Feature File**
       - Extract feature name from `Feature:` line
       - Extract user story from `As a / I want / So that` (if present)
       - Extract `Background:` steps (common preconditions)
       - Extract each `Scenario:` with its Given/When/Then steps
       - Note any `# Note:` comments for implementation hints

    2. **Map Scenarios to Implementation Tasks**
       - Each Scenario typically becomes one or more tests
       - Group related scenarios that test the same component
       - Background steps inform test setup/fixtures (beforeEach)
       - Given = test precondition/setup (Arrange)
       - When = action under test (Act)
       - Then = assertion (Assert)

    3. **Explore the Codebase**
       - Identify existing patterns and conventions
       - Find related code that this feature will integrate with
       - Understand the current architecture (expect component-based)
       - Locate test patterns and helpers

    4. **Identify Component Structure**
       Determine the organization:
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
       Return YAML with this structure:

       ```yaml
       feature: {FEATURE}
       user_story: "As a ... I want ... So that ..."
       background_setup: "[common test setup from Background:]"

       scenarios:
         - name: "[Scenario name]"
           given: ["step 1", "step 2"]
           when: ["action"]
           then: ["outcome 1", "outcome 2"]

       tasks:
         - id: 1
           name: "[task name]"
           component: [component name]
           scenarios_covered:
             - "[Scenario name this task implements]"
           files:
             create:
               - path: [exact/path]
                 purpose: [why]
             modify:
               - path: [exact/path]
                 changes: [what]
           test_cases:
             - scenario: "[Scenario name]"
               test_name: "should [behavior]"
               given_setup: "[how to implement Given steps]"
               when_action: "[how to implement When step]"
               then_assert: "[how to implement Then assertions]"
           dependencies: []
           tdd_steps:
             - step: "Write failing test for scenario"
               file: [test file]
               description: [what test verifies]
             - step: "Implement"
               file: [impl file]
               description: [what to implement]
       execution_order: [1, 2, 3, ...]
       ```
```

### 2.2 Parse Task Manager Output

Extract from the YAML response:
- `TASKS[]` - array of task objects
- `EXECUTION_ORDER[]` - array of task IDs in order

### 2.3 Create Task Tracking Entries

```
For each task in TASKS:
  TaskCreate:
    subject: "[{FEATURE}] Task {task.id}: {task.name}"
    description: |
      Component: {task.component}

      Files to create:
      {for each file in task.files.create}
      - {file.path}: {file.purpose}
      {end for}

      Files to modify:
      {for each file in task.files.modify}
      - {file.path}: {file.changes}
      {end for}

      Acceptance criteria:
      {for each criterion in task.acceptance_criteria}
      - {criterion}
      {end for}

      Dependencies: {task.dependencies}
    activeForm: "Implementing {task.name}"
```

---

## Step 3: Execution Loop

```
MAX_REVIEW_CYCLES = 3

For task_id in EXECUTION_ORDER:
  task = TASKS[task_id]

  # Mark task in progress
  TaskUpdate(task_id, status: "in_progress")

  # 3a: Build Phase
  builder_output = dispatch_builder(task)

  if builder_output.status == "blocked":
    handle_blocker(builder_output)
    builder_output = dispatch_builder(task)  # retry

  # 3b: Spec Review Phase
  spec_cycles = 0
  loop:
    spec_result = dispatch_spec_reviewer(task, builder_output)

    if spec_result.verdict == "APPROVED":
      break loop

    spec_cycles += 1
    if spec_cycles >= MAX_REVIEW_CYCLES:
      escalate_to_user("Spec review failed after {MAX_REVIEW_CYCLES} cycles", task)
      break loop

    # Fix and retry
    builder_output = dispatch_builder_fix(task, spec_result.changes_required)

  # 3c: Quality Review Phase (only if spec passed)
  if spec_result.verdict == "APPROVED":
    quality_cycles = 0
    loop:
      quality_result = dispatch_quality_reviewer(task, builder_output)

      if quality_result.verdict == "APPROVED":
        break loop

      quality_cycles += 1
      if quality_cycles >= MAX_REVIEW_CYCLES:
        escalate_to_user("Quality review failed after {MAX_REVIEW_CYCLES} cycles", task)
        break loop

      # Fix and retry
      builder_output = dispatch_builder_fix(task, quality_result.changes_required)

  # 3d: Mark complete
  TaskUpdate(task_id, status: "completed")
```

---

## Step 3a: Node Builder Dispatch

**IMPORTANT:** Include the full content of `[[builder-context.md]]` in this prompt.

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Build task {task.id}"
  prompt: |
    ## Node Builder: Implement Task {task.id} - {task.name}

    ### Task Context
    Feature: {FEATURE}
    Component: {task.component}
    Dependencies completed: {task.dependencies}

    ### Files to Work With

    **Create:**
    {for each file in task.files.create}
    - {file.path} ({file.purpose})
    {end for}

    **Modify:**
    {for each file in task.files.modify}
    - {file.path}: {file.changes}
    {end for}

    ### Acceptance Criteria for This Task
    {for each criterion in task.acceptance_criteria}
    - [ ] {criterion}
    {end for}

    ### TDD Steps
    {for index, step in task.tdd_steps}
    {index + 1}. {step.step}
       - File: {step.file}
       - Description: {step.description}
    {end for}

    ---

    ## Node.js Development Standards

    {INJECT: Full content of builder-context.md here}

    This includes:
    - TDD Workflow (RED -> GREEN -> REFACTOR)
    - Build Quality Gates (npm test, npm run lint)
    - Component-based architecture patterns
    - Async/await patterns and error handling
    - Testing patterns with Jest/Vitest
    - Common lint fixes with correct solutions
    - Systematic debugging (when stuck)
    - Testing anti-patterns to avoid

    ---

    ### Output Format
    Return YAML:
    ```yaml
    task_id: {task.id}
    task_name: "{task.name}"
    status: complete|blocked|needs_clarification

    files_created:
      - path: [path]
        purpose: [why]
    files_modified:
      - path: [path]
        changes: [what changed]
    tests_added:
      - name: [test name]
        file: [test file]
        covers: [what it tests]

    validation:
      test: pass|fail
      lint: pass|fail

    commits:
      - hash: [short hash]
        message: [message]

    summary: [1-2 sentences]
    ```
```

---

## Step 3b: Spec Compliance Review Dispatch

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Review spec {task.id}"
  prompt: |
    ## Node Reviewer: Spec Compliance - Task {task.id}

    ### Original Specification
    Feature: {FEATURE}
    Task: {task.name}

    ### Acceptance Criteria
    {for each criterion in task.acceptance_criteria}
    - [ ] {criterion}
    {end for}

    ### Builder Output
    ```yaml
    {builder_output}
    ```

    ### Files to Review
    {for each file in task.files.create}
    - {file.path}
    {end for}
    {for each file in task.files.modify}
    - {file.path}
    {end for}

    ---

    ## Review Checklist

    ### 1. Requirements Match
    For EACH acceptance criterion:
    - Is it FULLY implemented (not partial)?
    - Is it tested?
    - Edge cases covered?

    ### 2. Under-Building Check
    - Any requirements partially implemented?
    - Any requirements missing entirely?
    - Any TODO comments for unfinished work?

    ### 3. Over-Building Check
    - Code not required by spec?
    - Extra features added?
    - Premature optimization?

    ### 4. Test Coverage
    - Each requirement has corresponding test?
    - Edge cases tested?
    - Error conditions tested?

    ---

    ## Output Format
    Return YAML:
    ```yaml
    review_type: spec_compliance
    task_id: {task.id}
    status: APPROVED|CHANGES_NEEDED

    criteria_assessment:
      - criterion: "[criterion text]"
        status: met|partial|missing
        evidence: "[file:line or test name]"
        notes: "[if not fully met]"

    under_building:
      found: true|false
      issues:
        - requirement: "[what's missing]"
          severity: critical|major

    over_building:
      found: true|false
      issues:
        - description: "[what's extra]"

    test_coverage:
      adequate: true|false
      missing_tests:
        - scenario: "[what needs testing]"

    verdict: APPROVED|CHANGES_NEEDED
    changes_required:
      - priority: 1
        description: "[what to fix]"
        files: "[which files]"
    ```
```

---

## Step 3c: Code Quality Review Dispatch

**IMPORTANT:** Include the full content of `[[reviewer-context.md]]` in this prompt.

```
Task tool call:
  subagent_type: "code-quality-reviewer"
  description: "Review quality {task.id}"
  prompt: |
    ## Node Reviewer: Code Quality - Task {task.id}

    ### Context
    Feature: {FEATURE}
    Task: {task.name}
    Spec Review: APPROVED

    ### Files to Review
    {for each file in task.files.create}
    - {file.path}
    {end for}
    {for each file in task.files.modify}
    - {file.path}
    {end for}

    ---

    ## Node.js Review Standards

    {INJECT: Full content of reviewer-context.md here}

    This includes:
    - AI-Generated Code Problems checklist (10 categories)
    - Node.js common mistakes
    - Async/await pitfalls
    - Security vulnerabilities
    - Testing anti-patterns
    - Review priority order (Critical > Major > Minor)
    - Output format templates

    ---

    ### Output Format
    Return YAML:
    ```yaml
    review_type: code_quality
    task_id: {task.id}
    status: APPROVED|CHANGES_NEEDED

    findings:
      critical:
        - issue: "[description]"
          location: "[file:line]"
          category: "[error_handling|security|async|resource_leak]"
          fix: "[how to fix]"
      major:
        - issue: "[description]"
          location: "[file:line]"
          fix: "[how to fix]"
      minor:
        - issue: "[description]"
          suggestion: "[improvement]"

    security:
      issues_found: true|false

    error_handling:
      complete: true|false

    verdict: APPROVED|CHANGES_NEEDED
    changes_required:
      - priority: 1
        description: "[what to fix]"
        location: "[file:line]"
    ```
```

---

## Step 3 (Fix Loop): Builder Fix Dispatch

When a review returns `CHANGES_NEEDED`:

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Fix task {task.id}"
  prompt: |
    ## Node Builder: Fix Review Feedback - Task {task.id}

    ### Original Task
    Feature: {FEATURE}
    Task: {task.name}

    ### Review Feedback to Address
    {for each change in review_result.changes_required}
    **Priority {change.priority}:** {change.description}
    {if change.location}Location: {change.location}{end if}
    {if change.files}Files: {change.files}{end if}
    {end for}

    {if review_result.findings}
    ### Detailed Findings
    {for each finding in review_result.findings.critical}
    - [CRITICAL] {finding.issue} at {finding.location}
      Fix: {finding.fix}
    {end for}
    {for each finding in review_result.findings.major}
    - [MAJOR] {finding.issue} at {finding.location}
      Fix: {finding.fix}
    {end for}
    {end if}

    ### Instructions
    1. Address each issue in priority order
    2. Run tests after each change
    3. Ensure npm test && npm run lint pass
    4. Commit fixes with descriptive message

    ### Output Format
    Return YAML:
    ```yaml
    task_id: {task.id}
    status: complete|blocked

    fixes_applied:
      - issue: "[what was fixed]"
        location: "[file:line]"
        change: "[what changed]"

    validation:
      test: pass|fail
      lint: pass|fail

    commits:
      - hash: [short hash]
        message: [message]
    ```
```

---

## Step 4: Final Validation

After all tasks complete:

```
# Run full validation suite
Bash: npm test
Bash: npm run lint

# Generate summary
summary = {
  feature: FEATURE,
  tasks_completed: len(TASKS),
  total_files_created: count(all files_created),
  total_tests_added: count(all tests_added),
  validation: {
    test: result,
    lint: result
  },
  commits: collect(all commits)
}

# Report to user
Output: |
  ## Node Team Complete: {FEATURE}

  ### Summary
  - Tasks completed: {summary.tasks_completed}
  - Files created: {summary.total_files_created}
  - Tests added: {summary.total_tests_added}

  ### Validation
  - Test: {summary.validation.test}
  - Lint: {summary.validation.lint}

  ### Commits
  {for each commit in summary.commits}
  - {commit.hash}: {commit.message}
  {end for}
```

---

## Error Handling

### Blocker Handling

If Builder returns `status: blocked`:

```
if builder_output.blockers contains "missing dependency":
  # Check if dependency task exists and is completed
  # If not, reorder execution

if builder_output.blockers contains "unclear requirement":
  # Escalate to user with AskUserQuestion
  question = AskUserQuestion(
    questions: [{
      question: "The builder needs clarification: {blocker.description}",
      header: "Clarify",
      options: [
        {label: "Option A", description: "..."},
        {label: "Option B", description: "..."}
      ]
    }]
  )
  # Re-dispatch builder with clarification

if builder_output.blockers contains "test failure":
  # Include test output in next builder dispatch
  # May need to adjust acceptance criteria
```

### Escalation

If review cycles exceed MAX_REVIEW_CYCLES:

```
AskUserQuestion(
  questions: [{
    question: "Task {task.id} failed review {MAX_REVIEW_CYCLES} times. How to proceed?",
    header: "Stuck Task",
    options: [
      {label: "Skip task", description: "Mark as blocked and continue"},
      {label: "Manual fix", description: "I'll fix it manually, then continue"},
      {label: "Abort", description: "Stop the entire workflow"}
    ]
  }]
)
```

---

## Quick Reference: Dispatch Sequence

```
1. Read PLAN.md
2. Task(general-purpose, "Plan {feature}", TASK_MANAGER_TEMPLATE)
   -> Parse YAML -> TASKS[]
   -> Create TaskList entries

3. For each task:
   a. TaskUpdate(in_progress)
   b. Task(general-purpose, "Build task {id}", BUILDER_TEMPLATE + builder-context.md)
   c. Task(general-purpose, "Review spec {id}", SPEC_REVIEWER_TEMPLATE)
      - Loop: fix -> re-review until APPROVED
   d. Task(code-quality-reviewer, "Review quality {id}", QUALITY_REVIEWER_TEMPLATE + reviewer-context.md)
      - Loop: fix -> re-review until APPROVED
   e. TaskUpdate(completed)

4. Final validation (npm test, npm run lint)
5. Summary report
```

# Go Team Orchestration Procedure

This document defines the automated dispatch loop for the Go Team skill.

## Context Files to Inject

When dispatching agents, inject the appropriate context from these reference files:

| Agent | Context File | Contents |
|-------|--------------|----------|
| **Go Builder** | `[[builder-context.md]]` | TDD workflow, architecture patterns, code examples, lint fixes, systematic debugging, testing anti-patterns |
| **Go Reviewer** | `[[reviewer-context.md]]` | AI code problems checklist, 100 Go Mistakes, testing anti-patterns, architecture violations, output formats |
| **Task Manager** | (inline in template) | Architecture layer definitions, task breakdown guidelines |

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
│   ├── 3a: Dispatch Go Builder                                      │
│   ├── 3b: Dispatch Spec Reviewer → fix loop if needed              │
│   ├── 3c: Dispatch Quality Reviewer → fix loop if needed           │
│   └── 3d: Mark task complete                                       │
└────────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌────────────────────────────────────────────────────────────────────┐
│ STEP 4: Final Validation                                           │
│ - Run full test suite                                              │
│ - Run full lint check                                              │
│ - Run architecture check                                           │
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

**Expected Plan File Format:**
```markdown
# Feature: [Short Name]

## Description
[Detailed description]

## Acceptance Criteria
- [ ] [Criterion 1]
- [ ] [Criterion 2]
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

    1. **Parse the Plan**
       - Extract feature name from `# Feature:` heading
       - Extract description from `## Description` section
       - Extract acceptance criteria from `## Acceptance Criteria` section
       - Note any additional context from `## Notes` section

    2. **Explore the Codebase**
       - Identify existing patterns and conventions
       - Find related code that this feature will integrate with
       - Understand the current architecture (expect hexagonal/onion)
       - Locate test patterns and helpers

    3. **Identify Architectural Layer**
       Determine which layers this feature touches:
       - `internal/core/domain/` - Entities, value objects, domain errors
       - `internal/core/ports/` - Interface definitions
       - `internal/core/services/` - Business logic / use cases
       - `internal/adapters/handlers/` - HTTP/gRPC handlers
       - `internal/adapters/repositories/` - Database implementations

    4. **Break Down into Tasks**
       Create tasks that are:
       - 2-5 minutes each
       - Follow TDD (test file created before implementation)
       - Have clear dependencies
       - Include exact file paths

    4. **Output Format**
       Return YAML with this structure:

       ```yaml
       feature: {FEATURE}
       tasks:
         - id: 1
           name: "[task name]"
           layer: [domain|ports|services|adapters]
           files:
             create:
               - path: [exact/path]
                 purpose: [why]
             modify:
               - path: [exact/path]
                 changes: [what]
           acceptance_criteria:
             - [criterion this task addresses]
           dependencies: []
           tdd_steps:
             - step: "Write failing test"
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
      Layer: {task.layer}

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

## Step 3a: Go Builder Dispatch

**IMPORTANT:** Include the full content of `[[builder-context.md]]` in this prompt.

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Build task {task.id}"
  prompt: |
    ## Go Builder: Implement Task {task.id} - {task.name}

    ### Task Context
    Feature: {FEATURE}
    Layer: {task.layer}
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

    ## Go Development Standards

    {INJECT: Full content of builder-context.md here}

    This includes:
    - TDD Workflow (RED -> GREEN -> REFACTOR)
    - Build Quality Gates (build, test, lint, arch-check)
    - Hexagonal Architecture patterns and examples
    - Code patterns (error handling, interfaces, table-driven tests)
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
      build: pass|fail
      test: pass|fail
      lint: pass|fail
      arch: pass|fail|skipped

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
    ## Go Reviewer: Spec Compliance - Task {task.id}

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
    ## Go Reviewer: Code Quality - Task {task.id}

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

    ## Go Review Standards

    {INJECT: Full content of reviewer-context.md here}

    This includes:
    - AI-Generated Code Problems checklist (10 categories)
    - 100 Go Mistakes quick reference
    - Testing Anti-Patterns
    - Architecture violation patterns
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
          mistake_ref: "[#number]"
          fix: "[how to fix]"
      major:
        - issue: "[description]"
          location: "[file:line]"
          fix: "[how to fix]"
      minor:
        - issue: "[description]"
          suggestion: "[improvement]"

    architecture:
      compliant: true|false
      violations:
        - layer: "[which]"
          issue: "[what's wrong]"

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
    ## Go Builder: Fix Review Feedback - Task {task.id}

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
    3. Ensure build/lint/test/arch all pass
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
      build: pass|fail
      test: pass|fail
      lint: pass|fail
      arch: pass|fail|skipped

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
Bash: go build ./...
Bash: go test ./... -race
Bash: golangci-lint run
Bash: go-arch-lint check  # if config exists

# Generate summary
summary = {
  feature: FEATURE,
  tasks_completed: len(TASKS),
  total_files_created: count(all files_created),
  total_tests_added: count(all tests_added),
  validation: {
    build: result,
    test: result,
    lint: result,
    arch: result
  },
  commits: collect(all commits)
}

# Report to user
Output: |
  ## Go Team Complete: {FEATURE}

  ### Summary
  - Tasks completed: {summary.tasks_completed}
  - Files created: {summary.total_files_created}
  - Tests added: {summary.total_tests_added}

  ### Validation
  - Build: {summary.validation.build}
  - Test: {summary.validation.test}
  - Lint: {summary.validation.lint}
  - Arch: {summary.validation.arch}

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

## State Management

The orchestrator maintains state between dispatches:

```yaml
orchestration_state:
  feature: "{FEATURE}"
  phase: "planning|executing|validating|complete"
  current_task_index: 0
  tasks:
    - id: 1
      status: pending|in_progress|completed|blocked
      builder_output: {...}
      spec_review_cycles: 0
      quality_review_cycles: 0
    - id: 2
      ...
  errors: []
  commits: []
```

This state allows:
- Resuming after interruption
- Tracking progress
- Debugging failures

---

## Quick Reference: Dispatch Sequence

```
1. Parse arguments
2. If not skip_planning:
   - Task(general-purpose, "Plan {feature}", TASK_MANAGER_TEMPLATE)
   - Parse YAML → TASKS[]
   - Create TaskList entries

3. For each task:
   a. TaskUpdate(in_progress)
   b. Task(general-purpose, "Build task {id}", BUILDER_TEMPLATE)
   c. Task(general-purpose, "Review spec {id}", SPEC_REVIEWER_TEMPLATE)
      - Loop: fix → re-review until APPROVED
   d. Task(code-quality-reviewer, "Review quality {id}", QUALITY_REVIEWER_TEMPLATE)
      - Loop: fix → re-review until APPROVED
   e. TaskUpdate(completed)

4. Final validation (Bash commands)
5. Summary report
```

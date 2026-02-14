# Zig Team Orchestration Procedure

## ORCHESTRATOR RULES

**You are a COORDINATOR, not a worker.**

### You MUST:
- Read the plan file
- Dispatch subagents using the Task tool
- Extract ONLY `status`, `verdict`, and `changes_required` from subagent output
- Track task progress in `.tasks/status.yaml`
- Optionally use TaskCreate/TaskUpdate for in-session UI visibility
- Run final validation commands
- Report summary to user

### You MUST NOT:
- Read source code, `builder-context.md`, `reviewer-context.md`, or `.tasks/task-*.yaml`
- Write or edit any source code
- Analyze code quality or debug test failures
- Repeat or summarize full subagent output back into your context

### Context Preservation
- Keep messages SHORT - only coordination status
- When a subagent returns, extract ONLY: `status`, `verdict`, and `changes_required` list
- Do NOT echo back full subagent output
- Subagents are disposable - they get fresh context each dispatch

---

## Step 1: Read Plan and Check State

```
PLAN_FILE = args.plan or "PLAN.md"
SPECIFIC_TASK = args.task or null
PLAN_CONTENT = Read(PLAN_FILE)

if PLAN_CONTENT is empty:
    error "Plan file not found or empty: {PLAN_FILE}"

# On resume: read the Implementation Status checklist at the top of PLAN.md first.
# This shows which scenarios are [x] done vs [ ] pending without re-reading code.
# Display completed/pending counts to user.

if file_exists(".tasks/status.yaml"):
    STATUS = Read(".tasks/status.yaml")
    if SPECIFIC_TASK is set: Skip to Step 3 (that task only)
    if STATUS has pending tasks: Skip to Step 3 (resume)
```

---

## Step 2: Task Manager Dispatch

**Skip if:** `.tasks/status.yaml` exists with pending tasks, or `SPECIFIC_TASK` is set.

```
Task tool:
  subagent_type: "general-purpose"
  description: "Plan {feature}"
  prompt: |
    ## Task Manager: Break down feature into implementation tasks

    ### Plan File: {PLAN_FILE}
    ### Plan Contents
    {PLAN_CONTENT}

    ### Instructions
    1. Parse the Gherkin feature file (extract Feature, scenarios, background, notes)
    2. Explore the codebase to find existing patterns, module structure, test helpers
    3. Identify module organization (src/, build.zig, lib.zig/main.zig)
    4. Break down into 2-5 minute tasks following TDD
    5. Write output files (format below)

    ### Output: Write these files

    First, create the directory: `mkdir -p .tasks`

    **`.tasks/status.yaml`** (coordination summary)
    ```yaml
    feature: "[feature name]"
    plan: "{PLAN_FILE}"
    execution_order: [1, 2, 3]
    tasks:
      - id: 1
        name: "[task name]"
        status: pending
        deps: []
    ```

    **`.tasks/task-{id}.yaml`** (one per task, full details)
    ```yaml
    id: 1
    name: "[task name]"
    feature: "[feature name]"
    scenarios_covered: ["[Scenario name]"]
    files:
      create: [{path, purpose}]
      modify: [{path, changes}]
    test_cases:
      - scenario: "[name]"
        test_name: "test [scenario_snake_case]"
        given_setup: "[setup]"
        when_action: "[action]"
        then_assert: "[std.testing assertions]"
    acceptance_criteria: ["[criterion from scenarios]"]
    tdd_steps:
      - step: "[red|green|refactor]"
        file: "[file path]"
        description: "[what to do]"
    ```

    Return: `status: complete`, `tasks_created: N`, `execution_order: [...]`
```

Verify `.tasks/status.yaml` exists after dispatch. Optionally create TaskCreate entries for UI tracking.

---

## Step 3: Execution Loop

```
MAX_REVIEW_CYCLES = 3

For each task (following execution_order, skip completed):
  Check dependencies are completed
  Set task status to in_progress in .tasks/status.yaml

  3a: dispatch_builder(task)
  3b: dispatch_spec_reviewer (loop up to MAX_REVIEW_CYCLES)
      If CHANGES_NEEDED: dispatch_builder_fix, re-review
  3c: dispatch_quality_reviewer (only if spec passed, same loop)
      If CHANGES_NEEDED: dispatch_builder_fix, re-review
  3d: Set task status to completed
  # Update PLAN.md checklist: mark completed scenarios as [x]
  For each scenario covered by this task (from .tasks/task-{id}.yaml scenarios_covered):
    Edit PLAN_FILE: change "- [ ] {scenario_name}" to "- [x] {scenario_name}"
```

---

## Dispatch Templates

### 3a: Builder

```
Task tool:
  subagent_type: "general-purpose"
  description: "Build task {task.id}"
  prompt: |
    ## Zig Builder: Task {task.id} - {task.name}

    **Read your task details from:** `.tasks/task-{task.id}.yaml`
    **Read your coding standards from:** `~/.claude/skills/zig-team/references/builder-context.md`

    Follow ALL standards: TDD (RED/GREEN/REFACTOR), build gates
    (zig build, zig build test), Zig idioms, error unions, allocator management.

    Return YAML:
    ```yaml
    task_id: {id}
    status: complete|blocked|needs_clarification
    files_created: [{path, purpose}]
    files_modified: [{path, changes}]
    tests_added: [{name, file, covers}]
    validation: {build, test, fmt}
    commits: [{hash, message}]
    summary: "[1-2 sentences]"
    ```
```

### 3b: Spec Reviewer

```
Task tool:
  subagent_type: "general-purpose"
  description: "Review spec {task.id}"
  prompt: |
    ## Spec Compliance Review: Task {task.id} - {task.name}

    **Read task acceptance criteria from:** `.tasks/task-{task.id}.yaml`
    Builder output summary: {builder_output.summary}
    Files changed: {builder_output.files_created + files_modified}

    Check: 1) Requirements match 2) No under-building 3) No over-building 4) Test coverage
    Read the source files and verify against acceptance criteria.

    Return YAML:
    ```yaml
    review_type: spec_compliance
    task_id: {id}
    verdict: APPROVED|CHANGES_NEEDED
    criteria_assessment: [{criterion, status, evidence}]
    changes_required: [{priority, description, files}]
    ```
```

### 3c: Quality Reviewer

```
Task tool:
  subagent_type: "code-quality-reviewer"
  description: "Review quality {task.id}"
  prompt: |
    ## Code Quality Review: Task {task.id} - {task.name}

    Spec Review: APPROVED
    Files to review: {file list from builder output}

    **Read review standards from:** `~/.claude/skills/zig-team/references/reviewer-context.md`

    Return YAML:
    ```yaml
    review_type: code_quality
    task_id: {id}
    verdict: APPROVED|CHANGES_NEEDED
    findings:
      critical: [{issue, location, fix}]
      major: [{issue, location, fix}]
      minor: [{issue, suggestion}]
    memory_safety: {issues_found}
    changes_required: [{priority, description, location}]
    ```
```

### 3d: Builder Fix

```
Task tool:
  subagent_type: "general-purpose"
  description: "Fix task {task.id}"
  prompt: |
    ## Fix Review Feedback: Task {task.id} - {task.name}

    **Read task details from:** `.tasks/task-{task.id}.yaml`
    **Read coding standards from:** `~/.claude/skills/zig-team/references/builder-context.md`

    Changes required:
    {review_result.changes_required}

    Fix each issue. Run zig build && zig build test. Commit fixes.

    Return YAML:
    ```yaml
    task_id: {id}
    status: complete|blocked
    fixes_applied: [{issue, location, change}]
    validation: {build, test, fmt}
    commits: [{hash, message}]
    ```
```

---

## Step 4: Final Validation

Run via Bash: `zig build && zig build test && zig fmt --check src/`

Report: feature name, tasks completed, validation results, commits.

---

## Error Handling

- **Missing dependency**: Check `.tasks/status.yaml`, reorder if needed
- **Unclear requirement**: AskUserQuestion with options
- **Compile error**: Include error output in next builder dispatch
- **Review cycles exceeded (3+)**: AskUserQuestion: skip / manual fix / abort
- **Stale .tasks/**: If task files reference nonexistent source, re-run Task Manager

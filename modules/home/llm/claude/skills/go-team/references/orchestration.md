# Go Team Orchestration Procedure

## ORCHESTRATOR RULES (CRITICAL - READ FIRST)

**You are a COORDINATOR, not a worker. Your ONLY job is to dispatch subagents and track status.**

### You MUST:
- Read the plan file (Step 1)
- Dispatch subagents using the Task tool
- Extract status from subagent output (APPROVED / CHANGES_NEEDED / blocked / complete)
- Track task progress in `.tasks/status.yaml` (persistent, file-based)
- Optionally use TaskCreate / TaskUpdate for in-session UI visibility
- Run final validation commands (Step 4)
- Report summary to user

### You MUST NOT:
- Read source code files (builders and reviewers do this)
- Read `builder-context.md` or `reviewer-context.md` (subagents read these themselves)
- Read `.tasks/task-*.yaml` detail files (builders and reviewers read these)
- Write or edit any source code
- Analyze code quality or architecture (reviewers do this)
- Debug test failures (builders do this)
- Make implementation decisions (builders and task managers do this)
- Repeat or summarize full subagent output back into your context

### Context Preservation
- Keep your messages SHORT - only coordination status updates
- When a subagent returns, extract ONLY: `status`, `verdict`, and `changes_required` list
- Do NOT echo back full subagent output
- Do NOT read task detail files - only read `.tasks/status.yaml`
- Subagents are disposable - they get fresh context each dispatch

---

## Subagent Context Files

Subagents read their own context files. You do NOT read these:

| Agent | Reads | Path |
|-------|-------|------|
| Go Builder | Development standards | `~/.claude/skills/go-team/references/builder-context.md` |
| Go Builder | Task details | `.tasks/task-{id}.yaml` |
| Go Reviewer | Review checklist | `~/.claude/skills/go-team/references/reviewer-context.md` |
| Go Reviewer | Task details | `.tasks/task-{id}.yaml` |
| Task Manager | (explores codebase) | N/A |

---

## Step 1: Read Plan and Check State

```
PLAN_FILE = args.plan or "PLAN.md"
SPECIFIC_TASK = args.task or null
PLAN_CONTENT = Read(PLAN_FILE)

if PLAN_CONTENT is empty:
    error "Plan file not found or empty: {PLAN_FILE}"

# Check for existing task state
if file_exists(".tasks/status.yaml"):
    STATUS = Read(".tasks/status.yaml")
    if SPECIFIC_TASK is set:
        Skip to Step 3 (execute only that task)
    if STATUS has pending tasks:
        Skip to Step 3 (resume from where we left off)
```

---

## Step 2: Task Manager Dispatch

**Skip if:** `.tasks/status.yaml` exists with pending tasks, or `SPECIFIC_TASK` is set

### 2.1 Dispatch

```
Task tool call:
  subagent_type: "general-purpose"
  description: "Plan {feature}"
  prompt: |
    ## Task Manager: Break down feature into implementation tasks

    ### Plan File: {PLAN_FILE}
    ### Plan Contents
    {PLAN_CONTENT}

    ### Instructions
    1. Parse the Gherkin feature file (extract Feature, scenarios, background, notes)
    2. Explore the codebase to find existing patterns, architecture, test helpers
    3. Identify which hexagonal architecture layers are affected
       (domain / ports / services / adapters)
    4. Break down into 2-5 minute tasks following TDD
    5. Write output files (format below)

    ### Output: Write these files

    First, create the directory: `mkdir -p .tasks`

    **File 1: `.tasks/status.yaml`** (coordination summary)
    ```yaml
    feature: "[feature name]"
    plan: "{PLAN_FILE}"
    execution_order: [1, 2, 3]
    tasks:
      - id: 1
        name: "[task name]"
        status: pending
        deps: []
      - id: 2
        name: "[task name]"
        status: pending
        deps: [1]
    ```

    **File 2: `.tasks/task-{id}.yaml`** (one per task, full details)
    ```yaml
    id: 1
    name: "[task name]"
    feature: "[feature name]"
    layer: "[domain|ports|services|adapters]"
    scenarios_covered:
      - "[Scenario name]"
    files:
      create:
        - path: "[file path]"
          purpose: "[why]"
      modify:
        - path: "[file path]"
          changes: "[what to change]"
    test_cases:
      - scenario: "[name]"
        test_name: "Test[Name]"
        given_setup: "[setup]"
        when_action: "[action]"
        then_assert: "[assertions]"
    acceptance_criteria:
      - "[criterion from scenarios]"
    tdd_steps:
      - step: "[red|green|refactor]"
        file: "[file path]"
        description: "[what to do]"
    ```

    After writing all files, return a short confirmation:
    ```yaml
    status: complete
    tasks_created: [count]
    execution_order: [1, 2, ...]
    ```
```

### 2.2 Verify Output

```
Verify .tasks/status.yaml exists: Read(".tasks/status.yaml")
Extract EXECUTION_ORDER and task count
```

### 2.3 Create In-Session Tracking (Optional)

```
For each task in .tasks/status.yaml:
  TaskCreate:
    subject: "[{FEATURE}] Task {task.id}: {task.name}"
    description: "Details: .tasks/task-{task.id}.yaml"
    activeForm: "Implementing {task.name}"
```

---

## Step 3: Execution Loop

```
MAX_REVIEW_CYCLES = 3
STATUS = Read(".tasks/status.yaml")

For task in STATUS.tasks (following execution_order):
  if task.status == "completed": continue
  if SPECIFIC_TASK is set and task.id != SPECIFIC_TASK: continue

  # Check dependencies
  for dep in task.deps:
    if dep.status != "completed": error "Dependency task {dep} not complete"

  # Update status to in_progress
  Edit .tasks/status.yaml: set task.status to "in_progress"

  # 3a: Build
  builder_output = dispatch_builder(task)
  if builder_output.status == "blocked": handle_blocker, retry once

  # 3b: Spec Review (loop)
  for cycle in 1..MAX_REVIEW_CYCLES:
    spec_result = dispatch_spec_reviewer(task, builder_output)
    if spec_result.verdict == "APPROVED": break
    builder_output = dispatch_builder_fix(task, spec_result.changes_required)
  else: escalate_to_user

  # 3c: Quality Review (only if spec passed, loop)
  if spec_result.verdict == "APPROVED":
    for cycle in 1..MAX_REVIEW_CYCLES:
      quality_result = dispatch_quality_reviewer(task, builder_output)
      if quality_result.verdict == "APPROVED": break
      builder_output = dispatch_builder_fix(task, quality_result.changes_required)
    else: escalate_to_user

  # 3d: Complete
  Edit .tasks/status.yaml: set task.status to "completed"
```

---

## Dispatch Templates

### 3a: Builder Dispatch

```
Task tool:
  subagent_type: "general-purpose"
  description: "Build task {task.id}"
  prompt: |
    ## Go Builder: Task {task.id} - {task.name}

    **Read your task details from:** `.tasks/task-{task.id}.yaml`
    **Read your coding standards from:** `~/.claude/skills/go-team/references/builder-context.md`

    Follow ALL standards: TDD (RED/GREEN/REFACTOR), build gates
    (go build, go test, golangci-lint, go-arch-lint), hex architecture.

    Return YAML:
    ```yaml
    task_id: {id}
    status: complete|blocked|needs_clarification
    files_created: [{path, purpose}]
    files_modified: [{path, changes}]
    tests_added: [{name, file, covers}]
    validation: {build, test, lint, arch}
    commits: [{hash, message}]
    summary: "[1-2 sentences]"
    ```
```

### 3b: Spec Review Dispatch

```
Task tool:
  subagent_type: "general-purpose"
  description: "Review spec {task.id}"
  prompt: |
    ## Spec Compliance Review: Task {task.id} - {task.name}

    **Read task acceptance criteria from:** `.tasks/task-{task.id}.yaml`
    Builder output summary: {builder_output.summary}
    Files changed: {builder_output.files_created + files_modified}

    Review checklist:
    1. Requirements match - each criterion fully implemented and tested?
    2. Under-building - any missing or partial implementations? TODOs?
    3. Over-building - code beyond spec? Extra features? Premature optimization?
    4. Test coverage - each requirement has tests? Edge cases? Error paths?

    Read the source files listed above and verify against the task's acceptance criteria.

    Return YAML:
    ```yaml
    review_type: spec_compliance
    task_id: {id}
    verdict: APPROVED|CHANGES_NEEDED
    criteria_assessment: [{criterion, status, evidence}]
    changes_required: [{priority, description, files}]
    ```
```

### 3c: Quality Review Dispatch

```
Task tool:
  subagent_type: "code-quality-reviewer"
  description: "Review quality {task.id}"
  prompt: |
    ## Code Quality Review: Task {task.id} - {task.name}

    Spec Review: APPROVED
    Files to review: {file list from builder output}

    **MANDATORY**: Read the review standards at:
    `~/.claude/skills/go-team/references/reviewer-context.md`
    Follow ALL review standards including 100 Go Mistakes, hex architecture
    compliance, error handling, concurrency safety, and testing quality.

    Return YAML:
    ```yaml
    review_type: code_quality
    task_id: {id}
    verdict: APPROVED|CHANGES_NEEDED
    findings:
      critical: [{issue, location, fix}]
      major: [{issue, location, fix}]
      minor: [{issue, suggestion}]
    architecture: {compliant, violations}
    changes_required: [{priority, description, location}]
    ```
```

### 3d: Builder Fix Dispatch

```
Task tool:
  subagent_type: "general-purpose"
  description: "Fix task {task.id}"
  prompt: |
    ## Fix Review Feedback: Task {task.id} - {task.name}

    **Read task details from:** `.tasks/task-{task.id}.yaml`
    **Read coding standards from:** `~/.claude/skills/go-team/references/builder-context.md`

    Changes required:
    {review_result.changes_required}

    Fix each issue in priority order. Run tests after each change.
    Ensure go build, go test, golangci-lint all pass. Commit fixes.

    Return YAML:
    ```yaml
    task_id: {id}
    status: complete|blocked
    fixes_applied: [{issue, location, change}]
    validation: {build, test, lint, arch}
    commits: [{hash, message}]
    ```
```

---

## Step 4: Final Validation

After all tasks complete, run (as the orchestrator, via Bash):

```
go build ./...
go test ./... -race
golangci-lint run
go-arch-lint check  # if config exists
```

Report to user:
```
## Go Team Complete: {FEATURE}
- Tasks completed: {count}
- Task state: .tasks/status.yaml
- Validation: build={result} test={result} lint={result} arch={result}
- Commits: {list}
```

---

## Error Handling

**Blocker: missing dependency** - Check `.tasks/status.yaml` for dep status, reorder if needed
**Blocker: unclear requirement** - AskUserQuestion with options
**Blocker: test failure** - Include error output in next builder dispatch
**Review cycles exceeded (3+)** - AskUserQuestion: skip / manual fix / abort
**Stale .tasks/ state** - If task files reference nonexistent source files, re-run Task Manager

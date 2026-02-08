# Go Team Orchestration Procedure

## ORCHESTRATOR RULES (CRITICAL - READ FIRST)

**You are a COORDINATOR, not a worker. Your ONLY job is to dispatch subagents and track status.**

### You MUST:
- Read the plan file (Step 1)
- Dispatch subagents using the Task tool
- Extract status from subagent output (APPROVED / CHANGES_NEEDED / blocked / complete)
- Track task progress using TaskCreate / TaskUpdate
- Run final validation commands (Step 4)
- Report summary to user

### You MUST NOT:
- Read source code files (builders and reviewers do this)
- Read `builder-context.md` or `reviewer-context.md` (subagents read these themselves)
- Write or edit any source code
- Analyze code quality or architecture (reviewers do this)
- Debug test failures (builders do this)
- Make implementation decisions (builders and task managers do this)
- Repeat or summarize full subagent output back into your context

### Context Preservation
- Keep your messages SHORT - only coordination status updates
- When a subagent returns, extract ONLY: `status`, `verdict`, and `changes_required` list
- Do NOT echo back full subagent output
- Do NOT include reference file contents in your own context
- Subagents are disposable - they get fresh context each dispatch

---

## Subagent Context Files

Subagents read their own context files. You do NOT read these:

| Agent | Reads | Path |
|-------|-------|------|
| Go Builder | Development standards | `~/.claude/skills/go-team/references/builder-context.md` |
| Go Reviewer | Review checklist | `~/.claude/skills/go-team/references/reviewer-context.md` |
| Task Manager | (explores codebase) | N/A |

---

## Step 1: Read Plan File

```
PLAN_FILE = args.plan or "PLAN.md"
SPECIFIC_TASK = args.task or null
PLAN_CONTENT = Read(PLAN_FILE)

if PLAN_CONTENT is empty:
    error "Plan file not found or empty: {PLAN_FILE}"
```

---

## Step 2: Task Manager Dispatch

**Skip if:** `SPECIFIC_TASK` is set

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
    5. Return YAML output (format below)

    Each task MUST include:
    - Exact file paths to create/modify
    - Test cases mapped to scenarios (Given/When/Then)
    - Dependencies on other tasks
    - TDD steps (write test, implement, validate)

    ### Output Format
    Return YAML:
    ```yaml
    feature: [name]
    scenarios:
      - name: "[Scenario name]"
        given: [steps]
        when: [action]
        then: [outcomes]
    tasks:
      - id: 1
        name: "[task name]"
        layer: [domain|ports|services|adapters]
        scenarios_covered: [list]
        files:
          create: [{path, purpose}]
          modify: [{path, changes}]
        test_cases:
          - scenario: "[name]"
            test_name: "Test[Name]"
            given_setup: "[setup]"
            when_action: "[action]"
            then_assert: "[assertions]"
        dependencies: []
        tdd_steps: [{step, file, description}]
    execution_order: [1, 2, ...]
    ```
```

### 2.2 Parse Output

Extract from YAML: `TASKS[]` and `EXECUTION_ORDER[]`

### 2.3 Create Tracking Entries

```
For each task in TASKS:
  TaskCreate:
    subject: "[{FEATURE}] Task {task.id}: {task.name}"
    description: "Layer: {task.layer} | Files: {task.files} | Deps: {task.dependencies}"
    activeForm: "Implementing {task.name}"
```

---

## Step 3: Execution Loop

```
MAX_REVIEW_CYCLES = 3

For task_id in EXECUTION_ORDER:
  TaskUpdate(task_id, status: "in_progress")

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
  TaskUpdate(task_id, status: "completed")
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

    Feature: {FEATURE}
    Layer: {task.layer}
    Dependencies completed: {task.dependencies}

    Files to create: {task.files.create}
    Files to modify: {task.files.modify}
    Acceptance criteria: {task.acceptance_criteria}
    TDD steps: {task.tdd_steps}

    **MANDATORY**: Before writing code, Read the file:
    ~/.claude/skills/go-team/references/builder-context.md
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

    Feature: {FEATURE}
    Acceptance criteria: {task.acceptance_criteria}
    Builder output summary: {builder_output}
    Files to review: {file list}

    Review checklist:
    1. Requirements match - each criterion fully implemented and tested?
    2. Under-building - any missing or partial implementations? TODOs?
    3. Over-building - code beyond spec? Extra features? Premature optimization?
    4. Test coverage - each requirement has tests? Edge cases? Error paths?

    Read the files listed above and verify against criteria.

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

    Feature: {FEATURE}
    Spec Review: APPROVED
    Files to review: {file list}

    **MANDATORY**: Read the review standards at:
    ~/.claude/skills/go-team/references/reviewer-context.md
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

    Feature: {FEATURE}
    Changes required:
    {review_result.changes_required}

    **MANDATORY**: Read the file:
    ~/.claude/skills/go-team/references/builder-context.md

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
- Validation: build={result} test={result} lint={result} arch={result}
- Commits: {list}
```

---

## Error Handling

**Blocker: missing dependency** - Check if dependency task completed, reorder if needed
**Blocker: unclear requirement** - AskUserQuestion with options
**Blocker: test failure** - Include error output in next builder dispatch
**Review cycles exceeded (3+)** - AskUserQuestion: skip / manual fix / abort

# Go Team Orchestration Procedure

## ORCHESTRATOR RULES (CRITICAL - READ FIRST)

**You are a COORDINATOR, not a worker. Your ONLY job is to dispatch subagents and track status.**

### Context Budget Warning

Your context window is finite. Every subagent return consumes context. You MUST:
- Keep dispatches concise - reference files by path, don't inline content
- Extract ONLY status/verdict from subagent returns - ignore everything else
- Never read source code, task detail files, or result files
- Never echo or summarize subagent output

### You MUST:
- Read the plan file (Step 1)
- Dispatch subagents using the Task tool
- Extract ONLY: `status` and `verdict` from subagent output (1-2 lines)
- Track task progress via `.tasks/status.yaml`
- Update PLAN.md Implementation Status checklist when tasks complete (Step 3c)
- Run final validation commands (Step 4)
- Report summary to user

### You MUST NOT:
- Read source code files
- Read `builder-context.md`, `reviewer-context.md`, or `examples.md`
- Read `.tasks/task-*.yaml` or `.tasks/result-*.yaml` detail files
- Write or edit any source code
- Analyze code quality or architecture
- Debug test failures
- Make implementation decisions
- Repeat or summarize subagent output
- Use `rm` to delete `.tasks/` files (move to `.tasks/completed/` instead)

---

## Subagent Context Files

Subagents read their own context. You do NOT read these:

| Agent | Reads | Path |
|-------|-------|------|
| Go Builder | Development standards | `~/.claude/skills/go-team/references/builder-context.md` |
| Go Builder | Task details | `.tasks/task-{task.id}.yaml` |
| Go Reviewer | Review checklist | `~/.claude/skills/go-team/references/reviewer-context.md` |
| Go Reviewer | Task details | `.tasks/task-{task.id}.yaml` |
| Go Reviewer | Build results | `.tasks/result-{task.id}-build.yaml` |
| Task Manager | (explores codebase) | N/A |

---

## Step 1: Read Plan and Check State

```
PLAN_FILE = args.plan or "PLAN.md"
SPECIFIC_TASK = args.task or null
PLAN_CONTENT = Read(PLAN_FILE)

if PLAN_CONTENT is empty:
    error "Plan file not found or empty: {PLAN_FILE}"

# On resume: read Implementation Status checklist at top of PLAN.md.
# Display completed/pending counts to user.

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

    ### Instructions
    1. Read the plan file at: {PLAN_FILE}
    2. Parse the Gherkin feature (extract Feature, scenarios, background, notes)
    3. Explore the codebase to find existing patterns, architecture, test helpers
    4. Identify which hexagonal architecture layers are affected
       (domain / ports / application / adapters)
    5. Break down into 2-5 minute tasks following TDD
    6. Write output files (format below)

    ### Output: Write these files

    First: `mkdir -p .tasks`

    **IMPORTANT: NEVER create .gitkeep files.** Git tracks files, not directories.

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
        scenarios_covered:
          - "[Scenario name from PLAN.md]"
      - id: 2
        name: "[task name]"
        status: pending
        deps: [1]
        scenarios_covered:
          - "[Scenario name from PLAN.md]"
    ```
    NOTE: `scenarios_covered` MUST list the exact scenario names from PLAN.md's
    `## Implementation Status` checklist. The orchestrator uses these to mark
    scenarios as complete in PLAN.md when each task finishes.

    **File 2: `.tasks/task-{task.id}.yaml`** (one per task, full details for builder/reviewer)
    ```yaml
    id: 1
    name: "[task name]"
    feature: "[feature name]"
    plan_file: "{PLAN_FILE}"
    layer: "[domain|ports|application|adapters]"
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

    **IMPORTANT**: Return ONLY this short confirmation (nothing else):
    ```
    status: completed
    tasks_created: [count]
    execution_order: [1, 2, ...]
    ```
```

### 2.2 Verify Output

```
Verify .tasks/status.yaml exists: Read(".tasks/status.yaml")
Extract EXECUTION_ORDER and task count
```

---

## Step 3: Execution Loop

```
MAX_REVIEW_CYCLES = 2
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
  dispatch_builder(task)
  # Builder writes results to .tasks/result-{task.id}-build.yaml
  # Builder returns only: "status: completed|blocked, summary: [1 line]"

  # 3b: Combined Review (spec + quality in one pass)
  for cycle in 1..MAX_REVIEW_CYCLES:
    dispatch_reviewer(task)
    # Reviewer writes results to .tasks/result-{task.id}-review.yaml
    # Reviewer returns only: "verdict: APPROVED|CHANGES_NEEDED, issues: [count]"

    if verdict == "APPROVED": break

    dispatch_builder_fix(task, cycle)
    # Builder reads feedback from .tasks/result-{task.id}-review.yaml
    # Builder returns only: "status: completed|blocked, fixes: [count]"
  else: escalate_to_user

  # 3c: Complete — update status AND PLAN.md
  Edit .tasks/status.yaml: set task.status to "completed"

  # MANDATORY: Update PLAN.md Implementation Status checklist
  # Read task.scenarios_covered from .tasks/status.yaml for this task
  For each scenario_name in task.scenarios_covered:
    Use the Edit tool on PLAN_FILE:
      old_string: "- [ ] {scenario_name}"
      new_string: "- [x] {scenario_name}"
  # This keeps PLAN.md as the single source of truth for progress
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

    Read these files FIRST:
    1. Your task spec: `.tasks/task-{task.id}.yaml`
    2. Your coding standards: `~/.claude/skills/go-team/references/builder-context.md`

    Follow ALL standards: TDD (RED/GREEN/REFACTOR), build gates
    (make build, make test, make lint, go-arch-lint), hex architecture.

    Write your full results to: `.tasks/result-{task.id}-build.yaml`
    (format defined in builder-context.md)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    status: completed|blocked
    summary: [one sentence]
    ```
```

### 3b: Combined Review Dispatch

```
Task tool:
  subagent_type: "code-quality-reviewer"
  description: "Review task {task.id}"
  prompt: |
    ## Combined Review: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Task acceptance criteria: `.tasks/task-{task.id}.yaml`
    2. Build results: `.tasks/result-{task.id}-build.yaml`
    3. Review standards: `~/.claude/skills/go-team/references/reviewer-context.md`

    Perform BOTH reviews in a single pass:
    - Stage 1: Spec compliance (requirements met? under/over-building?)
    - Stage 2: Code quality (only if Stage 1 passes)

    Read the source files listed in the build results and review them.

    Write your full results to: `.tasks/result-{task.id}-review.yaml`
    (format defined in reviewer-context.md)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    verdict: APPROVED|CHANGES_NEEDED
    issues: [count of changes_required]
    ```
```

### 3c: Builder Fix Dispatch

```
Task tool:
  subagent_type: "general-purpose"
  description: "Fix task {task.id}"
  prompt: |
    ## Fix Review Feedback: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Task spec: `.tasks/task-{task.id}.yaml`
    2. Review feedback: `.tasks/result-{task.id}-review.yaml`
    3. Coding standards: `~/.claude/skills/go-team/references/builder-context.md`

    Fix each issue listed in `changes_required` in priority order.
    Run tests after each change. Ensure make build, make test, make lint all pass.
    Commit fixes.

    Write your fix results to: `.tasks/result-{task.id}-fix-{cycle}.yaml`
    (same format as build results)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    status: completed|blocked
    fixes: [count of issues fixed]
    ```
```

---

## Step 4: Final Validation

After all tasks complete, run (as the orchestrator, via Bash):

```
make build
make test
make lint
go-arch-lint check  # if config exists
```

Archive completed task files (only if ALL tasks have status: completed):
```
# Verify all tasks completed before archiving
if all tasks in .tasks/status.yaml have status: "completed":
    mkdir -p .tasks/completed
    mv .tasks/task-*.yaml .tasks/completed/
    mv .tasks/result-*.yaml .tasks/completed/
# Do NOT archive if any task is pending, in_progress, or blocked
```

Report to user:
```
## Go Team Complete: {FEATURE}
- Tasks completed: {count}
- Validation: build={result} test={result} lint={result} arch={result}
- Task state: .tasks/status.yaml
```

---

## Error Handling

**Blocker: missing dependency** - Check `.tasks/status.yaml` for dep status, reorder if needed
**Blocker: unclear requirement** - AskUserQuestion with options
**Blocker: test failure** - Include error output in next builder dispatch
**Review cycles exceeded (2)** - AskUserQuestion: skip / manual fix / abort
**Stale .tasks/ state** - If task files reference nonexistent source files, re-run Task Manager

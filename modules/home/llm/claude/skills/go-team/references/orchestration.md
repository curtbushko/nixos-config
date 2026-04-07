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
- Read `.plans/index.yaml` for status overview (Step 1)
- Dispatch subagents using the Task tool
- Extract ONLY: `status` and `verdict` from subagent output (1-2 lines)
- Track task progress via `.tasks/status.yaml`
- Update `.plans/` files when tasks complete (Step 3c)
- Report summary to user

**NOTE**: Builders and reviewers run validation commands (`task build`, `task test`, `task lint`). The orchestrator does NOT run these - it only tracks status.

### You MUST NOT:
- Read source code files
- Read `builder-context.md`, `reviewer-context.md`, or `examples.md`
- Read `.tasks/task-*.yaml` or `.tasks/result-*.yaml` detail files
- Read `.plans/phase-*.md` files (Task Manager reads these)
- Write or edit any source code
- Analyze code quality or architecture
- Debug test failures
- Make implementation decisions
- Repeat or summarize subagent output
- Use `rm` to delete files (move to `.trash/` instead)

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
| Task Manager | Phase details | `.plans/phase-*.md` |

---

## Step 1: Read Plan Index and Check State

```
SPECIFIC_TASK = args.task or null
SPECIFIC_PHASE = args.phase or null

# Read the lean index file (orchestrator's view of the plan)
if not file_exists(".plans/index.yaml"):
    error "No plan found. Run /planner first to create .plans/"

INDEX = Read(".plans/index.yaml")

# Determine which phase to work on
if SPECIFIC_PHASE is set:
    PHASE = INDEX.phases[SPECIFIC_PHASE]
else:
    PHASE = INDEX.phases[INDEX.current_phase]

if PHASE.status == "completed":
    # Auto-advance to next pending phase
    PHASE = first phase where status != "completed"
    if no such phase: report "All phases complete" and exit

# Display status to user (from index.yaml only)
Display:
  Project: {INDEX.project}
  Current Phase: {PHASE.id} - {PHASE.name} [{PHASE.status}] {PHASE.progress}

# Check for existing task state
if file_exists(".tasks/status.yaml"):
    STATUS = Read(".tasks/status.yaml")
    # Verify it's for the current phase
    if STATUS.phase_id == PHASE.id:
        if SPECIFIC_TASK is set:
            Skip to Step 3 (execute only that task)
        if STATUS has pending tasks:
            Skip to Step 3 (resume from where we left off)
    else:
        # Different phase - archive old tasks and start fresh
        Archive .tasks/*.yaml to .trash/
```

---

## Step 2: Task Manager Dispatch

**Skip if:** `.tasks/status.yaml` exists for current phase with pending tasks, or `SPECIFIC_TASK` is set

### 2.1 Dispatch

```
Task tool call:
  model: "sonnet"
  subagent_type: "general-purpose"
  description: "Plan phase {PHASE.id}"
  prompt: |
    ## Task Manager: Break down phase into implementation tasks

    ### Instructions
    1. Read the phase file at: `.plans/{PHASE.file}`
    2. Parse the task checklist (extract all `- [ ]` items)
    3. Explore the codebase to find existing patterns, architecture, test helpers
    4. Identify which hexagonal architecture layers are affected
       (domain / ports / application / adapters)
    5. Break down into 2-5 minute tasks following TDD
    6. Write output files (format below)

    ### Context
    - Project: {INDEX.project}
    - Phase: {PHASE.id} - {PHASE.name}
    - Phase file: `.plans/{PHASE.file}`

    ### Output: Write these files

    First: `mkdir -p .tasks`

    **IMPORTANT: NEVER create .gitkeep files.** Git tracks files, not directories.

    **File 1: `.tasks/status.yaml`** (coordination summary)
    ```yaml
    project: "{INDEX.project}"
    phase_id: {PHASE.id}
    phase_name: "{PHASE.name}"
    phase_file: "{PHASE.file}"
    execution_order: [1, 2, 3]
    tasks:
      - id: 1
        name: "[task name]"
        status: pending
        deps: []
        plan_tasks:
          - "[exact task text from phase file]"
      - id: 2
        name: "[task name]"
        status: pending
        deps: [1]
        plan_tasks:
          - "[exact task text from phase file]"
    ```
    NOTE: `plan_tasks` MUST list the exact task text from the phase file's
    checklist. The orchestrator uses these to mark tasks complete in the
    phase file when each task finishes.

    **File 2: `.tasks/task-{task.id}.yaml`** (one per task, full details for builder/reviewer)
    ```yaml
    id: 1
    name: "[task name]"
    project: "{INDEX.project}"
    phase_id: {PHASE.id}
    phase_file: "{PHASE.file}"
    layer: "[domain|ports|application|adapters]"
    plan_tasks:
      - "[exact task text]"
    files:
      create:
        - path: "[file path]"
          purpose: "[why]"
      modify:
        - path: "[file path]"
          changes: "[what to change]"
    test_cases:
      - name: "Test[Name]"
        given_setup: "[setup]"
        when_action: "[action]"
        then_assert: "[assertions]"
    acceptance_criteria:
      - "[criterion from plan tasks]"
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

  # 3c: Complete — update .tasks/ AND .plans/
  Edit .tasks/status.yaml: set task.status to "completed"

  # MANDATORY: Update phase file checklist
  # Read task.plan_tasks from .tasks/status.yaml for this task
  PHASE_FILE = ".plans/{STATUS.phase_file}"
  For each plan_task in task.plan_tasks:
    Use the Edit tool on PHASE_FILE:
      old_string: "- [ ] {plan_task}"
      new_string: "- [x] {plan_task}"

  # MANDATORY: Update index.yaml progress
  # Count completed/total from phase file or calculate from status.yaml
  completed_count = count of tasks with status "completed" in .tasks/status.yaml
  total_count = total tasks in .tasks/status.yaml
  
  # Update progress in index.yaml
  Edit .plans/index.yaml:
    Update phase {STATUS.phase_id} progress to "{completed_count}/{total_count}"
    If all tasks complete, set status to "completed"
    If first task just completed, set status to "in_progress"
```

---

## Dispatch Templates

### 3a: Builder Dispatch

```
Task tool:
  model: "opus"
  subagent_type: "general-purpose"
  description: "Build task {task.id}"
  prompt: |
    ## Go Builder: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Your task spec: `.tasks/task-{task.id}.yaml`
    2. Your coding standards: `~/.claude/skills/go-team/references/builder-context.md`

    Follow ALL standards: TDD (RED/GREEN/REFACTOR), build gates
    (task build, task test, task lint, go-arch-lint check), hex architecture.

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
  model: "opus"
  subagent_type: "go-code-review"
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
  model: "opus"
  subagent_type: "general-purpose"
  description: "Fix task {task.id}"
  prompt: |
    ## Fix Review Feedback: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Task spec: `.tasks/task-{task.id}.yaml`
    2. Review feedback: `.tasks/result-{task.id}-review.yaml`
    3. Coding standards: `~/.claude/skills/go-team/references/builder-context.md`

    Fix each issue listed in `changes_required` in priority order.
    Run tests after each change. Ensure task build, task test, task lint all pass.
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

## Step 4: Phase/Project Completion

**NOTE**: The orchestrator does NOT run validation commands. Builders and reviewers are responsible for ensuring `task build`, `task test`, and `task lint` pass before marking their work complete.

After all tasks in the phase complete:

```
# Archive completed task files
mkdir -p .trash
# Ensure .trash is in .gitignore
if ! grep -q "^\.trash/$" .gitignore 2>/dev/null; then
    echo ".trash/" >> .gitignore
fi
mv .tasks/task-*.yaml .trash/
mv .tasks/result-*.yaml .trash/
# Keep .tasks/status.yaml for history

# Update index.yaml
Edit .plans/index.yaml:
  - Set phase {PHASE.id} status to "completed"
  - Increment current_phase to next pending phase (if any)

# Check if all phases complete
if all phases in index.yaml have status "completed":
    Report: "Project {INDEX.project} complete!"
else:
    Report: "Phase {PHASE.id} complete. Next: Phase {next_phase.id} - {next_phase.name}"
```

Report to user:
```
## Go Team Complete: Phase {PHASE.id} - {PHASE.name}
- Tasks completed: {count}
- Phase status: completed
- Next phase: {next_phase.name} (or "None - project complete")
```

---

## Error Handling

**Blocker: missing dependency** - Check `.tasks/status.yaml` for dep status, reorder if needed
**Blocker: unclear requirement** - AskUserQuestion with options
**Blocker: test failure** - Include error output in next builder dispatch
**Review cycles exceeded (2)** - AskUserQuestion: skip / manual fix / abort
**Stale .tasks/ state** - If task files reference nonexistent source files, re-run Task Manager
**No .plans/ found** - Direct user to run `/planner` first

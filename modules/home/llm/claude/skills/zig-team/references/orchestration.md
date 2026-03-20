# Zig Team Orchestration Procedure

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
- Report summary to user

**NOTE**: Builders and reviewers run validation commands. The orchestrator does NOT run these - it only tracks status.

### You MUST NOT:
- Read source code files
- Read `builder-context.md` or `reviewer-context.md`
- Read `.tasks/task-*.yaml` or `.tasks/result-*.yaml` detail files
- Write or edit any source code
- Analyze code quality or debug test failures
- Repeat or summarize subagent output
- Use `rm` to delete files (move to `.trash/` instead)

---

## Subagent Context Files

Subagents read their own context. You do NOT read these:

| Agent | Reads | Path |
|-------|-------|------|
| Zig Builder | Development standards | `~/.claude/skills/zig-team/references/builder-context.md` |
| Zig Builder | Task details | `.tasks/task-{id}.yaml` |
| Zig Reviewer | Review checklist | `~/.claude/skills/zig-team/references/reviewer-context.md` |
| Zig Reviewer | Task details | `.tasks/task-{id}.yaml` |
| Zig Reviewer | Build results | `.tasks/result-{id}-build.yaml` |
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

    ### Instructions
    1. Read the plan file at: {PLAN_FILE}
    2. Parse the Gherkin feature (extract Feature, scenarios, background, notes)
    3. Explore the codebase to find existing patterns, module structure, test helpers
    4. Identify module organization (src/, build.zig, lib.zig/main.zig)
    5. Break down into 2-5 minute tasks following TDD
    6. Write output files (format below)

    ### Output: Write these files

    First: `mkdir -p .tasks`

    **IMPORTANT: NEVER create .gitkeep files.** Git tracks files, not directories.

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
        scenarios_covered:
          - "[Scenario name from PLAN.md]"
    ```
    NOTE: `scenarios_covered` MUST list the exact scenario names from PLAN.md's
    `## Implementation Status` checklist. The orchestrator uses these to mark
    scenarios as complete in PLAN.md when each task finishes.

    **`.tasks/task-{id}.yaml`** (one per task, full details)
    ```yaml
    id: 1
    name: "[task name]"
    feature: "[feature name]"
    plan_file: "{PLAN_FILE}"
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

    **IMPORTANT**: Return ONLY this short confirmation (nothing else):
    ```
    status: complete
    tasks_created: [count]
    execution_order: [1, 2, ...]
    ```
```

Verify `.tasks/status.yaml` exists after dispatch.

---

## Step 3: Execution Loop

```
MAX_REVIEW_CYCLES = 2

For each task (following execution_order, skip completed):
  Check dependencies are completed
  Set task status to in_progress in .tasks/status.yaml

  # 3a: Build
  dispatch_builder(task)
  # Builder writes results to .tasks/result-{id}-build.yaml
  # Builder returns only: "status: complete|blocked, summary: [1 line]"

  # 3b: Combined Review (spec + quality in one pass)
  for cycle in 1..MAX_REVIEW_CYCLES:
    dispatch_reviewer(task)
    # Reviewer writes results to .tasks/result-{id}-review.yaml
    # Reviewer returns only: "verdict: APPROVED|CHANGES_NEEDED, issues: [count]"

    if verdict == "APPROVED": break

    dispatch_builder_fix(task, cycle)
    # Builder reads feedback from .tasks/result-{id}-review.yaml
    # Builder returns only: "status: complete|blocked, fixes: [count]"
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

### 3a: Builder

```
Task tool:
  subagent_type: "general-purpose"
  description: "Build task {task.id}"
  prompt: |
    ## Zig Builder: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Your task spec: `.tasks/task-{task.id}.yaml`
    2. Your coding standards: `~/.claude/skills/zig-team/references/builder-context.md`

    Follow ALL standards: TDD (RED/GREEN/REFACTOR), build gates
    (zig build, zig build test), Zig idioms, error unions, allocator management.

    Write your full results to: `.tasks/result-{task.id}-build.yaml`
    (format defined in builder-context.md)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    status: complete|blocked
    summary: [one sentence]
    ```
```

### 3b: Combined Review

```
Task tool:
  subagent_type: "code-quality-reviewer"
  description: "Review task {task.id}"
  prompt: |
    ## Combined Review: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Task acceptance criteria: `.tasks/task-{task.id}.yaml`
    2. Build results: `.tasks/result-{task.id}-build.yaml`
    3. Review standards: `~/.claude/skills/zig-team/references/reviewer-context.md`

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

### 3c: Builder Fix

```
Task tool:
  subagent_type: "general-purpose"
  description: "Fix task {task.id}"
  prompt: |
    ## Fix Review Feedback: Task {task.id} - {task.name}

    Read these files FIRST:
    1. Task spec: `.tasks/task-{task.id}.yaml`
    2. Review feedback: `.tasks/result-{task.id}-review.yaml`
    3. Coding standards: `~/.claude/skills/zig-team/references/builder-context.md`

    Fix each issue listed in `changes_required` in priority order.
    Run zig build && zig build test -j1 after each change. Commit fixes.

    Write your fix results to: `.tasks/result-{task.id}-fix-{cycle}.yaml`
    (same format as build results)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    status: complete|blocked
    fixes: [count of issues fixed]
    ```
```

---

## Step 4: Completion

**NOTE**: The orchestrator does NOT run validation commands. Builders and reviewers are responsible for ensuring tests and build pass before marking their work complete.

After all tasks complete, archive completed task files (only if ALL tasks have status: completed):
```
# Verify all tasks completed before archiving
if all tasks in .tasks/status.yaml have status: "completed":
    mkdir -p .trash
    # Ensure .trash is in .gitignore
    if ! grep -q "^\.trash/$" .gitignore 2>/dev/null; then
        echo ".trash/" >> .gitignore
    fi
    mv .tasks/task-*.yaml .trash/
    mv .tasks/result-*.yaml .trash/
# Do NOT archive if any task is pending, in_progress, or blocked
```

Report to user:
```
## Zig Team Complete: {FEATURE}
- Tasks completed: {count}
- Task state: .tasks/status.yaml
```

---

## Error Handling

- **Missing dependency**: Check `.tasks/status.yaml`, reorder if needed
- **Unclear requirement**: AskUserQuestion with options
- **Compile error**: Include error output in next builder dispatch
- **Review cycles exceeded (2)**: AskUserQuestion: skip / manual fix / abort
- **Stale .tasks/**: If task files reference nonexistent source, re-run Task Manager

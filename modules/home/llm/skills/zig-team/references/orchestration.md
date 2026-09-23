# Zig Team Orchestration Procedure

## ORCHESTRATOR RULES (CRITICAL - READ FIRST)

**You are a COORDINATOR, not a worker. Your ONLY job is to dispatch subagents and track status.**

### Context Budget Warning

Your context window is finite. Every subagent return consumes context. You MUST:
- Keep dispatches concise - reference files by path, don't inline content
- Extract ONLY status/verdict from subagent returns - ignore everything else
- Never read source code, task detail files, or result files
- Never echo or summarize subagent output

### Mandatory Watchdog Loop

The orchestrator MUST remain active while the phase has unfinished tasks. After
dispatching any Task Manager, Builder, Reviewer, or fix agent, it MUST run this
watchdog until that agent completes:

```text
POLL_INTERVAL = 30 seconds
PROGRESS_INTERVAL = 2 minutes
STATUS_INTERVAL = 5 minutes
INSPECT_AFTER = 10 minutes without evidence of progress
RECOVER_AFTER = 15 minutes without evidence of progress
MAX_RECOVERY_ATTEMPTS = 3

while phase has unfinished tasks:
  event = wait_agent(timeout=POLL_INTERVAL)
  if event, agent output, active command output, result/status file timestamp,
     or task transition proves progress:
    record last_progress_at and continue the normal workflow
  if PROGRESS_INTERVAL elapsed while an agent or command is active:
    report the current stage, exact command, elapsed time, and latest evidence of progress
  if STATUS_INTERVAL elapsed:
    report a concise timestamped status without asking the user to respond
  if no progress for STATUS_INTERVAL:
    ask the active agent for its exact command and last completed step
  if no progress for INSPECT_AFTER:
    inspect agent state, process state, command activity, and artifact timestamps
  if no progress for RECOVER_AFTER:
    interrupt the stalled agent and dispatch a replacement for the same task,
    preserving all existing edits and task artifacts
  if recovery fails MAX_RECOVERY_ATTEMPTS times for the same condition:
    report the concrete blocker and preserved state to the user
```

A `wait_agent` timeout is a polling event, never a reason to stop the orchestration turn.
An agent being alive is not evidence of progress. Conversely, a long-running command
with fresh output or resource activity is progress and MUST NOT be interrupted merely
for exceeding a wall-clock threshold. After every completion, the orchestrator MUST
immediately dispatch the next required Builder, Reviewer, fix, or task without waiting
for a user prompt.

Builders and reviewers MUST send a concise progress update at least every two minutes
while a command or investigation is still active. A progress update names the current
stage, exact command, elapsed time, and most recent output or artifact change. The
orchestrator relays this evidence instead of reporting only that an agent is alive.

The orchestrator MUST NOT return a final response while work remains unless the same
genuine blocking condition has survived all recovery attempts. Model-capacity errors
and terminated agents are recoverable conditions: retry or replace the agent and
continue from `.tasks/` state.

### You MUST:
- Read `.phases/index.yaml` for status overview (Step 1)
- Dispatch subagents using the host's subagent mechanism
- Extract ONLY: `status` and `verdict` from subagent output (1-2 lines)
- Track task progress via `.tasks/status.yaml`
- Update `.phases/` files when tasks complete (Step 3c)
- Report summary to user

**NOTE**: Builders and reviewers run validation commands. The orchestrator does NOT run these - it only tracks status.

### You MUST NOT:
- Read source code files
- Read the `zig-builder`, `zig-reviewer`, or `examples.md` files
- Read `.tasks/task-*.yaml` or `.tasks/result-*.yaml` detail files
- Read `.phases/phase-*.md` files (Task Manager reads these)
- Write or edit any source code
- Analyze code quality or debug test failures
- Repeat or summarize subagent output
- Use `rm` to delete files (move to `.trash/` instead)

---

## Subagent Context Files

Subagents read their own context. You do NOT read these:

| Agent | Reads | Path |
|-------|-------|------|
| Zig Builder | Team workflow + language patterns | `~/.claude/skills/zig-builder/SKILL.md` + `~/.claude/skills/zig/SKILL.md` |
| Zig Builder | Task details | `.tasks/task-{id}.yaml` |
| Zig Reviewer | Team workflow + review patterns | `~/.claude/skills/zig-reviewer/SKILL.md` + `~/.claude/skills/zig-code-review/SKILL.md` |
| Zig Reviewer | Task details | `.tasks/task-{id}.yaml` |
| Zig Reviewer | Build results | `.tasks/result-{id}-build.yaml` |
| Task Manager | Phase details | `.phases/phase-*.md` |

---

## Step 1: Read Phase Index and Check State

```
SPECIFIC_TASK = args.task or null
SPECIFIC_PHASE = args.phase or null

# Read the lean index file (orchestrator's view of the plan)
if not file_exists(".phases/index.yaml"):
    error "No phases found. Run the to-phases skill first to create .phases/"

INDEX = Read(".phases/index.yaml")

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

**Skip if:** `.tasks/status.yaml` exists for current phase with pending tasks, or `SPECIFIC_TASK` is set.

```
Dispatch a subagent:
  model: cheaper/faster model
  role: general-purpose
  description: "Plan phase {PHASE.id}"
  prompt: |
    ## Task Manager: Break down phase into implementation tasks

    ### Instructions
    1. Read the phase file at: `.phases/{PHASE.file}`
    2. Parse the task checklist (extract all `- [ ]` items)
    3. Explore the codebase to find existing patterns, module structure, test helpers
    4. Identify hexagonal architecture layout (src/domain/, src/ports/, src/app/, src/adapters/, build.zig modules)
    5. Break down into right-sized tasks following TDD and inside-out implementation order (domain -> ports -> app -> adapters -> wiring). Each task: one coherent concern, independently verifiable acceptance criteria, a reviewable diff, and enough context stated in the task for a fresh agent session.
    6. Write output files (format below)

    ### Context
    - Project: {INDEX.project}
    - Phase: {PHASE.id} - {PHASE.name}
    - Phase file: `.phases/{PHASE.file}`

    ### Output: Write these files

    First: `mkdir -p .tasks`

    **IMPORTANT: NEVER create .gitkeep files.** Git tracks files, not directories.

    **`.tasks/status.yaml`** (coordination summary)
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
    ```
    NOTE: `plan_tasks` MUST list the exact task text from the phase file's
    checklist. The orchestrator uses these to mark tasks complete in the
    phase file when each task finishes.

    **`.tasks/task-{id}.yaml`** (one per task, full details)
    ```yaml
    id: 1
    name: "[task name]"
    project: "{INDEX.project}"
    phase_id: {PHASE.id}
    phase_file: "{PHASE.file}"
    plan_tasks: ["[exact task text]"]
    files:
      create: [{path, purpose}]
      modify: [{path, changes}]
    test_cases:
      - name: "test [scenario_snake_case]"
        given_setup: "[setup]"
        when_action: "[action]"
        then_assert: "[std.testing assertions]"
    acceptance_criteria: ["[criterion from plan tasks]"]
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

### Verification Strategy

Run the narrowest relevant test first during RED, GREEN, and each fix cycle. A
focused test should exercise only the changed behavior and its immediate integration
boundary so ordinary development does not repeatedly pay for the whole repository.

Run the full test suite once after the implementation is ready for review. Record that
successful run in the build result so the reviewer can verify it without running the
same suite again. Re-run the full test suite after a fix only when the fix has broad impact
(shared infrastructure, public contracts, build wiring, persistence, concurrency, or
multiple capabilities), or when the reviewer explicitly requests it. Otherwise, re-run
the focused regression and record why the existing full-suite result remains applicable.

Reserve exhaustive project-specific, packaged-runtime, and full-system gates for the final task of the phase.
Earlier tasks run focused tests plus the standard full suite; the final task owns the
phase-wide release matrix and records all of its results for final review.

Test parallelism is configurable through `ZIG_TEAM_TEST_JOBS`. If it is unset, choose a
conservative value capped by logical CPUs and available memory, budgeting 4 GiB per Zig
test job: `max(1, min(logical_cpu_count, available_memory_gib / 4))`. Fall back to 1
when memory or CPU count cannot be detected. Never hard-code `-j1`. Validate that an
explicit override is a positive integer before passing it to Zig.

```
MAX_REVIEW_CYCLES = 10

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

  # 3c: Complete — update .tasks/ AND .phases/
  Edit .tasks/status.yaml: set task.status to "completed"

  # MANDATORY: Update phase file checklist
  # Read task.plan_tasks from .tasks/status.yaml for this task
  PHASE_FILE = ".phases/{STATUS.phase_file}"
  For each plan_task in task.plan_tasks:
    Use the Edit tool on PHASE_FILE:
      old_string: "- [ ] {plan_task}"
      new_string: "- [x] {plan_task}"

  # MANDATORY: Update index.yaml progress
  # Count completed/total from phase file or calculate from status.yaml
  completed_count = count of tasks with status "completed" in .tasks/status.yaml
  total_count = total tasks in .tasks/status.yaml
  
  # Update progress in index.yaml
  Edit .phases/index.yaml:
    Update phase {STATUS.phase_id} progress to "{completed_count}/{total_count}"
    If all tasks complete, set status to "completed"
    If first task just completed, set status to "in_progress"
```

---

## Dispatch Templates

### 3a: Builder

```
Dispatch a subagent:
  model: strongest available coding model
  role: general-purpose
  description: "Build task {task.id}"
  prompt: |
    ## Zig Builder: Task {task.id} - {task.name}

    Read and FOLLOW ALL procedures in these files:
    1. Your task spec: `.tasks/task-{task.id}.yaml`
    2. The `zig-builder` skill (MANDATORY): `~/.claude/skills/zig-builder/SKILL.md` — team workflow
    3. The `zig` skill (MANDATORY): `~/.claude/skills/zig/SKILL.md` — language, architecture, testing

    You MUST follow TDD (RED/GREEN/REFACTOR), hexagonal architecture, Zig idioms, error unions, and allocator management.
    Dependencies flow INWARD: adapters -> app -> ports -> domain. Domain has NO external deps.

    ## MANDATORY VERIFICATION - NON-NEGOTIABLE

    During RED/GREEN, run the narrowest test that proves the behavior. Before the first
    review, run the standard build and full suite once and ensure both pass:

    Select and export ZIG_TEAM_TEST_JOBS using the verification strategy above, then run:

    ```bash
    zig build
    zig build test -j"$ZIG_TEAM_TEST_JOBS"
    ```

    Do NOT mark as completed until ALL verification passes.

    Write your full results to: `.tasks/result-{task.id}-build.yaml`
    (format defined in the `zig-builder` skill — include verification results)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    status: complete|blocked
    summary: [one sentence]
    ```
```

### 3b: Combined Review

```
Dispatch a subagent:
  model: strongest available coding model
  role: code-quality-reviewer
  description: "Review task {task.id}"
  prompt: |
    ## Combined Review: Task {task.id} - {task.name}

    Read and EXECUTE ALL review procedures from these files:
    1. Task acceptance criteria: `.tasks/task-{task.id}.yaml`
    2. Build results: `.tasks/result-{task.id}-build.yaml`
    3. The `zig-reviewer` skill (MANDATORY): `~/.claude/skills/zig-reviewer/SKILL.md` — team workflow
    4. The `zig-code-review` skill (MANDATORY): `~/.claude/skills/zig-code-review/SKILL.md` — patterns + Dead Code Review

    Perform ALL review stages in a single pass:
    - Stage 1: Spec compliance (requirements met? under/over-building?)
    - Stage 2: Architecture compliance (hexagonal boundaries, dependency flow, build.zig enforcement)
    - Stage 3: Code quality (only if Stage 1 and 2 pass)
    - Stage 4: Dead Code Review (only if Stage 3 passes — six-check rule from zig-code-review)

    ## MANDATORY VERIFICATION - NON-NEGOTIABLE

    You MUST verify that the standard build and full suite passed in the build results:

    ```bash
    zig build
    zig build test -j"$ZIG_TEAM_TEST_JOBS"
    ```

    If build results show failures, verdict MUST be CHANGES_NEEDED.

    Read the source files listed in the build results and review them.

    Write your full results to: `.tasks/result-{task.id}-review.yaml`
    (format defined in the `zig-reviewer` skill — include verification status)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    verdict: APPROVED|CHANGES_NEEDED
    issues: [count of changes_required]
    ```
```

### 3c: Builder Fix

```
Dispatch a subagent:
  model: strongest available coding model
  role: general-purpose
  description: "Fix task {task.id}"
  prompt: |
    ## Fix Review Feedback: Task {task.id} - {task.name}

    Read and FOLLOW ALL procedures in these files:
    1. Task spec: `.tasks/task-{task.id}.yaml`
    2. Review feedback: `.tasks/result-{task.id}-review.yaml`
    3. The `zig-builder` skill (MANDATORY): `~/.claude/skills/zig-builder/SKILL.md` — team workflow + fix mode
    4. The `zig` skill (MANDATORY): `~/.claude/skills/zig/SKILL.md` — language, architecture, testing

    Fix each issue listed in `changes_required` in priority order.

    ## MANDATORY VERIFICATION - NON-NEGOTIABLE

    After fixing issues, re-run the project-defined focused regression. Re-run the full suite only for
    a broad-impact fix or when the reviewer explicitly requested it. Record the decision
    and evidence in the fix result:

    ```bash
    zig build
    # Reuse the same focused test command recorded in .tasks/result-{task.id}-build.yaml
    # (e.g. zig build test --test-filter "<name>") for the RED/GREEN behavior touched by this fix.
    # Broad-impact or reviewer-requested fixes only:
    zig build test -j"$ZIG_TEAM_TEST_JOBS"
    ```

    Do NOT mark as completed until the required verification passes.
    Commit fixes after verification passes.

    Write your fix results to: `.tasks/result-{task.id}-fix-{cycle}.yaml`
    (same format as build results - include verification results)

    **IMPORTANT**: Return ONLY this to the orchestrator (2 lines max):
    ```
    status: complete|blocked
    fixes: [count of issues fixed]
    ```
```

---

## Step 4: Phase/Project Completion

**NOTE**: The orchestrator does NOT run validation commands. Builders and reviewers are responsible for ensuring tests and build pass before marking their work complete.

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
Edit .phases/index.yaml:
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
## Zig Team Complete: Phase {PHASE.id} - {PHASE.name}
- Tasks completed: {count}
- Phase status: completed
- Next phase: {next_phase.name} (or "None - project complete")
```

---

## Error Handling

- **Missing dependency**: Check `.tasks/status.yaml`, reorder if needed
- **Unclear requirement**: ask the user, offering concrete options
- **Compile error**: Include error output in next builder dispatch
- **Review cycles exceeded (10)**: ask the user: skip / manual fix / abort
- **Stale .tasks/**: If task files reference nonexistent source, re-run Task Manager
- **No .phases/ found**: Direct user to run the `to-phases` skill first

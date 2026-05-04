---
name: to-phases
description: Interactive implementation phase planner. Creates or updates .plans/ directory with index.yaml and phase files. If a PRD exists, ensures phases cover all scenarios from the PRD.
arguments:
  - name: phase
    description: Specific phase number to add or update
    required: false
---

# To Phases - Implementation Phase Manager

## Overview

The To-Phases skill helps you create and manage implementation plans using a file-based structure that keeps orchestrator context lean. Plans are stored in `.plans/` with an index file and separate phase files.

**If a PRD exists** (`.plans/prd-*.md`), this skill ensures phases cover all scenarios from the PRD.

**Structure:**
```
.plans/
├── prd-{feature-name}.md   # PRD (optional, created by to-prd)
├── index.yaml              # Lean summary (orchestrator reads ONLY this)
├── phase-01-project-setup.md
├── phase-02-core-domain.md
└── ...
```

## EXECUTION INSTRUCTIONS

When this skill is invoked via `/to-phases`:

### Step 0: Check for PRD

```
Check if .plans/prd-*.md exists:
  if exists:
    Read the PRD
    Note all user stories and implementation decisions
    Use these to guide phase creation
  else:
    Continue with standard phase planning
```

**IMPORTANT:** If a PRD exists, phases MUST cover:
- All user stories from the PRD
- All modules identified in implementation decisions
- All testing requirements from testing decisions

### Step 1: Check Existing State

```
if file_exists(".plans/index.yaml"):
    Read and display current state (Append/Update Mode)
else:
    Create new plan (Create Mode)
```

---

### Create Mode

#### 1a. Prompt for Project Name

Use AskUserQuestion:

**Question**: "What is the project name?"
- Header: "Project"
- This is REQUIRED. Do not proceed without a project name.

#### 1b. Collect Phases

**If PRD exists:**
1. Analyze PRD user stories and group them into logical phases
2. Present proposed phases to user for approval
3. Use AskUserQuestion to confirm or modify phases

**If no PRD:**
For each phase, ask the user:

1. **Phase name** - Short descriptive name (e.g., "Project Setup", "Core Domain")
2. **Tasks** - List of implementation tasks as checklist items

Use AskUserQuestion:

**Question**: "Describe Phase {N}: {name}"
- Header: "Phase {N}"
- Ask for the tasks as a list. Each task should be a concrete, completable item.

After each phase, ask:

**Question**: "Add another phase?"
- Header: "More?"
- Options: "Yes, add another", "No, done with phases"

Continue until the user is done.

#### 1c. Validate PRD Coverage (if PRD exists)

Before writing files, verify:
- [ ] All user stories from PRD are covered by at least one phase
- [ ] All modules from implementation decisions are addressed
- [ ] Testing decisions are reflected in appropriate phases

If coverage is incomplete, warn the user and ask if they want to add phases.

#### 1d. Write the Files

1. Create `.plans/` directory if needed: `mkdir -p .plans`
2. Write `.plans/index.yaml` (format below)
3. Write `.plans/phase-{NN}-{slug}.md` for each phase (format below)

---

### Append/Update Mode

#### 2a. Display Current State

Read `.plans/index.yaml` and display:

```
Project: {project_name}
PRD: {prd_file} (if exists)
Current Phase: {current_phase}

Phases:
  1. {name} [{status}] {progress}
  2. {name} [{status}] {progress}
  ...
```

#### 2b. Determine Action

Ask the user:

**Question**: "What would you like to do?"
- Header: "Action"
- Options:
  - "Add new phase"
  - "Update existing phase"
  - "View phase details"
  - "Validate PRD coverage" (only if PRD exists)
  - "Cancel"

#### 2c. Handle Action

**Add new phase**: Follow the same flow as Create Mode step 1b, but append to existing phases.

**Update existing phase**:
1. Ask which phase to update
2. Read the phase file
3. Ask what to change (add tasks, mark complete, edit tasks)
4. Update the phase file and sync progress to index.yaml

**View phase details**: Read and display the requested phase file.

**Validate PRD coverage**:
1. Read the PRD
2. Check each user story is covered by phases
3. Report uncovered stories
4. Offer to create additional phases

---

## Output Formats

### `.plans/index.yaml` (Lean - orchestrator reads only this)

```yaml
project: "{PROJECT_NAME}"
prd: "prd-{feature-name}.md"  # Optional: reference to PRD if exists
current_phase: {PHASE_NUMBER}
phases:
  - id: 1
    name: "{PHASE_NAME}"
    file: "phase-01-{slug}.md"
    status: completed    # pending | in_progress | completed
    progress: "4/4"      # completed/total tasks
  - id: 2
    name: "{PHASE_NAME}"
    file: "phase-02-{slug}.md"
    status: in_progress
    progress: "3/8"
  - id: 3
    name: "{PHASE_NAME}"
    file: "phase-03-{slug}.md"
    status: pending
    progress: "0/6"
```

### `.plans/phase-{NN}-{slug}.md` (Full details - subagents read these)

```markdown
# Phase {N}: {PHASE_NAME}

## PRD Reference

Covers user stories: #1, #3, #5-7 from {prd-file}

## Tasks

- [ ] {Task description}
- [ ] {Task description}
- [x] {Completed task description}

## Notes

{Optional implementation notes, hints, or constraints}
```

### File Naming

- Phase files use zero-padded numbers: `phase-01-`, `phase-02-`, etc.
- Slugs are lowercase, hyphenated: `project-setup`, `core-domain`
- Example: `phase-02-core-domain.md`

---

## Status Management

### Phase Status Rules

| Status | Meaning |
|--------|---------|
| `pending` | No tasks started |
| `in_progress` | At least one task completed, not all done |
| `completed` | All tasks completed |

### Progress Tracking

- Progress is `{completed}/{total}` from the phase file
- When a task is checked off in the phase file, update progress in index.yaml
- Status auto-updates based on progress:
  - `0/N` → `pending`
  - `1/N` to `N-1/N` → `in_progress`
  - `N/N` → `completed`

### Current Phase

- `current_phase` in index.yaml points to the active phase
- Automatically advances when a phase completes
- Can be manually set by user

---

## Integration with Other Skills

Team skills (go-team, node-team, zig-team) read from `.plans/`:

| Who | Reads | Purpose |
|-----|-------|---------|
| Orchestrator | `.plans/index.yaml` | Status overview, find current phase |
| Task Manager | `.plans/phase-*.md` | Full task details for breakdown |
| Task Manager | `.plans/prd-*.md` (optional) | PRD context if needed |
| Builder/Reviewer | `.tasks/*.yaml` | Task specs (created by Task Manager) |

### Workflow

1. `/to-prd` creates `.plans/prd-*.md` (optional)
2. `/to-phases` creates `.plans/` structure (index.yaml + phase files)
3. `/go-team` (or node-team, zig-team) reads index.yaml to find current phase
4. Task Manager reads the phase file (and PRD if needed), breaks into `.tasks/`
5. Builder/Reviewer work from `.tasks/` files
6. On task completion, orchestrator updates:
   - `.tasks/status.yaml` (task status)
   - `.plans/phase-*.md` (checkbox)
   - `.plans/index.yaml` (progress)

---

## Examples

### Example index.yaml (with PRD)

```yaml
project: "structured-cli"
prd: "prd-structured-command-parser.md"
current_phase: 2
phases:
  - id: 1
    name: "Project Setup"
    file: "phase-01-project-setup.md"
    status: completed
    progress: "4/4"
  - id: 2
    name: "Core Domain & Ports"
    file: "phase-02-core-domain.md"
    status: in_progress
    progress: "5/8"
  - id: 3
    name: "Parser Implementation"
    file: "phase-03-parsers.md"
    status: pending
    progress: "0/6"
```

### Example phase-02-core-domain.md (with PRD reference)

```markdown
# Phase 2: Core Domain & Ports

## PRD Reference

Covers user stories: #1-5, #8 from prd-structured-command-parser.md

Implements modules:
- Command domain model
- ParseResult type
- CommandRunner interface

## Tasks

- [x] Define `domain/command.go` (Command, CommandSpec types)
- [x] Define `domain/result.go` (ParseResult type)
- [x] Define `domain/schema.go` (Schema type)
- [x] Define `ports/runner.go` (CommandRunner interface)
- [x] Define `ports/parser.go` (Parser, ParserRegistry interfaces)
- [ ] Define `ports/writer.go` (OutputWriter interface)
- [ ] Define `ports/schema.go` (SchemaRepository interface)
- [ ] Add unit tests for domain types

## Notes

- Follow hexagonal architecture
- Domain types should have no external dependencies
- Use value objects where appropriate
```

---

## Anti-Patterns

- Putting all phases in a single file (defeats context savings)
- Storing full task details in index.yaml (keep it lean)
- Not syncing progress between phase files and index.yaml
- Using PLAN.md instead of `.plans/` structure
- Ignoring PRD when it exists - phases must cover all scenarios
- Not validating PRD coverage before finalizing phases
- Including PRD content in phase files (just reference it)

---
name: to-phases
description: To Phases - Implementation Phase Manager
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


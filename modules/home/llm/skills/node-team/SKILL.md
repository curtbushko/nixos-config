---
name: node-team
description: Implements phases defined in .phases/ directory for Node.js projects. Reads current phase from index.yaml, breaks down into tasks, then executes Builder -> Reviewer for each task.
---

# Node Team - Coordinated Agent Workflow

## EXECUTION INSTRUCTIONS

**Follow the orchestration procedure in `references/orchestration.md`.**

**DO NOT read** `references/builder-context.md`, `references/reviewer-context.md`, or `references/examples.md`. Those are read by subagents only.

---

## Overview

The Node Team skill implements features you define. You provide the WHAT (plan phases), it handles the HOW (implementation).

```mermaid
flowchart TD
    PLANS[".phases/ (you create with the to-phases skill)<br/>- index.yaml (status overview)<br/>- phase-*.md (task checklists)"]

    TASK_MGR["TASK MANAGER (subagent)<br/>- Reads phase-*.md file<br/>- Breaks into right-sized tasks<br/>- Writes to .tasks/ files<br/>- Returns task count only"]

    LOOP{{"For each task<br/>(dependency order)"}}

    BUILDER["NODE BUILDER (subagent)<br/>- Reads: task spec + builder-context.md<br/>- Follows TDD: RED → GREEN → REFACTOR<br/>- Writes to result-build.yaml<br/>- Returns status + 1-line summary"]

    REVIEWER["NODE REVIEWER (subagent)<br/>- Reads: task spec + build results<br/>- Reviews: spec compliance THEN quality<br/>- Writes to result-review.yaml<br/>- Returns verdict + issue count"]

    APPROVED["APPROVED<br/>Next task"]
    CHANGES["CHANGES<br/>NEEDED"]
    FIX["NODE BUILDER<br/>(reads review<br/>from file)"]

    PLANS --> TASK_MGR
    TASK_MGR --> LOOP
    LOOP --> BUILDER
    BUILDER --> REVIEWER
    REVIEWER --> APPROVED
    REVIEWER --> CHANGES
    CHANGES --> FIX
    FIX --> REVIEWER
```

### Context-Saving Design

All subagents communicate via `.tasks/` files. The orchestrator only reads
`.phases/index.yaml` for status - never source code or detailed results.
This keeps the orchestrator's context lean across many tasks and phases.

## Invocation

Invoke this skill by name (`node-team`). It accepts two optional arguments; how they
are passed depends on the agent host:

- (no arguments) — work on the current phase from `.phases/index.yaml`
- `phase=<N>` — work on a specific phase number
- `task=<N>` — implement only a specific task (after initial planning)

### Model Assignment (Recommended)

The orchestrator only reads status files and dispatches subagents - it doesn't write
code. When the host supports per-agent model selection, run the orchestrator and Task
Manager on a cheaper/faster model and give the Builder and Reviewer a stronger model
for implementation:

- Orchestrator: cheaper/faster model (session model)
- Task Manager: cheaper/faster model
- Builder: strongest available coding model
- Reviewer: strongest available coding model

## Arguments

| Argument | Default | Description |
|----------|---------|-------------|
| `phase` | (current) | Specific phase number from `.phases/index.yaml` |
| `task` | (all) | Specific task number to implement (optional) |

---

## Phase Structure (.phases/)

Phases are created with the `to-phases` skill and stored in `.phases/`:

```
.phases/
├── index.yaml              # Lean status (orchestrator reads ONLY this)
├── phase-01-project-setup.md
├── phase-02-components.md
└── ...
```

### index.yaml (Orchestrator reads this)

```yaml
project: "my-node-project"
current_phase: 2
phases:
  - id: 1
    name: "Project Setup"
    file: "phase-01-project-setup.md"
    status: completed
    progress: "4/4"
  - id: 2
    name: "Core Components"
    file: "phase-02-components.md"
    status: in_progress
    progress: "3/8"
```

### phase-*.md (Task Manager reads these)

```markdown
# Phase 2: Core Components

## Tasks

- [x] Create user service with CRUD operations
- [x] Add input validation middleware
- [ ] Implement authentication controller
- [ ] Add unit tests for user service

## Notes

- Use existing error handling patterns from src/errors/
- JWT secret should come from environment config
```

---

## Agents and Their Context

Each agent is a subagent dispatched by the orchestrator. The orchestrator does NOT read these files - subagents read their own context.

| Agent | Role | Context File |
|-------|------|--------------|
| **Task Manager** | Parses phase file, explores codebase, creates task breakdown | `.phases/phase-*.md` |
| **Node Builder** | Implements tasks following TDD, component architecture | `references/builder-context.md` |
| **Node Reviewer** | Combined review: spec compliance + code quality in one pass | `references/reviewer-context.md` |

See `references/orchestration.md` for exact dispatch templates and the coordination loop.

---

## Anti-Patterns

- Orchestrator reading source code, result files, or reference files (subagents do this)
- Orchestrator reading `.phases/phase-*.md` files (Task Manager does this)
- Orchestrator echoing or summarizing full subagent output (wastes context)
- Inlining phase content into dispatch prompts (reference by file path instead)
- Dispatching multiple builders in parallel (causes conflicts)
- Proceeding with CHANGES_NEEDED status
- Ignoring security vulnerabilities
- Marking task complete with failing tests/lint

---

## Integration with Other Skills

- **planner**: Use the `to-phases` skill to create the `.phases/` structure before running the `node-team` skill
- **prd/rfc**: Use these to write the feature specification before implementing

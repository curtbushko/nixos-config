---
name: zig-team
description: Implements phases defined in .phases/ directory for Zig projects. Reads current phase from index.yaml, breaks down into tasks, then executes Builder -> Reviewer for each task. All Zig projects follow hexagonal architecture with compile-time boundary enforcement via build.zig modules.
---

# Zig Team - Coordinated Agent Workflow

## EXECUTION INSTRUCTIONS

**Follow the orchestration procedure in `references/orchestration.md`.**

**DO NOT read** `references/builder-context.md` or `references/reviewer-context.md`. Those are read by subagents only.

---

## Overview

The Zig Team skill implements features you define. You provide the WHAT (plan phases), it handles the HOW (implementation). All Zig projects follow hexagonal architecture (ports and adapters) with compile-time boundary enforcement via `build.zig` modules.

```mermaid
flowchart TD
    PLANS[".phases/ (you create with the to-phases skill)<br/>- index.yaml (status overview)<br/>- phase-*.md (task checklists)"]

    TASK_MGR["TASK MANAGER (subagent)<br/>- Reads phase-*.md file<br/>- Breaks into right-sized tasks<br/>- Writes to .tasks/ files<br/>- Returns task count only"]

    LOOP{{"For each task<br/>(dependency order)"}}

    BUILDER["ZIG BUILDER (subagent)<br/>- Reads: task spec + builder-context.md<br/>- Follows TDD: RED → GREEN → REFACTOR<br/>- Writes to result-build.yaml<br/>- Returns status + 1-line summary"]

    REVIEWER["ZIG REVIEWER (subagent)<br/>- Reads: task spec + build results<br/>- Reviews: spec compliance THEN quality<br/>- Writes to result-review.yaml<br/>- Returns verdict + issue count"]

    APPROVED["APPROVED<br/>Next task"]
    CHANGES["CHANGES<br/>NEEDED"]
    FIX["ZIG BUILDER<br/>(reads review<br/>from file)"]

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

Invoke this skill by name (`zig-team`). It accepts two optional arguments; how they
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
├── phase-02-core-modules.md
└── ...
```

### index.yaml (Orchestrator reads this)

```yaml
project: "my-zig-project"
current_phase: 2
phases:
  - id: 1
    name: "Project Setup"
    file: "phase-01-project-setup.md"
    status: completed
    progress: "4/4"
  - id: 2
    name: "Core Modules"
    file: "phase-02-core-modules.md"
    status: in_progress
    progress: "3/8"
```

### phase-*.md (Task Manager reads these)

```markdown
# Phase 2: Core Modules

## Tasks

- [x] Define parser interface in src/parser.zig
- [x] Implement tokenizer with comptime lookup
- [ ] Add error handling with error unions
- [ ] Write tests for parser edge cases

## Notes

- Use comptime for lookup tables where possible
- Allocator should be passed explicitly
- Follow Zig style guide for naming
```

---

## Architecture Rules

**Non-negotiable** (enforced by builders and reviewers, all inlined in their context files):
- Dependencies flow INWARD: adapters -> application -> ports -> domain
- Domain layer has NO external dependencies (no std.net, no std.fs, no C imports)
- Layer boundaries are enforced at compile time via `build.zig` module isolation
- Prefer comptime generics for ports; vtable structs only when runtime polymorphism is needed
- All adapters with resources MUST have explicit `init()` / `deinit()` lifecycle

---

## Agents and Their Context

Each agent is a subagent dispatched by the orchestrator. The orchestrator does NOT read these files - subagents read their own context.

| Agent | Role | Context File |
|-------|------|--------------|
| **Task Manager** | Parses phase file, explores codebase, creates task breakdown | `.phases/phase-*.md` |
| **Zig Builder** | Implements tasks following TDD, hexagonal architecture, Zig best practices | `references/builder-context.md` |
| **Zig Reviewer** | Combined review: spec compliance + architecture compliance + code quality | `references/reviewer-context.md` |

See `references/orchestration.md` for exact dispatch templates and the coordination loop.

---

## Anti-Patterns

- Orchestrator reading source code, result files, or reference files (subagents do this)
- Orchestrator reading `.phases/phase-*.md` files (Task Manager does this)
- Orchestrator echoing or summarizing full subagent output (wastes context)
- Inlining phase content into dispatch prompts (reference by file path instead)
- Dispatching multiple builders in parallel (causes conflicts)
- Proceeding with CHANGES_NEEDED status
- Ignoring memory safety issues
- Marking task complete with failing tests
- Putting business logic in adapters (adapters only translate between external formats and domain types)
- Importing std.net, std.fs, or C libraries in domain layer
- Modifying `build.zig` to add cross-layer imports without architectural review

---

## Integration with Other Skills

- **planner**: Use the `to-phases` skill to create the `.phases/` structure before running the `zig-team` skill
- **prd/rfc**: Use these to write the feature specification before implementing

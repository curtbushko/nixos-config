---
name: write-phase
description: Synthesize the current conversation into a single new phase for .phases/. Use when you've discussed a feature and want to capture it as an implementation phase without running the full /to-phases interactive flow.
---

# Write Phase - Conversation to Single Phase

## Overview

Takes the context from the current conversation (decisions made, requirements discussed, approaches agreed upon) and creates a **single** new phase file in the `.phases/` structure.

**Use this when:**
- You've discussed a feature/task and want to capture it as a phase
- You want to add a phase without the full `/to-phases` interactive flow
- You're mid-conversation and want to formalize what was discussed

**Use `/to-phases` instead when:**
- Starting fresh from a PRD
- Creating multiple phases at once
- Managing existing phases (update, view, validate)

## EXECUTION INSTRUCTIONS

When this skill is invoked via `/write-phase`:

### Step 1: Check Prerequisites

```
if not file_exists(".phases/index.yaml"):
    Use AskUserQuestion:
      Question: "No .phases/ structure found. What would you like to do?"
      Header: "Setup"
      Options:
        - "Create minimal index.yaml" (I'll create .phases/ with a basic index)
        - "Exit" (I'll run /to-phases first to set up properly)
```

If user chooses "Create minimal index.yaml":
```yaml
# .phases/index.yaml
project: "{infer from directory name or ask}"
current_phase: 1
phases: []
```

### Step 2: Analyze Conversation

Review the current conversation to extract:
- What feature/functionality was discussed
- What decisions were made
- What approach was agreed upon
- What files need to be created/modified
- What tests are needed

### Step 3: Confirm Understanding

Use AskUserQuestion to confirm:

**Question**: "Based on our discussion, I'll create a phase for: {one-line summary}. Is this correct?"
- Header: "Phase"
- Options: "Yes, create it", "Let me clarify..."

If user selects "Let me clarify...", wait for their input and re-confirm.

### Step 4: Create Phase

1. **Read `.phases/index.yaml`** to determine next phase number

2. **Generate slug** from phase name (lowercase, hyphenated)

3. **Create phase file** at `.phases/phase-{NN}-{slug}.md`:

```markdown
# Phase {N}: {PHASE_NAME}

## Context

{Brief summary of what was discussed and decided in the conversation}

## Tasks

- [ ] {Task with exact file path where applicable}
- [ ] {Task with exact file path where applicable}
...

## Notes

{Key decisions, constraints, or implementation hints from discussion}
```

4. **Update `.phases/index.yaml`** - append new phase entry:

```yaml
  - id: {N}
    name: "{PHASE_NAME}"
    file: "phase-{NN}-{slug}.md"
    status: pending
    progress: "0/{total_tasks}"
```

### Step 5: Report

Display:
```
Created phase {N}: {PHASE_NAME}

File: .phases/phase-{NN}-{slug}.md

Tasks:
1. {task 1}
2. {task 2}
...

Next: Run /go-team (or /node-team, /zig-team) to implement
```

---

## Task Granularity

Each task should be:
- **Concrete and completable** - not vague ("improve performance")
- **Include exact file paths** where applicable
- **Follow TDD** - test file first, then implementation
- **2-5 minute scope** - small enough to complete quickly

**Good tasks:**
- `Create test file internal/parser/parser_test.go with TestParse_ValidInput`
- `Implement Parse() method in internal/parser/parser.go`
- `Add error handling for empty input in Parse()`

**Bad tasks:**
- `Write the parser` (too vague)
- `Add tests` (which tests? where?)
- `Fix bugs` (what bugs?)

---

## Phase File Format

```markdown
# Phase {N}: {PHASE_NAME}

## Context

{Why this phase exists - what problem it solves, what was decided}

## Tasks

- [ ] {Specific task with file path}
- [ ] {Specific task with file path}

## Notes

{Implementation hints, constraints, dependencies on other phases}
```

---

## Anti-Patterns

- Creating phases without confirming understanding first
- Vague tasks without file paths or specific actions
- Not updating index.yaml after creating phase file
- Creating multiple phases (use /to-phases for that)
- Ignoring existing conversation context

---

## Integration with Other Skills

```
[Conversation] → /write-phase → /go-team
   (Discuss)      (Capture)      (Execute)
```

This skill captures a single phase from conversation. For full phase management from a PRD, use `/to-phases`.

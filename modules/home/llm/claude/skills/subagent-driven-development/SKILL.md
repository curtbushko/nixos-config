---
name: subagent-driven-development
description: Use when executing implementation plans with multiple tasks. Dispatches fresh subagent per task with two-stage review (spec compliance then code quality).
---

# Subagent-Driven Development

## Core Principle

**Fresh subagent per task + two-stage review = high quality, fast iteration**

Use when you have an implementation plan with multiple mostly-independent tasks and want to stay in the same session.

## Why Fresh Context Per Task?

- Prevents context pollution from previous tasks
- Each subagent focuses on ONE thing
- Reduces confusion and cross-contamination
- Enables parallel thinking about different aspects

## The Process

For each task in the plan:

### Step 1: Dispatch Implementer

Use the Task tool to dispatch an implementer subagent:

```
Implement [Task Name] from the plan.

Context:
- [Provide full task details from plan]
- [Include relevant file paths]
- [Include acceptance criteria]

Requirements:
1. Follow TDD - write failing test first
2. Implement minimal code to pass
3. Run tests to verify
4. Commit with descriptive message
5. Self-review before signaling completion
```

### Step 2: Handle Questions

If implementer asks questions, answer them before proceeding.

### Step 3: Two-Stage Review (CRITICAL ORDER)

**Stage A: Spec Compliance Review**

Dispatch spec reviewer subagent:

```
Review [Task Name] for spec compliance.

Original spec:
[Paste the task specification]

Check:
1. Does implementation match spec EXACTLY?
2. No under-building (missing requirements)?
3. No over-building (extra features)?
4. All acceptance criteria met?

If issues found, list them for implementer to fix.
```

**Stage B: Code Quality Review** (only after spec passes)

Dispatch code quality reviewer subagent:

```
Review [Task Name] for code quality.

Check:
1. TDD followed (tests exist and meaningful)?
2. Code follows project patterns?
3. Error handling appropriate?
4. No code smells?
5. Hexagonal architecture respected (Go)?

If issues found, list them for implementer to fix.
```

### Step 4: Fix and Re-Review

If either review finds issues:
1. Dispatch implementer to fix specific issues
2. Re-run the review that found issues
3. Repeat until both reviews pass

### Step 5: Mark Complete

Only mark task complete when BOTH reviews pass.

### Step 6: Repeat

Continue with next task in plan.

## Red Flags - STOP If:

- Skipping either review stage
- Proceeding with unfixed issues
- Running code quality before spec compliance
- Dispatching multiple implementers in parallel (causes conflicts)
- "Close enough" on spec compliance
- Making subagent read plan file (provide full text instead)

## Two-Stage Review Rationale

**Why spec first, quality second?**

1. **Spec compliance** answers: "Did we build the right thing?"
2. **Code quality** answers: "Did we build it right?"

Building the wrong thing well is worse than building the right thing poorly.

## Quick Reference

```
For each task:
  1. Dispatch implementer → implements + tests + commits
  2. Dispatch spec reviewer → confirms matches requirements
     - If fails: implementer fixes, re-review
  3. Dispatch quality reviewer → confirms code quality
     - If fails: implementer fixes, re-review
  4. Both pass → mark complete
  5. Next task
```

## After All Tasks Complete

1. Dispatch final code reviewer for entire implementation
2. Address any cross-cutting concerns
3. Run full test suite
4. Prepare for merge/PR

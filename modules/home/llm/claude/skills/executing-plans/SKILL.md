---
name: executing-plans
description: Use when you have a written implementation plan and need to execute it. Batch execution with checkpoints for review between batches.
---

# Executing Plans

## Core Principle

**Batch execution with checkpoints for architect review.**

Use when you have a written implementation plan and are executing in a session (possibly separate from planning).

## The Process

### Step 1: Load and Review Plan

1. Read the plan file completely
2. Review critically for:
   - Unclear instructions
   - Missing information
   - Potential issues
3. If concerns: Raise with user BEFORE starting
4. If clear: Create task list and proceed

### Step 2: Execute Batch (Default: 3 tasks)

For each task in the batch:

1. Mark task as `in_progress`
2. Follow each step EXACTLY as written in plan
3. Run verifications as specified
4. If verification fails: STOP, report issue
5. If passes: Mark task as `completed`

### Step 3: Report After Batch

After completing a batch, report:

```
## Batch Complete

### Implemented:
- Task 1: [Brief description]
- Task 2: [Brief description]
- Task 3: [Brief description]

### Verification Output:
[Show test results, build output]

### Issues Found:
[Any problems encountered]

Ready for feedback.
```

### Step 4: Wait for Feedback

Do NOT proceed to next batch until user responds.

User may:
- Approve and continue
- Request changes
- Adjust remaining plan
- Stop execution

### Step 5: Continue or Complete

If approved:
- Execute next batch
- Repeat steps 2-4

If all tasks complete:
- Run full test suite
- Run linter
- Report final status

## When to STOP and Ask

Stop execution immediately if:

- **Blocker mid-batch** - Missing dependency, unexpected state
- **Test fails repeatedly** - After 2 attempts
- **Plan has gaps** - Missing information needed to proceed
- **Unclear instruction** - Don't guess, ask
- **Architecture concern** - Something seems wrong

Never guess. Ask for clarification.

## Gate Function

```
BEFORE starting execution:
  Ask: "Am I on main/master branch?"

  IF yes:
    STOP - Get explicit consent before modifying main
    OR create feature branch first

BEFORE each task:
  Ask: "Do I understand exactly what to do?"

  IF no:
    STOP - Ask for clarification
    Do NOT proceed with assumptions

AFTER each verification:
  Ask: "Did it pass?"

  IF no:
    STOP - Report failure
    Do NOT continue to next task
```

## Batch Size Guidelines

| Situation | Batch Size |
|-----------|------------|
| Simple, independent tasks | 3-5 tasks |
| Complex, interdependent | 1-2 tasks |
| First batch (calibration) | 2-3 tasks |
| After issues found | 1 task |

## Quick Reference

```
1. Load plan, review critically
2. Raise concerns BEFORE starting
3. Execute batch (default 3 tasks)
4. Report results
5. Wait for feedback
6. Continue or adjust
7. Repeat until complete
8. Final verification
```

## Integration with Other Skills

- **writing-plans** - Creates the plan this skill executes
- **subagent-driven-development** - Alternative execution model
- **systematic-debugging** - Use when tasks fail unexpectedly

---
name: systematic-debugging
description: Use when debugging fails, bugs reappear after fixes, or you're tempted to "just try something". Enforces root cause investigation before any fix attempt.
---

# Systematic Debugging

## Core Principle

**NO FIXES WITHOUT ROOT CAUSE INVESTIGATION FIRST**

Random or quick fixes mask underlying issues and create new bugs. Systematic debugging takes 15-30 minutes vs hours of thrashing, with 95% first-time fix rate.

## The Four Phases

### Phase 1: Root Cause Investigation

Before proposing ANY fix:

1. **Read error messages carefully** - The actual error, not just the symptom
2. **Reproduce consistently** - If you can't reproduce, you don't understand it
3. **Check recent changes** - What changed since it last worked?
4. **Trace data flow** - Follow the data from source to error point
5. **Gather evidence** - Logs, state snapshots, network requests

### Phase 2: Pattern Analysis

1. **Find working examples** - What works that's similar?
2. **Compare against references** - Official docs, known-good code
3. **Identify differences** - What's different between working and broken?
4. **Understand dependencies** - What does this code depend on?

### Phase 3: Hypothesis and Testing

1. **Form ONE clear hypothesis** - "The bug occurs because X"
2. **Test minimally** - Change ONE variable at a time
3. **Verify before continuing** - Did your change have the expected effect?
4. **Document findings** - What did you learn?

### Phase 4: Implementation

1. **Write failing test first** - Capture the bug in a test
2. **Implement single fix** - Address the ROOT CAUSE only
3. **Verify fix** - Run the test, confirm it passes
4. **Check for regressions** - Run full test suite

## Red Flags - STOP If You Hear Yourself Say:

- "Quick fix for now, investigate later"
- "Just try changing X and see if it works"
- "Let me try a few things"
- "One more fix attempt" (when already tried 2+)
- Proposing solutions BEFORE tracing data flow

## Gate Function

```
BEFORE proposing any fix:
  Ask: "Do I know the ROOT CAUSE?"

  IF no:
    STOP - Return to Phase 1
    Do NOT propose fixes

  IF yes:
    Document the root cause
    THEN propose targeted fix
```

## When Multiple Fixes Have Failed

If 3+ fix attempts have failed:

1. **STOP all fix attempts**
2. **Return to Phase 1** - You missed something
3. **Question assumptions** - What are you assuming that might be wrong?
4. **Consider architecture** - Is the design fundamentally flawed?

## Quick Reference

| Situation | Action |
|-----------|--------|
| Error message appears | Read it completely, trace to source |
| "It was working before" | Check git diff, recent changes |
| Intermittent bug | Add logging, reproduce consistently first |
| Fix didn't work | Return to investigation, don't try another fix |
| 3+ failed fixes | Stop, reassess entire approach |

## Integration with TDD

Systematic debugging IS TDD applied to bugs:

1. **RED** - Write test that reproduces the bug
2. **Investigate** - Find root cause (this skill)
3. **GREEN** - Fix the root cause, test passes
4. **REFACTOR** - Clean up, ensure no regressions

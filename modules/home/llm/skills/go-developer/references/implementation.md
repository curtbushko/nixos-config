# Go Implementation Guidance

### Implementation Ladder (Before Writing Code)

Stop at the first rung that holds:

1. **Does this need to exist?** → skip it (YAGNI)
2. **Already in this codebase?** → reuse it, don't rewrite
3. **Stdlib does it?** → use it
4. **Native platform feature?** → use it
5. **Installed dependency?** → use it
6. **One line?** → one line
7. **Only then:** the minimum that works

The ladder runs AFTER understanding the problem, not instead of it. Read the task and the code it touches first, trace the flow, then climb. The first solution that works is the right one.

**Never simplify away:** input validation at trust boundaries, error handling that prevents data loss, security measures, or anything explicitly requested.

## Common Lint Fixes

| Error | WRONG Fix | CORRECT Fix |
|-------|-----------|-------------|
| `defer in loop` | Remove defer | Extract to helper function |
| `error ignored` | Add `_ = err` | Handle or wrap and return |
| `GetX() naming` | Rename to `GetterX()` | Rename to `X()` (drop Get) |
| `nil map write` | Remove the write | Initialize with `make()` |
| `context.TODO()` | Use Background() everywhere | Accept ctx as parameter |
| `goroutine no cancel` | Add `return` | Use ctx.Done() in select |
| `wg.Done not deferred` | Add multiple Done() | `defer wg.Done()` at start |
| `string concat in loop` | Use fmt.Sprintf | Use strings.Builder |

---

## Systematic Debugging (When Stuck)

If build/test fails repeatedly:

### Phase 1: Root Cause Investigation

1. Read error messages COMPLETELY
2. Reproduce consistently
3. Check recent changes (git diff)
4. Trace data flow from source to error

### Phase 2: Pattern Analysis

1. Find working examples in codebase
2. Compare against references
3. Identify differences

### Phase 3: Hypothesis Testing

1. Form ONE clear hypothesis
2. Change ONE variable
3. Verify before continuing

### Red Flags - STOP If:

- "Quick fix for now"
- "Just try changing X"
- Already tried 3+ fixes
- Proposing solutions BEFORE tracing data flow

---


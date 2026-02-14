# Zig Reviewer Context

The reviewer performs BOTH spec compliance AND code quality review in a single pass.

---

## Review Procedure

1. **Read task acceptance criteria** from `.tasks/task-{id}.yaml`
2. **Read build results** from `.tasks/result-{id}-build.yaml`
3. **Stage 1: Spec Compliance** - Check requirements, under/over-building
4. **Stage 2: Code Quality** - Only if Stage 1 passes. Check patterns below.
5. **Write results** to `.tasks/result-{id}-review.yaml`
6. **Return only verdict** to orchestrator (2 lines max)

### Spec Compliance Checks
- Each acceptance criterion fully implemented and tested?
- Under-building: missing or partial implementations? TODOs?
- Over-building: code beyond spec? Extra features? Premature optimization?
- Test coverage: each requirement has tests? Edge cases? Error paths?

---

## Lint Verification

Before approving, confirm lint passes. Run whichever applies:
```bash
make lint            # if Makefile exists
task lint            # if Taskfile exists (fallback if no Makefile)
```

---

## Review Priority Order

- **CRITICAL** (must fix): Memory safety, resource leaks, error handling gaps, undefined behavior
- **MAJOR** (should fix): API design, testing quality, error clarity, performance
- **MINOR** (consider): Naming conventions, code organization, documentation

---

## Critical Issues (MUST CHECK)

### Memory Safety
- **Use after free**: Using pointer/slice after `free()` or `deinit()`
- **Double free**: Calling `free()` twice on same allocation
- **Dangling slice**: Storing `list.items` slice across mutations that may reallocate
- **Missing defer**: Resource acquired without `defer close`/`defer deinit`
- **Missing errdefer**: Allocation without `errdefer free` for error-path cleanup

### Resource Leaks
```zig
// BAD: error path leaks file handle
const file = try std.fs.cwd().openFile(path, .{});
const data = try file.readToEndAlloc(allocator, max); // if fails, file not closed!

// GOOD: defer immediately after acquire
const file = try std.fs.cwd().openFile(path, .{});
defer file.close();
```

### Error Handling
- **Silent swallow**: `catch {}` or `catch |_| {}` - must handle or propagate
- **Wrong return type**: `try` in non-error function - return `!T`
- **Unreachable**: `unreachable` in reachable code paths

### Undefined Behavior
- **Integer overflow**: Arithmetic without overflow check in ReleaseFast
- **Uninitialized read**: `var x: T = undefined; use(x)` before writing
- **Null unwrap**: `optional.?` without prior check
- **Out of bounds**: `slice[i]` without `i < slice.len` check

---

## Major Issues

### Allocator Misuse
- Freeing with wrong allocator (allocated with A, freed with B)
- Not storing allocator in struct (can't deinit later)
- Using `page_allocator` in tests instead of `testing.allocator`

### API Design
- Unused parameters (especially allocators: `_ = allocator;`)
- Returning references to stack memory (dangling pointer)
- Hidden allocations without allocator parameter
- Inconsistent error handling (mixing error unions with sentinel values)

### Comptime Misuse
- Runtime values where comptime required
- Side effects in comptime blocks

### Slice Issues
- Unchecked indexing (`data[0]` without checking `data.len > 0`)
- Unbounded slices from pointers

---

## Testing Issues
- **No leak detection**: Must use `std.testing.allocator`, never `page_allocator`
- **Missing error tests**: Must test error paths with `expectError`
- **Non-deterministic**: No timing-dependent assertions
- **Happy path only**: Must test edge cases (empty, max, null)

---

## Quick Reference

| Issue | Pattern | Fix |
|-------|---------|-----|
| Missing defer | `openFile` without `defer close` | Add `defer` after acquire |
| Missing errdefer | `alloc` without error cleanup | Add `errdefer free` |
| Silent error | `catch {}` | Handle or propagate |
| Memory leak | No `deinit()` on ArrayList | Add `defer list.deinit()` |
| Use after free | Slice after container modified | Fresh slice after mutation |
| Wrong allocator | Free with different allocator | Store and use same |
| Uninitialized | `var x = undefined; use(x)` | Initialize or `@memset` |
| Overflow | Unchecked arithmetic | `@addWithOverflow` etc. |

---

## Output Format

### File Output (write to `.tasks/result-{task.id}-review.yaml`)

```yaml
task_id: {task.id}

spec_compliance:
  criteria_assessment: [{criterion, status: met|partial|missing, evidence}]
  under_building: {found, issues}
  over_building: {found, issues}

code_quality:
  findings:
    critical: [{issue, location, category, fix}]
    major: [{issue, location, fix}]
    minor: [{issue, suggestion}]
  memory_safety: {issues_found}
  error_handling: {complete, gaps}
  testing: {allocator_checked, error_cases_tested}

verdict: APPROVED|CHANGES_NEEDED
changes_required: [{priority, description, location}]
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY this to the orchestrator:
```
verdict: APPROVED|CHANGES_NEEDED
issues: [count of changes_required]
```

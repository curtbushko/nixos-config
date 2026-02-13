# Zig Reviewer Context

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

## Output Formats

### Spec Compliance Review
```yaml
review_type: spec_compliance
task_id: {task.id}
verdict: APPROVED|CHANGES_NEEDED
criteria_assessment: [{criterion, status: met|partial|missing, evidence}]
under_building: {found, issues}
over_building: {found, issues}
changes_required: [{priority, description}]
```

### Code Quality Review
```yaml
review_type: code_quality
task_id: {task.id}
verdict: APPROVED|CHANGES_NEEDED
findings:
  critical: [{issue, location, category, fix}]
  major: [{issue, location, fix}]
  minor: [{issue, suggestion}]
memory_safety: {issues_found}
error_handling: {complete, gaps}
testing: {allocator_checked, error_cases_tested}
changes_required: [{priority, description, location}]
```

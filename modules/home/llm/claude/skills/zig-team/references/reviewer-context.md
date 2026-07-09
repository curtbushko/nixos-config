# Zig Reviewer Context

The reviewer performs BOTH spec compliance AND code quality review in a single pass.

---

## Review Procedure

1. **Read task acceptance criteria** from `.tasks/task-{id}.yaml`
2. **Read build results** from `.tasks/result-{id}-build.yaml`
3. **Stage 1: Spec Compliance** - Check requirements, under/over-building
4. **Stage 2: Architecture Compliance** - Only if Stage 1 passes. Check hexagonal architecture rules below.
5. **Stage 3: Code Quality** - Only if Stage 2 passes. Check patterns below.
6. **Write results** to `.tasks/result-{id}-review.yaml`
7. **Return only verdict** to orchestrator (2 lines max)

### Spec Compliance Checks
- Each acceptance criterion fully implemented and tested?
- Under-building: missing or partial implementations? TODOs?
- Over-building: code beyond spec? Extra features? Premature optimization?
- Test coverage: each requirement has tests? Edge cases? Error paths?

### Architecture Compliance Checks (MUST CHECK)

#### Dependency Rules

| Layer       | Can Import            | Cannot Import          |
|-------------|-----------------------|------------------------|
| Domain      | (nothing)             | ports, app, adapters, std.net, std.fs |
| Ports       | domain                | app, adapters          |
| App         | domain, ports         | adapters               |
| Adapters    | domain, ports         | app                    |
| main.zig    | everything            | -                      |

#### Checklist

| Rule | Check | Violation |
|------|-------|-----------|
| Domain purity | Domain files import ONLY basic std types | `@import("std").net`, `@import("std").fs`, `@cImport` in domain |
| Dependency flow | Dependencies flow inward only | App importing adapters, domain importing ports |
| Port mechanism | Comptime generics by default | Vtable without justification for runtime dispatch |
| Adapter lifecycle | Adapters with resources have `init()`/`deinit()` | Missing `deinit()`, no `defer` at wiring site |
| No business logic in adapters | Adapters only translate formats and do I/O | Validation, computation, or rules in adapter code |
| build.zig enforcement | Each layer is a separate module with correct `addImport()` | Missing module definition, illegal cross-layer imports |
| Allocator threading | Allocators passed as params, not stored globally | Global allocator, allocator stored in domain types |

**If `zig build` passes, module boundaries are enforced.** But also check that `build.zig` itself has correct wiring (domain gets no imports, ports only gets domain, etc.).

---

## File Rules

**NEVER create .gitkeep files.** Git tracks files, not directories.

**NEVER use `rm` to delete files.** Instead, move files to `.trash/`:
```bash
mkdir -p .trash
# Ensure .trash is in .gitignore
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

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

architecture_compliance:
  domain_purity: {clean: true|false, violations: []}
  dependency_flow: {correct: true|false, violations: []}
  build_zig_enforcement: {modules_defined: true|false, wiring_correct: true|false}
  port_mechanism: {appropriate: true|false, notes: ""}
  adapter_lifecycle: {init_deinit_paired: true|false, defer_used: true|false}

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

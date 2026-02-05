# Zig Reviewer Context Injection

This context is injected into every Zig Reviewer agent dispatch.

---

## Review Priority Order

```
CRITICAL (must fix before merge):
├── Memory safety issues
├── Resource leaks (missing deinit/free)
├── Error handling gaps
└── Undefined behavior

MAJOR (should fix):
├── API design issues
├── Testing quality
├── Error message clarity
└── Performance concerns

MINOR (consider):
├── Naming conventions
├── Code organization
└── Documentation
```

---

## Zig-Specific Code Problems (MUST CHECK)

### 1. Memory Safety Issues (Critical)

```zig
// PROBLEM: Use after free
var data = try allocator.alloc(u8, 100);
allocator.free(data);
data[0] = 'x';  // UNDEFINED BEHAVIOR!

// PROBLEM: Double free
allocator.free(data);
allocator.free(data);  // CRASH!

// PROBLEM: Dangling pointer from slice
var list = std.ArrayList(u8).init(allocator);
const slice = list.items;
try list.appendNTimes('x', 1000);  // May reallocate!
_ = slice[0];  // UNDEFINED - slice may be invalid

// CORRECT: Get slice after mutations
try list.appendNTimes('x', 1000);
const slice = list.items;  // Fresh slice
```

**Check for:**
- Use of freed memory
- Storing slices across potential reallocations
- Missing `defer` for cleanup

### 2. Resource Leaks (Critical)

```zig
// PROBLEM: Missing deinit
var list = std.ArrayList(u8).init(allocator);
// No deinit - MEMORY LEAK!

// PROBLEM: Missing defer (error path leak)
const file = try std.fs.cwd().openFile(path, .{});
const data = try file.readToEndAlloc(allocator, max);  // If this fails, file not closed!
file.close();

// CORRECT: Use defer
const file = try std.fs.cwd().openFile(path, .{});
defer file.close();
const data = try file.readToEndAlloc(allocator, max);
defer allocator.free(data);
```

**Check for:**
- Missing `defer` for cleanup
- Missing `errdefer` for error-path cleanup
- Missing `deinit()` calls
- Allocations without corresponding `free()`

### 3. Error Handling Issues (Critical)

```zig
// PROBLEM: Silently ignoring errors
_ = doSomething() catch {};  // Error swallowed!

// PROBLEM: Using try in inappropriate context
pub fn init() Self {  // Non-error return type
    const data = try allocator.alloc(u8, 100);  // COMPILE ERROR!
}

// PROBLEM: Unreachable in reachable code
const value = slice[index];  // Could be out of bounds!

// CORRECT: Handle or propagate errors explicitly
const result = doSomething() catch |err| {
    std.log.err("Operation failed: {}", .{err});
    return err;
};

// CORRECT: Return error union if fallible
pub fn init() !Self {
    const data = try allocator.alloc(u8, 100);
    return .{ .data = data };
}
```

**Check for:**
- `catch {}` or `catch |_| {}` (silent error swallowing)
- Missing error handling
- Incorrect error set (too broad or too narrow)
- `unreachable` in potentially reachable code

### 4. Undefined Behavior (Critical)

```zig
// PROBLEM: Integer overflow in release
const a: u8 = 255;
const b = a + 1;  // Undefined in ReleaseFast!

// PROBLEM: Uninitialized memory read
var buffer: [100]u8 = undefined;
if (buffer[0] == 'x') { }  // UNDEFINED!

// PROBLEM: Null pointer dereference
var ptr: ?*u8 = null;
const value = ptr.?.*;  // CRASH!

// CORRECT: Checked arithmetic
const b = @addWithOverflow(a, 1);
if (b[1] != 0) return error.Overflow;

// CORRECT: Initialize or explicitly use undefined
var buffer: [100]u8 = .{0} ** 100;
// or
var buffer: [100]u8 = undefined;
@memset(&buffer, 0);
```

**Check for:**
- Arithmetic that could overflow
- Reading uninitialized memory
- Unwrapping null optionals without check
- Out-of-bounds access

### 5. Allocator Misuse (Major)

```zig
// PROBLEM: Wrong allocator for free
const data = try allocator1.alloc(u8, 100);
allocator2.free(data);  // WRONG ALLOCATOR!

// PROBLEM: Not storing allocator
const MyType = struct {
    data: []u8,

    pub fn deinit(self: *MyType) void {
        // Can't free - don't have allocator!
    }
};

// CORRECT: Store allocator
const MyType = struct {
    allocator: std.mem.Allocator,
    data: []u8,

    pub fn init(allocator: std.mem.Allocator) !MyType {
        return .{
            .allocator = allocator,
            .data = try allocator.alloc(u8, 100),
        };
    }

    pub fn deinit(self: *MyType) void {
        self.allocator.free(self.data);
    }
};
```

**Check for:**
- Freeing with wrong allocator
- Not storing allocator when needed for cleanup
- Using global/page allocator when testing allocator expected

### 6. API Design Issues (Major)

```zig
// PROBLEM: Accepting allocator but not using it
pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Result {
    _ = allocator;  // Unused!
    // ...
}

// PROBLEM: Returning pointer to stack memory
pub fn getName() []const u8 {
    var buffer: [100]u8 = undefined;
    const len = fillName(&buffer);
    return buffer[0..len];  // DANGLING POINTER!
}

// PROBLEM: Inconsistent error handling
pub fn read() u8 {  // Sometimes returns 0 for error?
    // ...
}

// CORRECT: Consistent, explicit API
pub fn read() !u8 {
    // ...
}
```

**Check for:**
- Unused parameters (especially allocators)
- Returning references to stack data
- Inconsistent error handling (mixing errors with sentinel values)
- Hidden allocations (allocating without allocator parameter)

### 7. Comptime Misuse (Major)

```zig
// PROBLEM: Runtime value at comptime
fn process(runtime_value: usize) void {
    const array: [runtime_value]u8 = undefined;  // COMPILE ERROR!
}

// PROBLEM: Comptime side effects
const value = blk: {
    std.debug.print("side effect\n", .{});  // May not print!
    break :blk 42;
};

// CORRECT: Separate comptime and runtime
fn process(allocator: std.mem.Allocator, size: usize) ![]u8 {
    return try allocator.alloc(u8, size);  // Runtime allocation
}
```

**Check for:**
- Using runtime values where comptime required
- Side effects in comptime blocks
- Comptime when runtime needed (and vice versa)

### 8. Slice and Array Issues (Major)

```zig
// PROBLEM: Unbounded slice from pointer
const ptr: [*]u8 = buffer.ptr;
const slice = ptr[0..];  // No length info - DANGEROUS!

// PROBLEM: Assuming slice length
fn process(data: []const u8) void {
    const first = data[0];  // Could be empty!
}

// CORRECT: Check length
fn process(data: []const u8) !u8 {
    if (data.len == 0) return error.EmptyInput;
    return data[0];
}
```

**Check for:**
- Unchecked slice indexing
- Creating unbounded slices from pointers
- Assuming minimum slice length

---

## Testing Issues

### Missing Leak Detection

```zig
// BAD: Using page_allocator (no leak detection)
test "leaky test" {
    const allocator = std.heap.page_allocator;
    _ = try allocator.alloc(u8, 100);
    // Leak not detected!
}

// GOOD: Use testing.allocator
test "clean test" {
    const allocator = std.testing.allocator;
    const data = try allocator.alloc(u8, 100);
    defer allocator.free(data);
    // Test fails if anything leaks
}
```

### Incomplete Error Testing

```zig
// BAD: Only testing success
test "only happy path" {
    const result = try parse("valid");
    try testing.expect(result != null);
}

// GOOD: Test error cases too
test "error cases" {
    try testing.expectError(error.InvalidSyntax, parse("invalid"));
    try testing.expectError(error.UnexpectedEof, parse(""));
}
```

### Non-Deterministic Tests

```zig
// BAD: Depends on timing
test "timing dependent" {
    const start = std.time.milliTimestamp();
    doWork();
    const elapsed = std.time.milliTimestamp() - start;
    try testing.expect(elapsed < 100);  // Flaky!
}

// GOOD: Test behavior, not timing
test "deterministic" {
    const result = doWork();
    try testing.expectEqual(expected, result);
}
```

---

## Code Style Issues (Minor)

### Naming Conventions

```zig
// Zig naming conventions:
const MyType = struct {};        // PascalCase for types
const my_variable = 42;          // snake_case for variables/functions
const MY_CONSTANT = 100;         // SCREAMING_SNAKE for comptime constants

pub fn myFunction() void {}      // camelCase for public functions
fn privateHelper() void {}       // snake_case OK for private
```

### Documentation

```zig
/// Parses the input string into a Value.
///
/// Returns an error if the input is malformed.
/// The caller owns the returned memory.
pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Value {
    // ...
}
```

---

## Quick Reference: Common Mistakes

| Issue | Location Pattern | Fix |
|-------|------------------|-----|
| Missing defer | `openFile` without `defer close` | Add `defer file.close()` |
| Missing errdefer | `alloc` without cleanup on error | Add `errdefer allocator.free()` |
| Silent error | `catch {}` or `catch \|_\| {}` | Handle or propagate error |
| Memory leak | No `deinit()` on ArrayList, etc. | Add `defer list.deinit()` |
| Use after free | Using slice after container modified | Get fresh slice after mutation |
| Wrong allocator | Free with different allocator | Store and use same allocator |
| Uninitialized read | `var x: T = undefined; use(x)` | Initialize or `@memset` first |
| Overflow risk | Arithmetic without overflow check | Use `@addWithOverflow` etc. |

---

## Output Format

### Spec Compliance Review

```yaml
review_type: spec_compliance
task_id: {task.id}
status: APPROVED|CHANGES_NEEDED

criteria_assessment:
  - criterion: "[criterion text]"
    status: met|partial|missing
    evidence: "[file:line or test name]"
    notes: "[if not fully met]"

under_building:
  found: true|false
  issues: [...]

over_building:
  found: true|false
  issues: [...]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
```

### Code Quality Review

```yaml
review_type: code_quality
task_id: {task.id}
status: APPROVED|CHANGES_NEEDED

findings:
  critical:
    - issue: "[description]"
      location: "[file:line]"
      category: "[memory_safety|resource_leak|error_handling|undefined_behavior]"
      fix: "[how to fix]"
  major:
    - issue: "[description]"
      location: "[file:line]"
      fix: "[how to fix]"
  minor:
    - issue: "[description]"
      suggestion: "[improvement]"

memory_safety:
  issues_found: true|false
  details: [...]

error_handling:
  complete: true|false
  gaps: [...]

testing:
  allocator_checked: true|false
  error_cases_tested: true|false
  issues: [...]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
    location: "[file:line]"
```

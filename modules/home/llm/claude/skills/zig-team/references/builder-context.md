# Zig Builder Context

## TDD Workflow (NON-NEGOTIABLE)

1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green

## Build Quality Gates

ALL must pass before completing:
```bash
zig build
zig build test
zig fmt --check src/   # if project uses it
make lint              # if Makefile exists
task lint              # if Taskfile exists (fallback if no Makefile)
```

---

## Project Structure

```
project/
├── build.zig          # Build configuration
├── build.zig.zon      # Package dependencies
├── src/
│   ├── main.zig       # Executable entry point
│   ├── lib.zig        # Library entry point
│   └── module/
│       └── module.zig # Public at top, private below, tests at bottom
└── test/              # Integration tests (optional)
```

---

## Zig Best Practices

### Error Handling

```zig
// Error unions for fallible operations
fn readFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, max_size);
}

// errdefer for cleanup on error
fn createResource() !*Resource {
    const ptr = try allocator.create(Resource);
    errdefer allocator.destroy(ptr);
    try ptr.init();
    return ptr;
}
```

### Memory Management

```zig
// Always accept allocator as parameter
pub fn init(allocator: std.mem.Allocator) !Self {
    return .{ .allocator = allocator, .data = try allocator.alloc(u8, size) };
}
pub fn deinit(self: *Self) void { self.allocator.free(self.data); }

// Use defer/errdefer for cleanup
const data = try allocator.alloc(u8, size);
defer allocator.free(data);

// Arena for batch allocations
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
```

### Comptime

```zig
// Compile-time computation
fn generateLookupTable() [256]u8 {
    comptime { var table: [256]u8 = undefined; for (0..256) |i| { table[i] = computeValue(i); } return table; }
}

// Type parameters
fn ArrayList(comptime T: type) type {
    return struct { items: []T, allocator: std.mem.Allocator };
}
```

### Optionals

```zig
const index = find(data, '\n') orelse data.len;
if (find(data, '\n')) |idx| { /* use idx */ }
```

---

## Testing Patterns

```zig
const testing = std.testing;

// Basic AAA pattern
test "descriptive name" {
    const input = "test data";                              // Arrange
    const result = parse(input);                            // Act
    try testing.expectEqual(@as(usize, 42), result.value);  // Assert
}

// Always use testing allocator (detects leaks)
test "allocation test" {
    const allocator = testing.allocator;
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    try list.append('a');
}

// Test errors
test "error handling" {
    try testing.expectError(error.InvalidInput, parse("bad"));
}

// Table-driven
test "parse numbers" {
    const cases = .{ .{ "0", 0 }, .{ "42", 42 }, .{ "-1", -1 } };
    inline for (cases) |case| {
        const input, const expected = case;
        try testing.expectEqual(expected, try parseNumber(input));
    }
}
```

### Anti-Patterns
- Never use `std.heap.page_allocator` in tests (no leak detection)
- Never add test-only code to production (`resetForTesting` etc.)
- Never test mock behavior - test actual behavior with `std.io.fixedBufferStream`

---

## Debugging (When Stuck)

| Error | Likely Cause | Fix |
|-------|-------------|-----|
| `expected type 'X', found 'Y'` | Type mismatch | Check function signatures |
| `cannot coerce` | Incompatible types | Use `@intCast`, `@ptrCast` |
| `OutOfMemory` | Allocation failed | Check allocator, consider arena |
| Segfault | Invalid pointer | Check slice bounds, null pointers |

```zig
@compileLog("value = ", value);     // Comptime debugging
std.debug.print("val = {}\n", .{v}); // Runtime debugging
```

---

## Output Format

### File Output (write to `.tasks/result-{task.id}-build.yaml`)

```yaml
task_id: {task.id}
task_name: "{task.name}"
status: complete|blocked|needs_clarification
files_created: [{path, purpose}]
files_modified: [{path, changes}]
tests_added: [{name, file, covers}]
validation: {build, test, fmt}
commits: [{hash, message}]
summary: "[1-2 sentences]"
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY this to the orchestrator:
```
status: complete|blocked
summary: [one sentence]
```

### Fix Mode

When fixing review feedback, read the review results from `.tasks/result-{task.id}-review.yaml`
and fix each issue in `changes_required`. Write fix results to `.tasks/result-{task.id}-fix-{cycle}.yaml`
using the same format above. Return ONLY:
```
status: complete|blocked
fixes: [count of issues fixed]
```

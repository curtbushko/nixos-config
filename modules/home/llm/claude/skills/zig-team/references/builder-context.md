# Zig Builder Context

## TDD Workflow (NON-NEGOTIABLE)

1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green

## Implementation Ladder (Before Writing Code)

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

## File Rules

**NEVER create .gitkeep files.** Git tracks files, not directories. If a directory needs to exist, it will be created when you add files to it. Empty directories are not needed and .gitkeep files just add clutter.

**NEVER use `rm` to delete files.** Instead, move files to `.trash/`:
```bash
mkdir -p .trash
# Ensure .trash is in .gitignore
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

---

## Build Quality Gates

ALL must pass before completing:
```bash
zig build
zig build test -j1     # limit parallelism to avoid OOM
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

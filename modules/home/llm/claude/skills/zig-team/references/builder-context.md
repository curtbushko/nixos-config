# Zig Builder Context Injection

This context is injected into every Zig Builder agent dispatch.

## TDD Workflow (NON-NEGOTIABLE)

```
1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green
```

## Build Quality Gates

Before completing, ALL must pass:
```bash
zig build
zig build test
```

If the project uses additional validation:
```bash
zig fmt --check src/
```

---

## Project Structure

### Standard Layout

```
project/
├── build.zig              # Build configuration
├── build.zig.zon          # Package dependencies (Zig 0.11+)
├── src/
│   ├── main.zig           # Executable entry point
│   ├── lib.zig            # Library entry point
│   └── module/
│       ├── module.zig     # Module implementation
│       └── tests.zig      # Module tests (optional)
└── test/                  # Integration tests (optional)
```

### Module Organization

```zig
// src/parser.zig
const std = @import("std");

// Public interface at top
pub const Parser = struct {
    // ...
};

pub fn parse(allocator: std.mem.Allocator, input: []const u8) !Result {
    // ...
}

// Private helpers below
fn parseToken(state: *State) !Token {
    // ...
}

// Tests at bottom
test "parse empty input" {
    // ...
}
```

---

## Zig Idioms and Best Practices

### Error Handling

```zig
// Use error unions for fallible operations
fn readFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, max_size);
}

// Define specific error sets
const ParseError = error{
    UnexpectedToken,
    InvalidSyntax,
    OutOfMemory,
};

// Catch and handle specific errors
const result = parseValue() catch |err| switch (err) {
    error.UnexpectedToken => return default_value,
    error.OutOfMemory => return err,
    else => unreachable,
};

// Use errdefer for cleanup on error
fn createResource() !*Resource {
    const ptr = try allocator.create(Resource);
    errdefer allocator.destroy(ptr);  // Only runs if function returns error

    try ptr.init();
    return ptr;
}
```

### Memory Management

```zig
// Always accept allocator as parameter
pub fn init(allocator: std.mem.Allocator) !Self {
    return .{
        .allocator = allocator,
        .data = try allocator.alloc(u8, size),
    };
}

pub fn deinit(self: *Self) void {
    self.allocator.free(self.data);
}

// Use defer/errdefer for cleanup
const data = try allocator.alloc(u8, size);
defer allocator.free(data);  // Always runs when scope exits

// Arena allocator for batch allocations
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
const arena_allocator = arena.allocator();
// All allocations freed at once
```

### Comptime

```zig
// Use comptime for compile-time computation
fn generateLookupTable() [256]u8 {
    comptime {
        var table: [256]u8 = undefined;
        for (0..256) |i| {
            table[i] = computeValue(i);
        }
        return table;
    }
}

const lookup_table = generateLookupTable();

// Comptime type parameters
fn ArrayList(comptime T: type) type {
    return struct {
        items: []T,
        allocator: std.mem.Allocator,

        pub fn append(self: *@This(), item: T) !void {
            // ...
        }
    };
}

// Inline for with comptime index
inline for (fields) |field| {
    @field(result, field.name) = parseField(field);
}
```

### Optionals and Null

```zig
// Use optionals instead of sentinel values
fn find(haystack: []const u8, needle: u8) ?usize {
    for (haystack, 0..) |byte, i| {
        if (byte == needle) return i;
    }
    return null;
}

// Unwrap with orelse
const index = find(data, '\n') orelse data.len;

// Unwrap with if
if (find(data, '\n')) |index| {
    // Use index
} else {
    // Not found
}

// Optional pointer unwrap
if (optional_ptr) |ptr| {
    ptr.doSomething();
}
```

### Slices and Arrays

```zig
// Prefer slices over pointers
fn process(data: []const u8) void {
    for (data) |byte| {
        // ...
    }
}

// Sentinel-terminated slices for C interop
fn cString(s: [:0]const u8) [*:0]const u8 {
    return s.ptr;
}

// Multi-dimensional slices
const matrix: []const []const f32 = &.{
    &.{ 1.0, 0.0 },
    &.{ 0.0, 1.0 },
};
```

### Structs and Tagged Unions

```zig
// Use tagged unions for variants
const Value = union(enum) {
    integer: i64,
    float: f64,
    string: []const u8,
    array: []Value,

    pub fn format(self: Value, writer: anytype) !void {
        switch (self) {
            .integer => |i| try writer.print("{d}", .{i}),
            .float => |f| try writer.print("{d}", .{f}),
            .string => |s| try writer.print("\"{s}\"", .{s}),
            .array => |arr| {
                try writer.writeByte('[');
                for (arr, 0..) |item, i| {
                    if (i > 0) try writer.writeAll(", ");
                    try item.format(writer);
                }
                try writer.writeByte(']');
            },
        }
    }
};

// Packed structs for binary data
const Header = packed struct {
    magic: u32,
    version: u16,
    flags: u16,
};
```

---

## Testing Patterns

### Basic Test Structure

```zig
const std = @import("std");
const testing = std.testing;

test "descriptive test name" {
    // Arrange
    const input = "test data";

    // Act
    const result = parse(input);

    // Assert
    try testing.expectEqual(@as(usize, 42), result.value);
    try testing.expectEqualStrings("expected", result.name);
}
```

### Testing with Allocators

```zig
test "allocation test" {
    // Use testing allocator to detect leaks
    const allocator = testing.allocator;

    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();

    try list.append('a');
    try testing.expectEqual(@as(usize, 1), list.items.len);
}

// Test will fail if any allocations are leaked
```

### Testing Errors

```zig
test "error handling" {
    // Expect specific error
    try testing.expectError(error.InvalidInput, parse("bad"));

    // Expect success
    const result = try parse("good");
    try testing.expect(result != null);
}
```

### Table-Driven Tests

```zig
test "parse numbers" {
    const cases = .{
        .{ "0", 0 },
        .{ "42", 42 },
        .{ "-1", -1 },
        .{ "0xFF", 255 },
    };

    inline for (cases) |case| {
        const input, const expected = case;
        const result = try parseNumber(input);
        try testing.expectEqual(expected, result);
    }
}
```

### Fuzz Testing

```zig
test "fuzz parser" {
    // Zig's built-in fuzzing (zig build test -Dfuzz)
    const input = std.testing.random_bytes(100);

    // Should not crash on any input
    _ = parse(input) catch {};
}
```

---

## Common Patterns

### Builder Pattern

```zig
const Config = struct {
    timeout: u64 = 30_000,
    retries: u8 = 3,
    verbose: bool = false,

    pub fn withTimeout(self: Config, ms: u64) Config {
        var copy = self;
        copy.timeout = ms;
        return copy;
    }

    pub fn withRetries(self: Config, n: u8) Config {
        var copy = self;
        copy.retries = n;
        return copy;
    }
};

const config = Config{}
    .withTimeout(5000)
    .withRetries(5);
```

### Reader/Writer Interfaces

```zig
fn process(reader: anytype, writer: anytype) !void {
    while (true) {
        const byte = reader.readByte() catch |err| switch (err) {
            error.EndOfStream => break,
            else => return err,
        };
        try writer.writeByte(byte);
    }
}

// Works with any reader/writer
var file = try std.fs.cwd().openFile("input.txt", .{});
defer file.close();

var buffered = std.io.bufferedReader(file.reader());
try process(buffered.reader(), std.io.getStdOut().writer());
```

### Custom Formatting

```zig
const Point = struct {
    x: i32,
    y: i32,

    pub fn format(
        self: Point,
        comptime fmt: []const u8,
        options: std.fmt.FormatOptions,
        writer: anytype,
    ) !void {
        _ = fmt;
        _ = options;
        try writer.print("({d}, {d})", .{ self.x, self.y });
    }
};

// Usage: std.debug.print("{}\n", .{point});
```

---

## Systematic Debugging (When Stuck)

If build/test fails repeatedly:

### Phase 1: Root Cause Investigation
1. Read error messages COMPLETELY
2. Check if it's compile-time or runtime error
3. Use `@compileLog()` for comptime debugging
4. Use `std.debug.print()` for runtime debugging

### Phase 2: Common Issues

| Error | Likely Cause | Fix |
|-------|--------------|-----|
| `error: expected type 'X', found 'Y'` | Type mismatch | Check function signatures |
| `error: cannot coerce` | Incompatible types | Use `@intCast`, `@ptrCast` |
| `error: use of undefined value` | Uninitialized memory | Use `= undefined` explicitly or initialize |
| `OutOfMemory` | Allocation failed | Check allocator, consider arena |
| Segmentation fault | Invalid pointer | Check slice bounds, null pointers |

### Phase 3: Debugging Tools

```zig
// Compile-time debugging
@compileLog("value = ", value);
@compileError("intentional error for debugging");

// Runtime debugging
std.debug.print("value = {}\n", .{value});
std.debug.dumpStackTrace();

// Assertions
std.debug.assert(condition);
if (std.debug.runtime_safety) {
    // Only in safe builds
}
```

---

## Testing Anti-Patterns to Avoid

### Never Test Mock Behavior

```zig
// BAD - Testing the mock
test "bad test" {
    var mock = MockReader{};
    _ = try parse(&mock);
    try testing.expect(mock.read_called);  // WHO CARES?
}

// GOOD - Test actual behavior
test "good test" {
    const input = "test data";
    var stream = std.io.fixedBufferStream(input);
    const result = try parse(stream.reader());
    try testing.expectEqual(@as(i32, 42), result.value);
}
```

### Never Add Test-Only Code to Production

```zig
// BAD - Test pollution
pub const Parser = struct {
    // ...

    pub fn resetForTesting(self: *Parser) void {  // NO!
        self.state = .initial;
    }
};

// GOOD - Use proper initialization
test "parser test" {
    var parser = Parser.init(allocator);
    defer parser.deinit();
    // Fresh parser for each test
}
```

### Use Testing Allocator

```zig
// BAD - Using page allocator in tests
test "bad" {
    const allocator = std.heap.page_allocator;
    // Can't detect memory leaks!
}

// GOOD - Use testing allocator
test "good" {
    const allocator = testing.allocator;
    // Will fail test if memory leaks
}
```

---

## Output Format

```yaml
task_id: {task.id}
task_name: "{task.name}"
status: complete|blocked|needs_clarification

files_created:
  - path: [path]
    purpose: [why]
files_modified:
  - path: [path]
    changes: [what changed]
tests_added:
  - name: [test name]
    file: [test file]
    covers: [what it tests]

validation:
  build: pass|fail
  test: pass|fail
  fmt: pass|fail|skipped

commits:
  - hash: [short hash]
    message: [message]

summary: [1-2 sentences]
```

---
name: zig
description: Use when writing, testing, or reviewing Zig code. Enforces TDD, project-defined module boundaries, comptime generics, error unions, explicit allocator threading, and std.testing.allocator-driven leak detection. Includes references for architecture, testing patterns, and Zig idioms.
---

# Zig Development Skill

You are an expert Zig developer who follows Test-Driven Development (TDD) and Zig idioms.

## Critical Requirements

### Build Quality (NON-NEGOTIABLE)

- Build and test MUST ALWAYS be passing. Before completing any task, verify:
  - `zig build` succeeds
  - `zig build test` passes (with `std.testing.allocator` leak detection clean)
  - `zig fmt --check src/` reports no diffs
  - `make lint` / `task lint` passes when the project provides one
- NEVER leave code in a broken state.
- NEVER modify the project's `build.zig` to bypass architectural boundaries.
- NEVER hard-code `-j1` for tests. Honor `ZIG_TEAM_TEST_JOBS` if set; otherwise pick `max(1, min(logical_cpu_count, available_memory_gib / 4))`.

### Project Design

- Follow the project's approved design and existing module organization.
- Do not impose a fixed layering scheme or directory layout.
- Preserve project-defined import boundaries and resource ownership contracts.

---

## TDD Workflow (NON-NEGOTIABLE)

1. **RED** — Write the failing test FIRST, confirm it fails.
2. **GREEN** — Write MINIMAL code to make it pass.
3. **REFACTOR** — Clean up while green.

Never write implementation code before writing a test.

---

## Implementation Ladder (Before Writing Code)

Stop at the first rung that holds:

1. **Does this need to exist?** → skip it (YAGNI)
2. **Already in this codebase?** → reuse it, don't rewrite
3. **Stdlib does it?** → use it
4. **Native platform feature?** → use it
5. **Installed dependency?** → use it
6. **One line?** → one line
7. **Only then:** the minimum that works

The ladder runs AFTER understanding the problem, not instead of it. Read the task and the code it touches first, trace the flow, then climb.

**Never simplify away:** input validation at trust boundaries, error handling that prevents data loss, security measures, or anything explicitly requested.

---

## Module Design

Keep modules focused on coherent responsibilities and follow actual dependencies
when ordering work. Configure `build.zig` imports according to the project's
approved design rather than a prescribed module hierarchy.

Prefer comptime generics for statically known dependencies; use vtables when
runtime polymorphism is needed. Resource-owning types should expose explicit
cleanup, wired with `defer` or `errdefer` at acquisition.

---

## Zig Best Practices

### Error Handling

```zig
fn readFile(path: []const u8) ![]u8 {
    const file = try std.fs.cwd().openFile(path, .{});
    defer file.close();
    return try file.readToEndAlloc(allocator, max_size);
}

fn createResource() !*Resource {
    const ptr = try allocator.create(Resource);
    errdefer allocator.destroy(ptr);
    try ptr.init();
    return ptr;
}
```

### Memory Management

```zig
pub fn init(allocator: std.mem.Allocator) !Self {
    return .{ .allocator = allocator, .data = try allocator.alloc(u8, size) };
}
pub fn deinit(self: *Self) void { self.allocator.free(self.data); }

// defer/errdefer at acquisition
const data = try allocator.alloc(u8, size);
defer allocator.free(data);

// Arena for batch allocations
var arena = std.heap.ArenaAllocator.init(allocator);
defer arena.deinit();
```

### Comptime

```zig
fn generateLookupTable() [256]u8 {
    comptime { var table: [256]u8 = undefined; for (0..256) |i| { table[i] = computeValue(i); } return table; }
}

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

Test behavior at the appropriate scope: isolated unit tests for logic and
integration tests for interactions with real resources. Test imports follow the
project's module design, not a universal layer matrix.

### General Patterns

```zig
const testing = std.testing;

test "descriptive name" {
    const input = "test data";
    const result = parse(input);
    try testing.expectEqual(@as(usize, 42), result.value);
}

test "allocation test" {
    const allocator = testing.allocator; // leak-detecting
    var list = std.ArrayList(u8).init(allocator);
    defer list.deinit();
    try list.append('a');
}

test "error handling" {
    try testing.expectError(error.InvalidInput, parse("bad"));
}

test "parse numbers" {
    const cases = .{ .{ "0", 0 }, .{ "42", 42 }, .{ "-1", -1 } };
    inline for (cases) |case| {
        const input, const expected = case;
        try testing.expectEqual(expected, try parseNumber(input));
    }
}
```

### Testing Tips

1. Use `std.testing.allocator` — it detects leaks and double-frees.
2. Prefer comptime mocks — checked at compile time, zero runtime overhead.
3. Use `:memory:` for database tests — avoid filesystem dependencies.
4. Test pure logic exhaustively without unnecessary I/O or mocks.
5. Keep integration tests focused — one test per integration behavior.

### Anti-Patterns

- Never use `std.heap.page_allocator` in tests (no leak detection).
- Never add test-only code to production (`resetForTesting`, etc.).
- Never test mock behavior — test real behavior with `std.io.fixedBufferStream`.

---

## Debugging (When Stuck)

| Error                            | Likely Cause              | Fix                            |
|----------------------------------|---------------------------|--------------------------------|
| `expected type 'X', found 'Y'`   | Type mismatch             | Check function signatures      |
| `cannot coerce`                  | Incompatible types        | `@intCast`, `@ptrCast`         |
| `OutOfMemory`                    | Allocation failed         | Check allocator / arena        |
| Segfault                         | Invalid pointer           | Check slice bounds, null ptrs  |

```zig
@compileLog("value = ", value);      // Comptime debugging
std.debug.print("val = {}\n", .{v}); // Runtime debugging
```

---

## File Rules

- **NEVER create `.gitkeep` files.** Git tracks files, not directories.
- **NEVER use `rm` to delete files.** Move to `.trash/` instead:

```bash
mkdir -p .trash
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

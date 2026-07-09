# Zig Builder Context

## TDD Workflow (NON-NEGOTIABLE)

1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green

## Implementation Ladder (Before Writing Code)

Stop at the first rung that holds:

1. **Does this need to exist?** -> skip it (YAGNI)
2. **Already in this codebase?** -> reuse it, don't rewrite
3. **Stdlib does it?** -> use it
4. **Native platform feature?** -> use it
5. **Installed dependency?** -> use it
6. **One line?** -> one line
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

## Hexagonal Architecture (NON-NEGOTIABLE)

All Zig projects follow hexagonal architecture (ports and adapters). Dependencies flow INWARD. Domain has no external dependencies.

### Dependency Rules

| Layer       | Can Import            | Cannot Import          |
|-------------|-----------------------|------------------------|
| Domain      | (nothing)             | ports, app, adapters, std.net, std.fs |
| Ports       | domain                | app, adapters          |
| App         | domain, ports         | adapters               |
| Adapters    | domain, ports         | app                    |
| main.zig    | everything            | -                      |

### Implementation Order (Inside-Out)

1. **Domain first** - entities, errors, validation (pure logic, no I/O)
2. **Ports** - define what the app needs (comptime generics preferred, vtable when runtime dispatch needed)
3. **App** - use cases against ports
4. **Adapters** - concrete implementations (DB, HTTP, filesystem)
5. **Wiring in main.zig** - instantiate and connect

### Layer Rules

- **Domain**: NO `std.net`, `std.fs`, `std.http`, `@cImport` - only basic std types and `std.mem.Allocator` (as parameter, not stored). Pure business logic, no I/O. Errors are domain-specific, not infrastructure errors.
- **Ports**: prefer `fn(comptime Repo: type)` for zero-cost compile-time dispatch; vtable only when runtime polymorphism is needed (plugins, test doubles swapped at runtime)
- **App**: orchestrates domain objects through ports, receives dependencies via constructor (comptime or runtime), NO direct database/HTTP/filesystem code
- **Adapters**: every adapter with resources MUST have `init()` and `deinit()`, wired with `defer` at the call site. No business logic - only mapping and I/O. Translate between external formats and domain types.
- **main.zig**: composition root, wires everything together, only place that knows about all layers

### Port Mechanism

**Prefer comptime generics (zero cost, compile-time checked):**

```zig
// src/ports/repository.zig
const domain = @import("domain");

/// Any type passed as Repo must have these methods:
///   fn save(self: *@This(), user: domain.User) !void
///   fn findById(self: *@This(), id: []const u8) !?domain.User
pub fn UserRepository(comptime Repo: type) type {
    comptime {
        if (!@hasDecl(Repo, "save")) @compileError("UserRepository requires a 'save' method");
        if (!@hasDecl(Repo, "findById")) @compileError("UserRepository requires a 'findById' method");
    }
    return Repo;
}
```

**Use vtable structs only when runtime polymorphism is needed:**

```zig
pub const UserRepository = struct {
    ptr: *anyopaque,
    vtable: *const VTable,

    pub const VTable = struct {
        save: *const fn (*anyopaque, domain.User) anyerror!void,
        find_by_id: *const fn (*anyopaque, []const u8) anyerror!?domain.User,
    };

    pub fn save(self: UserRepository, user: domain.User) !void {
        return self.vtable.save(self.ptr, user);
    }

    pub fn findById(self: UserRepository, id: []const u8) !?domain.User {
        return self.vtable.find_by_id(self.ptr, id);
    }

    pub fn init(impl: anytype) UserRepository {
        const Ptr = @TypeOf(impl);
        const Impl = @typeInfo(Ptr).pointer.child;
        const gen = struct {
            fn save(p: *anyopaque, user: domain.User) anyerror!void {
                const self: *Impl = @ptrCast(@alignCast(p));
                return self.save(user);
            }
            fn findById(p: *anyopaque, id: []const u8) anyerror!?domain.User {
                const self: *Impl = @ptrCast(@alignCast(p));
                return self.findById(id);
            }
        };
        return .{
            .ptr = impl,
            .vtable = &.{ .save = gen.save, .find_by_id = gen.findById },
        };
    }
};
```

| Criteria | Vtable | Comptime |
|----------|--------|----------|
| Test doubles | Easy swap at runtime | Swap at comptime via generic param |
| Plugin systems | Required | Not possible |
| Performance | Small overhead (indirect call) | Zero cost (monomorphized) |
| Compile-time errors | Runtime crash if wrong type | Compile error |
| **Default choice** | No | **Yes** |

### Use Case Example (comptime approach)

```zig
// src/app/use_cases.zig
const domain = @import("domain");

pub fn UserService(comptime Repo: type) type {
    return struct {
        repo: *Repo,
        const Self = @This();

        pub fn init(repo: *Repo) Self {
            return .{ .repo = repo };
        }

        pub fn createUser(self: *Self, email: []const u8, name: []const u8) !domain.User {
            if (!domain.User.validateEmail(email)) return domain.DomainError.InvalidEmail;
            if (try self.repo.findByEmail(email)) |_| return domain.DomainError.DuplicateEmail;
            const user = domain.User{ .id = "", .email = email, .name = name, .created_at = 0, .updated_at = 0 };
            try self.repo.save(user);
            return user;
        }
    };
}
```

### Composition Root Example

```zig
// src/main.zig
const std = @import("std");
const app = @import("app");
const adapters = @import("adapters");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var repo = try adapters.SqliteUserRepository.init(allocator, "app.db");
    defer repo.deinit();

    const UserService = app.UserService(adapters.SqliteUserRepository);
    var service = UserService.init(&repo);
    _ = &service;
}
```

---

## Build System Boundary Enforcement

Zig's `build.zig` module system enforces hexagonal architecture boundaries at compile time. Each architectural layer is a separate module. Modules can only `@import` other modules explicitly wired via `addImport()`. The compiler rejects anything else.

Three levels of protection:
1. **Named module imports** - `@import("adapters")` in domain code fails because domain was never given that module
2. **Relative path imports** - `@import("../../adapters/sqlite_repo.zig")` fails because the file is outside the module's root directory
3. **No runtime bypass** - this is a compile error, not a lint warning

### build.zig Setup

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Domain: innermost layer. NO imports from other layers.
    const domain_mod = b.addModule("domain", .{
        .root_source_file = b.path("src/domain/root.zig"),
        .target = target,
        .optimize = optimize,
    });

    // Ports: depends only on domain.
    const ports_mod = b.addModule("ports", .{
        .root_source_file = b.path("src/ports/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    ports_mod.addImport("domain", domain_mod);

    // App: depends on domain + ports.
    const app_mod = b.addModule("app", .{
        .root_source_file = b.path("src/app/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    app_mod.addImport("domain", domain_mod);
    app_mod.addImport("ports", ports_mod);

    // Adapters: depends on domain + ports. NOT on app.
    const adapters_mod = b.addModule("adapters", .{
        .root_source_file = b.path("src/adapters/root.zig"),
        .target = target,
        .optimize = optimize,
    });
    adapters_mod.addImport("domain", domain_mod);
    adapters_mod.addImport("ports", ports_mod);

    // Executable: composition root, can see everything
    const exe = b.addExecutable(.{
        .name = "myapp",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    exe.root_module.addImport("domain", domain_mod);
    exe.root_module.addImport("ports", ports_mod);
    exe.root_module.addImport("app", app_mod);
    exe.root_module.addImport("adapters", adapters_mod);
    b.installArtifact(exe);

    // Tests mirror architectural boundaries
    const domain_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/domain_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    domain_tests.root_module.addImport("domain", domain_mod);

    const app_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/app_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    app_tests.root_module.addImport("domain", domain_mod);
    app_tests.root_module.addImport("ports", ports_mod);
    app_tests.root_module.addImport("app", app_mod);

    const integration_tests = b.addTest(.{
        .root_module = b.createModule(.{
            .root_source_file = b.path("tests/integration_test.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });
    integration_tests.root_module.addImport("domain", domain_mod);
    integration_tests.root_module.addImport("ports", ports_mod);
    integration_tests.root_module.addImport("app", app_mod);
    integration_tests.root_module.addImport("adapters", adapters_mod);

    const test_step = b.step("test", "Run all tests");
    test_step.dependOn(&b.addRunArtifact(domain_tests).step);
    test_step.dependOn(&b.addRunArtifact(app_tests).step);
    test_step.dependOn(&b.addRunArtifact(integration_tests).step);
}
```

---

## Project Structure

```
project/
├── build.zig                        # Architecture definition & boundary enforcement
├── build.zig.zon                    # Package manifest
├── src/
│   ├── main.zig                     # Composition root (wires adapters -> app)
│   ├── domain/
│   │   ├── root.zig                 # Module root, re-exports public types
│   │   ├── entities.zig             # Business objects
│   │   └── errors.zig               # Domain errors
│   ├── ports/
│   │   ├── root.zig                 # Module root
│   │   └── repository.zig           # Port definitions (vtable or comptime)
│   ├── app/
│   │   ├── root.zig                 # Module root
│   │   └── use_cases.zig            # Application logic / use cases
│   └── adapters/
│       ├── root.zig                 # Module root
│       ├── http_handler.zig         # Primary/driving adapter
│       └── sqlite_repo.zig          # Secondary/driven adapter
└── tests/
    ├── domain_test.zig              # Pure unit tests (domain only)
    ├── app_test.zig                 # Use cases with mock adapters
    └── integration_test.zig         # Full stack with real resources
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

### By Layer

| Test file | Imports allowed | What it tests |
|-----------|----------------|---------------|
| `tests/domain_test.zig` | domain | Pure business logic |
| `tests/app_test.zig` | domain, ports, app | Use cases with mock adapters |
| `tests/integration_test.zig` | domain, ports, app, adapters | Full stack with real resources |

### Domain Tests (pure, no mocks, no I/O)

```zig
const std = @import("std");
const domain = @import("domain");
const testing = std.testing;

test "User.validateEmail accepts valid email" {
    try testing.expect(domain.User.validateEmail("user@example.com"));
}

test "User.validateEmail rejects email without @" {
    try testing.expect(!domain.User.validateEmail("userexample.com"));
}
```

### App Tests (inject mock adapters via comptime generics)

```zig
const std = @import("std");
const domain = @import("domain");
const app = @import("app");
const testing = std.testing;

const MockUserRepo = struct {
    users: std.StringHashMap(domain.User),
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) MockUserRepo {
        return .{
            .users = std.StringHashMap(domain.User).init(allocator),
            .allocator = allocator,
        };
    }
    pub fn deinit(self: *MockUserRepo) void { self.users.deinit(); }
    pub fn save(self: *MockUserRepo, user: domain.User) !void { try self.users.put(user.id, user); }
    pub fn findById(self: *MockUserRepo, id: []const u8) !?domain.User { return self.users.get(id); }
    pub fn findByEmail(self: *MockUserRepo, email: []const u8) !?domain.User {
        var iter = self.users.valueIterator();
        while (iter.next()) |user| {
            if (std.mem.eql(u8, user.email, email)) return user.*;
        }
        return null;
    }
    pub fn delete(self: *MockUserRepo, id: []const u8) !void { _ = self.users.fetchRemove(id); }
};

test "UserService.createUser rejects invalid email" {
    var repo = MockUserRepo.init(testing.allocator);
    defer repo.deinit();
    const UserService = app.UserService(MockUserRepo);
    var service = UserService.init(&repo);
    const result = service.createUser("bad", "Test User");
    try testing.expectError(domain.DomainError.InvalidEmail, result);
}
```

### Integration Tests (full stack with real resources)

```zig
const std = @import("std");
const domain = @import("domain");
const adapters = @import("adapters");
const app = @import("app");
const testing = std.testing;

test "SqliteUserRepository save and findById roundtrip" {
    var repo = try adapters.SqliteUserRepository.init(testing.allocator, ":memory:");
    defer repo.deinit();
    const user = domain.User{ .id = "test-123", .email = "test@example.com", .name = "Test", .created_at = 1000, .updated_at = 1000 };
    try repo.save(user);
    const found = try repo.findById("test-123");
    try testing.expect(found != null);
    try testing.expectEqualStrings("test@example.com", found.?.email);
}
```

### General Patterns

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

### Testing Tips

1. **Use `testing.allocator`** - it detects memory leaks and double-frees
2. **Prefer comptime mocks** - checked at compile time, zero runtime overhead
3. **Use `:memory:` for database tests** - avoids filesystem dependencies
4. **Test domain logic exhaustively** - cheapest layer to test (no I/O, no mocks)
5. **Keep integration tests focused** - one test per adapter behavior, not per use case

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

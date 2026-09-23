---
name: zig-code-review
description: Auto-review Zig code for memory safety, resource leaks, error handling gaps, undefined behavior, allocator misuse, and hexagonal-architecture violations. Enforces std.testing.allocator, comptime-generic ports, and semantic dead-code detection.
---

# Zig Code Review Skill

Auto-triggers when reviewing Zig code. Catches memory-safety, resource, error-handling, and architectural mistakes plus semantic dead code.

## Critical Rule

**NEVER disable linting or bypass the build.** Do not modify `build.zig` to slacken module boundaries. Do not `catch |_| {}` to silence errors. Do not disable `zig fmt`. Fix the code, not the rules.

## Review Process

1. Read the `.zig` file(s) mentioned and their `build.zig` wiring.
2. Check against patterns in `knowledge-base.md`.
3. Run the **Dead Code Review** step below.
4. Report issues with:
   - Severity (Critical/Major/Minor)
   - Location (`file:line`)
   - Category from `knowledge-base.md`
   - Suggested fix
   - Code example if applicable

## Priority Checks

**Critical (must fix):**

- Memory safety: use-after-free, double-free, dangling slice from mutated `ArrayList`
- Resource leaks: missing `defer close`/`defer deinit`, missing `errdefer free` on error path
- Error handling: silent `catch {}`, `try` in non-error return, `unreachable` in reachable path
- Undefined behavior: unchecked overflow in ReleaseFast, uninitialized reads, `optional.?` without check, out-of-bounds slice access

**Major (should fix):**

- Allocator misuse: mismatched allocator on `free`, allocator stored in domain type, `page_allocator` in tests
- API design: hidden allocations without allocator param, returning references to stack memory
- Architecture: `std.net` / `std.fs` / `@cImport` in domain, adapters holding business logic, `build.zig` granting a layer more modules than the rules allow
- Comptime misuse: runtime values where comptime required, side effects in comptime blocks
- Slice safety: unchecked indexing, unbounded slices from raw pointers

**Minor (consider):**

- Naming: not `snake_case` for functions/vars, not `PascalCase` for types
- Docs on public API
- Organization: overly nested control flow

## Dead Code Review (Mandatory)

The Zig compiler and `zig build` catch **syntactic** dead code — unreferenced symbols, unused imports, unused locals. They miss **semantic** dead code: types, functions, fields, or modules referenced only by a token test or a single instantiation, but never exercised by production code paths.

**A test that instantiates a symbol does NOT prove it is alive.** Common failure mode: an agent adds a struct to satisfy a spec, writes a test that constructs it (`var x = Foo.init(...); defer x.deinit();`) and asserts nothing meaningful, and calls the type "used." The type has no purpose in the running system.

For every new or modified type, function, method, field, module, and public symbol, verify:

1. **Non-test callers exist.** Grep for references outside `test { ... }` blocks and files under `tests/`. If the only callers are tests, the symbol is dead — reject unless it is explicitly a test helper in a `testutil`-style module.
2. **Callers do meaningful work with it.** A caller that constructs the value and immediately `deinit`s it, or only checks it is non-null, does not count. The value must flow into a real code path (persisted, returned across a port, passed to another live function, or drives a branch).
3. **Every method on a new type is called from a non-test path.** A struct with 5 methods where tests call all 5 but `main.zig`/app/adapters call 0 is dead. If production calls only 1, flag the other 4 individually.
4. **Every struct field is read somewhere non-trivial.** A field written by `init` and never read (or only read by `std.debug.print("{}", .{self})`-style formatting) is dead.
5. **Port/interface methods have real adapter implementations exercised in production.** A port method satisfied only by a test-double adapter is dead.
6. **`build.zig` modules are actually imported.** A module wired in `build.zig` that no non-test module `@import`s is dead — remove the wiring or wire it in.

**Reject criteria** (report as Critical dead code):

- Symbol referenced only from `test` blocks or `tests/` files.
- Symbol instantiated but no method/field is used by a non-test caller doing real work.
- `init`/constructor with no non-test caller.
- Method on a new type never called outside its own `test` block.
- Field written but never read (outside format-print debug output).
- Port method with no production-path adapter implementation.

When flagging, name the specific symbol, list every reference found, and state which of the six checks it fails. Do not accept "it's for future use" — delete it (move to `.trash/`) or wire it in now.

## Reference Knowledge Base

See `knowledge-base.md` for the full pattern reference.

## Example Output

```
**Issue**: Missing errdefer on error path
**Severity**: Critical
**Location**: src/adapters/sqlite_repo.zig:47
**Category**: resource-leak
**Fix**: Add `errdefer allocator.free(buf);` after `const buf = try allocator.alloc(u8, n);`
**Pattern**: Every allocation that could be followed by a fallible operation needs `errdefer` cleanup.
```

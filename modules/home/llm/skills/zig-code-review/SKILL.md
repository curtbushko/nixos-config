---
name: zig-code-review
description: Use when reviewing Zig code for memory safety, resource leaks, error handling gaps, undefined behavior, allocator misuse, and semantic dead code.
---

# Zig Code Review Skill

Auto-triggers when reviewing Zig code. Catches memory-safety, resource,
error-handling, allocator, undefined-behavior, and semantic dead-code mistakes.
The triggered independent `architecture-reviewer` owns architectural verdicts.

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

- Allocator misuse: mismatched allocator on `free`, unclear allocator ownership or lifetime, `page_allocator` in tests
- API design: hidden allocations without allocator param, returning references to stack memory
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

1. **Intended consumers exist.** Inspect actual callers and the accepted public API/extension contract. Test-only callers can be valid for supported externally consumed APIs; require purpose, a consumer scenario and behavior tests. Investigate unused internal code separately.
2. **Callers do meaningful work with it.** A caller that constructs the value and immediately `deinit`s it, or only checks it is non-null, does not count. The value must flow into a real code path (persisted, returned to a caller, passed to another live function, or drives a branch).
3. **Methods serve accepted behavior.** Check internal use or supported external consumption; do not invent callers for public APIs or reject legitimate extension points solely from repository-local call counts.
4. **Every struct field is read somewhere non-trivial.** A field written by `init` and never read (or only read by `std.debug.print("{}", .{self})`-style formatting) is dead.
5. **Interface methods have implementations exercised in production.** An interface method implemented only by a test double is dead.
6. **`build.zig` modules are actually imported.** A module wired in `build.zig` that no non-test module `@import`s is dead — remove the wiring or wire it in.

**Reject criteria** (report as Critical dead code):

- Unused internal symbol with no accepted purpose or supported external contract.
- Symbol instantiated but no method/field is used by a non-test caller doing real work.
- `init`/constructor with no non-test caller.
- Speculative method with no accepted consumer behavior or implementation need.
- Field written but never read (outside format-print debug output).
- Interface method with no implementation exercised by a production path.

When flagging, name the specific symbol, list every reference found, and state which of the six checks it fails. Do not accept "it's for future use" — delete it (move to `.trash/`) or wire it in now.

## Reference Knowledge Base

See `knowledge-base.md` for the full pattern reference.

## Example Output

```
**Issue**: Missing errdefer on error path
**Severity**: Critical
**Location**: src/storage/sqlite_repo.zig:47
**Category**: resource-leak
**Fix**: Add `errdefer allocator.free(buf);` after `const buf = try allocator.alloc(u8, n);`
**Pattern**: Every allocation that could be followed by a fallible operation needs `errdefer` cleanup.
```

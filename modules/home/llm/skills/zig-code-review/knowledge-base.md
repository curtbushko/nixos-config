# Zig Code Review Knowledge Base

Categorized pattern reference. Cite by category name (e.g. `memory-safety/use-after-free`) when reporting findings.

---

## memory-safety

### use-after-free
Using a pointer or slice after `free()` / `deinit()` on its owner.

```zig
// BAD
var list = std.ArrayList(u8).init(allocator);
const items = list.items;
list.deinit();
_ = items[0]; // use after free

// GOOD
var list = std.ArrayList(u8).init(allocator);
defer list.deinit();
const items = list.items;
_ = items[0];
```

### double-free
Calling `free()` (or `deinit()`) twice on the same allocation. Usually caused by a `defer` in one path plus an explicit `free` in another.

### dangling-slice-after-mutation
Storing `list.items` across mutations that may reallocate.

```zig
// BAD
const items = list.items;
try list.append(x);       // may reallocate; items is now dangling
_ = items[0];

// GOOD
try list.append(x);
const items = list.items; // take slice AFTER mutation
_ = items[0];
```

### missing-defer
Resource acquired without `defer close`/`defer deinit`.

### missing-errdefer
Allocation without `errdefer free` for the error path.

```zig
// BAD: error path leaks
const buf = try allocator.alloc(u8, n);
try fillFromNetwork(buf);         // if fails, buf leaks

// GOOD
const buf = try allocator.alloc(u8, n);
errdefer allocator.free(buf);
try fillFromNetwork(buf);
```

---

## resource-leaks

### unclosed-file
```zig
// BAD
const file = try std.fs.cwd().openFile(path, .{});
const data = try file.readToEndAlloc(allocator, max); // if fails, file not closed

// GOOD
const file = try std.fs.cwd().openFile(path, .{});
defer file.close();
```

### undeinit-container
`ArrayList`, `HashMap`, `StringHashMap` acquired without `defer list.deinit()`.

---

## error-handling

### silent-swallow
`catch {}` or `catch |_| {}` on a fallible operation. Handle or propagate.

### wrong-return-type
`try` used inside a function whose return type is not an error union. The function must return `!T`.

### unreachable-in-reachable-path
`unreachable` in a code path that can actually execute.

---

## undefined-behavior

### unchecked-overflow
Integer arithmetic in ReleaseFast without overflow guard. Use `@addWithOverflow`, `@mulWithOverflow`, etc., or a wider type.

### uninitialized-read
```zig
// BAD
var x: T = undefined;
use(x);

// GOOD
var x: T = undefined;
@memset(std.mem.asBytes(&x), 0);
// or initialize field-by-field before first use
use(x);
```

### unchecked-optional-unwrap
`optional.?` without a prior `if (optional) |v|` or explicit null check.

### out-of-bounds-slice
`slice[i]` without checking `i < slice.len`.

---

## allocator-misuse

### mismatched-allocator
Allocated with allocator A, freed with allocator B.

### stored-allocator-in-domain
Domain types must accept allocators as parameters, not store them (and certainly not use a global one).

### page-allocator-in-tests
Tests must use `std.testing.allocator` (leak-detecting), never `std.heap.page_allocator`.

---

## api-design

### unused-parameter
Especially: silently discarding the allocator with `_ = allocator;`. Either use it or drop it from the signature.

### stack-reference-return
Returning a slice / pointer into a local. Caller sees garbage after the function returns.

### hidden-allocation
Function allocates internally but takes no allocator parameter — surprises the caller and hides ownership.

### mixed-error-styles
Mixing error unions with sentinel return values (`-1`, `null`) for the same error condition.

---

## comptime-misuse

### runtime-value-where-comptime-required
Passing a runtime value into a slot that must be known at compile time (`comptime T: type`, array sizes).

### side-effects-in-comptime
Comptime blocks that print, mutate globals, or otherwise depend on evaluation order.

---

## slice-safety

### unchecked-indexing
`data[0]` without checking `data.len > 0`.

### unbounded-slice-from-pointer
Converting a raw C pointer to a slice without knowing the length.

---

## architecture

### domain-imports-infrastructure
`@import("std").net`, `@import("std").fs`, `@cImport`, or any adapter/port module inside `src/domain/`.

### adapter-holds-business-logic
Validation, computation, or business rules inside an adapter. Adapters translate formats and do I/O — nothing else.

### app-imports-adapters
Application layer must depend on ports, not on concrete adapters.

### build-zig-cross-layer-import
`build.zig` grants a module more imports than the layer rules allow (e.g. `domain_mod.addImport("adapters", …)`). Reject.

### missing-adapter-lifecycle
Adapter holds resources but has no `init()`/`deinit()` pair, or the caller wires it without `defer`.

---

## testing

### no-leak-detection
Test uses an allocator that does not detect leaks. Must be `std.testing.allocator`.

### missing-error-tests
Fallible function has no `expectError` case.

### non-deterministic-test
Timing assertions, wall-clock comparisons, iteration-order assumptions on `HashMap`.

### happy-path-only
No edge cases (empty input, max size, null, off-by-one).

### test-only-code-in-production
`resetForTesting`, `internalPokeState`, or similar accessors added just to satisfy a test.

---

## dead-code (semantic)

See the six-check dead code review in `SKILL.md`. Common patterns:

- **only-test-callers**: Symbol referenced only from `test { ... }` blocks or `tests/` files.
- **instantiated-but-unused**: Constructor called, methods never called on the result.
- **method-never-called-outside-test**: Method on a new type has no non-test caller.
- **field-written-never-read**: Field assigned in `init` and never read except by format-print.
- **orphan-port-method**: Port method with no production adapter implementation.
- **orphan-build-module**: `build.zig` wires a module no non-test module imports.

---

## naming and organization (minor)

- Functions and variables: `snake_case`.
- Types: `PascalCase`.
- Constants: `SCREAMING_SNAKE_CASE`.
- Public API: doc comments (`///`) on every exported declaration.
- Prefer flat control flow; extract helpers over nested branches beyond 3 levels.

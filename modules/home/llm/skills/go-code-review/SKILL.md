---
name: go-code-review
description: Auto-review Go code for 100+ common mistakes when analyzing .go files, discussing Go patterns, or reviewing PRs with Go code. Checks error handling, concurrency, interfaces, performance, testing, and stdlib usage.
---

# Go Code Review Skill

Auto-triggers when reviewing Go code to catch common mistakes from https://100go.co/

## Critical Rule

**NEVER disable linting** - Do not modify `.golangci.yml`, `.go-arch-lint.yml`, `.go-ai-lint.yml`, or `Taskfile.yml` to fix lint errors. Do not use `//nolint:` directives. If lint fails, fix the underlying code issue. There are no exceptions. Fix the code, not the rules.

## Review Process

1. Read Go file(s) mentioned
2. Check against patterns in `knowledge-base.md`
3. Run the **Dead Code Review** step below
4. Report issues with:
   - Severity (Critical/Major/Minor)
   - Location (file:line)
   - Mistake # from knowledge base
   - Suggested fix
   - Code example if applicable

## Dead Code Review (Mandatory)

Static reachability tools (`deadcode`, `unused`, compiler) catch **syntactic** dead code — symbols with zero references. They miss **semantic** dead code: types, functions, or fields that are referenced only by a token test or a single instantiation, but never actually exercised by production code paths.

**A test that instantiates a symbol does NOT prove it is alive.** A common failure mode: an agent adds a type to satisfy a spec, writes `var _ = NewFoo()` or a test that constructs `Foo` and asserts nothing meaningful, and calls the type "used." The type has no purpose in the running system.

For every new or modified type, function, method, field, package, and exported symbol, verify:

1. **Non-test callers exist.** Grep for references outside `_test.go` files. If the only callers are tests, the symbol is dead — reject unless it is explicitly a test helper in a `testing`/`testutil` package.
2. **Callers do meaningful work with it.** A caller that instantiates the value and discards it, or only checks `!= nil`, does not count. The returned value must flow into a real code path (persisted, returned to a boundary, passed to another live function, or drives a branch).
3. **Every method on a new type is called from a non-test path.** A type with 5 methods where tests call all 5 but production calls 0 is dead. A type with 5 methods where production calls 1 means the other 4 are dead — flag them individually.
4. **Every struct field is read somewhere non-trivial.** A field written by a constructor and never read (or only read by `reflect`/`fmt.Sprintf("%+v", …)` in a log line) is dead.
5. **Interface methods have real implementations exercised in production.** An interface satisfied only by a mock is dead.

**Reject criteria** (report as Critical dead code):
- Symbol referenced only from `_test.go` files.
- Symbol instantiated but no method/field is used by a caller doing real work.
- Constructor with no non-test caller.
- Method on a new type never called outside its own test.
- Field written but never read (outside `%+v`-style formatting).

When flagging, name the specific symbol, list every reference you found, and state which of the five checks it fails. Do not accept "it's for future use" — delete it or wire it in now.

## Priority Checks

**Critical (must fix):**
- Error handling (#48-54): ignored errors, incorrect wrapping/comparison
- Concurrency (#58, 69, 70, 74): data races, mutex misuse, sync type copying
- Resource leaks (#26, 28, 76, 79): unclosed resources, memory leaks

**Major (should fix):**
- Interface design (#5-7): pollution, wrong side, returning interfaces
- Goroutine lifecycle (#62, 63): no stop mechanism, loop var capture
- Testing (#83, 86): no race flag, sleep in tests

**Minor (consider):**
- Code organization (#1, 2, 15): shadowing, nesting, missing docs
- Performance (#21, 27, 39): unoptimized init, string concat

## Reference Knowledge Base

See `knowledge-base.md` for full 100 Go mistakes reference.

## Example Output

```
**Issue**: Error not wrapped with context
**Severity**: Major
**Location**: handler.go:42
**Mistake**: #49 - Ignoring When to Wrap an Error
**Fix**: Use `fmt.Errorf("fetch user: %w", err)` instead of returning raw error
**Pattern**: Always wrap errors for context/traceability
```

# Go Review Patterns

Numeric heuristics and pattern preferences below are investigation signals, not
universal rejection rules. Block only against accepted requirements or concrete
correctness/maintenance risk. Respect project conventions and intentional public APIs.

## Review Priority Order

- **CRITICAL** (must fix): Error handling (#48-54), concurrency races (#58,69,70,74), resource leaks (#26,28,35,76,79), nil pointer dereferences
- **MAJOR** (should fix): Architecture violations, interface design (#5-7), testing quality (#83,86), context misuse
- **MINOR** (consider): Naming conventions, performance optimization, code organization

---

## Critical Issues (MUST CHECK)

### Error Handling

- **Error ignored**: `_ = err` or `_, _ =` patterns
- **Double handling**: Both logging AND returning error (#52)
- **Missing context**: Bare `return err` without `fmt.Errorf("context: %w", err)` (#49)
- **Wrong comparison**: Using `==` instead of `errors.Is`/`errors.As` (#50, #51)

```go
// BAD: Silent, double-handled, no context
file, _ := os.Open(filename)  // ignored
if err != nil {
    log.Printf("error: %v", err)  // logged
    return err                     // AND returned - double!
}
return err  // no context!
```

### Nil Pointer Dereferences

- Pointer params used without nil check
- Map lookups without comma-ok idiom
- Missing returns after nil checks

```go
// BAD: Panics if u is nil
func ProcessUser(u *User) string {
    return u.Name
}
```

### Resource Leaks

- HTTP responses without `defer resp.Body.Close()` (#79)
- Files, DB connections, rows without defer Close
- `defer` inside `for` loops (#35)
- `time.After` in loops without cleanup (#76)

```go
// BAD: Defer in loop - won't close until function returns!
for _, filename := range files {
    f, _ := os.Open(filename)
    defer f.Close()
}
```

### Concurrency Issues

- Loop variable capture in goroutines (pre-Go 1.22) (#63)
- Goroutines without context cancellation (#62)
- Shared variables without mutex/channels (#58)
- Copying sync.Mutex, sync.WaitGroup, etc. (#74)
- WaitGroup.Done() not deferred
- Mutex scope doesn't cover entire operation (#70)

```go
// BAD: Data race
var counter int
for i := 0; i < 10; i++ {
    go func() { counter++ }()  // DATA RACE!
}
```

### Context Misuse

- `context.Background()` in handlers (should use `r.Context()`)
- `context.TODO()` in non-test code
- HTTP requests without context

---

## Major Issues

### Project Design Compliance

- Check against the project's approved design and existing package boundaries.
- Do not require a particular layering scheme or directory layout unless the project requires it.

### Interface Design

- Interface >5 methods (#5)
- Interface defined at implementation instead of consumer (#6)
- Returning interfaces instead of concrete types (#7)

### Unsafe Operations

- Type assertions without comma-ok: `v.(Type)` instead of `v, ok := v.(Type)`
- Defer args evaluated immediately (wrap in closure for deferred eval)
- Nil map writes
- Slice modification during iteration

---

## Testing Issues

- Testing mock behavior instead of actual behavior
- Test-only methods in production code
- Mocks that neuter functionality tests depend on
- Missing `-race` flag (#83)
- `time.Sleep` instead of sync primitives (#86)

---

## Preferred Patterns

### io.Reader/io.Writer

Accept interfaces, not concrete types. Maximize composability.

```go
// BAD: Tied to concrete type
func ProcessFile(f *os.File) error { ... }
// GOOD: Accepts any reader
func ProcessData(r io.Reader) error { ... }
```

### Embedding for Composition

Use wrappers/decorators instead of inheritance-like patterns.

```go
// GOOD: Decorator pattern
type LoggingRepository struct {
    Repository
    logger *slog.Logger
}
```

---

## Quick Reference

| # | Issue | Check |
|---|-------|-------|
| 5 | Interface Pollution | >5 methods? Created upfront? |
| 6 | Producer-Side Interface | Defined where implemented? |
| 7 | Returning Interface | Returns interface not concrete? |
| 21 | Slice Init | Could be preallocated? |
| 27 | Map Init | Could be preallocated? |
| 35 | Defer in Loop | Defer inside for/range? |
| 39 | String Concat | += in loop instead of Builder? |
| 48-53 | Error Handling | Ignored, doubled, or unwrapped? |
| 58,70 | Data Race | Shared state without sync? |
| 62 | Goroutine Lifecycle | No stop mechanism? |
| 63 | Loop Variables | Captured without param? |
| 74 | Copying Sync Types | sync.Mutex copied by value? |
| 76 | time.After Leaks | In loop without cleanup? |
| 79 | Resource Closing | defer Close() missing? |
| 83 | Race Flag | Tests run with -race? |
| 86 | Sleep in Tests | time.Sleep instead of sync? |

---


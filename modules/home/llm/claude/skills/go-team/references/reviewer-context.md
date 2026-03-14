# Go Reviewer Context

The reviewer performs BOTH spec compliance AND code quality review in a single pass.

**IMPORTANT**: For detailed patterns, see the shared Go references at `~/.claude/skills/golang/references/`:
- [architecture.md](../../golang/references/architecture.md) - Hexagonal architecture
- [ai-code-problems.md](../../golang/references/ai-code-problems.md) - Common AI mistakes and fixes

---

## Review Procedure

1. **Read task acceptance criteria** from `.tasks/task-{task.id}.yaml`
2. **Read build results** from `.tasks/result-{task.id}-build.yaml`
3. **Stage 1: Spec Compliance** - Check requirements, under/over-building
4. **Stage 2: Code Quality** - Only if Stage 1 passes. Check patterns below.
5. **Write results** to `.tasks/result-{task.id}-review.yaml`
6. **Return only verdict** to orchestrator (2 lines max)

### Spec Compliance Checks
- Each acceptance criterion fully implemented and tested?
- Under-building: missing or partial implementations? TODOs?
- Over-building: code beyond spec? Extra features? Premature optimization?
- Test coverage: each requirement has tests? Edge cases? Error paths?

---

## Lint Verification

Before approving, confirm lint passes:
```bash
make lint            # REQUIRED - error if Makefile not found
```

**IMPORTANT**: Always use `make lint` for linting. If no Makefile exists, STOP and report an error requesting one be added.

**DO NOT MODIFY** linting configuration files (`.golangci.yml`, `.go-arch-lint.yml`, `.go-ai-lint.yml`, `Taskfile.yml`). These are project-level standards. If code fails lint, fix the code, not the rules.

**NEVER disable linting globally** - Do not remove, comment out, or disable lint rules in config files. Per-function exceptions (e.g., `//nolint:rulename` directives) are acceptable when truly necessary, but global changes affect the entire codebase.

---

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

### Architecture Violations
- Domain importing adapters (`database/sql`, `net/http`)
- Service depending on concrete type instead of interface
- Business logic in handlers

```go
// BAD: Domain imports adapter
package domain
import "database/sql"  // NO!

// BAD: Concrete dependency
func NewUserService(repo *postgres.UserRepository) // NO!
```

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
    ports.Repository
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

## Output Format

### File Output (write to `.tasks/result-{task.id}-review.yaml`)

```yaml
task_id: {task.id}

spec_compliance:
  criteria_assessment: [{criterion, status: met|partial|missing, evidence}]
  under_building: {found, issues}
  over_building: {found, issues}

code_quality:
  findings:
    critical: [{issue, location, mistake_ref, category, fix}]
    major: [{issue, location, fix}]
    minor: [{issue, suggestion}]
  architecture: {compliant, violations}

verdict: APPROVED|CHANGES_NEEDED
changes_required: [{priority, description, location}]
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY this to the orchestrator:
```
verdict: APPROVED|CHANGES_NEEDED
issues: [count of changes_required]
```

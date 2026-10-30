---
name: go-reviewer
description: Use when a go-team reviewer checks specification compliance then code quality. Returns revision-bound review evidence for serial mtn publication; patterns live in go-code-review and golang.
---

# Go Reviewer Skill

Read by a subagent dispatched from `go-team`. The reviewer performs BOTH spec compliance AND code quality review in a single pass.

For detailed patterns, see the shared Go references:

- `golang` and its architecture/common-mistake references
- `go-code-review` for Go mistake patterns and semantic dead-code checks
- `mtn-tasks` and its short worker contract for exact handoff and evidence rules

Read the short worker contract, not coordinator/migration internals. Receive absolute collection root, exact task ref,
build event ID, spec hash, isolated worktree path, base/head/tree and attempt.
Review THAT frozen checkout, not the current parent checkout. Isolate mutable check
outputs/resources or serialize checks with other reviewers. Source and managed records are read-only; return evidence for coordinator
publication. Do not complete tasks, mutate frontmatter, or fix source.

---

## Review Procedure

1. Read task acceptance criteria and current build/fix evidence through `agent show`.
2. Confirm the evidence matches the frozen code/diff identity being reviewed.
3. **Stage 1: Spec Compliance** — requirements, under/over-building.
4. **Stage 2: Code Quality** — only if Stage 1 passes; include semantic dead code.
5. Return full findings and verdict payload under the mtn-tasks evidence contract.
6. Coordinator serially publishes it as a `review` note; publication is required
   before the verdict can authorize completion.

### Spec Compliance Checks

- Each acceptance criterion fully implemented and tested?
- Under-building: missing or partial implementations? TODOs?
- Over-building: code beyond spec? Extra features? Premature optimization?
- Test coverage: each requirement has tests? Edge cases? Error paths?

---

## File Rules

**NEVER create .gitkeep files.** Git tracks files, not directories.

**NEVER use `rm` to delete files.** Instead, move files to `.trash/`:

```bash
mkdir -p .trash
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

---

## Lint Verification

Before approving, confirm lint passes:

```bash
task lint            # REQUIRED - error if Taskfile not found
```

**IMPORTANT**: Always use `task lint` for linting. If no Taskfile exists, STOP and report an error requesting one be added.

**DO NOT MODIFY** linting configuration files (`.golangci.yml`, `.go-arch-lint.yml`, `.go-ai-lint.yml`, `Taskfile.yml`). These are project-level standards. If code fails lint, fix the code, not the rules.

**NEVER disable linting** — Do not use `//nolint:` directives. Do not remove, comment out, or disable lint rules in config files. If lint fails, fix the underlying code issue. There are no exceptions.

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

## Review Evidence

Return a protocol v1 `review` JSON payload through host delivery: common schemaVersion,
eventId, kind, recordRef, specHash and attempt; buildEventId, matching head/tree,
`reviewer: combined`, APPROVED or
CHANGES_NEEDED, criterion-by-criterion assessment, under/over-building, quality and
architecture findings, lint/independent command evidence, and limitations.
Each blocker has a stable ID, file:line, violated rule, evidence/impact, required
outcome, and re-review scope. Keep `NON_BLOCKING_SUGGESTIONS` distinct from blockers.
Missing/stale validation prevents approval; personal preference does not.

The coordinator serially appends the full payload as mtn note content and verifies
it via `show`. Do not write sidecar results or concurrently append review notes.
A two-line verdict without durable findings is insufficient. Return a concise
verdict/count alongside the full payload; never mutate task lifecycle status.
A new build requires a fresh explicit verdict. Approval authorizes coordinator-owned
integration only; combined-target checks and integration/completion evidence are
required before native task completion.

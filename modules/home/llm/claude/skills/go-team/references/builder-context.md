# Go Builder Context Injection

This context is injected into every Go Builder agent dispatch.

## TDD Workflow (NON-NEGOTIABLE)

```
1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green
```

## Build Quality Gates

Before completing, ALL must pass:
```bash
go build ./...
go test ./...
golangci-lint run
go-arch-lint check  # if config exists
make lint            # if Makefile exists
task lint            # if Taskfile exists (fallback if no Makefile)
```

---

## Hexagonal Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     ADAPTERS (Outer)                        │
│  ┌─────────────┐                         ┌─────────────┐   │
│  │  Handlers   │                         │ Repositories│   │
│  │  (HTTP/gRPC)│                         │ (DB/Cache)  │   │
│  └──────┬──────┘                         └──────┬──────┘   │
│         │         ┌───────────────┐             │           │
│         └────────►│    PORTS      │◄────────────┘           │
│                   │  (Interfaces) │                         │
│                   └───────┬───────┘                         │
│                   ┌───────▼───────┐                         │
│                   │   SERVICES    │                         │
│                   │ (Use Cases)   │                         │
│                   └───────┬───────┘                         │
│                   ┌───────▼───────┐                         │
│                   │    DOMAIN     │                         │
│                   │  (Entities)   │                         │
│                   └───────────────┘                         │
│                      CORE (Inner)                           │
└─────────────────────────────────────────────────────────────┘

Dependencies flow INWARD:
  adapters/handlers -> core/services -> core/domain
  adapters/repositories -> core/ports <- core/services

Domain layer has NO external dependencies
```

### Layer Locations

| Layer | Path | Contains |
|-------|------|----------|
| Domain | `internal/core/domain/` | Entities, value objects, domain errors |
| Ports | `internal/core/ports/` | Interface definitions |
| Services | `internal/core/services/` | Business logic, use cases |
| Handlers | `internal/adapters/handlers/` | HTTP/gRPC entry points |
| Repositories | `internal/adapters/repositories/` | Database implementations |

---

## Code Patterns

### Error Handling
```go
// Wrap with context
return fmt.Errorf("operation failed: %w", err)

// Check wrapped errors
errors.As(err, &targetType)
errors.Is(err, sentinelErr)

// Handle ONCE - log OR return, not both
if err != nil {
    return fmt.Errorf("fetch user: %w", err)
}
```

### Interfaces
```go
// Define where used, not where implemented
// Keep small (1-3 methods)
// Name with -er suffix for single method
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

// Return concrete types, not interfaces
func NewUserService(repo UserRepository) *userService {
    return &userService{repo: repo}
}
```

### Table-Driven Tests
```go
func TestFeature(t *testing.T) {
    tests := []struct {
        name    string
        input   Input
        want    Output
        wantErr bool
    }{
        {"valid input", validInput, expectedOutput, false},
        {"empty input", emptyInput, Output{}, true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Feature(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("got %v, want %v", got, tt.want)
            }
        })
    }
}
```

### Reader/Writer (io.Reader / io.Writer) — Preferred Pattern

The `io.Reader` and `io.Writer` interfaces are the most important interfaces in Go. Nearly everything that deals with streams of bytes (files, network connections, buffers, compression, HTTP bodies) implements one or both. Their power comes from their simplicity: just one method each (`Read` and `Write`), which makes them endlessly composable.

```go
// Accept io.Reader/io.Writer to maximize composability
func ProcessData(r io.Reader) ([]byte, error) {
    return io.ReadAll(r)
}

// Works with files, buffers, HTTP bodies, compression, etc.
f, _ := os.Open("data.txt")
ProcessData(f)

var buf bytes.Buffer
ProcessData(&buf)

ProcessData(resp.Body)
```

**Prefer `io.Reader`/`io.Writer` parameters over concrete types** (like `*os.File` or `*bytes.Buffer`) whenever you deal with byte streams. This makes your code testable, composable, and reusable.

### Embedding for Composition (Decorator / Wrapper Pattern) — Preferred Pattern

Go doesn't have inheritance. The stdlib relies heavily on struct embedding and wrapping to layer behavior. Examples: `bufio.Reader` wrapping an `io.Reader`, `io.LimitedReader`, `io.TeeReader`, `cipher.StreamReader`, `gzip.Reader`. Each takes a simpler type and adds functionality on top.

```go
// Wrap an io.Reader to add counting behavior
type CountingReader struct {
    io.Reader
    BytesRead int64
}

func (cr *CountingReader) Read(p []byte) (int, error) {
    n, err := cr.Reader.Read(p)
    cr.BytesRead += int64(n)
    return n, err
}

// Usage: layer behaviors via wrapping
func NewCountingReader(r io.Reader) *CountingReader {
    return &CountingReader{Reader: r}
}

// Compose decorators: counting + buffered + gzip
raw, _ := os.Open("data.gz")
counted := NewCountingReader(raw)
buffered := bufio.NewReader(counted)
gz, _ := gzip.NewReader(buffered)
```

**Prefer composition via embedding/wrapping over large interfaces.** When you need new behavior, wrap an existing small interface rather than expanding the interface.

### Domain Entity Example
```go
// internal/core/domain/user.go
package domain

import (
    "errors"
    "time"
)

var (
    ErrUserNotFound   = errors.New("user not found")
    ErrInvalidEmail   = errors.New("invalid email format")
    ErrDuplicateEmail = errors.New("email already exists")
)

type User struct {
    ID        string
    Email     string
    Name      string
    CreatedAt time.Time
    UpdatedAt time.Time
}

func NewUser(email, name string) (*User, error) {
    if !isValidEmail(email) {
        return nil, ErrInvalidEmail
    }
    return &User{
        Email:     email,
        Name:      name,
        CreatedAt: time.Now(),
        UpdatedAt: time.Now(),
    }, nil
}

func (u *User) UpdateName(name string) {
    u.Name = name
    u.UpdatedAt = time.Now()
}
```

### Service Example
```go
// internal/core/services/user_service.go
package services

import (
    "context"
    "fmt"

    "myapp/internal/core/domain"
    "myapp/internal/core/ports"
)

type userService struct {
    repo ports.UserRepository
}

func NewUserService(repo ports.UserRepository) ports.UserService {
    return &userService{repo: repo}
}

func (s *userService) CreateUser(ctx context.Context, email, name string) (*domain.User, error) {
    existing, err := s.repo.FindByEmail(ctx, email)
    if err != nil && err != domain.ErrUserNotFound {
        return nil, fmt.Errorf("check existing user: %w", err)
    }
    if existing != nil {
        return nil, domain.ErrDuplicateEmail
    }

    user, err := domain.NewUser(email, name)
    if err != nil {
        return nil, fmt.Errorf("create user: %w", err)
    }

    if err := s.repo.Save(ctx, user); err != nil {
        return nil, fmt.Errorf("save user: %w", err)
    }

    return user, nil
}
```

---

## Common Lint Fixes

| Error | WRONG Fix | CORRECT Fix |
|-------|-----------|-------------|
| `defer in loop` | Remove defer | Extract to helper function |
| `error ignored` | Add `_ = err` | Handle or wrap and return |
| `GetX() naming` | Rename to `GetterX()` | Rename to `X()` (drop Get) |
| `nil map write` | Remove the write | Initialize with `make()` |
| `context.TODO()` | Use Background() everywhere | Accept ctx as parameter |
| `goroutine no cancel` | Add `return` | Use ctx.Done() in select |
| `wg.Done not deferred` | Add multiple Done() | `defer wg.Done()` at start |
| `string concat in loop` | Use fmt.Sprintf | Use strings.Builder |

---

## Systematic Debugging (When Stuck)

If build/test fails repeatedly:

### Phase 1: Root Cause Investigation
1. Read error messages COMPLETELY
2. Reproduce consistently
3. Check recent changes (git diff)
4. Trace data flow from source to error

### Phase 2: Pattern Analysis
1. Find working examples in codebase
2. Compare against references
3. Identify differences

### Phase 3: Hypothesis Testing
1. Form ONE clear hypothesis
2. Change ONE variable
3. Verify before continuing

### Red Flags - STOP If:
- "Quick fix for now"
- "Just try changing X"
- Already tried 3+ fixes
- Proposing solutions BEFORE tracing data flow

**Gate Function:**
```
BEFORE any fix:
  Ask: "Do I know the ROOT CAUSE?"
  IF no: STOP - Return to Phase 1
  IF yes: Document it, THEN fix
```

---

## Testing Anti-Patterns to Avoid

### Never Test Mock Behavior
```go
// BAD - Testing the mock, not the code
if !mockDB.CalledWith("expected") {
    t.Fatal("mock not called correctly")
}

// GOOD - Test actual behavior
result := handler.Process(input)
if result.Status != "success" {
    t.Fatalf("expected success, got %s", result.Status)
}
```

### Never Add Test-Only Methods to Production
```go
// BAD - Test pollution
func (c *Cache) Reset() {  // Only used in tests!
    c.data = make(map[string]interface{})
}

// GOOD - Test utilities in test package
func cleanupCache(t *testing.T, c *Cache) {
    t.Helper()
    // Access via reflection or test package
}
```

### Mock Gate Function
```
BEFORE mocking any method:
  1. "What side effects does the real method have?"
  2. "Does this test depend on those side effects?"
  3. "Do I fully understand what this test needs?"

IF depends on side effects:
  Mock at LOWER level, not the method test depends on
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
  lint: pass|fail
  arch: pass|fail|skipped

commits:
  - hash: [short hash]
    message: [message]

summary: [1-2 sentences]
```

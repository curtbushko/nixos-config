# Golang Development Skill

You are an expert Go developer who follows Test-Driven Development (TDD) principles, hexagonal architecture, and Go best practices.

## Critical Requirements

### Build Quality (NON-NEGOTIABLE)
- **Build, lint, architecture check, and test MUST ALWAYS be passing**
- Before completing any task, verify:
  - `go build ./...` succeeds with no errors
  - `go test ./...` passes all tests
  - `golangci-lint run` reports no issues
  - `go-arch-lint check` passes (if `.go-arch-lint.yml` exists)
- If any of these fail, fix the issues before marking the task complete
- NEVER leave code in a broken state

### Architecture Enforcement (NON-NEGOTIABLE)
- **All Go projects MUST follow Hexagonal/Onion Architecture**
- Use `go-arch-lint` to enforce architectural boundaries
- Dependencies flow INWARD: handlers -> services -> domain
- Domain layer has NO external dependencies
- See [references/architecture.md](references/architecture.md) for detailed patterns

### Output and Documentation Standards
- **NEVER use emojis in code, comments, documentation, or any output**
- Keep all communication professional and text-based
- Use clear, descriptive text instead of visual symbols
- This applies to: code comments, README files, commit messages, error messages, logs, and user-facing output

### Test-Driven Development (TDD)
**ALWAYS follow the TDD cycle when implementing new functionality:**

1. **RED**: Write a failing test first
   - Write the test that describes the desired behavior
   - Run the test and confirm it fails for the right reason
   - This validates that the test can actually detect failures

2. **GREEN**: Write minimal code to make the test pass
   - Implement just enough code to make the test pass
   - Don't add extra features or over-engineer
   - Run the test and confirm it passes

3. **REFACTOR**: Improve the code while keeping tests green
   - Clean up the implementation
   - Remove duplication
   - Improve naming and structure
   - Run tests after each refactoring to ensure they still pass

**Testing Best Practices:**
- Write table-driven tests for multiple scenarios
- Use subtests with `t.Run()` for better test organization
- Test both happy paths and error cases
- Use test helpers to reduce duplication
- Mock external dependencies using interfaces
- Prefer black-box testing (package_test) when possible

## Code Organization

### Hexagonal Architecture Structure (MANDATORY)
**All Go projects MUST follow this layered architecture:**

```
project/
├── cmd/                      # Application entry points
│   └── myapp/
│       └── main.go           # Wires everything together
├── internal/
│   ├── adapters/             # OUTER LAYER: Infrastructure
│   │   ├── handlers/         # HTTP/gRPC handlers (primary/driving)
│   │   │   ├── http/
│   │   │   └── grpc/
│   │   └── repositories/     # Database implementations (secondary/driven)
│   │       ├── postgres/
│   │       └── redis/
│   ├── core/                 # INNER LAYERS: Business Logic
│   │   ├── domain/           # Entities, value objects, domain errors
│   │   │   ├── user.go
│   │   │   └── errors.go
│   │   ├── ports/            # Interfaces (contracts)
│   │   │   ├── repositories.go
│   │   │   └── services.go
│   │   └── services/         # Use cases / application logic
│   │       └── user_service.go
│   └── config/               # Configuration loading
├── pkg/                      # Public library code (reusable)
├── .go-arch-lint.yml         # Architecture enforcement rules
├── .golangci.yml             # Linting rules
└── go.mod
```

### Architectural Layers

| Layer | Location | Depends On | Description |
|-------|----------|------------|-------------|
| Domain | `internal/core/domain/` | Nothing | Entities, value objects, domain errors |
| Ports | `internal/core/ports/` | Domain | Interfaces defining contracts |
| Services | `internal/core/services/` | Domain, Ports | Business logic / use cases |
| Adapters | `internal/adapters/` | Ports, Domain | Infrastructure implementations |
| Main | `cmd/` | Everything | Dependency injection, wiring |

### Dependency Rules (ENFORCED BY go-arch-lint)
```
handlers   -> services  (handlers call services)
services   -> ports     (services use port interfaces)
services   -> domain    (services use domain types)
adapters   -> ports     (adapters implement ports)
adapters   -> domain    (adapters use domain types)
domain     -> (nothing) (domain is pure, no dependencies)
```

**Package Design Principles:**
- Keep packages focused on a single responsibility
- Use `internal/` for code that shouldn't be imported by external projects
- Use `pkg/` for code that could be reused in other projects
- Package names are part of the API—choose them carefully
- Avoid circular dependencies between packages
- **Domain layer MUST NOT import from adapters or external packages**

### Interfaces for Testability
**Design with interfaces to enable easy testing:**

```go
// Define interfaces for components that need to be mocked
type Storage interface {
    Save(ctx context.Context, data []byte) error
    Load(ctx context.Context, id string) ([]byte, error)
}

// Concrete implementation
type FileStorage struct {
    basePath string
}

func (fs *FileStorage) Save(ctx context.Context, data []byte) error {
    // Implementation
}

// Mock for testing
type MockStorage struct {
    SaveFunc func(ctx context.Context, data []byte) error
    LoadFunc func(ctx context.Context, id string) ([]byte, error)
}
```

**Interface Guidelines:**
- Accept interfaces, return concrete types (usually)
- Keep interfaces small (1-3 methods is ideal)
- Define interfaces where they're used, not where they're implemented
- Name single-method interfaces with "-er" suffix: `Reader`, `Writer`, `Uploader`
- Use embedding to compose larger interfaces from smaller ones

## Function Naming Conventions

### Core Principles
**Keep function names simple and rely on package context:**

GOOD: `uploader.Upload()` - package name provides context
BAD: `uploader.UploaderUpload()` - redundant

**Package names are part of the description:**
- In package `http`, use `Client` not `HTTPClient`
- In package `storage`, use `Save` not `StorageSave`
- In package `parser`, use `Parse` not `ParseJSON`

### Edge Cases and Features
**Do NOT document edge cases or implementation details in function names:**

GOOD: `Upload()` - implementation details are hidden
BAD: `UploadWithRetries()`, `UploadWithBackoff()`

**Best practices (retries, backoffs, jitter, timeouts) are implicit:**
- These are expected in production code
- Don't clutter names with implementation details
- Use options or configuration to control behavior

### When to Break the Rules
**Sometimes wrapper functions with arguments improve testing and compatibility:**

```go
// Public API with defaults
func Upload(ctx context.Context, data []byte) error {
    return UploadWithConfig(ctx, data, DefaultConfig)
}

// Internal function with configurable behavior
func UploadWithConfig(ctx context.Context, data []byte, cfg Config) error {
    // Implementation with retries, backoff, etc.
}
```

**This pattern is acceptable when:**
- The wrapped function provides better testability
- You need to maintain backward compatibility
- The edge case can be controlled via a parameter
- It makes the public API simpler

### Adding Features to Functions
**Prefer wrapper functions with parameters over new function names:**

GOOD: Add a parameter to control behavior
```go
func Process(data []byte, opts ...Option) error
```

BAD: Create a new function for each variant
```go
func Process(data []byte) error
func ProcessWithValidation(data []byte) error
func ProcessWithValidationAndRetries(data []byte) error
```

## Effective Go Best Practices

### Naming
- **Packages**: Short, concise, lowercase, single-word (avoid underscores)
- **Exported**: Start with uppercase letter (visible outside package)
- **Unexported**: Start with lowercase letter (private to package)
- **Getters**: Don't use "Get" prefix—use `Owner()` not `GetOwner()`
- **Interfaces**: Use agent nouns ending in "-er" for single-method interfaces
- **Variables**: Use short names in small scopes, longer names for broader scope

### Formatting
- Use `gofmt` or `goimports` for automatic formatting
- Always use braces, even for single statements
- Opening brace on same line as control keyword
- Use tabs for indentation

### Error Handling
- Return errors as values: `func Read() ([]byte, error)`
- Check errors immediately after the call
- Use early returns (guard clauses) instead of nested else statements
- Wrap errors with context: `fmt.Errorf("failed to read file: %w", err)`
- Define custom error types when you need to distinguish error kinds

```go
// Guard clause pattern (GOOD)
func Process(data []byte) error {
    if len(data) == 0 {
        return errors.New("empty data")
    }

    result, err := transform(data)
    if err != nil {
        return fmt.Errorf("transform failed: %w", err)
    }

    return save(result)
}
```

### Functions and Methods
- Use multiple return values, especially for (result, error) pattern
- Use named return parameters for documentation and clarity
- Use `defer` for cleanup operations (closing files, unlocking mutexes)
- Keep functions small and focused

### Data Structures
- Design types so their zero value is useful
- Use `make()` for slices, maps, and channels (creates initialized value)
- Use `new()` for pointers to zero-valued structs (rarely needed)
- Prefer slices over arrays
- Use the "comma ok" idiom for maps: `value, ok := m[key]`

### Interfaces
- Keep interfaces small (1-3 methods is common)
- Define interfaces where they're used, not implemented
- Embed interfaces to compose larger ones
- Use type assertions carefully: `value, ok := x.(Type)`

### Concurrency
- **Share by communicating**: Use channels instead of shared memory + locks
- Goroutines are cheap—use them liberally for concurrent tasks
- Use buffered channels as semaphores to limit concurrency
- Use `select` to multiplex channel operations
- Close channels when done to signal completion
- Use `sync.WaitGroup` to wait for goroutines to complete
- Use `context.Context` for cancellation and timeouts

```go
// Good concurrency pattern
func ProcessConcurrently(items []Item, maxWorkers int) error {
    ctx, cancel := context.WithTimeout(context.Background(), 5*time.Minute)
    defer cancel()

    sem := make(chan struct{}, maxWorkers)
    errCh := make(chan error, len(items))

    for _, item := range items {
        sem <- struct{}{} // Acquire semaphore
        go func(item Item) {
            defer func() { <-sem }() // Release semaphore
            if err := process(ctx, item); err != nil {
                errCh <- err
            }
        }(item)
    }

    // Wait for all goroutines
    for i := 0; i < maxWorkers; i++ {
        sem <- struct{}{}
    }

    close(errCh)
    for err := range errCh {
        if err != nil {
            return err
        }
    }
    return nil
}
```

### Panic and Recover
- Use `panic` only for truly unrecoverable errors (usually during init)
- Use `recover` in deferred functions to regain control
- Most functions should return errors, not panic

### Initialization
- Use `init()` functions for package-level initialization
- Keep init functions minimal and side-effect free when possible
- Remember: init runs after all variable initializers

## Development Workflow

### Before You Start Coding
1. Understand the requirement clearly
2. Identify which layer the code belongs to (domain/ports/services/adapters)
3. Identify which packages/interfaces will be affected
4. Plan the test cases you'll need to write
5. Consider the API design before implementation

### During Development
1. Write the test first (RED)
2. Implement minimal code to pass (GREEN)
3. Refactor while keeping tests green (REFACTOR)
4. Commit frequently with clear messages
5. Run build, lint, architecture check, and test regularly

### Before Completing
1. Run `go build ./...` (must pass)
2. Run `go test ./...` (must pass)
3. Run `golangci-lint run` (must pass)
4. Run `go-arch-lint check` (must pass, if config exists)
5. Review function names for simplicity
6. Check that interfaces are properly defined
7. Verify package organization follows hexagonal architecture
8. Ensure error handling is proper
9. Verify no emojis in code, comments, or documentation

## Code Review Checklist

- [ ] All tests pass (`go test ./...`)
- [ ] Build succeeds (`go build ./...`)
- [ ] Linter passes (`golangci-lint run`)
- [ ] Architecture check passes (`go-arch-lint check`)
- [ ] Code follows TDD—tests written first
- [ ] Code placed in correct architectural layer
- [ ] Domain layer has no external dependencies
- [ ] Interfaces (ports) used for dependencies
- [ ] Function names are simple (no edge cases in names)
- [ ] Package names are short and clear
- [ ] Error handling is proper (no ignored errors)
- [ ] Proper use of context for cancellation/timeouts
- [ ] Concurrent code uses channels or proper synchronization
- [ ] No exported names in `internal/` packages
- [ ] Documentation comments for exported symbols
- [ ] No emojis in any code, comments, or documentation

## Common Patterns

### Option Pattern for Configuration
```go
type Option func(*Config)

func WithRetries(n int) Option {
    return func(c *Config) {
        c.Retries = n
    }
}

func Upload(data []byte, opts ...Option) error {
    cfg := DefaultConfig
    for _, opt := range opts {
        opt(&cfg)
    }
    // Use cfg
}
```

### Table-Driven Tests
```go
func TestProcess(t *testing.T) {
    tests := []struct {
        name    string
        input   []byte
        want    Result
        wantErr bool
    }{
        {"empty input", []byte{}, Result{}, true},
        {"valid input", []byte("data"), Result{Value: "data"}, false},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            got, err := Process(tt.input)
            if (err != nil) != tt.wantErr {
                t.Errorf("Process() error = %v, wantErr %v", err, tt.wantErr)
                return
            }
            if !reflect.DeepEqual(got, tt.want) {
                t.Errorf("Process() = %v, want %v", got, tt.want)
            }
        })
    }
}
```

### Interface Mocking
```go
type Uploader interface {
    Upload(ctx context.Context, data []byte) error
}

type MockUploader struct {
    UploadFunc func(ctx context.Context, data []byte) error
}

func (m *MockUploader) Upload(ctx context.Context, data []byte) error {
    if m.UploadFunc != nil {
        return m.UploadFunc(ctx, data)
    }
    return nil
}
```

## Linting and Architecture Enforcement

### Required Tools
```bash
# Install golangci-lint
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest

# Install go-arch-lint
go install github.com/fe3dback/go-arch-lint@latest
```

### Configuration Files
Every Go project MUST have these configuration files:
- `.golangci.yml` - See [references/golangci.yml](references/golangci.yml)
- `.go-arch-lint.yml` - See [references/go-arch-lint.yml](references/go-arch-lint.yml)

### Running Checks
```bash
# Full validation (run before every commit)
go build ./...
go test ./...
golangci-lint run
go-arch-lint check

# Quick architecture visualization
go-arch-lint graph
```

### Handling Lint Errors (CRITICAL - Prevents Fix Loops)

**When you encounter a linting error, STOP and think before fixing:**

1. **Understand the WHY** - Read the error message completely. What problem is it preventing?
2. **Understand the CONSEQUENCE** - What would happen if you ignored this?
3. **Plan the FIX** - What is the correct pattern to use?
4. **Avoid common wrong fixes** - See table below

**Common Lint Errors and Correct Fixes:**

| Error | WRONG Fix | CORRECT Fix |
|-------|-----------|-------------|
| `defer in loop` | Remove defer | Extract to helper function |
| `defer in loop` | Move defer outside loop | Extract to helper function |
| `error ignored` | Add `_ = err` | Handle the error or wrap and return |
| `error ignored` | Delete the line | Check error and handle appropriately |
| `nil map write` | Remove the write | Initialize with `make(map[K]V)` |
| `context.TODO()` | Remove context | Pass context from caller or use `context.Background()` |
| `context.TODO()` | Use `context.Background()` everywhere | Accept `context.Context` as first parameter |
| `GetX() naming` | Rename to `GetterX()` | Rename to `X()` (drop Get prefix) |
| `goroutine no cancel` | Add `return` statement | Add `ctx.Done()` check in select |
| `interface too large` | Add more methods | Split into smaller focused interfaces |
| `wg.Done not deferred` | Remove wg.Done() | Wrap with `defer wg.Done()` at goroutine start |
| `string concat in loop` | Use `fmt.Sprintf` | Use `strings.Builder` |
| `panic in library` | Remove panic | Return error instead |
| `unsafe type assertion` | Keep as-is | Use comma-ok: `v, ok := x.(T)` |

**Example - Fixing "defer in loop" correctly:**

```go
// ORIGINAL (triggers AIL001)
for _, f := range files {
    file, _ := os.Open(f)
    defer file.Close()  // ERROR: defer in loop
    process(file)
}

// WRONG FIX 1: Removing defer
for _, f := range files {
    file, _ := os.Open(f)
    process(file)
    file.Close()  // WRONG: skipped on panic or early return
}

// WRONG FIX 2: Moving defer outside
var file *os.File
for _, f := range files {
    file, _ = os.Open(f)
    process(file)
}
defer file.Close()  // WRONG: only closes last file

// CORRECT FIX: Extract to helper function
for _, f := range files {
    if err := processFile(f); err != nil {
        return err
    }
}

func processFile(path string) error {
    file, err := os.Open(path)
    if err != nil {
        return err
    }
    defer file.Close()  // CORRECT: closes after each iteration
    return process(file)
}
```

**If you find yourself in a fix loop (same error keeps appearing):**
1. STOP making changes
2. Re-read the original error message
3. Check the "WRONG Fix" patterns above
4. Ask for clarification if needed

## Quick Reference

| Task | Command |
|------|---------|
| Build | `go build ./...` |
| Test | `go test ./...` |
| Test with race detector | `go test -race ./...` |
| Lint | `golangci-lint run` |
| Lint with fix | `golangci-lint run --fix` |
| Architecture check | `go-arch-lint check` |
| Architecture graph | `go-arch-lint graph` |

## Additional Resources

- Architecture patterns: [references/architecture.md](references/architecture.md)
- golangci-lint config: [references/golangci.yml](references/golangci.yml)
- go-arch-lint config: [references/go-arch-lint.yml](references/go-arch-lint.yml)

---

**Remember**: Write tests first, follow hexagonal architecture, keep domain pure, use interfaces for dependencies, ensure build/lint/arch-check/test always pass, and never use emojis!

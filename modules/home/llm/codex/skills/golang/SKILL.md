---
name: golang
description: Golang Development Guidelines
---

# Golang Development Guidelines

You are an expert Go developer who follows Test-Driven Development (TDD) principles, hexagonal architecture, and Go best practices.

## Build Quality (NON-NEGOTIABLE)

Build, lint, architecture check, and test MUST ALWAYS be passing.

Before completing any task, verify:
- `task build` succeeds with no errors
- `task test` passes all tests
- `task lint` reports no issues
- `go-arch-lint check` passes (if `.go-arch-lint.yml` exists)

NEVER leave code in a broken state. Always use Taskfile targets. If no Taskfile exists, STOP and report an error.

**DO NOT MODIFY** linting configuration files (`.golangci.yml`, `.go-arch-lint.yml`, `.go-ai-lint.yml`, `Taskfile.yml`). These are project-level standards. Fix the code, not the rules.

**NEVER disable linting** - Do not use `//nolint:` directives. Do not remove, comment out, or disable lint rules. If lint fails, fix the underlying code issue.

## Architecture Enforcement (NON-NEGOTIABLE)

All Go projects MUST follow Hexagonal/Onion Architecture:
- Use `go-arch-lint` to enforce architectural boundaries
- Dependencies flow INWARD: adapters -> application -> ports -> domain
- Domain layer has NO external dependencies

## CLI Framework (NON-NEGOTIABLE)

All service CLI entry points MUST use Cobra and Viper:
- Use [spf13/cobra](https://github.com/spf13/cobra) for command-line interface structure
- Use [spf13/viper](https://github.com/spf13/viper) for configuration management
- Cobra provides: subcommands, flags, help generation, shell completion
- Viper provides: config files, environment variables, flag binding, defaults
- Place root command in `cmd/<app>/root.go`, subcommands in separate files
- Bind Viper to Cobra flags: `viper.BindPFlag("key", cmd.Flags().Lookup("flag"))`

## Testing Framework (NON-NEGOTIABLE)

All tests MUST use [testify](https://github.com/stretchr/testify) for assertions and mocking:
- Use `assert` for non-fatal assertions, `require` for fatal assertions
- Use `mock` package for mock generation and verification
- Use `suite` package for test suites when appropriate
- Exception: Kubernetes e2e tests may use the Kubernetes e2e testing framework

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestExample(t *testing.T) {
    require.NotNil(t, result, "result should not be nil")
    assert.Equal(t, expected, actual, "values should match")
    assert.NoError(t, err, "operation should succeed")
}
```

## Test-Driven Development (TDD)

ALWAYS follow the TDD cycle:

1. **RED**: Write a failing test first - confirms it fails for the right reason
2. **GREEN**: Write minimal code to make the test pass
3. **REFACTOR**: Improve the code while keeping tests green

Testing Best Practices:
- Write table-driven tests for multiple scenarios
- Use subtests with `t.Run()` for better test organization
- Test both happy paths and error cases
- Use test helpers to reduce duplication
- Mock external dependencies using interfaces
- Prefer black-box testing (package_test) when possible

## Code Organization

### Hexagonal Architecture Structure (MANDATORY)

```
project/
├── cmd/                      # COMPOSITION ROOT: Wires all dependencies
│   └── myapp/
│       └── main.go           # Dependency injection, bootstrap
├── internal/
│   ├── domain/               # INNER LAYER: Pure business logic
│   │   ├── user.go           # Entities, value objects
│   │   └── errors.go         # Domain errors
│   ├── ports/                # INNER LAYER: Interfaces (contracts)
│   │   ├── repositories.go
│   │   └── services.go
│   ├── application/          # APPLICATION LAYER: Use cases
│   │   └── user_service.go   # Orchestrates domain logic
│   ├── adapters/             # OUTER LAYER: Infrastructure
│   │   ├── handlers/         # HTTP/gRPC handlers (primary/driving)
│   │   │   ├── http/
│   │   │   └── grpc/
│   │   └── repositories/     # Database implementations (secondary/driven)
│   │       ├── postgres/
│   │       └── redis/
│   └── config/               # Configuration loading
├── pkg/                      # PUBLIC PACKAGES: Reusable library code
├── .go-arch-lint.yml         # Architecture enforcement rules
├── .golangci.yml             # Linting rules
└── go.mod
```

### Dependency Rules (ENFORCED BY go-arch-lint)

```
adapters    -> ports       (adapters implement port interfaces)
application -> ports       (application uses port interfaces)
domain      -> (nothing)   (domain is pure, no dependencies)
ports       -> domain      (ports reference domain types)
pkg         -> (vendor)    (pkg only uses external libraries)
cmd         -> (all)       (cmd wires everything together)
```

Package Design Principles:
- Keep packages focused on a single responsibility
- Use `internal/` for code that shouldn't be imported by external projects
- Use `pkg/` for code that could be reused in other projects
- Package names are part of the API—choose them carefully
- Avoid circular dependencies between packages
- Domain layer MUST NOT import from adapters or external packages

## Interface Guidelines

- Accept interfaces, return concrete types (usually)
- Keep interfaces small (1-3 methods is ideal)
- Define interfaces where they're used, not where they're implemented
- Name single-method interfaces with "-er" suffix: `Reader`, `Writer`, `Uploader`
- NEVER add "Interface" suffix: use `UserRepository` not `UserRepositoryInterface`
- NEVER use "I" prefix: use `UserRepository` not `IUserRepository`
- Use embedding to compose larger interfaces from smaller ones

## Function Naming Conventions

### Core Principles

Keep function names simple and rely on package context:
- GOOD: `uploader.Upload()` - package name provides context
- BAD: `uploader.UploaderUpload()` - redundant

Package names are part of the description:
- In package `http`, use `Client` not `HTTPClient`
- In package `storage`, use `Save` not `StorageSave`
- In package `parser`, use `Parse` not `ParseJSON`

### Edge Cases and Features

Do NOT document edge cases or implementation details in function names:
- GOOD: `Upload()` - implementation details are hidden
- BAD: `UploadWithRetries()`, `UploadWithBackoff()`

Best practices (retries, backoffs, jitter, timeouts) are implicit. Use options or configuration to control behavior.

### Adding Features to Functions

Prefer wrapper functions with parameters over new function names:

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
- Packages: Short, concise, lowercase, single-word (avoid underscores)
- Exported: Start with uppercase letter (visible outside package)
- Unexported: Start with lowercase letter (private to package)
- Getters: Don't use "Get" prefix—use `Owner()` not `GetOwner()`
- Variables: Use short names in small scopes, longer names for broader scope

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

### Concurrency
- Share by communicating: Use channels instead of shared memory + locks
- Goroutines are cheap—use them liberally for concurrent tasks
- Use buffered channels as semaphores to limit concurrency
- Use `select` to multiplex channel operations
- Close channels when done to signal completion
- Use `sync.WaitGroup` to wait for goroutines to complete
- Use `context.Context` for cancellation and timeouts

## Development Workflow

### Before You Start Coding
1. Understand the requirement clearly
2. Identify which layer the code belongs to (domain/ports/application/adapters)
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
1. Run `task build` (must pass)
2. Run `task test` (must pass)
3. Run `task lint` (must pass)
4. Run `go-arch-lint check` (must pass, if config exists)
5. Review function names for simplicity
6. Check that interfaces are properly defined
7. Verify package organization follows hexagonal architecture
8. Ensure error handling is proper
9. Verify no emojis in code, comments, or documentation

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

### Table-Driven Tests (with testify)
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
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
            assert.Equal(t, tt.want, got)
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

### Running Checks
```bash
# Full validation (run before every commit)
task build
task test
task lint
go-arch-lint check

# Quick architecture visualization
go-arch-lint graph
```

### Handling Lint Errors (CRITICAL)

When you encounter a linting error:
1. Understand the WHY - Read the error message completely
2. Understand the CONSEQUENCE - What would happen if ignored?
3. Plan the FIX - What is the correct pattern to use?
4. Avoid common wrong fixes

Common Lint Errors and Correct Fixes:

| Error | WRONG Fix | CORRECT Fix |
|-------|-----------|-------------|
| `defer in loop` | Remove defer | Extract to helper function |
| `error ignored` | Add `_ = err` | Handle the error or wrap and return |
| `nil map write` | Remove the write | Initialize with `make(map[K]V)` |
| `context.TODO()` | Use `context.Background()` | Accept `context.Context` as first parameter |
| `GetX() naming` | Rename to `GetterX()` | Rename to `X()` (drop Get prefix) |
| `Interface suffix` | Rename to `IRepository` | Rename to `Repository` (drop suffix/prefix) |

## Contract Testing (NON-NEGOTIABLE for Ports)

Ports (interfaces) define contracts. Any implementation must handle edge cases identically. Contract tests enforce this.

```go
// internal/ports/card_repository_contract.go

// RunCardRepositoryContract tests any CardRepository implementation.
// All implementations (postgres, mock, in-memory) MUST pass these tests.
func RunCardRepositoryContract(t *testing.T, repo CardRepository, cleanup func()) {
    t.Helper()

    t.Run("Create_NilTags", func(t *testing.T) {
        if cleanup != nil {
            t.Cleanup(cleanup)
        }
        card := &domain.Card{
            ID:    uuid.New(),
            Tags:  nil,  // Edge case: nil not empty slice
            Front: "test",
            Back:  "test",
        }
        err := repo.Create(context.Background(), card)
        require.NoError(t, err, "nil tags must be handled")
    })

    t.Run("Create_NilCard", func(t *testing.T) {
        err := repo.Create(context.Background(), nil)
        require.ErrorIs(t, err, domain.ErrInvalidInput)
    })
}
```

Required Edge Cases for All Repository Contracts:

| Input | Required Behavior |
|-------|-------------------|
| `nil` slice fields | Treat as empty, never panic |
| `nil` entity pointer | Return `ErrInvalidInput` |
| Zero/nil UUID | Return `ErrInvalidInput` |
| Entity not found | Return typed error (`ErrCardNotFound`) |
| Duplicate key | Return typed error (`ErrDuplicateKey`) |
| Context cancelled | Return `ctx.Err()` or wrapped error |

## Quick Reference

| Task | Command |
|------|---------|
| Build | `task build` |
| Test | `task test` |
| Lint | `task lint` |
| Architecture check | `go-arch-lint check` |
| Architecture graph | `go-arch-lint graph` |

## Remember

Write tests first with testify, follow hexagonal architecture, keep domain pure, use interfaces for dependencies, use contract tests for ports, use Cobra/Viper for CLI entry points, ensure build/lint/arch-check/test always pass, and never use emojis.

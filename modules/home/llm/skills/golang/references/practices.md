# Go Practices Reference

You are an expert Go developer who follows Test-Driven Development (TDD) principles and Go best practices.

## Project Practices

Follow `golang` for current requirements and optional package recommendations.
Use the established CLI/test frameworks, command surface and pinned environment.
The examples below illustrate techniques; they do not mandate a package, Taskfile,
interface hierarchy or layout. Use focused checks while iterating, candidate-required
build/lint/test gates before review and planned integrated checks before delivery.

## Code Organization

Follow the project's established package organization and approved design. Do not
introduce mandatory layers or a fixed directory layout.

**Package Design Principles:**
- Keep packages focused on a single responsibility
- Use `internal/` for code that shouldn't be imported by external projects
- Use `pkg/` for code that could be reused in other projects
- Package names are part of the API—choose them carefully
- Avoid circular dependencies between packages

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
- NEVER add "Interface" suffix: use `UserRepository` not `UserRepositoryInterface`
- NEVER use "I" prefix: use `UserRepository` not `IUserRepository`
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
- **Interfaces**: Use agent nouns ending in "-er" for single-method interfaces; NEVER use "Interface" suffix or "I" prefix
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
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

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

### Cobra + Viper CLI Pattern
```go
// cmd/myapp/root.go
package main

import (
    "fmt"
    "os"

    "github.com/spf13/cobra"
    "github.com/spf13/viper"
)

var cfgFile string

var rootCmd = &cobra.Command{
    Use:   "myapp",
    Short: "My application description",
    PersistentPreRunE: func(cmd *cobra.Command, args []string) error {
        return initConfig()
    },
}

func init() {
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default $HOME/.myapp.yaml)")
    rootCmd.PersistentFlags().String("log-level", "info", "log level (debug, info, warn, error)")
    viper.BindPFlag("log-level", rootCmd.PersistentFlags().Lookup("log-level"))
}

func initConfig() error {
    if cfgFile != "" {
        viper.SetConfigFile(cfgFile)
    } else {
        home, err := os.UserHomeDir()
        if err != nil {
            return err
        }
        viper.AddConfigPath(home)
        viper.SetConfigName(".myapp")
    }
    viper.SetEnvPrefix("MYAPP")
    viper.AutomaticEnv()
    if err := viper.ReadInConfig(); err == nil {
        fmt.Fprintln(os.Stderr, "Using config file:", viper.ConfigFileUsed())
    }
    return nil
}

func main() {
    if err := rootCmd.Execute(); err != nil {
        os.Exit(1)
    }
}
```

## Linting

### Required Tools
```bash
# Install golangci-lint
go install github.com/golangci/golangci-lint/cmd/golangci-lint@latest
```

### Configuration Files
When the project chooses golangci-lint, use its approved configuration; for example:
- `.golangci.yml` - See [golangci.yml](golangci.yml)

### Running Checks
```bash
# Full validation (run before every commit)
task build
task test
task lint
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
| `Interface suffix` | Rename to `IRepository` | Rename to `Repository` (drop suffix/prefix) |
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
| Build | `task build` |
| Test | `task test` |
| Lint | `task lint` |

## Portable Cloud Components (Go Cloud SDK)

Follow [Go Cloud SDK](https://gocloud.dev/) patterns for cloud-agnostic, reusable components:

- **URL-based construction**: `blob.OpenBucket(ctx, "s3://bucket")` or `"file:///tmp/local"`
- **Portable interfaces**: Define interfaces that work across AWS, GCP, Azure, and local
- **Local development**: Always support file/memory backends for testing
- **Configuration-driven**: Provider selected by URL at runtime, not compile time

```go
// Application code is provider-agnostic
func NewService(ctx context.Context, storageURL string) (*Service, error) {
    bucket, err := blob.OpenBucket(ctx, storageURL)
    if err != nil {
        return nil, err
    }
    return &Service{storage: bucket}, nil
}
```

## Contract Testing Where Consistency Matters

Use shared contract suites for actual consistency promises across implementations
or substitutes. Ordinary tests can already prove behavior for one implementation;
do not require a separate suite or invent interfaces just to satisfy a pattern.

Cover invalid input, nil and empty collections, missing records, duplicate keys,
context cancellation, and cleanup as applicable. Assert observable outcomes and
errors, not incidental implementation details. Follow the project's existing
package organization; contract tests do not require separate interface, service,
or persistence packages.

See [contract-testing.md](contract-testing.md).

## Input Invariants via Types (RECOMMENDED)

Use types and constructors to express validated input, meaningful identifiers, and
numeric constraints where they improve correctness. Keep zero-value behavior,
ownership, and runtime validation explicit; constructors do not prevent callers
from creating zero values. Do not introduce a separate package or mapping structure
solely to hold these types.

## Additional Resources

- Architecture patterns: [architecture.md](architecture.md)
- TDD workflow: [tdd-workflow.md](tdd-workflow.md)
- Code patterns: [code-patterns.md](code-patterns.md)
- API resilience (retries, backoff, jitter, rate limiting): [api-resilience.md](api-resilience.md)
- BDD/Gherkin specifications: [bdd-gherkin.md](bdd-gherkin.md)
- Protobuf guidelines: [protobuf.md](protobuf.md)
- Go Cloud SDK patterns: [go-cloud-sdk.md](go-cloud-sdk.md)
- AI code problems: [ai-code-problems.md](ai-code-problems.md)
- golangci-lint config: [golangci.yml](golangci.yml)
- Contract testing: [contract-testing.md](contract-testing.md)

---

**Remember**: Write tests first with testify, follow the project's approved design, use interfaces where needed, use contract tests for dependency interfaces, use value objects for invariants, use Cobra/Viper for CLI entry points, use Go Cloud SDK for portable cloud components, ensure build/lint/test always pass, and never use emojis!

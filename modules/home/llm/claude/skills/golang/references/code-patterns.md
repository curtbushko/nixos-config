# Go Code Patterns

Essential Go idioms and patterns for production code.

## Error Handling

### Wrap Errors with Context

```go
// GOOD: Error wrapped with context
if err != nil {
    return fmt.Errorf("fetch user %s: %w", userID, err)
}

// BAD: Bare error return
if err != nil {
    return err  // No context about what failed
}
```

### Check Wrapped Errors

```go
// Check for specific error type
var notFoundErr *NotFoundError
if errors.As(err, &notFoundErr) {
    // Handle not found
}

// Check for sentinel error
if errors.Is(err, domain.ErrUserNotFound) {
    // Handle not found
}
```

### Handle ONCE - Log OR Return

```go
// GOOD: Return with context
if err != nil {
    return fmt.Errorf("save user: %w", err)
}

// BAD: Log AND return (double handling)
if err != nil {
    log.Printf("error saving user: %v", err)
    return err  // Will be logged again upstream
}
```

---

## Interface Design

### Define Where Used

```go
// GOOD: Interface defined in consumer package
// internal/application/user_service.go
type UserRepository interface {
    FindByID(ctx context.Context, id string) (*domain.User, error)
    Save(ctx context.Context, user *domain.User) error
}

type userService struct {
    repo UserRepository
}

// BAD: Interface defined with implementation
// internal/adapters/repositories/postgres/user_repo.go
type UserRepository interface {  // Wrong place!
    // ...
}

type postgresUserRepo struct {
    // ...
}
```

### Keep Interfaces Small

```go
// GOOD: Small, focused interface
type UserReader interface {
    FindByID(ctx context.Context, id string) (*User, error)
}

type UserWriter interface {
    Save(ctx context.Context, user *User) error
}

// Compose when needed
type UserRepository interface {
    UserReader
    UserWriter
}

// BAD: God interface
type Repository interface {
    FindUserByID(ctx context.Context, id string) (*User, error)
    FindUserByEmail(ctx context.Context, email string) (*User, error)
    SaveUser(ctx context.Context, user *User) error
    DeleteUser(ctx context.Context, id string) error
    ListUsers(ctx context.Context) ([]*User, error)
    FindProductByID(ctx context.Context, id string) (*Product, error)
    // ... 20 more methods
}
```

### Return Concrete Types

```go
// GOOD: Return concrete type
func NewUserService(repo UserRepository) *userService {
    return &userService{repo: repo}
}

// BAD: Return interface
func NewUserService(repo UserRepository) UserService {
    return &userService{repo: repo}
}
```

---

## io.Reader / io.Writer

The most important interfaces in Go. Accept them to maximize composability.

```go
// GOOD: Accept io.Reader for maximum flexibility
func ProcessData(r io.Reader) ([]byte, error) {
    return io.ReadAll(r)
}

// Works with files
f, _ := os.Open("data.txt")
ProcessData(f)

// Works with buffers
var buf bytes.Buffer
ProcessData(&buf)

// Works with HTTP bodies
ProcessData(resp.Body)

// Works with compressed data
gz, _ := gzip.NewReader(file)
ProcessData(gz)
```

### Composition via Wrapping

```go
// Decorator pattern - add behavior by wrapping
type CountingReader struct {
    io.Reader
    BytesRead int64
}

func (cr *CountingReader) Read(p []byte) (int, error) {
    n, err := cr.Reader.Read(p)
    cr.BytesRead += int64(n)
    return n, err
}

// Usage: layer behaviors
raw, _ := os.Open("data.gz")
counted := &CountingReader{Reader: raw}
buffered := bufio.NewReader(counted)
gz, _ := gzip.NewReader(buffered)
```

---

## Option Pattern

For configurable functions:

```go
type Config struct {
    Timeout     time.Duration
    Retries     int
    MaxBodySize int64
}

var DefaultConfig = Config{
    Timeout:     30 * time.Second,
    Retries:     3,
    MaxBodySize: 1 << 20, // 1MB
}

type Option func(*Config)

func WithTimeout(d time.Duration) Option {
    return func(c *Config) {
        c.Timeout = d
    }
}

func WithRetries(n int) Option {
    return func(c *Config) {
        c.Retries = n
    }
}

func NewClient(opts ...Option) *Client {
    cfg := DefaultConfig
    for _, opt := range opts {
        opt(&cfg)
    }
    return &Client{config: cfg}
}

// Usage
client := NewClient(
    WithTimeout(10 * time.Second),
    WithRetries(5),
)
```

---

## Concurrency Patterns

### Context for Cancellation

```go
func Worker(ctx context.Context) error {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()

    for {
        select {
        case <-ctx.Done():
            return ctx.Err()
        case <-ticker.C:
            if err := doWork(); err != nil {
                return err
            }
        }
    }
}
```

### WaitGroup with Defer

```go
func ProcessConcurrently(items []Item) error {
    var wg sync.WaitGroup
    errCh := make(chan error, len(items))

    for _, item := range items {
        wg.Add(1)
        go func(item Item) {
            defer wg.Done()  // Always defer immediately
            if err := process(item); err != nil {
                errCh <- err
            }
        }(item)
    }

    wg.Wait()
    close(errCh)

    for err := range errCh {
        if err != nil {
            return err
        }
    }
    return nil
}
```

### Semaphore for Limiting Concurrency

```go
func ProcessWithLimit(items []Item, maxWorkers int) error {
    sem := make(chan struct{}, maxWorkers)
    var wg sync.WaitGroup

    for _, item := range items {
        sem <- struct{}{}  // Acquire
        wg.Add(1)
        go func(item Item) {
            defer func() {
                <-sem  // Release
                wg.Done()
            }()
            process(item)
        }(item)
    }

    wg.Wait()
    return nil
}
```

---

## Resource Management

### Defer for Cleanup

```go
func ReadFile(path string) ([]byte, error) {
    f, err := os.Open(path)
    if err != nil {
        return nil, err
    }
    defer f.Close()

    return io.ReadAll(f)
}
```

### Avoid Defer in Loops

```go
// BAD: Defer accumulates until function returns
for _, path := range paths {
    f, _ := os.Open(path)
    defer f.Close()  // Won't close until function ends!
    process(f)
}

// GOOD: Extract to helper function
for _, path := range paths {
    if err := processFile(path); err != nil {
        return err
    }
}

func processFile(path string) error {
    f, err := os.Open(path)
    if err != nil {
        return err
    }
    defer f.Close()  // Closes after each file
    return process(f)
}
```

---

## Testing Patterns

**All tests MUST use [testify](https://github.com/stretchr/testify):**
- `require` for fatal assertions (stops test on failure)
- `assert` for non-fatal assertions (continues test)
- **Exception**: Kubernetes e2e tests may use k8s e2e framework

### Table-Driven Tests (with testify)

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid", "user@example.com", false},
        {"empty", "", true},
        {"no domain", "user@", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr {
                require.Error(t, err)
                return
            }
            require.NoError(t, err)
        })
    }
}
```

### Test Helpers

```go
func setupTestDB(t *testing.T) (*sql.DB, func()) {
    t.Helper()

    db, err := sql.Open("postgres", testDSN)
    if err != nil {
        t.Fatalf("open database: %v", err)
    }

    cleanup := func() {
        db.Close()
    }

    return db, cleanup
}

func TestRepository(t *testing.T) {
    db, cleanup := setupTestDB(t)
    defer cleanup()

    // ... tests
}
```

---

## Common Lint Fixes

| Error | Wrong Fix | Correct Fix |
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

## Naming Conventions

### Packages

- Short, lowercase, single-word
- Avoid generic names like `util`, `common`, `helper`

### Functions

- Unexported functions: `camelCase`
- Exported functions: `PascalCase`
- Getters: `X()` not `GetX()`
- Setters: `SetX()`

### Variables

- Short names in small scopes: `i`, `n`, `err`
- Longer names for broader scope: `userCount`, `errorMessage`

### Interfaces

- Single-method: `-er` suffix (`Reader`, `Writer`, `Closer`)
- Multiple methods: Descriptive name (`UserRepository`)

---

## CLI Framework (Cobra + Viper)

**All service CLI entry points MUST use Cobra and Viper.**

### Root Command Pattern

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
    rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file")
    rootCmd.PersistentFlags().String("log-level", "info", "log level")
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

### Subcommand Pattern

```go
// cmd/myapp/serve.go
package main

import (
    "github.com/spf13/cobra"
    "github.com/spf13/viper"
)

var serveCmd = &cobra.Command{
    Use:   "serve",
    Short: "Start the server",
    RunE: func(cmd *cobra.Command, args []string) error {
        port := viper.GetInt("port")
        return startServer(port)
    },
}

func init() {
    serveCmd.Flags().Int("port", 8080, "server port")
    viper.BindPFlag("port", serveCmd.Flags().Lookup("port"))
    rootCmd.AddCommand(serveCmd)
}
```

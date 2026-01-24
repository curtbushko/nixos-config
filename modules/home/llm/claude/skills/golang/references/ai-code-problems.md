# AI-Generated Go Code: Common Problems and Enforcement

This document catalogs common mistakes AI/LLMs make when generating Go code and provides enforcement strategies through linters, scripts, and custom rules.

## Executive Summary

AI code generators (ChatGPT, Copilot, Claude, etc.) consistently make predictable mistakes in Go code. These fall into several categories:

| Category | Severity | Detection | Enforcement |
|----------|----------|-----------|-------------|
| Error Handling | Critical | errcheck, errorlint | golangci-lint |
| Nil Safety | Critical | nilaway, staticcheck | golangci-lint |
| Resource Leaks | Critical | bodyclose, rowserrcheck | golangci-lint |
| Concurrency | Critical | govet, staticcheck | golangci-lint + tests |
| Context Misuse | High | noctx, contextcheck | golangci-lint |
| Type Assertions | High | errcheck, govet | golangci-lint |
| Defer Mistakes | High | Custom analyzer needed | Custom linter |
| Architecture | Medium | go-arch-lint | Pre-commit hook |

## Common AI Code Generation Problems

### 1. Error Handling Issues (Critical)

**Problem**: AI frequently generates code that ignores errors or handles them incorrectly.

```go
// BAD: AI often generates this
file, _ := os.Open(filename)  // Error ignored!

// BAD: Handling error twice (logging AND returning)
if err != nil {
    log.Printf("error: %v", err)  // Logged here
    return err                      // And returned - will be logged again upstream
}

// BAD: Not wrapping errors with context
if err != nil {
    return err  // No context about what operation failed
}
```

**Enforcement**:
- `errcheck` - Detects ignored errors
- `errorlint` - Detects improper error wrapping (Go 1.13+)
- `wrapcheck` - Ensures errors from external packages are wrapped
- `nilerr` - Detects returning nil when err is not nil

**golangci-lint config**:
```yaml
linters:
  enable:
    - errcheck
    - errorlint
    - wrapcheck
    - nilerr

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true
```

---

### 2. Nil Pointer Dereferences (Critical)

**Problem**: AI generates code that can panic due to nil pointer access.

```go
// BAD: AI often forgets nil checks
func ProcessUser(u *User) string {
    return u.Name  // Panics if u is nil
}

// BAD: Checking nil but not returning
func GetValue(m map[string]*Item, key string) *Item {
    item := m[key]
    if item == nil {
        log.Println("item not found")
        // Missing return! Falls through and may cause issues
    }
    return item
}
```

**Enforcement**:
- `nilaway` (Uber) - Interprocedural nil analysis
- `staticcheck SA5011` - Nil pointer dereference detection
- GoLand IDE - Built-in interprocedural analysis

**golangci-lint config**:
```yaml
linters:
  enable:
    - staticcheck
    - govet

linters-settings:
  staticcheck:
    checks: ["all"]
```

---

### 3. Resource Leaks (Critical)

**Problem**: AI forgets to close resources or closes them incorrectly.

```go
// BAD: HTTP response body not closed
resp, err := http.Get(url)
if err != nil {
    return err
}
// Missing: defer resp.Body.Close()
body, _ := io.ReadAll(resp.Body)

// BAD: Defer in loop (resources stay open until function returns)
for _, filename := range files {
    f, _ := os.Open(filename)
    defer f.Close()  // Won't close until loop finishes!
    // Process file...
}

// BAD: File opened but error check closes wrong file
f, err := os.Open(filename)
if err != nil {
    f.Close()  // f might be nil here!
    return err
}
```

**Enforcement**:
- `bodyclose` - Checks HTTP response body is closed
- `rowserrcheck` - Checks sql.Rows error is checked
- `sqlclosecheck` - Checks sql.Rows and sql.Stmt are closed
- Custom analyzer for defer-in-loop pattern

**golangci-lint config**:
```yaml
linters:
  enable:
    - bodyclose
    - rowserrcheck
    - sqlclosecheck
```

---

### 4. Concurrency Issues (Critical)

**Problem**: AI generates racy code, leaks goroutines, or misuses synchronization.

```go
// BAD: Loop variable capture (fixed in Go 1.22+, but AI may generate old patterns)
for _, item := range items {
    go func() {
        process(item)  // All goroutines see same item!
    }()
}

// BAD: Goroutine without cancellation mechanism
func StartWorker() {
    go func() {
        for {
            doWork()  // Runs forever, no way to stop
        }
    }()
}

// BAD: Race condition with shared variable
var counter int
for i := 0; i < 10; i++ {
    go func() {
        counter++  // Data race!
    }()
}

// BAD: Copying sync types
var mu sync.Mutex
mu2 := mu  // Copies the mutex - undefined behavior!
```

**Enforcement**:
- `go test -race` - Runtime race detector (MUST be enabled)
- `govet` - Detects copying of sync types
- `staticcheck` - Various concurrency checks
- `goleak` (Uber) - Goroutine leak detection in tests

**golangci-lint config**:
```yaml
linters:
  enable:
    - govet
    - staticcheck

linters-settings:
  govet:
    enable-all: true
```

**Test enforcement**:
```go
import "go.uber.org/goleak"

func TestMain(m *testing.M) {
    goleak.VerifyTestMain(m)
}
```

---

### 5. Context Misuse (High)

**Problem**: AI uses context.Background() everywhere or forgets to propagate context.

```go
// BAD: Using Background when context should be propagated
func HandleRequest(w http.ResponseWriter, r *http.Request) {
    result := doWork(context.Background())  // Should use r.Context()
}

// BAD: context.TODO() left in production code
func Process() error {
    ctx := context.TODO()  // Should be replaced before shipping
    return db.QueryContext(ctx, "SELECT ...")
}

// BAD: HTTP request without context
resp, err := http.Get(url)  // No timeout, no cancellation!
```

**Enforcement**:
- `noctx` - Detects HTTP requests without context
- `contextcheck` - Checks context propagation
- Custom rule to flag context.TODO() in non-test code

**golangci-lint config**:
```yaml
linters:
  enable:
    - noctx
    - contextcheck
```

---

### 6. Unsafe Type Assertions (High)

**Problem**: AI uses type assertions without checking for failure.

```go
// BAD: Unsafe type assertion - panics if wrong type
func ProcessValue(v interface{}) {
    s := v.(string)  // Panic if v is not a string!
    fmt.Println(s)
}

// GOOD: Safe type assertion with check
func ProcessValue(v interface{}) {
    s, ok := v.(string)
    if !ok {
        return // Handle gracefully
    }
    fmt.Println(s)
}
```

**Enforcement**:
- `errcheck` with `check-type-assertions: true`
- `govet` - Detects impossible type assertions
- `forcetypeassert` - Requires comma-ok form

**golangci-lint config**:
```yaml
linters:
  enable:
    - errcheck
    - forcetypeassert

linters-settings:
  errcheck:
    check-type-assertions: true
```

---

### 7. Defer Mistakes (High)

**Problem**: AI misunderstands defer evaluation and scope.

```go
// BAD: Defer argument evaluated immediately
func LogDuration(start time.Time) {
    defer log.Printf("took %v", time.Since(start))  // time.Since evaluated NOW
}

// GOOD: Wrap in closure
func LogDuration(start time.Time) {
    defer func() {
        log.Printf("took %v", time.Since(start))  // Evaluated when defer runs
    }()
}

// BAD: Ignoring error from deferred Close
func WriteFile(filename string, data []byte) error {
    f, err := os.Create(filename)
    if err != nil {
        return err
    }
    defer f.Close()  // Error from Close is ignored!

    _, err = f.Write(data)
    return err
}
```

**Enforcement**:
- Custom analyzer needed (see below)
- `revive` has some defer checks

---

### 8. Slice/Map Issues (Medium)

**Problem**: AI misunderstands slice behavior and map semantics.

```go
// BAD: Modifying slice during iteration
for i, v := range slice {
    if shouldRemove(v) {
        slice = append(slice[:i], slice[i+1:]...)  // Corrupts iteration
    }
}

// BAD: Nil map assignment (panic)
var m map[string]int
m["key"] = 1  // Panic! Map is nil

// BAD: Slice append side effects
a := []int{1, 2, 3}
b := a[:2]
b = append(b, 4)  // Modifies a[2] if cap allows!
```

**Enforcement**:
- `staticcheck` - Some slice/map checks
- `makezero` - Checks for non-zero length slice initialization
- `prealloc` - Suggests slice preallocation

---

### 9. String Handling (Medium)

**Problem**: AI doesn't understand runes vs bytes.

```go
// BAD: Iterating bytes instead of runes
for i := 0; i < len(s); i++ {
    fmt.Printf("%c", s[i])  // Breaks on multi-byte UTF-8
}

// BAD: Inefficient string concatenation
var result string
for _, s := range strings {
    result += s  // O(n^2) - creates new string each time
}

// GOOD: Use strings.Builder
var builder strings.Builder
for _, s := range strings {
    builder.WriteString(s)
}
result := builder.String()
```

**Enforcement**:
- `gocritic` - Detects inefficient patterns
- `perfsprint` - Suggests faster alternatives to fmt.Sprint

---

### 10. Interface Pollution (Medium)

**Problem**: AI creates large interfaces instead of small, focused ones.

```go
// BAD: AI creates "god interfaces"
type Repository interface {
    Create(item Item) error
    Read(id string) (Item, error)
    Update(item Item) error
    Delete(id string) error
    List() ([]Item, error)
    Search(query string) ([]Item, error)
    // ... 20 more methods
}

// GOOD: Small, focused interfaces
type Reader interface {
    Read(id string) (Item, error)
}

type Writer interface {
    Write(item Item) error
}
```

**Enforcement**:
- `interfacebloat` - Checks interface method count
- `ireturn` - Warns against returning interfaces

**golangci-lint config**:
```yaml
linters:
  enable:
    - interfacebloat
    - ireturn

linters-settings:
  interfacebloat:
    max: 5
```

---

## Comprehensive Linter Configuration

Based on this research, here is an enhanced `.golangci.yml` that catches AI-generated code issues:

```yaml
version: "2"

run:
  timeout: 5m
  modules-download-mode: readonly

linters:
  enable:
    # Error Handling (AI Problem #1)
    - errcheck
    - errorlint
    - wrapcheck
    - nilerr

    # Nil Safety (AI Problem #2)
    - staticcheck
    - govet

    # Resource Leaks (AI Problem #3)
    - bodyclose
    - rowserrcheck
    - sqlclosecheck

    # Concurrency (AI Problem #4)
    # govet and staticcheck cover this

    # Context (AI Problem #5)
    - noctx
    - contextcheck

    # Type Assertions (AI Problem #6)
    - forcetypeassert

    # Code Quality
    - gocritic
    - revive
    - ineffassign
    - unused
    - unconvert
    - unparam

    # Performance
    - prealloc
    - makezero
    - perfsprint

    # Interfaces (AI Problem #10)
    - interfacebloat
    - ireturn

    # Security
    - gosec

linters-settings:
  errcheck:
    check-type-assertions: true
    check-blank: true

  staticcheck:
    checks: ["all"]

  govet:
    enable-all: true

  interfacebloat:
    max: 5

  gocritic:
    enabled-tags:
      - diagnostic
      - performance
      - style
    disabled-checks:
      - hugeParam  # Can be too strict

  revive:
    rules:
      - name: blank-imports
      - name: context-as-argument
      - name: context-keys-type
      - name: defer
      - name: error-return
      - name: error-strings
      - name: error-naming
      - name: exported
      - name: if-return
      - name: increment-decrement
      - name: var-naming
      - name: var-declaration
      - name: range
      - name: receiver-naming
      - name: time-naming
      - name: unexported-return
      - name: indent-error-flow
      - name: errorf
      - name: empty-block
      - name: superfluous-else
      - name: unused-parameter
      - name: unreachable-code
      - name: redefines-builtin-id

issues:
  exclude-rules:
    - path: _test\.go
      linters:
        - errcheck
        - wrapcheck
        - forcetypeassert
```

---

## Custom Linter Recommendations

Some AI problems need custom analyzers. Consider creating:

### 1. `deferlint` - Defer Pattern Analyzer

Detects:
- Defer inside loops
- Ignored errors from deferred Close()
- Arguments evaluated at defer time issues

### 2. `contextlint` - Context Usage Analyzer

Detects:
- `context.TODO()` in non-test code
- `context.Background()` where context should be propagated
- Missing context in HTTP handlers

### 3. `goroutinelint` - Goroutine Lifecycle Analyzer

Detects:
- Goroutines without cancellation mechanism
- Infinite loops in goroutines without context
- Missing WaitGroup usage

---

## Creating Custom Analyzers

Use the `go/analysis` framework:

```go
package deferlint

import (
    "go/ast"
    "golang.org/x/tools/go/analysis"
    "golang.org/x/tools/go/analysis/passes/inspect"
    "golang.org/x/tools/go/ast/inspector"
)

var Analyzer = &analysis.Analyzer{
    Name:     "deferlint",
    Doc:      "checks for common defer mistakes",
    Run:      run,
    Requires: []*analysis.Analyzer{inspect.Analyzer},
}

func run(pass *analysis.Pass) (interface{}, error) {
    inspect := pass.ResultOf[inspect.Analyzer].(*inspector.Inspector)

    nodeFilter := []ast.Node{
        (*ast.ForStmt)(nil),
        (*ast.RangeStmt)(nil),
    }

    inspect.Preorder(nodeFilter, func(n ast.Node) {
        // Check for defer inside loops
        ast.Inspect(n, func(node ast.Node) bool {
            if deferStmt, ok := node.(*ast.DeferStmt); ok {
                pass.Reportf(deferStmt.Pos(),
                    "defer inside loop - resources won't be released until function returns")
            }
            return true
        })
    })

    return nil, nil
}
```

---

## Enforcement Strategy

### 1. Pre-commit Hook
```bash
#!/usr/bin/env bash
set -euo pipefail

echo "Running Go quality checks..."

# Build
go build ./...

# Test with race detector
go test -race ./...

# Lint
golangci-lint run

# Architecture
if [[ -f .go-arch-lint.yml ]]; then
    go-arch-lint check
fi

echo "All checks passed!"
```

### 2. CI Pipeline
```yaml
# .github/workflows/go.yml
jobs:
  lint:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: actions/setup-go@v5
        with:
          go-version: '1.22'
      - name: golangci-lint
        uses: golangci/golangci-lint-action@v4
        with:
          version: latest
          args: --timeout=5m
```

### 3. Claude Code Hook
Configure in settings to run lint checks after code generation (already configured in your setup).

---

---

## AI-Friendly Diagnostic Templates

When fixing linting errors, use these templates to understand the correct fix:

### Defer in Loop (AIL001)

**Problem**: `defer inside loop delays resource cleanup`

**Why it matters**: Deferred calls accumulate until function returns. Processing 1000 files keeps 1000 handles open.

**WRONG fixes**:
- Removing defer (resource never closed on panic/early return)
- Moving defer outside loop (only closes last resource)
- Manual Close() without defer (skipped on panic)

**CORRECT fix**: Extract loop body to helper function
```go
// Before (wrong)
for _, f := range files {
    file, _ := os.Open(f)
    defer file.Close()
}

// After (correct)
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
    defer file.Close()
    // ... process
    return nil
}
```

---

### Error Ignored (errcheck)

**Problem**: `error return value not checked`

**Why it matters**: Silently failing operations cause data loss, corrupted state, or mysterious bugs later.

**WRONG fixes**:
- Adding `_ = err` (still ignores the error)
- Deleting the line (removes functionality)

**CORRECT fix**: Handle the error appropriately
```go
// Before (wrong)
file, _ := os.Open(path)
json.Unmarshal(data, &config)

// After (correct)
file, err := os.Open(path)
if err != nil {
    return fmt.Errorf("open config: %w", err)
}

if err := json.Unmarshal(data, &config); err != nil {
    return fmt.Errorf("parse config: %w", err)
}
```

---

### Nil Map Write (staticcheck)

**Problem**: `assignment to nil map`

**Why it matters**: Writing to nil map causes panic at runtime.

**WRONG fixes**:
- Removing the write (loses functionality)
- Adding nil check without init (still can't write)

**CORRECT fix**: Initialize the map
```go
// Before (wrong - panics)
var m map[string]int
m["key"] = 1

// After (correct)
m := make(map[string]int)
m["key"] = 1

// Or with struct
type Config struct {
    Settings map[string]string
}

func NewConfig() *Config {
    return &Config{
        Settings: make(map[string]string),
    }
}
```

---

### Context.TODO() in Production (AIL010)

**Problem**: `context.TODO() in non-test code`

**Why it matters**: TODO indicates incomplete code. Production needs proper context for cancellation/timeouts.

**WRONG fixes**:
- Replace with `context.Background()` everywhere (loses cancellation)
- Remove context entirely (breaks context propagation)

**CORRECT fix**: Accept context as parameter
```go
// Before (wrong)
func FetchData() (*Data, error) {
    ctx := context.TODO()
    return db.QueryContext(ctx, "SELECT ...")
}

// After (correct)
func FetchData(ctx context.Context) (*Data, error) {
    return db.QueryContext(ctx, "SELECT ...")
}

// Caller provides context
func HandleRequest(w http.ResponseWriter, r *http.Request) {
    data, err := FetchData(r.Context())
    // ...
}
```

---

### Goroutine Without Cancellation (AIL020)

**Problem**: `goroutine has no cancellation mechanism`

**Why it matters**: Goroutine runs forever, leaking resources. Cannot gracefully shutdown.

**WRONG fixes**:
- Adding a `return` statement (only exits once)
- Using a boolean flag (race condition)

**CORRECT fix**: Use context with Done() channel
```go
// Before (wrong - runs forever)
go func() {
    for {
        doWork()
        time.Sleep(time.Second)
    }
}()

// After (correct)
go func(ctx context.Context) {
    ticker := time.NewTicker(time.Second)
    defer ticker.Stop()
    for {
        select {
        case <-ctx.Done():
            return
        case <-ticker.C:
            doWork()
        }
    }
}(ctx)
```

---

### WaitGroup.Done() Not Deferred (AIL080)

**Problem**: `wg.Done() should be deferred`

**Why it matters**: If goroutine panics or returns early, Done() never called, Wait() blocks forever.

**WRONG fixes**:
- Removing wg.Done() (Wait blocks forever)
- Adding multiple Done() calls (counter goes negative, panic)

**CORRECT fix**: Defer Done() immediately after Add()
```go
// Before (wrong)
wg.Add(1)
go func() {
    result := process()
    if result == nil {
        return  // Done() never called!
    }
    save(result)
    wg.Done()
}()

// After (correct)
wg.Add(1)
go func() {
    defer wg.Done()  // Always called, even on panic
    result := process()
    if result == nil {
        return
    }
    save(result)
}()
```

---

### String Concatenation in Loop (AIL071)

**Problem**: `string concatenation in loop has O(n²) complexity`

**Why it matters**: Each `+=` creates new string, copying all previous content. 1000 iterations = ~500,000 copies.

**WRONG fixes**:
- Using `fmt.Sprintf` (still allocates each iteration)
- Pre-allocating string (strings are immutable)

**CORRECT fix**: Use strings.Builder
```go
// Before (wrong - O(n²))
var result string
for _, s := range items {
    result += s
}

// After (correct - O(n))
var b strings.Builder
for _, s := range items {
    b.WriteString(s)
}
result := b.String()

// Or with known size
var b strings.Builder
b.Grow(totalLen)  // Pre-allocate
for _, s := range items {
    b.WriteString(s)
}
```

---

### GetX() Naming (AIL050)

**Problem**: `getter should not have Get prefix`

**Why it matters**: Go convention is `X()` not `GetX()`. Setters use `SetX()`.

**WRONG fixes**:
- Renaming to `GetterX()` or `FetchX()`
- Keeping Get but making unexported

**CORRECT fix**: Remove Get prefix
```go
// Before (wrong)
func (u *User) GetName() string { return u.name }
func (u *User) GetEmail() string { return u.email }

// After (correct)
func (u *User) Name() string { return u.name }
func (u *User) Email() string { return u.email }

// Setters DO use Set prefix
func (u *User) SetName(name string) { u.name = name }
```

---

## Sources

- [100 Go Mistakes and How to Avoid Them](https://100go.co/)
- [NilAway: Practical Nil Panic Detection](https://www.uber.com/blog/nilaway-practical-nil-panic-detection-for-go/)
- [golangci-lint Documentation](https://golangci-lint.run/)
- [go-critic Checks Overview](https://go-critic.com/overview.html)
- [revive Linter Rules](https://revive.run/r/)
- [Creating Custom Go Analyzers](https://pkg.go.dev/golang.org/x/tools/go/analysis)
- [A Survey of Bugs in AI-Generated Code](https://arxiv.org/abs/2512.05239)
- [AI Coding Tools for Go in 2025](https://skoredin.pro/blog/golang/ai-coding-tools-go-2025)

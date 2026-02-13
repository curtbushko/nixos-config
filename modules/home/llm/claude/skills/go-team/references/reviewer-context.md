# Go Reviewer Context Injection

This context is injected into every Go Reviewer agent dispatch.

---

## Lint Verification

Before approving, confirm lint passes. Run whichever applies:
```bash
make lint            # if Makefile exists
task lint            # if Taskfile exists (fallback if no Makefile)
```

---

## Review Priority Order

```
CRITICAL (must fix before merge):
├── Error handling (#48-54)
├── Concurrency races (#58, 69, 70, 74)
├── Resource leaks (#26, 28, 35, 76, 79)
└── Nil pointer dereferences

MAJOR (should fix):
├── Architecture violations
├── Interface design (#5-7)
├── Testing quality (#83, 86)
└── Context misuse

MINOR (consider):
├── Naming conventions
├── Performance optimization
└── Code organization
```

---

## AI-Generated Code Problems (MUST CHECK)

AI code generators consistently make these mistakes. Check explicitly:

### 1. Error Handling Issues (Critical)

```go
// AI MISTAKE: Error ignored
file, _ := os.Open(filename)  // ERROR!

// AI MISTAKE: Handling error twice
if err != nil {
    log.Printf("error: %v", err)  // Logged
    return err                      // And returned - double handling!
}

// AI MISTAKE: Not wrapping errors
if err != nil {
    return err  // No context!
}
```

**Check for:**
- `_ = err` or `_, _ =` patterns
- Both logging AND returning errors
- Bare `return err` without `fmt.Errorf`

### 2. Nil Pointer Dereferences (Critical)

```go
// AI MISTAKE: No nil check
func ProcessUser(u *User) string {
    return u.Name  // Panics if u is nil!
}

// AI MISTAKE: Check but don't return
item := m[key]
if item == nil {
    log.Println("not found")
    // Missing return! Falls through
}
return item
```

**Check for:**
- Pointer parameters used without nil check
- Map lookups without comma-ok idiom
- Missing returns after nil checks

### 3. Resource Leaks (Critical)

```go
// AI MISTAKE: Body not closed
resp, err := http.Get(url)
if err != nil {
    return err
}
// Missing: defer resp.Body.Close()
body, _ := io.ReadAll(resp.Body)

// AI MISTAKE: Defer in loop
for _, filename := range files {
    f, _ := os.Open(filename)
    defer f.Close()  // Won't close until function returns!
}
```

**Check for:**
- HTTP responses without `defer resp.Body.Close()`
- Files, database connections, rows without defer Close
- `defer` inside `for` loops

### 4. Concurrency Issues (Critical)

```go
// AI MISTAKE: Loop variable capture (pre-Go 1.22)
for _, item := range items {
    go func() {
        process(item)  // All see same item!
    }()
}

// AI MISTAKE: No cancellation mechanism
go func() {
    for {
        doWork()  // Runs forever!
    }
}()

// AI MISTAKE: Data race
var counter int
for i := 0; i < 10; i++ {
    go func() {
        counter++  // DATA RACE!
    }()
}

// AI MISTAKE: Copying sync types
var mu sync.Mutex
mu2 := mu  // Undefined behavior!
```

**Check for:**
- Goroutines without context cancellation
- Shared variables without mutex/channels
- Copying of sync.Mutex, sync.WaitGroup, etc.
- WaitGroup.Done() not deferred

### 5. Context Misuse (High)

```go
// AI MISTAKE: Background when should propagate
func HandleRequest(w http.ResponseWriter, r *http.Request) {
    result := doWork(context.Background())  // Should use r.Context()!
}

// AI MISTAKE: TODO in production
ctx := context.TODO()  // Incomplete code!

// AI MISTAKE: HTTP without context
resp, err := http.Get(url)  // No timeout, no cancellation!
```

**Check for:**
- `context.Background()` in handlers (should use r.Context())
- `context.TODO()` in non-test code
- HTTP requests without context

### 6. Unsafe Type Assertions (High)

```go
// AI MISTAKE: Panics on wrong type
s := v.(string)  // Panic if not string!

// CORRECT: Safe assertion
s, ok := v.(string)
if !ok {
    return // Handle gracefully
}
```

**Check for:**
- Type assertions without comma-ok: `v.(Type)`
- Should be: `v, ok := v.(Type)`

### 7. Defer Mistakes (High)

```go
// AI MISTAKE: Args evaluated immediately
defer log.Printf("took %v", time.Since(start))  // Evaluated NOW!

// CORRECT: Wrap in closure
defer func() {
    log.Printf("took %v", time.Since(start))
}()

// AI MISTAKE: Error from Close ignored
defer f.Close()  // Error lost!

// CORRECT: Capture error
defer func() {
    if err := f.Close(); err != nil {
        // Handle
    }
}()
```

### 8. Slice/Map Issues (Medium)

```go
// AI MISTAKE: Nil map write
var m map[string]int
m["key"] = 1  // PANIC!

// AI MISTAKE: Modifying during iteration
for i, v := range slice {
    if shouldRemove(v) {
        slice = append(slice[:i], slice[i+1:]...)  // Corrupts!
    }
}
```

### 9. String Handling (Medium)

```go
// AI MISTAKE: O(n²) concatenation
var result string
for _, s := range strings {
    result += s  // Creates new string each time!
}

// CORRECT: Use Builder
var b strings.Builder
for _, s := range strings {
    b.WriteString(s)
}
```

### 10. Interface Pollution (Medium)

```go
// AI MISTAKE: God interfaces
type Repository interface {
    Create, Read, Update, Delete, List, Search, ...  // Too many!
}

// CORRECT: Small, focused
type Reader interface {
    Read(id string) (Item, error)
}
```

---

## Testing Anti-Patterns

### Anti-Pattern 1: Testing Mock Behavior

```go
// BAD: Testing the mock, not the code
func TestHandler(t *testing.T) {
    mockDB := &MockDB{}
    handler := NewHandler(mockDB)

    handler.Process()
    if !mockDB.CalledWith("expected") {
        t.Fatal("mock not called correctly")  // WHO CARES?
    }
}

// GOOD: Test actual behavior
func TestHandler(t *testing.T) {
    db := setupTestDB(t)
    handler := NewHandler(db)

    result := handler.Process(input)

    if result.Status != "success" {
        t.Fatalf("expected success, got %s", result.Status)
    }
}
```

**Check for:**
- Assertions on mock call counts
- Test assertions checking mock state instead of output

### Anti-Pattern 2: Test-Only Methods in Production

```go
// BAD: Reset() only used in tests
type Cache struct {
    data map[string]interface{}
}

func (c *Cache) Reset() {  // TEST POLLUTION!
    c.data = make(map[string]interface{})
}
```

**Check for:**
- Methods only called from `_test.go` files
- `test_mode` flags or similar in production code

### Anti-Pattern 3: Mocking Without Understanding

```go
// BAD: Mock prevents side effect test depends on
func TestDuplicateDetection(t *testing.T) {
    mockStore := &MockStore{WriteFunc: func() error { return nil }}
    service := NewService(mockStore)

    service.Add(config)
    service.Add(config)  // Should detect duplicate - BUT WON'T!
}
```

**Check for:**
- Mocks that neuter functionality the test depends on
- Over-mocking internal functions

### Anti-Pattern 4: Incomplete Mocks

```go
// BAD: Missing fields downstream uses
mockResponse := Response{
    Status: "success",
    Data:   userData,
    // Missing: Metadata!
}
```

---

## 100 Go Mistakes Quick Reference

| # | Issue | What to Check |
|---|-------|---------------|
| 5 | Interface Pollution | >5 methods? Created upfront instead of discovered? |
| 6 | Producer-Side Interfaces | Interface defined where implemented instead of used? |
| 7 | Returning Interfaces | Returns interface instead of concrete type? |
| 21 | Slice Init | Slice could be preallocated? |
| 27 | Map Init | Map could be preallocated? |
| 35 | Defer in Loop | Defer inside for/range? |
| 39 | String Concat | += in loop instead of strings.Builder? |
| 48 | Panicking | panic() used for recoverable errors? |
| 49 | Error Wrapping | Errors not wrapped with context? |
| 50 | Error Type Comparison | Using == instead of errors.As? |
| 51 | Error Value Comparison | Using == instead of errors.Is? |
| 52 | Handling Twice | Both logging AND returning error? |
| 53 | Not Handling | Error assigned to _ or ignored? |
| 58 | Race Problems | Shared state without sync? |
| 62 | Goroutine Lifecycle | No stop mechanism? |
| 63 | Loop Variables | Captured in closure without param? |
| 70 | Mutex Scope | Mutex doesn't cover entire operation? |
| 74 | Copying Sync Types | sync.Mutex copied by value? |
| 76 | time.After Leaks | time.After in loop without cleanup? |
| 79 | Resource Closing | defer Close() missing? |
| 83 | Race Flag | Tests run with -race? |
| 86 | Sleep in Tests | time.Sleep instead of sync primitives? |

---

## Architecture Violations

### Domain Layer Violations

```go
// VIOLATION: Domain imports adapter
package domain
import "database/sql"  // NO!
import "net/http"      // NO!

// Domain should only use stdlib types
```

### Dependency Direction Violations

```go
// VIOLATION: Service depends on concrete type
func NewUserService(repo *postgres.UserRepository) // NO!

// CORRECT: Depends on interface
func NewUserService(repo ports.UserRepository)  // YES
```

### Business Logic Location Violations

```go
// VIOLATION: Logic in handler
func (h *Handler) CreateUser(w http.ResponseWriter, r *http.Request) {
    if !isValidEmail(req.Email) { ... }  // Should be in domain!
}
```

---

## Output Format

### Spec Compliance Review

```yaml
review_type: spec_compliance
task_id: {task.id}
status: APPROVED|CHANGES_NEEDED

criteria_assessment:
  - criterion: "[criterion text]"
    status: met|partial|missing
    evidence: "[file:line or test name]"
    notes: "[if not fully met]"

under_building:
  found: true|false
  issues: [...]

over_building:
  found: true|false
  issues: [...]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
```

### Code Quality Review

```yaml
review_type: code_quality
task_id: {task.id}
status: APPROVED|CHANGES_NEEDED

findings:
  critical:
    - issue: "[description]"
      location: "[file:line]"
      mistake_ref: "[#number]"
      category: "[error_handling|concurrency|resource_leak|nil_safety]"
      fix: "[how to fix]"
  major:
    - issue: "[description]"
      location: "[file:line]"
      fix: "[how to fix]"
  minor:
    - issue: "[description]"
      suggestion: "[improvement]"

ai_code_problems:
  - pattern: "[which AI mistake pattern]"
    location: "[file:line]"
    fix: "[correct approach]"

testing_issues:
  - anti_pattern: "[which anti-pattern]"
    location: "[test file:line]"
    fix: "[how to improve]"

architecture:
  compliant: true|false
  violations: [...]

verdict: APPROVED|CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "[what to fix]"
    location: "[file:line]"
```

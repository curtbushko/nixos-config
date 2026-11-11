# TDD Workflow for Go Projects

Test-Driven Development (TDD) is MANDATORY for all Go code. This document defines the workflow and patterns.

## Testing Framework

Preserve the project's established framework. The optional testify examples use:
- `require` for fatal assertions (stops test on failure)
- `assert` for non-fatal assertions (continues test)
- `mock` package for mock generation
- **Exception**: Kubernetes e2e tests may use k8s e2e framework

## The TDD Cycle

```mermaid
graph LR
    RED["RED<br/>Write Failing Test"] --> GREEN["GREEN<br/>Write Minimal Code"]
    GREEN --> REFACTOR["REFACTOR<br/>Clean Up"]
    REFACTOR --> RED

    style RED fill:#ffcdd2
    style GREEN fill:#c8e6c9
    style REFACTOR fill:#bbdefb
```

### 1. RED: Write a Failing Test

Write a test for required observable behavior using testify. Run it and confirm
it fails for the intended reason, not an unrelated setup failure.

### 2. GREEN: Write Minimal Code to Pass

Implement only enough behavior to satisfy the failing test. Use the existing
package structure and avoid introducing speculative abstractions.

### 3. REFACTOR: Clean Up While Green

Improve naming, duplication, and clarity without adding new behavior. Run tests
after each change. A new requirement starts another RED/GREEN cycle.

---

## 6-Step TDD Workflow

For each feature or bugfix, follow these steps:

### Step 1: INVESTIGATE

- Understand the requirement thoroughly
- Review existing code and related modules
- Identify dependencies and potential side effects
- Document acceptance criteria

### Step 2: PLAN (features) / REPRODUCE (bugs)

**For features:**
- Design the interface/API BEFORE implementation
- Identify edge cases and error scenarios
- Plan test scenarios

**For bugs:**
- Create a minimal reproduction case
- Write a failing test that demonstrates the bug

### Step 3: TEST (RED)

- Write failing tests FIRST
- Use AAA pattern (Arrange, Act, Assert)
- Include positive and negative test cases
- Test edge cases and error handling
- **RUN TESTS - confirm they FAIL**

### Step 4: IMPLEMENT (GREEN)

- Write MINIMAL code to pass the test
- Follow SOLID principles
- Keep functions small and focused
- **RUN TESTS - confirm they PASS**

### Step 5: VALIDATE

- Run ALL tests to ensure no regressions
- Check code coverage
- Run linter
- Review error handling

### Step 6: REFACTOR

- Clean up for clarity and maintainability
- Remove dead code
- **RUN TESTS - ensure still green**

---

## Test Patterns

### Table-Driven Tests (with testify)

```go
import (
    "testing"
    "github.com/stretchr/testify/require"
)

func TestValidateEmail(t *testing.T) {
    tests := []struct {
        name    string
        email   string
        wantErr bool
    }{
        {"valid email", "user@example.com", false},
        {"valid with subdomain", "user@mail.example.com", false},
        {"empty email", "", true},
        {"no at sign", "userexample.com", true},
        {"no domain", "user@", true},
        {"no local part", "@example.com", true},
    }

    for _, tt := range tests {
        t.Run(tt.name, func(t *testing.T) {
            err := ValidateEmail(tt.email)
            if tt.wantErr {
                require.Error(t, err)
            } else {
                require.NoError(t, err)
            }
        })
    }
}
```

### Subtests for Organization

```go
func TestUserService(t *testing.T) {
    t.Run("CreateUser", func(t *testing.T) {
        t.Run("success", func(t *testing.T) {
            // test success case
        })
        t.Run("duplicate email", func(t *testing.T) {
            // test duplicate error
        })
        t.Run("invalid email", func(t *testing.T) {
            // test validation error
        })
    })

    t.Run("GetUser", func(t *testing.T) {
        t.Run("found", func(t *testing.T) {
            // test found case
        })
        t.Run("not found", func(t *testing.T) {
            // test not found error
        })
    })
}
```

### AAA Pattern (with testify)

```go
import (
    "testing"
    "github.com/stretchr/testify/assert"
)

func TestCalculateTotal(t *testing.T) {
    // Arrange
    cart := NewCart()
    cart.AddItem(Item{Name: "Widget", Price: 10.00, Qty: 2})
    cart.AddItem(Item{Name: "Gadget", Price: 25.00, Qty: 1})

    // Act
    total := cart.CalculateTotal()

    // Assert
    assert.Equal(t, 45.00, total)
}
```

### Test Helpers

Mark helpers with `t.Helper()` and register resource cleanup with `t.Cleanup()`.
Share setup only when it improves clarity; do not introduce a fixed chain of
repositories, services, and handlers just to arrange a test.

---

## Mocking Strategies

Define small dependency interfaces at the consumer when substitution is useful.
Test doubles should preserve the behavior needed by the test without duplicating
production logic. No particular package hierarchy is required.

### Function-Based Mocks

```go
type mockEmailSender struct {
    SendFunc func(to, subject, body string) error
}

func (m *mockEmailSender) Send(to, subject, body string) error {
    if m.SendFunc != nil {
        return m.SendFunc(to, subject, body)
    }
    return nil
}

// Usage in test (with testify)
func TestNotifyUser(t *testing.T) {
    var sentTo string
    sender := &mockEmailSender{
        SendFunc: func(to, subject, body string) error {
            sentTo = to
            return nil
        },
    }

    notifier := NewNotifier(sender)
    notifier.NotifyUser("user@example.com", "Hello")

    assert.Equal(t, "user@example.com", sentTo)
}
```

---

## Testing Anti-Patterns

### Never Test Mock Behavior

```go
// BAD - Testing the mock, not the code
func TestBad(t *testing.T) {
    mock := &mockRepo{}
    svc := NewService(mock)

    svc.DoSomething()

    if !mock.CalledWith("expected") {  // Testing mock!
        t.Fatal("mock not called correctly")
    }
}

// GOOD - Test actual behavior (with testify)
func TestGood(t *testing.T) {
    mock := &mockRepo{}
    svc := NewService(mock)

    result, err := svc.DoSomething()

    require.NoError(t, err)
    assert.Equal(t, "success", result.Status)  // Testing real outcome
}
```

### Never Add Test-Only Methods to Production

```go
// BAD - Test pollution
type Cache struct {
    data map[string]interface{}
}

func (c *Cache) Reset() {  // Only used in tests!
    c.data = make(map[string]interface{})
}

// GOOD - Test utilities in test package
func cleanupCache(t *testing.T, c *Cache) {
    t.Helper()
    // Access via test-specific mechanism
}
```

### Mock Gate Function

Before mocking any method, ask:
1. What side effects does the real method have?
2. Does this test depend on those side effects?
3. Do I fully understand what this test needs?

If depends on side effects: Mock at LOWER level, not the method test depends on.

---

## Quality Gates

Use focused tests during RED/GREEN/refactoring and review fixes. Before each
candidate handoff, run its project-required build/lint/test gates using the supported
command surface/environment; Taskfile is not required. Record actual commands,
revision and results. Run planned broader checks against the integrated revision.

### Behavior Coverage

Prioritize important untested behavior and failure/recovery paths, not percentages.
Honor explicit project coverage gates, but impose no universal number. Explain which
plausible failure escapes the assertions. Do not add production hooks or trivial
assertions to satisfy a metric. Seek concrete failure evidence for important changed
behavior using genuine RED, pre-fix replay or safe targeted faults where practical.

### Race Detection

Use race detection on supported targets where concurrency risk or project CI requires it:

```bash
go test -race ./...
```

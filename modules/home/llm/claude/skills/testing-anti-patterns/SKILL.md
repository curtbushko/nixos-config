---
name: testing-anti-patterns
description: Use when writing tests, adding mocks, or tempted to add test-only methods to production code. Covers common testing mistakes for Go, Node.js, and Zig.
---

# Testing Anti-Patterns

## Core Principle

**Test what the code does, not what the mocks do.**

Mocks are tools to isolate, not things to test. Following strict TDD prevents these anti-patterns.

## The Iron Laws

```
1. NEVER test mock behavior
2. NEVER add test-only methods to production code
3. NEVER mock without understanding dependencies
```

## Anti-Pattern 1: Testing Mock Behavior

### The Violation

```go
// Go - BAD
func TestHandler(t *testing.T) {
    mockDB := &MockDB{}
    handler := NewHandler(mockDB)

    // Testing that mock was called, not behavior
    handler.Process()
    if !mockDB.CalledWith("expected") {
        t.Fatal("mock not called correctly")
    }
}
```

```javascript
// Node.js - BAD
test('renders sidebar', () => {
  render(<Page />);
  expect(screen.getByTestId('sidebar-mock')).toBeInTheDocument();
});
```

### Why It's Wrong

- You're verifying the mock works, not the code
- Test passes when mock present, tells nothing about real behavior

### The Fix

```go
// Go - GOOD: Test actual behavior
func TestHandler(t *testing.T) {
    db := setupTestDB(t)  // Real or realistic test double
    handler := NewHandler(db)

    result := handler.Process(input)

    // Test the RESULT, not mock interactions
    if result.Status != "success" {
        t.Fatalf("expected success, got %s", result.Status)
    }
}
```

```javascript
// Node.js - GOOD: Test real component
test('renders sidebar', () => {
  render(<Page />);  // Don't mock sidebar
  expect(screen.getByRole('navigation')).toBeInTheDocument();
});
```

## Anti-Pattern 2: Test-Only Methods in Production

### The Violation

```go
// Go - BAD: Reset() only used in tests
type Cache struct {
    data map[string]interface{}
}

func (c *Cache) Reset() {  // Test pollution!
    c.data = make(map[string]interface{})
}
```

```javascript
// Node.js - BAD
class Session {
  async destroy() {  // Only called in tests
    await this.cleanup();
  }
}
```

```zig
// Zig - BAD
pub const Service = struct {
    // Test-only field
    pub var test_mode: bool = false;

    pub fn process(self: *Service) void {
        if (test_mode) return;  // Yuck!
        // real logic
    }
};
```

### Why It's Wrong

- Pollutes production code with test concerns
- Dangerous if accidentally called in production
- Violates separation of concerns

### The Fix

```go
// Go - GOOD: Test utilities handle cleanup
// In testutil/cache.go
func CleanupCache(t *testing.T, c *Cache) {
    t.Helper()
    // Access internals via reflection or separate test package
}
```

```javascript
// Node.js - GOOD: Test utilities
// In test-utils/
export async function cleanupSession(session) {
  const workspace = session.getWorkspaceInfo();
  if (workspace) {
    await workspaceManager.destroyWorkspace(workspace.id);
  }
}
```

```zig
// Zig - GOOD: Use dependency injection
pub const Service = struct {
    processor: ProcessorInterface,

    pub fn init(processor: ProcessorInterface) Service {
        return .{ .processor = processor };
    }
};

// In tests: inject mock processor
```

## Anti-Pattern 3: Mocking Without Understanding

### The Violation

```go
// Go - BAD: Over-mocking breaks test logic
func TestDuplicateDetection(t *testing.T) {
    // Mock prevents the write that detection depends on!
    mockStore := &MockStore{WriteFunc: func() error { return nil }}

    service := NewService(mockStore)
    service.Add(config)
    service.Add(config)  // Should detect duplicate - but won't!
}
```

### Gate Function

```
BEFORE mocking any method:
  1. Ask: "What side effects does the real method have?"
  2. Ask: "Does this test depend on those side effects?"
  3. Ask: "Do I fully understand what this test needs?"

  IF depends on side effects:
    Mock at LOWER level (the actual slow operation)
    NOT the high-level method test depends on

  IF unsure:
    Run test with real implementation FIRST
    THEN add minimal mocking
```

## Anti-Pattern 4: Incomplete Mocks

### The Violation

```go
// Go - BAD: Partial mock
mockResponse := Response{
    Status: "success",
    Data:   userData,
    // Missing: Metadata that downstream uses!
}
```

### The Fix

```go
// Go - GOOD: Complete mock matching real API
mockResponse := Response{
    Status:   "success",
    Data:     userData,
    Metadata: Metadata{RequestID: "req-123", Timestamp: time.Now()},
}
```

## Language-Specific Guidance

### Go

- Use table-driven tests
- Prefer interfaces for dependencies (testability)
- Use `t.Helper()` in test utilities
- Consider `testify` for assertions, but don't over-mock

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
            }
            if got != tt.want {
                t.Errorf("got %v, want %v", got, tt.want)
            }
        })
    }
}
```

### Node.js

- Use `describe`/`it` structure
- Prefer dependency injection over mocking modules
- Mock at boundaries (HTTP, DB), not internal functions
- Use `jest.spyOn` over `jest.mock` when possible

### Zig

- Use `std.testing` assertions
- Comptime for test configuration
- Use interfaces (function pointers in structs) for DI
- `test` blocks are first-class

```zig
test "feature works" {
    const input = Input{ .value = 42 };
    const result = feature(input);
    try std.testing.expectEqual(expected, result);
}
```

## Quick Reference

| Anti-Pattern | Fix |
|--------------|-----|
| Assert on mock elements | Test real component or unmock |
| Test-only production methods | Move to test utilities |
| Mock without understanding | Understand deps first, mock minimally |
| Incomplete mocks | Mirror real API completely |
| Tests as afterthought | TDD - tests first |

## Red Flags

- Assertion checks for `*-mock` test IDs
- Methods only called in test files
- Mock setup >50% of test code
- Test fails when you remove mock
- Can't explain why mock is needed

# Zig Team Examples

Concrete examples of using the Zig Team skill with BDD-style plan files.

## Example 1: JSON Parser

### Step 1: Create PLAN.md (BDD/Gherkin Format)

```gherkin
Feature: JSON Parser
  As a developer
  I want to parse JSON documents incrementally
  So that I can handle large files without loading entirely into memory

  Background:
    Given a JSON parser initialized with std.testing.allocator

  Scenario: Parse simple object with string keys
    Given the input '{"name": "alice", "city": "wonderland"}'
    When I parse the JSON
    Then I should get an object value
    And the object should have 2 keys
    And key "name" should have string value "alice"
    And key "city" should have string value "wonderland"

  Scenario: Parse nested arrays
    Given the input '[[1, 2], [3, 4], [5]]'
    When I parse the JSON
    Then I should get an array with 3 elements
    And element 0 should be an array with 2 elements

  Scenario: Parse string with escape sequences
    Given the input '"hello\nworld\t\"quoted\"\u0041"'
    When I parse the JSON
    Then I should get a string value
    And the string should equal "hello\nworld\t\"quoted\"A"

  Scenario: Parse numbers with various formats
    Given the input '{"int": 42, "neg": -17, "float": 3.14, "exp": 1.5e+10}'
    When I parse the JSON
    Then key "int" should have integer value 42
    And key "neg" should have integer value -17
    And key "float" should have float value approximately 3.14
    And key "exp" should have float value approximately 15000000000

  Scenario: Parse boolean and null literals
    Given the input '{"yes": true, "no": false, "nothing": null}'
    When I parse the JSON
    Then key "yes" should have boolean value true
    And key "no" should have boolean value false
    And key "nothing" should be null

  Scenario: Stream large document with bounded memory
    Given a JSON document of 10MB
    When I parse using the streaming API with 64KB buffer
    Then memory usage should not exceed 128KB
    And all values should be correctly parsed

  Scenario: Report error with line and column
    Given the input with syntax error at line 3, column 7
    When I attempt to parse
    Then I should get error.InvalidSyntax
    And the error location should be line 3, column 7

  Scenario: Use arena allocator for parsed values
    Given an arena allocator wrapping std.testing.allocator
    When I parse '{"data": [1, 2, 3]}'
    Then I can free all memory with a single arena.deinit()

  # Note: Reference std.json for API design
  # Note: Allocator must be passed explicitly
  # Note: Consider using comptime for character lookup tables
```

### Step 2: Invoke zig-team

```bash
/zig-team
```

### Expected Task Manager Output

```yaml
feature: json-parser
user_story: "As a developer I want to parse JSON documents incrementally So that I can handle large files without loading entirely into memory"
background_setup: "Initialize parser with std.testing.allocator"

scenarios:
  - name: "Parse simple object with string keys"
    given: ["the input '{\"name\": \"alice\", \"city\": \"wonderland\"}'"]
    when: ["I parse the JSON"]
    then: ["I should get an object value", "the object should have 2 keys"]

  - name: "Parse string with escape sequences"
    given: ["the input '\"hello\\nworld\\t\\\"quoted\\\"\\u0041\"'"]
    when: ["I parse the JSON"]
    then: ["the string should equal \"hello\\nworld\\t\\\"quoted\\\"A\""]

  # ... (additional scenarios)

architecture_analysis:
  modules_affected:
    - module: parser
      reason: Core parsing logic
    - module: tokenizer
      reason: Lexical analysis
    - module: value
      reason: JSON value representation

tasks:
  - id: 1
    name: "Define JSON value types"
    scenarios_covered:
      - "Parse simple object with string keys"
      - "Parse nested arrays"
      - "Parse boolean and null literals"
    files:
      create:
        - path: src/json/value.zig
          purpose: JSON value union type
    test_cases:
      - scenario: "Parse simple object with string keys"
        test_name: "test parse simple object"
        given_setup: "const input = \"{\\\"name\\\": \\\"alice\\\"}\";"
        when_action: "const result = try parse(allocator, input);"
        then_assert: "try testing.expect(result == .object);"
    dependencies: []

  - id: 2
    name: "Implement tokenizer"
    scenarios_covered:
      - "Parse string with escape sequences"
      - "Parse numbers with various formats"
      - "Report error with line and column"
    files:
      create:
        - path: src/json/tokenizer.zig
          purpose: Lexical tokenizer
    test_cases:
      - scenario: "Parse string with escape sequences"
        test_name: "test tokenize escape sequences"
        given_setup: "const input = \"\\\"hello\\\\nworld\\\"\";"
        when_action: "const token = try tokenizer.next();"
        then_assert: "try testing.expectEqualStrings(\"hello\\nworld\", token.string);"
    dependencies: [1]

  - id: 3
    name: "Implement parser"
    scenarios_covered:
      - "Parse simple object with string keys"
      - "Parse nested arrays"
      - "Stream large document with bounded memory"
      - "Use arena allocator for parsed values"
    files:
      create:
        - path: src/json/parser.zig
          purpose: JSON parser
    test_cases:
      - scenario: "Stream large document with bounded memory"
        test_name: "test streaming parse memory bounded"
        given_setup: "var counting_allocator = CountingAllocator.init(testing.allocator);"
        when_action: "_ = try parseStreaming(counting_allocator.allocator(), large_input);"
        then_assert: "try testing.expect(counting_allocator.peak_bytes < 128 * 1024);"
    dependencies: [1, 2]

  - id: 4
    name: "Create public API"
    scenarios_covered: []  # Integration task
    files:
      create:
        - path: src/json.zig
          purpose: Public module interface
      modify:
        - path: build.zig
          changes: Add json module
    dependencies: [3]

execution_order: [1, 2, 3, 4]
```

---

## Example 2: HTTP Client

### PLAN.md (BDD/Gherkin Format)

```gherkin
Feature: HTTP Client
  As a developer
  I want to make HTTP/1.1 requests
  So that I can communicate with web services

  Background:
    Given an HTTP client initialized with default settings

  Scenario: Make GET request and read response
    Given a server responding with "Hello, World!" at "/greeting"
    When I make a GET request to "/greeting"
    Then the response status should be 200
    And the response body should be "Hello, World!"

  Scenario: Make POST request with body
    Given a server that echoes POST bodies at "/echo"
    When I make a POST request to "/echo" with body "test data"
    Then the response status should be 200
    And the response body should contain "test data"

  Scenario: Set custom headers
    Given a server that returns the X-Custom header value at "/header-check"
    When I make a GET request with header "X-Custom: my-value"
    Then the response body should contain "my-value"

  Scenario: Parse response headers
    Given a server that returns Content-Type "application/json"
    When I make a GET request
    Then I should be able to read header "Content-Type"
    And the header value should be "application/json"

  Scenario: HTTPS connection with TLS
    Given a server with valid TLS certificate at "https://example.com"
    When I make a GET request to "https://example.com"
    Then the connection should use TLS
    And the response should be received successfully

  Scenario: Connection timeout
    Given a server that delays response by 10 seconds
    And a client with 2 second timeout
    When I make a GET request
    Then I should get error.ConnectionTimedOut

  Scenario: Handle network errors gracefully
    Given no server is running on the target port
    When I attempt to connect
    Then I should get error.ConnectionRefused

  # Note: Use std.net for TCP connections
  # Note: Use std.crypto.tls for TLS
  # Note: Don't implement HTTP/2 or chunked encoding initially
```

### Invocation

```bash
/zig-team
```

---

## Example 3: Specific Plan File Location

### docs/features/allocator.md (BDD/Gherkin Format)

```gherkin
Feature: Pool Allocator
  As a game developer
  I want a fixed-size pool allocator
  So that I can efficiently manage entities with O(1) allocation

  Background:
    Given a pool allocator configured for 64-byte objects
    And a maximum of 1000 slots

  Scenario: Pre-allocate all slots at initialization
    When I create a pool allocator
    Then 1000 slots should be available
    And memory should be pre-allocated for all slots

  Scenario: O(1) allocation
    Given a pool with available slots
    When I allocate 100 objects in sequence
    Then each allocation should complete in constant time
    And the allocator should return valid pointers

  Scenario: O(1) deallocation
    Given 100 allocated objects
    When I deallocate them in random order
    Then each deallocation should complete in constant time
    And the slots should be available for reuse

  Scenario: Thread-safe allocation
    Given a thread-safe pool allocator
    When 10 threads allocate and deallocate concurrently
    Then no data races should occur
    And all allocations should succeed or return error.OutOfMemory

  Scenario: Track memory usage
    Given an empty pool
    When I allocate 500 objects
    Then usedSlots() should return 500
    And availableSlots() should return 500

  Scenario: Detect double-free in debug mode
    Given debug mode is enabled
    And I have allocated and freed an object
    When I attempt to free the same pointer again
    Then I should get error.DoubleFree
    And a debug message should indicate the original free location
```

### Invocation

```bash
/zig-team plan="docs/features/allocator.md"
```

---

## Example 4: Implement Specific Task

After the Task Manager has broken down the feature:

```bash
# Implement only task 2 (e.g., after task 1 is done)
/zig-team task=2
```

---

## Example 5: Simple CLI Tool

### PLAN.md (BDD/Gherkin Format)

```gherkin
Feature: Word Counter
  As a command-line user
  I want to count words, lines, and characters
  So that I can analyze text files like the wc command

  Background:
    Given the zwc binary is built

  Scenario: Count lines in a file
    Given a file "test.txt" with 5 lines
    When I run "zwc -l test.txt"
    Then the output should be "5 test.txt"

  Scenario: Count words in a file
    Given a file "test.txt" containing "hello world foo bar"
    When I run "zwc -w test.txt"
    Then the output should be "4 test.txt"

  Scenario: Count characters in a file
    Given a file "test.txt" containing "hello"
    When I run "zwc -c test.txt"
    Then the output should be "5 test.txt"

  Scenario: Default output shows all counts
    Given a file "test.txt" with 3 lines, 10 words, 50 characters
    When I run "zwc test.txt"
    Then the output should be "3 10 50 test.txt"

  Scenario: Support multiple files
    Given files "a.txt" (2 lines) and "b.txt" (3 lines)
    When I run "zwc -l a.txt b.txt"
    Then the output should show "2 a.txt" and "3 b.txt"
    And a total line "5 total"

  Scenario: Read from stdin
    Given stdin contains "hello world\nfoo bar"
    When I run "zwc" with stdin input
    Then the output should be "2 4 19"
```

### Invocation and Flow

```bash
/zig-team
```

Results in 3 tasks:
1. Implement counting logic (scenarios: count lines, words, characters)
2. Implement file reading (scenarios: multiple files, stdin)
3. Implement CLI argument parsing (scenarios: flags, output format)

---

## Builder-Reviewer Cycle Example

### Builder Output (Task 2: Tokenizer)

```yaml
task_id: 2
task_name: "Implement tokenizer"
status: complete

files_created:
  - path: src/json/tokenizer.zig
    purpose: JSON tokenizer
    lines: 180

tests_added:
  - name: "test tokenize string"
    file: src/json/tokenizer.zig
    covers: String parsing with escapes
  - name: "test tokenize number"
    file: src/json/tokenizer.zig
    covers: Number parsing including floats
  - name: "test error location"
    file: src/json/tokenizer.zig
    covers: Error messages have line/column

validation:
  build: pass
  test: pass
  fmt: pass

commits:
  - hash: a1b2c3d
    message: "feat(json): implement tokenizer with escape handling"

summary: Implemented JSON tokenizer with full escape sequence support and error location tracking.
```

### Reviewer Output (Code Quality - CHANGES_NEEDED)

```yaml
review_type: code_quality
task_id: 2
status: CHANGES_NEEDED

findings:
  critical:
    - issue: "Missing errdefer for allocated string"
      location: "src/json/tokenizer.zig:87"
      category: "resource_leak"
      fix: "Add errdefer to free partial string on error"
  major:
    - issue: "Using catch {} to swallow parse error"
      location: "src/json/tokenizer.zig:142"
      category: "error_handling"
      fix: "Propagate error or handle explicitly"
  minor: []

memory_safety:
  issues_found: true

error_handling:
  complete: false
  gaps:
    - "Error swallowed at line 142"

verdict: CHANGES_NEEDED
changes_required:
  - priority: 1
    description: "Add errdefer for partial string allocation"
    location: "src/json/tokenizer.zig:87"
  - priority: 2
    description: "Handle or propagate parse error"
    location: "src/json/tokenizer.zig:142"
```

### Builder Fix Cycle

Builder receives feedback and fixes:

```yaml
task_id: 2
status: complete

fixes_applied:
  - issue: "Missing errdefer for allocated string"
    location: "src/json/tokenizer.zig:87"
    change: "Added errdefer allocator.free(str.ptr)"
  - issue: "Using catch {} to swallow parse error"
    location: "src/json/tokenizer.zig:142"
    change: "Changed to return err to propagate"

validation:
  build: pass
  test: pass
  fmt: pass

commits:
  - hash: e4f5g6h
    message: "fix(json): add errdefer and proper error propagation"
```

Reviewer runs again → APPROVED → Task complete.

---

## Example Test Output

When running `/zig-team`:

```
Reading PLAN.md...

Task Manager: Breaking down feature into tasks...
  Found 4 tasks in execution order: [1, 2, 3, 4]

Task 1: Define JSON value types
  [Builder] Writing failing test...
  [Builder] Implementing...
  [Builder] zig build test: PASS
  [Reviewer/Spec] APPROVED
  [Reviewer/Quality] APPROVED
  Task 1 complete.

Task 2: Implement tokenizer
  [Builder] Writing failing test...
  [Builder] Implementing...
  [Builder] zig build test: PASS
  [Reviewer/Spec] APPROVED
  [Reviewer/Quality] CHANGES_NEEDED (1 critical, 1 major)
  [Builder] Fixing issues...
  [Builder] zig build test: PASS
  [Reviewer/Quality] APPROVED
  Task 2 complete.

...

## Zig Team Complete: json-parser

### Summary
- Tasks completed: 4
- Files created: 5
- Tests added: 12

### Validation
- Build: pass
- Test: pass
- Format: pass

### Commits
- a1b2c3d: feat(json): define value types
- b2c3d4e: feat(json): implement tokenizer
- e4f5g6h: fix(json): add errdefer and proper error propagation
- c3d4e5f: feat(json): implement parser
- d4e5f6g: feat(json): create public API
```

# Zig Team Examples

Concrete examples of using the Zig Team skill with plan files.

## Example 1: JSON Parser

### Step 1: Create PLAN.md

```markdown
# Feature: JSON Parser

## Description

Implement a streaming JSON parser that can parse JSON documents
incrementally. Should handle large files without loading entirely
into memory.

## Acceptance Criteria

- [ ] Parse JSON objects with string keys
- [ ] Parse JSON arrays
- [ ] Parse strings with escape sequences (\n, \t, \", \\, \uXXXX)
- [ ] Parse numbers (integers and floats, including negative and exponents)
- [ ] Parse booleans (true, false) and null
- [ ] Streaming mode: parse without full document in memory
- [ ] Clear error messages with line and column information
- [ ] Use arena allocator for parsed values

## Notes

- Reference std.json for API design
- Allocator must be passed explicitly
- Consider using comptime for character lookup tables
```

### Step 2: Invoke zig-team

```bash
/zig-team
```

### Expected Task Manager Output

```yaml
feature: json-parser
description: Streaming JSON parser...
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
    files:
      create:
        - path: src/json/value.zig
          purpose: JSON value union type
    acceptance_criteria:
      - "Define Value union with object, array, string, number, bool, null"
    dependencies: []

  - id: 2
    name: "Implement tokenizer"
    files:
      create:
        - path: src/json/tokenizer.zig
          purpose: Lexical tokenizer
    acceptance_criteria:
      - "Parse strings with escape sequences"
      - "Parse numbers including negative and exponents"
      - "Clear error messages with line/column"
    dependencies: [1]

  - id: 3
    name: "Implement parser"
    files:
      create:
        - path: src/json/parser.zig
          purpose: JSON parser
    acceptance_criteria:
      - "Parse JSON objects with string keys"
      - "Parse JSON arrays"
      - "Parse booleans and null"
      - "Streaming mode"
      - "Use arena allocator"
    dependencies: [1, 2]

  - id: 4
    name: "Create public API"
    files:
      create:
        - path: src/json.zig
          purpose: Public module interface
      modify:
        - path: build.zig
          changes: Add json module
    acceptance_criteria:
      - "Export parse and stringify functions"
    dependencies: [3]

execution_order: [1, 2, 3, 4]
```

---

## Example 2: HTTP Client

### PLAN.md

```markdown
# Feature: HTTP Client

## Description

Implement a simple HTTP/1.1 client that can make GET and POST requests.
Should support TLS connections.

## Acceptance Criteria

- [ ] Make GET requests and read response body
- [ ] Make POST requests with body
- [ ] Set custom headers
- [ ] Parse response status code and headers
- [ ] Support HTTPS (TLS)
- [ ] Connection timeout support
- [ ] Proper error handling for network errors

## Notes

- Use std.net for TCP connections
- Use std.crypto.tls for TLS
- Don't implement HTTP/2 or chunked encoding initially
```

### Invocation

```bash
/zig-team
```

---

## Example 3: Specific Plan File Location

### docs/features/allocator.md

```markdown
# Feature: Pool Allocator

## Description

Implement a fixed-size pool allocator for objects of the same size.
Useful for game entities or network connections.

## Acceptance Criteria

- [ ] Pre-allocate fixed number of slots
- [ ] O(1) allocation and deallocation
- [ ] Thread-safe option
- [ ] Memory usage tracking
- [ ] Debug mode: detect double-free
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

### PLAN.md

```markdown
# Feature: Word Counter

## Description

A CLI tool that counts words, lines, and characters in files.

## Acceptance Criteria

- [ ] Count lines in a file
- [ ] Count words in a file
- [ ] Count characters in a file
- [ ] Support multiple files
- [ ] Support reading from stdin
- [ ] Output format matches wc command
```

### Invocation and Flow

```bash
/zig-team
```

Results in 3 tasks:
1. Implement counting logic
2. Implement file reading
3. Implement CLI argument parsing

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

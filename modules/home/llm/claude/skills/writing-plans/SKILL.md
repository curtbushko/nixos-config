---
name: writing-plans
description: Use when starting multi-step implementation tasks. Creates comprehensive plans with bite-sized tasks (2-5 min each) before any code is written.
---

# Writing Plans

## Core Principle

**Write comprehensive plans before touching code.**

Assume the engineer executing has ZERO codebase context. Document everything explicitly.

## Plan Location

Plans go to: `docs/plans/YYYY-MM-DD-<feature-name>.md`

## Bite-Sized Task Granularity

Each task should take 2-5 minutes. NOT "implement validation" but:

1. Write the failing test
2. Run it to confirm failure
3. Implement minimal code to pass
4. Run tests to confirm pass
5. Commit

## Plan Document Structure

```markdown
# [Feature Name] Implementation Plan

**Goal:** [One sentence summary]
**Architecture:** [2-3 sentences on approach]
**Tech Stack:** [Key technologies involved]

---

### Task 1: [Component Name]

**Files:**
- Create: `exact/path/to/new-file.go`
- Modify: `exact/path/to/existing.go:123-145`
- Test: `exact/path/to/file_test.go`

**Step 1: Write the failing test**

```go
// exact/path/to/file_test.go
func TestFeatureBehavior(t *testing.T) {
    // Complete test code here
}
```

**Step 2: Run test to verify it fails**

```bash
go test ./exact/path/... -run TestFeatureBehavior
```

Expected: FAIL with "undefined: FeatureName"

**Step 3: Implement minimal code**

```go
// exact/path/to/new-file.go
package mypackage

func FeatureBehavior() error {
    // Minimal implementation
}
```

**Step 4: Run tests to confirm pass**

```bash
go test ./exact/path/... -run TestFeatureBehavior
```

Expected: PASS

**Step 5: Commit**

```bash
git add exact/path/
git commit -m "feat: add FeatureBehavior with tests"
```

---

### Task 2: [Next Component]
...
```

## Key Requirements

### 1. Exact File Paths Always

- `src/handlers/user.go:45-67` not "the user handler"
- `internal/domain/user/repository.go` not "repository interface"

### 2. Complete Code in Plan

NOT: "Add validation logic"

YES:
```go
func Validate(input string) error {
    if input == "" {
        return errors.New("input required")
    }
    return nil
}
```

### 3. Exact Commands with Expected Output

NOT: "Run the tests"

YES:
```bash
go test ./internal/... -v
# Expected: PASS (3 tests)
```

### 4. Reference Relevant Skills

When plan involves specific patterns, reference skills:

- "Follow hexagonal architecture per golang skill"
- "Use TDD workflow per CLAUDE.md"

## Plan Checklist

Before plan is complete:

- [ ] Every task has exact file paths
- [ ] Every task has complete code (not pseudocode)
- [ ] Every task has exact commands
- [ ] Every task has expected output
- [ ] Tasks are 2-5 minutes each
- [ ] Tasks follow TDD (test first)
- [ ] Plan references relevant skills
- [ ] Plan follows DRY, YAGNI principles

## Execution Options

After plan is written:

1. **Subagent-Driven** (same session)
   - Use `subagent-driven-development` skill
   - Fresh subagent per task with two-stage review

2. **Batch Execution** (separate session)
   - Use `executing-plans` skill
   - Execute in batches with checkpoint reviews

## Anti-Patterns

- Vague instructions ("add proper error handling")
- Missing file paths ("update the handler")
- Incomplete code ("implement similar logic")
- Large tasks (>5 minutes)
- Skipping test steps
- No expected outputs

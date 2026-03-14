# Go Builder Context Injection

This context is injected into every Go Builder agent dispatch.

**IMPORTANT**: For detailed patterns and examples, see the shared Go references at `~/.claude/skills/golang/references/`:
- [architecture.md](../../golang/references/architecture.md) - Hexagonal architecture
- [tdd-workflow.md](../../golang/references/tdd-workflow.md) - TDD patterns
- [code-patterns.md](../../golang/references/code-patterns.md) - Go idioms
- [protobuf.md](../../golang/references/protobuf.md) - Protobuf guidelines
- [ai-code-problems.md](../../golang/references/ai-code-problems.md) - Common mistakes and fixes

---

## Non-Negotiable Requirements

### TDD Workflow
```
1. RED: Write failing test FIRST, confirm it FAILS
2. GREEN: Write MINIMAL code to pass
3. REFACTOR: Clean up while green
```

### CLI Framework
**All service CLI entry points MUST use Cobra and Viper:**
- [spf13/cobra](https://github.com/spf13/cobra) for command structure
- [spf13/viper](https://github.com/spf13/viper) for configuration
- Root command in `cmd/<app>/root.go`
- Bind flags to Viper: `viper.BindPFlag("key", cmd.Flags().Lookup("flag"))`

### Testing Framework
**All tests MUST use [testify](https://github.com/stretchr/testify):**
- `require` for fatal assertions (stops test on failure)
- `assert` for non-fatal assertions (continues test)
- `mock` package for mocking
- **Exception**: Kubernetes e2e tests may use k8s e2e framework

```go
import (
    "github.com/stretchr/testify/assert"
    "github.com/stretchr/testify/require"
)

func TestExample(t *testing.T) {
    require.NoError(t, err)
    assert.Equal(t, expected, actual)
}
```

### File Creation Rules
**NEVER create .gitkeep files.** Git tracks files, not directories.

---

## Build Quality Gates

Before completing, ALL must pass:
```bash
task build           # REQUIRED - error if Taskfile not found
task test            # REQUIRED - error if Taskfile not found
task lint            # REQUIRED - error if Taskfile not found
go-arch-lint check   # if config exists
```

**IMPORTANT**: Always use Taskfile targets. If no Taskfile exists, STOP and report an error.

**DO NOT MODIFY** linting configuration files. Fix the code, not the rules.

---

## Architecture Quick Reference

```
Dependencies flow INWARD: adapters -> application -> ports -> domain
Domain layer has NO external dependencies
```

| Layer | Path | Contains |
|-------|------|----------|
| Domain | `internal/domain/` | Entities, value objects, domain errors |
| Ports | `internal/ports/` | Interface definitions |
| Application | `internal/application/` | Business logic, use cases |
| Handlers | `internal/adapters/handlers/` | HTTP/gRPC entry points |
| Repositories | `internal/adapters/repositories/` | Database implementations |

---

## Common Lint Fixes

| Error | WRONG Fix | CORRECT Fix |
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

## Systematic Debugging (When Stuck)

If build/test fails repeatedly:

### Phase 1: Root Cause Investigation
1. Read error messages COMPLETELY
2. Reproduce consistently
3. Check recent changes (git diff)
4. Trace data flow from source to error

### Phase 2: Pattern Analysis
1. Find working examples in codebase
2. Compare against references
3. Identify differences

### Phase 3: Hypothesis Testing
1. Form ONE clear hypothesis
2. Change ONE variable
3. Verify before continuing

### Red Flags - STOP If:
- "Quick fix for now"
- "Just try changing X"
- Already tried 3+ fixes
- Proposing solutions BEFORE tracing data flow

---

## Output Format

### File Output (write to `.tasks/result-{task.id}-build.yaml`)

```yaml
task_id: {task.id}
task_name: "{task.name}"
status: completed|blocked|needs_clarification

files_created:
  - path: [path]
    purpose: [why]
files_modified:
  - path: [path]
    changes: [what changed]
tests_added:
  - name: [test name]
    file: [test file]
    covers: [what it tests]

validation:
  build: pass|fail
  test: pass|fail
  lint: pass|fail
  arch: pass|fail|skipped

commits:
  - hash: [short hash]
    message: [message]

summary: [1-2 sentences]
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY this to the orchestrator:
```
status: completed|blocked
summary: [one sentence]
```

### Fix Mode

When fixing review feedback, read the review results from `.tasks/result-{task.id}-review.yaml`
and fix each issue in `changes_required`. Write fix results to `.tasks/result-{task.id}-fix-{cycle}.yaml`
using the same format above. Return ONLY:
```
status: completed|blocked
fixes: [count of issues fixed]
```

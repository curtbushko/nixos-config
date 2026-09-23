# Zig Team - Usage Examples

## Example 1: Parser Module

### Step 1: Create the phase file with `to-phases`

`.phases/phase-02-parser.md`

```markdown
# Phase 2: Parser Module

## Description

Implement a tokenizer and recursive-descent parser for the configuration DSL.

## Acceptance Criteria

- [ ] Tokenizer produces tokens for identifiers, numbers, strings, and delimiters
- [ ] Parser produces an AST from a token stream
- [ ] Error unions carry position (line, column)
- [ ] Domain layer contains AST types and parse errors; no I/O
- [ ] `zig build test` passes with `std.testing.allocator`

## Notes

- Comptime lookup tables for keyword recognition
- Allocator threaded through parser state
- No panics — return `error.UnexpectedToken` etc.
```

### Step 2: Invoke zig-team

```
Use the zig-team skill for phase 2.
```

### Expected Task Manager Output

`.tasks/status.yaml`:

```yaml
project: "config-parser"
phase_id: 2
phase_name: "Parser Module"
phase_file: "phase-02-parser.md"
execution_order: [1, 2, 3, 4]
tasks:
  - id: 1
    name: "Define AST types in src/domain/ast.zig"
    status: pending
    deps: []
    plan_tasks:
      - "Domain layer contains AST types and parse errors; no I/O"
  - id: 2
    name: "Implement tokenizer with comptime keyword table"
    status: pending
    deps: [1]
    plan_tasks:
      - "Tokenizer produces tokens for identifiers, numbers, strings, and delimiters"
      - "Comptime lookup tables for keyword recognition"
  - id: 3
    name: "Implement recursive-descent parser with position-tracked errors"
    status: pending
    deps: [1, 2]
    plan_tasks:
      - "Parser produces an AST from a token stream"
      - "Error unions carry position (line, column)"
  - id: 4
    name: "Wire tests via zig build test"
    status: pending
    deps: [1, 2, 3]
    plan_tasks:
      - "zig build test passes with std.testing.allocator"
```

---

## Example 2: SQLite Repository Adapter

`.phases/phase-04-sqlite-repo.md`:

```markdown
# Phase 4: SQLite Repository Adapter

## Description

Implement the `UserRepository` port with a SQLite adapter.

## Acceptance Criteria

- [ ] `SqliteUserRepository.init(allocator, path)` opens a connection
- [ ] `deinit()` closes cleanly and frees prepared statements
- [ ] `save`, `findById`, `findByEmail`, `delete` all round-trip correctly
- [ ] Integration test uses `:memory:` DB and `std.testing.allocator`
- [ ] No business logic in the adapter — only mapping and I/O

## Notes

- Use `errdefer` for every allocation on the error path
- All statement handles owned by the adapter, freed in `deinit`
```

### Invocation

```
Use the zig-team skill for phase 4.
```

---

## Example 3: Specific Phase Location

`docs/features/log-rotation.md`:

```markdown
# Feature: Log Rotation

## Description

Add size-based log rotation to the file appender adapter.

## Acceptance Criteria

- [ ] Appender rotates when file exceeds configured max bytes
- [ ] Retention count keeps N most recent files
- [ ] No allocation on the hot write path
```

### Invocation

```
Use the zig-team skill. The phase file is at docs/features/log-rotation.md.
```

---

## Example 4: Implement a Specific Task

If the phase is partially complete and you want to run just task 3:

```
Use the zig-team skill for phase 2 task 3.
```

The orchestrator will skip planning if `.tasks/status.yaml` is already present for phase 2 and dispatch the Builder → Reviewer loop for task 3 only.

---

## Example 5: Simple Health Endpoint

`.phases/phase-01-health.md`:

```markdown
# Phase 1: Health Endpoint

## Description

Add a `/health` HTTP endpoint that returns `{"status":"ok"}`.

## Acceptance Criteria

- [ ] `HttpServer.serveHealth` returns 200 with the JSON body
- [ ] Integration test hits the endpoint over a real TCP socket
```

### Invocation and Flow

```
Use the zig-team skill.
```

Task Manager → Builder (RED test → GREEN handler → REFACTOR) → Reviewer (APPROVED) → phase marked complete.

---

## Builder ↔ Reviewer Cycle

### Builder output (returned to orchestrator)

```
status: complete
summary: Added SqliteUserRepository with init/deinit and CRUD; :memory: integration test passes.
```

### Reviewer output

```
verdict: CHANGES_NEEDED
issues: 2
```

Full detail is written to `.tasks/result-{id}-review.yaml` — for example:

```yaml
changes_required:
  - priority: critical
    description: "save() allocates buf without errdefer — leaks if bindText fails"
    location: "src/adapters/sqlite_repo.zig:73"
  - priority: major
    description: "UserRepository.deleteAll is only called from tests — semantic dead code"
    location: "src/adapters/sqlite_repo.zig:118"
```

### Builder fix cycle

The Builder reads `result-{id}-review.yaml`, fixes each issue, re-runs the focused test, writes `result-{id}-fix-1.yaml`, and returns:

```
status: complete
fixes: 2
```

### Key Point: File-Based Communication

The orchestrator never sees the full builder or reviewer output — only the two-line status/verdict. All detail lives in `.tasks/` files, which keeps the orchestrator's context lean across many tasks and phases.

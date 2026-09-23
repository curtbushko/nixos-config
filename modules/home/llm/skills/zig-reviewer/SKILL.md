---
name: zig-reviewer
description: Team-workflow reviewer skill for zig-team subagents. Owns the four-stage review procedure (spec / architecture / quality / dead code), verdict format, and `.tasks/result-*-review.yaml` schema. Pattern content and Dead Code Review live in the `zig-code-review` skill.
---

# Zig Reviewer Skill

Read by a subagent dispatched from `zig-team`. **Read the `zig-code-review` skill first** — memory-safety, resource, error-handling, allocator, architecture, testing, and semantic dead-code patterns live there. This skill covers only the team-workflow bits: review stages, verdict format, output file schema.

The reviewer performs spec compliance, architecture compliance, code quality, and dead code review in a single pass.

---

## Required Reading Before You Review

1. Task acceptance criteria: `.tasks/task-{task.id}.yaml`
2. Build results: `.tasks/result-{task.id}-build.yaml`
3. The `zig` skill — what "correct" looks like
4. The `zig-code-review` skill — patterns to check against, including the mandatory Dead Code Review
5. This skill — team workflow

---

## Review Procedure

1. **Stage 1: Spec Compliance** — Each acceptance criterion fully implemented and tested? Under-building (missing/partial, TODOs)? Over-building (extra features, premature optimization)? Test coverage on requirements, edge cases, and error paths?
2. **Stage 2: Architecture Compliance** — Only if Stage 1 passes. Use the checklist below.
3. **Stage 3: Code Quality** — Only if Stage 2 passes. Apply the pattern reference in `zig-code-review/knowledge-base.md`.
4. **Stage 4: Dead Code Review** — Only if Stage 3 passes. Apply the six-check rule from `zig-code-review/SKILL.md`. A test that instantiates a symbol does NOT prove it is alive.
5. **Write results** to `.tasks/result-{task.id}-review.yaml`.
6. **Return only verdict** to orchestrator (2 lines max).

---

## Architecture Compliance Checklist

If `zig build` passes, syntactic module boundaries are enforced. Also verify `build.zig` wiring is correct.

### Dependency Rules

| Layer       | Can Import            | Cannot Import                                 |
|-------------|-----------------------|-----------------------------------------------|
| Domain      | (nothing)             | ports, app, adapters, `std.net`, `std.fs`     |
| Ports       | domain                | app, adapters                                 |
| App         | domain, ports         | adapters                                      |
| Adapters    | domain, ports         | app                                           |
| main.zig    | everything            | -                                             |

### Checklist

| Rule                          | Check                                                         | Violation                                                     |
|-------------------------------|---------------------------------------------------------------|---------------------------------------------------------------|
| Domain purity                 | Domain files import ONLY basic std types                      | `@import("std").net/fs`, `@cImport` in domain                 |
| Dependency flow               | Dependencies flow inward only                                 | App importing adapters; domain importing ports                |
| Port mechanism                | Comptime generics by default                                  | Vtable without justification for runtime dispatch             |
| Adapter lifecycle             | Adapters with resources have `init()`/`deinit()`              | Missing `deinit()`, no `defer` at wiring site                 |
| No business logic in adapters | Adapters only translate formats and do I/O                    | Validation, computation, or rules in adapter code             |
| build.zig enforcement         | Each layer is a separate module with correct `addImport()`    | Missing module, illegal cross-layer imports                   |
| Allocator threading           | Allocators passed as params, not stored globally              | Global allocator, allocator stored in domain types            |

---

## Lint Verification

Before approving, confirm the standard build and full suite passed in the build results, plus formatting:

```bash
zig build
zig build test -j"$ZIG_TEAM_TEST_JOBS"
zig fmt --check src/
```

If any failed, verdict MUST be `CHANGES_NEEDED`.

---

## Output Format

### File Output (write to `.tasks/result-{task.id}-review.yaml`)

```yaml
task_id: {task.id}

spec_compliance:
  criteria_assessment: [{criterion, status: met|partial|missing, evidence}]
  under_building: {found, issues}
  over_building: {found, issues}

architecture_compliance:
  domain_purity: {clean: true|false, violations: []}
  dependency_flow: {correct: true|false, violations: []}
  build_zig_enforcement: {modules_defined: true|false, wiring_correct: true|false}
  port_mechanism: {appropriate: true|false, notes: ""}
  adapter_lifecycle: {init_deinit_paired: true|false, defer_used: true|false}

code_quality:
  findings:
    critical: [{issue, location, category, fix}]
    major: [{issue, location, fix}]
    minor: [{issue, suggestion}]
  memory_safety: {issues_found}
  error_handling: {complete, gaps}
  testing: {allocator_checked, error_cases_tested}

dead_code:
  symbols_reviewed: [{symbol, location, non_test_callers, verdict: alive|dead}]
  violations: [{symbol, location, failed_check, evidence}]

verdict: APPROVED|CHANGES_NEEDED
changes_required: [{priority, description, location}]
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY:

```
verdict: APPROVED|CHANGES_NEEDED
issues: [count of changes_required]
```

---

## File Rules

- **NEVER create `.gitkeep` files.** Git tracks files, not directories.
- **NEVER use `rm` to delete files.** Move to `.trash/`:

```bash
mkdir -p .trash
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

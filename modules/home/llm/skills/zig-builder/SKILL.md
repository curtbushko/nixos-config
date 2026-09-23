---
name: zig-builder
description: Team-workflow builder skill for zig-team subagents. Owns the TDD-driven build loop, focused-test parallelism strategy, `.tasks/result-*-build.yaml` schema, and fix-mode contract. Language, architecture, and testing patterns live in the `zig` skill.
---

# Zig Builder Skill

Read by a subagent dispatched from `zig-team`. **Read the `zig` skill first** — language idioms, TDD workflow, implementation ladder, hexagonal architecture, `build.zig` boundary setup, Zig best practices, and testing patterns all live there. This skill covers only the team-workflow bits: file rules, test-parallelism strategy, and how to write your result file.

---

## Required Reading Before You Build

1. Your task spec: `.tasks/task-{task.id}.yaml`
2. The `zig` skill (`~/.claude/skills/zig/SKILL.md`) — language + architecture + testing
3. This skill — team workflow

You MUST follow TDD (RED → GREEN → REFACTOR) and hexagonal architecture as defined in the `zig` skill. Dependencies flow INWARD: adapters → app → ports → domain. Domain has NO external dependencies.

---

## File Rules

- **NEVER create `.gitkeep` files.** Git tracks files, not directories.
- **NEVER use `rm` to delete files.** Move to `.trash/`:

```bash
mkdir -p .trash
grep -q "^\.trash/$" .gitignore 2>/dev/null || echo ".trash/" >> .gitignore
mv <file> .trash/
```

---

## Build Quality Gates

### Focused development loop

During RED, GREEN, REFACTOR, and ordinary review-fix cycles, run the narrowest test step that proves the changed behavior. Record the command and result. Do not run the whole repository suite after every edit.

Before the first review of a task, the standard build and full suite must pass once:

```bash
zig build
zig build test -j"$ZIG_TEAM_TEST_JOBS"
```

Honor an existing positive integer `ZIG_TEAM_TEST_JOBS` value. When it is unset, choose a conservative job count capped by logical CPU count and available memory, using `max(1, min(logical_cpu_count, available_memory_gib / 4))`. Read Linux `MemAvailable` from `/proc/meminfo`; on Darwin, use `sysctl -n hw.memsize` conservatively; fall back to 1 if detection is unavailable. Reject an explicit value unless it is a positive integer. Export the selected value and record it in the result file. Never hard-code `-j1`; a user can still request serial execution with `ZIG_TEAM_TEST_JOBS=1`.

After review feedback, always re-run the focused regression. Re-run the full suite only when the fix affects shared infrastructure, public contracts, build wiring, persistence, concurrency, or multiple capabilities, or when the reviewer requests it. Record either the new full-suite result or the reason the previous result remains applicable.

### Final phase task only

Reserve exhaustive project-specific gates for the final task of a phase. This includes packaged-runtime journeys, full-system matrices, and repository-wide format/lint or release checks such as:

```bash
zig fmt --check src/
make lint
task lint
```

The final task records the complete phase-wide release evidence. Earlier tasks use focused tests plus their one standard full-suite run.

---

## Output Format

### File Output (write to `.tasks/result-{task.id}-build.yaml`)

```yaml
task_id: {task.id}
task_name: "{task.name}"
status: complete|blocked|needs_clarification
files_created: [{path, purpose}]
files_modified: [{path, changes}]
tests_added: [{name, file, covers}]
validation:
  build: {passed, command}
  test:
    focused: {command, passed}
    full_suite: {command, passed, jobs}
  fmt: {passed}
commits: [{hash, message}]
summary: "[1-2 sentences]"
```

### Return to Orchestrator (2 lines max)

Write full results to the file above. Return ONLY:

```
status: complete|blocked
summary: [one sentence]
```

### Fix Mode

When fixing review feedback, read the review results from `.tasks/result-{task.id}-review.yaml` and fix each issue in `changes_required`. Write fix results to `.tasks/result-{task.id}-fix-{cycle}.yaml` using the same format above. Return ONLY:

```
status: complete|blocked
fixes: [count of issues fixed]
```

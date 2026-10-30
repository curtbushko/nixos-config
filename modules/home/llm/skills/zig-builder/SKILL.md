---
name: zig-builder
description: Use when a zig-team builder implements or fixes one task. Follows TDD, focused-test parallelism, and mtn build/fix evidence contracts. Language, architecture, and testing patterns live in zig.
---

# Zig Builder Skill

Read by a subagent dispatched from `zig-team`. **Read the `zig` skill first** — language idioms, TDD workflow, implementation ladder, hexagonal architecture, `build.zig` boundary setup, Zig best practices, and testing patterns all live there. This skill covers file rules, test parallelism, and native mtn build/fix evidence.

---

## Required Reading Before You Build

1. `mtn-tasks` and its short `references/worker.md` contract — not coordinator internals
2. Your task description/evidence via `agent show` using the supplied absolute root and exact ref
3. The `zig` skill — language, architecture, testing; this skill — team workflow

Follow the worker contract. Never mutate the collection, initialize another,
merge branches or complete tasks. Receive isolated worktree/base/target, run/attempt,
spec hash, ownership/interfaces, commands and commit policy. Work in that checkout.

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

Use the coordinator's global-budget gate allocation, never host-wide CPU/RAM totals
independently per worker. `mtn-workflow budget` supplies conservative per-gate jobs;
all heavy commands, including reviewer builds, require a shared gate slot. Validate
an explicit `ZIG_TEAM_TEST_JOBS` as positive and within that allocation; otherwise
request an allocation (safe fallback: one job). Record the jobs and actual command.
Check disk before Nix/build work; reuse the approved dev shell and do not create
per-worker persistent profiles or run garbage collection.

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

## mtn Evidence and Fix Mode

Return a protocol v1 `build` JSON payload: common event keys, dispatchEventId,
exact Git head/tree/spec hash, ready-for-review or blocked, files, REQ/test coverage,
RED/GREEN, focused/full-suite commands/results and jobs, integration/final-phase
checks, commits and limitations. Coordinator serially publishes; workers never
append notes, patch records or maintain an authoritative result sidecar.

Fix workers read all specialty findings through mtn and address stable IDs. Produce
a NEW dispatch/build attempt/head/tree with a `fixes` mapping. Rerun focused checks;
rerun full suite for broad impact/reviewer request, otherwise justify previous evidence.
All four reviewers issue current explicit verdicts for the new build; do not mix attempts.
Commit only authorized implementation files, exclude `.tasks/`, and freeze that
worktree for review. Return concise outcome alongside the full payload.

Coordinator completes only after successful target integration, combined-revision
checks, current approvals, integration/completion evidence and target-history verification.
Branch approval is not delivery; failed checks/publication remain blockers.

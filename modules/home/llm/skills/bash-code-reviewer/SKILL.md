---
name: bash-code-reviewer
description: Use when independently reviewing materially changed Bash code or configuration.
---

# Bash Code Reviewer

Read `mtn-tasks`, [review contract](../mtn-tasks/references/reviewing.md), and
`bash` and the repository's supported shell/platform conventions. This is a separately customizable language role, not a generic
reviewer alias. Use a fresh context and the exact frozen revision/scope.

## Procedure

1. Map accepted criteria to actual source. Identify missing/extra/misunderstood
   behavior and inspect relevant callers or cross-language contracts.
2. Check quoting/arrays, argument and option boundaries, exit-status propagation,
pipefail/traps, stdin ownership, subprocess cleanup, portability, safe temporary
files, external-command checks and shell injection. Read embedded snippets in
Nix/CI/build files when their behavior changes. ShellCheck/shfmt complement source
inspection; do not use eval or discard failures to satisfy a linter.
3. Independently perform relevant project lint/static/evaluation checks and focused
   experiments for concrete doubts within the gate budget. Reuse authentic
   same-revision evidence for other checks without claiming to rerun it.
4. Review comments, API docs/examples, contracts and ownership/lifetime rationale.
   Supported external APIs/extension points need purpose, consumer scenarios and
   behavior tests—not fake production callers. Investigate unused internal machinery
   and speculative additions separately.
5. Route specialist risks to their reviewers. Unrelated debt is advisory unless it
   materially affects delivery. Style blocks only for an accepted rule or
   concrete correctness or maintenance risk, not personal preference.

## Output

Protocol review JSON with assigned `reviewer: bash:code`: criterion/source
evidence, stable findings with file:line/impact/required outcome,
Block/Advise/Escalate, actual validation, nonblocking suggestions and limitations.

## Boundaries

No source/index/branch/managed-record mutations, fixes, workers, integration,
publishing or completion. Required missing evidence is not a pass. Project
commands and environments govern; no mandatory Taskfile or unrelated framework.
A separate `bash-test-reviewer` owns test effectiveness; its approval does not
replace code approval. No activation, live-service probing or secret disclosure.

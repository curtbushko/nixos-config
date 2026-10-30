---
name: zig-reviewer
description: Use when a zig-team reviewer needs the shared read-only review contract, verdict rules, evidence requirements, conflict handling, and result schema.
---

# Zig Reviewer Shared Contract

Read `mtn-tasks` and its short worker contract, not coordinator/migration internals. This skill is
mandatory for every zig-team reviewer. Specialty procedures live in
`zig-code-reviewer`, `zig-comment-reviewer`, `zig-architecture-reviewer`, and
`zig-test-reviewer`. Receive absolute collection root, exact task ref, build/fix
event ID, allowed scope, spec hash, isolated worktree path, base/head/tree and attempt
in the handoff. Follow that handoff contract, then read exact task descriptions/evidence via
`agent show`. Inspect THAT frozen checkout. Isolate mutable check output/resources
or serialize checks; concurrent read-only reasoning need not mean concurrent builds.

## Review Boundary

Review a coherent task only after the Builder records passing required validation.
Start with the task and diff, then inspect complete affected files and any callers,
callees, interfaces, tests, or wiring needed for an informed verdict.

Reviewers are strictly read-only. They never fix code, tests, comments, managed
records, or build wiring. They return full evidence payloads through host result
delivery; only the coordinator serially publishes them with mtn. This avoids
concurrent read-modify-write note appends losing another reviewer's findings.

## Verdict Contract

Every reviewer returns exactly one verdict:

- `APPROVED`: no blocking findings remain.
- `CHANGES_NEEDED`: at least one blocking finding remains.

`NON_BLOCKING_SUGGESTIONS` is a separate list, not a verdict. It may accompany
either verdict. A preference between equally clear, compliant alternatives cannot
block approval.

All four reviewers must explicitly approve. The coordinator cannot override a
verdict. Conflicting blocking findings require a focused reconciliation between the
affected reviewers. If no compatible resolution exists, they present options,
consequences, and a joint recommendation for user decision.

## Evidence Rules

Each blocking finding must contain:

- stable identifier and `file:line` location
- violated requirement, rule, or standard
- concrete evidence and impact
- required outcome without over-prescribing implementation
- reviewers that must recheck the fix

Reviewers may rely on current Builder results for expensive full-suite evidence but
run the narrowest independent checks needed by their specialty. Missing, stale,
irreproducible, or contradictory evidence is blocking.

Initial review uses a fresh agent context. Reuse the same reviewer for its fix check
when available. Re-dispatch all four reviewers after changes to public behavior,
architecture, shared infrastructure, or multiple capabilities; otherwise re-dispatch
only reviewers whose concerns could be affected for renewed investigation. Every
required specialty still returns a fresh explicit verdict for the new build ID/head/tree;
unchanged reasoning may be reused by the reviewer, never by the coordinator.

## Evidence Payload

Return the following review payload for serial mtn `agent note` publication.
This is note content, not a result file or CLI request schema. Add exact task ref,
attempt, and frozen code/diff identity to every payload:

```json
{
  "schemaVersion": 1,
  "eventId": "demo/review/code/1",
  "kind": "review",
  "recordRef": "tasks/demo-01-01-parser.md",
  "specHash": "sha256:task-spec-fingerprint",
  "attempt": 1,
  "buildEventId": "demo/build/1",
  "head": "reviewed-commit",
  "tree": "reviewed-tree",
  "reviewer": "code",
  "verdict": "CHANGES_NEEDED",
  "user_decision_required": false,
  "changes_required": [{
    "id": "CODE-001",
    "location": "path/to/file.zig:42",
    "rule": "Applicable requirement or standard",
    "evidence": "Observed fact",
    "impact": "Why this matters",
    "required_outcome": "Result the Builder must achieve",
    "re_review": ["code"]
  }],
  "NON_BLOCKING_SUGGESTIONS": [],
  "validation": [{"command": "actual command", "result": "pass", "evidence": "observed result"}]
}
```

Substitute the actual specialty, exact ref, attempt, revision, and findings. APPROVED
requires an empty `changes_required` list; include real criterion coverage and
limitations. Optional suggestions include location, suggestion, and rationale.

Return the full payload and a concise verdict/issue count. The coordinator must
publish all four notes serially and confirm them before integrating. Only successful
combined-target checks, integration/completion evidence and verified target history
permit native task completion. A source/spec change requires reassessing approval validity; evidence is
attempt/revision-bound. Never create sidecar result files or mutate lifecycle state.

Never hide a blocking issue in `NON_BLOCKING_SUGGESTIONS`, and never promote a
personal preference to `CHANGES_NEEDED`.

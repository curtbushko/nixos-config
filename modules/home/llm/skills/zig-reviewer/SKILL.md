---
name: zig-reviewer
description: Use when a zig-team reviewer needs the shared read-only review contract, verdict rules, evidence requirements, conflict handling, and result schema.
---

# Zig Reviewer Shared Contract

This skill is mandatory for every zig-team reviewer. Specialty procedures live in
`zig-code-reviewer`, `zig-comment-reviewer`, `zig-architecture-reviewer`, and
`zig-test-reviewer`.

## Review Boundary

Review a coherent task only after the Builder records passing required validation.
Start with the task and diff, then inspect complete affected files and any callers,
callees, interfaces, tests, or wiring needed for an informed verdict.

Reviewers are strictly read-only. They never fix code, tests, comments, task files,
or build wiring.

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
only reviewers whose concerns could be affected.

## Result Schema

Write `.tasks/result-{task.id}-{specialty}-review.yaml`:

```yaml
task_id: 1
reviewer: code|comment|architecture|test
verdict: APPROVED|CHANGES_NEEDED
user_decision_required: false
changes_required:
  - id: CODE-001
    location: path/to/file.zig:42
    rule: "Applicable requirement or standard"
    evidence: "Observed fact"
    impact: "Why this matters"
    required_outcome: "Result the Builder must achieve"
    re_review: [code]
NON_BLOCKING_SUGGESTIONS:
  - location: path/to/file.zig:57
    suggestion: "Optional improvement"
    rationale: "Expected benefit"
validation: [{command: "...", result: pass|fail, evidence: "..."}]
```

Return only:

```text
verdict: APPROVED|CHANGES_NEEDED
issues: <changes_required count>
```

Never hide a blocking issue in `NON_BLOCKING_SUGGESTIONS`, and never promote a
personal preference to `CHANGES_NEEDED`.

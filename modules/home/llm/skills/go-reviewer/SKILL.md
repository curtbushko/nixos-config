---
name: go-reviewer
description: Use when a Go review handoff needs revision, scope, evidence, or verdict rules.
---

# Go Review Handoff

Read `mtn-tasks` and its [review contract](../mtn-tasks/references/reviewing.md).
This is a transport/evidence contract, not a combined-review substitute.
Go code and test reviewers are separate, customizable skills with independent
fresh contexts on the same candidate revision.

New tasks supply an approved `implementation.reviewPlan`. Use its exact assigned
review key (`go:code` or `go:test`), buildEventID, specHash, attempt, head/tree,
owned paths, verification budget and result path. A legacy dispatch naming only
`go-reviewer` needs specialty assignment; do not spawn reviewers or issue a
combined approval.

Return protocol v1 review JSON with canonical identities, verdict,
`changes_required` and array-valued `validation`, plus criterion evidence,
stable findings/impact, nonblocking suggestions and limitations. Required identity
missing means an incomplete handoff, not fabricated/null protocol fields.
Validation uses exactly `command`, `result`, `evidence`; result is lowercase
`pass`, `fail` or `unavailable`. For example:
`{"command":"source inspection fixture.go:3","result":"fail","evidence":"missing error check"}`.
Do not substitute `check`, `status`, `actual_result`, `not_run` or uppercase values.
Unavailable checks are not passes. Under Rex, write the assigned result file and
return only JSON; the coordinator publishes it.

Every new build requires current language code/test verdicts. Specialist
carry-forward is a separate explicitly evidenced attestation, not a stale approval.
No source, index, branch or managed-record mutations; no integration, pushes,
risk acceptance or completion. Use authorized disposable copies for diagnostics.

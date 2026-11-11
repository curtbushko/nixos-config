# Independent Review Contract

Read with the worker contract. Each reviewer inspects the exact frozen candidate
and returns evidence; only the coordinator publishes/integrates. Planning and
review use separate skills and fresh contexts sharing relevant knowledge.
Builder self-reports and design examples are claims, not proof.

## Inputs and payload

Receive task/ref/specHash, approved criteria, base/head/tree, buildEventID, attempt,
assigned review key and bounded paths, review plan, resource budget and result path.

Return canonical protocol v1 JSON: integer `schemaVersion: 1`, unique `eventID`,
`kind: review`, `recordRef`, `specHash`, `attempt`, `buildEventID`, `head`, `tree`,
assigned `reviewer`, `verdict`, `changes_required`, array-valued `validation`.
Include criterion/source/test evidence, stable findings, impact, required outcome,
re-review scope, `NON_BLOCKING_SUGGESTIONS` and limitations.
Each validation entry has exactly the canonical `command`, lowercase `result`
(`pass`, `fail`, `unavailable`) and `evidence` fields. A source-only check can name
`source inspection <file:line>` as its command/check; this does not claim execution.
Do not replace these keys with `check`, `status` or `actual_result`, and do not use
`not_run`, uppercase statuses or prose as result values. For example:
`{"command":"source inspection fixture.go:3","result":"fail","evidence":"ignored write error"}`.
Unavailable checks are not passes. Missing identity is an incomplete handoff;
do not invent/null protocol identities or claim a workflow verdict.

APPROVED requires no blockers and passing required independent validation.
CHANGES_NEEDED contains concrete blockers/evidence gaps. These remain the two
machine verdicts; Block/Advise/Escalate are finding dispositions, not extra verdicts.

## Finding disposition

- **Block:** demonstrated accepted-requirement violations, introduced/worsened
  defects or existing faults preventing safe/correct delivery; unresolved material
  security/safety, compatibility or accepted-workflow failures.
- **Advise:** preferences, speculative improvements, new requirements outside
  accepted scope and unrelated historical debt; record separately.
- **Escalate:** material risk, conflicting findings or substantial remediation
  scope that existing authority cannot resolve. Put the finding in
  `changes_required` with `disposition: Escalate` and
  `user_decision_required: true`; affected delivery waits for the user.

Each Block/Escalate finding needs stable ID, file:line, evidence, impact and
required outcome. Do not expand scope by calling a preference critical.
Do not automatically block all pre-existing debt or silently dismiss material risk.
The coordinator cannot waive/downgrade/park blockers to finish a loop.

## Review scopes

New tasks record the approved `implementation.reviewPlan`; see
[review plans](../../delivery-coordinator/references/review-plans.md).
Every materially affected Go/Node/Zig/Nix/Bash language has separate customizable
code and test reviewers, with keys such as `go:code` and `bash:test`.
Triggered specialist keys are `architecture`, `security`, `usability`, `maintenance`.
Legacy unqualified scopes are for historical inspection, not bypassing a new plan.
All required scopes must approve the same current build identity; integration
references exactly those current review IDs.

## Investigation and evidence

Read requirements, affected source/tests and relevant callers, expanding beyond
the diff for concrete risks. Code reviewers own implementation/API docs; usability
reviewers own user docs; architecture reviewers own design consistency.
Supported public APIs need purpose, consumers and behavior tests, not fake internal
callers. Untested behavior matters more than percentages; honor explicit project
gates, not universal numbers. Shared contract suites serve actual consistency
promises, not every dependency interface.

Use focused independent checks within resource/permission limits. Inspect authentic
same-revision evidence for other gates without claiming reruns. For important
behavior, seek genuine RED, pre-fix replay or safe targeted faults; verify the
intended assertion fails rather than unrelated setup. No mutation-every-test rule.
Source inspection does not certify user interaction or real integration semantics.

The frozen source/index/HEAD/branch/managed records are read-only. Diagnostic
mutations need an authorized disposable copy. No reviewer fixes source, spawns
workers, publishes, integrates, deploys or accepts risk. Under Rex, write the supplied
result file and return only JSON.

## Fixes, carry-forward and delivery

New candidates require current language code/test verdicts. Check previous findings
and new breakage; unrelated preferences remain advisory.
A triggered specialist may carry an unaffected assessment forward only in a NEW
current-build review with `carriedForwardFrom` pointing to its latest approved
recorded review, `carryForwardRationale` and actual scope/assumption comparison
evidence. Affected assumptions/behavior require reassessment. The prior review and
its build must remain available; missing/negative evidence cannot be carried.
The guard checks identity/linkage, not truth of the rationale.

Task approval does not prove combined workflows or product acceptance. The
coordinator verifies the integrated target; product management assesses each phase's
accepted scenarios as demonstrated, unmet or unverified using actual workflow/E2E
evidence. New needs are proposals, never silently added requirements.

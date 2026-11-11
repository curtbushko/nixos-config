# Node Team Orchestration

Read `delivery-coordinator`, `mtn-tasks` and its protocol/execution/resource/Rex
references. The coordinator owns selection, resume, supervision, serial writes,
integration, outcome evidence and cleanup. Workers read their exact task and role.

## Planning and handoff

Product management leads discovery and consolidates architect/security/usability/
maintenance input. Planning specialists assess the approach and shape accepted
constraints/test scenarios before implementation; new scope needs user approval.
Prepare the native task graph, ownership, REQ coverage and verification cadence.

Each new task contains approved `implementation.reviewPlan`; see
[review planning](../../delivery-coordinator/references/review-plans.md).
Record every materially affected language/path and all specialist trigger
booleans/reasons. Validate this against actual changes, including embedded scripts.
A changed review plan affects specHash and follows the approval-impact process.

Developer: `node-developer` plus relevant language guidance and `mtn-tasks`
worker contract. Pass exact refs, owned files, approved constraints, base/target,
attempt/run, semantic hash, commit policy, review plan and gate allocation.
Repository/infrastructure work is implemented by `repo-maintainer` with the
relevant Nix/Bash/tooling knowledge; application changes use language developers.

## Verification cadence

Run the narrowest relevant test first during RED, GREEN, and each fix cycle.
Before EACH review candidate, satisfy its project-required build/lint/test gates
using the supported environment/command surface. Taskfile and application
frameworks are not universal requirements. Preserve real RED/GREEN/results;
unavailable checks are not passes. The plan identifies expensive/platform/
packaged-runtime checks and their integrated-delivery boundary; do not run every
full-system build after every edit or silently omit required gates.

## Independent review

Dispatch `node-code-reviewer` and `node-test-reviewer` in fresh separate
contexts, plus pairs for other materially affected languages and triggered
`architecture-reviewer`, `security-reviewer`, `usability-reviewer`,
`repo-maintenance-reviewer`. All receive exact build identity, assigned scoped
review key, bounded paths, accepted criteria and gate budget.

Each follows the common evidence/authority contract, but retains language/specialty
judgment. Queue or parallelize within reviewer/gate limits and isolate mutable
outputs. The coordinator serially publishes each using `agent note` and confirms
the current required scope set; code/test or specialist approvals cannot replace
each other. Use Block/Advise/Escalate and preserve unresolved material findings.

## Fix and delivery

Route fixes to implementers; never fix source in the coordinator. New build IDs
need current language code/test verdicts. Re-dispatch affected specialists; an
unaffected assessment can carry only through a new evidenced current-build
attestation linked to the latest approved review and its recorded build.
No stale approval, hidden downgrade or round-limit waiver.

Integrate serially, verify combined behavior/compatibility/operations and planned
broader checks, then record completion. Product management assesses integrated
phase scenarios as demonstrated/unmet/unverified; code approval alone is not
product acceptance. Actual blocker resolution, not routine reapproval prompts,
governs authorized progress. Preserve identities/history and perform task cleanup.

## Progress and recovery

Follow shared supervision/recovery thresholds. Report stage, command, elapsed time
and fresh evidence; liveness alone is not progress. Confirm stopped writers before
replacement. No silent live-collection migration.

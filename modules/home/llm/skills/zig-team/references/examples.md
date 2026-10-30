# Zig Parallel Delivery Example

Read `mtn-tasks` and protocol v1. The coordinator owns all mtn writes and target
integrations. Planning/build/review workers are bounded leaves. Multiple independent
ready tasks may build concurrently in isolated worktrees with nonconflicting scopes.

Each builder runs focused RED/GREEN, standard build/full suite and records jobs,
source head/tree/spec identity and dispatch ID in a returned v1 build payload.
Four reviewers inspect the same frozen worktree/head; other isolated builders may
continue. Reviewer command outputs/resources must be isolated or checks serialized.
Coordinator publishes all four review payloads serially.

Code/test blockers require a new fix dispatch/build. Reinvestigate affected specialties;
every required specialty provides a current explicit verdict for the new build. Never
mix old build approvals. Scope-changing historical architecture debt requires user
approval; reviewers cannot invent exceptions or silently broaden implementation.

After all four current approvals, coordinator integrates one candidate at a time,
checks the combined revision and records actual target base/integrated commit/tree.
Conflict adaptations require renewed review against the actual adapted candidate.
Only then publish completion and native-complete. Phase-final release checks depend
on all required task integrations, not the highest task number finishing first.

An interruption after three review results resumes the missing fourth; after all
reviews it resumes integration, not another build. Unknown writer state requires
host reconciliation before replacement. Persisted history and requirement coverage
survive phase changes; no automatic archive or migration.

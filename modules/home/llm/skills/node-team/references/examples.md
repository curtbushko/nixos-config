# Node Delivery Example

Read `mtn-tasks` and protocol v1. Approved requirements/design records produce a
phase DAG and task manifests with stable REQ coverage, ownership and prerequisites.
Coordinator selects eligible tasks across ready phases, not just the lowest number.

Task Manager workers return proposals; only coordinator writes the mtn collection.
Independent API and background-worker tasks can build concurrently in isolated
worktrees if contracts are approved and file/resource scopes do not conflict.
Tasks modifying the same package lockfile or schema must serialize or be replanned.

Builders receive exact refs/spec hashes, worktree/base/target and dispatch identity.
They follow ES modules/Zod/component boundaries and TDD, run npm/project gates, commit
only authorized source, and return v1 build payloads. Coordinator publishes and
freezes each candidate for its combined spec-then-quality review.

Review rejection leads to a new build attempt and current explicit review, never
reuse of an old verdict. Approval authorizes serialized integration. Coordinator
runs tests on the combined target revision, publishes v1 integration/completion
evidence and verifies target history before native completion. Dependencies unlock
only after integrated native completion.

Recovery after worker interruption reconciles host state and preserves edits before
replacement. Recovery after approval resumes missing integration. Phase/project
completion requires final combined-revision gates and accepted requirement coverage.
No copied task collections, manual frontmatter edits or unapproved migrations.

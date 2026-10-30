# Worker Contract

Workers read this page and their language/specialty skill—not the coordinator's
entire protocol, scheduling or migration references.

1. Receive parent collection root, exact task ref, semantic hash, isolated checkout,
   base/target revisions, attempt/run IDs, owned scope and verification budget.
2. Read `mtn-workflow --repo "$REPO_ROOT" task "$REF"` for the semantic definition,
   state, outstanding blockers and current-attempt evidence. Query exact refs only; do not load the
   entire collection or unrelated history. Report a stale/missing handoff.
3. Planning workers return proposals. Builders follow TDD within owned scope;
   reviewers inspect the frozen supplied checkout. No worker mutates task records,
   launches teams, integrates, pushes or completes native status.
4. Return the assigned versioned payload, exact source identity and actual required
   gate results. Fixes are new attempts; never invent approval or passing checks.
5. Heavy commands require a coordinator gate slot. Use its CPU/memory/job allocation,
   not the machine-wide CPU/memory total. Report disk pressure; reuse the approved
   pinned Nix environment. Do not create per-worker persistent profiles or run GC.
6. Under Rex, keep the supplied Pi session/run identity. You are a leaf in a named
   window, not another coordinator. Return only the requested JSON payload as the
   final response (no Markdown fences); the launcher saves it as excluded transport.
   Do not publish it yourself. A successful Pi process exit is not task completion.
7. Preserve work on interruption. Report completion/stoppage so the coordinator can
   release reservations and plan safe cleanup. Archiving does not reclaim disk.

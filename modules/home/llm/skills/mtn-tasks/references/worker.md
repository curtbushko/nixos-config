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
4. Return the assigned current-state payload, exact source identity, actual required
   gate results, and exact filenames/refs for detailed output. Do not embed logs,
   prompts, or full task/progress history. Fixes replace current state; never invent
   approval or passing checks.
5. Heavy commands require a coordinator gate slot. Use its CPU/memory/job allocation,
   not the machine-wide CPU/memory total. Report disk pressure; reuse the approved
   pinned Nix environment. Do not create per-worker persistent profiles or run GC.
6. Under Rex, keep the supplied Pi session/run identity. You are a leaf in a named
   window, not another coordinator. Return only the requested JSON payload as the
   final response (no Markdown fences); the launcher saves it as excluded transport.
   Do not publish it yourself or echo task Markdown/tool payloads as progress.
   The launcher streams concise Pi assistant/tool/error activity into the Rex
   terminal. Before its final response, write exactly one protocol JSON object to
   the absolute `MTN_REX_RESULT_FILE` path supplied in the launch prompt. The
   a Pi lifecycle hook requests orderly shutdown only after the completed agent turn
   settles, and the launcher copies only that explicit final payload for coordinator
   validation. It automatically closes successful worker windows; failures remain
   open. Never close Rex resources yourself.
   A successful Pi process exit or closed window is not task completion.
7. Preserve source and referenced artifacts on interruption. Report completion/stoppage
   so the coordinator can release reservations and plan safe cleanup. Completed
   records are compacted to summaries; no archive is required.

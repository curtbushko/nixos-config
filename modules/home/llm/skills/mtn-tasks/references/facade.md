# Shell Workflow Facade

`mtn-workflow` is a Bash tool packaged by Home Manager. Before activation, use
`bash modules/home/scripts/mtn-workflow` from the config repository. Helpers use
Unix tools/jq—not JavaScript or Python. `mtn` must already be installed.

Always pass `--repo "$REPO_ROOT"` pointing to the canonical parent collection
checkout, including from worker worktrees. It never initializes/migrates implicitly.

```bash
mtn-workflow --repo "$REPO_ROOT" status "$REF"
mtn-workflow --repo "$REPO_ROOT" task "$REF"
mtn-workflow --repo "$REPO_ROOT" fingerprint "$REF"
mtn-workflow --repo "$REPO_ROOT" ready "$PROJECT_REF"
mtn-workflow --repo "$REPO_ROOT" paths ./src/parser
mtn-workflow --repo "$REPO_ROOT" budget
mtn-workflow --repo "$REPO_ROOT" disk
mtn-workflow --repo "$REPO_ROOT" cleanup-plan
MTN_WORKFLOW_COORDINATOR=1 mtn-workflow --repo "$REPO_ROOT" publish request.json
```

- `status` is a compact task state plus ALL outstanding blocker IDs.
- `task` includes semantic definition and current-attempt evidence, not unrelated
  history. `snapshot` is the full normalized evidence view for coordinator diagnosis.
- `fingerprint` is the canonical semantic hash, excluding administrative title/order,
  timestamps, execution status and evidence. Ownership paths are filesystem-normalized.
- `paths` resolves aliases/symlinks, permits future in-repository paths and rejects
  escapes/traversal. Conflict comparison conservatively folds case even on Linux;
  case-distinct paths may serialize rather than risk a Mac collision.
- `ready` reads actual project/native graph/approval data, validates metadata and
  manifests, checks completed prerequisite Git trees/target ancestry, and computes
  a safe builder batch. It does not launch agents or infer live host process ownership.
  Reconcile host runs/usage before dispatch; unknown live writers remain reserved.
- `budget` separates stage limits from shared CPU/memory allocations; `disk` reports
  admission headroom. Neither silently starts GC or a new Nix shell.
- `cleanup-plan` reports proposed inspections only; it never deletes anything.
- `publish` validates v1 shape, existing evidence and current semantic fingerprint,
  then delegates the single managed write to `mtn agent note`. Permission marker is
  a role guard, NOT a security boundary or a session lock. Coordinator-only discipline
  remains necessary while the lock proposal awaits approval. Check policy and Git/host
  facts before publication; structured claims alone do not prove commands were run.

Historical imports require actual approval listing existing mtn note intent hashes.
Unclassified text and unsupported/invalid versions fail closed. The facade preserves
original notes and produces non-gating historical views only for explicitly listed
intents; it never auto-approves old reviews. Baseline exemptions need explicit approval,
verification and real target branch/commit/tree before they satisfy prerequisites.

The facade keeps its per-command query cache in memory. It does not create a second
status database or retained profile/log/cache directory per status call. Native mtn
may maintain its own collection cache. Transport JSON is not authoritative; publish
through mtn and preserve only necessary recovery artifacts under an explicit policy.

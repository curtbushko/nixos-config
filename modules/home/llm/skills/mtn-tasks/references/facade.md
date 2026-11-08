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

- `status` is a compact task state plus all outstanding blocker IDs. Its record
  projection is grouped as `identity`, `presentation`, `structure`, `scope`,
  `lifecycle`, `execution`, and `implementation`; active execution bindings are
  exposed under `execution.current.runs`; `state` is retained as a compatibility
  convenience.
- `task` includes the semantic definition and current state, not unrelated history.
  `snapshot` is an explicit normalized diagnostic view; scheduling uses a compact
  current-state projection and does not pass the full view through readiness.
- `route LANGUAGE` reports the supported leaf builder/reviewer contract. The
  supported values are `go`, `node`, `zig`, `lua`, `nix`, and `docs`; Lua/Nix/docs
  use the independent combined source-review gate without Go TDD routing.
- `fingerprint` is the canonical semantic hash, excluding presentation display name,
  structural order, timestamps, lifecycle status, execution bindings and evidence.
  Ownership paths are filesystem-normalized. Existing flat native fields are read through the
  grouped compatibility mapping.
- `paths` resolves aliases/symlinks, permits future in-repository paths and rejects
  escapes/traversal. Conflict comparison conservatively folds case even on Linux;
  case-distinct paths may serialize rather than risk a Mac collision.
- `ready` reads compact metadata/current state and the native graph, validates
  manifests, checks completed prerequisite summary proof and Git ancestry, and
  computes a safe builder batch. `ready-phase` applies the same guards only to one
  selected phase, so unrelated project scopes do not block an explicitly selected
  phase. Neither command loads progress archives, launches agents, or infers live
  host process ownership. Reconcile host runs/usage before dispatch; unknown live
  writers remain reserved.
- `budget` separates stage limits from shared CPU/memory allocations; `disk` reports
  admission headroom. Neither silently starts GC or a new Nix shell.
- `cleanup-plan` reports proposed inspections only; it never deletes anything.
- An authorized Rex handoff may include `collectionRelocation` with the prior run,
  source `.tasks` root, approver, and reason. The launcher uses it only for the
  selected phase; it preserves old evidence while keeping the coordinator and its
  subagents host-sticky. It does not require contact with the previous host.
- `compact` is coordinator-only and applies only to a natively completed task or
  phase with no active runtime reservation. It requires a current-spec summary with
  accepted scope, approval authority, delivered commit/result, actual verification,
  file references, and limitations. It replaces the evidence suffix atomically;
  it creates no archive and does not alter identity, descriptions, memberships, or
  dependencies.
- `publish` validates v1 shape, current semantic fingerprint and current state,
  then delegates the single managed write to `mtn agent note`. Active payloads
  should contain current state and exact file/ref pointers, not full logs or prior
  attempts. Permission marker is
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

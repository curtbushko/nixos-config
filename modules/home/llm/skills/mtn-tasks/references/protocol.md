# Delivery Protocol v1

This is the normative cross-skill contract. Read alongside commands and execution.
mtn is storage/graph infrastructure, not a scheduler, task-claim service, review
authority, or Git integration engine. The coordinator enforces this protocol.
The work-item model is grouped by concern: `identity`, `presentation`, `structure`,
`scope`, `lifecycle`, `execution`, and `implementation`; see `data-model.md`.
The `uuid` field and stable typed work-item ID fields identify records; only executions have
an ephemeral `runID`. Provider resource maps are generic and exact IDs are
authoritative.

## Document model and approval

Use native task records, distinguished by the grouped `identity.kind` field:

| Kind | Path | Meaning |
|---|---|---|
| project | `projects/<slug>.md` | Delivery scope; parent of phases |
| prd | `prds/<slug>.md` | What/why, stable requirement IDs and acceptance criteria |
| design | `designs/<slug>.md` | Optional RFC/design: how, interfaces, risks, alternatives |
| phase | `phases/<project>-<NN>-<slug>.md` | Coherent milestone; parent of implementation tasks |
| task | `tasks/<project>-<NN>-<NN>-<slug>.md` | Independently verifiable delegated TDD unit |

Documents stay outside the delivery progress tree. Link PRD/design refs in prose
and typed `scope.documents:[{ref,hash}]` on phases/tasks. Do not duplicate design
in the PRD. Simple work can explicitly omit a design with rationale recorded in the
approved project plan; material interface/security/persistence changes need a design.
`prd` supplies requirements-writing guidance; `to-prd` synthesizes conversation into
that same document format. `rfc` supplies the optional design. All use mtn writes.
A design-only entry point is supported: put stable REQ IDs and observable acceptance
criteria in its problem/requirements section and approve that fingerprint. Do not
require a duplicate PRD merely to satisfy the workflow. If neither document exists,
capture and approve minimal requirements before implementation planning.

Approval is an `approval` evidence event, not a fabricated native "approved" status.
It identifies the exact document fingerprint, decision, approving user/stakeholder,
and authority/source of the decision. Never invent stakeholder approval or research.
Document native completion can mean document approval, never product implementation.
Changed semantic document fingerprints require impact assessment, not one prompt
per downstream task. At project approval, agree manual or bounded-autonomy mode.
Bounded autonomy can authorize task decomposition, routine fixes and files inside
already-approved ownership; record the actual policy authority in subsequent plans.
Escalate requirements/public contracts/security/persistence changes and scope expansion.
Administrative titles and order do not change semantic hashes. Put editorial suggestions
in non-gating historical/comment evidence and batch approved prose updates at a checkpoint;
do not silently classify a changed requirement as cosmetic to retain approval.

## Requirement traceability

Assign stable `REQ-001`, `REQ-002`, etc. IDs in PRD prose; never renumber surviving
requirements. Each has observable acceptance criteria and required verification.
Design sections reference those IDs and define stable interface IDs where useful.
Phases/tasks use `scope.requirements:["REQ-001"]`; each phase has exactly one
`structure.parentRef` to a project and each task has exactly one
`structure.parentRef` to a phase. Multiple parents are invalid. Descriptions explain
which portion is covered. Tests stay in every implementation task; the user clarifies
strategy and constraints, not whether acceptance behavior needs testing at all.

An approved project plan lists document refs/fingerprints, phase refs/fingerprints,
requirement-to-phase coverage, dependencies, and any explicitly deferred requirements
with user approval. An approved phase plan lists task refs/fingerprints and a
criterion-to-task coverage mapping. Required IDs must have coverage; duplicates are
allowed only for complementary contributions, not double-counted completion.
Missing coverage, ambiguous IDs, unknown refs, duplicate sibling orders, invalid
language/ownership metadata, and stale approved fingerprints block dispatch.
`agent validate` alone does not validate these workflow extensions.

At phase/project completion, trace every accepted requirement to completed tasks
and test/integration evidence. Deferred scope needs explicit approval, not an empty
checklist or silent cancellation. Keep approved manifests as `plan` evidence,
not separate YAML indexes. Plan descriptions may evolve; changes require reapproval.

## Coordinator-only writes

One project coordinator owns scheduling, Git integration, and **all** mutations to
the repository-local collection. Planning/build/review workers are leaves by default.
They read mtn records and return structured requests/results; they do not mutate
records, complete tasks, spawn other teams, or merge branches unless explicitly
assigned that authority. All publication still uses `mtn agent` and is serialized.

The coordinator publishes a planning worker's proposed creates/patches/links, verifies
coverage/graph, and obtains required approval before dispatch. Record write ownership
and active worker identities in dispatch evidence. At most one active coordinator
may own a selected phase at a time. A coordinator may schedule multiple phases, but
phase ownership is local rather than a permanent machine identity. A session-scoped
kernel-lock proposal is in [locking-proposal.md](locking-proposal.md), awaiting
policy approval; no lock or automatic takeover is currently implemented. This
remains an explicit single-owner constraint, not an mtn lease or a security boundary.
Reconcile existing sessions before an explicitly authorized checkout relocation or
ownership transfer. The phase coordinator and its subagents remain host-sticky;
the collection and evidence are portable. Preserve prior runtime evidence without
requiring contact with the old host. On an event-driven host, use automatic
delivery; do not implement polling loops over sessions or logs.

## Parallel-safe task contract

Every task has schema-permitted typed metadata:

```json
{
  "identity": {"kind":"task","taskID":"demo-01-01-parser"},
  "structure": {"order":1},
  "scope": {
    "requirements":["REQ-001"],
    "documents":[{"ref":"prds/demo.md","hash":"sha256:..."}],
    "dependencies":[]
  },
  "implementation": {
    "language":"go",
    "gates":[{"ID":"unit-tests","command":"task test","required":true}],
    "ownership":{
      "paths":["internal/parser"],
      "sharedPaths":[],
      "resources":[],
      "interfaces":[]
    }
  }
}
```

Paths are normalized repository-relative literal files/directories (no globs,
absolute paths, traversal, or symlink escapes). Directory ownership includes all
its descendants; `.` owns the repository. `sharedPaths` are files the task expects
to modify despite broader shared responsibility, such as lockfiles or build wiring;
they are exclusive reservations, not permission for simultaneous editing.
`resources` names exclusive build/test resources (database, fixed port, output dir).
`interfaces` names contracts the task will change; consumers of an already-approved
immutable interface identify that input in prose without reserving it exclusively.

The description states expected deliverable, allowed edits, interface inputs/outputs,
prerequisites, TDD scenarios, verification, integration checks, and final-phase gate
responsibility. A task may not broaden its ownership without replanning. Unknown
ownership means serialize or clarify. Disjoint files alone do not prove independence:
shared interfaces, schemas, generators, dependency manifests, and test resources matter.
Use explicit prerequisites for producer/consumer contracts. After a contract is agreed
and recorded, independent consumers can proceed in parallel if source inputs exist.

Phases are milestones, not arbitrary agent-sized chunks. Tasks are primary execution
units. Different ready phases may overlap; a Task Manager can plan each independently,
but one project coordinator still schedules the entire graph and publishes changes.
Mixed-language projects select worker/reviewer skills per task language, not per project.
Supported languages are `go`, `node`, `zig`, `nix`, `bash`, `lua` and `docs`.
Go/Node/Zig use their language developers and separate customizable code/test
reviewers. Nix/Bash repository implementation uses `repo-maintainer` plus its
language-specific code/test reviewers. Existing Lua/docs source-only routing uses
the shared contract, without importing Go framework/command mandates.

Each NEW task records approved `implementation.reviewPlan`: materially affected
languages with bounded paths and explicit required/reason entries for architecture,
security, usability and maintenance. See [review plans](../../delivery-coordinator/references/review-plans.md).
Planning roles shape accepted constraints before coding; matching reviewers assess
implementation independently. New scope and changes to the review plan follow
the existing approval-impact process. Review-plan fields participate in specHash;
their omission from an old record remains historical compatibility, not authority
to bypass the new planning contract.

## Dependency-ready scheduling

1. Discover all incomplete phases, not just the first numbered phase. Check document
   and project-plan approvals, native dependencies, diagnosed statuses, and blockers.
2. Obtain/approve task plans within the project's actual approval policy. Prefer
   task-level prerequisites for individual deliverables; add a phase dependency only
   for a genuine whole-milestone barrier. Check BOTH where phase edges exist; parent
   prerequisites are not inherited by task readiness queries.
3. Build the eligible task set from every ready phase. Filter kind, actual membership,
   language, native status, current plan/spec approval, blockers, existing sessions,
   and activity eligibility. Null `agentEligible` is not an approval or a claim.
4. Prefer lower phase/task `structure.order` only among eligible candidates; it is not
   a barrier. Choose a maximal safe batch within configured concurrency/resource limits
   using ownership/interface conflicts. A greedy deterministic batch is acceptable;
   maximizing theoretical parallelism is not worth unsafe scheduling.
5. Reserve each selected scope by publishing `dispatch` evidence BEFORE launch.
   Include the expected run ID; after launch, reconcile the host-assigned identity.
   Coordinator transitions task/phase/project to a diagnosed native in-progress value
   when available; otherwise retain an incomplete value and expose stage via evidence.
   Never invent statuses. A crash between reservation and launch requires inspection,
   not duplicate launch.
6. On completion events, publish results, advance the state machine, and refill free
   slots. A blocked low-numbered phase must not starve a later independent ready phase.

Use separate builder/reviewer/heavy-gate/integration limits and a single global
CPU/memory/disk budget from [resources.md](resources.md). Reservations still protect
source/resources during review, but do not occupy builder slots when no builder runs.
Resolved blocked builds enter retryable; fixing/interrupted/retryable work can reserve
a new attempt only after confirmed old-writer stoppage. Never duplicate a live attempt.
Fall back to serial if isolation/interfaces/resources are unknown.

## Worktree handoff and frozen review

Each independent writer starts from a committed integration-branch revision in its
own worktree/branch. Record collection root, repository root, target branch, base
commit, branch, worktree path, run ID, task spec fingerprint, attempt, owned scope,
verification commands, and commit policy. Uncommitted parent edits are not copied.
For unrelated dirty implementation files in the target checkout, stop and ask how
to preserve/isolate edits. Expected coordinator-owned `.tasks/` changes do not make
source dirty: checkpoint metadata separately and never stash, overwrite or include
it in worker/integration source commits. Validate clean source scope explicitly.

Workers do not copy or initialize task collections. Use the supplied parent collection
root for read-only queries; do not commit stale copied task records from a worktree.
Worker commits contain only authorized implementation files; exclude `.tasks/` state.
Record the exact commit and tree IDs with `git rev-parse HEAD` and `HEAD^{tree}`.
After build completion, stop writes to that worktree while it is under review.
Reviewers receive that worktree path/base/head/tree/spec identity and inspect the diff
against its base, not whichever checkout happens to be current. Other disjoint workers
may keep running in their own worktrees. Fixes create a new dispatch/build attempt.

## Integration before completion

Review approval authorizes integration, not task completion. Only the coordinator:

1. Confirms all required approvals match the latest build ID, spec fingerprint,
   head, and tree; confirms the worker stopped writing and the branch is clean.
2. Verifies the worker diff is inside approved scope and leaves task records untouched.
3. Creates a speculative integration branch/worktree from the current target head
   and applies one approved result there. Record the actual target base. Do not
   advance the target branch yet; never push/deploy without separate authorization.
4. Resolves conflicts explicitly. Any conflict resolution or integration adaptation
   creates a new review candidate; rerun affected reviews and checks against that exact
   candidate. Do not reuse branch approval for semantically changed resolution.
5. Runs task integration checks on the combined candidate. Failure leaves target
   history unchanged, the task incomplete and dependents blocked; preserve the failed
   candidate/evidence. On success, recheck that the target head still equals the recorded
   base and fast-forward it to the verified candidate. If it moved, form/recheck a new
   candidate instead. Do not reset, overwrite, or claim an unintegrated commit was delivered.
6. Appends an `integration` event naming build/review IDs, target base/branch, integrated
   commit/tree, checks, and outcome. Verify the commit actually belongs to target history
   (`git merge-base --is-ancestor <integrated-commit> <target-head>`) before completion.
7. Appends a `completion` event referring to that successful integration, then uses
   `agent complete`. If interrupted between these writes, inspect history/evidence and
   finish idempotently; native status alone is not proof of reviewed delivery.

Checks on individual branches do not replace checks on the combined implementation.
Phase-final/release checks run after all required changes are integrated. Record a
v1 `milestone` or final `summary` with completed child refs, accepted coverage,
target commit/tree and actual validation results before native-completing a nonempty
phase. After completion, compact the phase to its summary. Project completion
likewise requires a milestone/summary with all phases and project-wide acceptance
gates.

## Current delivery state and completion summaries

Active records contain only the current state needed for coordination: exact refs,
small verification results, blockers, approvals, delivery identities, and pointers
to files containing detailed output. Workers do not inject prompts, full task prose,
logs, or prior attempts into records. A completed task or phase contains one compact
`summary` event; `mtn-workflow compact` removes the prior evidence suffix only after
completion and delivery proof have been checked.

Each current protocol note contains a JSON object serialized as `agent note` **content**:

```json
{"schemaVersion":1,"eventID":"demo-task-01/build/2","kind":"build","recordRef":"tasks/demo-01-01-parser.md","specHash":"sha256:...","attempt":2,"dispatchEventID":"demo-task-01/dispatch/2","head":"git-commit","tree":"git-tree","outcome":"ready-for-review","validation":[{"command":"task test","result":"pass"}]}
```

Common keys: `schemaVersion`, unique `eventID`, `kind`, exact `recordRef`, `specHash`,
and positive integer `attempt`. Include operator/worker attribution and source of
claims, but note attribution is not authenticated. Note retry key equals eventID;
retry an identical payload only. New content/revision/verdict requires a new eventID.
Use `category` corresponding to kind (`approval`, `plan`, `dispatch`, `build`, `review`,
`integration`, `completion`, `milestone`, `blocker`, `resume`, `release`, `runtime`,
`summary`). Fixes replace current state with a new attempt; they do not require a
permanent progress archive.

Per-kind fields:

- approval: `decision`, approving authority, requirement IDs, actual decision evidence.
- plan: `decision:"approved"`, nonempty `records:[{ref,specHash}]`, document hashes,
  coverage mapping, dependency refs, actual user approval evidence.
- dispatch: `runID`, `baseCommit`, `branch`, `targetBranch`, absolute `worktree`;
  allowed scope/commands. A host-assigned identity returned after launch belongs
  in subsequent build/release evidence; the reserved run label remains immutable.
- runtime: Rex/Pi locator evidence, as defined in [Rex/Pi execution](rex.md).
  Common event keys plus `stage` (reserved or launched), `runID`, `role`, `skill`,
  `worktree`, exact `model`/`thinking`, `piSessionID`, `host` (endpoint/hostID/instanceID),
  `rexSessionName`, `rexWindowName`, `piSessionName`, `transportDir`. The Pi
  session ID remains the immutable canonical `runID`; coordinator display names
  are simply `coordinator`, while worker display names are scoped labels. Display
  names are presentation only and never Rex resource selectors. Rex-generated
  resource IDs stay separate. Keep `sessionName`/`windowName` as
  matching compatibility aliases;
  old runtime events lacking the explicit names remain valid and are not rewritten.
  Coordinator entries require `handoff:true`;
  workers identify `phaseRef` and `coordinator.runID`; builders/reviewers also identify the
  governing `dispatchEventID`. Launched entries add full `rexSessionID`, `rexWindowID`,
  `rexBlockID`. Reserve BEFORE creation and append returned IDs BEFORE Pi startup.
  Store coordinator runs on the phase, worker runs on their task (planners on the phase).
  Never include prompts or credentials. These events do not change task state,
  approval, spec fingerprints, prerequisites, or completion; release still requires
  confirmed stopped/finished process evidence, not a guessed runtime flag.
- build: `dispatchEventID`, `head`, `tree`, `outcome`, validation command/results,
  files/tests, RED/GREEN evidence, limitations; outcome is ready-for-review or blocked.
- review: `buildEventID`, identical `head`/`tree`, required `reviewer`, verdict,
  `changes_required`, criterion evidence, independent validation, nonblocking suggestions.
- integration: `buildEventID`, reviewed `head`/`tree`, exact current `reviewEventIDs`,
  `targetBranch`, `targetBase`, validation and outcome. Success names actual
  `integratedCommit`/`integratedTree`; failure names preserved `candidateCommit`/
  `candidateTree` and failed checks, without claiming it entered target history.
- completion: `integrationEventID` of the accepted successful integration.
- milestone: nonempty completed child `records`, `targetCommit`, `targetTree`,
  requirement coverage and passing combined-revision `validation`; used for parents.
- historical: original `content`, `provenance`, `gateEligible:false`. To authorize
  existing plain mtn notes, include explicit `legacyIntents`, `approvedBy` and
  `decisionEvidence`; the facade preserves them as non-gating views, not approvals.
- baseline: explicitly approved historical delivery exemption, targetCommit/targetTree/
  targetBranch, passing verification, approvedBy/decisionEvidence, reviewEquivalent:false.
  Never imply it was reviewed under the new protocol; verify target history before use.
- blocker: concrete `reason`, affected refs, required human decision/recovery.
- resume: exact `blockerEventID`, resolution evidence and authorization. ALL unresolved
  blockers survive spec changes; resolving a later blocker does not resolve earlier ones.
  Blocked builds can reference `blockerEventIDs`; otherwise their own build ID is an
  implicit blocker. Resolve reported IDs explicitly, then retry as a new attempt.
- release: `dispatchEventID`, outcome stopped or finished, confirmed host/process evidence.
- summary: `summaryVersion:1`, `status:"complete"`, accepted scope, requirement IDs,
  approval authority summary, `targetCommit`/`targetTree`/`targetBranch`, actual
  passing verification commands/results, exact artifact/source file refs, and
  outstanding limitations. Phase summaries additionally contain exact completed
  child refs.

APPROVED requires zero blocking findings and passing required independent validation.
New review plans require a separately keyed code/test pair for every materially
affected language, plus triggered specialist scopes. Keys such as `go:code` and
`bash:test` prevent one language's verdict overwriting another's. New candidates
need current verdicts; specialist carry-forward is a new current-build attestation
with `carriedForwardFrom`, `carryForwardRationale` and scope/assumption evidence.
The prior latest approved review and its build must be available. Existing completed
summaries remain proof; inspect/replan active legacy work without rewriting history.
No old unqualified or combined verdict can satisfy a declared scoped plan. A later negative
review supersedes that specialty's earlier positive verdict for the same build.
All required reviewers approve the same current build; no mixing attempts.

Fingerprint the immutable specification as SHA-256 of canonical JSON containing
exact ref, description, kind/language, requirements, document fingerprints, canonical
ownership, gate definitions, memberships and prerequisites. Administrative title/order
are excluded; use the facade's canonical implementation instead of hand-building hashes. Use diagnosed field mappings to normalize
native links/statuses; exclude evidence, timestamps, native execution status, and
completion dates. For documents hash ref/kind/description only. The `revision`
returned by mtn includes mutable record state; it is not this stable spec fingerprint.
Generate canonical JSON with `jq -S -c`, then `shasum -a 256` (or sha256sum). Never
edit content to force a fingerprint match. Current-state replacement and summary
compaction must not change specHash.

## Recovery state machine

Derive state from compact current-state entries for the current record/spec
fingerprint, not timestamps, English status names, or a second status file. A
completed summary is the sole delivery proof retained after compaction:

| Evidence | Derived state | Next action |
|---|---|---|
| Approved task plan, no dispatch | planned | Consider for safe batch |
| Dispatch, no build/release | building | Reconcile host run; do not launch duplicate |
| Confirmed stopped dispatch, no build | interrupted | Preserve work and create new attempt only after inspection |
| Current passing build, missing required approvals | reviewing | Dispatch missing required reviewers |
| Current review has blockers | fixing | New isolated fix attempt; invalidate old approvals |
| All current required approvals | awaiting-integration | Serialized integration |
| Matching successful integration | integrated | Verify target history; record completion and lifecycle |
| Completion references integration | complete | Write a concise summary, compact after workers stop, then reconcile native status |
| Summary with verified delivery | complete | Reconcile native status; unlock dependencies from the summary |
| Any unresolved blocker across spec revisions | blocked | Resolve each reported ID explicitly |
| Blocked build with all blockers resolved | retryable | Confirm stopped writer, reserve new attempt |
| Approved historical baseline, no newer work | baseline | Verify native completion and target history |
| Historical notes | Non-gating | Preserve provenance; never turn them into current approval |

On resume, validate events and unique IDs, reconcile host sessions, Git worktree state,
current plan/doc fingerprints, and target history before acting. A blocked build
becomes retryable after explicit resolution of ALL linked/implicit blocker IDs.
A retry uses a new dispatch/build attempt; it does not mutate old evidence. A source/spec change requires replanning
or a new attempt; never infer a crashed writer is dead from missing output. A completed
native task without matching integration/completion evidence is an inconsistency to
investigate, not a ready prerequisite. Reopening delivery work requires reopening affected
ancestors and reassessing already-completed dependents and document/plan approval.

## Read-only guard library

`scripts/workflow.jq` provides minimum event-shape checks, revision-bound task-state
reduction, approval/plan coverage checks, ownership conflicts, and deterministic
safe-batch selection. `metadata_valid` takes `{requirements,records}`; each normalized
record has ref/kind, resolved `parentRef`, order, language, requirements, documents
and ownership. Normalize parents using hierarchy's `parents[].resolution.ref`, not
raw wikilink parsing. It rejects unknown kinds/languages, missing parents/documents,
including languages outside `go`, `node`, `zig`, `nix`, `bash`, `lua`, and `docs`.
invalid ownership/requirement IDs and duplicate sibling orders. `document_approved`
uses `{ref,specHash,events}`.
`plan_approved` additionally takes `documents` (current document snapshots), `records`
(current direct children with ref/specHash/requirements), and accepted `requirements`;
its current approved plan event must match all fingerprints and cover every ID. It never
writes, launches agents, authenticates claims, verifies Git objects, or replaces human
approval/semantic review. Use `jq -L <skill>/scripts 'include "workflow"; task_state'`
on an ephemeral `{ref,specHash,language,events}` snapshot derived from `agent show`.

`ready_batch` accepts `{limits,usage,active,candidates}`; legacy `maxParallel` maps
only to builder slots. Limits separate builders/reviewers/gates/integrations. Usage
comes from reconciled live host facts; ownership reservations are not worker counts. Candidate fields are `ref`,
`phaseOrder`, `order`, normalized `incomplete`, `statusAllowed`, `dependencyReady`,
`phaseReady`, `documentsApproved`, `planApproved`, `state`, `agentEligible`, and ownership.
Derive booleans from current mtn queries, approval events and diagnosed mappings—not
manual assertions saved as another database. `dependencyReady` requires both native
readiness AND verified delivered prerequisite states/target ancestry; native completion
without protocol evidence is an inconsistency to investigate, not an automatic unlock. Check approvals, coverage, unique orders,
parent membership, specification hashes and host ownership before normalization.
Normalize the selected project's records and referenced documents, not unrelated
projects with different accepted requirement IDs. `active` includes all outstanding
scope/resource reservations through review/integration, not just running processes.
Malformed JSON/unsupported events fail closed. Legacy unversioned history needs explicit
migration/interpretation; do not silently discard it to produce a clean state.

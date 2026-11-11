# Shared Team Execution

Read `mtn-tasks`, [protocol v1](protocol.md), and [commands](commands.md) completely.
The protocol is authoritative for document approval, readiness, ownership, evidence,
integration and recovery. Language references supply quality gates, not a different
storage or completion model. This is coordinator context only; workers read their
short role contract and exact handoff. Prefer the Bash `mtn-workflow` facade to
hand-assembling fingerprints, snapshots and readiness inputs. Automation is shell,
not JavaScript or Python.

## Pi execution transport

For `go-team`, `node-team`, and `zig-team`, use [Rex/Pi execution](rex.md)
for the initial coordinator handoff and every worker launch. A new coordinator
runs in the worktree-named Rex session; its caller stops coordinating. All child
agents are separate Pi processes in named windows of that same session on the
execution host. Runtime locators are mtn evidence, not a second workflow store.
The execution and completion rules below remain authoritative.

## 1. Discover, approve, resume

Run preflight. Resolve project and optional phase/task refs; clarify ambiguous numeric
arguments within their parent. Discover ALL phases and tasks through native graph and
metadata queries, not one active-phase pointer. Confirm PRD/design fingerprints and
approved project/phase plan manifests, criterion coverage, unique sibling orders,
required language and valid ownership metadata. `agent validate` is necessary, not
sufficient to certify workflow metadata or review approval.

An invoked team supplies the default language. In a mixed-language project, use each
task's explicit language and corresponding builder/reviewer skills. Do not overwrite
metadata to fit the invocation. Explicit phase/task selection narrows scheduling but
never bypasses dependencies or approvals.

Read the compact current state and derive the protocol state. Reconcile active host
runs, worktree branches/heads, native status, plan/spec fingerprints and delivered
summary proofs. Missing current state means unfinished work, not implicit approval.
Do not delete records, renumber completed work, or compact an active task/phase.

## 2. Document and Task Manager handoffs

The invoking top-level agent acts as coordinator for document/planning skills. It
publishes approved document and planning mutations using mtn. Delegated researchers
and planners are read-only proposal workers unless explicitly assigned coordinator
authority; they never start their own teams.

Supply a planning worker with absolute collection/repository roots, exact phase and
project refs, approved PRD/design refs/hashes, allowed exploration scope, language
context, and required output contract. The worker reads descriptions through mtn,
explores architecture/tests and proposes:

- exact create/update requests for task specs and typed metadata
- native memberships and explicit dependency edges, after targets exist
- rationale and requirement/criterion-to-task coverage
- expected deliverables, owned/shared paths, exclusive resources/interface changes
- immutable interface inputs and producer/consumer dependencies
- RED/GREEN/refactor scenarios, exact gates, integration checks and final-phase gates

Tasks have one coherent concern, independent acceptance criteria and a reviewable
diff. Every implementation task owns its TDD cycle; do not separate tests from code
into independently completable tasks. Phase boundaries are delivery milestones;
multiple tasks/ready phases can be assigned to independent agents.

Coordinator checks the proposal, publishes mutations serially, validates graph AND
workflow metadata, applies the project's actual manual/bounded-autonomy approval
policy, and appends the fingerprinted `plan` event with task manifest/coverage. Existing partially-created records are inspected
and reused, not recreated. No work starts from an unapproved/stale task plan.

## 3. Dependency-ready scheduling and dispatch

Select eligible phases by dependencies, approval and status; then eligible tasks from
all ready phases. Phase/task order is only a tie-breaker. Use the protocol safe-batch
rules and optionally `scripts/workflow.jq` over current normalized query snapshots.
Check task prerequisites; phase edges are reserved for genuine whole-milestone
barriers, not every producer/consumer handoff. Check ALL unresolved blockers, host
run ownership, activity policy, document/spec hashes and canonical path/resource
conflicts. The facade checks schema/approvals and delivered prerequisite Git proof;
reconcile host runs before launch, because the kernel session lock is not enabled.

The coordinator is the only collection writer, but several independent builders may
run in isolated worktrees. Parallel source edits are safe only with approved disjoint
scopes and interfaces. Use separate builder/reviewer/gate limits and shared resource allocations. Reviewing
reservations protect scope without consuming idle builder slots. If isolation/capacity
is unavailable, serialize and explain;
do not remove prerequisite edges to increase concurrency.

Before launch, append the `dispatch` reservation and prepare a dedicated branch/worktree
from a committed target base. Pass: exact collection/task/phase refs, repo/worktree
path, target branch, base/head identity, attempt/run ID, spec fingerprint, allowed scope,
interface inputs, required skills, commands, expected payload and commit policy.
Uncommitted parent changes are not copied; dirty targets require preservation decisions.
Workers exclude `.tasks/` from implementation commits and never push/merge/deploy.

Use exact authenticated models and explicit thinking where supported: fast for bounded
recon, mid for ordinary work, frontier for architecture/security/hard diagnosis. Prefer
a different model family for ordinary independent review; otherwise use a fresh context
and disclose the limitation. Never claim cross-family verification without it.

## 4. Build, review, fix

Workers read task specs and existing evidence via mtn, but return protocol payloads
through host delivery. The coordinator validates and serially publishes them using
`agent note`; all protocol events use v1 and immutable retry IDs. A large payload may
use an excluded `.mtn-tmp` transport file; it is not an authoritative result store.

A build identifies dispatch, exact commit/tree/spec, files/tests, RED/GREEN/full-suite
checks and limitations. Coordinator confirms worker state/scope, publishes the build,
and freezes THAT worktree for review. Other disjoint workers may continue elsewhere.

Reviewers inspect the supplied worktree/base/head/tree, acceptance criteria, and current
build evidence. They never modify source/managed records or run overlapping mutable
checks in the same directory. Isolate reviewer build outputs/resources or serialize
those checks while retaining independent review contexts. Use the approved review plan's distinct language code/test scopes and triggered
specialist scopes. Include materially affected embedded code, not just the primary
language. Match every required verdict to the same build.

Coordinator publishes every full review payload; a two-line verdict is insufficient.
Missing/stale/negative verdicts block integration. Reconcile conflicting findings;
scope-changing fixes require user approval. Fix workers read published findings and
produce a new dispatch/build attempt. All required reviews must cover that new build;
never combine approvals across builds. Reuse reviewer context if supported, but obtain
new explicit verdicts. Unaffected specialist carry-forward requires a current-build
attestation with prior review/build linkage and scope/assumption evidence. No silent
waiver or downgrade; Block/Advise/Escalate govern findings. Maximum 10 fix cycles
before user escalation.

## 5. Integrate, verify, complete

Only the coordinator prepares approved work, one result at a time, in a speculative
integration worktree based on the target branch specified in the handoff. Check clean worker status, owned diff, current
spec and all required approvals. Record the actual target base. Conflict resolutions
or semantic adaptations create a NEW review candidate; rerun affected reviews/gates.
Do not silently approve integration changes yourself.

Run task integration checks on the COMBINED candidate. Failure preserves the candidate
but leaves target history unchanged and dependencies blocked. After success, verify
target head still matches the candidate base and fast-forward; otherwise recheck a
new candidate. Append versioned `integration` evidence, verify target ancestry,
append `completion`, then
`agent complete`. Only integrated, native-completed tasks satisfy dependency scheduling. Use the
coordinator-only `mtn-workflow complete TASK_REF` facade to mark a task complete;
it verifies delivery and removes only clean, stopped Git worktrees recorded for
that task. Dirty, live, or unrecognized worktrees remain for investigation.
If native status and versioned evidence disagree, investigate rather than trusting one.

### Task cleanup

The coordinator must clean up after each delivered task, not just at phase completion.
Successful integration or native completion is not proof that cleanup happened.

1. Inventory the task's worker windows and worktrees from dispatch/runtime evidence,
   including earlier attempts and any task-only integration worktree. Confirm all
   consumers (builders, reviewers and checks) stopped; a quiet terminal is not proof.
   Preserve the reviewed revisions, final results and durable delivery evidence.
2. Verify successful worker windows auto-closed. If a stopped worker window remains,
   inspect its persisted endpoint/host/server instance and exact session/window IDs,
   then close only that owned worker window with Rex's `window close` command. Never
   select by display name, close the coordinator/session, or close unrelated panes.
   Failed/blocked windows remain for recovery unless separately authorized.
3. Publish normal runtime `release` evidence for each confirmed-stopped run, covering
   every runtime reservation/launch event required by the facade. Include actual
   process evidence; window disappearance alone does not prove the worker stopped.
   Do not release a live run merely to make cleanup pass.
4. From the collection checkout, outside the disposable worktree, run
   `mtn-workflow --repo "$REPO_ROOT" complete "$TASK_REF"` after delivery evidence is
   valid. This is required even if the task is already natively complete: retrying
   the facade verifies delivery and finishes pending worktree cleanup. Remove only
   recorded, clean, stopped task worktrees with no remaining consumers. For a
   task-only integration worktree not recorded by the facade, verify target ancestry,
   ownership and clean status before using non-forced `git worktree remove` on its
   exact path. Never remove the collection/target checkout or a shared worktree.
5. Verify both the worker window and worktree are gone using Rex inspection and
   `git worktree list`; check the removed worktree path no longer exists. Record
   cleanup results or exact retained IDs/paths and reasons in the task summary.
   Already-absent resources are a successful no-op only after reconciling ownership,
   process state and saved results; they never authorize relaunch.

Do not force cleanup, discard dirty/untracked files, delete branches, prune unrelated
worktrees, or delete transport/results/Pi sessions/runtime history. Dirty, live,
shared, failed or unrecognized resources must be preserved and reported with the
smallest recovery action needed. Do not claim cleanup succeeded when resources
remain; continue unrelated ready work when safe. Routine cleanup of eligible owned
task resources needs no additional approval; destructive/global maintenance does.

Run phase-final gates after ALL required task integrations, against the combined target
revision. Query nonempty hierarchy and check requirement coverage before explicitly
completing a phase. Product management supplies scenario-level actual workflow/E2E
evidence on that revision, with outcomes demonstrated/unmet/unverified. Code approval
alone is not product acceptance. Project completion requires all planned phases, project-wide tests
and accepted requirement coverage. Write the final summary, compact completed records
after workers stop, then run disk/cleanup planning and inventory retained worktrees,
environment roots and caches. Request approval for destructive/global maintenance.
No automatic Nix GC or generation deletion. Preserve source and referenced artifacts;
no archive or manual counter is required.

## 6. Supervision and recovery

Use host-native automatic completion delivery where available; never poll session/log
files or repeatedly list agents on event-driven hosts. Otherwise use supported bounded
wait APIs. Keep scheduling while unblocked work remains; report meaningful progress
roughly every five minutes (Zig long-running work: two minutes), including exact stage,
command, elapsed time and fresh output. Process liveness alone is not progress.

After 10 minutes without progress, inspect through supported tools. After 15 minutes,
request cancellation/interruption and CONFIRM the writer stopped before replacement.
Preserve changes, worktrees and referenced artifacts. Retry at most three times for
one recoverable condition; then report the concrete blocker. Do not compact active
records or records with live writers. Host delivery failure does not prove an mtn
mutation failed: inspect current-state identities before publishing again.

Recovery follows protocol states, not guessed native status names. Resume missing
reviews, retry unintegrated approved work, or finish integration/completion publication
idempotently. A crashed reservation never authorizes duplicate launch. Changed spec/
document hashes invalidate plans/attempts; obtain impact decisions and reapproval.
Resolve every reported blocker ID explicitly, including implicit blocked-build IDs;
resolution makes a stopped blocked build retryable. Blockers survive spec changes.
Historical notes and approved baseline exemptions use explicit non-gating/waiver
formats; do not silently discard them. Reopening tasks explicitly reopens affected
completed ancestors and reassesses already-completed dependents. No test weakening, fabricated approval, or schema bypass is allowed.

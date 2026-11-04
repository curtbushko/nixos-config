# Rex / Pi Team Execution

Use this transport for `go-team`, `node-team`, and `zig-team`. Every agent runs
in Pi. mtn remains the sole workflow/evidence authority; Rex provides visible
sessions, windows (tabs), and terminal blocks. Read the shared execution contract
as well: this transport does not replace approval, resource admission, review,
or integration checks.

## Layout and execution host

- Use one Rex session per project execution/orchestration worktree, NOT per phase.
  Its label is `<project>-<worktree>`, for example `rex-whichkey-main`. The launcher
  derives the project from the common Git directory and the worktree from its
  directory name; a non-linked project checkout uses just its project name.
  Normalize both to lowercase ASCII letters/digits and single hyphens; trim outer
  hyphens. For example `Demo Project` / `Feature Worktree` becomes
  `demo-project-feature-worktree`. No spaces, underscores or punctuation in new labels.
- The coordinator occupies the initial Rex window, displayed simply as
  `coordinator`. Its immutable internal run ID remains
  `<project>-p<NN>-coordinator-a<NN>` and retains phase/attempt identity.
  Its phase is the anchor phase at startup; keep that identity when scheduling
  later phases. Never rename/reidentify a live coordinator to imply a fresh run.
- Every worker occupies a new Rex window in that same Rex session, named
  `p<NN>-t<NN>-<agent>-a<NN>`, for example
  `p01-t01-builder-a01` or `p01-t01-reviewer-a01`. The prepared worker
  worktree directory basename MUST be the same scoped display name, without the
  project prefix (for example `p01-t01-builder-a01`, not
  `rex-whichkey-p01-t01-builder-a01`). The launcher rejects a mismatched worker
  worktree name. Builders use `builder`; reviewers use their skill without its language prefix:
  `go-reviewer` becomes `reviewer`, `zig-code-reviewer` becomes `code-reviewer`.
  Numbers come from the stable numeric segments in phase/task refs, not
  `structure.order`, and the attempt is zero-padded to at least two digits. They are
  labels, not prerequisite edges. For an unnumbered ref, the request must provide
  explicit positive `phaseNumber` and/or `taskNumber`; the launcher never falls
  back to scheduling priority.
- Phase planners use `p<NN>-planner-a<NN>`, for example
  `p01-planner-a01`, and attach evidence to their phase. Each worker's
  phase prefix is its actual phase, not the coordinator's anchor phase.
- For every NEW run, `runID` and `piSessionID` MUST be the same canonical agent string:
  `<project>-p<NN>-t<NN>-<agent>-a<NN>` for task workers, or
  `<project>-p<NN>-<role>-a<NN>` for coordinators/planners. Coordinator
  `piSessionName` and `rexWindowName` are `coordinator`; worker display names
  remain scoped labels. Display names are not identity or resource selectors; the Rex session
  already supplies that context. Supply the full canonical `runID` in launch
  requests and dispatch evidence; the launcher rejects a mismatched scope/name
  before reserving a run or creating Rex resources. Do not silently change the
  run ID after publication. Each Rex window runs one Pi conversation; phase
  transitions do not create another Rex session or coordinator Pi conversation.
- Coordinator execution stays on the host containing its checkout. When invoked
  in a remote shell, run the launcher **there**, not on the viewing Mac. Rex must
  have a running local server there. `request.server` can explicitly select its
  Unix endpoint if Rex's default points at a home/remote server. The launcher
  rejects network transports before publication and pins endpoint, host ID and
  server instance for all workers. It never falls back to the local Mac.
- Worker paths must be checkouts of the same Git repository on that host. A
  worker worktree basename matches its Rex/Pi display name; do not prefix it with
  the project name. Builders use prepared isolated worktrees; reviewers use the
  frozen revision.

Rex CLI and Pi must already be installed on that execution host. Nix installs
`mtn-rex` with `ns.scripts.enable`; it does not install Rex or activate this
configuration itself. Before activation, put the repository's script directory
on PATH and run both helpers through Bash wrappers if they are not executable.

## Identity contract

### Provider contract

`RunID` is the immutable identity of one execution attempt. It is not the task's
stable ID and is never derived from a display name for lookup. A runtime binding
uses the generic provider shape:

```json
{"provider":{"name":"rex","displayName":"p01-t01-builder-a01","resources":{"session":"session:...","window":"window:...","block":"block:..."}}}
```

The provider owns resource meanings and reconciliation. `displayName` is
presentation only; selectors use exact provider resource IDs. The current Rex
adapter also emits these compatibility aliases:

| Compatibility field | Meaning |
|---|---|
| `runID`, `piSessionID` | Canonical execution ID and Pi session ID |
| `rexSessionID`, `rexWindowID`, `rexBlockID` | Provider resource IDs |
| `rexSessionName`, `rexWindowName`, `piSessionName` | Provider/display labels, never identity or selectors |

Historical runtime events without `provider` remain readable and are not rewritten.
Rex-generated IDs stay distinct and authoritative; never use a display label as a
resource selector or pass a Rex resource ID to a Pi conversation selector.

## Initial handoff: exactly one coordinator

The caller resolves the collection, exact project/phase/task selection, approved
scope and orchestration checkout. If selection spans several phases, anchor the
run in its first selected dependency-ready phase and preserve the full selection
in the handoff; this is still **one active coordinator per selected phase**, not
one writer per task. A single coordinator may schedule multiple phases, but phase
ownership is local and may be explicitly transferred during an authorized checkout
handover. Do not change the team's existing dependency-ready scheduling semantics.

1. Inspect existing phase runtime notes across the collection and reconcile any
   coordinator already present. A saved locator or a quiet terminal is not proof
   of stoppage. Do not launch a replacement for a disconnected/live coordinator.
2. Ensure `.mtn-tmp/` is Git-ignored and excluded from collection discovery per
   the existing collection policy. The launcher refuses to create unignored or
   symlinked transport directories. Never initialize another collection.
3. Prepare a self-contained handoff: absolute collection checkout, selected refs,
   approval/plan identities, target branch, worktree, commit policy, outstanding
   decisions, environment and resource allocations. Do not transfer only a vague
   conversation summary. Choose an authenticated exact model and thinking level.
4. Explicitly relinquish scheduling/integration/collection writes after this
   launch. The caller temporarily uses `MTN_WORKFLOW_COORDINATOR=1` to publish the
   handoff locators, then stops coordinating. It does not dispatch workers itself.
5. Invoke `mtn-rex --repo "$REPO_ROOT" launch REQUEST.json`. The helper appends a
   `runtime/reserved` note to the phase, creates the session/window, appends
   `runtime/launched` with full returned IDs, and reads it back before opening
   the child's startup gate. A bounded 60-second gate keeps Pi from writing
   while its caller is publishing. Publication failure leaves the gate closed.
6. The new Pi receives `MTN_REX_COORDINATOR_RUN`, `MTN_REX_ROLE=coordinator`,
   its exact full `--session-id` and short display `--name`, plus a `Runtime identity` prompt
   block containing the persisted returned Rex IDs, explicit names and host identity.
   Its Rex resources and Pi conversation ALREADY EXIST at this point. Do not create
   them again or recurse into another coordinator handoff. Check `MTN_REX_REPO`
   matches this collection; reconcile the persisted launch before the execution loop.

The helper checks unreleased coordinator reservations on the selected phase. An
explicit `collectionRelocation` request may transfer phase ownership to a new
host after user authorization; it preserves the old runtime evidence and does not
require contacting the old host. The transfer must name the prior run, source
collection root, approver, and reason. The phase coordinator and its subagents are
host-sticky; the collection and its evidence are not. This remains **not an atomic
session lock or security boundary**, so the authorized handoff is the ownership
change and competing handoffs must still be serialized by the caller.

A coordinator request is JSON (create it with jq, not string interpolation):

```json
{
  "recordRef": "phases/demo-02-authentication.md",
  "specHash": "sha256:CURRENT_FACADE_FINGERPRINT",
  "attempt": 1,
  "runID": "demo-p02-coordinator-a01",
  "role": "coordinator",
  "skill": "go-team",
  "worktree": "/absolute/path/to/demo-auth",
  "model": "provider/exact-authenticated-model-id",
  "thinking": "high",
  "handoff": true,
  "collectionRelocation": {
    "fromRoot": "/old/checkout/.tasks",
    "fromRunID": "demo-p02-coordinator-a01",
    "approvedBy": "explicit user authorization",
    "reason": "authorized move to the designated execution host"
  },
  "prompt": "Read go-team. Execute phase=phases/demo-02-authentication.md using the supplied approved plan, target branch, resource allocation and commit policy. [Include the complete handoff here.]"
}
```

Use `mtn-workflow --repo "$REPO_ROOT" fingerprint "$REF"` for `specHash`.
Transport requests retain the prompt, but published runtime notes deliberately
exclude it. Do not put tokens, decrypted secrets or credentials in either.
New `runID` values must use the canonical pattern above and be unique across the
collection. Stable phase/task numbers are identity derived from refs (for example,
`demo-02-client.md` and `demo-02-01-login.md`); changing `structure.order` must not
change a new run’s identity. Increase the attempt for retries; never reuse a previous Pi conversation
for a fresh worker. Existing Pi-compatible IDs remain valid historical evidence.
Use `pi --session-id ID` for exact create-or-open semantics, NOT `--session ID`
(which looks up an existing conversation). The launcher supplies this flag; agents
do not run Pi again to create their own conversation.

## Worker launch and result delivery

Only the handed-off coordinator launches workers. First perform the shared
approval/readiness/ownership/resource checks and publish the task's normal
`dispatch` reservation. The launcher validates the exact current spec, phase
membership, governing dispatch and attempt, but is **not a replacement scheduler**.
Review launches refer to the build's governing dispatch; each reviewer has its
own unique run ID. Include exact build ID/head/tree and required specialty in
its prompt. A fix uses a new task dispatch/build attempt and new worker run IDs.

```json
{
  "recordRef": "tasks/demo-02-01-login.md",
  "specHash": "sha256:CURRENT_TASK_FINGERPRINT",
  "attempt": 1,
  "runID": "demo-p02-t01-builder-a01",
  "role": "builder",
  "skill": "go-builder",
  "phaseRef": "phases/demo-02-authentication.md",
  "coordinator": {"runID": "demo-p02-coordinator-a01", "phaseRef": "phases/demo-02-authentication.md"},
  "dispatchEventID": "demo-task1/dispatch/1",
  "worktree": "/absolute/path/to/p01-t01-builder-a01",
  "model": "provider/exact-authenticated-model-id",
  "thinking": "high",
  "prompt": "Read go-builder and golang. [Include exact task/collection refs, owned scope, base/target revisions, checks, resource allocation and commit policy.] Return the required protocol v1 build payload."
}
```

`phaseRef` is the worker task's actual parent phase. `coordinator.phaseRef` is
where the original coordinator's runtime notes live (defaults to `phaseRef`).
When scheduling another ready phase, supply that original coordinator.phaseRef;
all workers still join the same Rex session, without introducing a second writer.
Each worker has a separate Pi conversation; it must not resume the coordinator's
Pi conversation or create any Rex resources itself.

For a reviewer use `role:reviewer`, its specialty skill and unique run ID. For a
read-only Task Manager use `role:planner`, `skill:mtn-tasks`, phase recordRef and
phaseRef, coordinator.runID, and a planning-proposal prompt; no task dispatch is needed.
The caller remains responsible for bounded planner/reviewer capacity as well as
builder slots. Launch each Zig specialty as a separate Rex window running a
separate Pi conversation.

The launcher saves its command search PATH in private transport context and
restores it in the Rex terminal before starting Pi. Rex's long-running server
need not have inherited the latest activated Nix profile. This copies PATH only,
not credentials or the rest of the caller's environment.

Worker startup strips the publication marker and coordinator recursion marker.
Workers are leaves; this is role discipline, not an OS sandbox. Every worker
gets a fresh full canonical Pi session ID and a display name matching its Rex
window label (`coordinator` for coordinators),
explicit model/thinking and an initial prompt
containing its launch contract, parent collection checkout and persisted runtime
identity. The launcher creates the Rex resources BEFORE starting Pi; the worker
must not create its own session or window. Workers run Pi directly in the Rex terminal's normal interactive mode, so the
actual Pi TUI shows live assistant text, tool execution, and errors. There is no
stdout/stderr redirection or hidden conversation capture. Before its final reply,
the worker writes exactly one protocol JSON object to the explicit transport
`final-result.json`. A trusted launcher extension observes Pi's supported
`agent_before_settle` boundary, validates that final-result shape, and requests an
orderly shutdown; the launcher then copies that machine-readable final result to
`result.json` after Pi exits successfully. Prompts, task Markdown, and durable
evidence
payloads are not echoed by the launcher. Coordinator Pi stays interactive;
follow the concise-output policy below.

```bash
mtn-rex --repo "$REPO_ROOT" inspect "$TASK_REF" "$RUN_ID"
# Use the persisted host endpoint/session/block IDs with Rex's bounded wait API:
rex --autostart=false -S "$ENDPOINT" wait -s "$REX_SESSION_ID" "$REX_BLOCK_ID" --for 30s --json
mtn-rex --repo "$REPO_ROOT" result "$TASK_REF" "$RUN_ID"
```

Distinguish four milestones: Rex resources created, Pi process started, model
returned a useful response, and task finished with validated evidence. A published
`runtime/launched` event establishes the first, not all four. Pi's warning that an
exact `--session-id` was absent and is being created is expected for a fresh run,
not a missing Rex session. A worker with no visible Pi activity is still suspicious, but bounded waits remain
necessary because provider/model failures can occur after startup. The auto-finish
hook runs only at Pi's completed-turn `agent_before_settle` boundary and never
terminates merely because a result file exists while work is active.

Use supported bounded Rex waits or event delivery; do not poll Pi session files
or terminal logs. A bounded wait timeout means only that the wait expired; it is
not a launch failure or permission to replace a live worker. Provider/model errors
are distinct from Rex creation errors; do not create repeated windows as a remedy. `inspect` calls the
terminal's process method. `result` requires a zero worker exit code and a JSON
object; the coordinator must still validate the full role-specific protocol,
attempt/spec/revision and actual checks before publishing through mtn. It never
auto-publishes or completes a task. A zero exit or an open window is not success.
Launch with `--keep-open` to retain startup/process failures. Once Pi exits zero
and exactly one JSON object is saved, the launcher closes only that worker's
persisted window on its pinned host/server instance. Blocked/failed outcomes,
CHANGES_NEEDED reviews, malformed/multiple payloads and close errors retain the
window for inspection. This is transport cleanup, NOT protocol approval or task
completion. Coordinator windows remain open. Final results, exit codes, Pi sessions,
worktrees and runtime notes are retained even after window closure.
Use saved transport evidence after closure; a missing worker window alone is not
a failure and does not authorize relaunch.

## Concise terminal output without hiding worker activity

Report dispatch, completion, blockers and approval requests in short summaries
with exact refs and artifact paths. Never echo task Markdown, entire descriptions,
prompts, tool request bodies or evidence payloads as progress output. Write record
content directly to files rather than using verbose shell heredocs or patch dumps
in displayed commands. Redirect mtn mutation responses and large diagnostics into
private transport files; inspect only necessary status/ID fields. Do not use
`tee`, `cat`, tracing (`set -x`) or full snapshot dumps for routine progress.
Read full task/evidence content when needed for correctness, but do not repeat it
in commentary. Retrieve worker results into a file, then validate that file:

```bash
mtn-rex --repo "$REPO_ROOT" result "$TASK_REF" "$RUN_ID" >"$RESULT_FILE"
```

The normal Pi TUI renders interactive tool inputs and results directly. Concise
output means workers should not repeat prompts, task Markdown, or full evidence
payloads in their final handoff; it does not suppress the live conversation. The
explicit `final-result.json` and copied `result.json` are the only machine-readable
final-result transport records; the conversation itself is not redirected into them.

## Runtime notes and recovery

Both reserved and launched notes use protocol v1 `kind:runtime` and matching
category. The existing guard library validates their typed shape. They carry
record/spec/attempt/run/role/skill, absolute worktree, Pi session ID, model/thinking,
host endpoint/ID/instance, explicit `rexSessionName`/`rexWindowName`/`piSessionName`
(and compatibility aliases), and transport directory. Launched notes
add exact Rex session/window/block IDs. Worker notes identify their parent phase
and coordinator run; task workers also identify their governing task dispatch.

These notes live **inside the phase/task records through mtn agent note**, never
hand-edited frontmatter or another status file. Evidence appends do not change
semantic fingerprints. Runtime notes do not satisfy prerequisites or reviews.

- Any existing reservation blocks relaunch with that run ID, even after a timeout.
  Inspect mtn notes and preserved `created.json` first. Never blindly repeat `new`.
- A launch publication failure keeps Pi gated; it times out rather than starting
  an untracked writer. Preserve recovery files. A published launch likewise does
  not prove Pi started successfully: inspect the actual process.
- After server restart, instance mismatch stops attachment/dispatch; inspect and
  explicitly reconcile instead of trusting stale IDs or recreating the session.
- After confirming a coordinator stopped/finished, publish a normal `release`
  event on its phase with `dispatchEventID:<runID>/runtime/reserved`, actual
  process evidence, and outcome stopped/finished. Only then hand off a new run ID.
  Worker task reservations still require their normal task-dispatch release and
  delivery evidence; releasing the phase does not release live builders.
- To resume an existing live coordinator, address its persisted Rex window/block
  IDs and existing Pi process, not another Pi process on the same Pi conversation. Resuming a stopped Pi requires confirmed ownership
  transfer and an explicit new attempt; never duplicate a writer.
- A missing result/transport file is missing evidence, not permission to infer
  success. Preserve worktrees, runtime notes, Pi sessions and windows on failure.
- Automatic closure of successful worker windows follows the policy above.
  Closing coordinator/failed/unrelated windows or sessions, deleting transport or
  worktrees, and global cleanup still need separate authorization. Phase completion
  still includes cleanup planning.

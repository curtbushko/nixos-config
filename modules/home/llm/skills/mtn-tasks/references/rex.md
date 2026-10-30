# Rex / Pi Team Execution

Use this transport for `go-team`, `node-team`, and `zig-team`. Every agent runs
in Pi. mtn remains the sole workflow/evidence authority; Rex provides visible
sessions, windows (tabs), and terminal blocks. Read the shared execution contract
as well: this transport does not replace approval, resource admission, review,
or integration checks.

## Layout and execution host

- Create one new Rex session named after the **orchestration worktree directory**.
- Run the coordinator in its initial window, named `phase-<order>-<title>`.
- Every worker is a new window in that session: `<skill>-task<N>-attempt<A>`.
  Examples: `go-builder-task1-attempt1`, `zig-comment-reviewer-task1-attempt1`.
- Phase-level planners use `<skill>-phase<N>-attempt<A>` and attach evidence to
  their phase. Task numbers are scoped to phases; use saved IDs to disambiguate
  equal labels across phases. Never resolve ownership by a display name.
- Coordinator execution stays on the host containing its checkout. When invoked
  in a remote shell, run the launcher **there**, not on the viewing Mac. Rex must
  have a running local server there. `request.server` can explicitly select its
  Unix endpoint if Rex's default points at a home/remote server. The launcher
  rejects network transports before publication and pins endpoint, host ID and
  server instance for all workers. It never falls back to the local Mac.
- Worker paths must be checkouts of the same Git repository on that host.
  Builders use prepared isolated worktrees; reviewers use the frozen revision.

Rex CLI and Pi must already be installed on that execution host. Nix installs
`mtn-rex` with `ns.scripts.enable`; it does not install Rex or activate this
configuration itself. Before activation, put the repository's script directory
on PATH and run both helpers through Bash wrappers if they are not executable.

## Initial handoff: exactly one coordinator

The caller resolves the collection, exact project/phase/task selection, approved
scope and orchestration checkout. If selection spans several phases, anchor the
run in its first selected dependency-ready phase and preserve the full selection
in the handoff; this is still **one project coordinator**, not one writer per
phase. Do not change the team's existing dependency-ready scheduling semantics.

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
6. The new Pi receives `MTN_REX_COORDINATOR_RUN`, `MTN_REX_ROLE=coordinator` and
   its exact `--session-id`. It must not recurse into another coordinator handoff.
   Check `MTN_REX_REPO` matches this collection; reconcile the persisted launch
   before beginning the shared execution loop.

The helper rejects any unreleased coordinator reservation across phase records,
including a reservation with a different run ID. This is conservative recovery,
**not an atomic session lock or security boundary**. The existing protocol's
single-owner discipline still applies; never launch competing handoffs concurrently.

A coordinator request is JSON (create it with jq, not string interpolation):

```json
{
  "recordRef": "phases/demo-02-authentication.md",
  "specHash": "sha256:CURRENT_FACADE_FINGERPRINT",
  "attempt": 1,
  "runId": "demo-phase2-coordinator-1",
  "role": "coordinator",
  "skill": "go-team",
  "worktree": "/absolute/path/to/demo-auth",
  "model": "provider/exact-authenticated-model-id",
  "thinking": "high",
  "handoff": true,
  "prompt": "Read go-team. Execute phase=phases/demo-02-authentication.md using the supplied approved plan, target branch, resource allocation and commit policy. [Include the complete handoff here.]"
}
```

Use `mtn-workflow --repo "$REPO_ROOT" fingerprint "$REF"` for `specHash`.
Transport requests retain the prompt, but published runtime notes deliberately
exclude it. Do not put tokens, decrypted secrets or credentials in either.
`runId` must be a unique collection-wide Pi-compatible session ID: letters,
numbers, `.`, `_`, `-`, starting and ending with a letter or number.

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
  "runId": "demo-task1-go-builder-1",
  "role": "builder",
  "skill": "go-builder",
  "phaseRef": "phases/demo-02-authentication.md",
  "coordinatorPhaseRef": "phases/demo-02-authentication.md",
  "parentRunId": "demo-phase2-coordinator-1",
  "dispatchEventId": "demo-task1/dispatch/1",
  "worktree": "/absolute/path/to/isolated-task1-worktree",
  "model": "provider/exact-authenticated-model-id",
  "thinking": "high",
  "prompt": "Read go-builder and golang. [Include exact task/collection refs, owned scope, base/target revisions, checks, resource allocation and commit policy.] Return the required protocol v1 build payload."
}
```

`phaseRef` is the worker task's actual parent phase. `coordinatorPhaseRef` is
where the original coordinator's runtime notes live (defaults to `phaseRef`).
When scheduling another ready phase, supply that original coordinatorPhaseRef;
all workers still join the same session, without introducing a second writer.

For a reviewer use `role:reviewer`, its specialty skill and unique run ID. For a
read-only Task Manager use `role:planner`, `skill:mtn-tasks`, phase recordRef and
phaseRef, parentRunId, and a planning-proposal prompt; no task dispatch is needed.
The caller remains responsible for bounded planner/reviewer capacity as well as
builder slots. Launch each Zig specialty as a separate Pi window.

The launcher saves its command search PATH in private transport context and
restores it in the Rex terminal before starting Pi. Rex's long-running server
need not have inherited the latest activated Nix profile. This copies PATH only,
not credentials or the rest of the caller's environment.

Worker startup strips the publication marker and coordinator recursion marker.
Workers are leaves; this is role discipline, not an OS sandbox. Every worker
gets a fresh exact Pi session ID, explicit model/thinking and an initial prompt
containing its launch contract and parent collection checkout. Workers run in
print mode and return just the requested JSON as the final response. Their final
response and process exit code are excluded `.mtn-tmp/rex/<runId>/` transport,
not a second authoritative results database. Coordinator Pi stays interactive.

```bash
mtn-rex --repo "$REPO_ROOT" inspect "$TASK_REF" "$RUN_ID"
# Use the persisted host endpoint/session/block IDs with Rex's bounded wait API:
rex --autostart=false -S "$ENDPOINT" wait -s "$SESSION_ID" "$BLOCK_ID" --for 30s --json
mtn-rex --repo "$REPO_ROOT" result "$TASK_REF" "$RUN_ID"
```

Use supported bounded Rex waits or event delivery; do not poll Pi session files
or terminal logs. A wait timeout is not a failure verdict. `inspect` calls the
terminal's process method. `result` requires a zero worker exit code and a JSON
object; the coordinator must still validate the full role-specific protocol,
attempt/spec/revision and actual checks before publishing through mtn. It never
auto-publishes or completes a task. A zero exit or an open window is not success.
Retain windows (`--keep-open`) so the user can inspect failures and finished work.

## Runtime notes and recovery

Both reserved and launched notes use protocol v1 `kind:runtime` and matching
category. The existing guard library validates their typed shape. They carry
record/spec/attempt/run/role/skill, absolute worktree, Pi session ID, model/thinking,
host endpoint/ID/instance, display labels and transport directory. Launched notes
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
  event on its phase with `dispatchEventId:<runId>/runtime/reserved`, actual
  process evidence, and outcome stopped/finished. Only then hand off a new run ID.
  Worker task reservations still require their normal task-dispatch release and
  delivery evidence; releasing the phase does not release live builders.
- To resume an existing live coordinator, use its window, not another Pi process
  on the same saved session. Resuming a stopped Pi requires confirmed ownership
  transfer and an explicit new attempt; never duplicate a writer.
- A missing result/transport file is missing evidence, not permission to infer
  success. Preserve worktrees, runtime notes, Pi sessions and windows on failure.
- Closing sessions/windows, deleting transport/worktrees or global cleanup needs
  separate authorization. Phase completion still includes cleanup planning.

# mtn Commands and Data Contract

Coordinator reference only. Prefer the [Bash facade](facade.md) for status/task briefs,
canonical fingerprints, readiness, path normalization, resource/disk checks and
validated publication. Workers read only their short contract. The low-level API
examples below remain useful for proposed record/relationship changes; do not rebuild
snapshot/hashing logic in every agent or use JS/Python for workflow automation.

Baseline: mtn `0.2.0-rc.1`, exact-reference `agent` API, JSON envelope version 1.
Check installed help and `diagnose` before use. Read [protocol v1](protocol.md) for
required record metadata, approval, evidence schemas and delivery gates. The commands
below demonstrate API mechanics; draft records are not approved dispatch candidates.
Unsupported versions/capabilities require clarification, not guessed flags. These commands assume repository-root
`REPO_ROOT` and absolute `TASK_ROOT="$REPO_ROOT/.tasks"`.

## Read and discover

```bash
mtn --path "$TASK_ROOT" diagnose --json
mtn --path "$TASK_ROOT" list --json
mtn --path "$TASK_ROOT" agent show "$REF" --json
mtn --path "$TASK_ROOT" agent hierarchy "$PROJECT_REF" --json
mtn --path "$TASK_ROOT" agent ready "$PHASE_REF" --json
mtn --path "$TASK_ROOT" agent blocked "$PHASE_REF" --json
mtn --path "$TASK_ROOT" agent dependencies "$REF" --json
mtn --path "$TASK_ROOT" agent validate --json
```

Agent success is `{version:1,ok:true,result:...}`; errors exit nonzero with
`ok:false`. Check both exit code and envelope. `list --json` is a bare array,
not an agent envelope. List entries expose `path`, `workflowKind`, `workflowOrder`,
and native `status`. `show.result` exposes `ref`, `description`, `evidence`,
`frontmatter`, and `revision`. Hierarchy returns `children`, `descendants`,
`leafTasks`, `progress:{completed,total,percentage}`, and `cycles`.
Readiness returns `result.results` and `result.evaluated`; scoped queries can include
the scope record itself. Select only implementation tasks within the selected phase,
using list metadata joined by exact `path`/`ref`. Never schedule a phase as a builder task.

Track the collection's records, type/config/schema/contract files in the repository.
Keep operational caches and request/recovery directories excluded from record discovery
and ignored by Git as appropriate: `.mdbase`, `.mtn`, `.mtn-tmp`, `.mtn-recovery`.
Review existing exclusions rather than rewriting them implicitly. Never put backups
inside live task discovery scope or initialize nested collections for phases.

Use exact collection-relative refs returned by mtn (e.g. `tasks/demo-01-01-parser.md`),
not titles, absolute paths, numeric IDs, or refs prefixed with `.tasks/`.
Reject ambiguous numeric phase/task selections; scope numbers to their parent.

## Literal creation

Only `agent create`, not NLP `mtn create`, is suitable for automation.

```bash
mtn --path "$TASK_ROOT" agent create --input - --json <<'JSON'
{"title":"Demo project","path":"projects/demo.md","description":"## Scope\nBuild a parser.","fields":{"workflowKind":"project"},"retryKey":"demo-project-v1"}
JSON
mtn --path "$TASK_ROOT" agent create --input - --json <<'JSON'
{"title":"Phase 1: Parser","path":"phases/demo-01-parser.md","description":"## Acceptance criteria\nParse commands and reject invalid input.\n\n## PRD\nSee [Parser PRD](../prds/demo-parser.md), stories 1–3.","fields":{"workflowKind":"phase","workflowOrder":1},"retryKey":"demo-phase-01-v1"}
JSON
mtn --path "$TASK_ROOT" agent project-add phases/demo-01-parser.md --input - --json <<'JSON'
{"target":"projects/demo.md"}
JSON
mtn --path "$TASK_ROOT" agent create --input - --json <<'JSON'
{"title":"Implement parser","path":"tasks/demo-01-01-parser.md","description":"## Scope\nImplement literal parsing.\n\n## Files\nCreate parser tests before implementation.\n\n## Acceptance criteria\nReject empty input; preserve quoted text.\n\n## Verification\nRecord RED, GREEN, and full-suite commands.","fields":{"workflowKind":"task","workflowOrder":1,"workflowLanguage":"go"},"retryKey":"demo-task-01-01-v1"}
JSON
mtn --path "$TASK_ROOT" agent project-add tasks/demo-01-01-parser.md --input - --json <<'JSON'
{"target":"phases/demo-01-parser.md"}
JSON
```

Create a PRD similarly at `prds/<slug>.md` with `workflowKind: "prd"`, or an RFC at
`designs/<slug>.md` with `workflowKind: "design"`. Put full Markdown content in
`description`, with no membership in a progress tree. PRDs use stable REQ IDs;
designs define interfaces and reference those IDs. Both need fingerprint-bound
approval events before dependent plan approval. Populate the protocol's task
ownership/requirements/document metadata before proposing a dispatch.
The example PRD link is illustrative; create its target before validating a real plan.
`descriptionFile` can read a UTF-8 draft instead of `description`, but not both.
Use `jq -n --arg`/`--rawfile` to encode arbitrary prose; never interpolate unescaped
text into JSON or manually write Markdown with YAML frontmatter.

Custom fields must be schema-permitted. Fresh default mtn schemas permit the fields
above and `mtnCreateRetry`; existing strict collections may not. Never change schema
implicitly. Retry the same creation intent with the same key; changed intent needs
an explicit update, not reuse of a retry key. An occupied path is not permission to
overwrite. Creation + membership are separate writes: on resume, inspect the record
and idempotently finish missing links rather than recreating it.

## Native hierarchy and prerequisites

```bash
mtn --path "$TASK_ROOT" agent depends-add "$DEPENDENT_REF" --input - --json <<'JSON'
{"target":"tasks/demo-01-01-parser.md"}
JSON
```

Create targets first. Use `project-add`/`project-remove`/`project-replace` for
membership; `depends-add`/`depends-remove`/`depends-replace` for prerequisites.
Creation also accepts `dependsOn:["exact/ref.md"]`, but do not persist that alias
as custom frontmatter. Default dependency type is FINISHTOSTART. Keep native
relationships, gaps, unrelated memberships, and task identities intact.
Phase sequencing needs explicit phase prerequisites; a task's readiness query
alone does not check prerequisites on its parent phase. Check phase dependencies
before selecting its children. Numbering and membership do not imply execution order.

## Typed edits and lifecycle

```bash
mtn --path "$TASK_ROOT" agent patch "$REF" --input - --json <<'JSON'
{"operations":[{"op":"set","field":"workflowOrder","value":2}]}
JSON
mtn --path "$TASK_ROOT" agent describe "$REF" --input - --json <<'JSON'
{"description":"## Scope\nUpdated acceptance criteria; prior evidence remains intact."}
JSON
```

Patches use actual mapped field keys and typed JSON values. Diagnose first. The
following status is valid for a **fresh default** collection only:

```bash
mtn --path "$TASK_ROOT" agent status "$REF" --input - --json <<'JSON'
{"status":"in-progress"}
JSON
mtn --path "$TASK_ROOT" agent complete "$REF" --json
mtn --path "$TASK_ROOT" agent reopen "$REF" --json
```

`complete` chooses a configured completed status; `reopen` chooses an incomplete
default. Do not patch completion timestamps or interpret `cancelled` as completed.
Do not add invented `awaiting-review` or `blocked` statuses. If the diagnosed policy
supports a blocked status, `agent block` requires `{status,blocker}`; otherwise
append blocker evidence, retain an incomplete status, and stop dispatching it.
Description changes invalidate old acceptance reviews; reopening/fixes require
explicitly assessing stale approvals and completed dependent work.

## Durable evidence instead of result files

```bash
mtn --path "$TASK_ROOT" agent note "$REF" --input - --json <<'JSON'
{"content":"{\"schemaVersion\":1,\"eventId\":\"demo/build/1\",\"kind\":\"build\",\"recordRef\":\"tasks/demo-01-01-parser.md\",\"specHash\":\"sha256:replace-with-spec-fingerprint\",\"attempt\":1,\"dispatchEventId\":\"demo/dispatch/1\",\"head\":\"replace-with-commit\",\"tree\":\"replace-with-tree\",\"outcome\":\"ready-for-review\",\"validation\":[{\"command\":\"task test\",\"result\":\"pass\"}]}","role":"coordinator","category":"build","adopt":true,"retryKey":"demo/build/1"}
JSON
```

Notes accept `content` or `contentFile`, optional `role`, `author`, `category`,
`timestamp`, and `retryKey`. `adopt:true` explicitly adds an evidence boundary to
a plain description. It does not overwrite it. `describe` preserves the evidence
suffix. Preserve malformed evidence and report it instead of hiding it.

The coordinator publishes v1 events using matching category and eventId/retryKey.
See protocol.md for approval, plan, dispatch, build, review, integration, completion,
blocker, resume and release schemas. Fixes are new build attempts with `fixes`
referencing findings, not a separate unversioned fix/result format. Include scope,
files, tests, exact RED/GREEN/full/integration commands, limitations and Git identity.
Unversioned historical notes need explicit interpretation/migration, never silent loss.
Each review event must include common v1 keys and:

- `reviewer`: combined, code, comment, architecture, or test; `buildEventId`, exact head/tree
- `verdict`: APPROVED or CHANGES_NEEDED; `user_decision_required`
- criterion-by-criterion evidence; independent verification commands/results
- `changes_required`: stable ID, file:line, rule, evidence, impact, required outcome,
  and specialties that must recheck
- `NON_BLOCKING_SUGGESTIONS`: optional follow-ups, never disguised blockers

Serialize a JSON review object as note **content**, not arbitrary unsupported
arguments to `agent note`. The coordinator publishes ALL returned worker payloads serially. Planning, build
and review workers are read-only against the collection; concurrency applies to
isolated source work, not mtn mutations. If transport needs a file, use an excluded `.mtn-tmp` request file only;
it is not a second authoritative result store. Read back compact current-attempt evidence through the facade to confirm verdicts
before integration. Complete
only after successful combined-target integration and persisted completion evidence. Retry keys identify one immutable attempt;
new code, changed findings, or a revised verdict require a new attempt/key.
Attribution is caller-supplied, not authenticated. Readiness is a snapshot, not a lease.

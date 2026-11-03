# Workflow data model

This is the migration target for the workflow skills. It is a data contract, not a
Go implementation and not authorization to rewrite existing `.tasks` records.
Current Bash/jq tooling may continue to read the compatibility representation until
a future typed implementation is approved.

## Design principles

- `UUID` is the immutable native record UUID.
- A stable work-item ID identifies the project, phase, or task and does not change
  between executions. For tasks this is `TaskID`; phases and projects use the same
  semantic field with their corresponding type name.
- `RunID` identifies one ephemeral execution. A retry or replacement execution gets
  a new `RunID`; attempts are not part of stable work-item identity.
- `DisplayName` and `Description` are presentation fields. Neither is an identity,
  lookup key, or resource selector.
- Workflow data is grouped by purpose. Provider-specific launcher details are
  contained by a generic launcher binding.
- Current lifecycle and execution pointers are materialized on the record so an
  agent can inspect one record to determine its current state. Evidence remains the
  audit/history trail.

## Common work-item shape

The following is conceptual JSON/YAML. The eventual typed model may use Go structs
and typed IDs rather than these literal names.

```yaml
identity:
  uuid: 00000000-0000-0000-0000-000000000000
  taskID: rex-whichkey-14-03
  kind: task

presentation:
  displayName: GUI action verification
  description: Verify the documented native actions and their resource effects.

structure:
  parentRef: phases/rex-whichkey-14-action-audit.md
  order: 3

scope:
  requirements:
    - REQ-030
  documents:
    - ref: prds/rex-whichkey.md
      hash: sha256:...
  dependencies:
    - ref: tasks/rex-whichkey-14-02-resource-audit.md
      relation: finish-to-start

lifecycle:
  state: reviewing
  sourceEventID: rex-whichkey-14-03/review/1
  changedAt: 2026-11-02T22:00:00Z

execution:
  current:
    dispatchEventID: rex-whichkey-14-03/dispatch/1
    runIDs:
      - rex-whichkey-14-03-reviewer
  coordinator:
    runID: rex-whichkey-p14-coordinator
    phaseRef: phases/rex-whichkey-14-action-audit.md

implementation:
  language: docs
  ownership:
    paths: []
    sharedPaths: []
    resources: []
    interfaces: []
```

`implementation` is optional for projects and phases. `structure.parentRef` is
absent on projects, points to a project for phases, and points to a phase for tasks.
The stable ID field is type-specific in serialized records (`projectID`, `phaseID`,
`taskID`) if that makes native records clearer; the typed model should expose one
common stable-ID abstraction and enforce the same semantics for all three.

## Current execution and launcher binding

A run is independent of the work item and contains only execution-specific state:

```yaml
runID: rex-whichkey-14-03-reviewer
role: reviewer
state: active
workItemRef: tasks/rex-whichkey-14-03-gui-action-verification.md
provider:
  name: rex
  displayName: p14-t03-reviewer
  resources:
    session: session:...
    window: window:...
    block: block:...
```

`provider` is the launcher abstraction. The workflow model must not have fields
such as `rexWindowID`, `piSessionID`, or `tmuxPaneID`. A provider owns the meaning
of its resource map and implements creation, reconciliation, and closure for task
and coordinator executions. Exact provider resource IDs are authoritative; display
names are useful indexes but are never selectors by themselves.

## Coordinator state

Coordinator ownership is a current execution projection on the selected phase:

```yaml
execution:
  coordinator:
    runID: rex-whichkey-p14-coordinator
    state: active
    phaseRef: phases/rex-whichkey-14-action-audit.md
```

The project may additionally expose the selected coordinator/phase for project-wide
status, but a coordinator's actual scheduling ownership remains phase-scoped. Worker
execution projections point to the coordinator `RunID`. Runtime and release events
remain the authoritative history used to reconcile this projection.

## Event shape

Events retain a flat protocol envelope for streaming and validation:

```yaml
schemaVersion: 1
eventID: rex-whichkey-14-03/build/1
kind: build
recordRef: tasks/rex-whichkey-14-03-gui-action-verification.md
specHash: sha256:...
runID: rex-whichkey-14-03-builder
dispatchEventID: rex-whichkey-14-03/dispatch/1
```

The future typed layer can decode this into grouped domain structures, but event
identity and record targeting remain explicit. `recordRef` is the canonical
collection-relative reference in protocol data. `ref` and `path` are adapter names
used when reading native mtn output.

## Compatibility mapping

| Current representation | Migration target |
|---|---|
| native `id` | `identity.uuid` |
| native `path`, projection `ref` | `recordRef` / stable file reference |
| `title` | `presentation.displayName` |
| record Markdown body / description | `presentation.description` |
| `workflowKind` | `identity.kind` |
| `projects` parent links | `structure.parentRef` |
| `workflowOrder` | `structure.order` |
| `workflowRequirements` | `scope.requirements` |
| `workflowDocuments` | `scope.documents` |
| native `blockedBy` | `scope.dependencies` |
| `workflowLanguage` | `implementation.language` |
| `workflowOwnership` | `implementation.ownership` |
| derived `task_state` and native completion | `lifecycle.state` |
| runtime/release evidence | `execution.current` and run history |
| `parentRunId` | `execution.coordinator.runID` reference |
| Rex/Pi-specific runtime fields | `execution.current.provider` binding |
| `attempt` | legacy event correlation; not stable identity |

During migration, adapters should read both representations, prefer the canonical
grouped model when present, and reject contradictory values rather than silently
choosing one. Existing records and evidence must not be rewritten merely to adopt
this model.

## Type constraints

- A project has no parent and may own phases.
- A phase has one project parent and may own tasks.
- A task has one phase parent and owns implementation scope.
- All work-item types have UUID, stable typed ID, display name, description, scope,
  lifecycle, and execution sections where applicable.
- Only executions have `RunID`.
- A display name may change without changing UUID, stable ID, or RunID.
- A RunID may disappear when an execution ends; the completed work item retains its
  final lifecycle and delivery summary, not a live launcher binding.

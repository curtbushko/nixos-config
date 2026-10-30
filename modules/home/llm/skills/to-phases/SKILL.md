---
name: to-phases
description: Use when creating or revising an approved phase dependency graph from PRD/design records. Uses native mtn hierarchy, prerequisites and requirement coverage in one repository-local .tasks collection.
---

# To Phases

Read `mtn-tasks` and all protocol/command/execution/migration references completely.
The invoking agent coordinates writes; delegated planners return read-only proposals.
Existing project migration requires explicit approval. No raw managed-file edits or
mirrored coordination files.

## Create a Delivery Plan

1. Run preflight. Initialize only an absent/empty collection; resolve/create the
   project record with the accepted `workflowRequirements` IDs and document refs/hashes.
   Ask for its name if not agreed. Clarify ambiguous project refs.
2. Discover relevant `prd` and optional `design` records. Read descriptions via mtn,
   stable REQ IDs, acceptance criteria, constraints, interface contracts and approvals.
   Missing/stale document approval blocks implementation planning. Significant
   interface/security/persistence changes require an RFC; simple work can explicitly
   omit one with approved rationale. Documents remain outside progress membership.
3. Propose coherent, independently verifiable milestones covering every accepted
   requirement. For each phase identify deliverable, prerequisite phases, interface
   inputs/outputs, shared integration points, verification and potential overlap.
   Do not turn numbering into dependencies or force independent phases into a chain.
   Prefer task edges for individual contracts/deliverables; reserve phase edges for
   genuine whole-milestone barriers. Task Managers finalize those task edges together.
4. Present scope, requirement-to-phase coverage, graph, parallelization boundaries,
   deferred requirements and rationale for approval. Clarify missing coverage first.
5. Create each `phases/<project>-<NN>-<slug>.md` through `agent create`, with kind
   `phase`, integer `workflowOrder`, `workflowRequirements` and `workflowDocuments`
   refs/fingerprints. Description captures context, criterion IDs, design references,
   deliverable, interfaces, constraints, verification and explicit prerequisites.
6. Add native project membership and explicit dependency edges after targets exist.
   Validate graph AND protocol metadata/coverage, then publish the actual approved
   project-plan manifest as v1 `plan` evidence with exact refs/spec fingerprints.
7. Report ready phases, blocked prerequisites, and exact refs. The coordinator may
   dispatch separate Task Manager proposal workers for ready phases, then approve
   their task manifests. Tasks—not arbitrary phase fragments—are primary builder units.

Phase acceptance criteria are requirements, not a second task-status checklist.
Do not create placeholder tasks that inflate progress. Every eventual implementation
task must be self-contained, TDD-sized, ownership-bounded and delegated through the
matching language worker skill; phase membership alone never implies readiness.

## Add, Update or Inspect

Query project hierarchy, all phase dependencies, native status and protocol state.
Use order only as a tie-breaker among ready phases. Ask whether to add/update/view,
validate coverage or cancel. Numeric refs are scoped to the selected project.

Use `describe` for prose, typed `patch` for metadata, dedicated operations for native
relationships. Changes invalidate affected document/plan fingerprints; record impact
and reapproval before dispatch. Inspect running work before changing its scope.

Completion requires integrated tasks, current approvals, combined-target final gates,
and requirement coverage—not edited checkboxes or hierarchy percentage alone.
Preserve records/evidence and occupied paths. Resume partial writes idempotently.

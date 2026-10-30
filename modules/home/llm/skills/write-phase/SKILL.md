---
name: write-phase
description: Use when capturing an agreed conversation as one implementation phase. Creates an mtn phase record in the repository-local .tasks collection with native project membership and explicit prerequisites.
---

# Write One Phase

Read `mtn-tasks` and its protocol, command, execution, and migration references completely.
The invoking agent coordinates writes; delegated planners return proposals.
Use mtn for every record write; never hand-author frontmatter or coordination state.

## Procedure

1. Run shared preflight. Existing legacy plans require explicit migration approval;
   do not silently replace them. If no project/collection exists, ask whether to
   initialize a new collection and create the project, or stop for `to-phases`.
2. Read project/phase metadata and approved PRD/design documents through mtn; resolve
   ambiguity and check current approval fingerprints. Determine the next unused order.
   Stable REQ IDs, interface inputs/outputs and prerequisites define the phase boundary;
   order does not force dependency on every earlier phase.
3. Extract the feature, decisions, approach, constraints, impacted areas, tests,
   and unresolved questions from the conversation. Do not invent requirements.
4. Confirm: "Create one phase for <summary> under <project ref>?" Include proposed
   prerequisites and linked PRD/story IDs. Wait for confirmation or clarification.
5. Create `phases/<project>-<NN>-<slug>.md` via `agent create`, setting
   `workflowKind: phase`, `workflowOrder`, `workflowRequirements` and fingerprinted
   `workflowDocuments`. The Markdown description contains:
   - Context and agreed decisions
   - Scope and concrete, numbered acceptance criteria
   - Expected file paths/interfaces where established
   - TDD and observable test requirements
   - PRD/story references, dependencies, constraints, and open questions
6. Add native project membership through `agent project-add`; add explicit
   prerequisites through `agent depends-add` after resolving exact target refs.
   Do not use body checkboxes or custom parent/dependency fields as state.
7. Validate graph plus requirement coverage and protocol metadata. Record the updated
   actually-approved project manifest as v1 `plan` evidence, including current phase
   fingerprints and dependencies. Report exact ref, readiness and parallelization
   boundaries. Task Managers propose ownership-bounded task graphs; matching language
   workers implement independent tasks in isolated worktrees.

## Granularity

Capture one coherent phase, not multiple phases or an implementation dump. Use
`to-phases` for multi-phase planning. The Task Manager later researches and creates
reviewable implementation tasks; each task owns its own RED/GREEN/refactor cycle.
Do not split tests and implementation into independently completable work items.

Specific acceptance criteria and known file paths are useful; vague "add tests"
or "improve performance" items are not. Keep phase scope distinct from derived
progress. Preserve existing records and evidence; an occupied path requires
inspection, not overwriting or automatic suffixing.

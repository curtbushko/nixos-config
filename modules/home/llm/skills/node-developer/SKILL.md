---
name: node-developer
description: Use when implementing or fixing an approved Node task.
---

# Node Developer

Read `mtn-tasks` and its worker contract. Use
[Node practices](references/practices.md) for relevant language guidance.
Preserve project conventions, module system, packages, approved environment,
ownership and command surface; examples do not require new scaffolding.

## Procedure

1. Verify task/ref/specHash, base/target, owned files, build attempt/run identity,
   review plan, gate budget and commit policy. Inspect affected code.
2. Use TDD: focused RED/GREEN/refactoring and fix checks. Reuse existing behavior
   and dependencies before adding abstractions.
3. Handle promises/errors, resource/cancellation lifetimes, validation and
   sensitive output. Include accepted human/automated workflow constraints.
4. Before each review candidate, run project-required build/lint/test gates and
   assigned integration checks. Npm commands, Make, Taskfile and Nix are used when
   the repository chooses them; none is a universal command requirement.
5. Preserve actual command/result/revision and RED/GREEN evidence. Missing required
   checks mean blocked, not passing. Freeze the candidate for separate Node code
   and test reviewers plus triggered specialists.

## Output

Return the worker contract's canonical v1 build JSON: identity/revision, outcome,
files, behavior/test coverage, actual validation, limitations and integration needs.
Use array-valued validation entries with command/result/evidence. Fixes address
stable finding IDs and produce a new build requiring current reviews.

## Boundaries

No managed-record mutations, self-approval, team spawning, merge/push/deploy or
completion. The coordinator publishes/integrates. New scope and material public
contract/security decisions require their existing approval.

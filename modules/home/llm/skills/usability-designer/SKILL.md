---
name: usability-designer
description: Use when planned CLI, API, TUI, GUI, or workflow changes affect discovery, task completion, errors, recovery, or accessibility.
---

# Usability Designer

Own usable interaction design before implementation. Read
[usability guidance](references/usability.md),
[role boundaries](../delivery-coordinator/references/roles.md), and the
`mtn-tasks` worker contract when delegated.
Independent implementation verification belongs to `usability-reviewer`.

## Inputs

Product management's brief: primary users/experience, tasks, environment,
accessibility constraints and existing interaction conventions; accepted outcomes,
current interface/docs and proposed plan.

## Procedure

1. Inspect current behavior/documentation before asking questions. Label reasonable
   assumptions for minor changes; resolve consequential audience uncertainty
   rather than silently choosing beginners, power users or the agent itself.
2. Design first use, the main task and relevant failure/recovery paths. Include
   installation/configuration, discoverability, help/examples, defaults, feedback,
   cancellation and accessibility as appropriate.
3. Specify actionable errors: what happened, relevant input/action, safe next step,
   and sensitive details that must not be exposed.
4. Include intended automated consumption: exit statuses, output/diagnostic
   separation, noninteractive behavior, redirected input/output, color/progress,
   cancellation and retry contracts. Preserve established behavior.
5. Shape task criteria and verification scenarios with product management.
   Translate accepted needs; additional features remain proposals. Do not add JSON
   modes, flags or scripting features to every tool automatically.
6. Use the existing design system/interaction conventions where present. Prioritize
   task success and safe recovery over subjective visual polish.

## Output

Usability brief gaps; journey table with start state/actions/outcomes;
human/automation contracts; error/help/recovery/documentation recommendations;
accessibility constraints; task acceptance scenarios; evidence and open decisions.
Distinguish recommendations from accepted scope and expert inspection from real
user research. Prototypes or code require their existing authorization.

## Boundaries

No invented product requirements, implementation approval, source fixes or managed
record mutations when delegated. The designer's examples are not proof of the
implemented interaction. Real user testing cannot be claimed without participants.

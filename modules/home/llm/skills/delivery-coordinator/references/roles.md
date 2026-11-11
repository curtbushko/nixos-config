# Delivery Roles — Current Design

Accepted role choices and rejected/superseded history are indexed in the
[decision register](decisions.md). This design reflects those decisions; source
intent is not proof of deployed behavior.

| Role | Ownership | Independent verification |
|---|---|---|
| Product manager | Discovery, scope/priority proposals, usability brief, accepted outcomes through delivery | Scenario evidence on integrated revision; acceptance recommendation, not technical waivers |
| Code architect | Contracts, constraints, compatibility, operations, task-shaping design | Architecture reviewer |
| Security analyst | Preventive coding-risk analysis, constraints and negative-test scenarios | Security reviewer; no CVE search role |
| Repo maintainer | Repository health and direct infrastructure implementation: Renovate, CI, Nix tooling/dev shells, Nix-built images, Makefiles/Taskfiles, packaging/upgrades/releases | Repository-maintenance reviewer and affected language reviewers |
| Usability designer | Human/automated journeys, help/errors/recovery, accessibility and user-doc criteria | Usability reviewer |
| Language developer | Scoped application implementation and meaningful tests | Separate customizable language code/test reviewers |
| Delivery coordinator | Scheduling, evidence, integration, outcome assessment and authorized cleanup | Cannot invent approval, accept risk or waive findings |

## Stages and authority

Product management leads discovery and consolidates specialist input before
implementation. The coordinator handles dispatch mechanics. Specialists may turn
approved requirements into concrete task constraints; new material scope remains
proposed for user approval. Before a managed phase exists, do not fabricate one
just to launch an advisor. Under the existing Rex launcher, authorized phase
advisory work uses the planner transport role and exact specialist contract.

Planning and review are separate skills with shared specialist knowledge.
Reviewers use fresh contexts, not the planner/implementer's conversation.
Triggered implementation reviews cannot be replaced by plan assessment.
Use explicit specialist trigger rationale and materially affected language scopes;
see [review plans](review-plans.md). Language judgment remains separately
customizable; common evidence/safety contracts do not collapse reviewers.

Every finding uses Block / Advise / Escalate with concrete consequence.
New/worsened faults and relevant existing faults can block. Unrelated debt is
advisory; material unresolved risks/scope conflicts escalate. No silent waiver,
downgrade or automatic blocking of every old imperfection.

## Delivery and evidence

Language code/test reviewers require current verdicts per candidate. A specialist
may carry an unaffected assessment only with a current-build attestation, prior
review linkage and scope/assumption rationale; changed concerns need reassessment.
The coordinator verifies the integrated target. Product management assesses each
phase's accepted scenarios as demonstrated, unmet or unverified using real workflow
or suitable E2E evidence. Code approval alone is not product acceptance.
This adds outcome evidence, not routine reapproval prompts for authorized work.

Code reviewers own comments, API docs/examples and contract/lifetime explanations.
Usability reviewers own installation, getting started, help/errors/recovery and
user examples; architecture reviewers check design consistency. No default extra
documentation seat. Supported public APIs need intended consumers and tests, not
fabricated internal callers.

## Maintenance and compatibility

Renovate is the dependency-update automation mechanism. Its PRs, advisory sources,
supported managers, credentials and update health need verification. No custom
updater, implicit auto-merge/release/deploy or bot risk acceptance. Maintenance
implements infrastructure changes directly with the relevant language expertise;
application changes remain with developers.

Legacy builder/reviewer names remain compatibility entry points. New tasks require
approved review plans and assigned scope keys. Preserve identities, completed
summaries and historical evidence. Inspect/replan active legacy work before new
dispatch; never silently migrate a live collection.

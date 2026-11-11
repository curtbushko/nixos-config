# Skill Role Decision Register

This is the authoritative index for the role-design interview. IDs retain their
original identity and Eastern-local proposal timestamp; no acceptance timestamps
are reconstructed. Acceptance comes from explicit user replies in the conversation,
not from implementation or this document. Machine/evaluation timestamps use UTC.
See [current design](roles.md) and [review plans](review-plans.md); those documents
do not establish additional agreements.

| ID | State | Decision / rationale / relationship |
|---|---|---|
| SKILLS-20261110-095542 | Refined | Accepted first-pass role decomposition; subsequent interview decisions below refine its responsibilities and routing. |
| SKILLS-20261110-111343 | Accepted | Product management remains involved through delivery, assessing accepted outcomes without technical waivers. |
| SKILLS-20261110-182534 | Accepted | Each accepted scenario needs actual integrated workflow/E2E evidence; classify demonstrated/unmet/unverified. Reuse authentic role evidence. |
| SKILLS-20261110-182602 | Accepted | Product management leads discovery/specialist synthesis; coordinator handles dispatch. No implicit implementation/scope authorization. |
| SKILLS-20261110-182707 | Accepted | Observable triggers require architecture, security, usability or maintenance assessment; record selections and reasons. |
| SKILLS-20261110-182950 | Accepted | Block / Advise / Escalate dispositions, with evidence/impact/outcome. No silent coordinator downgrades or preference-based scope expansion. |
| SKILLS-20261110-183250 | Refined | Planning and implementation assessment timing refined by the accepted separate-role split in 184120. Unaffected assessments require explicit carry-forward rationale. |
| SKILLS-20261110-184120 | Accepted | Separate architect/architecture-reviewer, security-analyst/security-reviewer, usability-designer/usability-reviewer, maintainer/maintenance-reviewer. Shared specialist knowledge, fresh independent review contexts. |
| SKILLS-20261110-184204 | Accepted | Block introduced/worsened violations and relevant existing faults; unrelated debt is advisory; material risk or scope expansion escalates. |
| SKILLS-20261110-184412 | Accepted | Architect specifies contracts, constraints, operational/migration/lifetime needs and verification; patterns/pseudocode only for consequential ambiguity, not mandatory scaffolding. |
| SKILLS-20261110-184642 | Deferred | Original CVE-exposure question was deferred out of the security role after the user's correction. No additional CVE risk-acceptance rule was adopted from this proposal. |
| SKILLS-20261110-184932 | Accepted | Security analyst/reviewer focus on coding risks; CVE monitoring/dependency remediation belong to maintenance. Explicitly corrects the initial security-role scope. |
| SKILLS-20261110-185027 | Accepted | Security review combines code paths with practical safe local adversarial checks; distinguish verified behavior, credible source evidence and suspicion. No production probing or universal exploit requirement. |
| SKILLS-20261110-185208 | Refined | Approved maintenance automation opens bounded PRs, not implicit merges/releases. User specifies Renovate; broader remit clarified by 185441. |
| SKILLS-20261110-185441 | Refined | Renovate limits the dependency-automation mechanism, not maintenance remit. User explicitly adds Nix tooling/dev environments, Docker/container images built with Nix, and Makefiles/Taskfiles. Direct implementation clarified by 195154. |
| SKILLS-20261110-185738 | Accepted | Product management supplies audience/task/environment/accessibility/convention brief; label minor assumptions, resolve consequential uncertainty. |
| SKILLS-20261110-185850 | Accepted | Usability covers relevant human AND automated consumption, preserving exit/output/noninteractive/redirection/recovery contracts without invented features. |
| SKILLS-20261110-191044 | Refined | Existing project conventions govern libraries, environment and commands. Taskfile/Cobra/Viper are not required; optional recommended-packages guidance requested. No universal testify mandate. |
| SKILLS-20261110-191600 | Accepted | Focused iteration/fix checks; project-required gates per review candidate; planned broader checks on integrated delivery. No full-system build per small edit. |
| SKILLS-20261110-193220 | Accepted | Supported external APIs/extension points need purpose, consumer scenarios and tests, not artificial internal callers. Distinguish unused internals and speculative work. |
| SKILLS-20261110-194652 | Accepted | Code reviewer owns implementation/API docs; usability reviewer owns user docs; architecture reviewer owns design consistency. No extra documentation-review agent by default. |
| SKILLS-20261110-194724 | Refined | User prioritizes untested behavior over percentages. Coverage is diagnostic absent an explicit project gate; no artificial tests/hooks for a metric. |
| SKILLS-20261110-194848 | Accepted | Seek concrete failure evidence for important changed behavior: genuine RED, pre-fix replay or safe targeted faults; validate intended failure. No mutate-every-test requirement. |
| SKILLS-20261110-194922 | Accepted | Shared contract suites require actual consistency promises, not every interface. Ordinary behavior tests can suffice; integration semantics need appropriate real checks. |
| SKILLS-20261110-195036 | Superseded | Proposed developer-delegated infrastructure implementation replaced by direct maintainer ownership/implementation in 195154. |
| SKILLS-20261110-195154 | Accepted | Maintainer directly plans/implements repository infrastructure with relevant Nix/Bash expertise; independent reviewers assess it. App development and coordinator integration remain separate. |
| SKILLS-20261110-195335 | Rejected | Language-independent code/test reviewer judgment rejected: user wants separate language reviewers for customization. Common transport/evidence/safety may still be shared. |
| SKILLS-20261110-195519 | Accepted | Each materially affected language gets its relevant reviewer pair, including embedded behavior. Incidental references/generated output/trivial metadata do not automatically add pairs; scopes stay bounded. |

No open role-design choice is inferred from silence. The deferred CVE question
remains historical, not an implementation requirement. Product/specialist approvals
for future projects remain distinct from this authorization to update skills.

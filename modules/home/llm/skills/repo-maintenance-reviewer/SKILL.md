---
name: repo-maintenance-reviewer
description: Use when reviewing dependency automation, repository configuration, developer environments, CI, packaging, or upgrade/release changes.
---

# Repository Maintenance Reviewer

Independently verify the maintainer's implemented work. Read `mtn-tasks`,
[review contract](../mtn-tasks/references/reviewing.md),
[maintenance guidance](../repo-maintainer/references/maintenance.md), and relevant
`nix`/`bash` or package-manager guidance. Do not reuse the maintainer's context.

## Procedure

1. Confirm revision, accepted maintenance scope, supported platforms, review key
   and verification budget.
2. Inspect Renovate scope/cadence, supported managers/advisory sources, credential
   permissions, PR boundaries and update-health handling. No custom updater or
   implicit auto-merge/release authority.
3. Check advisory applicability and claimed remediation evidence when relevant,
   compatibility/lockfile consistency, required checks and documented exceptions.
   Do not equate a new version with proven remediation.
4. Verify pinned/reproducible developer environments, Nix tooling/dev shells,
   Nix-built Docker/container images, CI, Makefiles/Taskfiles, packaging,
   installation/upgrades and rollback where affected.
5. Examine actual evaluation/build/tool/image evidence and independently perform
   relevant safe checks. Formatting alone does not prove the environment works.
6. Coordinate with separate language code/test reviewers without replacing them.
   Report concrete risks and unavailable platform checks, not fictional passes.

## Output

Protocol review JSON with `reviewer: maintenance`: accepted constraints ->
configuration/artifact evidence; stable findings and consequences;
Block/Advise/Escalate; actual checks, limitations and verdict.

## Boundaries

No implementation fixes, workflow mutations, waived advisories, exposed credentials,
risk acceptance, activation, publishing, deployment or destructive cleanup.
Those actions need their existing authority. Findings block by consequence, not
because an unrelated repository improvement could be made.

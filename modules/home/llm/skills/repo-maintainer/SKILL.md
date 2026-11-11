---
name: repo-maintainer
description: Use when repository health, dependency automation, developer environments, CI, packaging, or release readiness need work.
---

# Repository Maintainer

Own repository/infrastructure planning and implementation. Read
[maintenance guidance](references/maintenance.md),
[role boundaries](../delivery-coordinator/references/roles.md), and the
`mtn-tasks` worker contract when delegated.

## Inputs

Repository conventions, manifests/locks, Renovate configuration, advisory evidence,
supported platforms, Nix environments/image builds, Makefiles/Taskfiles, CI and
approved maintenance/release policy.

## Procedure

1. Inspect repository health and reproducibility. Own developer environments,
   Nix tooling/dev shells, Docker/container images built with Nix, Makefile/Taskfile
   workflows, CI hygiene, packaging, upgrades and release readiness.
2. Use Renovate for recurring dependency-update automation, not custom updater
   scripts. Own its configuration, bounded scope, cadence, credentials, failed
   updates and operational health.
3. Triage dependency advisories/CVEs here, not through the code-security analyst.
   Verify affected versions, available fixes and compatibility evidence; do not
   claim complete CVE coverage without checking supported managers/advisory sources.
4. Under an approved policy, automation detects/triages and opens bounded update
   PRs. Escalate consequential upgrades, incompatible fixes or unresolved exposure.
   No implicit auto-merge, publishing, deployment or risk acceptance.
5. Plan and directly implement authorized repository/infrastructure tasks. Load
   `nix`/`bash` and relevant tooling guidance. Application changes remain with
   the relevant developer. Test executable changes with focused iteration checks.
6. Before handoff, satisfy project-required build/lint/test/evaluation gates on the
   candidate; record commands, results and limitations. Include installation,
   image, upgrade and rollback checks where relevant.
7. Freeze the result for `repo-maintenance-reviewer` and applicable separate
   language code/test reviewers. The maintainer cannot approve its own work.

## Output

Inventory/findings; approved/proposed maintenance scope; Renovate policy/health;
environment/build/release constraints; changed files; regression and gate evidence;
compatibility/security impact; review needs, limitations and user decisions.
Implementation handoffs use the `mtn-tasks` build contract.

## Boundaries

No hidden advisories, disabled checks, leaked credentials, managed-record writes
when delegated, unauthorized upgrades, releases or destructive cleanup.
The coordinator owns integration; deployment/publishing retain existing permissions.
Missing checks are unavailable, not passing. Maintenance risk acceptance belongs
to the user, not a bot or reviewer.

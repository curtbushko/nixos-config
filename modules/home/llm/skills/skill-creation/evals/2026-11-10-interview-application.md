# Role interview application — verified 2026-11-11T02:35:03Z

## Scope

Applies the explicit decisions in
[the register](../../delivery-coordinator/references/decisions.md). Source base is
`6dccea4` plus the uncommitted first pass and interview changes. Nothing was
activated, committed, pushed or migrated in a live collection.

Planning/review roles are separate. Go/Node/Zig/Nix/Bash have separately customizable
code/test reviewers. New task review plans declare material languages/paths and
specialist triggers; those fields are fingerprinted. Unscoped original policies
remain for historical interpretation. Fresh dispatches require a review plan;
identical existing dispatch retries retain idempotency.

## Executable evidence

All commands below exited successfully on source during this application:

- `skill-creation/tests/contracts_test.sh`: role names, descriptions, links and word budgets.
- `skill-creation/tests/runner_test.sh`: every scenario visited and existing artifacts preserved.
- `mtn-tasks/tests/go_roles_test.sh`: scoped Go code/test identity and gate behavior.
- `mtn-tasks/tests/review_plan_test.sh`: material mixed-language scopes, required specialists,
  stale/negative/missing verdicts, integration IDs, fingerprint inclusion, carry-forward
  linkage, historical compatibility and canonical validation entries.
- `mtn-tasks/tests/protocol_test.sh`, `policy_test.sh`, `rex_policy_test.sh`.
- `zig-team/tests/policy_test.sh`: updated role/verification/resource policy.
- `modules/home/scripts/tests/mtn-workflow_test.sh`: real facade publication rejects
  fresh planless dispatch without changing legacy inspection behavior.
- `modules/home/scripts/tests/mtn-workflow_compact_test.sh`: native scoped Go and
  maintenance publication, integration and summary compaction.
- `mtn-tasks/tests/delivery_test.sh`: deterministic mixed Go/Node fixture delivery,
  rejection/fix/new-build reviews and failed combined-candidate checks.
- `modules/home/scripts/tests/mtn-rex_test.sh`: fixture-provider launch, persisted
  identity and distinct Go/Bash code/test run/window names in one task attempt.
- `mtn-tasks/tests/hardening_test.sh`: evidence recovery and workflow hardening.
- ShellCheck, shfmt and `git diff --check` for changed executable source/tests.

Hardening, delivery and compaction passed before the final naming-only helper fix;
their state/fingerprint/dispatch paths were unchanged afterward. The naming change
was covered by focused guard tests and the final native fixture-provider launch test.
The final short structural/protocol/shell gates were rerun after that fix.
Native launch tests use a fixture provider, not real Rex windows or LLM workers.

## Behavioral smoke evidence

Model `openai-codex/gpt-6.1-sol`, low thinking, fresh ephemeral contexts, no tools,
extensions, MCP, automatic skills or context files. The checked-in runner saved
exact prompts, context hashes and responses. Eighteen candidate scenarios were
manually inspected. This is judgment/output evidence, not real implementation,
security exploitation, UI interaction or user research.

Observed appropriate behavior included:
- Code-security analysis identified shell injection/token exposure without CVE searching.
- Maintenance selected Renovate and direct maintainer ownership of Nix/image/Taskfile work.
- Usability labeled inspection unverified and rejected destructive config deletion.
- Architecture avoided speculative packages and unrelated-debt blockers.
- Go preserved native tests/stdlib CLI/Make/Nix rather than requiring new frameworks.
- Public APIs were not declared dead solely from missing internal callers.
- Low coverage alone did not block; reviewers sought behavior/assertion evidence.
- Mixed-language selection included actual embedded behavior and triggered specialists.
- Integrated outcomes distinguished demonstrated behavior from source-only or reported claims.

Three issues were observed and corrected:
1. Product management unnecessarily asked to reopen an explicit rejection. Added an
   evidence-conditioned decision slot; two same-scenario reruns returned no user decision
   needed and preserved the existing boundary.
2. Go code/test review JSON used noncanonical validation keys/statuses. Tightened the
   output recipe and guard; two reruns per reviewer used canonical arrays and all four
   responses passed `workflow.jq:valid_event`.
3. Independent source audit found language-prefix stripping collided Go/Bash seats.
   Added a failing uniqueness test, preserved full new seat names, and added actual
   fixture launch assertions for all four Go/Bash code/test identities. The rerun passed.

The first source audit and follow-up used a separate read-only Pi context on the same
model family, not cross-family verification. Follow-up reported no blockers; its one
naming-documentation inconsistency was corrected. It did not execute tests itself.

Artifacts were retained under `/tmp/skill-agreements-evals-20261110`,
`/tmp/skill-agreements-refined-*-20261110`, and `/tmp/skill-agreements-*.log`/`.txt`.
These are run-local evidence, not deployment dependencies. The earlier first-pass
report remains historical and is not overwritten by these results.

## Final relevant source hashes

| Source | SHA-256 |
|---|---|
| mtn-tasks/scripts/workflow.jq | b62949634d98672457e1011b0c6b5bd584e191ee6e27cf0af98bdc419742174e |
| mtn-tasks/scripts/facade.jq | d5165616dc375398a63c4fdc19f5c22f3138db06ec02f1bed171776537c43ad6 |
| modules/home/scripts/mtn-rex | 1e57844022ec2a1aa50ad88646d81ce948dd1ea15f55db9d8f389dff0926cc74 |
| modules/home/scripts/mtn-workflow | b95a7dcd6e1ebc92dbe2713ac52b014b8a4d541d74d4748797e452d82d5cc328 |
| product-manager/SKILL.md | e6d82cba26d0730f393a2762483f2202a25c185857dd50eb4bfcb28ed89cca72 |
| go-reviewer/SKILL.md | 402e58d6047df51f4c04137dc391360823323aa2532a8f310b5f9d5af5d3af00 |

## Limits

No claim that every role/language has exhaustive behavioral evaluation. No live
Renovate installation, dependency PR, Nix activation, container deployment, user
research or complete LLM-driven delivery was performed. Structural guards enforce
declared scopes and identity, not honesty of semantic trigger rationale, unaffected
assumptions or command claims. The coordinator and independent reviewers must inspect
actual changes and evidence. Old deployed copies remain unchanged until authorized
Home Manager activation.

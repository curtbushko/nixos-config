# Task Review Plans

Record `implementation.reviewPlan` in new task specifications, before plan approval.
It is part of the semantic fingerprint. The following is an illustrative shape;
paths and rationale must reflect the actual approved task:

```json
{
  "languages": [
    {"language":"go","paths":["cmd/import"]},
    {"language":"bash","paths":["scripts/import-fixture.sh"]}
  ],
  "specialists": {
    "architecture":{"required":false,"reason":"No consequential contract/design change"},
    "security":{"required":true,"reason":"Untrusted file paths reach filesystem writes"},
    "usability":{"required":true,"reason":"CLI failure and recovery behavior changes"},
    "maintenance":{"required":false,"reason":"No environment/dependency/build change"}
  }
}
```

## Selection and task shaping

Every specialist has a required boolean and concrete reason, including false.
Triggers are consequential interfaces/persistence/cross-component/operations
(architecture); coding trust/sensitive-data/permission paths (security); user or
automation workflows/defaults/help/errors/recovery/accessibility (usability);
dependencies, Renovate, CI, Nix tooling/dev shells, Nix-built images, Makefiles/
Taskfiles, packaging/upgrades/releases (maintenance).

Planning specialists establish constraints, tests and evidence before implementation.
Accepted constraints can be made concrete in tasks; new scope needs user approval.
The maintainer plans and implements repository/infrastructure changes, loading Nix/
Bash guidance. It cannot review its own output. Application changes use language
developers. Product management leads discovery and owns outcome criteria.

List every materially affected language and bounded paths, including embedded
scripts. Do not infer scope from the primary language alone. Incidental references,
generated output and trivial metadata need no automatic extra pair; still examine
the generation source/consumer contract when relevant. The coordinator and reviewers
must inspect the actual diff to validate selection. Structural guards cannot infer
semantic risk or honesty from a reason string.

## Review keys and routing

Go, Node, Zig, Nix and Bash each have separate code/test reviewer skills. Keys in
new plans are `go:code`, `go:test`, `node:code`, etc. Keep their criteria independently
customizable; share only transport/evidence/safety contracts. Existing Lua/docs
source-only routing remains `lua:combined`/`docs:combined`, not Go policy.

Triggered specialist keys are `architecture`, `security`, `usability` and
`maintenance`, routed to their matching reviewer skills. There is no default
comment-review seat: code reviewers own implementation/API docs, usability reviewers
own user docs, architecture reviewers own design consistency.

All required scopes approve the same build/attempt/head/tree/specHash. Reviewers
receive the exact assigned key. Unqualified legacy verdicts cannot satisfy a
declared language-scoped plan. Every integration references all current required
review IDs, not just the primary-language pair.

## Changes and historical records

Re-evaluate selection after actual changes. A review-plan change alters specHash
and needs the existing plan-impact/approval process; do not quietly broaden or
weaken a reviewed task. Explicit user-approved constraints are authoritative.
Adding a triggered review within the already accepted policy is routine coordination,
not a new product decision. Refresh fingerprints/attempts and record the governing
bounded authorization; never invent a new explicit user approval. Material scope,
public-contract/security decisions or weakening an accepted gate still require
user approval. The fingerprint change prevents stale verdict reuse; it does not
itself turn every dispatch adjustment into a human approval gate.

Historical records without a review plan retain their original unscoped inspection
policy (including old combined or Zig four-specialty proof); installing skills does
not reinterpret completed history. New dispatch publication requires a valid task
review plan; only identical existing dispatch retries can retain legacy idempotency.
This is not permission to dispatch new work without one. Preserve completed
summaries and original identities; inspect/replan active legacy work rather than
inventing triggers or rewriting old approvals. No live collection migration is
authorized merely by installing updated skills.

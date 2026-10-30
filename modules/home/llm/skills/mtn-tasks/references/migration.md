# Approval-Gated Migration

Changing these skills does not authorize migration of any existing project.

## Detect before initialization

Inspect repository-local legacy `.phases/`, task/status/result YAML, and any nonempty
`.tasks/` lacking a valid mdbase configuration. Diagnose existing collections without
writing. Never run `init --force`, infer approval from an earlier skill update, or
silently keep writing legacy coordination files.

Ask for **explicit approval** of a concrete plan naming:

- source files, destination `.tasks/` collection, project identity and path mapping
- PRDs, optional RFC/designs, phases, task specs, lifecycle values, native links,
  stable REQ identifiers, ownership metadata and explicit prerequisites
- treatment of review/build history, partial completion, ambiguity, and missing evidence
- preservation/backup location outside collection discovery scope
- any required schema extension and who owns its authoritative configuration

If approval is absent, stop without changing that project. Offer a new-project
workflow only if the user explicitly chooses it; do not create parallel truth.

## Execute only the approved plan

1. Preserve originals byte-for-byte in a collision-free ignored `.trash/` location
   outside `.tasks/` discovery. Copy first; do not destroy or overwrite originals.
   For a legacy nonempty `.tasks/`, agree how it will be relocated before initialization.
2. Initialize an empty destination with `mtn init`, or diagnose its existing schema.
   Do not hand-author record frontmatter or regenerate a live schema.
3. Create project/PRD/phase/task records through `agent create`, carrying full prose
   in descriptions. Use stable retry identities when schema permits; record the
   source-to-exact-ref mapping as a project migration evidence note.
4. Create native memberships and explicit prerequisites after all targets exist.
   Preserve old evidence without pretending it is current approval/review. For
   existing plain mtn notes, append an explicitly approved v1 historical declaration
   naming their exact native intent hashes. The facade retains originals and creates
   non-gating views for only those intents; unsupported protocol versions still fail
   closed. For external YAML/results, create v1 historical events with original
   content/provenance and gateEligible:false. Obtain approval for interpretation; versioned delivery guards
   must not silently discard legacy notes. Build new current document/plan manifests
   with actual approval and fingerprints. Do not fabricate integration proof for old
   task completion. A v1 baseline event must include approvedBy/decisionEvidence,
   reviewEquivalent:false, real targetBranch/targetCommit/targetTree and passing
   verification. The facade checks native completion and Git target ancestry/tree
   before using the baseline as a delivered prerequisite. A newer dispatch supersedes
   baseline state; unresolved blockers still apply.
5. Map statuses only after diagnosing completed/incomplete values. Ask about
   inconsistent task/phase statuses and missing prerequisite targets.
6. Validate every record/graph; compare counts, descriptions, coverage, relationships,
   statuses, and preserved history against originals. Query hierarchy and readiness.
   Verify exclusions and absence of live backup files in discovery scope.
7. Present the migration verification. Move legacy files out of active use only as
   approved, preserving backups. Do not dual-write indexes, counters, or results.

mtn does not offer multi-record transactions or exclusive task claims. Stop other
writers during migration. On partial failure, inspect existing refs and evidence,
resume idempotently, and report exactly which steps remain. Never roll back over
newer human changes. No production vault or project is migrated by the skill tests.

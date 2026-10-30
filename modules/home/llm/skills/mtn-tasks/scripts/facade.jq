# Only explicitly authorized legacy intents become non-gating historical views.
def evidence_events:
  .result as $r |
  [$r.evidence[]? | (.content | try fromjson catch null) |
    select(type == "object" and .schemaVersion == 1)] as $typed |
  [$typed[] | select(.kind == "historical" and (.approvedBy | type == "string" and length > 0) and
    (.decisionEvidence | type == "string" and length > 0)) | . as $authorization |
    (.legacyIntents // [])[] | {intent:.,authorization:$authorization.eventId}] as $imports |
  [($r.evidence // [] | to_entries[]) | .key as $index | .value as $note | ($note.content | try fromjson catch null) as $event |
    if ($event | type) == "object" and ($event | has("schemaVersion")) then
      if $event.schemaVersion == 1 then $event else error("Unsupported evidence version") end
    else
      ([$imports[] | select(.intent == $note.intent)] | first) as $import |
      if $import == null then error("Unclassified historical evidence: approve an import of its mtn intent first")
      else {schemaVersion:1,eventId:("legacy/"+($index|tostring)+"/"+$note.intent),kind:"historical",recordRef:$r.ref,
        specHash:"historical",attempt:1,content:$note.content,provenance:("Authorized by "+$import.authorization),gateEligible:false}
      end
    end];
# Administrative title/order changes do not invalidate semantic implementation reviews.
def semantic_spec($mapping):
  .result as $r | $r.frontmatter as $f |
  {ref:$r.ref,kind:$f.workflowKind,description:$r.description} +
  (if $f.workflowKind == "prd" or $f.workflowKind == "design" then {}
   else {language:$f.workflowLanguage,requirements:$f.workflowRequirements,
     documents:$f.workflowDocuments,ownership:$f.workflowOwnership,gates:$f.workflowGates,
     projects:$f[$mapping.projects // "projects"],blockedBy:$f[$mapping.blockedBy // "blockedBy"]}
   end);

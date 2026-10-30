# Context digests are computed by the shell from native content bytes, not trusted
# from event payloads. This projection never rewrites the original note.
def recovery_bindings($r; $context; $entries):
  [$entries[] | select(.event | type == "object" and has("schemaVersion"))] as $protocol |
  [$protocol[] | select(.event.kind == "recovery")] as $recoveries |
  if ($recoveries | length) == 0 then []
  elif ([$protocol[].event.eventId] |
        length != (unique | length)) then error("Duplicate evidence eventId")
  elif ($recoveries | map(.event.replacementEventId) | length != (unique | length)) then
    error("Recovery replacement identities must be unique")
  else
    [$recoveries[] | . as $entry | .event as $a |
      if ($entry.valid | not) then error("Invalid recovery authorization")
      elif ($r.frontmatter.workflowKind != "prd" and $r.frontmatter.workflowKind != "design") or
           $context.collectionRoot != $a.collectionRoot or
           ($context.contentDigests | type) != "array" or
           ($context.contentDigests | length) != ($entries | length) or $a.recordRef != $r.ref then
        error("Recovery collection, record or current fingerprint mismatch")
      else
        [$protocol[] | select(.event.eventId == $a.target.eventId)] as $targets |
        ([$recoveries[] | select(.index < $entry.index and .event.target.eventId == $a.target.eventId)] | last) as $previous |
        if ($previous == null and ($a | has("supersedesRecoveryEventId"))) or
           ($previous != null and ($a.supersedesRecoveryEventId != $previous.event.eventId or
             $a.target != $previous.event.target)) then error("Conflicting or non-linear recovery reassessment")
        elif ($targets | length) != 1 then error("Missing or ambiguous recovery target")
        else $targets[0] as $target |
          if $target.index >= $entry.index or
             $target.event.schemaVersion != 1 or $target.event.kind != "approval" or
             $target.event.recordRef != $r.ref or $target.event.specHash != $a.target.specHash or
             $target.valid or $target.note.intent != $a.target.intent or
             $context.contentDigests[$target.index] != $a.target.contentDigest or
             ([$entries[] | select(.note.intent == $a.target.intent)] | length) != 1 then
            error("Recovery does not match one earlier malformed approval")
          elif any($protocol[] | select(.event.eventId == $a.replacementEventId);
            .index <= $entry.index or (.valid | not) or
            .event.kind != "approval" or .event.decision != "approved" or
            .event.recordRef != $r.ref or .event.specHash != $a.specHash) then
            error("Invalid recovery replacement approval")
          else {index:$target.index,authorization:$a.eventId,target:$a.target,specHash:$a.specHash} end
        end
      end] |
    # Only the last explicitly authorized link governs each original target.
    group_by(.index) | map(last) |
    if $context.allowStaleRecoveryTips == true or all(.[]; .specHash == $context.specHash) then map(del(.specHash))
    else error("Recovery current fingerprint mismatch; explicit reassessment required") end
  end;

# Only explicitly authorized targets become non-gating historical views.
def evidence_events(validator):
  .result as $r | .recoveryContext as $context |
  [($r.evidence // [] | to_entries[]) |
    (.value.content | try fromjson catch null) as $event |
    {index:.key,note:.value,event:$event,valid:($event | try validator catch false)}] as $entries |
  if any($entries[]; (.event | type) == "object" and (.event | has("schemaVersion")) and .event.schemaVersion != 1)
  then error("Unsupported evidence version") else . end |
  recovery_bindings($r; $context; $entries) as $bindings |
  [$r.evidence[]? | (.content | try fromjson catch null) |
    select(type == "object" and .schemaVersion == 1)] as $typed |
  [$typed[] | select(.kind == "historical" and (.approvedBy | type == "string" and length > 0) and
    (.decisionEvidence | type == "string" and length > 0)) | . as $authorization |
    (.legacyIntents // [])[] | {intent:.,authorization:$authorization.eventId}] as $imports |
  [($r.evidence // [] | to_entries[]) | .key as $index | .value as $note | ($note.content | try fromjson catch null) as $event |
    ([$bindings[] | select(.index == $index)] | first) as $binding |
    if $binding != null then
      {schemaVersion:1,eventId:$event.eventId,kind:"historical",recordRef:$r.ref,
       specHash:$event.specHash,attempt:1,content:$note.content,
       provenance:("Malformed approval quarantined by " + $binding.authorization),gateEligible:false,
       originalNote:$note,quarantine:$binding}
    elif ($event | type) == "object" and ($event | has("schemaVersion")) then
      $event
    else
      ([$imports[] | select(.intent == $note.intent)] | first) as $import |
      if $import == null then error("Unclassified historical evidence: approve an import of its mtn intent first")
      else {schemaVersion:1,eventId:("legacy/"+($index|tostring)+"/"+$note.intent),kind:"historical",recordRef:$r.ref,
        specHash:"historical",attempt:1,content:$note.content,provenance:("Authorized by "+$import.authorization),gateEligible:false}
      end
    end] as $events |
  # Generated legacy identities occupy the same namespace as native event IDs.
  # Validate reservations after projection too, before any caller can append.
  if ([$events[].eventId] | length != (unique | length)) then error("Duplicate effective evidence eventId")
  elif any($events | to_entries[] | select(.value.kind == "recovery"); . as $authorization |
    any($events | to_entries[] | select(.value.eventId == $authorization.value.replacementEventId);
      .key <= $authorization.key or .value.kind != "approval" or .value.decision != "approved" or
      .value.recordRef != $authorization.value.recordRef or .value.specHash != $authorization.value.specHash))
  then error("Recovery replacement collides with an effective evidence identity")
  else $events end;
# Legacy callers can read ordinary evidence, but cannot authorize recovery without a guard.
def evidence_events: evidence_events(false);
# Administrative title/order changes do not invalidate semantic implementation reviews.
def semantic_spec($mapping):
  .result as $r | $r.frontmatter as $f |
  {ref:$r.ref,kind:$f.workflowKind,description:$r.description} +
  (if $f.workflowKind == "prd" or $f.workflowKind == "design" then {}
   else {language:$f.workflowLanguage,requirements:$f.workflowRequirements,
     documents:$f.workflowDocuments,ownership:$f.workflowOwnership,gates:$f.workflowGates,
     projects:$f[$mapping.projects // "projects"],blockedBy:$f[$mapping.blockedBy // "blockedBy"]}
   end);

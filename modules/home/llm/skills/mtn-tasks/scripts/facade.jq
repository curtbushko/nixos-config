# Canonical grouped work-item projection. Native mtn fields such as title, id and
# hierarchy are adapted into the domain model; workflow metadata is grouped only.
def canonical_event:
  walk(if type == "object" then
    with_entries(.key = ({eventId:"eventID",runId:"runID",dispatchEventId:"dispatchEventID",parentRunId:"parentRunID",sourceEventId:"sourceEventID",replacementEventId:"replacementEventID",supersedesRecoveryEventId:"supersedesRecoveryEventID",blockerEventId:"blockerEventID",buildEventId:"buildEventID",integrationEventId:"integrationEventID"}[.key] // .key))
  else . end);
def dependency_ref:
  (.ref // .resolution.ref // .uid // "") |
  sub("^\\[\\["; "") | sub("\\]\\]$"; "");
def dependency_relation:
  (.relation // .reltype // "finish-to-start") | ascii_downcase |
  gsub("finish[ _-]?to[ _-]?start"; "finish-to-start");
def normalized_dependencies($frontmatter; $native):
  ($frontmatter.scope.dependencies // $native.blockedBy // []) |
  if type != "array" then [] else
    map(select(type == "object") | {ref:dependency_ref,relation:dependency_relation} | select(.ref != ""))
  end;
def canonical_work_item:
  .result as $r | ($r.frontmatter // {}) as $f |
  $f.identity.kind as $kind |
  ($r.hierarchy.parents // []) as $parents |
  ({identity:({uuid:($f.identity.uuid // $f.id),kind:$kind} +
      (if $kind == "task" then {taskID:$f.identity.taskID}
       elif $kind == "phase" then {phaseID:$f.identity.phaseID}
       elif $kind == "project" then {projectID:$f.identity.projectID}
       else {} end)),
   presentation:{displayName:($f.presentation.displayName // $f.title),description:($f.presentation.description // $r.description // "")},
   structure:{parentRef:($parents[0].resolution.ref // null),order:$f.structure.order},
   scope:{requirements:($f.scope.requirements // []),documents:($f.scope.documents // []),dependencies:normalized_dependencies($f; ($r.dependencies // {}))},
   lifecycle:{state:($f.lifecycle.state // null),sourceEventID:($f.lifecycle.sourceEventID // null),changedAt:($f.lifecycle.changedAt // null),nativeStatus:($f.status // null)},
   execution:($f.execution // {}),
   implementation:{language:$f.implementation.language,ownership:$f.implementation.ownership,gates:($f.implementation.gates // [])}}) as $item |
  if ($parents | length) > 1 then error("Work item has multiple parents")
  elif ($kind == "project" or $kind == "prd" or $kind == "design") and ($parents | length) != 0 then error("Root work item has a parent")
  elif ($kind == "phase" or $kind == "task") and ($parents | length) != 1 then error("Phase/task must have exactly one parent")
  elif ($item.identity.uuid | type) != "string" or ($item.identity.uuid | length) == 0 then error("Work item is missing identity.uuid")
  elif ($kind == "task" and (($item.identity.taskID | type) != "string" or ($item.identity.taskID | length) == 0)) then error("Task is missing identity.taskID")
  elif ($kind == "phase" and (($item.identity.phaseID | type) != "string" or ($item.identity.phaseID | length) == 0)) then error("Phase is missing identity.phaseID")
  elif ($kind == "project" and (($item.identity.projectID | type) != "string" or ($item.identity.projectID | length) == 0)) then error("Project is missing identity.projectID")
  else $item end;

# Context digests are computed by the shell from native content bytes, not trusted
# from event payloads. This projection never rewrites the original note.
def relocation_authorized($context; $event):
  $context.allowCollectionRelocation == true and
  ($context.relocation | type == "object") and
  $context.relocation.fromRoot == $event.collectionRoot and
  ($context.relocation.approvedBy | type == "string" and length > 0) and
  ($context.relocation.reason | type == "string" and length > 0);
def recovery_bindings($r; $context; $entries):
  [$entries[] | select(.event | type == "object" and has("schemaVersion"))] as $protocol |
  [$protocol[] | select(.event.kind == "recovery")] as $recoveries |
  if ($recoveries | length) == 0 then []
  elif ([$protocol[].event.eventID] |
        length != (unique | length)) then error("Duplicate evidence eventID")
  elif ($recoveries | map(.event.replacementEventID) | length != (unique | length)) then
    error("Recovery replacement identities must be unique")
  else
    [$recoveries[] | . as $entry | .event as $a |
      if ($entry.valid | not) then error("Invalid recovery authorization")
      elif (($r.frontmatter.identity.kind != "prd" and $r.frontmatter.identity.kind != "design")) or
           ($context.collectionRoot != $a.collectionRoot and (relocation_authorized($context; $a) | not)) or
           ($context.contentDigests | type) != "array" or
           ($context.contentDigests | length) != ($entries | length) or $a.recordRef != $r.ref then
        error("Recovery collection, record or current fingerprint mismatch")
      else
        [$protocol[] | select(.event.eventID == $a.target.eventID)] as $targets |
        ([$recoveries[] | select(.index < $entry.index and .event.target.eventID == $a.target.eventID)] | last) as $previous |
        if ($previous == null and ($a | has("supersedesRecoveryEventID"))) or
           ($previous != null and ($a.supersedesRecoveryEventID != $previous.event.eventID or
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
          elif any($protocol[] | select(.event.eventID == $a.replacementEventID);
            .index <= $entry.index or (.valid | not) or
            .event.kind != "approval" or .event.decision != "approved" or
            .event.recordRef != $r.ref or .event.specHash != $a.specHash) then
            error("Invalid recovery replacement approval")
          else {index:$target.index,authorization:$a.eventID,target:$a.target,specHash:$a.specHash} end
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
    (.value.content | try fromjson catch null | canonical_event) as $event |
    {index:.key,note:.value,event:$event,valid:($event | try validator catch false)}] as $entries |
  if any($entries[]; (.event | type) == "object" and (.event | has("schemaVersion")) and .event.schemaVersion != 1)
  then error("Unsupported evidence version") else . end |
  recovery_bindings($r; $context; $entries) as $bindings |
  [$r.evidence[]? | (.content | try fromjson catch null | canonical_event) |
    select(type == "object" and .schemaVersion == 1)] as $typed |
  [$typed[] | select(.kind == "historical" and (.approvedBy | type == "string" and length > 0) and
    (.decisionEvidence | type == "string" and length > 0)) | . as $authorization |
    (.legacyIntents // [])[] | {intent:.,authorization:$authorization.eventID}] as $imports |
  [($r.evidence // [] | to_entries[]) | .key as $index | .value as $note | ($note.content | try fromjson catch null | canonical_event) as $event |
    ([$bindings[] | select(.index == $index)] | first) as $binding |
    if $binding != null then
      {schemaVersion:1,eventID:$event.eventID,kind:"historical",recordRef:$r.ref,
       specHash:$event.specHash,attempt:1,content:$note.content,
       provenance:("Malformed approval quarantined by " + $binding.authorization),gateEligible:false,
       originalNote:$note,quarantine:$binding}
    elif ($event | type) == "object" and ($event | has("schemaVersion")) then
      $event
    else
      ([$imports[] | select(.intent == $note.intent)] | first) as $import |
      if $import == null then error("Unclassified historical evidence: approve an import of its mtn intent first")
      else {schemaVersion:1,eventID:("legacy/"+($index|tostring)+"/"+$note.intent),kind:"historical",recordRef:$r.ref,
        specHash:"historical",attempt:1,content:$note.content,provenance:("Authorized by "+$import.authorization),gateEligible:false}
      end
    end] as $events |
  # Generated legacy identities occupy the same namespace as native event IDs.
  # Validate reservations after projection too, before any caller can append.
  if ([$events[].eventID] | length != (unique | length)) then error("Duplicate effective evidence eventID")
  elif any($events | to_entries[] | select(.value.kind == "recovery"); . as $authorization |
    any($events | to_entries[] | select(.value.eventID == $authorization.value.replacementEventID);
      .key <= $authorization.key or .value.kind != "approval" or .value.decision != "approved" or
      .value.recordRef != $authorization.value.recordRef or .value.specHash != $authorization.value.specHash))
  then error("Recovery replacement collides with an effective evidence identity")
  else $events end;
# Legacy callers can read ordinary evidence, but cannot authorize recovery without a guard.
def evidence_events: evidence_events(false);
# Administrative title/order changes do not invalidate semantic implementation reviews.
def semantic_spec($mapping):
  . as $show | ($show | canonical_work_item) as $item |
  .result as $r |
  {ref:$r.ref,kind:$item.identity.kind,description:$item.presentation.description} +
  (if $item.identity.kind == "prd" or $item.identity.kind == "design" then {}
   else {language:$item.implementation.language,requirements:$item.scope.requirements,
     documents:$item.scope.documents,ownership:$item.implementation.ownership,gates:$item.implementation.gates,
     parentRef:$item.structure.parentRef,dependencies:$item.scope.dependencies}
   end);

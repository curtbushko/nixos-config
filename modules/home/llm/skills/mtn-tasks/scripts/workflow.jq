# Read-only guards over ephemeral snapshots derived from mtn. No writes or claims.
# Rex transport identity is evidence, not task completion or a host lease.
def rex_string: type == "string" and length > 0 and (test("[\u0000-\u001f]") | not);
def rex_run_id:
  type == "string" and length <= 100 and test("^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$");
def rex_launch_metadata:
  ([.recordRef,.specHash,.worktree,.model,.thinking] | all(.[]; rex_string)) and
  (.runId | rex_run_id) and
  (.skill | type == "string" and test("^[a-z][a-z0-9-]*$")) and
  (.attempt | type == "number" and . >= 1 and floor == .) and
  (.thinking as $t | ["off","minimal","low","medium","high","xhigh","max"] | index($t) != null) and
  (.worktree | startswith("/")) and
  (if .role == "coordinator" then
     .handoff == true and (.skill as $s | ["go-team","node-team","zig-team"] | index($s) != null)
   elif .role == "builder" or .role == "reviewer" then
     ([.phaseRef,.dispatchEventId] | all(.[]; rex_string)) and (.parentRunId | rex_run_id)
   elif .role == "planner" then
     (.phaseRef | rex_string) and (.parentRunId | rex_run_id)
   else false end);
def rex_request:
  rex_launch_metadata and (.prompt | type == "string" and length > 0 and (contains("\u0000") | not));
def rex_runtime:
  rex_launch_metadata and
  ([.sessionName,.windowName,.transportDir] | all(.[]; rex_string)) and
  .piSessionId == .runId and
  (if has("rexSessionName") or has("rexWindowName") or has("piSessionName") then
     ([.rexSessionName,.rexWindowName,.piSessionName] | all(.[]; rex_string)) and
     .rexSessionName == .sessionName and .rexWindowName == .windowName and
     .piSessionName == .rexWindowName
   else true end) and
  (.host | [.endpoint,.hostId,.instanceId] | all(.[]; rex_string)) and
  (.host.endpoint | startswith("unix://")) and
  (if .stage == "reserved" then true
   elif .stage == "launched" then
     (.rexSessionId | rex_string and startswith("session:")) and
     (.rexWindowId | rex_string and startswith("window:")) and
     (.rexBlockId | rex_string and startswith("block:"))
   else false end);
def nonempty: type == "string" and length > 0;
def positive_integer: type == "number" and . >= 1 and floor == .;
def checks_pass:
  type == "array" and length > 0 and all(.[];
    (.command | nonempty) and .result == "pass");
# A recovery is narrow authorization, never a replacement document approval.
def recovery_authorization:
  .decision == "approved" and .disposition == "quarantine-malformed-approval" and
  ([.approvedBy,.decisionEvidence,.replacementEventId] | all(.[]; nonempty)) and
  (.collectionRoot | nonempty and startswith("/")) and
  (.target | type == "object" and
    ([.eventId,.specHash] | all(.[]; nonempty)) and
    (.intent | type == "string" and test("^[0-9a-f]{64}$")) and
    (.contentDigest | type == "string" and test("^sha256:[0-9a-f]{64}$"))) and
  .target.eventId != .eventId and .replacementEventId != .eventId and
  .replacementEventId != .target.eventId and
  (if has("supersedesRecoveryEventId") then
    (.supersedesRecoveryEventId | nonempty) and .supersedesRecoveryEventId != .eventId
   else true end);
def valid_event:
  (.schemaVersion == 1) and (.eventId | nonempty) and
  (.recordRef | nonempty) and (.specHash | nonempty) and
  (.attempt | positive_integer) and
  (if .kind == "approval" then
     (.decision == "approved" or .decision == "rejected") and
     ([.approvedBy,.decisionEvidence] | all(.[];nonempty))
   elif .kind == "plan" then
     .decision == "approved" and (.records | type == "array" and length > 0) and
     ([.approvedBy,.decisionEvidence] | all(.[];nonempty))
   elif .kind == "dispatch" then
     ([.runId,.baseCommit,.branch,.worktree,.targetBranch] | all(.[]; nonempty))
   elif .kind == "runtime" then rex_runtime
   elif .kind == "recovery" then recovery_authorization
   elif .kind == "build" then
     ([.dispatchEventId,.head,.tree] | all(.[]; nonempty)) and
     (.outcome == "blocked" or (.outcome == "ready-for-review" and (.validation | checks_pass)))
   elif .kind == "review" then
     ([.buildEventId,.head,.tree,.reviewer] | all(.[]; nonempty)) and
     (.reviewer as $r | ["combined","code","comment","architecture","test"] | index($r) != null) and
     (.changes_required | type == "array") and
     ((.verdict == "APPROVED" and (.changes_required | length == 0) and (.validation | checks_pass)) or
      (.verdict == "CHANGES_NEEDED" and (.changes_required | length > 0)))
   elif .kind == "integration" then
     ([.buildEventId,.head,.tree,.targetBranch,.targetBase] | all(.[]; nonempty)) and
     (.reviewEventIds | type == "array" and all(.[]; nonempty)) and
     (if .outcome == "failed" then
        ([.candidateCommit,.candidateTree] | all(.[]; nonempty)) and
        (.validation | type == "array" and any(.[]; .result == "fail"))
      elif .outcome == "passed" then
        ([.integratedCommit,.integratedTree] | all(.[]; nonempty)) and (.validation | checks_pass)
      else false end)
   elif .kind == "milestone" then
     ([.targetCommit,.targetTree,.targetBranch] | all(.[]; nonempty)) and
     (.records | type == "array" and length > 0) and (.validation | checks_pass)
   elif .kind == "completion" then (.integrationEventId | nonempty)
   elif .kind == "historical" then
     (.content | type == "string") and (.provenance | nonempty) and .gateEligible == false
   elif .kind == "baseline" then
     ([.approvedBy,.decisionEvidence,.targetCommit,.targetTree,.targetBranch] | all(.[]; nonempty)) and
     .reviewEquivalent == false and (.validation | checks_pass)
   elif .kind == "blocker" then (.reason | nonempty)
   elif .kind == "resume" then (.blockerEventId | nonempty)
   elif .kind == "release" then
     (.dispatchEventId | nonempty) and (.outcome == "stopped" or .outcome == "finished")
   else false end);
def document_approved:
  . as $s |
  (any(.events[]; (valid_event | not)) | not) and
  ([.events[].eventId] | length == (unique | length)) and
  # Quarantine cannot expose an unrelated earlier approval as current authority.
  # Superseded authorizations stay visible, but only the active chain tip governs.
  all(.events[] | select(.kind == "recovery") | . as $a |
    select(any($s.events[]; .kind == "recovery" and .supersedesRecoveryEventId == $a.eventId) | not);
    . as $recovery |
    .recordRef == $s.ref and .specHash == $s.specHash and
    any($s.events[(($s.events | index($recovery)) + 1):][];
      .eventId == $recovery.replacementEventId and .kind == "approval" and
      .recordRef == $s.ref and .specHash == $s.specHash and .decision == "approved")) and
  (([.events[] | select(.kind == "approval" and .recordRef == $s.ref and .specHash == $s.specHash)] | last | .decision) == "approved");
def plan_approved:
  . as $s |
  ([$s.events[] | select(.kind == "plan" and .recordRef == $s.ref and .specHash == $s.specHash)] | last) as $plan |
  $plan != null and ($plan | valid_event) and
  (any($s.events[]; (valid_event | not)) | not) and
  ([$s.events[].eventId] | length == (unique | length)) and
  ($s.documents | all(.[]; document_approved)) and
  (($plan.documents | sort_by(.ref)) == ([$s.documents[] | {ref,hash:.specHash}] | sort_by(.ref))) and
  (($plan.records | sort_by(.ref)) == ([$s.records[] | {ref,specHash}] | sort_by(.ref))) and
  ($s.records | length > 0) and
  ([$s.records[].ref] | length == (unique | length)) and
  ($plan.coverage | type == "object") and
  all($s.requirements[]; . as $req |
    ($plan.coverage[$req] | type == "array" and length > 0) and
    all($plan.coverage[$req][]; . as $ref |
      any($s.records[]; .ref == $ref and (.requirements | index($req) != null)))) and
  all($plan.coverage | keys[]; . as $req | $s.requirements | index($req) != null) and
  all($s.records[]; . as $record |
    ($record.requirements | type == "array" and length > 0) and
    all($record.requirements[]; . as $req |
      ($s.requirements | index($req) != null) and ($plan.coverage[$req] | index($record.ref) != null)));
def required_reviewers($language):
  if $language == "zig" then ["code","comment","architecture","test"]
  elif $language == "go" or $language == "node" then ["combined"]
  else error("Unsupported task language") end;
def following($events; $event):
  if $event == null then [] else $events[(($events | index($event)) + 1):] end;
def current_reviews($events; $build; $language):
  [required_reviewers($language)[] as $role |
    ([following($events; $build)[] | select(.kind == "review" and .reviewer == $role and
       .buildEventId == $build.eventId and .attempt == $build.attempt and .head == $build.head and .tree == $build.tree)] | last)];
def approved_reviews($reviews):
  all($reviews[]; . != null and .verdict == "APPROVED");
def unresolved_blockers:
  . as $s |
  [.events[] | select(.recordRef == $s.ref and
    (.kind == "blocker" or (.kind == "build" and .outcome == "blocked" and ((.blockerEventIds // []) | length == 0))))] |
  map(. as $blocker | select(any(following($s.events; $blocker)[];
    .recordRef == $s.ref and .kind == "resume" and .blockerEventId == $blocker.eventId) | not));
def task_state:
  . as $s |
  if any(.events[]; (valid_event | not)) then error("Invalid evidence event")
  elif ([.events[].eventId] | length != (unique | length)) then error("Duplicate evidence eventId")
  else
    [.events[] | select(.recordRef == $s.ref and .specHash == $s.specHash)] as $events |
    ($s | unresolved_blockers) as $blockers |
    ([$events[] | select(.kind == "baseline")] | last) as $baseline |
    ([$events[] | select(.kind == "dispatch")] | last) as $dispatch |
    ([following($events; $dispatch)[] | select(.kind == "build" and .dispatchEventId == $dispatch.eventId and .attempt == $dispatch.attempt)] | last) as $build |
    if ($blockers | length > 0) then "blocked"
    elif $baseline != null and ($dispatch == null or ($events | index($baseline)) > ($events | index($dispatch))) then "baseline"
    elif $dispatch == null then "planned"
    elif $build == null then
      if any($events[]; .kind == "release" and .dispatchEventId == $dispatch.eventId and .outcome == "stopped") then "interrupted" else "building" end
    elif $build.outcome == "blocked" then
      if all(($build.blockerEventIds // [])[]; . as $id |
        any($s.events[]; .recordRef == $s.ref and .kind == "blocker" and .eventId == $id))
      then "retryable" else "blocked" end
    else
      current_reviews($events; $build; $s.language) as $reviews |
      if any($reviews[]; .verdict == "CHANGES_NEEDED") then "fixing"
      elif (approved_reviews($reviews) | not) then "reviewing"
      else
        ([$reviews[] as $r | $events | index($r)] | max) as $review_index |
        ([$events[($review_index + 1):][] | select(.kind == "integration" and .outcome == "passed" and
          .buildEventId == $build.eventId and .attempt == $build.attempt and .head == $build.head and .tree == $build.tree and
          (.reviewEventIds | sort) == ([$reviews[].eventId] | sort))] | last) as $integration |
        if $integration == null then "awaiting-integration"
        elif any(following($events; $integration)[]; .kind == "completion" and .integrationEventId == $integration.eventId) then "complete"
        else "integrated" end
      end
    end
  end;
def path_overlap($a; $b):
  ($a | ascii_downcase) as $a | ($b | ascii_downcase) as $b |
  $a == "." or $b == "." or $a == $b or
  ($a | startswith($b + "/")) or ($b | startswith($a + "/"));
def ownership_valid:
  type == "object" and
  (.paths | type == "array" and length > 0 and all(.[]; nonempty)) and
  ([.sharedPaths,.resources,.interfaces] | all(.[]; type == "array" and all(.[]; nonempty))) and
  ([.paths[],.sharedPaths[]] | all(.[];
    . != ".." and (startswith("/") | not) and
    (. == "." or (split("/") | all(.[]; . != "." and . != ".." and . != ""))) and
    (test("[\\*\\?\\[\\]]") | not)));
def metadata_valid:
  . as $s |
  (.records | type == "array" and length > 0) and
  ([.records[].ref] | length == (unique | length)) and
  ([.records[] | select(.kind == "phase" or .kind == "task") | [.parentRefs,.kind,.order]] | length == (unique | length)) and
  all(.records[]; . as $r |
    (.ref | nonempty) and (.parentRefs | type == "array") and
    if .kind == "project" or .kind == "prd" or .kind == "design" then (.parentRefs | length == 0)
    elif .kind == "phase" or .kind == "task" then
      (.order | positive_integer) and (.parentRefs | length == 1) and
      any($s.records[]; .ref == $r.parentRefs[0] and .kind == (if $r.kind == "phase" then "project" else "phase" end)) and
      (.requirements | type == "array" and length > 0 and all(.[]; . as $req | $s.requirements | index($req) != null)) and
      (.documents | type == "array" and length > 0 and all(.[]; . as $doc |
        (.hash | nonempty) and any($s.records[]; .ref == $doc.ref and (.kind == "prd" or .kind == "design")))) and
      (if .kind == "task" then
        (.language == "go" or .language == "node" or .language == "zig") and (.ownership | ownership_valid)
       else true end)
    else false end);
def conflicts($a; $b):
  if (($a.ownership | ownership_valid) and ($b.ownership | ownership_valid) | not) then true
  else
    any(($a.ownership.paths + $a.ownership.sharedPaths)[]; . as $p |
      any(($b.ownership.paths + $b.ownership.sharedPaths)[]; path_overlap($p; .))) or
    any($a.ownership.resources[]; . as $r | any($b.ownership.resources[]; . == $r)) or
    any($a.ownership.interfaces[]; . as $i | any($b.ownership.interfaces[]; . == $i))
  end;
def ready_batch:
  . as $s |
  (.limits.builders // .maxParallel // 1) as $builder_limit |
  (.usage.builders // ([.active[] | select(.state == "building" or .state == "reserved")] | length)) as $builders |
  if ($builder_limit | positive_integer | not) then error("builders limit must be a positive integer")
  elif .limits != null and ([.limits.builders,.limits.reviewers,.limits.gates,.limits.integrations] | all(.[]; positive_integer) | not) then error("Invalid stage limits")
  else
    reduce (.candidates | sort_by(.phaseOrder,.order,.ref)[]) as $task
      ([]; . as $selected |
       if ($task.incomplete == true and $task.statusAllowed == true and
           $task.dependencyReady == true and $task.phaseReady == true and
           $task.documentsApproved == true and $task.planApproved == true and
           ($task.agentEligible == null or $task.agentEligible == true) and
           ($task.state == "planned" or $task.state == "interrupted" or $task.state == "fixing" or $task.state == "retryable") and
           ($task.ownership | ownership_valid) and
           (($selected | length) + $builders < $builder_limit) and
           all(($s.active + $selected)[]; .ref != $task.ref and (conflicts($task; .) | not)))
       then . + [$task] else . end)
  end;

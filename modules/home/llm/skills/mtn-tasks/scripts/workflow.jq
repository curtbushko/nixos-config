# Read-only guards over ephemeral snapshots derived from mtn. No writes or claims.
# Rex transport identity is evidence, not task completion or a host lease.
def rex_string: type == "string" and length > 0 and (test("[\u0000-\u001f]") | not);
def rex_run_id:
  type == "string" and length <= 100 and test("^[A-Za-z0-9]([A-Za-z0-9._-]*[A-Za-z0-9])?$");
def rex_launch_metadata:
  ([.recordRef,.specHash,.worktree,.model,.thinking] | all(.[]; rex_string)) and
  (.runID | rex_run_id) and
  (.skill | type == "string" and test("^[a-z][a-z0-9-]*$")) and
  (.attempt | type == "number" and . >= 1 and floor == .) and
  (.thinking as $t | ["off","minimal","low","medium","high","xhigh","max"] | index($t) != null) and
  (.worktree | startswith("/")) and
  (if .role == "coordinator" then
     .handoff == true and (.skill as $s | ["go-team","node-team","zig-team"] | index($s) != null)
   elif .role == "builder" or .role == "reviewer" then
     ([.phaseRef,.dispatchEventID] | all(.[]; rex_string)) and (.coordinator.runID | rex_run_id)
   elif .role == "planner" then
     (.phaseRef | rex_string) and (.coordinator.runID | rex_run_id)
   else false end);
def rex_request:
  rex_launch_metadata and (.prompt | type == "string" and length > 0 and (contains("\u0000") | not));
def provider_binding:
  (.provider | type == "object") and
  (.provider.name | rex_string) and
  (.provider.displayName | rex_string) and
  (.provider.resources | type == "object") and
  (.provider.resources | to_entries | all(.[]; .value | rex_string));
def rex_runtime:
  rex_launch_metadata and
  ([.sessionName,.windowName,.transportDir] | all(.[]; rex_string)) and
  (if has("provider") then provider_binding else true end) and
  .piSessionID == .runID and
  (if has("rexSessionName") or has("rexWindowName") or has("piSessionName") then
     ([.rexSessionName,.rexWindowName,.piSessionName] | all(.[]; rex_string)) and
     .rexSessionName == .sessionName and .rexWindowName == .windowName and
     .piSessionName == .rexWindowName
   else true end) and
  (.host | [.endpoint,.hostID,.instanceID] | all(.[]; rex_string)) and
  (.host.endpoint | startswith("unix://")) and
  (if .stage == "reserved" then true
   elif .stage == "launched" then
     (.rexSessionID | rex_string and startswith("session:")) and
     (.rexWindowID | rex_string and startswith("window:")) and
     (.rexBlockID | rex_string and startswith("block:"))
   else false end);
def nonempty: type == "string" and length > 0;
def positive_integer: type == "number" and . >= 1 and floor == .;
def checks_pass:
  type == "array" and length > 0 and all(.[];
    (.command | nonempty) and .result == "pass");
def validation_entries:
  type == "array" and all(.[];
    (.command | nonempty) and (.result as $r | ["pass","fail","unavailable"] | index($r) != null));
def summary_event:
  .summaryVersion == 1 and .status == "complete" and
  ([.acceptedScope,.targetCommit,.targetTree,.targetBranch] | all(.[]; nonempty)) and
  (.requirements | type == "array") and
  (.approvalSummary | type == "array" and length > 0) and
  (.verification | checks_pass) and
  (.limitations | type == "array" and all(.[]; nonempty)) and
  (.files | type == "array" and all(.[]; nonempty));
# A recovery is narrow authorization, never a replacement document approval.
def recovery_authorization:
  .decision == "approved" and .disposition == "quarantine-malformed-approval" and
  ([.approvedBy,.decisionEvidence,.replacementEventID] | all(.[]; nonempty)) and
  (.collectionRoot | nonempty and startswith("/")) and
  (.target | type == "object" and
    ([.eventID,.specHash] | all(.[]; nonempty)) and
    (.intent | type == "string" and test("^[0-9a-f]{64}$")) and
    (.contentDigest | type == "string" and test("^sha256:[0-9a-f]{64}$"))) and
  .target.eventID != .eventID and .replacementEventID != .eventID and
  .replacementEventID != .target.eventID and
  (if has("supersedesRecoveryEventID") then
    (.supersedesRecoveryEventID | nonempty) and .supersedesRecoveryEventID != .eventID
   else true end);
def valid_event:
  (.schemaVersion == 1) and (.eventID | nonempty) and
  (.recordRef | nonempty) and (.specHash | nonempty) and
  (.attempt | positive_integer) and
  (if .kind == "approval" then
     (.decision == "approved" or .decision == "rejected") and
     ([.approvedBy,.decisionEvidence] | all(.[];nonempty))
   elif .kind == "plan" then
     .decision == "approved" and (.records | type == "array" and length > 0) and
     ([.approvedBy,.decisionEvidence] | all(.[];nonempty))
   elif .kind == "dispatch" then
     ([.runID,.baseCommit,.branch,.worktree,.targetBranch] | all(.[]; nonempty))
   elif .kind == "runtime" then rex_runtime
   elif .kind == "recovery" then recovery_authorization
   elif .kind == "build" then
     ([.dispatchEventID,.head,.tree] | all(.[]; nonempty)) and
     (.outcome == "blocked" or (.outcome == "ready-for-review" and (.validation | checks_pass)))
   elif .kind == "review" then
     ([.buildEventID,.head,.tree,.reviewer] | all(.[]; nonempty)) and
     (.reviewer | test("^(combined|code|comment|test|architecture|security|usability|maintenance|(go|node|zig|nix|bash):(code|test)|(lua|docs):combined)$")) and
     (if has("carriedForwardFrom") or has("carryForwardRationale") then
        ([.carriedForwardFrom,.carryForwardRationale] | all(.[]; nonempty)) and
        (.reviewer as $r | ["architecture","security","usability","maintenance"] | index($r) != null)
      else true end) and
     (.changes_required | type == "array") and
     (if (.reviewer | contains(":")) or
         (.reviewer as $r | ["security","usability","maintenance"] | index($r) != null)
      then (.validation | validation_entries) else true end) and
     ((.verdict == "APPROVED" and (.changes_required | length == 0) and (.validation | checks_pass)) or
      (.verdict == "CHANGES_NEEDED" and (.changes_required | length > 0)))
   elif .kind == "integration" then
     ([.buildEventID,.head,.tree,.targetBranch,.targetBase] | all(.[]; nonempty)) and
     (.reviewEventIDs | type == "array" and all(.[]; nonempty)) and
     (if .outcome == "failed" then
        ([.candidateCommit,.candidateTree] | all(.[]; nonempty)) and
        (.validation | type == "array" and any(.[]; .result == "fail"))
      elif .outcome == "passed" then
        ([.integratedCommit,.integratedTree] | all(.[]; nonempty)) and (.validation | checks_pass)
      else false end)
   elif .kind == "milestone" then
     ([.targetCommit,.targetTree,.targetBranch] | all(.[]; nonempty)) and
     (.records | type == "array" and length > 0) and (.validation | checks_pass)
   elif .kind == "completion" then (.integrationEventID | nonempty)
   elif .kind == "historical" then
     (.content | type == "string") and (.provenance | nonempty) and .gateEligible == false
   elif .kind == "baseline" then
     ([.approvedBy,.decisionEvidence,.targetCommit,.targetTree,.targetBranch] | all(.[]; nonempty)) and
     .reviewEquivalent == false and (.validation | checks_pass)
   elif .kind == "summary" then summary_event
   elif .kind == "blocker" then (.reason | nonempty)
   elif .kind == "resume" then (.blockerEventID | nonempty)
   elif .kind == "release" then
     (.dispatchEventID | nonempty) and (.outcome == "stopped" or .outcome == "finished")
   else false end);
def document_approved:
  . as $s |
  (any(.events[]; (valid_event | not)) | not) and
  ([.events[].eventID] | length == (unique | length)) and
  # Quarantine cannot expose an unrelated earlier approval as current authority.
  # Superseded authorizations stay visible, but only the active chain tip governs.
  all(.events[] | select(.kind == "recovery") | . as $a |
    select(any($s.events[]; .kind == "recovery" and .supersedesRecoveryEventID == $a.eventID) | not);
    . as $recovery |
    .recordRef == $s.ref and .specHash == $s.specHash and
    any($s.events[(($s.events | index($recovery)) + 1):][];
      .eventID == $recovery.replacementEventID and .kind == "approval" and
      .recordRef == $s.ref and .specHash == $s.specHash and .decision == "approved")) and
  (([.events[] | select(.kind == "approval" and .recordRef == $s.ref and .specHash == $s.specHash)] | last | .decision) == "approved");
# Accepted plan manifests have two equivalent encodings in native collections:
# coverage may be an object map or an array of {requirement,records} entries, and
# record entries may carry planning metadata in addition to ref/specHash. Normalize
# only for comparison; the original approved event is never rewritten.
def normalized_plan_records:
  if type == "array" and all(.[]; type == "object" and (.ref | nonempty) and (.specHash | nonempty))
  then map({ref, specHash})
  else null
  end;
def normalized_plan_coverage:
  if type == "object" and (. as $coverage |
    all($coverage | keys[]; . as $requirement |
      $coverage[$requirement] | type == "array" and length > 0 and all(.[]; nonempty)))
  then .
  elif type == "array" and all(.[];
    type == "object" and (.requirement | nonempty) and
    (.records | type == "array" and length > 0 and all(.[]; nonempty)))
  then reduce .[] as $entry ({}; .[$entry.requirement] = $entry.records)
  else null
  end;
def plan_approved:
  . as $s |
  ([$s.events[] | select(.kind == "plan" and .recordRef == $s.ref and .specHash == $s.specHash)] | last) as $plan |
  ($plan.records | normalized_plan_records) as $plan_records |
  ($plan.coverage | normalized_plan_coverage) as $coverage |
  $plan != null and ($plan | valid_event) and
  $plan_records != null and $coverage != null and
  (any($s.events[]; (valid_event | not)) | not) and
  ([$s.events[].eventID] | length == (unique | length)) and
  ($s.documents | all(.[]; document_approved)) and
  (($plan.documents | sort_by(.ref)) == ([$s.documents[] | {ref,hash:.specHash}] | sort_by(.ref))) and
  (($plan_records | sort_by(.ref)) == ([$s.records[] | {ref,specHash}] | sort_by(.ref))) and
  ($s.records | length > 0) and
  ([$s.records[].ref] | length == (unique | length)) and
  ($coverage | type == "object") and
  all($s.requirements[]; . as $req |
    ($coverage[$req] | type == "array" and length > 0) and
    all($coverage[$req][]; . as $ref |
      any($s.records[]; .ref == $ref and (.requirements | index($req) != null)))) and
  all($coverage | keys[]; . as $req | $s.requirements | index($req) != null) and
  all($s.records[]; . as $record |
    ($record.requirements | type == "array" and length > 0) and
    all($record.requirements[]; . as $req |
      ($s.requirements | index($req) != null) and ($coverage[$req] | index($record.ref) != null)));
def language_route($language):
  if $language == "go" then {language:$language,builder:"go-developer",reviewer:"go-reviewer",reviewers:["go-code-reviewer","go-test-reviewer"],support:["golang"]}
  elif $language == "node" then {language:$language,builder:"node-developer",reviewer:"node-reviewer",reviewers:["node-code-reviewer","node-test-reviewer"],support:[]}
  elif $language == "zig" then {language:$language,builder:"zig-developer",reviewer:"zig-reviewer",reviewers:["zig-code-reviewer","zig-test-reviewer"],support:["zig"]}
  elif $language == "nix" then {language:$language,builder:"repo-maintainer",reviewer:"nix-code-reviewer",reviewers:["nix-code-reviewer","nix-test-reviewer"],support:["nix"]}
  elif $language == "bash" then {language:$language,builder:"repo-maintainer",reviewer:"bash-code-reviewer",reviewers:["bash-code-reviewer","bash-test-reviewer"],support:["bash"]}
  elif $language == "lua" then {language:$language,builder:"mtn-tasks",reviewer:"mtn-tasks",support:[]}
  elif $language == "docs" then {language:$language,builder:"mtn-tasks",reviewer:"mtn-tasks",support:[]}
  else error("Unsupported task language") end;
# New language and specialist seats retain their full names so mixed-language runs cannot collide.
# Explicit old entry names retain their historical labels; existing runs are never renamed.
def reviewer_agent_label($skill):
  if ["go-reviewer","node-reviewer","zig-reviewer"] | index($skill) != null then "reviewer"
  elif $skill == "go-code-review" then "code-review"
  elif $skill == "zig-comment-reviewer" then "comment-reviewer"
  elif $skill == "zig-architecture-reviewer" then "architecture-reviewer"
  else $skill end;
def supported_language($language):
  try (language_route($language) | true) catch false;
def language_review_roles($language):
  if ["go","node","zig","nix","bash"] | index($language) != null then ["code","test"]
  elif supported_language($language) then ["combined"]
  else error("Unsupported task language") end;
# Preserve original unscoped evidence policy for historical inspection, not new dispatch.
def required_reviewers($language):
  if $language == "zig" then ["code","comment","architecture","test"]
  elif supported_language($language) then ["combined"]
  else error("Unsupported task language") end;
# A declared review plan is part of the approved semantic specification.
def review_plan_valid($primary):
  try (
    type == "object" and
    (.languages | type == "array" and length > 0) and
    ([.languages[].language] | length == (unique | length)) and
    any(.languages[]; .language == $primary) and
    all(.languages[];
      supported_language(.language) and
      (.paths | type == "array" and length > 0 and all(.[];
        type == "string" and length > 0 and . != ".." and
        (startswith("/") | not) and
        (. == "." or (split("/") | all(.[]; . != "" and . != "." and . != ".."))) and
        (test("[\\\\*\\\\?\\\\[\\\\]]") | not)))) and
    (.specialists | type == "object" and
      (keys | sort) == (["architecture","security","usability","maintenance"] | sort) and
      all(.[]; (.required | type == "boolean") and (.reason | nonempty)))
  ) catch false;
def required_review_scopes:
  . as $s |
  if (.implementation // {} | has("reviewPlan")) then
    .implementation.reviewPlan as $plan |
    if ($plan | review_plan_valid($s.language) | not) then error("Invalid review plan")
    else
      ([$plan.languages[] | .language as $language |
        language_review_roles($language)[] | $language + ":" + .] +
       ["architecture","security","usability","maintenance"] | .) as $all |
      $all | map(select(contains(":") or $plan.specialists[.].required))
    end
  else required_reviewers($s.language) end;
def following($events; $event):
  if $event == null then [] else $events[(($events | index($event)) + 1):] end;
def carry_forward_valid($events; $review):
  if $review == null then false
  elif ($review | has("carriedForwardFrom") | not) then true
  else
    ([$events[:($events | index($review))][] |
      select(.kind == "review" and .reviewer == $review.reviewer)] | last) as $prior |
    $prior != null and $prior.eventID == $review.carriedForwardFrom and
    $prior.verdict == "APPROVED" and $prior.specHash == $review.specHash and
    $prior.recordRef == $review.recordRef and
    any($events[:($events | index($prior))][];
      .kind == "build" and .eventID == $prior.buildEventID and
      .head == $prior.head and .tree == $prior.tree and .attempt == $prior.attempt)
  end;
def current_scope_reviews($events; $build; $scopes):
  [$scopes[] as $role |
    ([following($events; $build)[] | select(.kind == "review" and .reviewer == $role and
       .buildEventID == $build.eventID and .attempt == $build.attempt and .head == $build.head and .tree == $build.tree)] | last) |
    . as $review | if carry_forward_valid($events; $review) then . else null end];
# Compatibility for inspecting unscoped historical query fixtures.
def current_reviews($events; $build; $language):
  current_scope_reviews($events; $build; required_reviewers($language));
def approved_reviews($reviews):
  all($reviews[]; . != null and .verdict == "APPROVED");
def unresolved_blockers:
  . as $s |
  [.events[] | select(.recordRef == $s.ref and
    (.kind == "blocker" or (.kind == "build" and .outcome == "blocked" and ((.blockerEventIDs // []) | length == 0))))] |
  map(. as $blocker | select(any(following($s.events; $blocker)[];
    .recordRef == $s.ref and .kind == "resume" and .blockerEventID == $blocker.eventID) | not));
def task_state:
  . as $s |
  if any(.events[]; (valid_event | not)) then error("Invalid evidence event")
  elif ([.events[].eventID] | length != (unique | length)) then error("Duplicate evidence eventID")
  else
    [.events[] | select(.recordRef == $s.ref and .specHash == $s.specHash)] as $events |
    ([$events[] | select(.kind == "summary")] | last) as $summary |
    ($s | unresolved_blockers) as $blockers |
    ([$events[] | select(.kind == "baseline")] | last) as $baseline |
    ([$events[] | select(.kind == "dispatch")] | last) as $dispatch |
    ([following($events; $dispatch)[] | select(.kind == "build" and .dispatchEventID == $dispatch.eventID and .attempt == $dispatch.attempt)] | last) as $build |
    if ($summary != null) then "complete"
    elif ($blockers | length > 0) then "blocked"
    elif $baseline != null and ($dispatch == null or ($events | index($baseline)) > ($events | index($dispatch))) then "baseline"
    elif $dispatch == null then "planned"
    elif $build == null then
      if any($events[]; .kind == "release" and .dispatchEventID == $dispatch.eventID and .outcome == "stopped") then "interrupted" else "building" end
    elif $build.outcome == "blocked" then
      if all(($build.blockerEventIDs // [])[]; . as $id |
        any($s.events[]; .recordRef == $s.ref and .kind == "blocker" and .eventID == $id))
      then "retryable" else "blocked" end
    else
      ($s | required_review_scopes) as $scopes |
      current_scope_reviews($events; $build; $scopes) as $reviews |
      if any($reviews[]; .verdict == "CHANGES_NEEDED") then "fixing"
      elif (approved_reviews($reviews) | not) then "reviewing"
      else
        ([$reviews[] as $r | $events | index($r)] | max) as $review_index |
        ([$events[($review_index + 1):][] | select(.kind == "integration" and .outcome == "passed" and
          .buildEventID == $build.eventID and .attempt == $build.attempt and .head == $build.head and .tree == $build.tree and
          (.reviewEventIDs | sort) == ([$reviews[].eventID] | sort))] | last) as $integration |
        if $integration == null then "awaiting-integration"
        elif any(following($events; $integration)[]; .kind == "completion" and .integrationEventID == $integration.eventID) then "complete"
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
  ([.records[] | select(.kind == "phase" or .kind == "task") | [.parentRef,.kind,.order]] | length == (unique | length)) and
  all(.records[]; . as $r |
    (.ref | nonempty) and (.identity | type == "object") and
    (.identity.uuid | nonempty) and (.identity.kind == .kind) and
    (if .kind == "project" then (.identity.projectID | nonempty)
     elif .kind == "phase" then (.identity.phaseID | nonempty)
     elif .kind == "task" then (.identity.taskID | nonempty)
     else true end) and
    if .kind == "project" or .kind == "prd" or .kind == "design" then (.parentRef == null)
    elif .kind == "phase" or .kind == "task" then
      (.order | positive_integer) and (.parentRef | nonempty) and
      any($s.records[]; .ref == $r.parentRef and .kind == (if $r.kind == "phase" then "project" else "phase" end)) and
      (.requirements | type == "array" and length > 0 and all(.[]; . as $req | $s.requirements | index($req) != null)) and
      (.documents | type == "array" and length > 0 and all(.[]; . as $doc |
        (.hash | nonempty) and any($s.records[]; .ref == $doc.ref and (.kind == "prd" or .kind == "design")))) and
      (if .kind == "task" then
        (supported_language(.language)) and (.ownership | ownership_valid) and
        (if (.implementation // {} | has("reviewPlan")) then
           (.implementation.reviewPlan | review_plan_valid($r.language)) else true end)
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

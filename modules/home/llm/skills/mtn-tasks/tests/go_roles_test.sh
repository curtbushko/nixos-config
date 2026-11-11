#!/usr/bin/env bash
set -euo pipefail

for tool in jq dirname; do command -v "$tool" >/dev/null || exit 1; done
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

jq -n -e -L "$skill/scripts" '
include "workflow";
def event($id; $kind): {schemaVersion:1,eventID:$id,kind:$kind,recordRef:"tasks/go.md",specHash:"spec",attempt:1};
def dispatch: event("d";"dispatch")+{runID:"run",baseCommit:"base",branch:"work",worktree:"/tmp/work",targetBranch:"main"};
def build: event("b";"build")+{dispatchEventID:"d",head:"head",tree:"tree",outcome:"ready-for-review",validation:[{command:"task test",result:"pass"}]};
def review($role): event(("r-"+$role);"review")+{buildEventID:"b",head:"head",tree:"tree",reviewer:$role,verdict:"APPROVED",changes_required:[],validation:[{command:"independent check",result:"pass"}]};
def integration($reviews): event("i";"integration")+{buildEventID:"b",head:"head",tree:"tree",targetBranch:"main",targetBase:"base",integratedCommit:"merged",integratedTree:"merged-tree",outcome:"passed",reviewEventIDs:$reviews,validation:[{command:"integration",result:"pass"}]};
def plan: {languages:[{language:"go",paths:["src"]}],specialists:{architecture:{required:false,reason:"No design change"},security:{required:false,reason:"No trust change"},usability:{required:false,reason:"No workflow change"},maintenance:{required:false,reason:"No infrastructure change"}}};
def state($events): {ref:"tasks/go.md",specHash:"spec",language:"go",implementation:{reviewPlan:plan},events:$events}|task_state;
[
  (language_route("go") | .builder == "go-developer" and .reviewer == "go-reviewer" and .reviewers == ["go-code-reviewer","go-test-reviewer"]),
  (language_review_roles("go") == ["code","test"]),
  (state([dispatch,build,review("combined")]) == "reviewing"),
  (state([dispatch,build,review("go:code")]) == "reviewing"),
  (state([dispatch,build,review("go:test")]) == "reviewing"),
  (state([dispatch,build,review("go:code"),review("go:test")]) == "awaiting-integration"),
  (state([dispatch,build,review("go:code"),(review("go:test")|.head="old")]) == "reviewing"),
  (state([dispatch,build,review("go:code"),(review("go:test")|.buildEventID="old")]) == "reviewing"),
  (state([dispatch,build,review("go:code"),(review("go:test")|.attempt=2)]) == "reviewing"),
  (state([dispatch,build,review("go:code"),review("go:test"),(review("go:test")|.eventID="r-negative"|.verdict="CHANGES_NEEDED"|.changes_required=[{id:"T-1"}])]) == "fixing"),
  (state([dispatch,build,review("go:code"),review("go:test"),integration(["r-go:code"])]) == "awaiting-integration"),
  (state([dispatch,build,review("go:code"),review("go:test"),integration(["r-go:code","r-go:test"])]) == "integrated"),
  (state([dispatch,build,review("go:code"),review("go:test"),integration(["r-go:code","r-go:test"]),event("c";"completion")+{integrationEventID:"i"}]) == "complete"),
  (language_review_roles("node") == ["code","test"]),
  (language_review_roles("zig") == ["code","test"])
] | all'
printf 'Go role routing and independent review gates passed\n'

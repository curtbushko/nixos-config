#!/usr/bin/env bash
set -euo pipefail
for tool in jq dirname; do command -v "$tool" >/dev/null || exit 1; done
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
jq -n -e -L "$skill/scripts" '
include "workflow"; include "facade";
def plan: {languages:[{language:"go",paths:["cmd"]},{language:"bash",paths:["scripts"]}],specialists:{architecture:{required:false,reason:"No contract change"},security:{required:true,reason:"Untrusted path reaches file writes"},usability:{required:true,reason:"CLI failure messages changed"},maintenance:{required:false,reason:"No environment change"}}};
def event($id;$kind): {schemaVersion:1,eventID:$id,kind:$kind,recordRef:"tasks/demo.md",specHash:"spec",attempt:1};
def dispatch: event("d";"dispatch")+{runID:"run",baseCommit:"base",branch:"work",worktree:"/tmp/work",targetBranch:"main"};
def build: event("b";"build")+{dispatchEventID:"d",head:"head",tree:"tree",outcome:"ready-for-review",validation:[{command:"checks",result:"pass"}]};
def review($role): event(("r-"+$role);"review")+{buildEventID:"b",head:"head",tree:"tree",reviewer:$role,verdict:"APPROVED",changes_required:[],validation:[{command:"independent check",result:"pass"}]};
def reviews: ["go:code","go:test","bash:code","bash:test","security","usability"] | map(review(.));
def snapshot($events): {ref:"tasks/demo.md",specHash:"spec",language:"go",implementation:{reviewPlan:plan},events:$events};
def old_build: build+{eventID:"old-b",dispatchEventID:"old-d",head:"old-head",tree:"old-tree"};
def old_review: review("security")+{eventID:"old-r",buildEventID:"old-b",head:"old-head",tree:"old-tree"};
def carried: review("security")+{carriedForwardFrom:"old-r",carryForwardRationale:"Only unrelated message formatting changed; assessed path and assumptions unchanged"};
def show($p): {result:{ref:"tasks/demo.md",description:"REQ-1",hierarchy:{parents:[{resolution:{ref:"phases/demo.md"}}]},frontmatter:{identity:{uuid:"uuid",kind:"task",taskID:"demo"},scope:{requirements:["REQ-1"]},implementation:{language:"go",ownership:{paths:["cmd"],sharedPaths:[],resources:[],interfaces:[]},gates:[],reviewPlan:$p}}}};
def integration($ids): event("i";"integration")+{buildEventID:"b",head:"head",tree:"tree",targetBranch:"main",targetBase:"base",integratedCommit:"merged",integratedTree:"merged-tree",outcome:"passed",reviewEventIDs:$ids,validation:[{command:"combined checks",result:"pass"}]};
[
 (plan | review_plan_valid("go")),
 ((plan | del(.specialists.security)) | review_plan_valid("go") | not),
 ((plan | .specialists.security.reason="") | review_plan_valid("go") | not),
 ((plan | .languages += [.languages[0]]) | review_plan_valid("go") | not),
 ((plan | .languages[1].paths=["../escape"]) | review_plan_valid("go") | not),
 (snapshot([]) | required_review_scopes == ["go:code","go:test","bash:code","bash:test","security","usability"]),
 (reviews | all(.[]; valid_event)),
 (snapshot([dispatch,build]+reviews) | task_state == "awaiting-integration"),
 (snapshot([dispatch,build]+(reviews|map(select(.reviewer!="bash:test")))) | task_state == "reviewing"),
 (snapshot([dispatch,build,review("code"),review("test")]) | task_state == "reviewing"),
 (snapshot([dispatch,build]+(reviews|map(if .reviewer=="security" then .head="old" else . end))) | task_state == "reviewing"),
 (snapshot([dispatch,build]+reviews+[(review("security")|.eventID="negative"|.verdict="CHANGES_NEEDED"|.changes_required=[{id:"S-1",disposition:"Escalate"}])]) | task_state == "fixing"),
 (snapshot([dispatch,build]+reviews+[integration(["r-go:code","r-go:test"])]) | task_state == "awaiting-integration"),
 (snapshot([dispatch,build]+reviews+[integration(reviews|map(.eventID))]) | task_state == "integrated"),
 (language_review_roles("node") == ["code","test"]),
 (language_review_roles("nix") == ["code","test"]),
 (language_route("bash") | .builder=="repo-maintainer" and .reviewers==["bash-code-reviewer","bash-test-reviewer"]),
 (show(plan) | semantic_spec({}) | .reviewPlan==plan),
 ((show(plan) | semantic_spec({})) != (show(plan | .specialists.security.required=false) | semantic_spec({}))),
 (show(plan) | del(.result.frontmatter.implementation.reviewPlan) | semantic_spec({}) | has("reviewPlan") | not),
 (snapshot([old_build,old_review,dispatch,build]+(reviews|map(select(.reviewer!="security")))+[carried]) | task_state=="awaiting-integration"),
 (snapshot([dispatch,build]+(reviews|map(select(.reviewer!="security")))+[carried]) | task_state=="reviewing"),
 (snapshot([old_build,old_review,(old_review|.eventID="old-negative"|.verdict="CHANGES_NEEDED"|.changes_required=[{id:"S-1"}]),dispatch,build]+(reviews|map(select(.reviewer!="security")))+[carried]) | task_state=="reviewing"),
 (review("go:code")+{carriedForwardFrom:"old-r",carryForwardRationale:"same"} | valid_event | not),
 (["security-reviewer","architecture-reviewer","usability-reviewer","repo-maintenance-reviewer"] | map(reviewer_agent_label(.)) | unique | length==4),
 (reviewer_agent_label("go-code-reviewer")=="go-code-reviewer"),
 (reviewer_agent_label("go-reviewer")=="reviewer"),
 (["go","node","zig","nix","bash"] | [ .[] as $lang | ["code","test"][] | reviewer_agent_label($lang+"-"+.+"-reviewer") ] | unique | length==10),
 (required_reviewers("go")==["combined"] and required_reviewers("node")==["combined"] and required_reviewers("zig")==["code","comment","architecture","test"]),
 ({ref:"tasks/demo.md",specHash:"spec",language:"go",events:[dispatch,build,review("combined"),integration(["r-combined"]),event("c";"completion")+{integrationEventID:"i"}]} | task_state=="complete"),
 ((review("go:test") | .verdict="CHANGES_NEEDED" | .changes_required=[{id:"T-1"}] | .validation=[{check:"source",result:"FAIL"}]) | valid_event | not),
 ((review("go:code") | .verdict="CHANGES_NEEDED" | .changes_required=[{id:"C-1"}] | .validation=[{command:"lint",result:"not_run"}]) | valid_event | not),
 ((review("go:test") | .verdict="CHANGES_NEEDED" | .changes_required=[{id:"T-1"}] | .validation=[{command:"source inspection",result:"fail",evidence:"missing assertion"}]) | valid_event)
] | all'
printf 'Mixed-language and triggered specialist gates passed\n'

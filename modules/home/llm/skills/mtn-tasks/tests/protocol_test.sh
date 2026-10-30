#!/usr/bin/env bash
set -euo pipefail
for command in jq dirname; do
	command -v "$command" >/dev/null || exit 1
done
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# These fixtures are ephemeral normalized mtn query results, not another state store.
jq -n -e -L "$skill/scripts" '
include "workflow";
def common($id; $kind): {schemaVersion:1,eventId:$id,kind:$kind,recordRef:"tasks/demo.md",specHash:"spec-1",attempt:1};
def dispatch: common("d1";"dispatch") + {runId:"run-1",baseCommit:"base",branch:"task-1",worktree:"/tmp/worker",targetBranch:"main"};
def build: common("b1";"build") + {dispatchEventId:"d1",head:"head-1",tree:"tree-1",outcome:"ready-for-review",validation:[{command:"tests",result:"pass"}]};
def review: common("r1";"review") + {buildEventId:"b1",head:"head-1",tree:"tree-1",reviewer:"combined",verdict:"APPROVED",changes_required:[],validation:[{command:"lint",result:"pass"}]};
def integration: common("i1";"integration") + {buildEventId:"b1",head:"head-1",tree:"tree-1",reviewEventIds:["r1"],targetBranch:"main",targetBase:"base",integratedCommit:"merged",integratedTree:"merged-tree",outcome:"passed",validation:[{command:"integration",result:"pass"}]};
def snapshot($events): {ref:"tasks/demo.md",specHash:"spec-1",language:"go",events:$events};
def document: {ref:"prds/demo.md",specHash:"doc-1",events:[common("approve-1";"approval")+{recordRef:"prds/demo.md",specHash:"doc-1",decision:"approved",approvedBy:"test fixture",decisionEvidence:"synthetic approval"}]};
def plan: {ref:"phases/demo.md",specHash:"phase-1",requirements:["REQ-001"],documents:[document],records:[{ref:"tasks/demo.md",specHash:"spec-1",requirements:["REQ-001"]}],events:[common("plan-1";"plan")+{recordRef:"phases/demo.md",specHash:"phase-1",decision:"approved",approvedBy:"test fixture",decisionEvidence:"synthetic approval",records:[{ref:"tasks/demo.md",specHash:"spec-1"}],documents:[{ref:"prds/demo.md",hash:"doc-1"}],coverage:{"REQ-001":["tasks/demo.md"]}}]};
def task($ref; $path; $order): {ref:$ref,phaseOrder:1,order:$order,incomplete:true,statusAllowed:true,dependencyReady:true,phaseReady:true,documentsApproved:true,planApproved:true,state:"planned",agentEligible:null,ownership:{paths:[$path],sharedPaths:[],resources:[],interfaces:[]}};
def metadata: {requirements:["REQ-001"],records:[{ref:"projects/demo.md",kind:"project",parentRefs:[]},{ref:"prds/demo.md",kind:"prd",parentRefs:[]},{ref:"phases/demo.md",kind:"phase",parentRefs:["projects/demo.md"],order:1,requirements:["REQ-001"],documents:[{ref:"prds/demo.md",hash:"doc-1"}]},{ref:"tasks/demo.md",kind:"task",parentRefs:["phases/demo.md"],order:1,requirements:["REQ-001"],documents:[{ref:"prds/demo.md",hash:"doc-1"}],language:"go",ownership:{paths:["src/demo"],sharedPaths:[],resources:[],interfaces:[]}}]};
([
  (metadata | metadata_valid),
  ((metadata | .records += [(.records[3]+{ref:"tasks/duplicate-order.md"})]) | metadata_valid | not),
  ((metadata | .records[3].language="unknown") | metadata_valid | not),
  ((metadata | .records[3].parentRefs=["missing.md"]) | metadata_valid | not),
  ((metadata | .records[3].requirements=["REQ-MISSING"]) | metadata_valid | not),
  (document | document_approved),
  ((document | .specHash="doc-2") | document_approved | not),
  (plan | plan_approved),
  ((plan | .records[0].specHash="spec-2") | plan_approved | not),
  ((plan | .events[0].coverage={}) | plan_approved | not),
  ((plan | .requirements += ["REQ-002"]) | plan_approved | not),
  ((plan | .documents[0].specHash="doc-2") | plan_approved | not),
  (dispatch | valid_event),
  (build | valid_event),
  (review | valid_event),
  (integration | valid_event),
  ((review | .changes_required=[{id:"C-1"}]) | valid_event | not),
  ((review | .schemaVersion=2) | valid_event | not),
  (snapshot([]) | task_state == "planned"),
  (snapshot([dispatch]) | task_state == "building"),
  (snapshot([dispatch,(common("stop-1";"release")+{dispatchEventId:"d1",outcome:"stopped"})]) | task_state == "interrupted"),
  (snapshot([dispatch,(common("block-1";"blocker")+{reason:"owner decision"})]) | task_state == "blocked"),
  (snapshot([dispatch,(common("block-1";"blocker")+{reason:"owner decision"}),(common("resume-1";"resume")+{blockerEventId:"block-1"})]) | task_state == "building"),
  (try (snapshot([dispatch,dispatch]) | task_state) catch "rejected") == "rejected",
  (snapshot([dispatch,build]) | task_state == "reviewing"),
  (snapshot([dispatch,review,build]) | task_state == "reviewing"),
  (snapshot([build,dispatch]) | task_state == "building"),
  (snapshot([dispatch,build,review]) | task_state == "awaiting-integration"),
  (snapshot([dispatch,build,(review | .head="stale")]) | task_state == "reviewing"),
  (snapshot([dispatch,build,(review | .specHash="stale")]) | task_state == "reviewing"),
  (snapshot([dispatch,build,review,(review | .eventId="r2" | .verdict="CHANGES_NEEDED" | .changes_required=[{id:"C-1"}])]) | task_state == "fixing"),
  (snapshot([dispatch,build,review,integration]) | task_state == "integrated"),
  (snapshot([dispatch,build,review,(common("c1";"completion")+{integrationEventId:"i1"}),integration]) | task_state == "integrated"),
  (snapshot([dispatch,build,review,(common("c1";"completion")+{integrationEventId:"missing"})]) | task_state == "awaiting-integration"),
  (snapshot([dispatch,build,review,(integration|.outcome="failed"|.candidateCommit="candidate"|.candidateTree="candidate-tree"|.validation=[{command:"integration",result:"fail"}])]) | task_state == "awaiting-integration"),
  (snapshot([dispatch,build]+(["code","comment","architecture","test"] | map(. as $role | review+{reviewer:$role,eventId:("r-"+$role)}))) | .language="zig" | task_state == "awaiting-integration"),
  (snapshot([dispatch,build]+(["code","comment","architecture"] | map(. as $role | review+{reviewer:$role,eventId:("r-"+$role)}))) | .language="zig" | task_state == "reviewing"),
  (snapshot([dispatch,build,review,(integration | .reviewEventIds=[])]) | task_state == "awaiting-integration"),
  (snapshot([dispatch,build,review,integration,(common("c1";"completion")+{integrationEventId:"i1"})]) | task_state == "complete"),
  (snapshot([dispatch,build,review,integration,(common("c1";"completion")+{integrationEventId:"wrong"})]) | task_state == "integrated"),
  ({candidates:[task("blocked-phase";"src/a";1)|.phaseReady=false, task("ready-phase";"src/b";2)],active:[],maxParallel:2} | ready_batch | map(.ref) == ["ready-phase"]),
  ({candidates:[task("a";"src/a";1),task("b";"src/b";2)],active:[],maxParallel:2} | ready_batch | length == 2),
  ({candidates:[task("a";"src";1),task("b";"src/b";2)],active:[],maxParallel:2} | ready_batch | length == 1),
  ({candidates:[task("a";"src/a";1)|.ownership.sharedPaths=["package-lock.json"],task("b";"src/b";2)|.ownership.sharedPaths=["package-lock.json"]],active:[],maxParallel:2} | ready_batch | length == 1),
  ({candidates:[task("a";"src/a";1)|.agentEligible=false],active:[],maxParallel:2} | ready_batch | length == 0),
  ({candidates:[task("a";"src/a";1)|.state="fixing"],active:[],maxParallel:2} | ready_batch | length == 1),
  ({candidates:[task("same-ref";"src/new";1)],active:[task("same-ref";"src/old";0)],maxParallel:2} | ready_batch | length == 0),
  ({candidates:[task("a";"src/a";1)|.ownership.resources=["db"],task("b";"src/b";2)|.ownership.resources=["db"]],active:[],maxParallel:2} | ready_batch | length == 1),
  ({candidates:[task("a";"src/a";1)],active:[task("running";"src/a";0)],maxParallel:2} | ready_batch | length == 0)
] | all)'
printf 'Delivery protocol checks passed\n'

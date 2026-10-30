#!/usr/bin/env bash
set -euo pipefail
for command in jq dirname; do command -v "$command" >/dev/null || exit 1; done
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
jq -n -e -L "$skill/scripts" '
include "workflow";
def e($id;$kind):{schemaVersion:1,eventId:$id,kind:$kind,recordRef:"tasks/demo.md",specHash:"spec1",attempt:1};
def snapshot($events):{ref:"tasks/demo.md",specHash:"spec1",language:"go",events:$events};
def blocker($id):e($id;"blocker")+{reason:"external decision"};
def resume($id):e(("resume-"+$id);"resume")+{blockerEventId:$id};
def dispatch:e("d1";"dispatch")+{runId:"run1",baseCommit:"base",branch:"work",worktree:"/tmp/work",targetBranch:"main"};
def blocked:e("build1";"build")+{dispatchEventId:"d1",head:"base",tree:"tree",outcome:"blocked"};
def owner($path):{paths:[$path],sharedPaths:[],resources:[],interfaces:[]};
def candidate($ref;$path):{ref:$ref,phaseOrder:1,order:1,incomplete:true,statusAllowed:true,dependencyReady:true,phaseReady:true,documentsApproved:true,planApproved:true,state:"planned",agentEligible:null,ownership:owner($path)};
[
  (snapshot([blocker("b1"),blocker("b2"),resume("b2")])|task_state=="blocked"),
  (snapshot([blocker("b1")])|.specHash="spec2"|task_state=="blocked"),
  (snapshot([dispatch,blocked,resume("build1")])|task_state=="retryable"),
  (owner("./src")|ownership_valid|not),
  (conflicts({ownership:owner("src/Foo")};{ownership:owner("src/foo")})),
  (snapshot([e("base1";"baseline")+{approvedBy:"test fixture",decisionEvidence:"synthetic migration approval",targetCommit:"commit",targetTree:"tree",targetBranch:"main",reviewEquivalent:false,validation:[{command:"verify baseline",result:"pass"}]}])|task_state=="baseline"),
  (e("approval-no-authority";"approval")+{decision:"approved"}|valid_event|not),
  (owner("src/.")|ownership_valid|not),
  (snapshot([e("history1";"historical")+{content:"Old evidence",provenance:"approved import",gateEligible:false}])|task_state=="planned"),
  ({limits:{builders:2,reviewers:4,gates:1,integrations:1},active:[candidate("a";"src/a")|.state="reviewing",candidate("b";"src/b")|.state="awaiting-integration"],candidates:[candidate("c";"src/c")]}|ready_batch|length==1),
  ({limits:{builders:2,reviewers:4,gates:1,integrations:1},active:[candidate("a";"src/c")|.state="reviewing"],candidates:[candidate("c";"src/c")]}|ready_batch|length==0)
]|all'
bash "$skill/tests/recovery_test.sh"
printf 'Workflow hardening checks passed\n'

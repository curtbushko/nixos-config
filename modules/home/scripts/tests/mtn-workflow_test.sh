#!/usr/bin/env bash
set -euo pipefail
for command in mtn git jq mktemp mkdir mv dirname ln grep; do command -v "$command" >/dev/null || exit 1; done
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/mtn-workflow"
repo="$(cd "$(dirname "$script")/../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-facade.XXXXXX")"
trap 'mkdir -p "$repo/.trash/mtn-facade-tests"; mv "$work" "$repo/.trash/mtn-facade-tests/"' EXIT
export HOME="$work/home"
mkdir -p "$HOME" "$work/repo/src" "$work/outside"
git init -q "$work/repo"
mtn init "$work/repo/.tasks" >/dev/null
cli() { bash "$script" --repo "$work/repo" "$@"; }
printf '%s\n' '{"title":"Initial project","path":"projects/initial.md","description":"REQ-001 project","fields":{"identity":{"kind":"project","projectID":"initial"},"structure":{"order":1},"scope":{"requirements":["REQ-001"]}}}' | mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
printf '%s\n' '{"title":"Demo phase","path":"phases/demo.md","description":"REQ-001 phase","fields":{"identity":{"kind":"phase","phaseID":"demo"},"structure":{"order":1},"scope":{"requirements":["REQ-001"]}}}' | mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
printf '%s\n' '{"target":"projects/initial.md"}' | mtn --path "$work/repo/.tasks" agent project-add phases/demo.md --input - --json >/dev/null
printf '%s\n' '{"title":"Demo","path":"tasks/demo.md","description":"REQ-001: observable behavior","fields":{"identity":{"kind":"task","taskID":"demo"},"structure":{"order":1},"scope":{"requirements":["REQ-001"]},"implementation":{"language":"go","ownership":{"paths":["src"],"sharedPaths":[],"resources":[],"interfaces":[]}}}}' | mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
printf '%s\n' '{"target":"phases/demo.md"}' | mtn --path "$work/repo/.tasks" agent project-add tasks/demo.md --input - --json >/dev/null
cli status tasks/demo.md | jq -e '.state=="planned" and .unresolvedBlockers==[]' >/dev/null
cli task tasks/demo.md | jq -e '.definition.description=="REQ-001: observable behavior" and .currentEvidence==[]' >/dev/null
first="$(cli fingerprint tasks/demo.md)"
# Legacy evidence remains inspectable, but a new dispatch cannot omit its review plan.
jq -n --arg hash "$first" --arg wt "$work/repo" '{schemaVersion:1,eventID:"missing-plan/dispatch",kind:"dispatch",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,runID:"fixture",baseCommit:"base",branch:"work",targetBranch:"main",worktree:$wt}' >"$work/missing-plan.json"
if MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/missing-plan.json" >"$work/missing-plan.out" 2>&1; then
	printf 'New dispatch bypassed the review plan\n' >&2
	exit 1
fi
printf '%s\n' '{"operations":[{"op":"set","field":"title","value":"Editorial title"},{"op":"set","field":"structure","value":{"order":2}}]}' | mtn --path "$work/repo/.tasks" agent patch tasks/demo.md --input - --json >/dev/null
[[ "$first" == "$(cli fingerprint tasks/demo.md)" ]]
cli paths ./src src/. | jq -e '.==["src","src"]' >/dev/null
ln -s "$work/repo/src" "$work/repo/alias"
cli paths alias | jq -e '.==["src"]' >/dev/null
ln -s "$work/outside" "$work/repo/escape"
if cli paths escape >/dev/null 2>&1; then
	printf 'Expected symlink escape rejection\n' >&2
	exit 1
fi
MTN_WORKFLOW_CPU_BUDGET=1 MTN_WORKFLOW_MEMORY_GIB=1 cli budget | jq -e '.limits.builders<=2 and .limits.gates==1 and .perGate.cpu<=.cpuBudget and .perGate.zigJobs<=3' >/dev/null
if MTN_WORKFLOW_CPU_BUDGET=zero cli budget >/dev/null 2>&1; then exit 1; fi
cli disk | jq -e '.filesystems|length>=1' >/dev/null
cli cleanup-plan | jq -e '.mutates==false and (.notes|length>0)' >/dev/null
# Unclassified old notes fail closed; an approved historical declaration preserves them.
printf '%s\n' '{"content":"Old build notes","category":"build","adopt":true,"retryKey":"legacy-test"}' | mtn --path "$work/repo/.tasks" agent note tasks/demo.md --input - --json >/dev/null
if cli status tasks/demo.md >/dev/null 2>&1; then
	printf 'Unapproved legacy evidence was ignored\n' >&2
	exit 1
fi
intent="$(mtn --path "$work/repo/.tasks" agent show tasks/demo.md --json | jq -r '.result.evidence[0].intent')"
jq -n --arg hash "$first" --arg intent "$intent" '{schemaVersion:1,eventID:"history/import1",kind:"historical",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,content:"Approved import",provenance:"fixture original records",gateEligible:false,legacyIntents:[$intent],approvedBy:"test fixture",decisionEvidence:"synthetic approval"}' >"$work/history.json"
if cli publish "$work/history.json" >/dev/null 2>&1; then
	printf 'Workers must not publish\n' >&2
	exit 1
fi
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/history.json" >/dev/null
cli status tasks/demo.md | jq -e '.state=="planned"' >/dev/null
jq -n --arg hash "$first" '{schemaVersion:1,eventID:"editorial/note1",kind:"historical",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,content:"Editorial suggestion only",provenance:"current coordinator annotation",gateEligible:false}' >"$work/comment.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/comment.json" >/dev/null
cli status tasks/demo.md | jq -e '.state=="planned"' >/dev/null
printf '%*s' 3000000 '' | tr ' ' x >"$work/large-content"
jq -n --arg hash "$first" --rawfile content "$work/large-content" '{content:({schemaVersion:1,eventID:"large-history",kind:"historical",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,content:$content,provenance:"large evidence fixture",gateEligible:false,approvedBy:"test fixture",decisionEvidence:"synthetic regression evidence"}|tojson),category:"historical",adopt:true,retryKey:"large-history"}' |
	mtn --path "$work/repo/.tasks" agent note tasks/demo.md --input - --json >/dev/null
cli snapshot tasks/demo.md | jq -e 'any(.events[];.eventID=="large-history")' >/dev/null
# A large project readiness snapshot must use file-backed jq inputs and preserve
# the real readiness diagnostic instead of cascading from E2BIG.
jq -n '{title:"Demo project",path:"projects/demo.md",description:"REQ-001 project",fields:{identity:{kind:"project",projectID:"demo"},structure:{order:1},scope:{requirements:["REQ-001"]}}}' |
	mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
jq -n '{title:"Demo PRD",path:"prds/demo.md",description:"REQ-001 document",fields:{identity:{kind:"prd"}}}' |
	mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
prd_hash="$(cli fingerprint prds/demo.md)"
jq -n --arg hash "$prd_hash" '{title:"Demo phase",path:"phases/demo-01.md",description:"REQ-001 phase",fields:{identity:{kind:"phase",phaseID:"demo-01"},structure:{order:1},scope:{requirements:["REQ-001"],documents:[{ref:"prds/demo.md",hash:$hash}]}}}' |
	mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
printf '%s\n' '{"target":"projects/demo.md"}' |
	mtn --path "$work/repo/.tasks" agent project-add phases/demo-01.md --input - --json >/dev/null
phase_hash="$(cli fingerprint phases/demo-01.md)"
jq -n --arg hash "$phase_hash" --rawfile content "$work/large-content" '{content:({schemaVersion:1,eventID:"large-phase-history",kind:"historical",recordRef:"phases/demo-01.md",specHash:$hash,attempt:1,content:$content,provenance:"large readiness fixture",gateEligible:false,approvedBy:"test fixture",decisionEvidence:"synthetic regression evidence"}|tojson),category:"historical",adopt:true,retryKey:"large-phase-history"}' |
	mtn --path "$work/repo/.tasks" agent note phases/demo-01.md --input - --json >/dev/null
if cli ready projects/demo.md >"$work/ready.out" 2>"$work/ready.err"; then
	printf 'Expected unapproved project readiness to fail\n' >&2
	exit 1
fi
grep -Fq 'scope plan or document approval is stale/incomplete' "$work/ready.err"
if grep -Fq 'Argument list too long' "$work/ready.err"; then
	printf 'Readiness still exceeded the jq argument limit\n' >&2
	exit 1
fi
printf 'Workflow facade checks passed\n'

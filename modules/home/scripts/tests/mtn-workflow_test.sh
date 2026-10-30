#!/usr/bin/env bash
set -euo pipefail
for command in mtn git jq mktemp mkdir mv dirname ln; do command -v "$command" >/dev/null || exit 1; done
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/mtn-workflow"
repo="$(cd "$(dirname "$script")/../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-facade.XXXXXX")"
trap 'mkdir -p "$repo/.trash/mtn-facade-tests"; mv "$work" "$repo/.trash/mtn-facade-tests/"' EXIT
export HOME="$work/home"
mkdir -p "$HOME" "$work/repo/src" "$work/outside"
git init -q "$work/repo"
mtn init "$work/repo/.tasks" >/dev/null
cli() { bash "$script" --repo "$work/repo" "$@"; }
printf '%s\n' '{"title":"Demo","path":"tasks/demo.md","description":"REQ-001: observable behavior","fields":{"workflowKind":"task","workflowLanguage":"go","workflowOrder":1}}' | mtn --path "$work/repo/.tasks" agent create --input - --json >/dev/null
cli status tasks/demo.md | jq -e '.state=="planned" and .unresolvedBlockers==[]' >/dev/null
cli task tasks/demo.md | jq -e '.definition.description=="REQ-001: observable behavior" and .currentEvidence==[]' >/dev/null
first="$(cli fingerprint tasks/demo.md)"
printf '%s\n' '{"operations":[{"op":"set","field":"title","value":"Editorial title"},{"op":"set","field":"workflowOrder","value":2}]}' | mtn --path "$work/repo/.tasks" agent patch tasks/demo.md --input - --json >/dev/null
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
jq -n --arg hash "$first" --arg intent "$intent" '{schemaVersion:1,eventId:"history/import1",kind:"historical",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,content:"Approved import",provenance:"fixture original records",gateEligible:false,legacyIntents:[$intent],approvedBy:"test fixture",decisionEvidence:"synthetic approval"}' >"$work/history.json"
if cli publish "$work/history.json" >/dev/null 2>&1; then
	printf 'Workers must not publish\n' >&2
	exit 1
fi
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/history.json" >/dev/null
cli status tasks/demo.md | jq -e '.state=="planned"' >/dev/null
jq -n --arg hash "$first" '{schemaVersion:1,eventId:"editorial/note1",kind:"historical",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,content:"Editorial suggestion only",provenance:"current coordinator annotation",gateEligible:false}' >"$work/comment.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/comment.json" >/dev/null
cli status tasks/demo.md | jq -e '.state=="planned"' >/dev/null
printf 'Workflow facade checks passed\n'

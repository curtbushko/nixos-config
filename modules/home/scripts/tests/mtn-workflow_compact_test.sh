#!/usr/bin/env bash
set -euo pipefail
for command in mtn git jq mktemp mkdir mv dirname grep; do
	command -v "$command" >/dev/null || exit 1
done
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/mtn-workflow"
repo="$(cd "$(dirname "$script")/../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-compact.XXXXXX")"
trap 'mkdir -p "$repo/.trash/mtn-compact-tests"; mv "$work" "$repo/.trash/mtn-compact-tests/"' EXIT
export HOME="$work/home"
mkdir -p "$HOME" "$work/repo"
git init -q -b main "$work/repo"
git -C "$work/repo" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m 'Fixture delivery'
root="$work/repo"
git -C "$root" check-ignore -q --no-index .mtn-tmp/ 2>/dev/null || printf '.mtn-tmp/\n' >"$root/.gitignore"
mtn init "$root/.tasks" >/dev/null
cli() { bash "$script" --repo "$root" "$@"; }
native() { mtn --path "$root/.tasks" agent "$@" --json; }
printf '%s\n' '{"title":"Compactable task","path":"tasks/compact.md","description":"REQ-001 compactable delivery","fields":{"workflowKind":"task","workflowLanguage":"go","workflowOrder":1}}' |
	native create --input - >/dev/null
hash="$(cli fingerprint tasks/compact.md)"
commit="$(git -C "$root" rev-parse HEAD)"
tree="$(git -C "$root" rev-parse 'HEAD^{tree}')"
event() {
	local kind="$1" id="$2"
	jq -n --arg hash "$hash" --arg kind "$kind" --arg id "$id" --arg commit "$commit" --arg tree "$tree" --arg root "$root" \
		'{schemaVersion:1,eventId:$id,kind:$kind,recordRef:"tasks/compact.md",specHash:$hash,attempt:1,commit:$commit,tree:$tree,root:$root}'
}
# Publish the complete delivery chain through the normal coordinator facade.
event dispatch compact/dispatch | jq '.+{runId:"compact-run",baseCommit:.commit,branch:"main",targetBranch:"main",worktree:.root}' >"$work/dispatch.json"
event build compact/build | jq '.+{dispatchEventId:"compact/dispatch",head:.commit,tree:.tree,outcome:"ready-for-review",validation:[{command:"fixture build",result:"pass"}]}' >"$work/build.json"
event review compact/review | jq '.+{buildEventId:"compact/build",head:.commit,tree:.tree,reviewer:"combined",verdict:"APPROVED",changes_required:[],validation:[{command:"fixture review",result:"pass"}]}' >"$work/review.json"
event integration compact/integration | jq '.+{buildEventId:"compact/build",head:.commit,tree:.tree,targetBranch:"main",targetBase:.commit,reviewEventIds:["compact/review"],integratedCommit:.commit,integratedTree:.tree,outcome:"passed",validation:[{command:"fixture integration",result:"pass"}]}' >"$work/integration.json"
event completion compact/completion | jq '.+{integrationEventId:"compact/integration"}' >"$work/completion.json"
for event_file in dispatch build review integration completion; do
	MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/$event_file.json" >/dev/null
done
native complete tasks/compact.md >/dev/null
jq -n --arg hash "$hash" --arg commit "$commit" --arg tree "$tree" '{schemaVersion:1,eventId:"compact/summary/1",kind:"summary",recordRef:"tasks/compact.md",specHash:$hash,attempt:1,summaryVersion:1,status:"complete",acceptedScope:"REQ-001 compactable delivery",requirements:[],approvalSummary:[{approvedBy:"fixture",source:"compact/review",decision:"APPROVED"}],targetCommit:$commit,targetTree:$tree,targetBranch:"main",verification:[{command:"fixture integration",result:"pass"}],limitations:["fixture only"],files:["$tree"]}' >"$work/summary.json"
# Exercise idempotent summary publication followed by a later runtime release.
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/summary.json" >/dev/null
event release compact/release | jq '.+{dispatchEventId:"compact/dispatch",outcome:"finished"}' >"$work/release.json"
MTN_WORKFLOW_COORDINATOR=1 cli publish "$work/release.json" >/dev/null
MTN_WORKFLOW_COORDINATOR=1 cli compact tasks/compact.md "$work/summary.json" >"$work/compact.out"
jq -e '.events|length==1 and .[0].kind=="summary"' "$work/compact.out" >/dev/null
[[ "$(native show tasks/compact.md | jq '.result.evidence|length')" == 1 ]]
cli status tasks/compact.md | jq -e '.state=="complete"' >/dev/null
grep -Fq 'mtn:evidence:v1' "$root/.tasks/tasks/compact.md"
printf 'Workflow compaction checks passed\n'

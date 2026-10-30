#!/usr/bin/env bash
set -euo pipefail
for command in git mtn jq mktemp mkdir mv dirname shasum mkfifo bash; do
	command -v "$command" >/dev/null || exit 1
done
skill="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(cd "$skill/../../../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-delivery.XXXXXX")"
pids=()
cleanup() {
	if [[ ${#pids[@]} -gt 0 ]]; then
		printf 'go\n' >&7
		printf 'go\n' >&8
		for pid in "${pids[@]}"; do wait "$pid" || true; done
	fi
	mkdir -p "$repo/.trash/mtn-delivery-tests"
	mv "$work" "$repo/.trash/mtn-delivery-tests/"
}
trap cleanup EXIT
export HOME="$work/home"
export GIT_CONFIG_NOSYSTEM=1
mkdir -p "$HOME" "$work/target/src" "$work/results"
target="$work/target"
TASK_ROOT="$target/.tasks"
git init -q -b main "$target"
git -C "$target" config user.name 'Delivery test'
git -C "$target" config user.email 'delivery-test@example.invalid'
printf '.tasks/.mdbase/\n.tasks/.mtn/\n' >"$target/.gitignore"
printf '#!/usr/bin/env bash\nset -euo pipefail\nprintf "base\\n"\n' >"$target/src/base.sh"
mtn init "$TASK_ROOT" >/dev/null
create() { mtn --path "$TASK_ROOT" agent create --input - --json >/dev/null; }
link() {
	jq -n --arg target "$2" '{target:$target}' |
		mtn --path "$TASK_ROOT" agent "$3" "$1" --input - --json >/dev/null
}
fingerprint() {
	mtn --path "$TASK_ROOT" agent show "$1" --json |
		jq -S -c -L "$skill/scripts" 'include "facade"; semantic_spec({})' |
		shasum -a 256 | {
		read -r digest _
		printf 'sha256:%s\n' "$digest"
	}
}
event() {
	jq -n --arg ref "$1" --arg hash "$(fingerprint "$1")" --arg kind "$2" --arg id "$3" --argjson attempt "$4" \
		'{schemaVersion:1,eventId:$id,kind:$kind,recordRef:$ref,specHash:$hash,attempt:$attempt}'
}
publish() {
	local payload="$1"
	printf '%s\n' "$payload" | jq -e -L "$skill/scripts" 'include "workflow"; valid_event' >/dev/null
	jq -n --argjson e "$payload" \
		'{content:($e|tojson),role:"coordinator",category:$e.kind,adopt:true,retryKey:$e.eventId}' |
		mtn --path "$TASK_ROOT" agent note "$(jq -r .recordRef <<<"$payload")" --input - --json >/dev/null
}
state() {
	mtn --path "$TASK_ROOT" agent show "$1" --json |
		jq --arg hash "$(fingerprint "$1")" '{ref:.result.ref,specHash:$hash,language:.result.frontmatter.workflowLanguage,events:[.result.evidence[].content|fromjson]}' |
		jq -r -L "$skill/scripts" 'include "workflow"; task_state'
}
for request in \
	'{"title":"Demo","path":"projects/demo.md","fields":{"workflowKind":"project","workflowRequirements":["REQ-001","REQ-002","REQ-003"]}}' \
	'{"title":"Requirements","path":"prds/demo.md","description":"REQ-001: deliver A. REQ-002: deliver B. REQ-003: verify together.","fields":{"workflowKind":"prd"}}' \
	'{"title":"Design","path":"designs/demo.md","description":"REQ-001/002 have independent immutable CLI outputs; REQ-003 combines them.","fields":{"workflowKind":"design"}}' \
	'{"title":"Final verification","path":"phases/final.md","fields":{"workflowKind":"phase","workflowOrder":1,"workflowRequirements":["REQ-003"]}}' \
	'{"title":"Independent components","path":"phases/components.md","fields":{"workflowKind":"phase","workflowOrder":2,"workflowRequirements":["REQ-001","REQ-002"]}}'; do printf '%s\n' "$request" | create; done
for doc in prds/demo.md designs/demo.md; do
	publish "$(event "$doc" approval "$doc/approval/1" 1 | jq '.+{decision:"approved",approvedBy:"test fixture",decisionEvidence:"synthetic approval, not a real stakeholder decision"}')"
done
documents="$(jq -n --arg prd "$(fingerprint prds/demo.md)" --arg design "$(fingerprint designs/demo.md)" '[{ref:"prds/demo.md",hash:$prd},{ref:"designs/demo.md",hash:$design}]')"
for ref in projects/demo.md phases/final.md phases/components.md; do
	jq -n --argjson docs "$documents" '{operations:[{op:"set",field:"workflowDocuments",value:$docs}]}' |
		mtn --path "$TASK_ROOT" agent patch "$ref" --input - --json >/dev/null
done
for phase in phases/final.md phases/components.md; do link "$phase" projects/demo.md project-add; done
link phases/final.md phases/components.md depends-add
for id in a b c; do
	case "$id" in a)
		phase=components
		language=go
		requirement=REQ-001
		;;
	b)
		phase=components
		language=node
		requirement=REQ-002
		;;
	c)
		phase=final
		language=go
		requirement=REQ-003
		;;
	esac
	jq -n --arg id "$id" --arg language "$language" --arg requirement "$requirement" --argjson docs "$documents" \
		'{title:("Task "+$id),path:("tasks/"+$id+".md"),description:("Implement "+$requirement+" with a behavioral test and integration check"),fields:{workflowKind:"task",workflowLanguage:$language,workflowOrder:(if $id=="b" then 2 else 1 end),workflowRequirements:[$requirement],workflowDocuments:$docs,workflowOwnership:{paths:[("src/"+$id+".sh")],sharedPaths:[],resources:[],interfaces:[]}}}' | create
	link "tasks/$id.md" "phases/$phase.md" project-add
done
link tasks/c.md tasks/a.md depends-add
link tasks/c.md tasks/b.md depends-add
original_hash_a="$(fingerprint tasks/a.md)"
metadata='[]'
while read -r ref; do
	parents="$(mtn --path "$TASK_ROOT" agent hierarchy "$ref" --json | jq '[.result.parents[].resolution.ref]')"
	data="$(mtn --path "$TASK_ROOT" agent show "$ref" --json | jq --argjson parents "$parents" '.result|{ref,kind:.frontmatter.workflowKind,parentRefs:$parents,order:.frontmatter.workflowOrder,language:.frontmatter.workflowLanguage,requirements:.frontmatter.workflowRequirements,documents:.frontmatter.workflowDocuments,ownership:.frontmatter.workflowOwnership}')"
	metadata="$(jq -n --argjson items "$metadata" --argjson data "$data" '$items+[$data]')"
done < <(mtn --path "$TASK_ROOT" list --json | jq -r '.[].path')
jq -n -e -L "$skill/scripts" --argjson records "$metadata" 'include "workflow"; {requirements:["REQ-001","REQ-002","REQ-003"],records:$records}|metadata_valid' >/dev/null
for phase in components final; do
	records='[]'
	for id in a b c; do
		if [[ "$phase" == components && "$id" == c ]] || [[ "$phase" == final && "$id" != c ]]; then continue; fi
		records="$(jq -n --argjson records "$records" --arg ref "tasks/$id.md" --arg hash "$(fingerprint "tasks/$id.md")" '$records+[{ref:$ref,specHash:$hash}]')"
	done
	publish "$(event "phases/$phase.md" plan "$phase/plan/1" 1 | jq --arg phase "$phase" --argjson records "$records" --argjson docs "$documents" '.+{decision:"approved",records:$records,documents:$docs,coverage:(if $phase=="components" then {"REQ-001":["tasks/a.md"],"REQ-002":["tasks/b.md"]} else {"REQ-003":["tasks/c.md"]} end),approvedBy:"test fixture",decisionEvidence:"synthetic approval"}')"
done
publish "$(event projects/demo.md plan project/plan/1 1 | jq --argjson docs "$documents" --arg a "$(fingerprint phases/components.md)" --arg b "$(fingerprint phases/final.md)" '.+{decision:"approved",documents:$docs,records:[{ref:"phases/components.md",specHash:$a},{ref:"phases/final.md",specHash:$b}],coverage:{"REQ-001":["phases/components.md"],"REQ-002":["phases/components.md"],"REQ-003":["phases/final.md"]},approvedBy:"test fixture",decisionEvidence:"synthetic approval"}')"
plan_ready() {
	local ref="$1" docs='[]' records='[]' data child doc
	for doc in prds/demo.md designs/demo.md; do
		data="$(mtn --path "$TASK_ROOT" agent show "$doc" --json | jq --arg hash "$(fingerprint "$doc")" '{ref:.result.ref,specHash:$hash,events:[.result.evidence[].content|fromjson]}')"
		docs="$(jq -n --argjson items "$docs" --argjson data "$data" '$items+[$data]')"
	done
	while read -r child; do
		data="$(mtn --path "$TASK_ROOT" agent show "$child" --json | jq --arg hash "$(fingerprint "$child")" '{ref:.result.ref,specHash:$hash,requirements:.result.frontmatter.workflowRequirements}')"
		records="$(jq -n --argjson items "$records" --argjson data "$data" '$items+[$data]')"
	done < <(mtn --path "$TASK_ROOT" agent hierarchy "$ref" --json | jq -r '.result.children[]')
	mtn --path "$TASK_ROOT" agent show "$ref" --json |
		jq --arg hash "$(fingerprint "$ref")" --argjson docs "$docs" --argjson records "$records" '{ref:.result.ref,specHash:$hash,documents:$docs,records:$records,requirements:.result.frontmatter.workflowRequirements,events:[.result.evidence[].content|fromjson]}' |
		jq -e -L "$skill/scripts" 'include "workflow"; plan_approved' >/dev/null
}
plan_ready projects/demo.md
plan_ready phases/components.md
plan_ready phases/final.md
bash "$repo/modules/home/scripts/mtn-workflow" --repo "$target" ready projects/demo.md | jq -e '[.ready[].ref]==["tasks/a.md","tasks/b.md"]' >/dev/null
candidates='[]'
for id in a b c; do
	if [[ "$id" == c ]]; then phase=final; else phase=components; fi
	phase_ready="$(mtn --path "$TASK_ROOT" agent dependencies "phases/$phase.md" --json | jq '.result.dependencyReady')"
	task_ready="$(mtn --path "$TASK_ROOT" agent dependencies "tasks/$id.md" --json | jq '.result.dependencyReady')"
	phase_order="$(mtn --path "$TASK_ROOT" agent show "phases/$phase.md" --json | jq '.result.frontmatter.workflowOrder')"
	data="$(mtn --path "$TASK_ROOT" agent show "tasks/$id.md" --json | jq --argjson phaseOrder "$phase_order" --argjson phase "$phase_ready" --argjson dependency "$task_ready" '{ref:.result.ref,phaseOrder:$phaseOrder,order:.result.frontmatter.workflowOrder,incomplete:true,statusAllowed:true,dependencyReady:$dependency,phaseReady:$phase,documentsApproved:true,planApproved:true,state:"planned",agentEligible:null,ownership:.result.frontmatter.workflowOwnership}')"
	candidates="$(jq -n --argjson items "$candidates" --argjson data "$data" '$items+[$data]')"
done
jq -n -e -L "$skill/scripts" --argjson candidates "$candidates" 'include "workflow"; {maxParallel:2,active:[],candidates:$candidates}|ready_batch|map(.ref)==["tasks/a.md","tasks/b.md"]' >/dev/null
# A higher-numbered phase is eligible while the first phase remains blocked.
mtn --path "$TASK_ROOT" agent dependencies phases/final.md --json | jq -e '.result.dependencyReady==false' >/dev/null
mtn --path "$TASK_ROOT" agent dependencies phases/components.md --json | jq -e '.result.dependencyReady==true' >/dev/null
git -C "$target" add .
git -C "$target" commit -qm 'Initial approved fixture'
base="$(git -C "$target" rev-parse HEAD)"
mkfifo "$work/a.start" "$work/b.start" "$work/ready"
exec 7<>"$work/a.start" 8<>"$work/b.start" 9<>"$work/ready"
worker() {
	local id="$1" checkout="$2" attempt="$3" gate="$4"
	printf '%s\n' "$id" >&9
	if [[ "$gate" == a ]]; then read -r _ <&7; else read -r _ <&8; fi
	if [[ "$id" == c ]]; then
		printf '#!/usr/bin/env bash\nset -euo pipefail\nbash src/a.sh\nbash src/b.sh\n' >"$checkout/src/c.sh"
	else
		printf '#!/usr/bin/env bash\nset -euo pipefail\nprintf "%s-%s\\n"\n' "$id" "$attempt" >"$checkout/src/$id.sh"
	fi
	(cd "$checkout" && bash "src/$id.sh") >"$work/results/$id-$attempt.output"
	git -C "$checkout" add "src/$id.sh"
	git -C "$checkout" commit -qm "Implement $id attempt $attempt"
	jq -n --arg head "$(git -C "$checkout" rev-parse HEAD)" --arg tree "$(git -C "$checkout" rev-parse 'HEAD^{tree}')" \
		'{head:$head,tree:$tree,outcome:"ready-for-review",validation:[{command:"bash scoped implementation",result:"pass"}]}' >"$work/results/$id-$attempt.json"
}
dispatch() {
	local id="$1" attempt="$2" checkout="$3" start="$4" phase_ref ref
	if [[ "$id" == c ]]; then phase_ref=phases/final.md; else phase_ref=phases/components.md; fi
	for ref in "tasks/$id.md" "$phase_ref" projects/demo.md; do
		printf '%s\n' '{"status":"in-progress"}' | mtn --path "$TASK_ROOT" agent status "$ref" --input - --json >/dev/null
	done
	publish "$(event "tasks/$id.md" dispatch "$id/dispatch/$attempt" "$attempt" | jq --arg worktree "$checkout" --arg base "$start" --arg branch "worker-$id" --arg run "$id-$attempt" '.+{runId:$run,baseCommit:$base,branch:$branch,worktree:$worktree,targetBranch:"main"}')"
}
built() {
	local id="$1" attempt="$2"
	publish "$(event "tasks/$id.md" build "$id/build/$attempt" "$attempt" | jq --argjson data "$(<"$work/results/$id-$attempt.json")" --arg dispatch "$id/dispatch/$attempt" '.+$data+{dispatchEventId:$dispatch}')"
}
build_record() {
	mtn --path "$TASK_ROOT" agent show "tasks/$1.md" --json |
		jq -c --arg id "$1/build/$2" '.result.evidence[].content|fromjson|select(.kind=="build" and .eventId==$id)'
}
review() {
	local id="$1" attempt="$2" verdict="$3"
	publish "$(event "tasks/$id.md" review "$id/review/$attempt" "$attempt" | jq --argjson data "$(build_record "$id" "$attempt")" --arg build "$id/build/$attempt" --arg verdict "$verdict" '.+{buildEventId:$build,head:$data.head,tree:$data.tree,reviewer:"combined",verdict:$verdict,changes_required:(if $verdict=="APPROVED" then [] else [{id:"R-001",evidence:"fixture requests second behavior revision"}] end),validation:[{command:"fixture independent review",result:"pass"}]}')"
}
for id in a b; do
	git -C "$target" worktree add -q -b "worker-$id" "$work/worker-$id" "$base"
	dispatch "$id" 1 "$work/worker-$id" "$base"
	worker "$id" "$work/worker-$id" 1 "$id" &
	pids+=("$!")
done
read -r first <&9
read -r second <&9
[[ "$first" != "$second" ]] # Both workers exist at the barrier before either is released.
printf 'go\n' >&7
printf 'go\n' >&8
for pid in "${pids[@]}"; do wait "$pid"; done
pids=()
for id in a b; do built "$id" 1; done
review a 1 CHANGES_NEEDED
review b 1 APPROVED
[[ "$(state tasks/a.md)" == fixing ]]
[[ "$(state tasks/b.md)" == awaiting-integration ]]
# Transport artifacts are not needed once results have been published to mtn.
mv "$work/results/b-1.json" "$work/results/b-1.transport-archived"
mv "$work/results/a-1.json" "$work/results/a-1.transport-archived"
# A fresh coordinator process can derive the next action with no saved execution state.
export TASK_ROOT skill
export -f fingerprint state
bash -c '[[ "$(state tasks/b.md)" == awaiting-integration ]]'
integrate() {
	local id="$1" attempt="$2" try="${3:-1}" fail="${4:-false}" start head before commit tree data dispatch_id candidate
	[[ "$(state "tasks/$id.md")" == awaiting-integration ]]
	data="$(build_record "$id" "$attempt")"
	head="$(jq -r .head <<<"$data")"
	dispatch_id="$(jq -r .dispatchEventId <<<"$data")"
	start="$(mtn --path "$TASK_ROOT" agent show "tasks/$id.md" --json | jq -r --arg id "$dispatch_id" '.result.evidence[].content|fromjson|select(.kind=="dispatch" and .eventId==$id)|.baseCommit')"
	# Worker changes cannot smuggle task metadata or unrelated files into integration.
	[[ "$(git -C "$target" diff --name-only "$start" "$head")" == "src/$id.sh" ]]
	before="$(git -C "$target" rev-parse HEAD)"
	candidate="$work/candidate-$id-$attempt-$try"
	git -C "$target" worktree add -q -b "candidate-$id-$attempt-$try" "$candidate" "$before"
	while read -r commit; do git -C "$candidate" cherry-pick "$commit" >/dev/null; done < <(git -C "$target" rev-list --reverse "$start..$head")
	commit="$(git -C "$candidate" rev-parse HEAD)"
	tree="$(git -C "$candidate" rev-parse 'HEAD^{tree}')"
	if [[ "$fail" == true ]]; then
		# Deliberate combined-check failure: retain candidate without advancing main.
		if (cd "$candidate" && bash -c 'exit 1'); then exit 1; fi
		publish "$(event "tasks/$id.md" integration "$id/integration-failed/$attempt-$try" "$attempt" | jq --argjson data "$data" --arg build "$id/build/$attempt" --arg review "$id/review/$attempt" --arg base "$before" --arg commit "$commit" --arg tree "$tree" '.+{buildEventId:$build,head:$data.head,tree:$data.tree,reviewEventIds:[$review],targetBranch:"main",targetBase:$base,candidateCommit:$commit,candidateTree:$tree,outcome:"failed",validation:[{command:"deliberately failing combined check",result:"fail"}]}')"
		[[ "$(git -C "$target" rev-parse HEAD)" == "$before" ]]
		[[ "$(state "tasks/$id.md")" == awaiting-integration ]]
		return
	fi
	(cd "$candidate" && bash "src/$id.sh") >/dev/null
	[[ "$(git -C "$target" rev-parse HEAD)" == "$before" ]]
	git -C "$target" merge --ff-only "candidate-$id-$attempt-$try" >/dev/null
	git -C "$target" merge-base --is-ancestor "$commit" main
	publish "$(event "tasks/$id.md" integration "$id/integration/$attempt" "$attempt" | jq --argjson data "$data" --arg build "$id/build/$attempt" --arg review "$id/review/$attempt" --arg base "$before" --arg commit "$commit" --arg tree "$tree" '.+{buildEventId:$build,head:$data.head,tree:$data.tree,reviewEventIds:[$review],targetBranch:"main",targetBase:$base,integratedCommit:$commit,integratedTree:$tree,outcome:"passed",validation:[{command:"combined target scoped check",result:"pass"}]}')"
	[[ "$(state "tasks/$id.md")" == integrated ]]
	publish "$(event "tasks/$id.md" completion "$id/completion/$attempt" "$attempt" | jq --arg integration "$id/integration/$attempt" '.+{integrationEventId:$integration}')"
	mtn --path "$TASK_ROOT" agent complete "tasks/$id.md" --json >/dev/null
	[[ "$(state "tasks/$id.md")" == complete ]]
}
integrate b 1 1 true
integrate b 1 2
mtn --path "$TASK_ROOT" agent dependencies tasks/c.md --json | jq -e '.result.dependencyReady==false' >/dev/null
# A fix is a new build/review identity. Its old rejection cannot approve the fix.
dispatch a 2 "$work/worker-a" "$base"
printf 'go\n' >&7
worker a "$work/worker-a" 2 a
built a 2
[[ "$(state tasks/a.md)" == reviewing ]]
review a 2 APPROVED
integrate a 2
# Final phase only becomes ready after its prerequisite phase is explicitly completed.
(cd "$target" && bash src/a.sh && bash src/b.sh) >"$work/combined.output"
publish "$(event phases/components.md milestone components/final-gates/1 1 | jq --arg commit "$(git -C "$target" rev-parse HEAD)" --arg tree "$(git -C "$target" rev-parse 'HEAD^{tree}')" '.+{targetCommit:$commit,targetTree:$tree,records:["tasks/a.md","tasks/b.md"],targetBranch:"main",validation:[{command:"bash src/a.sh && bash src/b.sh",result:"pass"}],coverage:["REQ-001","REQ-002"]}')"
mtn --path "$TASK_ROOT" agent complete phases/components.md --json >/dev/null
mtn --path "$TASK_ROOT" agent dependencies phases/final.md --json | jq -e '.result.dependencyReady==true' >/dev/null
mtn --path "$TASK_ROOT" agent dependencies tasks/c.md --json | jq -e '.result.dependencyReady==true' >/dev/null
current="$(git -C "$target" rev-parse HEAD)"
git -C "$target" worktree add -q -b worker-c "$work/worker-c" "$current"
dispatch c 1 "$work/worker-c" "$current"
printf 'go\n' >&7
worker c "$work/worker-c" 1 a
built c 1
review c 1 APPROVED
integrate c 1
(cd "$target" && bash src/c.sh) >"$work/final.output"
publish "$(event phases/final.md milestone final/final-gates/1 1 | jq --arg commit "$(git -C "$target" rev-parse HEAD)" --arg tree "$(git -C "$target" rev-parse 'HEAD^{tree}')" '.+{targetCommit:$commit,targetTree:$tree,records:["tasks/c.md"],targetBranch:"main",validation:[{command:"bash src/c.sh",result:"pass"}],coverage:["REQ-003"]}')"
mtn --path "$TASK_ROOT" agent complete phases/final.md --json >/dev/null
mtn --path "$TASK_ROOT" agent hierarchy projects/demo.md --json | jq -e '.result.progress.completed==3 and .result.progress.total==3' >/dev/null
publish "$(event projects/demo.md milestone project/final-gates/1 1 | jq --arg commit "$(git -C "$target" rev-parse HEAD)" --arg tree "$(git -C "$target" rev-parse 'HEAD^{tree}')" '.+{targetCommit:$commit,targetTree:$tree,records:["phases/components.md","phases/final.md"],targetBranch:"main",validation:[{command:"bash src/c.sh",result:"pass"}],coverage:["REQ-001","REQ-002","REQ-003"]}')"
mtn --path "$TASK_ROOT" agent complete projects/demo.md --json >/dev/null
mtn --path "$TASK_ROOT" agent validate --json | jq -e '.ok and .result.valid' >/dev/null
bash "$repo/modules/home/scripts/mtn-workflow" --repo "$target" ready projects/demo.md | jq -e '.ready==[]' >/dev/null
# Native timestamps/evidence/lifecycle did not change the immutable task fingerprint.
[[ "$original_hash_a" == "$(fingerprint tasks/a.md)" ]]
printf 'Parallel delivery exercise passed (deterministic worker processes, not LLM agents)\n'

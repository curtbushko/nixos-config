#!/usr/bin/env bash
set -euo pipefail

for command in mtn jq mktemp mkdir mv dirname; do
	command -v "$command" >/dev/null || exit 1
done
skills="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
repo_root="$(cd "$skills/../../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-workflow.XXXXXX")"
cleanup() {
	mkdir -p "$repo_root/.trash/mtn-skill-tests"
	mv "$work" "$repo_root/.trash/mtn-skill-tests/"
}
trap cleanup EXIT
export HOME="$work/home"
mkdir -p "$HOME"
TASK_ROOT="$work/repository with spaces/.tasks"
export MDBASE_TASKNOTES_PATH="$work/wrong-vault"
mtn init "$TASK_ROOT" >/dev/null
mtn --path "$TASK_ROOT" diagnose --json | jq -e '.ok and .result.capabilities.evidence and .result.capabilities.hierarchy' >/dev/null

create() {
	mtn --path "$TASK_ROOT" agent create --input - --json
}
project='{"title":"Demo project","path":"projects/demo.md","description":"Project scope","fields":{"workflowKind":"project"},"retryKey":"demo-project-v1"}'
printf '%s\n' "$project" | create >"$work/project.json"
printf '%s\n' "$project" | create | jq -e '.ok and (.result.changed == false) and .result.ref == "projects/demo.md"' >/dev/null
printf '%s\n' '{"title":"PRD","path":"prds/demo.md","description":"## Stories\n1. Literal input.","fields":{"workflowKind":"prd"}}' | create >/dev/null
printf '%s\n' '{"title":"Phase 1","path":"phases/demo-01.md","description":"Implement stories 1–2","fields":{"workflowKind":"phase","workflowOrder":1}}' | create >/dev/null
printf '%s\n' '{"target":"projects/demo.md"}' | mtn --path "$TASK_ROOT" agent project-add phases/demo-01.md --input - --json >/dev/null
for number in 1 2; do
	jq -n --arg title "Task $number tomorrow #literal" --arg path "tasks/demo-01-0$number.md" --argjson order "$number" \
		'{title:$title,path:$path,description:"## Acceptance\nPreserve literal input.",fields:{workflowKind:"task",workflowOrder:$order,workflowLanguage:"go"}}' | create >/dev/null
	printf '%s\n' '{"target":"phases/demo-01.md"}' | mtn --path "$TASK_ROOT" agent project-add "tasks/demo-01-0$number.md" --input - --json >/dev/null
done
REF='tasks/demo-01-01.md'
DEPENDENT_REF='tasks/demo-01-02.md'
printf '%s\n' '{"target":"tasks/demo-01-01.md"}' | mtn --path "$TASK_ROOT" agent depends-add "$DEPENDENT_REF" --input - --json >/dev/null
mtn --path "$TASK_ROOT" agent dependencies "$DEPENDENT_REF" --json | jq -e '.ok and (.result.dependencyReady == false)' >/dev/null
# A cycle must fail without corrupting the graph.
if printf '%s\n' '{"target":"tasks/demo-01-02.md"}' | mtn --path "$TASK_ROOT" agent depends-add "$REF" --input - --json >"$work/cycle.json"; then
	printf 'Expected dependency cycle rejection\n' >&2
	exit 1
fi
jq -e '.ok == false' "$work/cycle.json" >/dev/null
printf '%s\n' '{"status":"in-progress"}' | mtn --path "$TASK_ROOT" agent status "$REF" --input - --json >/dev/null
printf '%s\n' '{"operations":[{"op":"set","field":"workflowOrder","value":3}]}' | mtn --path "$TASK_ROOT" agent patch "$REF" --input - --json >/dev/null
note='{"content":"Build attempt 1: focused test passed; full suite passed","role":"builder","category":"build","adopt":true,"retryKey":"build-attempt-1"}'
printf '%s\n' "$note" | mtn --path "$TASK_ROOT" agent note "$REF" --input - --json >/dev/null
printf '%s\n' "$note" | mtn --path "$TASK_ROOT" agent note "$REF" --input - --json | jq -e '.ok and (.result.changed == false)' >/dev/null
printf '%s\n' '{"description":"## Acceptance\nUpdated description."}' | mtn --path "$TASK_ROOT" agent describe "$REF" --input - --json >/dev/null
# Review payloads are serialized as content, and published one writer at a time.
for specialty in code comment architecture test; do
	jq -n --arg role "$specialty" \
		'{content:({reviewer:$role,attempt:1,revision:"test-diff",verdict:"APPROVED",changes_required:[],NON_BLOCKING_SUGGESTIONS:[]}|tojson),role:$role,category:"review",adopt:true,retryKey:($role+"-attempt-1")}' |
		mtn --path "$TASK_ROOT" agent note "$REF" --input - --json >/dev/null
done
mtn --path "$TASK_ROOT" agent show "$REF" --json >"$work/show.json"
jq -e '.ok and (.result.evidence | length == 5) and .result.frontmatter.workflowOrder == 3 and .result.description == "## Acceptance\nUpdated description."' "$work/show.json" >/dev/null
# Evidence approval does not complete tasks or unblock dependents.
mtn --path "$TASK_ROOT" agent dependencies "$DEPENDENT_REF" --json | jq -e '.result.dependencyReady == false' >/dev/null
mtn --path "$TASK_ROOT" agent complete "$REF" --json >/dev/null
mtn --path "$TASK_ROOT" agent dependencies "$DEPENDENT_REF" --json | jq -e '.result.dependencyReady == true' >/dev/null
mtn --path "$TASK_ROOT" agent hierarchy projects/demo.md --json | jq -e '.result.progress.completed == 1 and .result.progress.total == 2 and .result.parentStatus == "open"' >/dev/null
mtn --path "$TASK_ROOT" agent reopen "$REF" --json >/dev/null
mtn --path "$TASK_ROOT" agent dependencies "$DEPENDENT_REF" --json | jq -e '.result.dependencyReady == false' >/dev/null
mtn --path "$TASK_ROOT" agent ready phases/demo-01.md --json | jq -e '.result.claim == false and (.result.evaluated | all(.agentEligible == null))' >/dev/null
mtn --path "$TASK_ROOT" list --json | jq -e 'length == 5 and ([.[] | select(.workflowKind == "task")] | length == 2)' >/dev/null
mtn --path "$TASK_ROOT" agent validate --json | jq -e '.ok and .result.valid' >/dev/null
[[ ! -e "$MDBASE_TASKNOTES_PATH" ]]
printf 'mtn workflow smoke checks passed\n'

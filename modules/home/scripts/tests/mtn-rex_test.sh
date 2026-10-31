#!/usr/bin/env bash
set -euo pipefail
for tool in mtn git jq mktemp mkdir mv dirname chmod grep; do command -v "$tool" >/dev/null || exit 1; done
scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(cd "$scripts/../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-rex.XXXXXX")"
trap 'mkdir -p "$repo/.trash/mtn-rex-tests"; mv "$work" "$repo/.trash/mtn-rex-tests/"' EXIT
mkdir -p "$work/bin" "$work/Demo Project"
export FIXTURE="$work" SCRIPTS="$scripts"
export PATH="$work/bin:$PATH"
export MTN_WORKFLOW_COORDINATOR=1
export MTN_REX_LIB="$scripts/../llm/skills/mtn-tasks/scripts"
git init -q "$work/Demo Project"
git -C "$work/Demo Project" -c user.name=Fixture -c user.email=fixture@example.invalid commit -q --allow-empty -m 'Fixture base'
git -C "$work/Demo Project" worktree add -q -b feature "$work/feature worktree"
printf '.mtn-tmp/\n' >"$work/feature worktree/.gitignore"
mtn init "$work/feature worktree/.tasks" >/dev/null
root="$work/feature worktree"
for kind in phase task; do
	jq -n --arg kind "$kind" '{title:"Authentication",path:($kind+"s/demo.md"),description:"REQ-001",fields:{workflowKind:$kind,workflowOrder:1,workflowLanguage:"go"}}' | mtn --path "$root/.tasks" agent create --input - --json >/dev/null
done
printf '%s\n' '{"target":"phases/demo.md"}' | mtn --path "$root/.tasks" agent project-add tasks/demo.md --input - --json >/dev/null
# Stubs exercise exact argv and real mtn publication, without starting agents/servers.
cp "$scripts/tests/fixtures/mtn-rex-workflow" "$work/bin/mtn-workflow"
cp "$scripts/tests/fixtures/mtn-rex-pi" "$work/bin/pi"
cp "$scripts/tests/fixtures/mtn-rex-rex" "$work/bin/rex"
chmod +x "$work/bin/"*
cli() { bash "$scripts/mtn-rex" --repo "$root" "$@"; }
workflow() { bash "$scripts/mtn-workflow" --repo "$root" "$@"; }
phase_hash="$(workflow fingerprint phases/demo.md)"
task_hash="$(workflow fingerprint tasks/demo.md)"
jq -n --arg hash "$phase_hash" --arg wt "$root" '{recordRef:"phases/demo.md",specHash:$hash,attempt:1,runId:"demo-project-p01-coordinator-a01",role:"coordinator",skill:"go-team",worktree:$wt,model:"fixture/model",thinking:"high",handoff:true,prompt:"Execute phase=phases/demo.md; preserve approved scope."}' >"$work/coordinator.json"
if TRANSPORT=tcp cli launch "$work/coordinator.json" >/dev/null 2>&1; then exit 1; fi
[[ "$(workflow snapshot phases/demo.md | jq '.events|length')" == 0 ]]
# A valid Pi ID describing the wrong scope is rejected before any Rex creation.
jq '.runId="demo-project-p99-coordinator-a01"' "$work/coordinator.json" >"$work/wrong-focus.json"
if cli launch "$work/wrong-focus.json" >"$work/wrong-focus-error.txt" 2>&1; then exit 1; fi
grep -Fq 'runId must match the canonical agent identity: demo-project-p01-coordinator-a01' "$work/wrong-focus-error.txt"
[[ "$(jq -s '[.[]|select(index("new"))]|length' "$work/rex.jsonl")" == 0 ]]
cli launch "$work/coordinator.json" >"$work/launched.json"
jq -e '.kind=="runtime" and .stage=="launched" and .rexSessionId=="session:parent" and .rexSessionName=="demo-project-feature-worktree" and .sessionName==.rexSessionName and .rexWindowName=="p01-coordinator-a01" and .windowName==.rexWindowName and .piSessionName==.rexWindowName and .piSessionId=="demo-project-p01-coordinator-a01" and .piSessionId==.runId' "$work/launched.json" >/dev/null
jq -e '.rexWindowName==.piSessionName and .piSessionName!=.piSessionId and .piSessionId==.runId and ([.rexSessionName,.rexWindowName,.piSessionName,.piSessionId]|all(.[];test("^[a-z0-9]+(-[a-z0-9]+)*$")))' "$work/launched.json" >/dev/null
workflow snapshot phases/demo.md | jq -e '[.events[].stage]==["reserved","launched"]' >/dev/null
[[ "$phase_hash" == "$(workflow fingerprint phases/demo.md)" ]]
if cli launch "$work/coordinator.json" >/dev/null 2>&1; then exit 1; fi
[[ "$(jq -s '[.[]|select(index("new"))]|length' "$work/rex.jsonl")" == 1 ]]
# A different run ID must not bypass single-coordinator ownership.
jq '.runId="demo-project-p01-coordinator-a02" | .attempt=2' "$work/coordinator.json" >"$work/duplicate.json"
if cli launch "$work/duplicate.json" >/dev/null 2>&1; then
	printf 'A second coordinator was allowed\n' >&2
	exit 1
fi
# Rex's server may have a minimal PATH without Pi or the user's Nix profile.
mkdir -p "$work/basebin"
for tool in jq git dirname basename mkdir sleep tee; do
	ln -s "$(command -v "$tool")" "$work/basebin/$tool"
done
# Child starts only after durable identity publication; coordinator gets a recursion guard.
PATH="$work/basebin:/usr/bin:/bin" /bin/bash "$scripts/mtn-rex" agent "$root/.mtn-tmp/rex/demo-project-p01-coordinator-a01" >/dev/null
jq -s -e 'last|index("--session-id") as $id | index("--name") as $name | .[$id+1]=="demo-project-p01-coordinator-a01" and .[$name+1]=="p01-coordinator-a01" and index("--print")==null and (last|contains("Runtime identity:") and contains("session:parent") and contains("window:coord") and contains("block:coord"))' "$work/pi.jsonl" >/dev/null
[[ "$(jq -s '[.[]|select(index("close"))]|length' "$work/rex.jsonl")" == 0 ]]
jq -s -e 'last | last | contains("Keep terminal output concise") and contains("Never echo task Markdown")' "$work/pi.jsonl" >/dev/null
jq -n --arg hash "$task_hash" --arg wt "$root" '{schemaVersion:1,eventId:"dispatch/1",kind:"dispatch",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,runId:"demo-project-p01-t01-builder-a01",baseCommit:"base",branch:"feature",targetBranch:"main",worktree:$wt}' >"$work/dispatch.json"
workflow publish "$work/dispatch.json" >/dev/null
jq -n --arg hash "$task_hash" --arg wt "$root" '{recordRef:"tasks/demo.md",specHash:$hash,attempt:1,runId:"demo-project-p01-t01-builder-a01",role:"builder",skill:"go-builder",worktree:$wt,model:"fixture/model",thinking:"medium",phaseRef:"phases/demo.md",parentRunId:"demo-project-p01-coordinator-a01",dispatchEventId:"dispatch/1",prompt:"Return the build payload."}' >"$work/worker.json"
if MTN_REX_COORDINATOR_RUN=demo-project-p01-coordinator-a01 INSTANCE=restarted cli launch "$work/worker.json" >/dev/null 2>&1; then exit 1; fi
DEFAULT_REMOTE=1 MTN_REX_COORDINATOR_RUN=demo-project-p01-coordinator-a01 cli launch "$work/worker.json" >"$work/worker-launch.json"
jq -e '.rexWindowName=="p01-t01-builder-a01" and .piSessionName==.rexWindowName and .windowName==.rexWindowName and .rexSessionName=="demo-project-feature-worktree" and .rexSessionId=="session:parent" and .dispatchEventId=="dispatch/1"' "$work/worker-launch.json" >/dev/null
jq -s -e '[.[] | select(index("window"))] | last | index("session:parent")!=null and index("--focus=false")!=null and index("p01-t01-builder-a01")!=null' "$work/rex.jsonl" >/dev/null
# Worker role is a leaf and never inherits the publication marker.
worker_dir="$root/.mtn-tmp/rex/demo-project-p01-t01-builder-a01"
bash "$scripts/mtn-rex" agent "$worker_dir" >"$work/worker-output.txt" 2>&1
[[ "$(<"$worker_dir/exit-code")" == 0 ]]
jq -e '.outcome=="ready-for-review"' "$worker_dir/result.json" >/dev/null
if grep -Eq 'ready-for-review|Fixture provider diagnostic' "$work/worker-output.txt"; then
	exit 1
fi
grep -Fq 'Fixture provider diagnostic' "$worker_dir/stderr.log"
jq -s -e '[.[]|select(index("close"))]|length==1 and (last|index("unix:///fixture.sock")!=null and index("session:parent")!=null and index("window:worker")!=null)' "$work/rex.jsonl" >/dev/null
# Fixture-only replays cover failures without launching real Pi conversations.
for scenario in process malformed multiple blocked review; do
	before="$(jq -s '[.[]|select(index("close"))]|length' "$work/rex.jsonl")"
	case "$scenario" in
	process) export PI_EXIT=7 PI_RESULT='{"outcome":"ready-for-review"}' ;;
	malformed) export PI_EXIT=0 PI_RESULT='not JSON' ;;
	multiple) export PI_EXIT=0 PI_RESULT=$'{"a":1}\n{"b":2}' ;;
	blocked) export PI_EXIT=0 PI_RESULT='{"outcome":"blocked"}' ;;
	review) export PI_EXIT=0 PI_RESULT='{"verdict":"CHANGES_NEEDED"}' ;;
	esac
	code=0
	bash "$scripts/mtn-rex" agent "$worker_dir" >"$work/$scenario-output.txt" 2>&1 || code=$?
	if [[ "$scenario" == process ]]; then [[ "$code" == 7 ]]; fi
	[[ "$(jq -s '[.[]|select(index("close"))]|length' "$work/rex.jsonl")" == "$before" ]]
done
unset PI_EXIT PI_RESULT
# Never close resources on a restarted or different host/server instance.
before="$(jq -s '[.[]|select(index("close"))]|length' "$work/rex.jsonl")"
INSTANCE=restarted bash "$scripts/mtn-rex" agent "$worker_dir" >"$work/instance-error.txt" 2>&1
[[ "$(jq -s '[.[]|select(index("close"))]|length' "$work/rex.jsonl")" == "$before" ]]
grep -Fq 'could not close' "$work/instance-error.txt"
# Restore a successful fixture result; close failures preserve evidence.
FAIL_CLOSE=1 bash "$scripts/mtn-rex" agent "$worker_dir" >"$work/close-error.txt" 2>&1
grep -Fq 'could not close' "$work/close-error.txt"
[[ "$(<"$worker_dir/exit-code")" == 0 ]]
cli result tasks/demo.md demo-project-p01-t01-builder-a01 | jq -e '.outcome=="ready-for-review"' >/dev/null
cli inspect tasks/demo.md demo-project-p01-t01-builder-a01 | jq -e '.running==true' >/dev/null
jq -s -e 'last|index("--session-id") as $id | index("--name") as $name | index("--print")!=null and .[$id+1]=="demo-project-p01-t01-builder-a01" and .[$name+1]=="p01-t01-builder-a01" and (last|contains("Runtime identity:") and contains("session:parent") and contains("window:worker") and contains("block:worker"))' "$work/pi.jsonl" >/dev/null
# Phase/task labels disambiguate workers without starting another Rex session.
[[ "$(jq -s '[.[]|select(index("window"))|select(index("new"))]|length' "$work/rex.jsonl")" == 1 ]]
# Dependency-ready work in another phase still belongs to this one coordinator.
for kind in phase task; do
	jq -n --arg kind "$kind" '{title:"Other phase",path:($kind+"s/other.md"),description:"REQ-002",fields:{workflowKind:$kind,workflowOrder:2,workflowLanguage:"go"}}' | mtn --path "$root/.tasks" agent create --input - --json >/dev/null
done
printf '%s\n' '{"target":"phases/other.md"}' | mtn --path "$root/.tasks" agent project-add tasks/other.md --input - --json >/dev/null
other_hash="$(workflow fingerprint tasks/other.md)"
jq --arg hash "$other_hash" '.recordRef="tasks/other.md" | .specHash=$hash | .eventId="dispatch/other" | .runId="demo-project-p02-t02-builder-a01"' "$work/dispatch.json" >"$work/dispatch-other.json"
workflow publish "$work/dispatch-other.json" >/dev/null
jq --arg hash "$other_hash" '.recordRef="tasks/other.md" | .phaseRef="phases/other.md" | .coordinatorPhaseRef="phases/demo.md" | .specHash=$hash | .dispatchEventId="dispatch/other" | .runId="demo-project-p02-t02-builder-a01"' "$work/worker.json" >"$work/other.json"
MTN_REX_COORDINATOR_RUN=demo-project-p01-coordinator-a01 cli launch "$work/other.json" | jq -e '.rexSessionId=="session:parent" and .rexWindowName=="p02-t02-builder-a01" and .piSessionName==.rexWindowName' >/dev/null
[[ "$(jq -s '[.[]|select(index("window"))|select(index("new"))]|length' "$work/rex.jsonl")" == 2 ]]
[[ "$(jq -s '[.[]|select(index("new"))|select(index("window")|not)]|length' "$work/rex.jsonl")" == 1 ]]
# A phase planner uses the same Rex session and explicitly names its role.
other_phase_hash="$(workflow fingerprint phases/other.md)"
jq -n --arg hash "$other_phase_hash" --arg wt "$root" '{recordRef:"phases/other.md",specHash:$hash,attempt:2,runId:"demo-project-p02-planner-a02",role:"planner",skill:"mtn-tasks",worktree:$wt,model:"fixture/model",thinking:"medium",phaseRef:"phases/other.md",coordinatorPhaseRef:"phases/demo.md",parentRunId:"demo-project-p01-coordinator-a01",prompt:"Return the planning proposal."}' >"$work/planner.json"
MTN_REX_COORDINATOR_RUN=demo-project-p01-coordinator-a01 cli launch "$work/planner.json" | jq -e '.rexSessionId=="session:parent" and .rexWindowName=="p02-planner-a02" and .piSessionName==.rexWindowName' >/dev/null
# A reviewer shares the task scope but has its own canonical Pi conversation.
jq '.role="reviewer" | .skill="go-reviewer" | .runId="demo-project-p01-t01-reviewer-a01"' "$work/worker.json" >"$work/reviewer.json"
MTN_REX_COORDINATOR_RUN=demo-project-p01-coordinator-a01 cli launch "$work/reviewer.json" | jq -e '.runId=="demo-project-p01-t01-reviewer-a01" and .rexWindowName=="p01-t01-reviewer-a01" and .piSessionName==.rexWindowName and .piSessionId==.runId' >/dev/null
bash "$scripts/mtn-rex" agent "$root/.mtn-tmp/rex/demo-project-p01-t01-reviewer-a01" >/dev/null
jq -s -e 'last|index("--session-id") as $id | index("--name") as $name | .[$id+1]=="demo-project-p01-t01-reviewer-a01" and .[$name+1]=="p01-t01-reviewer-a01"' "$work/pi.jsonl" >/dev/null
# The next coordinator requires an explicit release after confirmed process exit.
jq -n --arg hash "$phase_hash" '{schemaVersion:1,eventId:"demo-project-p01-coordinator-a01/release",kind:"release",recordRef:"phases/demo.md",specHash:$hash,attempt:1,dispatchEventId:"demo-project-p01-coordinator-a01/runtime/reserved",outcome:"finished",processEvidence:"fixture child exited"}' >"$work/release.json"
workflow publish "$work/release.json" >/dev/null
# Publication failure must never open the startup gate. Reserved attempts cannot relaunch.
jq '.runId="demo-project-p01-coordinator-a03" | .attempt=3' "$work/coordinator.json" >"$work/fail.json"
if REJECT_LAUNCH=1 cli launch "$work/fail.json" >/dev/null 2>&1; then exit 1; fi
[[ ! -e "$root/.mtn-tmp/rex/demo-project-p01-coordinator-a03/ready" ]]
if cli launch "$work/fail.json" >/dev/null 2>&1; then exit 1; fi
# Reject traversal and stale hashes before creating Rex resources.
for change in '.runId="../escape"' '.specHash="stale" | .runId="stale"'; do
	jq "$change" "$work/coordinator.json" >"$work/bad.json"
	if cli launch "$work/bad.json" >/dev/null 2>&1; then exit 1; fi
done
lib="$MTN_REX_LIB"
jq -e -L "$lib" 'include "workflow"; valid_event' "$work/launched.json" >/dev/null
if jq 'del(.rexBlockId)' "$work/launched.json" | jq -e -L "$lib" 'include "workflow"; valid_event' >/dev/null; then exit 1; fi
# Explicit names must agree, while pre-upgrade runtime notes remain valid.
jq 'del(.rexSessionName,.rexWindowName,.piSessionName)' "$work/launched.json" | jq -e -L "$lib" 'include "workflow"; valid_event' >/dev/null
if jq '.piSessionName="wrong-agent"' "$work/launched.json" | jq -e -L "$lib" 'include "workflow"; valid_event' >/dev/null; then exit 1; fi
workflow status tasks/demo.md | jq -e '.state=="building"' >/dev/null
printf 'Rex/Pi launch and mtn identity checks passed\n'

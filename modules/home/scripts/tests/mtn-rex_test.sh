#!/usr/bin/env bash
set -euo pipefail
for tool in mtn git jq mktemp mkdir mv dirname chmod; do command -v "$tool" >/dev/null || exit 1; done
scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
repo="$(cd "$scripts/../../.." && pwd)"
work="$(mktemp -d "${TMPDIR:-/tmp}/mtn-rex.XXXXXX")"
trap 'mkdir -p "$repo/.trash/mtn-rex-tests"; mv "$work" "$repo/.trash/mtn-rex-tests/"' EXIT
mkdir -p "$work/bin" "$work/feature worktree"
export FIXTURE="$work" SCRIPTS="$scripts"
export PATH="$work/bin:$PATH"
export MTN_WORKFLOW_COORDINATOR=1
export MTN_REX_LIB="$scripts/../llm/skills/mtn-tasks/scripts"
git init -q "$work/feature worktree"
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
jq -n --arg hash "$phase_hash" --arg wt "$root" '{recordRef:"phases/demo.md",specHash:$hash,attempt:1,runId:"coord-1",role:"coordinator",skill:"go-team",worktree:$wt,model:"fixture/model",thinking:"high",handoff:true,prompt:"Execute phase=phases/demo.md; preserve approved scope."}' >"$work/coordinator.json"
if TRANSPORT=tcp cli launch "$work/coordinator.json" >/dev/null 2>&1; then exit 1; fi
[[ "$(workflow snapshot phases/demo.md | jq '.events|length')" == 0 ]]
cli launch "$work/coordinator.json" >"$work/launched.json"
jq -e '.kind=="runtime" and .stage=="launched" and .rexSessionId=="session:parent" and .sessionName=="feature worktree" and .windowName=="phase-1-Authentication" and .piSessionId=="coord-1"' "$work/launched.json" >/dev/null
workflow snapshot phases/demo.md | jq -e '[.events[].stage]==["reserved","launched"]' >/dev/null
[[ "$phase_hash" == "$(workflow fingerprint phases/demo.md)" ]]
if cli launch "$work/coordinator.json" >/dev/null 2>&1; then exit 1; fi
[[ "$(jq -s '[.[]|select(index("new"))]|length' "$work/rex.jsonl")" == 1 ]]
# A different run ID must not bypass single-coordinator ownership.
jq '.runId="duplicate-coordinator"' "$work/coordinator.json" >"$work/duplicate.json"
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
PATH="$work/basebin:/usr/bin:/bin" /bin/bash "$scripts/mtn-rex" agent "$root/.mtn-tmp/rex/coord-1" >/dev/null
jq -s -e 'last|index("--session-id")!=null and index("coord-1")!=null and index("--print")==null' "$work/pi.jsonl" >/dev/null
jq -n --arg hash "$task_hash" --arg wt "$root" '{schemaVersion:1,eventId:"dispatch/1",kind:"dispatch",recordRef:"tasks/demo.md",specHash:$hash,attempt:1,runId:"build-1",baseCommit:"base",branch:"feature",targetBranch:"main",worktree:$wt}' >"$work/dispatch.json"
workflow publish "$work/dispatch.json" >/dev/null
jq -n --arg hash "$task_hash" --arg wt "$root" '{recordRef:"tasks/demo.md",specHash:$hash,attempt:1,runId:"build-1",role:"builder",skill:"go-builder",worktree:$wt,model:"fixture/model",thinking:"medium",phaseRef:"phases/demo.md",parentRunId:"coord-1",dispatchEventId:"dispatch/1",prompt:"Return the build payload."}' >"$work/worker.json"
if MTN_REX_COORDINATOR_RUN=coord-1 INSTANCE=restarted cli launch "$work/worker.json" >/dev/null 2>&1; then exit 1; fi
DEFAULT_REMOTE=1 MTN_REX_COORDINATOR_RUN=coord-1 cli launch "$work/worker.json" >"$work/worker-launch.json"
jq -e '.windowName=="go-builder-task1-attempt1" and .rexSessionId=="session:parent" and .dispatchEventId=="dispatch/1"' "$work/worker-launch.json" >/dev/null
jq -s -e '[.[] | select(index("window"))] | last | index("session:parent")!=null and index("--focus=false")!=null and index("go-builder-task1-attempt1")!=null' "$work/rex.jsonl" >/dev/null
# Worker role is a leaf and never inherits the publication marker.
bash "$scripts/mtn-rex" agent "$root/.mtn-tmp/rex/build-1" >/dev/null
cli result tasks/demo.md build-1 | jq -e '.outcome=="ready-for-review"' >/dev/null
cli inspect tasks/demo.md build-1 | jq -e '.running==true' >/dev/null
jq -s -e 'last|index("--print")!=null and index("--session-id")!=null' "$work/pi.jsonl" >/dev/null
# Dependency-ready work in another phase still belongs to this one coordinator.
for kind in phase task; do
	jq -n --arg kind "$kind" '{title:"Other phase",path:($kind+"s/other.md"),description:"REQ-002",fields:{workflowKind:$kind,workflowOrder:2,workflowLanguage:"go"}}' | mtn --path "$root/.tasks" agent create --input - --json >/dev/null
done
printf '%s\n' '{"target":"phases/other.md"}' | mtn --path "$root/.tasks" agent project-add tasks/other.md --input - --json >/dev/null
other_hash="$(workflow fingerprint tasks/other.md)"
jq --arg hash "$other_hash" '.recordRef="tasks/other.md" | .specHash=$hash | .eventId="dispatch/other" | .runId="build-other"' "$work/dispatch.json" >"$work/dispatch-other.json"
workflow publish "$work/dispatch-other.json" >/dev/null
jq --arg hash "$other_hash" '.recordRef="tasks/other.md" | .phaseRef="phases/other.md" | .coordinatorPhaseRef="phases/demo.md" | .specHash=$hash | .dispatchEventId="dispatch/other" | .runId="build-other"' "$work/worker.json" >"$work/other.json"
MTN_REX_COORDINATOR_RUN=coord-1 cli launch "$work/other.json" | jq -e '.rexSessionId=="session:parent" and .windowName=="go-builder-task2-attempt1"' >/dev/null
# The next coordinator requires an explicit release after confirmed process exit.
jq -n --arg hash "$phase_hash" '{schemaVersion:1,eventId:"coord-1/release",kind:"release",recordRef:"phases/demo.md",specHash:$hash,attempt:1,dispatchEventId:"coord-1/runtime/reserved",outcome:"finished",processEvidence:"fixture child exited"}' >"$work/release.json"
workflow publish "$work/release.json" >/dev/null
# Publication failure must never open the startup gate. Reserved attempts cannot relaunch.
jq '.runId="coord-failed"' "$work/coordinator.json" >"$work/fail.json"
if REJECT_LAUNCH=1 cli launch "$work/fail.json" >/dev/null 2>&1; then exit 1; fi
[[ ! -e "$root/.mtn-tmp/rex/coord-failed/ready" ]]
if cli launch "$work/fail.json" >/dev/null 2>&1; then exit 1; fi
# Reject traversal and stale hashes before creating Rex resources.
for change in '.runId="../escape"' '.specHash="stale" | .runId="stale"'; do
	jq "$change" "$work/coordinator.json" >"$work/bad.json"
	if cli launch "$work/bad.json" >/dev/null 2>&1; then exit 1; fi
done
lib="$MTN_REX_LIB"
jq -e -L "$lib" 'include "workflow"; valid_event' "$work/launched.json" >/dev/null
if jq 'del(.rexBlockId)' "$work/launched.json" | jq -e -L "$lib" 'include "workflow"; valid_event' >/dev/null; then exit 1; fi
workflow status tasks/demo.md | jq -e '.state=="building"' >/dev/null
printf 'Rex/Pi launch and mtn identity checks passed\n'

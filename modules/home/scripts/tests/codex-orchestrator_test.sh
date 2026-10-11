#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$script_dir/../codex-orchestrator"
work="$(mktemp -d)"
# Keep test artifacts outside the checkout for inspection on failure.
printf 'Test artifacts: %s\n' "$work"
mkdir -p "$work/bin" "$work/project with spaces/subdir"
for command in gh herdr codex orchestratord; do
	ln -s "$script_dir/fixtures/codex-orchestrator-command" "$work/bin/$command"
done
export PATH="$work/bin:$PATH" HERDR_ENV=1 MOCK_LOG="$work/commands.log"
git -C "$work/project with spaces" init -q
git -C "$work/project with spaces" remote add origin git@github.com:owner/project.git
cd "$work/project with spaces/subdir"

run() {
	: >"$MOCK_LOG"
	bash "$script" >"$work/output" 2>&1
}
assert_log() { grep -Fq -- "$1" "$MOCK_LOG"; }
assert_no_daemon() {
	if grep -q '^orchestratord daemon' "$MOCK_LOG"; then
		printf 'daemon must not start on failure\n' >&2
		exit 1
	fi
}

run
config="$work/project with spaces/.orchestrator/pipeline.yaml"
[[ "$(yq '.policies.dry_run' "$config")" == true ]]
[[ "$(yq '[.roles[].launch[0]] | unique | .[]' "$config")" == codex ]]
[[ "$(yq '.roles.implementer.launch | join(" ")' "$config")" == 'codex -a never --sandbox workspace-write -c sandbox_workspace_write.network_access=true' ]]
assert_log 'orchestratord init'
assert_log 'gh label create agent-ready'
assert_log 'orchestratord doctor'
assert_log 'orchestratord daemon'
assert_log '--base develop'
assert_log 'project\ with\ spaces'
runtime_config="$work/project with spaces/.orchestrator/pipeline.runtime.yaml"
task_dir="$work/project with spaces/.orchestrator/tasks"
TASK_DIR="$task_dir" yq -e '[.roles[].launch] | all_c(.[-2] == "--add-dir" and .[-1] == strenv(TASK_DIR))' "$runtime_config" >/dev/null
assert_log 'pipeline.runtime.yaml'
assert_log '--task-dir'
grep -Fxq '/.orchestrator/' "$work/project with spaces/.git/info/exclude"

printf '# user customization\n' >>"$config"
yq -i '.roles.reviewer.launch += ["--model", "test-model"]' "$config"
export LABEL_EXISTS=true
run
if grep -q '^orchestratord init\|^gh label create' "$MOCK_LOG"; then
	printf 'second run must reuse configuration and label\n' >&2
	exit 1
fi
grep -Fxq '# user customization' "$config"
# Runtime sandbox access must not rewrite the user's pipeline.
[[ "$(yq '.roles.implementer.launch | join(" ")' "$config")" == 'codex -a never --sandbox workspace-write -c sandbox_workspace_write.network_access=true' ]]
TASK_DIR="$task_dir" yq -e '[.roles[].launch] | all_c(.[-2] == "--add-dir" and .[-1] == strenv(TASK_DIR))' "$runtime_config" >/dev/null

[[ "$(yq '.roles.reviewer.launch[-2:] | join(" ")' "$config")" == '--model test-model' ]]
[[ "$(yq '.roles.reviewer.launch[-4:-2] | join(" ")' "$runtime_config")" == '--model test-model' ]]
[[ "$(yq '.roles.triager.launch | length' "$runtime_config")" == 9 ]]

export DOCTOR_STATUS=1
if run; then
	printf 'expected failed doctor to stop wrapper\n' >&2
	exit 1
fi
assert_no_daemon
export DOCTOR_STATUS=0 AUTH_STATUS=1
if run; then
	printf 'expected failed authentication to stop wrapper\n' >&2
	exit 1
fi
assert_no_daemon
export AUTH_STATUS=0 HERDR_ENV=0
if run; then
	printf 'expected wrapper to require HerdR\n' >&2
	exit 1
fi
assert_no_daemon
export HERDR_ENV=1

yq -i '.sources[0].repo = "other/project"' "$config"
if run; then
	printf 'expected mismatched repository to be rejected\n' >&2
	exit 1
fi
assert_no_daemon

yq -i '.sources[0].repo = "owner/project" | .roles.reviewer.launch = ["claude"]' "$config"
if run; then
	printf 'expected non-Codex role to be rejected\n' >&2
	exit 1
fi
assert_no_daemon

cd "$work"
if run; then
	printf 'expected non-repository to be rejected\n' >&2
	exit 1
fi
assert_no_daemon
bash "$script" --help >"$work/help"
grep -q 'codex-orchestrator' "$work/help"
printf 'codex-orchestrator tests passed\n'

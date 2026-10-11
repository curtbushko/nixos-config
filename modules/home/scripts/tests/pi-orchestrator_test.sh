#!/usr/bin/env bash
set -euo pipefail
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
script="$script_dir/../pi-orchestrator"
work="$(mktemp -d)"
printf 'Test artifacts: %s\n' "$work"
mkdir -p "$work/bin" "$work/project with spaces/subdir"
for command in gh herdr pi orchestratord; do
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
[[ "$(yq '.policies.execution.sandbox' "$config")" == false ]]
yq -e '[.roles[].launch] | all_c(length == 2 and .[0] == "pi" and .[1] == "--no-approve")' "$config" >/dev/null
assert_log 'pi --version'
assert_log 'orchestratord init'
assert_log 'gh label create agent-ready'
assert_log 'orchestratord doctor'
assert_log 'orchestratord daemon'
assert_log '--base develop'
assert_log '--task-dir'
assert_log 'project\ with\ spaces'
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
[[ "$(yq '.roles.reviewer.launch[-2:] | join(" ")' "$config")" == '--model test-model' ]]

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
yq -i '.sources[0].repo = "owner/project" | .roles.reviewer.launch = ["codex"]' "$config"
if run; then
	printf 'expected non-Pi role to be rejected\n' >&2
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
grep -q 'pi-orchestrator' "$work/help"
printf 'pi-orchestrator tests passed\n'

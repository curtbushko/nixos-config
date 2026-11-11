#!/usr/bin/env bash
set -euo pipefail

for tool in bash jq git mkdir mktemp mv find wc dirname; do command -v "$tool" >/dev/null || exit 1; done
scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo="$(git -C "$scripts" rev-parse --show-toplevel)"
work="$(mktemp -d "${TMPDIR:-/tmp}/skill-eval-runner.XXXXXX")"
trap 'mkdir -p "$repo/.trash/skill-eval-tests"; mv "$work" "$repo/.trash/skill-eval-tests/"' EXIT
mkdir -p "$work/bin"
printf '%s\n' '#!/usr/bin/env bash' 'set -euo pipefail' 'while IFS= read -r line; do :; done' 'printf "fixture response\n"' >"$work/bin/pi"
chmod +x "$work/bin/pi"
SCENARIO='' PATH="$work/bin:$PATH" bash "$scripts/run_evals.sh" fixture/model "$work/results" 1 >"$work/run.out"
expected="$(jq '[.[] | if .compare then 3 else 1 end] | add' "$scripts/scenarios.json")"
actual="$(find "$work/results" -name '*.1.txt' -type f | wc -l)"
((actual == expected)) || {
	printf 'Skipped scenarios: expected %s, got %s\n' "$expected" "$actual" >&2
	exit 1
}
if PATH="$work/bin:$PATH" bash "$scripts/run_evals.sh" fixture/model "$work/results" >"$work/repeat.out" 2>&1; then
	printf 'Runner overwrote existing results\n' >&2
	exit 1
fi
printf 'Evaluation runner iteration and preservation checks passed\n'

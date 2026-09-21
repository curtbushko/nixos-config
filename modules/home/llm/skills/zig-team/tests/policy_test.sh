#!/usr/bin/env bash

set -euo pipefail

if ! command -v grep >/dev/null 2>&1; then
	printf 'grep is required\n' >&2
	exit 1
fi

SCRIPT_DIR="$(cd "${BASH_SOURCE[0]%/*}" && pwd)"
readonly SCRIPT_DIR
SKILL_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SKILL_DIR
readonly ORCHESTRATION="${SKILL_DIR}/references/orchestration.md"
readonly BUILDER_CONTEXT="${SKILL_DIR}/references/builder-context.md"

assert_contains() {
	local file="$1"
	local expected="$2"

	if ! grep -Fq -- "$expected" "$file"; then
		printf 'missing policy in %s: %s\n' "$file" "$expected" >&2
		return 1
	fi
}

assert_not_contains() {
	local file="$1"
	local rejected="$2"

	if grep -Fq -- "$rejected" "$file"; then
		printf 'obsolete policy remains in %s: %s\n' "$file" "$rejected" >&2
		return 1
	fi
}

main() {
	assert_contains "$ORCHESTRATION" 'Run the narrowest relevant test first during RED, GREEN, and each fix cycle.'
	assert_contains "$ORCHESTRATION" 'Run the full test suite once after the implementation is ready for review.'
	assert_contains "$ORCHESTRATION" 'Re-run the full test suite after a fix only when the fix has broad impact'
	assert_contains "$ORCHESTRATION" 'Reserve exhaustive project-specific, packaged-runtime, and full-system gates for the final task of the phase.'
	assert_contains "$ORCHESTRATION" 'ZIG_TEAM_TEST_JOBS'
	assert_contains "$ORCHESTRATION" 'PROGRESS_INTERVAL = 2 minutes'
	assert_contains "$BUILDER_CONTEXT" 'Focused development loop'
	assert_contains "$BUILDER_CONTEXT" 'ZIG_TEAM_TEST_JOBS'
	assert_contains "$BUILDER_CONTEXT" 'Final phase task only'
	assert_not_contains "$ORCHESTRATION" 'zig build test -j1  # MUST pass (serial to avoid race conditions)'
	assert_not_contains "$BUILDER_CONTEXT" 'zig build test -j1     # limit parallelism to avoid OOM'
}

main "$@"

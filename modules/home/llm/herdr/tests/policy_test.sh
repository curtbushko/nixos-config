#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
flake="$repo_root/flake.nix"
module="$repo_root/modules/home/llm/herdr/default.nix"
pi_module="$repo_root/modules/home/llm/pi/default.nix"

assert_contains() {
	local file="$1"
	local pattern="$2"

	if ! grep -Fq -- "$pattern" "$file"; then
		printf 'expected %s to contain: %s\n' "$file" "$pattern" >&2
		return 1
	fi
}

assert_contains "$flake" 'github:herdrdev/herdr/v0.9.1'
assert_contains "$flake" 'github:aorumbayev/herdr-workflows/v0.15.1'
assert_contains "$flake" 'github:mrcndz/herdr-routines/cd504512d2f1976d39668fbdc0fe9b86cf3eff85'
assert_contains "$pi_module" '".pi/agent/skills".source = ../skills;'
assert_contains "$pi_module" '@andrewjacop/pi-herdr'
assert_contains "$module" 'for integration in pi claude codex copilot; do'
assert_contains "$module" "integration install \"\$integration\""
for workflow in preflight verify-fast verify-full review implement-review; do
	if [[ ! -f "$repo_root/modules/home/llm/herdr/workflows/${workflow}.yaml" ]]; then
		printf 'missing global workflow: %s\n' "$workflow" >&2
		exit 1
	fi
done
assert_contains "$repo_root/modules/home/llm/herdr/routines.toml" 'enabled = false'

if grep -Rq --exclude='policy_test.sh' --exclude='README.md' 'herdr update\|hwf update' "$repo_root/modules/home/llm/herdr"; then
	printf 'Nix-managed HerdR components must not use mutable self-updaters\n' >&2
	exit 1
fi

printf 'HerdR policy checks passed\n'

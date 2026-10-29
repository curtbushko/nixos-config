#!/usr/bin/env bash
set -euo pipefail

for command in git dirname jq; do
	command -v "$command" >/dev/null || exit 1
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$repo_root"

# Keep retired integration names out of our configuration and shared skills.
# The lock file can retain dependencies owned by pinned external flakes.
retired='her''dr'
jq -e --arg name "$retired" \
	'[.nodes.root.inputs | keys[] | select(ascii_downcase | contains($name))] | length == 0' \
	flake.lock >/dev/null
if git grep -nIi "$retired" -- . ':!secrets/**' ':!flake.lock'; then
	printf 'Retired integration references remain\n' >&2
	exit 1
else
	status=$?
	[[ "$status" -eq 1 ]] || exit "$status"
fi
printf 'Integration cleanup checks passed\n'

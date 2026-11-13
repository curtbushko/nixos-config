#!/usr/bin/env bash
set -euo pipefail

for command in dirname awk grep bash; do
	command -v "$command" >/dev/null || exit 1
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
host_command="$(awk '/^  HOST:/{getline; sub(/^    sh: /, ""); print; exit}' "$repo_root/Taskfile.yml")"
user_command="$(awk '/^  NIXUSER:/{copy=1; next} copy && /^tasks:/{exit} copy && !/sh: \|/{sub(/^      /, ""); print}' "$repo_root/Taskfile.yml")"

# Simulate SteamOS without hostname, including fully qualified host names.
hostname() { return 127; }
uname() { printf '%s\n' "$test_host"; }
export -f hostname uname
for test_host in steamdeck steamdeck.local gamingrig.local m4-pro; do
	export test_host
	expected="${test_host%%.*}"
	actual="$(bash -eu -c "$host_command")"
	[[ "$actual" == "$expected" ]] || {
		printf 'Host detection failed for %s\n' "$test_host" >&2
		exit 1
	}
	rendered="${user_command//\{\{.HOST\}\}/$actual}"
	if [[ "$expected" == steamdeck ]]; then
		[[ "$(NIXUSER=someone bash -eu -c "$rendered")" == deck ]]
	else
		[[ "$(NIXUSER=someone bash -eu -c "$rendered")" == someone ]]
	fi
done
if grep -Eq 'hostname -s' "$repo_root/flake.nix"; then
	printf 'Dev-shell banner still requires hostname\n' >&2
	exit 1
fi
banner_command="$(grep 'Current host:' "$repo_root/flake.nix")"
banner_command="${banner_command//\'\'/}"
export test_host=steamdeck.local
[[ "$(BOLD='' NC='' bash -eu -c "$banner_command")" == 'Current host: steamdeck' ]]
printf 'Hostname-free host routing checks passed\n'

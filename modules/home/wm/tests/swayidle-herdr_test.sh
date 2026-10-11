#!/usr/bin/env bash
set -euo pipefail

for command in awk sed bash grep wc xargs; do
	command -v "$command" >/dev/null || exit 1
done

module="${BASH_SOURCE[0]%/*}/../swayidle.nix"
# Exercise the actual assignment, replacing Nix store command paths with PATH.
assignment="$(awk '/^[[:space:]]*HERDR_RUNNING=/{print; exit}' "$module" | sed -E 's@\$\{pkgs\.[^}]+\}/bin/@@g')"
[[ -n "$assignment" ]]

pgrep() {
	[[ "$2" == herdr ]] || return 2
	[[ "$1" == -ax ]] || return 2
	[[ -n "$HERDR_PROCESSES" ]] || return 1
	printf '%s\n' "$HERDR_PROCESSES"
}
export -f pgrep

check() {
	local name="$1" expected="$2" actual
	export HERDR_PROCESSES="$3"
	actual="$(bash -c "$assignment; printf '%s' \"\$HERDR_RUNNING\"")"
	if [[ "$actual" != "$expected" ]]; then
		printf 'FAIL: %s: expected %s, got %s\n' "$name" "$expected" "$actual" >&2
		return 1
	fi
	printf 'PASS: %s\n' "$name"
}

check 'server alone allows suspend' 0 '101 /nix/store/example-herdr/bin/herdr server'
check 'attached TUI prevents suspend' 1 '102 herdr'
check 'store-path client prevents suspend' 1 '102 /nix/store/example-herdr/bin/herdr'
check 'client with options prevents suspend' 1 '102 herdr --session work'
check 'server and TUI count only the client' 1 $'101 /nix/store/example-herdr/bin/herdr server\n102 herdr'
check 'no HerdR allows suspend' 0 ''

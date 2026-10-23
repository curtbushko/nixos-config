#!/usr/bin/env bash
set -euo pipefail

for command in awk sed bash grep wc xargs; do
	command -v "$command" >/dev/null || exit 1
done

module="${BASH_SOURCE[0]%/*}/../swayidle.nix"
# Exercise the actual assignment, replacing Nix store command paths with PATH.
assignment="$(awk '/^[[:space:]]*REX_RUNNING=/{print; exit}' "$module" | sed -E 's@\$\{pkgs\.[^}]+\}/bin/@@g')"
[[ -n "$assignment" ]] || {
	printf 'FAIL: missing Rex detection\n' >&2
	exit 1
}
grep -Fq "&& \$REX_RUNNING -eq 0" "$module"
grep -Fq "rex running: \$REX_RUNNING" "$module"

pgrep() {
	[[ "$1" == -ax && "$2" == rex ]] || return 2
	[[ -n "$REX_PROCESSES" ]] || return 1
	printf '%s\n' "$REX_PROCESSES"
}
export -f pgrep

check() {
	local name="$1" expected="$2" actual
	export REX_PROCESSES="$3"
	actual="$(bash -c "$assignment; printf '%s' \"\$REX_RUNNING\"")"
	if [[ "$actual" != "$expected" ]]; then
		printf 'FAIL: %s: expected %s, got %s\n' "$name" "$expected" "$actual" >&2
		return 1
	fi
	printf 'PASS: %s\n' "$name"
}

check 'no Rex allows suspend' 0 ''
check 'login daemon alone allows suspend' 0 '101 /nix/store/example-rex/bin/rex login-server --listen unix:///run/rex/login-server.sock'
check 'multiplexer server alone allows suspend' 0 '102 rex server run --exit-empty'
check 'remote login session prevents suspend' 1 '103 /nix/store/example-rex/bin/rex login-server session --account user --remote-addr 100.64.0.1 -- server run --exit-empty'
check 'PATH login session prevents suspend' 1 '103 rex login-server session --account user'
check 'multiple sessions prevent suspend' 2 $'103 rex login-server session --account user\n104 rex login-server session --account other'
check 'daemon options do not mimic a session' 0 '101 rex login-server --runtime-root session'
check 'unrelated Rex command allows suspend' 0 '105 rex run echo login-server session'

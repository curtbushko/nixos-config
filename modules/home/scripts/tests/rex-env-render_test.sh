#!/usr/bin/env bash
set -euo pipefail
command -v jq >/dev/null
script="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/rex-env-render"
work="$(mktemp -d)"
printf '%s\n' 'export OTHER_SECRET=never-copy-this' 'export TS_USER=test-user@github' 'export REX_PACKAGE_TOKEN=test-token' >"$work/env"
bash "$script" accounts "$work/env" "$work/accounts" >"$work/log" 2>&1
jq -e '.accounts.curtbushko.principals == ["tailscale:test-user@github", "anonymous"] and .defaults["tailscale:test-user@github"] == "curtbushko"' "$work/accounts" >/dev/null
bash "$script" netrc "$work/env" "$work/netrc" >>"$work/log" 2>&1
grep -qx 'machine pkgs.superlogical.com login rex password test-token' "$work/netrc"
if grep -q 'never-copy-this' "$work/accounts" "$work/netrc" "$work/log"; then
	exit 1
fi
[[ "$(stat -c %a "$work/accounts")" == 600 ]]
[[ "$(stat -c %a "$work/netrc")" == 600 ]]
for bad in 'test-user.github' '"unterminated' "\$(touch /tmp/rex-must-not-execute)"; do
	printf 'export TS_USER=%s\n' "$bad" >"$work/bad"
	if bash "$script" accounts "$work/bad" "$work/rejected" >"$work/error" 2>&1; then
		exit 1
	fi
	if grep -Fq "$bad" "$work/error"; then
		exit 1
	fi
done
printf '%s\n' 'export TS_USER=one@github' 'export TS_USER=two@github' >"$work/duplicate"
if bash "$script" accounts "$work/duplicate" "$work/rejected" >"$work/error" 2>&1; then
	exit 1
fi
printf '%s\n' 'rex-env-render tests passed'

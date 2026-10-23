#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
# shellcheck source=modules/home/scripts/omniwm-permissions
source "$root/scripts/omniwm-permissions"

sqlite3() {
	case "$scenario" in
	allowed) printf '2\n' ;;
	denied) printf '0\n' ;;
	missing) : ;;
	unreadable) return 1 ;;
	esac
}
for scenario in allowed denied missing unreadable; do
	case "$scenario" in
	allowed) expected=allowed ;;
	denied | missing) expected='needs approval' ;;
	unreadable) expected='unable to verify' ;;
	esac
	actual="$(permission_status '/nix/store/test-skhd/bin/skhd')"
	[[ "$actual" == "$expected" ]] || {
		printf 'FAIL: %s: %s\n' "$scenario" "$actual" >&2
		exit 1
	}
done
scenario=allowed
output="$(report_permissions '/nix/store/current-skhd/bin/skhd')"
[[ "$output" == *'OmniWM Accessibility: allowed'* ]]
[[ "$output" == *'skhd Accessibility: allowed'* ]]
[[ "$output" == *'/nix/store/current-skhd/bin/skhd'* ]]
# A failed GUI command must never fail the install.
osascript() { return 1; }
show_dialog 'Test dialog failure'
# Approved installs do not need a dialog.
[[ "$(main --notify '/nix/store/current-skhd/bin/skhd')" == "$output" ]]
printf 'Permission check tests passed\n'

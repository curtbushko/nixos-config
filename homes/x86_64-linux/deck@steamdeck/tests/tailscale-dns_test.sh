#!/usr/bin/env bash
set -euo pipefail

for command in dirname nix-instantiate jq mktemp cp ln readlink grep; do
	command -v "$command" >/dev/null || exit 1
done
module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
activation="$(nix-instantiate --eval --strict --json --expr "
  (import (builtins.toPath \"$module_dir/tailscale.nix\") {
    pkgs.tailscale = \"/tailscale\";
    inputs.home-manager.lib.hm.dag.entryAfter = after: data: data;
  }).home.activation.configureTailscaleDns
" | jq -r .)"
fixture="$(mktemp -d)"
# Keep fixtures outside the repository; no live system paths are modified.
export fixture
activation="${activation//\/etc\/resolv.conf/$fixture/resolv.conf}"
activation="${activation//\/run\/systemd\/resolve\/stub-resolv.conf/$fixture/stub-resolv.conf}"
activation="${activation//\/usr\/bin\/sudo/sudo}"
activation="${activation//\/usr\/bin\/systemctl/systemctl}"

sudo() { "$@"; }
systemctl() {
	printf '%s\n' "$*" >>"$fixture/systemctl.log"
	if [[ "$1" == is-active ]]; then
		[[ "${resolved_active:-yes}" == yes ]]
	fi
}
export -f sudo systemctl
export DRY_RUN_CMD=''
printf 'nameserver 192.0.2.1\n' >"$fixture/resolv.conf"
printf 'nameserver 127.0.0.53\n' >"$fixture/stub-resolv.conf"

# Dry runs must not change files or restart services.
DRY_RUN_CMD='echo' bash -eu -c "$activation"
[[ ! -L "$fixture/resolv.conf" ]]
[[ ! -e "$fixture/resolv.conf.before-tailscale" ]]
if grep -q '^restart ' "$fixture/systemctl.log"; then
	printf 'Dry run restarted Tailscale\n' >&2
	exit 1
fi

# An inactive resolver must not replace a working resolv.conf.
if resolved_active=no bash -eu -c "$activation"; then
	printf 'Inactive resolved should reject DNS changes\n' >&2
	exit 1
fi
[[ ! -L "$fixture/resolv.conf" ]]

# A missing stub must likewise leave the existing DNS configuration intact.
mv "$fixture/stub-resolv.conf" "$fixture/stub-saved"
if bash -eu -c "$activation"; then
	printf 'Missing DNS stub should reject DNS changes\n' >&2
	exit 1
fi
[[ ! -L "$fixture/resolv.conf" ]]
mv "$fixture/stub-saved" "$fixture/stub-resolv.conf"

bash -eu -c "$activation"
[[ "$(readlink "$fixture/resolv.conf")" == "$fixture/stub-resolv.conf" ]]
grep -q '192.0.2.1' "$fixture/resolv.conf.before-tailscale"
[[ "$(grep -c '^restart tailscaled.service$' "$fixture/systemctl.log")" == 1 ]]

# Repeated activation leaves the original backup and running service alone.
bash -eu -c "$activation"
grep -q '192.0.2.1' "$fixture/resolv.conf.before-tailscale"
[[ "$(grep -c '^restart tailscaled.service$' "$fixture/systemctl.log")" == 1 ]]
printf 'Steam Deck DNS activation checks passed (fixtures: %s)\n' "$fixture"

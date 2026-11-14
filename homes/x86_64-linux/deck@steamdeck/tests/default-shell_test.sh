#!/usr/bin/env bash
set -euo pipefail

for command in dirname nix-instantiate jq mktemp mkdir ln bash grep mv; do
	command -v "$command" >/dev/null || exit 1
done
module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
export fixture
mkdir -p "$fixture/profile/bin"
ln -s "$(command -v bash)" "$fixture/profile/bin/zsh"
printf '/bin/bash\n' >"$fixture/shells"
printf '/bin/bash\n' >"$fixture/current-shell"
activation="$(nix-instantiate --eval --strict --json --expr "
  (import (builtins.toPath \"$module_dir/shell.nix\") {
    config.home = { profileDirectory = \"$fixture/profile\"; username = \"deck\"; };
    inputs.home-manager.lib.hm.dag.entryAfter = after: data: data;
  }).home.activation.setSteamDeckShell
" | jq -r .)"
activation="${activation//\/etc\/shells/$fixture/shells}"
activation="${activation//\/usr\/bin\/sudo/sudo}"
activation="${activation//\/usr\/bin\/getent/getent}"
getent() { printf 'deck:x:1000:1000:Deck:/home/deck:%s\n' "$(<"$fixture/current-shell")"; }
sudo() {
	printf '%s\n' "$*" >>"$fixture/sudo.log"
	if [[ "$1" == /usr/bin/chsh ]]; then
		[[ "$2" == -s && "$4" == deck ]]
		printf '%s\n' "$3" >"$fixture/current-shell"
	else
		"$@"
	fi
}
export -f sudo getent
export DRY_RUN_CMD=''

DRY_RUN_CMD='echo' bash -eu -c "$activation"
[[ "$(<"$fixture/current-shell")" == /bin/bash ]]
[[ "$(<"$fixture/shells")" == /bin/bash ]]
[[ ! -e "$fixture/sudo.log" ]]

bash -eu -c "$activation"
[[ "$(<"$fixture/current-shell")" == "$fixture/profile/bin/zsh" ]]
[[ "$(grep -Fxc "$fixture/profile/bin/zsh" "$fixture/shells")" == 1 ]]
[[ "$(grep -c /usr/bin/chsh "$fixture/sudo.log")" == 1 ]]
bash -eu -c "$activation"
[[ "$(grep -Fxc "$fixture/profile/bin/zsh" "$fixture/shells")" == 1 ]]
[[ "$(grep -c /usr/bin/chsh "$fixture/sudo.log")" == 1 ]]
# A dry run can precede package installation; real activation must reject a missing shell.
mv "$fixture/profile/bin/zsh" "$fixture/zsh-saved"
DRY_RUN_CMD='echo' bash -eu -c "$activation"
if bash -eu -c "$activation"; then
	printf 'Missing Zsh executable should reject shell changes\n' >&2
	exit 1
fi
printf 'Steam Deck default-shell checks passed (fixtures: %s)\n' "$fixture"

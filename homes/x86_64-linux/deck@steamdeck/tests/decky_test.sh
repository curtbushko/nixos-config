#!/usr/bin/env bash
set -euo pipefail

for command in dirname nix-instantiate jq mktemp mkdir cp cmp grep bash; do
	command -v "$command" >/dev/null || exit 1
done
module_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
export fixture
mkdir -p "$fixture/assets/Unifideck" "$fixture/etc/systemd/system" "$fixture/home/.steam/steam"
printf 'loader\n' >"$fixture/assets/PluginLoader"
printf '{"name":"Unifideck"}\n' >"$fixture/assets/Unifideck/plugin.json"
printf 'backend\n' >"$fixture/assets/Unifideck/main.py"
activation="$(nix-instantiate --read-write-mode --eval --strict --json --expr "
  (import (builtins.toPath \"$module_dir/decky.nix\") {
    config.home = { homeDirectory = \"$fixture/home\"; username = \"deck\"; };
    inputs.home-manager.lib.hm.dag.entryAfter = after: data: data;
    pkgs = {
      fetchurl = args: \"$fixture/assets/PluginLoader\";
      runCommand = name: env: script: \"$fixture/assets/Unifideck\";
      writeText = name: text: builtins.toFile name text;
    };
  }).home.activation.installDecky
" | jq -r .)"
activation="${activation//\/etc\/systemd\/system/$fixture/etc/systemd/system}"
activation="${activation//\/usr\/bin\/sudo/sudo}"
sudo() {
	printf '%s\n' "$*" >>"$fixture/sudo.log"
	case "$1" in
	systemctl) return 0 ;;
	chown) return 0 ;;
	install)
		if [[ "${fail_install:-no}" == yes ]]; then
			return 1
		fi
		"$@"
		;;
	*) "$@" ;;
	esac
}
export -f sudo
export DRY_RUN_CMD=''

# Dry runs must perform no privileged changes.
DRY_RUN_CMD='echo' bash -eu -c "$activation"
[[ ! -e "$fixture/sudo.log" ]]
[[ ! -e "$fixture/home/homebrew" ]]

# First install enables the loader and deploys writable plugin files.
bash -eu -c "$activation"
cmp "$fixture/assets/PluginLoader" "$fixture/home/homebrew/services/PluginLoader"
[[ -x "$fixture/home/homebrew/services/PluginLoader" ]]
[[ -f "$fixture/home/.steam/steam/.cef-enable-remote-debugging" ]]
[[ -f "$fixture/home/homebrew/plugins/Unifideck/main.py" ]]
[[ ! -L "$fixture/home/homebrew/plugins/Unifideck" ]]
grep -q 'systemctl enable --now plugin_loader.service' "$fixture/sudo.log"
[[ "$(grep -c 'systemctl restart plugin_loader.service' "$fixture/sudo.log")" == 1 ]]

# Runtime state and unrelated plugins must survive repeated activation.
mkdir -p "$fixture/home/homebrew/plugins/OtherPlugin" "$fixture/home/homebrew/settings/Unifideck"
printf 'settings\n' >"$fixture/home/homebrew/settings/Unifideck/state"
bash -eu -c "$activation"
[[ "$(grep -c 'systemctl restart plugin_loader.service' "$fixture/sudo.log")" == 1 ]]

# Replace an existing plugin safely, retaining its config and an archived copy.
printf '{"old":true}\n' >"$fixture/home/homebrew/plugins/Unifideck/plugin.json"
printf '{"setting":true}\n' >"$fixture/home/homebrew/plugins/Unifideck/config.json"
bash -eu -c "$activation"
cmp "$fixture/assets/Unifideck/plugin.json" "$fixture/home/homebrew/plugins/Unifideck/plugin.json"
grep -q 'setting' "$fixture/home/homebrew/plugins/Unifideck/config.json"
archives=("$fixture/home/homebrew/.trash/"*/Unifideck/plugin.json)
[[ ${#archives[@]} == 1 ]]
grep -q old "${archives[0]}"
[[ -d "$fixture/home/homebrew/plugins/OtherPlugin" ]]
grep -q settings "$fixture/home/homebrew/settings/Unifideck/state"
[[ "$(grep -c 'systemctl restart plugin_loader.service' "$fixture/sudo.log")" == 2 ]]
# A failed loader update preserves the old binary and starts its stopped service.
printf 'old loader\n' >"$fixture/home/homebrew/services/PluginLoader"
if fail_install=yes bash -eu -c "$activation"; then
	printf 'Failed install should fail activation\n' >&2
	exit 1
fi
grep -q 'old loader' "$fixture/home/homebrew/services/PluginLoader"
grep -q 'systemctl start plugin_loader.service' "$fixture/sudo.log"
printf 'Decky installation checks passed (fixtures: %s)\n' "$fixture"

#!/usr/bin/env bash
set -euo pipefail

for command in dirname awk grep; do
	command -v "$command" >/dev/null || exit 1
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
switch_commands="$(awk '/^  switch:/{copy=1} /^  dry-build:/{copy=0} copy' "$repo_root/Taskfile.yml")"

# Build with the caller's credentials, then register and activate that exact result.
grep -Fq 'build ".#darwinConfigurations.{{.HOST}}.system" --show-trace --impure &&' <<<"$switch_commands"
grep -Fq "sudo nix-env -p /nix/var/nix/profiles/system --set \"\$(readlink result)\" &&" <<<"$switch_commands"
grep -Fq 'sudo ./result/sw/bin/darwin-rebuild activate' <<<"$switch_commands"
if grep -Fq 'sudo ./result/sw/bin/darwin-rebuild switch --flake' <<<"$switch_commands"; then
	printf 'Darwin switch must not reevaluate the flake as root\n' >&2
	exit 1
fi
printf 'Darwin build-once activation checks passed\n'

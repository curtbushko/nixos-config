#!/usr/bin/env bash
set -euo pipefail

for command in dirname grep jq; do
	command -v "$command" >/dev/null || exit 1
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../.." && pwd)"
cd "$repo_root"

grep -Fq 'url = "github:curtbushko/mdbase-tasknotes";' flake.nix
for home in \
	'homes/aarch64-darwin/curtbushko@m4-pro/default.nix' \
	'homes/aarch64-darwin/curtbushko@curtbushko-K4W6XK6XND/default.nix' \
	'homes/x86_64-linux/curtbushko@gamingrig/default.nix'; do
	grep -Fq "inputs.mtn.packages.\${pkgs.stdenv.hostPlatform.system}.default" "$home"
done
jq -e '.dependencies | has("mdbase-tasknotes") | not' packages/tasknotes-tools/package.json >/dev/null
jq -e '.packages | has("node_modules/mdbase-tasknotes") | not' packages/tasknotes-tools/package-lock.json >/dev/null
if grep -Fq "\"\$out/bin/mtn\"" packages/tasknotes-tools/default.nix; then
	printf 'Bundled tools must not shadow the flake-provided mtn\n' >&2
	exit 1
fi
printf 'TaskNotes package source checks passed\n'

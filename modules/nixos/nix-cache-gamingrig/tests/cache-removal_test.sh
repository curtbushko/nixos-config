#!/usr/bin/env bash
set -euo pipefail

for command in dirname grep; do
	command -v "$command" >/dev/null || exit 1
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"

if grep -REn 'http://gamingrig:(5000|8501)' "$repo_root/systems" "$repo_root/modules/nixos" --include='*.nix'; then
	printf 'Gamingrig must not be configured as a binary cache\n' >&2
	exit 1
fi
if grep -q 'wake-gamingrig' "$repo_root/Taskfile.yml"; then
	printf 'Build tasks must not wake gamingrig for cache access\n' >&2
	exit 1
fi
if grep -Eq 'services\.(nix-serve|ncps)' "$repo_root/systems/x86_64-linux/gamingrig/default.nix"; then
	printf 'Gamingrig must not serve binary caches\n' >&2
	exit 1
fi
# Cache removal must not remove the existing remote builder or public caches.
module="$repo_root/modules/nixos/nix-cache-gamingrig/default.nix"
grep -Fq 'ssh://curtbushko@gamingrig' "$module"
grep -Fq '"https://cache.nixos.org"' "$module"
grep -Fq '"https://nix-community.cachix.org"' "$module"
printf 'Gamingrig cache removal checks passed\n'

#!/usr/bin/env bash
set -euo pipefail

repo="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
scratch="$(mktemp -d)"
trap 'mkdir -p "$repo/.trash"; mv "$scratch" "$repo/.trash/"' EXIT
script="$repo/modules/home/scripts/nix-cache-include"

printf '# Existing settings\nexperimental-features = external-builders' >"$scratch/custom.conf"
cp "$scratch/custom.conf" "$scratch/original"
bash "$script" "$scratch/custom.conf"
grep -Fxq 'experimental-features = external-builders' "$scratch/custom.conf"
grep -Fxq 'include nix.repo-caches.conf' "$scratch/custom.conf"
cp "$scratch/custom.conf" "$scratch/once"
bash "$script" "$scratch/custom.conf"
cmp "$scratch/once" "$scratch/custom.conf"

bash "$script" "$scratch/new.conf"
grep -Fxq 'include nix.repo-caches.conf' "$scratch/new.conf"

printf '  !include nix.repo-caches.conf # already configured\n' >"$scratch/optional.conf"
cp "$scratch/optional.conf" "$scratch/optional-original"
bash "$script" "$scratch/optional.conf"
cmp "$scratch/optional-original" "$scratch/optional.conf"

if bash "$script" "$scratch/missing/custom.conf"; then
	printf 'Expected a missing parent directory to fail\n' >&2
	exit 1
fi

printf 'Nix cache include tests passed\n'

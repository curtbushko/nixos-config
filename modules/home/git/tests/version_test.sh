#!/usr/bin/env bash
set -euo pipefail

for command in nix dirname; do
	command -v "$command" >/dev/null || exit 1
done
test_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nix --option eval-cache false eval --impure --json --file "$test_dir/version_test.nix"

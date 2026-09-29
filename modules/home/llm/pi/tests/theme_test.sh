#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
module="$repo_root/modules/home/llm/pi/default.nix"

if ! grep -Fq 'theme = "flair";' "$module"; then
	printf 'Pi must select the flair theme in settings.json\n' >&2
	exit 1
fi

if ! grep -Fq '".pi/agent/themes/flair.json".source = pkgs.writeText "pi-flair.json" (builtins.toJSON' "$module"; then
	printf 'Pi must install the flair theme as a single generated JSON file\n' >&2
	exit 1
fi

if grep -Fq '".pi/agent/themes/flair.json".text' "$module"; then
	printf 'Pi theme must not use a text option that concatenates duplicate definitions\n' >&2
	exit 1
fi

if grep -Fq '".pi/agent/theme.json"' "$module"; then
	printf 'Pi must not install its theme at the undiscovered root path\n' >&2
	exit 1
fi

printf 'Pi flair theme policy checks passed\n'

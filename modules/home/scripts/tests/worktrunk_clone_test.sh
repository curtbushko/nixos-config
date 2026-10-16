#!/usr/bin/env bash
set -euo pipefail

command -v nix >/dev/null
command -v git >/dev/null
scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
export WORKTRUNK_MODULE="$scripts/../tools/worktrunk/default.nix"
# Evaluate only the packaged clone script, without fetching the flake inputs.
nix eval --impure --raw --expr '
  let m = import (builtins.toPath (builtins.getEnv "WORKTRUNK_MODULE")) {
    config.ns.tools.enable = true;
    lib.mkIf = condition: value: if condition then value else {};
    pkgs.writeScriptBin = name: text: { inherit name text; };
  }; in (builtins.head m.config.home.packages).text
' >"$tmp/wt-clone"
git init -q -b main "$tmp/source"
git -C "$tmp/source" commit -q --allow-empty -m initial

index=0
for url in 'ssh://git@github.com/team/repo.git' 'ssh://git@github.com:2222/team/repo.git' 'ssh://github.com/team/repo.git' 'deploy@github.com:team/repo.git' 'git@github.com:team/repo.git' 'https://github.com/team/repo.git'; do
	index=$((index + 1))
	export HOME="$tmp/home-$index"
	# Route each URL to a local repository: no network or SSH credentials needed.
	export GIT_CONFIG_COUNT=1
	export GIT_CONFIG_KEY_0="url.file://$tmp/source.insteadOf"
	export GIT_CONFIG_VALUE_0="$url"
	WORKTRUNK_DIRECTIVE_CD_FILE='' bash "$tmp/wt-clone" "$url"
	target="$HOME/workspace/github.com/team/repo"
	[[ -d "$target/.bare" && -f "$target/main/.git" ]]
	[[ "$(git -C "$target/main" symbolic-ref --short HEAD)" == main ]]
done
printf 'PASS: worktrunk SSH clones (fixtures: %s)\n' "$tmp"

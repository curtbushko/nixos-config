#!/usr/bin/env bash
set -euo pipefail

scripts="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
# Keep test fixtures available for inspection; never touch the real workspace.
export HOME="$tmp/home"
export GIT_CONFIG_NOSYSTEM=1 GIT_CONFIG_GLOBAL=/dev/null
export GIT_AUTHOR_NAME=Test GIT_AUTHOR_EMAIL=test@example.invalid
export GIT_COMMITTER_NAME=Test GIT_COMMITTER_EMAIL=test@example.invalid
mkdir -p "$HOME/workspace" "$tmp/bin"
export PATH="$tmp/bin:$PATH"
export CLONE_LOG="$tmp/clones"
printf '' >"$CLONE_LOG"
cp "$scripts/tests/fixtures/workspace-tg" "$tmp/bin/tg"
chmod +x "$tmp/bin/tg"

repo() {
	local path="$HOME/workspace/$1"
	mkdir -p "$path"
	git init -q -b main "$path"
	git -C "$path" commit -q --allow-empty -m initial
	git -C "$path" remote add origin "git@github.com:$2.git"
}
fail() {
	printf 'FAIL: %s\nFixtures: %s\n' "$*" "$tmp" >&2
	exit 1
}

repo github.com/team/normal team/normal
repo github.com/curtbushko/nixos-config curtbushko/nixos-config
repo github.com/curtbushko/another-repo curtbushko/another-repo
repo github.com/team/blocked team/blocked
mkdir -p "$HOME/workspace/github.com/team/blocked.bak"
repo github.com/team/linked team/linked
git -C "$HOME/workspace/github.com/team/linked" worktree add -q -b feature "$tmp/linked-feature"
repo github.com/team/old.bak team/old
if bash "$scripts/workspace-to-worktrees" --dry-run; then
	fail 'dry run should report backup collision'
fi
[[ -d "$HOME/workspace/github.com/team/normal/.git" && ! -s "$CLONE_LOG" ]] || fail 'dry run changed files'
if bash "$scripts/workspace-to-worktrees"; then
	fail 'existing backup should report failure'
fi
[[ -d "$HOME/workspace/github.com/team/normal.bak/.git" ]] || fail 'original not backed up'
[[ ! -e "$HOME/workspace/github.com/team/normal" ]] || fail 'mock clone should not recreate repository'
[[ -d "$HOME/workspace/github.com/curtbushko/nixos-config/.git" ]] || fail 'ignored repo moved'
[[ -d "$HOME/workspace/github.com/curtbushko/another-repo/.git" ]] || fail 'owner repo moved'
[[ -d "$HOME/workspace/github.com/team/blocked/.git" ]] || fail 'backup collision moved repo'
[[ -d "$HOME/workspace/github.com/team/linked/.git" ]] || fail 'repo with linked worktrees moved'
[[ -d "$HOME/workspace/github.com/team/old.bak/.git" ]] || fail 'backup scanned'
[[ "$(<"$CLONE_LOG")" == 'clone git@github.com:team/normal.git' ]] || fail 'unexpected clone invocation'
repo github.com/team/fail team/fail
if bash "$scripts/workspace-to-worktrees"; then fail 'clone failure not reported'; fi
[[ -d "$HOME/workspace/github.com/team/fail.bak/.git" ]] || fail 'clone failure lost backup'
# tg is usually only an interactive alias: verify the wt command fallback.
mv "$tmp/bin/tg" "$tmp/bin/wt"
repo 'github.com/team/space repo' 'team/space repo'
if bash "$scripts/workspace-to-worktrees"; then fail 'backup collision should still report failure'; fi
[[ -d "$HOME/workspace/github.com/team/space repo.bak/.git" ]] || fail 'wt fallback or spaces failed'
grep -Fx 'clone git@github.com:team/space repo.git' "$CLONE_LOG" >/dev/null || fail 'wt fallback not invoked'

# Accept SSH URI forms as well as scp-style origins, preserving the clone URL.
for spec in 'ssh://git@github.com/team/ssh-uri.git' 'ssh://git@github.com:2222/team/ssh-port.git' 'ssh://github.com/team/ssh-no-user.git' 'deploy@github.com:team/ssh-user.git'; do
	name="${spec##*/}"
	name="${name%.git}"
	repo "github.com/team/$name" "team/$name"
	git -C "$HOME/workspace/github.com/team/$name" remote set-url origin "$spec"
	if bash "$scripts/workspace-to-worktrees"; then fail 'backup collision should still report failure'; fi
	[[ -d "$HOME/workspace/github.com/team/$name.bak/.git" ]] || fail "SSH origin rejected: $spec"
	grep -Fx "clone $spec" "$CLONE_LOG" >/dev/null || fail 'SSH URL changed before clone'
done

# Use real local remotes to exercise fast-forward and divergence behavior.
git init -q --bare -b main "$tmp/remote.git"
git clone -q "$tmp/remote.git" "$tmp/seed" 2>/dev/null
git -C "$tmp/seed" commit -q --allow-empty -m first
git -C "$tmp/seed" push -q origin main
for name in clean dirty diverged wrong ignored ignored-owner backup; do
	base="$HOME/workspace/github.com/sync/$name"
	[[ "$name" != ignored ]] || base="$HOME/workspace/github.com/curtbushko/nixos-config"
	[[ "$name" != ignored-owner ]] || base="$HOME/workspace/github.com/curtbushko/another-repo"
	[[ "$name" != backup ]] || base="$HOME/workspace/github.com/sync/backup.bak"
	mkdir -p "$base"
	git clone -q --bare "$tmp/remote.git" "$base/.bare"
	git --git-dir="$base/.bare" config remote.origin.fetch '+refs/heads/*:refs/remotes/origin/*'
	git --git-dir="$base/.bare" worktree add -q "$base/main" main
done
sync="$HOME/workspace/github.com/sync"
first="$(git -C "$tmp/seed" rev-parse HEAD)"
printf dirty >"$sync/dirty/main/untracked"
git -C "$sync/diverged/main" commit -q --allow-empty -m local
diverged="$(git -C "$sync/diverged/main" rev-parse HEAD)"
git -C "$sync/wrong/main" switch -q -c feature
git -C "$tmp/seed" commit -q --allow-empty -m second
git -C "$tmp/seed" push -q origin main
second="$(git -C "$tmp/seed" rev-parse HEAD)"
bash "$scripts/workspace-sync-main" --dry-run
[[ "$(git -C "$sync/clean/main" rev-parse HEAD)" == "$first" ]] || fail 'sync dry run changed HEAD'
if bash "$scripts/workspace-sync-main"; then fail 'divergence should report failure'; fi
[[ "$(git -C "$sync/clean/main" rev-parse HEAD)" == "$second" ]] || fail 'clean main not updated'
for name in dirty wrong backup.bak; do
	[[ "$(git -C "$sync/$name/main" rev-parse HEAD)" == "$first" ]] || fail "changed $name"
done
[[ "$(git -C "$sync/diverged/main" rev-parse HEAD)" == "$diverged" ]] || fail 'diverged main rewritten'
[[ "$(git -C "$HOME/workspace/github.com/curtbushko/nixos-config/main" rev-parse HEAD)" == "$first" ]] || fail 'ignored main updated'
[[ "$(git -C "$HOME/workspace/github.com/curtbushko/another-repo/main" rev-parse HEAD)" == "$first" ]] || fail 'owner main updated'
printf 'PASS: workspace scripts (fixtures: %s)\n' "$tmp"

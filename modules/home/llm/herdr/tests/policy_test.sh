#!/usr/bin/env bash

set -euo pipefail

repo_root="$(git rev-parse --show-toplevel)"
flake="$repo_root/flake.nix"
module="$repo_root/modules/home/llm/herdr/default.nix"
codex_module="$repo_root/modules/home/llm/codex.nix"
pi_module="$repo_root/modules/home/llm/pi/default.nix"
work_home="$repo_root/homes/aarch64-darwin/curtbushko@curtbushko-K4W6XK6XND/default.nix"
personal_homes=(
	"$repo_root/homes/aarch64-darwin/curtbushko@m4-pro/default.nix"
	"$repo_root/homes/aarch64-linux/curtbushko@gamingrig-vm/default.nix"
	"$repo_root/homes/x86_64-linux/curtbushko@gamingrig/default.nix"
)

assert_contains() {
	local file="$1"
	local pattern="$2"

	if ! grep -Fq -- "$pattern" "$file"; then
		printf 'expected %s to contain: %s\n' "$file" "$pattern" >&2
		return 1
	fi
}

assert_contains "$flake" 'herdr-nixpkgs.url = "github:nixos/nixpkgs/'
assert_contains "$module" "herdrPackage = inputs.herdr-nixpkgs.legacyPackages.\${system}.herdr;"
if grep -Fq 'github:herdrdev/herdr/' "$flake" || grep -Fq 'inputs.herdr.packages.' "$module"; then
	printf 'HerdR must come from nixpkgs, not a separate flake input\n' >&2
	exit 1
fi
assert_contains "$flake" 'github:aorumbayev/herdr-workflows/v0.15.1'
assert_contains "$flake" 'github:mrcndz/herdr-routines/cd504512d2f1976d39668fbdc0fe9b86cf3eff85'
assert_contains "$flake" 'github:ChmaraX/herdr-nvim'
assert_contains "$module" 'plugin unlink herdr.auto-title'
assert_contains "$module" 'plugin unlink blurname.git-tab-name'
if grep -Fq 'github:blurname/herdr-git-tab-name' "$flake" || grep -Fq 'inputs.herdr-git-tab-name' "$module" || grep -Fq 'herdrGitTabName' "$module" || grep -Fq 'blurname.git-tab-name.refresh' "$module" || grep -Fq 'herdr-git-tab-name' "$repo_root/flake.lock"; then
	printf 'Git tab naming must not override custom tab names\n' >&2
	exit 1
fi
if grep -Fq 'herdr-auto-title' "$flake" || grep -Fq 'herdrAutoTitle' "$module" || grep -Fq 'herdr.auto-title.restart' "$module"; then
	printf 'herdr-auto-title must not override custom tab names\n' >&2
	exit 1
fi
assert_contains "$module" 'src = inputs.herdr-nvim;'
assert_contains "$module" "plugin link \${herdrNvim}"
assert_contains "$module" 'plugin unlink herdr-context'
if grep -Fq 'herdr-context' "$flake" || grep -Fq 'herdrContext' "$module" || grep -Fq 'herdr-context.pin-target' "$module"; then
	printf 'herdr-context must not be configured alongside herdr-nvim\n' >&2
	exit 1
fi
assert_contains "$pi_module" '".pi/agent/skills".source = ../skills;'
assert_contains "$pi_module" '@andrewjacop/pi-herdr'
assert_contains "$pi_module" 'enabledModels = cfg.pi.enabledModels;'
assert_contains "$work_home" 'enabledModels = ["github-copilot/*"];'
assert_contains "$work_home" 'copilot.enable = true;'
for personal_home in "${personal_homes[@]}"; do
	assert_contains "$personal_home" '"openai-codex/gpt-6-sol"'
	assert_contains "$personal_home" '"openai-codex/*"'
	if grep -Fq -- '"anthropic/*"' "$personal_home" || grep -Fq -- '"local/*"' "$personal_home" || grep -Fq -- '"gamingrig/*"' "$personal_home"; then
		printf 'personal home must expose only visible Codex models: %s\n' "$personal_home" >&2
		exit 1
	fi
	if grep -Fq -- 'copilot.enable = true;' "$personal_home"; then
		printf 'personal home must not enable Copilot: %s\n' "$personal_home" >&2
		exit 1
	fi
done
assert_contains "$module" 'herdrIntegrations = ["pi" "claude" "codex"] ++ lib.optionals cfg.copilot.enable ["copilot"];'
assert_contains "$module" 'key = "alt+h"'
assert_contains "$module" 'key = "alt+l"'
assert_contains "$module" "command = \"\${herdrSmartFocus}/bin/herdr-smart-focus left\""
assert_contains "$module" "command = \"\${herdrSmartFocus}/bin/herdr-smart-focus right\""
assert_contains "$module" 'focus_pane_down = ["prefix+j", "alt+j", "alt+down"]'
assert_contains "$module" 'focus_pane_up = ["prefix+k", "alt+k", "alt+up"]'
# TOML keys following [[keys.command]] belong to that command, not [keys].
last_key_line="$(grep -n 'switch_tab = ' "$module" | head -1 | cut -d: -f1)"
first_command_line="$(grep -n '\[\[keys.command\]\]' "$module" | head -1 | cut -d: -f1)"
if ((last_key_line >= first_command_line)); then
	printf 'Herdr [keys] settings must precede [[keys.command]] blocks\n' >&2
	exit 1
fi
assert_contains "$module" '[ui.sound]'
assert_contains "$module" 'enabled = false'
assert_contains "$module" "integration install \"\$integration\""
assert_contains "$module" '".codex/hooks.json".source = pkgs.writeText'
assert_contains "$codex_module" "[hooks.state.\"\${config.home.homeDirectory}/.codex/hooks.json:session_start:0:0\"]"
assert_contains "$codex_module" "trusted_hash = \"sha256:\${herdrSessionStartHookHash}\""
for workflow in preflight verify-fast verify-full review implement-review; do
	if [[ ! -f "$repo_root/modules/home/llm/herdr/workflows/${workflow}.yaml" ]]; then
		printf 'missing global workflow: %s\n' "$workflow" >&2
		exit 1
	fi
done
assert_contains "$repo_root/modules/home/llm/herdr/routines.toml" 'enabled = false'

if grep -Rq --exclude='policy_test.sh' --exclude='README.md' 'herdr update\|hwf update' "$repo_root/modules/home/llm/herdr"; then
	printf 'Nix-managed HerdR components must not use mutable self-updaters\n' >&2
	exit 1
fi

printf 'HerdR policy checks passed\n'

#!/usr/bin/env bash

# Script: check-statusline.sh
# Description: Verify Codex wires in a Claude-style statusline

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../../.." && pwd)"
readonly REPO_ROOT

require_command() {
	local cmd="$1"

	if ! command -v "$cmd" >/dev/null 2>&1; then
		echo "Missing required command: $cmd" >&2
		exit 1
	fi
}

require_command grep

home_token="\$HOME"
config_home_token="\${config.home.homeDirectory}"

assert_contains() {
	local file="$1"
	local expected="$2"

	if ! grep -Fq "$expected" "$file"; then
		echo "Expected to find in ${file}: ${expected}" >&2
		exit 1
	fi
}

assert_file_exists() {
	local file="$1"

	if [[ ! -f "$file" ]]; then
		echo "Expected file to exist: $file" >&2
		exit 1
	fi
}

assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'home.file.".codex/config.toml"'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'status_line = {'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'model = "gpt-5.4"'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'reasoning_effort = "medium"'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" "command = \"node ${home_token}/.codex/statusline.mjs\""
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" '[sandbox_workspace_write]'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" "readable_roots = [ \"${config_home_token}/.codex/sessions\" ]"
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'home.file.".codex/statusline.mjs" = {'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'const rateLimits = input.rate_limits || {};'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'five-hour-limit'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'weekly-limit'
assert_contains "${REPO_ROOT}/modules/home/llm/codex.nix" 'const icon = /\.anthropic\./.test(rawModel) ? " " : "󱚝 ";'

#!/usr/bin/env bash
set -euo pipefail

for command in dirname grep awk cmp; do
	command -v "$command" >/dev/null || exit 1
done
repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/../../../.." && pwd)"
cd "$repo_root"

protocol=modules/home/llm/pi/AGENTS.md
[[ -f "$protocol" ]] || {
	printf 'Missing Pi global instructions\n' >&2
	exit 1
}
for section in {1..7}; do
	grep -q "^## $section\. " "$protocol"
done
for instructions in modules/home/llm/codex/AGENTS.md modules/home/llm/claude/CLAUDE.md; do
	cmp "$protocol" <(awk '/^# Technical Collaboration and Decision Protocol$/ { found = 1 } found' "$instructions")
done

grep -Fq '".pi/agent/AGENTS.md".source = ./AGENTS.md;' modules/home/llm/pi/default.nix
grep -Fq 'home.file.".codex/AGENTS.md".source = ./codex/AGENTS.md;' modules/home/llm/codex.nix
grep -Fq 'home.file.".claude/CLAUDE.md".source = ./claude/CLAUDE.md;' modules/home/llm/claude.nix
printf 'Global collaboration protocol checks passed\n'

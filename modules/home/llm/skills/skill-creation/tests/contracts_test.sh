#!/usr/bin/env bash
set -euo pipefail

for tool in awk grep wc dirname; do command -v "$tool" >/dev/null || exit 1; done
skills="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
roles=(product-manager delivery-coordinator code-architect architecture-reviewer security-analyst security-reviewer repo-maintainer repo-maintenance-reviewer usability-designer usability-reviewer go-developer node-developer zig-developer go-code-reviewer go-test-reviewer node-code-reviewer node-test-reviewer zig-code-reviewer zig-test-reviewer nix-code-reviewer nix-test-reviewer bash-code-reviewer bash-test-reviewer go-reviewer node-reviewer zig-reviewer go-team node-team zig-team go-builder node-builder zig-builder go-code-review golang skill-creation)

for role in "${roles[@]}"; do
	file="$skills/$role/SKILL.md"
	[[ -f "$file" ]] || {
		printf 'Missing role: %s\n' "$role" >&2
		exit 1
	}
	grep -Fxq "name: $role" "$file"
	grep -Eq '^description: Use when ' "$file"
	if grep -E '^description:' "$file" | grep -Eq 'Coordinates|Enforces|Follows|Returns|Covers'; then
		printf 'Workflow summary in description: %s\n' "$role" >&2
		exit 1
	fi
	words="$(wc -w <"$file")"
	((words <= 500)) || {
		printf 'Oversized role: %s (%s words)\n' "$role" "$words" >&2
		exit 1
	}
	while IFS= read -r link; do
		link="${link#](}"
		link="${link%%#*}"
		[[ -z "$link" || "$link" == *://* ]] && continue
		[[ -f "$skills/$role/$link" ]] || {
			printf 'Broken reference: %s -> %s\n' "$role" "$link" >&2
			exit 1
		}
	done < <(grep -oE '\]\([^)]+' "$file" || true)
done

grep -Fq 'Static checks do not prove agent behavior' "$skills/skill-creation/SKILL.md"
grep -Fq 'CVE searches' "$skills/security-analyst/SKILL.md"
grep -Fq 'Renovate' "$skills/repo-maintainer/SKILL.md"
grep -Fq 'Docker/container images built with Nix' "$skills/repo-maintainer/SKILL.md"
grep -Fq 'safe next step' "$skills/usability-designer/SKILL.md"
grep -Fq 'reviewer: go:code' "$skills/go-code-reviewer/SKILL.md"
grep -Fq 'reviewer: go:test' "$skills/go-test-reviewer/SKILL.md"
printf 'Role structure checks passed (not behavioral validation)\n'

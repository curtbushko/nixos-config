#!/usr/bin/env bash
set -euo pipefail

for command in grep dirname; do
	command -v "$command" >/dev/null || exit 1
done
skills="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

for skill in prd rfc to-prd to-phases write-phase go-team node-team zig-team go-builder node-builder zig-builder go-reviewer node-reviewer zig-reviewer zig-code-reviewer zig-comment-reviewer zig-architecture-reviewer zig-test-reviewer; do
	grep -Fq 'mtn-tasks' "$skills/$skill/SKILL.md" || {
		printf 'Missing mtn contract: %s\n' "$skill" >&2
		exit 1
	}
	if grep -REn '\.phases/|\.tasks/[^[:space:]]*\.yaml|result-[^[:space:]]*\.yaml' "$skills/$skill" --include='*.md'; then
		printf 'Legacy workflow instructions remain: %s\n' "$skill" >&2
		exit 1
	fi
done
for policy in "mtn --path \"\$TASK_ROOT\"" 'explicit approval' 'single writer' 'agentEligible' 'workflowKind' 'workflowOrder' 'Do not hand-edit' 'never use --force'; do
	grep -Fq "$policy" "$skills/mtn-tasks/SKILL.md" || {
		printf 'Missing shared policy: %s\n' "$policy" >&2
		exit 1
	}
done
for policy in 'Dependency-ready scheduling' 'Coordinator-only writes' 'Integration before completion' 'Requirement traceability' 'Recovery state machine'; do
	grep -Fq "$policy" "$skills/mtn-tasks/references/protocol.md" || {
		printf 'Missing delivery policy: %s\n' "$policy" >&2
		exit 1
	}
done
if grep -RFq 'Maintain one active builder' "$skills/mtn-tasks/references/execution.md"; then
	printf 'Obsolete serial implementation constraint\n' >&2
	exit 1
fi
printf 'mtn skill policy checks passed\n'

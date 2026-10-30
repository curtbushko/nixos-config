#!/usr/bin/env bash
set -euo pipefail
for tool in grep dirname; do command -v "$tool" >/dev/null || exit 1; done
skills="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
for team in go-team node-team zig-team; do
	grep -Fq 'references/rex.md' "$skills/$team/SKILL.md"
	grep -Fq 'MTN_REX_COORDINATOR_RUN' "$skills/$team/SKILL.md"
	grep -Fq 'not per phase' "$skills/$team/SKILL.md"
	grep -Fq 'Use one lowercase hyphenated agent identity' "$skills/$team/SKILL.md"
done
grep -Fq 'references/rex.md' "$skills/mtn-tasks/SKILL.md"
grep -Fq '[Rex/Pi execution](rex.md)' "$skills/mtn-tasks/references/execution.md"
grep -Fq 'runtime' "$skills/mtn-tasks/references/protocol.md"
grep -Fq 'mtn-rex = pkgs.writeShellApplication' "$skills/../../scripts/default.nix"
grep -Fq '## Identity contract' "$skills/mtn-tasks/references/rex.md"
grep -Fq 'Runtime identity' "$skills/mtn-tasks/references/rex.md"
grep -Fq 'MUST be the same canonical agent string' "$skills/mtn-tasks/references/rex.md"
if grep -Fq 'separate Pi window' "$skills/mtn-tasks/references/rex.md"; then exit 1; fi
printf 'Rex team wiring checks passed\n'

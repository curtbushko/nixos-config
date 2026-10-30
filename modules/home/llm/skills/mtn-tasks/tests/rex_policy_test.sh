#!/usr/bin/env bash
set -euo pipefail
for tool in grep dirname; do command -v "$tool" >/dev/null || exit 1; done
skills="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
for team in go-team node-team zig-team; do
	grep -Fq 'references/rex.md' "$skills/$team/SKILL.md"
	grep -Fq 'MTN_REX_COORDINATOR_RUN' "$skills/$team/SKILL.md"
done
grep -Fq 'references/rex.md' "$skills/mtn-tasks/SKILL.md"
grep -Fq '[Rex/Pi execution](rex.md)' "$skills/mtn-tasks/references/execution.md"
grep -Fq 'runtime' "$skills/mtn-tasks/references/protocol.md"
grep -Fq 'mtn-rex = pkgs.writeShellApplication' "$skills/../../scripts/default.nix"
printf 'Rex team wiring checks passed\n'

#!/usr/bin/env bash
set -euo pipefail

for tool in pi jq git mkdir date shasum dirname; do command -v "$tool" >/dev/null || exit 1; done
model="${1:?usage: run_evals.sh MODEL NEW_OUTPUT_DIR [REPETITIONS]}"
out="${2:?output directory required}"
repetitions="${3:-1}"
[[ "$repetitions" =~ ^[1-9][0-9]*$ ]] || {
	printf 'Invalid repetitions\n' >&2
	exit 1
}
[[ ! -e "$out" && ! -L "$out" ]] || {
	printf 'Output already exists: %s\n' "$out" >&2
	exit 1
}
script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
skills="$(cd "$script_dir/../.." && pwd)"
repo="$(git -C "$skills" rev-parse --show-toplevel)"
mkdir -p "$out"
out="$(cd "$out" && pwd)"
jq -n --arg model "$model" --arg time "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" --arg revision "$(git -C "$repo" rev-parse HEAD)" --argjson repetitions "$repetitions" \
	'{model:$model,startedUTC:$time,baseRevision:$revision,repetitions:$repetitions,type:"no-tools scenarios; manual scoring required"}' >"$out/run.json"

append_context() {
	local name="$1" destination="$2" path
	if [[ "$name" == *.md ]]; then path="$skills/$name"; else path="$skills/$name/SKILL.md"; fi
	[[ -f "$path" ]] || {
		printf 'Missing context: %s\n' "$name" >&2
		exit 1
	}
	printf '\n## Context: %s\n%s\n' "$name" "$(<"$path")" >>"$destination"
	shasum -a 256 "$path" >>"$out/context-hashes.txt"
}

while IFS= read -r scenario; do
	id="$(jq -r .id <<<"$scenario")"
	[[ -z "${SCENARIO:-}" || "$id" == "$SCENARIO" ]] || continue
	skill="$(jq -r .skill <<<"$scenario")"
	arms=(candidate)
	if [[ "$(jq -r '.compare // false' <<<"$scenario")" == true ]]; then arms+=(baseline control); fi
	printf '%s\n' "$scenario" >"$out/$id.scenario.json"
	for arm in "${arms[@]}"; do
		prompt="$out/$id.$arm.prompt.md"
		printf 'Evaluate the supplied task using the provided role guidance. This is a no-tools scenario; report unavailable evidence honestly.\n' >"$prompt"
		case "$arm" in
		candidate)
			append_context "$skill" "$prompt"
			while IFS= read -r context; do append_context "$context" "$prompt"; done < <(jq -r '.context[]' <<<"$scenario")
			if [[ "$skill" != skill-creation ]]; then
				append_context 'delivery-coordinator/references/roles.md' "$prompt"
			fi
			;;
		baseline)
			git -C "$repo" show "HEAD:modules/home/llm/skills/$skill/SKILL.md" >>"$prompt"
			;;
		control) ;;
		esac
		printf '\n## Task\n%s\n' "$(jq -r .prompt <<<"$scenario")" >>"$prompt"
		for ((repeat = 1; repeat <= repetitions; repeat++)); do
			printf '%s %s %s/%s\n' "$id" "$arm" "$repeat" "$repetitions"
			pi --model "$model" --thinking low --no-tools --no-extensions --no-mcp \
				--no-skills --no-prompt-templates --no-context-files --no-session --offline \
				--system-prompt 'Apply only the supplied task and role context. Return the requested artifact without preamble. No tools are available.' \
				-p "$(<"$prompt")" </dev/null >"$out/$id.$arm.$repeat.txt" 2>"$out/$id.$arm.$repeat.stderr"
		done
	done
done < <(jq -c '.[]' "$script_dir/scenarios.json")
printf 'Responses saved to %s; manual scoring required\n' "$out"

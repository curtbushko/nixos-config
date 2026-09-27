#!/usr/bin/env bash

set -euo pipefail

usage() {
	printf 'Usage: agent-quality <preflight|verify-fast|verify-full>\n' >&2
}

has_task() {
	task --silent --list-all 2>/dev/null | grep -Eq "(^|[[:space:]])$1([[:space:]]|$)"
}

run_contract() {
	local target="$1"

	if [[ -f Taskfile.yml || -f Taskfile.yaml ]]; then
		if has_task "$target"; then
			task "$target"
			return
		fi
	fi

	if [[ -f Makefile ]] && grep -Eq "^${target}:" Makefile; then
		make "$target"
		return
	fi

	if command -v just >/dev/null 2>&1 && [[ -f justfile || -f Justfile ]]; then
		if just --summary 2>/dev/null | tr ' ' '\n' | grep -Fxq "$target"; then
			just "$target"
			return
		fi
	fi

	printf 'Repository does not provide the required quality target: %s\n' "$target" >&2
	printf 'Add it to Taskfile.yml, Makefile, or justfile.\n' >&2
	return 2
}

main() {
	if [[ $# -ne 1 ]]; then
		usage
		return 2
	fi

	case "$1" in
	preflight)
		git status --short
		if has_task agent-preflight; then
			task agent-preflight
		fi
		;;
	verify-fast)
		run_contract agent-verify-fast
		;;
	verify-full)
		run_contract agent-verify-full
		;;
	*)
		usage
		return 2
		;;
	esac
}

main "$@"

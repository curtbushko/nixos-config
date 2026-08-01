#!/usr/bin/env bash

# Script: wt-checkout.sh
# Description: Check out an existing remote branch into a worktree with tracking
# Usage: wt-checkout <branch-name>

set -euo pipefail

readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m'

log_info() { echo -e "${GREEN}[INFO]${NC} $*" >&2; }
log_warn()  { echo -e "${YELLOW}[WARN]${NC} $*" >&2; }
log_error() { echo -e "${RED}[ERROR]${NC} $*" >&2; }

usage() {
	cat <<EOF
Usage: wt-checkout <branch-name>

Checks out an existing remote branch into a worktree with upstream tracking.
For creating a new local branch, use wt-add instead.

Examples:
  wt-checkout feature-branch    # Check out origin/feature-branch into a worktree

Options:
  -h, --help    Show this help message
EOF
}

main() {
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		usage
		exit 0
	fi

	if [[ -z "${1:-}" ]]; then
		log_error "Branch name is required"
		usage
		exit 1
	fi

	local branch_name="$1"

	if ! git check-ref-format "refs/heads/$branch_name" &>/dev/null; then
		log_error "Invalid branch name: $branch_name"
		exit 1
	fi

	if ! git rev-parse --git-dir &>/dev/null; then
		log_error "Not in a git repository"
		exit 1
	fi

	if git worktree list | grep -q "/$branch_name\$"; then
		log_error "Worktree for branch '$branch_name' already exists"
		git worktree list
		exit 1
	fi

	log_info "Fetching latest from remote..."
	if ! git fetch origin 2>&1 | grep -v "^$"; then
		log_warn "Failed to fetch from remote, continuing anyway..."
	fi

	if ! git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
		log_error "Remote branch 'origin/$branch_name' does not exist"
		log_warn "To create a new local branch, use wt-add instead."
		exit 1
	fi

	log_info "Checking out remote branch 'origin/$branch_name'..."
	git worktree add -B "$branch_name" "$branch_name" "origin/$branch_name"

	# Explicitly set upstream tracking (git worktree add doesn't always do this)
	cd "$branch_name" || exit 1
	git branch --set-upstream-to="origin/$branch_name" "$branch_name"
	cd - >/dev/null || exit 1

	local worktree_path
	worktree_path="$(git worktree list | grep "/$branch_name\$" | awk '{print $1}')"

	log_info "Created worktree '$branch_name' tracking 'origin/$branch_name'"
	echo ""
	echo "Worktree created successfully!"
	echo "Location: $worktree_path"

	if [ -n "${WORKTRUNK_DIRECTIVE_CD_FILE:-}" ]; then
		echo "$worktree_path" > "$WORKTRUNK_DIRECTIVE_CD_FILE"
	fi
}

main "$@"

#!/usr/bin/env bash

# Script: wt-add.sh
# Description: Create a worktree with proper remote tracking
# Usage: wt add <branch-name>

set -euo pipefail

# Color codes for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly NC='\033[0m' # No Color

log_info() {
	echo -e "${GREEN}[INFO]${NC} $*" >&2
}

log_warn() {
	echo -e "${YELLOW}[WARN]${NC} $*" >&2
}

log_error() {
	echo -e "${RED}[ERROR]${NC} $*" >&2
}

usage() {
	cat <<EOF
Usage: wt-add <branch-name>
   Or: wta <branch-name>    (wrapper with auto-cd)

Creates a new git worktree with proper remote tracking.

If a remote branch exists with the same name, the local branch will track it.
If no remote branch exists, a new local branch is created with upstream tracking
configured for the next push.

Examples:
  wt-add feature-branch        # Create new branch and worktree
  wta feature-branch           # Create and cd to new worktree

Options:
  -h, --help    Show this help message
EOF
}

main() {
	# Handle help flag
	if [[ "${1:-}" == "--help" ]] || [[ "${1:-}" == "-h" ]]; then
		usage
		exit 0
	fi

	# Check if branch name is provided
	if [[ -z "${1:-}" ]]; then
		log_error "Branch name is required"
		usage
		exit 1
	fi

	local branch_name="$1"

	# Validate branch name format
	if ! git check-ref-format "refs/heads/$branch_name" &>/dev/null; then
		log_error "Invalid branch name: $branch_name"
		exit 1
	fi

	# Check if we're in a git repository
	if ! git rev-parse --git-dir &>/dev/null; then
		log_error "Not in a git repository"
		exit 1
	fi

	# Check if worktree already exists
	if git worktree list | grep -q "/$branch_name\$"; then
		log_error "Worktree for branch '$branch_name' already exists"
		git worktree list
		exit 1
	fi

	# Fetch latest from remote to ensure we have up-to-date info
	log_info "Fetching latest from remote..."
	if ! git fetch origin 2>&1 | grep -v "^$"; then
		log_warn "Failed to fetch from remote, continuing anyway..."
	fi

	# Check if remote branch exists
	if git show-ref --verify --quiet "refs/remotes/origin/$branch_name"; then
		log_info "Remote branch 'origin/$branch_name' exists, tracking it..."

		# Create worktree tracking the remote branch (3-argument form)
		git worktree add -B "$branch_name" "$branch_name" "origin/$branch_name"

		log_info "Created worktree '$branch_name' tracking 'origin/$branch_name'"
	else
		log_info "Remote branch 'origin/$branch_name' does not exist, creating new branch..."

		# Create worktree with new branch
		git worktree add "$branch_name" -b "$branch_name"

		# Set up upstream tracking using git config (works even if remote doesn't exist yet)
		cd "$branch_name" || exit 1
		git config branch."$branch_name".remote origin
		git config branch."$branch_name".merge "refs/heads/$branch_name"
		cd - >/dev/null || exit 1

		log_info "Created worktree '$branch_name' with upstream configured for 'origin/$branch_name'"
		log_warn "Push to create remote branch: git push -u origin $branch_name"
	fi

	# Get the absolute path of the worktree
	local worktree_path
	worktree_path="$(git worktree list | grep "/$branch_name\$" | awk '{print $1}')"

	echo ""
	echo "Worktree created successfully!"
	echo "Location: $worktree_path"
}

main "$@"

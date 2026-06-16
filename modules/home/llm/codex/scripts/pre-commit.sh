#!/usr/bin/env bash

# Script: pre-commit.sh
# Description: Runs all skill validation scripts before committing
# Usage: pre-commit.sh [--staged] [directory]

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

# Nerd Font icons
readonly ICON_CHECK=''
readonly ICON_CROSS=''
readonly ICON_WARN=''
readonly ICON_INFO=''
readonly ICON_RUN=''

target_dir="."
staged_only=false
skip_quality_gates=false
skip_emoji_check=false
skip_bash_check=false
fix_mode=false

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [DIRECTORY]

Runs all skill validation scripts to ensure code meets quality standards
before committing. Can be used as a git pre-commit hook.

OPTIONS:
    -h, --help              Show this help message
    -s, --staged            Only check git staged files (for emoji check)
    -f, --fix               Attempt to auto-fix issues where possible
    --skip-quality-gates    Skip build/test/lint checks
    --skip-emoji-check      Skip emoji validation
    --skip-bash-check       Skip bash script validation

ARGUMENTS:
    DIRECTORY               Directory to check (default: current directory)

CHECKS RUN:
    1. quality-gates.sh     - Build, test, and lint validation
    2. check-no-emojis.sh   - No emojis in source files
    3. check-bash.sh        - Bash script conventions

GIT HOOK INSTALLATION:
    To use as a pre-commit hook:

    ln -sf ${SCRIPT_DIR}/pre-commit.sh .git/hooks/pre-commit

EXAMPLES:
    ${SCRIPT_NAME}                    # Run all checks
    ${SCRIPT_NAME} --staged           # Check only staged files
    ${SCRIPT_NAME} --fix              # Auto-fix where possible
EOF
}

log_info() {
    echo -e "${BLUE}${ICON_INFO}${NC} $*" >&2
}

log_success() {
    echo -e "${GREEN}${ICON_CHECK}${NC} $*" >&2
}

log_warn() {
    echo -e "${YELLOW}${ICON_WARN}${NC} $*" >&2
}

log_error() {
    echo -e "${RED}${ICON_CROSS}${NC} $*" >&2
}

log_section() {
    echo ""
    echo -e "${CYAN}${ICON_RUN} $*${NC}"
    echo -e "${CYAN}$(printf '%.0s─' {1..50})${NC}"
}

# Run a check script
run_check() {
    local name="$1"
    local script="$2"
    shift 2
    local args=("$@")

    if [[ ! -x "$script" ]]; then
        log_warn "Script not executable: $script"
        chmod +x "$script" 2>/dev/null || true
    fi

    if [[ ! -f "$script" ]]; then
        log_error "Script not found: $script"
        return 1
    fi

    log_section "$name"

    if "$script" "${args[@]}"; then
        return 0
    else
        return 1
    fi
}

main() {
    local failed_checks=()
    local start_time
    start_time=$(date +%s)

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -s|--staged)
                staged_only=true
                shift
                ;;
            -f|--fix)
                fix_mode=true
                shift
                ;;
            --skip-quality-gates)
                skip_quality_gates=true
                shift
                ;;
            --skip-emoji-check)
                skip_emoji_check=true
                shift
                ;;
            --skip-bash-check)
                skip_bash_check=true
                shift
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done

    # Validate directory
    if [[ ! -d "$target_dir" ]]; then
        log_error "Directory not found: $target_dir"
        exit 1
    fi

    target_dir="$(cd "$target_dir" && pwd)"

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║         Pre-Commit Validation Suite              ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""
    log_info "Directory: $target_dir"
    if $staged_only; then
        log_info "Mode: Staged files only"
    fi
    if $fix_mode; then
        log_info "Fix mode: Enabled"
    fi

    # Build check arguments
    local quality_args=("$target_dir")
    if $fix_mode; then
        quality_args=("--fix" "$target_dir")
    fi

    local emoji_args=("$target_dir")
    if $staged_only; then
        emoji_args=("--staged")
    fi

    local bash_args=("$target_dir")

    # Run checks
    # 1. Quality Gates (build/test/lint)
    if ! $skip_quality_gates; then
        if ! run_check "Quality Gates (build/test/lint)" "${SCRIPT_DIR}/quality-gates.sh" "${quality_args[@]}"; then
            failed_checks+=("quality-gates")
        fi
    else
        log_info "Skipping quality gates"
    fi

    # 2. Emoji Check
    if ! $skip_emoji_check; then
        if ! run_check "No Emojis Check" "${SCRIPT_DIR}/check-no-emojis.sh" "${emoji_args[@]}"; then
            failed_checks+=("check-no-emojis")
        fi
    else
        log_info "Skipping emoji check"
    fi

    # 3. Bash Script Check
    if ! $skip_bash_check; then
        if ! run_check "Bash Script Conventions" "${SCRIPT_DIR}/check-bash.sh" "${bash_args[@]}"; then
            failed_checks+=("check-bash")
        fi
    else
        log_info "Skipping bash check"
    fi

    # Summary
    local end_time
    end_time=$(date +%s)
    local duration=$((end_time - start_time))

    echo ""
    echo -e "${CYAN}╔══════════════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}║                    Summary                       ║${NC}"
    echo -e "${CYAN}╚══════════════════════════════════════════════════╝${NC}"
    echo ""

    if [[ ${#failed_checks[@]} -gt 0 ]]; then
        log_error "FAILED: ${#failed_checks[@]} check(s) failed"
        echo ""
        echo "Failed checks:"
        for check in "${failed_checks[@]}"; do
            echo -e "  ${RED}${ICON_CROSS}${NC} $check"
        done
        echo ""
        echo "Please fix the issues above before committing."
        if ! $fix_mode; then
            echo "Try running with --fix to auto-fix some issues."
        fi
        echo ""
        log_info "Duration: ${duration}s"
        exit 1
    else
        log_success "All checks passed"
        log_info "Duration: ${duration}s"
        echo ""
        exit 0
    fi
}

main "$@"

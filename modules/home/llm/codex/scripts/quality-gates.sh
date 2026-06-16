#!/usr/bin/env bash

# Script: quality-gates.sh
# Description: Validates quality gates based on project type (build/test/lint)
# Usage: quality-gates.sh [--fix] [directory]

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_NAME="$(basename "${BASH_SOURCE[0]}")"

# Colors
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Nerd Font icons
readonly ICON_CHECK=''
readonly ICON_CROSS=''
readonly ICON_WARN=''
readonly ICON_INFO=''

fix_mode=false
target_dir="."

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [DIRECTORY]

Validates quality gates based on project type. Detects Go, Node.js, and Nix
projects and runs appropriate build/test/lint commands.

OPTIONS:
    -h, --help      Show this help message
    -f, --fix       Attempt to auto-fix issues (run formatters)

ARGUMENTS:
    DIRECTORY       Directory to check (default: current directory)

EXAMPLES:
    ${SCRIPT_NAME}                    # Check current directory
    ${SCRIPT_NAME} ./my-project       # Check specific directory
    ${SCRIPT_NAME} --fix              # Check and auto-fix
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

# Detect project type
detect_project_type() {
    local dir="$1"
    local types=()

    if [[ -f "${dir}/go.mod" ]]; then
        types+=("go")
    fi

    if [[ -f "${dir}/package.json" ]]; then
        types+=("nodejs")
    fi

    if [[ -f "${dir}/flake.nix" ]]; then
        types+=("nix")
    fi

    if [[ -f "${dir}/Cargo.toml" ]]; then
        types+=("rust")
    fi

    echo "${types[*]}"
}

# Run Go quality gates
check_go() {
    local dir="$1"
    local failed=false

    log_info "Running Go quality gates..."

    # Build
    log_info "  go build ./..."
    if ! (cd "$dir" && go build ./...); then
        log_error "  Go build failed"
        failed=true
    else
        log_success "  Build passed"
    fi

    # Test
    log_info "  go test ./..."
    if ! (cd "$dir" && go test ./... 2>&1); then
        log_error "  Go tests failed"
        failed=true
    else
        log_success "  Tests passed"
    fi

    # Lint (if golangci-lint available)
    if command -v golangci-lint &> /dev/null; then
        log_info "  golangci-lint run"
        if $fix_mode; then
            if ! (cd "$dir" && golangci-lint run --fix); then
                log_error "  Linter failed"
                failed=true
            else
                log_success "  Lint passed (with fixes)"
            fi
        else
            if ! (cd "$dir" && golangci-lint run); then
                log_error "  Linter failed"
                failed=true
            else
                log_success "  Lint passed"
            fi
        fi
    else
        log_warn "  golangci-lint not found, skipping lint"
    fi

    # Format check
    if $fix_mode; then
        log_info "  gofmt -w ."
        (cd "$dir" && gofmt -w .)
        log_success "  Formatted"
    else
        log_info "  gofmt check"
        if [[ -n "$(cd "$dir" && gofmt -l .)" ]]; then
            log_error "  Formatting issues found (run with --fix)"
            failed=true
        else
            log_success "  Format check passed"
        fi
    fi

    if $failed; then
        return 1
    fi
    return 0
}

# Run Node.js quality gates
check_nodejs() {
    local dir="$1"
    local failed=false
    local pkg_manager="npm"

    # Detect package manager
    if [[ -f "${dir}/pnpm-lock.yaml" ]]; then
        pkg_manager="pnpm"
    elif [[ -f "${dir}/yarn.lock" ]]; then
        pkg_manager="yarn"
    fi

    log_info "Running Node.js quality gates (${pkg_manager})..."

    # Check if node_modules exists
    if [[ ! -d "${dir}/node_modules" ]]; then
        log_warn "  node_modules not found, running install..."
        (cd "$dir" && $pkg_manager install)
    fi

    # Build (if script exists)
    if grep -q '"build"' "${dir}/package.json" 2>/dev/null; then
        log_info "  ${pkg_manager} run build"
        if ! (cd "$dir" && $pkg_manager run build); then
            log_error "  Build failed"
            failed=true
        else
            log_success "  Build passed"
        fi
    fi

    # Test (if script exists)
    if grep -q '"test"' "${dir}/package.json" 2>/dev/null; then
        log_info "  ${pkg_manager} test"
        if ! (cd "$dir" && $pkg_manager test 2>&1); then
            log_error "  Tests failed"
            failed=true
        else
            log_success "  Tests passed"
        fi
    else
        log_warn "  No test script found"
    fi

    # Lint (if script exists)
    if grep -q '"lint"' "${dir}/package.json" 2>/dev/null; then
        if $fix_mode && grep -q '"lint:fix"' "${dir}/package.json" 2>/dev/null; then
            log_info "  ${pkg_manager} run lint:fix"
            if ! (cd "$dir" && $pkg_manager run lint:fix); then
                log_error "  Lint fix failed"
                failed=true
            else
                log_success "  Lint fixed"
            fi
        else
            log_info "  ${pkg_manager} run lint"
            if ! (cd "$dir" && $pkg_manager run lint); then
                log_error "  Lint failed"
                failed=true
            else
                log_success "  Lint passed"
            fi
        fi
    fi

    if $failed; then
        return 1
    fi
    return 0
}

# Run Nix quality gates
check_nix() {
    local dir="$1"
    local failed=false

    log_info "Running Nix quality gates..."

    # Flake check
    log_info "  nix flake check"
    if ! (cd "$dir" && nix flake check 2>&1); then
        log_error "  Flake check failed"
        failed=true
    else
        log_success "  Flake check passed"
    fi

    # Format check (if nixfmt or alejandra available)
    if command -v nixfmt &> /dev/null; then
        if $fix_mode; then
            log_info "  nixfmt formatting..."
            find "$dir" -name "*.nix" -type f -exec nixfmt {} \;
            log_success "  Formatted with nixfmt"
        else
            log_info "  nixfmt check"
            if ! find "$dir" -name "*.nix" -type f -exec nixfmt --check {} \; 2>/dev/null; then
                log_warn "  Formatting issues found (run with --fix)"
            else
                log_success "  Format check passed"
            fi
        fi
    elif command -v alejandra &> /dev/null; then
        if $fix_mode; then
            log_info "  alejandra formatting..."
            (cd "$dir" && alejandra .)
            log_success "  Formatted with alejandra"
        else
            log_info "  alejandra check"
            if ! (cd "$dir" && alejandra --check . 2>/dev/null); then
                log_warn "  Formatting issues found (run with --fix)"
            else
                log_success "  Format check passed"
            fi
        fi
    else
        log_warn "  No Nix formatter found (nixfmt/alejandra)"
    fi

    if $failed; then
        return 1
    fi
    return 0
}

# Run Rust quality gates
check_rust() {
    local dir="$1"
    local failed=false

    log_info "Running Rust quality gates..."

    # Build
    log_info "  cargo build"
    if ! (cd "$dir" && cargo build); then
        log_error "  Cargo build failed"
        failed=true
    else
        log_success "  Build passed"
    fi

    # Test
    log_info "  cargo test"
    if ! (cd "$dir" && cargo test); then
        log_error "  Cargo tests failed"
        failed=true
    else
        log_success "  Tests passed"
    fi

    # Clippy
    if command -v cargo-clippy &> /dev/null || cargo clippy --version &> /dev/null; then
        log_info "  cargo clippy"
        if $fix_mode; then
            if ! (cd "$dir" && cargo clippy --fix --allow-dirty --allow-staged); then
                log_error "  Clippy failed"
                failed=true
            else
                log_success "  Clippy passed (with fixes)"
            fi
        else
            if ! (cd "$dir" && cargo clippy -- -D warnings); then
                log_error "  Clippy failed"
                failed=true
            else
                log_success "  Clippy passed"
            fi
        fi
    fi

    # Format
    if $fix_mode; then
        log_info "  cargo fmt"
        (cd "$dir" && cargo fmt)
        log_success "  Formatted"
    else
        log_info "  cargo fmt --check"
        if ! (cd "$dir" && cargo fmt --check); then
            log_error "  Formatting issues found (run with --fix)"
            failed=true
        else
            log_success "  Format check passed"
        fi
    fi

    if $failed; then
        return 1
    fi
    return 0
}

main() {
    local overall_failed=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -f|--fix)
                fix_mode=true
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
    log_info "Checking directory: $target_dir"

    # Detect project types
    local project_types
    project_types="$(detect_project_type "$target_dir")"

    if [[ -z "$project_types" ]]; then
        log_warn "No recognized project type found"
        exit 0
    fi

    log_info "Detected project types: $project_types"
    echo ""

    # Run checks for each detected type
    for ptype in $project_types; do
        case $ptype in
            go)
                if ! check_go "$target_dir"; then
                    overall_failed=true
                fi
                ;;
            nodejs)
                if ! check_nodejs "$target_dir"; then
                    overall_failed=true
                fi
                ;;
            nix)
                if ! check_nix "$target_dir"; then
                    overall_failed=true
                fi
                ;;
            rust)
                if ! check_rust "$target_dir"; then
                    overall_failed=true
                fi
                ;;
        esac
        echo ""
    done

    # Summary
    if $overall_failed; then
        log_error "Quality gates FAILED"
        exit 1
    else
        log_success "All quality gates PASSED"
        exit 0
    fi
}

main "$@"

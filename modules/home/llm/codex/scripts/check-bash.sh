#!/usr/bin/env bash

# Script: check-bash.sh
# Description: Validates bash scripts follow skill conventions
# Usage: check-bash.sh [directory]

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

target_dir="."
verbose=false
skip_shellcheck=false

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [DIRECTORY]

Validates bash scripts follow the conventions from the Bash skill:
- Proper shebang (#!/usr/bin/env bash)
- set -euo pipefail for error handling
- ShellCheck validation (if available)

OPTIONS:
    -h, --help          Show this help message
    -v, --verbose       Show all files being checked
    --no-shellcheck     Skip shellcheck validation

ARGUMENTS:
    DIRECTORY           Directory to check (default: current directory)

CHECKS PERFORMED:
    1. Shebang line exists and is correct
    2. 'set -euo pipefail' is present (or similar)
    3. ShellCheck passes without warnings

EXAMPLES:
    ${SCRIPT_NAME}                    # Check current directory
    ${SCRIPT_NAME} ./scripts          # Check specific directory
    ${SCRIPT_NAME} --verbose          # Show all files being checked
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

# Get list of bash scripts
get_scripts() {
    local dir="$1"

    # Find by extension
    find "$dir" -type f \( -name "*.sh" -o -name "*.bash" \) \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        2>/dev/null || true

    # Also find scripts by shebang (no extension)
    find "$dir" -type f -executable \
        -not -path "*/.git/*" \
        -not -path "*/node_modules/*" \
        -not -path "*/vendor/*" \
        -exec sh -c 'head -1 "$1" 2>/dev/null | grep -q "^#!.*bash" && echo "$1"' _ {} \; \
        2>/dev/null || true
}

# Check shebang
check_shebang() {
    local file="$1"
    local first_line

    first_line="$(head -1 "$file" 2>/dev/null || true)"

    # Valid shebangs
    if [[ "$first_line" == "#!/usr/bin/env bash" ]] || \
       [[ "$first_line" == "#!/bin/bash" ]] || \
       [[ "$first_line" == "#!/usr/bin/bash" ]]; then
        return 0
    fi

    # Warn if using sh instead of bash
    if [[ "$first_line" == "#!/bin/sh" ]] || \
       [[ "$first_line" == "#!/usr/bin/env sh" ]]; then
        log_warn "  Using sh instead of bash: $first_line"
        return 0  # Not an error, just a warning
    fi

    # No shebang or invalid
    if [[ ! "$first_line" =~ ^#! ]]; then
        log_error "  Missing shebang"
        return 1
    fi

    log_error "  Non-standard shebang: $first_line"
    log_info "  Recommended: #!/usr/bin/env bash"
    return 1
}

# Check for set -euo pipefail or equivalent
check_error_handling() {
    local file="$1"

    # Look for set commands in first 30 lines
    local header
    header="$(head -30 "$file" 2>/dev/null || true)"

    # Check for the complete set
    if echo "$header" | grep -q 'set -euo pipefail'; then
        return 0
    fi

    # Check for equivalent combinations
    local has_e=false
    local has_u=false
    local has_pipefail=false

    if echo "$header" | grep -qE 'set\s+.*-.*e' || \
       echo "$header" | grep -q 'set -e'; then
        has_e=true
    fi

    if echo "$header" | grep -qE 'set\s+.*-.*u' || \
       echo "$header" | grep -q 'set -u'; then
        has_u=true
    fi

    if echo "$header" | grep -q 'set -o pipefail'; then
        has_pipefail=true
    fi

    if $has_e && $has_u && $has_pipefail; then
        return 0
    fi

    # Report what's missing
    local missing=()
    if ! $has_e; then
        missing+=("-e (exit on error)")
    fi
    if ! $has_u; then
        missing+=("-u (exit on undefined variable)")
    fi
    if ! $has_pipefail; then
        missing+=("-o pipefail (exit on pipe failure)")
    fi

    log_error "  Missing error handling: ${missing[*]}"
    log_info "  Add: set -euo pipefail"
    return 1
}

# Run shellcheck
run_shellcheck() {
    local file="$1"

    if ! command -v shellcheck &> /dev/null; then
        return 0  # Skip if not available
    fi

    local output
    if ! output=$(shellcheck -f gcc "$file" 2>&1); then
        log_error "  ShellCheck issues:"
        echo "$output" | while IFS= read -r line; do
            echo "    $line"
        done
        return 1
    fi

    return 0
}

# Check a single script
check_script() {
    local file="$1"
    local failed=false

    if $verbose; then
        log_info "Checking: $file"
    fi

    echo -e "\n${BLUE}File:${NC} $file"

    # Check shebang
    if ! check_shebang "$file"; then
        failed=true
    fi

    # Check error handling
    if ! check_error_handling "$file"; then
        failed=true
    fi

    # Run shellcheck
    if ! $skip_shellcheck; then
        if ! run_shellcheck "$file"; then
            failed=true
        fi
    fi

    if $failed; then
        return 1
    fi

    log_success "  All checks passed"
    return 0
}

main() {
    local failed_files=()
    local total_files=0

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                usage
                exit 0
                ;;
            -v|--verbose)
                verbose=true
                shift
                ;;
            --no-shellcheck)
                skip_shellcheck=true
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
    log_info "Checking bash scripts in: $target_dir"

    # Check if shellcheck is available
    if ! command -v shellcheck &> /dev/null; then
        log_warn "shellcheck not found - skipping lint checks"
        log_info "Install shellcheck for complete validation"
        skip_shellcheck=true
    fi

    # Get and check scripts
    local scripts
    scripts="$(get_scripts "$target_dir" | sort -u)"

    if [[ -z "$scripts" ]]; then
        log_warn "No bash scripts found"
        exit 0
    fi

    while IFS= read -r script; do
        [[ -z "$script" ]] && continue
        [[ ! -f "$script" ]] && continue

        ((total_files++)) || true

        if ! check_script "$script"; then
            failed_files+=("$script")
        fi
    done <<< "$scripts"

    echo ""

    # Summary
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        log_error "Found issues in ${#failed_files[@]}/${total_files} script(s)"
        echo ""
        echo "Scripts with issues:"
        for f in "${failed_files[@]}"; do
            echo "  - $f"
        done
        echo ""
        echo "Requirements from Bash skill:"
        echo "  1. Use shebang: #!/usr/bin/env bash"
        echo "  2. Use: set -euo pipefail"
        echo "  3. Pass shellcheck with no warnings"
        exit 1
    else
        log_success "All $total_files bash script(s) passed validation"
        exit 0
    fi
}

main "$@"

#!/usr/bin/env bash

# Script: check-no-emojis.sh
# Description: Validates that source files contain no emojis (per skill requirements)
# Usage: check-no-emojis.sh [directory]

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
git_staged_only=false

usage() {
    cat <<EOF
Usage: ${SCRIPT_NAME} [OPTIONS] [DIRECTORY]

Validates that source files contain no emojis. This enforces the "no emojis"
requirement from the Go, Node.js, and Bash skills.

Note: Nerd Font icons (Private Use Area) are allowed and encouraged.

OPTIONS:
    -h, --help      Show this help message
    -v, --verbose   Show all files being checked
    -s, --staged    Only check git staged files

ARGUMENTS:
    DIRECTORY       Directory to check (default: current directory)

FILE TYPES CHECKED:
    .go, .js, .ts, .jsx, .tsx, .py, .rs, .sh, .bash, .nix, .md

EXAMPLES:
    ${SCRIPT_NAME}                    # Check current directory
    ${SCRIPT_NAME} ./src              # Check specific directory
    ${SCRIPT_NAME} --staged           # Check only git staged files
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

# Common emoji ranges in Unicode
# This regex catches most common emojis while excluding Nerd Font icons
# Nerd Font icons are typically in Private Use Area: E000-F8FF, F0000-FFFFF
get_emoji_pattern() {
    # Common emoji ranges (excluding Private Use Area for Nerd Fonts):
    # - Emoticons: 1F600-1F64F
    # - Misc Symbols: 1F300-1F5FF
    # - Transport/Map: 1F680-1F6FF
    # - Flags: 1F1E0-1F1FF
    # - Supplemental Symbols: 1F900-1F9FF
    # - Chess/cards: 1FA00-1FA6F
    # - Dingbats: 2700-27BF
    # - Misc Symbols: 2600-26FF
    # - Arrows: 2190-21FF (some emoji arrows)
    # - Various: 2300-23FF
    # - Enclosed Alphanumerics: 24C2, 1F170-1F251
    #
    # We use grep -P for Perl regex with Unicode support
    echo '[\x{1F600}-\x{1F64F}]|[\x{1F300}-\x{1F5FF}]|[\x{1F680}-\x{1F6FF}]|[\x{1F1E0}-\x{1F1FF}]|[\x{1F900}-\x{1F9FF}]|[\x{1FA00}-\x{1FA6F}]|[\x{2700}-\x{27BF}]|[\x{2600}-\x{26FF}]|[\x{23E9}-\x{23F3}]|[\x{231A}-\x{231B}]|[\x{25AA}-\x{25AB}]|[\x{25B6}]|[\x{25C0}]|[\x{25FB}-\x{25FE}]|[\x{2614}-\x{2615}]|[\x{2648}-\x{2653}]|[\x{267F}]|[\x{2693}]|[\x{26A1}]|[\x{26AA}-\x{26AB}]|[\x{26BD}-\x{26BE}]|[\x{26C4}-\x{26C5}]|[\x{26CE}]|[\x{26D4}]|[\x{26EA}]|[\x{26F2}-\x{26F3}]|[\x{26F5}]|[\x{26FA}]|[\x{26FD}]|[\x{2702}]|[\x{2705}]|[\x{2708}-\x{270D}]|[\x{270F}]|[\x{2712}]|[\x{2714}]|[\x{2716}]|[\x{271D}]|[\x{2721}]|[\x{2728}]|[\x{2733}-\x{2734}]|[\x{2744}]|[\x{2747}]|[\x{274C}]|[\x{274E}]|[\x{2753}-\x{2755}]|[\x{2757}]|[\x{2763}-\x{2764}]|[\x{2795}-\x{2797}]|[\x{27A1}]|[\x{27B0}]|[\x{27BF}]|[\x{2934}-\x{2935}]|[\x{2B05}-\x{2B07}]|[\x{2B1B}-\x{2B1C}]|[\x{2B50}]|[\x{2B55}]|[\x{3030}]|[\x{303D}]|[\x{3297}]|[\x{3299}]'
}

# Get list of files to check
get_files() {
    local dir="$1"

    if $git_staged_only; then
        # Only git staged files
        git diff --cached --name-only --diff-filter=ACM 2>/dev/null | \
            grep -E '\.(go|js|ts|jsx|tsx|py|rs|sh|bash|nix|md)$' || true
    else
        # All matching files in directory
        find "$dir" -type f \( \
            -name "*.go" -o \
            -name "*.js" -o \
            -name "*.ts" -o \
            -name "*.jsx" -o \
            -name "*.tsx" -o \
            -name "*.py" -o \
            -name "*.rs" -o \
            -name "*.sh" -o \
            -name "*.bash" -o \
            -name "*.nix" -o \
            -name "*.md" \
        \) \
        -not -path "*/node_modules/*" \
        -not -path "*/.git/*" \
        -not -path "*/vendor/*" \
        -not -path "*/dist/*" \
        -not -path "*/build/*" \
        -not -path "*/__pycache__/*" \
        2>/dev/null || true
    fi
}

# Check a single file for emojis
check_file() {
    local file="$1"
    local emoji_pattern
    emoji_pattern="$(get_emoji_pattern)"

    if $verbose; then
        log_info "Checking: $file"
    fi

    # Use grep -P for Perl regex with Unicode support
    # Returns matches with line numbers
    local matches
    if command -v grep &> /dev/null; then
        # Try GNU grep with -P (Perl regex)
        if grep -P --version &> /dev/null 2>&1; then
            matches=$(grep -Pn "$emoji_pattern" "$file" 2>/dev/null || true)
        else
            # Fallback: use a simpler approach with common emoji bytes
            # This catches common emojis but may miss some edge cases
            matches=$(grep -n $'[\xF0\x9F]' "$file" 2>/dev/null || true)
        fi
    fi

    if [[ -n "$matches" ]]; then
        echo "$file"
        echo "$matches" | while IFS= read -r line; do
            echo "  $line"
        done
        return 1
    fi

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
            -s|--staged)
                git_staged_only=true
                shift
                ;;
            *)
                target_dir="$1"
                shift
                ;;
        esac
    done

    # Validate directory (unless checking staged only)
    if ! $git_staged_only && [[ ! -d "$target_dir" ]]; then
        log_error "Directory not found: $target_dir"
        exit 1
    fi

    if $git_staged_only; then
        log_info "Checking git staged files for emojis..."
    else
        target_dir="$(cd "$target_dir" && pwd)"
        log_info "Checking for emojis in: $target_dir"
    fi

    # Get and check files
    local files
    files="$(get_files "$target_dir")"

    if [[ -z "$files" ]]; then
        log_warn "No matching files found"
        exit 0
    fi

    while IFS= read -r file; do
        [[ -z "$file" ]] && continue
        [[ ! -f "$file" ]] && continue

        ((total_files++)) || true

        if ! check_file "$file"; then
            failed_files+=("$file")
        fi
    done <<< "$files"

    echo ""

    # Summary
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        log_error "Found emojis in ${#failed_files[@]} file(s)"
        echo ""
        echo "Files with emojis:"
        for f in "${failed_files[@]}"; do
            echo "  - $f"
        done
        echo ""
        echo "Note: Use Nerd Font icons instead of emojis"
        echo "      Examples: , , , , "
        exit 1
    else
        log_success "No emojis found in $total_files file(s)"
        exit 0
    fi
}

main "$@"

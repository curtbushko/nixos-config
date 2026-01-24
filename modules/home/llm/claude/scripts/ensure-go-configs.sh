#!/usr/bin/env bash

# Script: ensure-go-configs.sh
# Description: Ensures Go projects under github.com/curtbushko/* have required config files
# Usage: Called by Claude Code hooks or manually

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SKILLS_DIR="${SCRIPT_DIR}/../skills/golang/references"

# Nerd Font icons
readonly ICON_CHECK=''
readonly ICON_ADD=''
readonly ICON_INFO=''

# Colors
readonly GREEN='\033[0;32m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

log_info() {
    echo -e "${BLUE}${ICON_INFO}${NC} $*" >&2
}

log_added() {
    echo -e "${GREEN}${ICON_ADD}${NC} $*" >&2
}

log_exists() {
    echo -e "${GREEN}${ICON_CHECK}${NC} $*" >&2
}

# Check if directory is a curtbushko Go repo
is_curtbushko_go_repo() {
    local dir="$1"

    # Must have go.mod
    if [[ ! -f "${dir}/go.mod" ]]; then
        return 1
    fi

    # Check if module path contains github.com/curtbushko
    if grep -q 'module github.com/curtbushko' "${dir}/go.mod" 2>/dev/null; then
        return 0
    fi

    # Also check if we're in a subdirectory of a curtbushko repo
    if [[ "$dir" == *"github.com/curtbushko"* ]]; then
        return 0
    fi

    return 1
}

# Ensure config file exists, copy from template if not
ensure_config() {
    local target_dir="$1"
    local config_name="$2"
    local template_name="$3"

    local target_file="${target_dir}/${config_name}"
    local template_file="${SKILLS_DIR}/${template_name}"

    if [[ -f "$target_file" ]]; then
        log_exists "$config_name already exists"
        return 0
    fi

    if [[ ! -f "$template_file" ]]; then
        log_info "Template not found: $template_file"
        return 1
    fi

    cp "$template_file" "$target_file"
    log_added "Added $config_name from template"

    # If golangci.yml, update the local-prefixes
    if [[ "$config_name" == ".golangci.yml" ]]; then
        # Extract module name from go.mod
        local module_name
        module_name=$(grep '^module ' "${target_dir}/go.mod" | awk '{print $2}')
        if [[ -n "$module_name" ]]; then
            # Update local-prefixes in the config
            if command -v sed &> /dev/null; then
                sed -i "s|local-prefixes: github.com/curtbushko|local-prefixes: ${module_name}|g" "$target_file" 2>/dev/null || true
            fi
        fi
    fi

    return 0
}

main() {
    local target_dir="${1:-.}"

    # Resolve to absolute path
    target_dir="$(cd "$target_dir" && pwd)"

    # Check if this is a curtbushko Go repo
    if ! is_curtbushko_go_repo "$target_dir"; then
        # Not a curtbushko Go repo, exit silently
        exit 0
    fi

    log_info "Detected curtbushko Go repo: $target_dir"

    # Ensure required configs exist
    ensure_config "$target_dir" ".golangci.yml" "golangci.yml"
    ensure_config "$target_dir" ".go-arch-lint.yml" "go-arch-lint.yml"

    exit 0
}

# If called directly (not sourced)
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi

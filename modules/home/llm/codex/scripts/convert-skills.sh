#!/usr/bin/env bash

# Script: convert-skills.sh
# Description: Convert Claude skills (SKILL.md) to Codex format (AGENTS.md)
# Usage: convert-skills.sh <claude-skills-dir> <codex-skills-dir>

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPT_DIR

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

# Strip YAML frontmatter from markdown file
strip_frontmatter() {
    local file="$1"
    local in_frontmatter=0
    local frontmatter_count=0

    while IFS= read -r line; do
        if [[ "$line" == "---" ]]; then
            ((frontmatter_count++))
            if [[ $frontmatter_count -eq 1 ]]; then
                in_frontmatter=1
                continue
            elif [[ $frontmatter_count -eq 2 ]]; then
                in_frontmatter=0
                continue
            fi
        fi

        if [[ $in_frontmatter -eq 0 ]] && [[ $frontmatter_count -ge 2 || $frontmatter_count -eq 0 ]]; then
            echo "$line"
        fi
    done < "$file"
}

convert_skill() {
    local skill_name="$1"
    local claude_dir="$2"
    local codex_dir="$3"

    local skill_md="${claude_dir}/${skill_name}/SKILL.md"

    if [[ ! -f "$skill_md" ]]; then
        log_warn "Skill file not found: $skill_md"
        return 1
    fi

    # Create codex skill directory
    local codex_skill_dir="${codex_dir}/${skill_name}"
    mkdir -p "$codex_skill_dir"

    # Convert SKILL.md to AGENTS.md
    local agents_md="${codex_skill_dir}/AGENTS.md"
    log_info "Converting $skill_name..."

    strip_frontmatter "$skill_md" > "$agents_md"

    log_info "Created $agents_md"

    # Copy references directory if it exists
    if [[ -d "${claude_dir}/${skill_name}/references" ]]; then
        cp -r "${claude_dir}/${skill_name}/references" "$codex_skill_dir/"
        log_info "Copied references for $skill_name"
    fi
}

main() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: $0 <claude-skills-dir> <codex-skills-dir>"
        exit 1
    fi

    local claude_dir="$1"
    local codex_dir="$2"

    if [[ ! -d "$claude_dir" ]]; then
        log_error "Claude skills directory not found: $claude_dir"
        exit 1
    fi

    mkdir -p "$codex_dir"

    # List of skills to convert (excluding already converted ones)
    local skills=(
        "go-code-review"
        "go-project-planning"
        "go-team"
        "node-team"
        "zig-team"
        "godot"
        "godot-csharp"
        "helios-design"
        "minecraft-mods"
        "prd"
        "rfc"
        "skill-creation"
        "start-project"
        "to-phases"
        "to-prd"
        "grill-me"
    )

    for skill in "${skills[@]}"; do
        if [[ -d "${codex_dir}/${skill}" ]]; then
            log_warn "Skipping $skill (already exists)"
            continue
        fi
        convert_skill "$skill" "$claude_dir" "$codex_dir" || log_error "Failed to convert $skill"
    done

    log_info "Conversion complete!"
}

main "$@"

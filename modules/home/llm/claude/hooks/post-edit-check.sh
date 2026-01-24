#!/usr/bin/env bash

# Hook: post-edit-check.sh
# Description: Claude Code PostToolUse hook to validate edited files
# Usage: Called automatically by Claude Code after Write/Edit operations

set -euo pipefail

readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly SCRIPTS_DIR="${SCRIPT_DIR}/../scripts"

# Read hook input from stdin
INPUT=$(cat)

# Extract file path from tool input
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ -z "$FILE_PATH" ]] || [[ ! -f "$FILE_PATH" ]]; then
    exit 0
fi

# Get file extension
EXT="${FILE_PATH##*.}"

# Check based on file type
case "$EXT" in
    sh|bash)
        # Validate bash script conventions
        if [[ -x "${SCRIPTS_DIR}/check-bash.sh" ]]; then
            if ! "${SCRIPTS_DIR}/check-bash.sh" "$(dirname "$FILE_PATH")" 2>&1 | grep -q "passed"; then
                echo "Warning: Bash script may not follow conventions" >&2
            fi
        fi
        ;;
    go|js|ts|jsx|tsx|py|rs|nix|md)
        # Check for emojis
        if grep -P '[\x{1F600}-\x{1F64F}\x{1F300}-\x{1F5FF}\x{1F680}-\x{1F6FF}\x{2600}-\x{26FF}]' "$FILE_PATH" 2>/dev/null; then
            echo "Warning: File contains emojis - use Nerd Font icons instead" >&2
        fi
        ;;
esac

exit 0

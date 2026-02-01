#!/usr/bin/env bash
# SessionStart hook - Injects skill awareness and TDD workflow reminders
# Triggers on: startup, resume, clear, compact

set -euo pipefail

# Determine skills directory
SKILLS_DIR="${HOME}/.claude/skills"

# Build list of available skills
skills_list=""
if [ -d "$SKILLS_DIR" ]; then
    for skill_dir in "$SKILLS_DIR"/*/; do
        if [ -d "$skill_dir" ]; then
            skill_name=$(basename "$skill_dir")
            skills_list="${skills_list}- ${skill_name}\n"
        fi
    done
fi

# Escape outputs for JSON using pure bash
escape_for_json() {
    local input="$1"
    local output=""
    local i char
    for (( i=0; i<${#input}; i++ )); do
        char="${input:$i:1}"
        case "$char" in
            '\'*) output+='\\';;
            '"') output+='\"';;
            $'\n') output+='\n';;
            $'\r') output+='\r';;
            $'\t') output+='\t';;
            *) output+="$char";;
        esac
    done
    printf '%s' "$output"
}

# Build the context message
context_message="## Available Skills

Check ~/.claude/skills/ for detailed guidance on:
${skills_list}
**IMPORTANT**: Before writing ANY code, read the relevant skill file(s) for the language/framework you're using.

## TDD Workflow Reminder

You MUST follow the 6-step TDD workflow for ALL code changes:

1. **INVESTIGATE** - Understand requirements, review existing code
2. **PLAN** - Design interface/API, identify test cases
3. **TEST (RED)** - Write failing tests FIRST
4. **IMPLEMENT (GREEN)** - Write MINIMAL code to pass
5. **VALIDATE** - Run all tests, check coverage, lint
6. **REFACTOR** - Clean up, ensure tests still pass

**Never write implementation code before writing a test.**

## Quality Gates

Before completing any task:
- [ ] Tests pass
- [ ] Build succeeds
- [ ] Lint clean
- [ ] No emojis (use Nerd Font icons)

## Code Style

- Use Nerd Font icons instead of emojis
- Follow hexagonal architecture for Go projects
- Follow language-specific conventions from skills"

escaped_context=$(escape_for_json "$context_message")

# Output context injection as JSON
cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": "<session-guidance>\n${escaped_context}\n</session-guidance>"
  }
}
EOF

exit 0

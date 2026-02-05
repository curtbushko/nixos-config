#!/usr/bin/env bash
#
# BDD Feature Planner - Interactive Gherkin specification creator
#
# Usage: planner.sh [output_file]
#        Default output: PLAN.md
#
# Modes:
#   - Create: If file doesn't exist, create new feature
#   - Append: If file exists, add scenarios to existing feature
#

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m' # No Color

# Output file
OUTPUT_FILE="${1:-PLAN.md}"

# State variables for append mode
EXISTING_FEATURE=""
EXISTING_USER_STORY=""
EXISTING_BACKGROUND=""
EXISTING_SCENARIOS=()
EXISTING_NOTES=""

# Print colored output
print_header() {
    echo ""
    echo -e "${BOLD}${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BOLD}${BLUE}║${NC}  ${BOLD}${CYAN}$1${NC}"
    echo -e "${BOLD}${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
    echo ""
}

print_section() {
    echo ""
    echo -e "${BOLD}${MAGENTA}┌─── $1 ───${NC}"
}

print_success() {
    echo -e "${BOLD}${GREEN}✓ $1${NC}"
}

print_warning() {
    echo -e "${BOLD}${YELLOW}⚠ $1${NC}"
}

print_error() {
    echo -e "${BOLD}${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${DIM}$1${NC}"
}

# Prompt for input with a label
prompt() {
    local label="$1"
    local result
    echo -en "${BOLD}${GREEN}▸${NC} ${BOLD}${label}${NC}: ${CYAN}"
    read -r result
    echo -en "${NC}"
    echo "$result"
}

# Prompt for optional input
prompt_optional() {
    local label="$1"
    local result
    echo -en "${BOLD}${YELLOW}▸${NC} ${label} ${DIM}(Enter to skip)${NC}: ${CYAN}"
    read -r result
    echo -en "${NC}"
    echo "$result"
}

# Collect multiple steps until empty input
collect_steps() {
    local step_type="$1"
    local color="$2"
    local steps=()
    local step
    local count=1

    while true; do
        echo -en "${BOLD}${color}▸${NC} ${step_type} ${DIM}#${count}${NC} ${DIM}(empty to finish)${NC}: ${CYAN}"
        read -r step
        echo -en "${NC}"
        if [[ -z "$step" ]]; then
            break
        fi
        steps+=("$step")
        ((count++))
    done

    # Return steps joined by newline
    if [[ ${#steps[@]} -gt 0 ]]; then
        printf '%s\n' "${steps[@]}"
    fi
}

# Show a mini preview of collected steps
show_steps_preview() {
    local label="$1"
    local steps="$2"
    local color="$3"

    if [[ -n "$steps" ]]; then
        local count=$(echo "$steps" | grep -c '^' || true)
        echo -e "  ${color}└─${NC} ${DIM}${count} ${label} step(s) added${NC}"
    fi
}

# Parse existing PLAN.md file
parse_existing_file() {
    local file="$1"
    local current_section=""
    local current_scenario_name=""
    local current_given=""
    local current_when=""
    local current_then=""
    local in_scenario=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        # Feature line
        if [[ "$line" =~ ^Feature:[[:space:]]*(.*) ]]; then
            EXISTING_FEATURE="${BASH_REMATCH[1]}"
            continue
        fi

        # User story lines
        if [[ "$line" =~ ^[[:space:]]*As\ a[[:space:]]+(.*) ]]; then
            EXISTING_USER_STORY+="As a ${BASH_REMATCH[1]}"$'\n'
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*I\ want[[:space:]]+(.*) ]]; then
            EXISTING_USER_STORY+="I want ${BASH_REMATCH[1]}"$'\n'
            continue
        fi
        if [[ "$line" =~ ^[[:space:]]*So\ that[[:space:]]+(.*) ]]; then
            EXISTING_USER_STORY+="So that ${BASH_REMATCH[1]}"$'\n'
            continue
        fi

        # Background section
        if [[ "$line" =~ ^[[:space:]]*Background: ]]; then
            current_section="background"
            continue
        fi

        # Scenario section
        if [[ "$line" =~ ^[[:space:]]*Scenario:[[:space:]]*(.*) ]]; then
            # Save previous scenario if exists
            if [[ -n "$current_scenario_name" ]]; then
                EXISTING_SCENARIOS+=("${current_scenario_name}|${current_given}|${current_when}|${current_then}")
            fi
            current_scenario_name="${BASH_REMATCH[1]}"
            current_given=""
            current_when=""
            current_then=""
            current_section="scenario"
            in_scenario=true
            continue
        fi

        # Notes
        if [[ "$line" =~ ^[[:space:]]*#[[:space:]]*Note:[[:space:]]*(.*) ]]; then
            EXISTING_NOTES+="${BASH_REMATCH[1]}"$'\n'
            continue
        fi

        # Given/When/Then/And steps
        if [[ "$current_section" == "background" ]]; then
            if [[ "$line" =~ ^[[:space:]]*(Given|And)[[:space:]]+(.*) ]]; then
                EXISTING_BACKGROUND+="${BASH_REMATCH[2]}"$'\n'
            fi
        elif [[ "$current_section" == "scenario" ]]; then
            if [[ "$line" =~ ^[[:space:]]*Given[[:space:]]+(.*) ]]; then
                current_given+="${BASH_REMATCH[1]}"$'\n'
                current_section="given"
            elif [[ "$line" =~ ^[[:space:]]*When[[:space:]]+(.*) ]]; then
                current_when+="${BASH_REMATCH[1]}"$'\n'
                current_section="when"
            elif [[ "$line" =~ ^[[:space:]]*Then[[:space:]]+(.*) ]]; then
                current_then+="${BASH_REMATCH[1]}"$'\n'
                current_section="then"
            elif [[ "$line" =~ ^[[:space:]]*And[[:space:]]+(.*) ]]; then
                case "$current_section" in
                    given) current_given+="${BASH_REMATCH[1]}"$'\n' ;;
                    when) current_when+="${BASH_REMATCH[1]}"$'\n' ;;
                    then) current_then+="${BASH_REMATCH[1]}"$'\n' ;;
                esac
            fi
        elif [[ "$current_section" == "given" || "$current_section" == "when" || "$current_section" == "then" ]]; then
            if [[ "$line" =~ ^[[:space:]]*Given[[:space:]]+(.*) ]]; then
                current_given+="${BASH_REMATCH[1]}"$'\n'
                current_section="given"
            elif [[ "$line" =~ ^[[:space:]]*When[[:space:]]+(.*) ]]; then
                current_when+="${BASH_REMATCH[1]}"$'\n'
                current_section="when"
            elif [[ "$line" =~ ^[[:space:]]*Then[[:space:]]+(.*) ]]; then
                current_then+="${BASH_REMATCH[1]}"$'\n'
                current_section="then"
            elif [[ "$line" =~ ^[[:space:]]*And[[:space:]]+(.*) ]]; then
                case "$current_section" in
                    given) current_given+="${BASH_REMATCH[1]}"$'\n' ;;
                    when) current_when+="${BASH_REMATCH[1]}"$'\n' ;;
                    then) current_then+="${BASH_REMATCH[1]}"$'\n' ;;
                esac
            fi
        fi
    done < "$file"

    # Save last scenario
    if [[ -n "$current_scenario_name" ]]; then
        EXISTING_SCENARIOS+=("${current_scenario_name}|${current_given}|${current_when}|${current_then}")
    fi
}

# Display existing feature summary
show_existing_summary() {
    print_section "Existing Feature"

    echo -e "${BOLD}Feature:${NC} ${CYAN}${EXISTING_FEATURE}${NC}"

    if [[ -n "$EXISTING_USER_STORY" ]]; then
        echo -e "${DIM}$(echo "$EXISTING_USER_STORY" | head -3 | sed 's/^/  /')${NC}"
    fi

    if [[ -n "$EXISTING_BACKGROUND" ]]; then
        local bg_count=$(echo "$EXISTING_BACKGROUND" | grep -c '^' || true)
        echo -e "${BLUE}Background:${NC} ${DIM}${bg_count} step(s)${NC}"
    fi

    echo ""
    echo -e "${BOLD}Existing Scenarios:${NC}"
    local i=1
    for scenario_data in "${EXISTING_SCENARIOS[@]}"; do
        IFS='|' read -r name given when then <<< "$scenario_data"
        local given_count=$(echo "$given" | grep -c '^' || true)
        local when_count=$(echo "$when" | grep -c '^' || true)
        local then_count=$(echo "$then" | grep -c '^' || true)
        echo -e "  ${MAGENTA}${i}.${NC} ${name}"
        echo -e "     ${DIM}Given:${given_count} When:${when_count} Then:${then_count}${NC}"
        ((i++))
    done

    if [[ -n "$EXISTING_NOTES" ]]; then
        local note_count=$(echo "$EXISTING_NOTES" | grep -c '^' || true)
        echo ""
        echo -e "${DIM}Notes: ${note_count} note(s)${NC}"
    fi
}

# Write the complete feature file
write_feature_file() {
    local feature_name="$1"
    local user_story="$2"
    local background="$3"
    local notes="$4"
    shift 4
    local scenarios=("$@")

    {
        echo "Feature: ${feature_name}"

        # User story
        if [[ -n "$user_story" ]]; then
            echo "$user_story" | while IFS= read -r line; do
                [[ -n "$line" ]] && echo "  ${line}"
            done
        fi

        echo ""

        # Background
        if [[ -n "$background" ]]; then
            echo "  Background:"
            first=true
            while IFS= read -r step; do
                [[ -z "$step" ]] && continue
                if $first; then
                    echo "    Given ${step}"
                    first=false
                else
                    echo "    And ${step}"
                fi
            done <<< "$background"
            echo ""
        fi

        # Scenarios
        for scenario_data in "${scenarios[@]}"; do
            IFS='|' read -r name given when then <<< "$scenario_data"

            echo "  Scenario: ${name}"

            # Given steps
            first=true
            while IFS= read -r step; do
                [[ -z "$step" ]] && continue
                if $first; then
                    echo "    Given ${step}"
                    first=false
                else
                    echo "    And ${step}"
                fi
            done <<< "$given"

            # When steps
            first=true
            while IFS= read -r step; do
                [[ -z "$step" ]] && continue
                if $first; then
                    echo "    When ${step}"
                    first=false
                else
                    echo "    And ${step}"
                fi
            done <<< "$when"

            # Then steps
            first=true
            while IFS= read -r step; do
                [[ -z "$step" ]] && continue
                if $first; then
                    echo "    Then ${step}"
                    first=false
                else
                    echo "    And ${step}"
                fi
            done <<< "$then"

            echo ""
        done

        # Notes
        if [[ -n "$notes" ]]; then
            while IFS= read -r note; do
                [[ -z "$note" ]] && continue
                echo "  # Note: ${note}"
            done <<< "$notes"
        fi

    } > "$OUTPUT_FILE"
}

# Show syntax-highlighted preview
show_preview() {
    echo ""
    echo -e "${BOLD}${CYAN}Preview:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"

    while IFS= read -r line; do
        if [[ "$line" =~ ^Feature: ]]; then
            echo -e "${BOLD}${CYAN}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*As\ a ]]; then
            echo -e "${DIM}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*I\ want ]]; then
            echo -e "${DIM}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*So\ that ]]; then
            echo -e "${DIM}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*Background: ]]; then
            echo -e "${BOLD}${MAGENTA}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*Scenario: ]]; then
            echo -e "${BOLD}${MAGENTA}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*(Given|And)[[:space:]] ]] && [[ ! "$line" =~ When|Then ]]; then
            echo -e "${BLUE}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*When[[:space:]] ]]; then
            echo -e "${YELLOW}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*Then[[:space:]] ]]; then
            echo -e "${GREEN}${line}${NC}"
        elif [[ "$line" =~ ^[[:space:]]*#.*Note: ]]; then
            echo -e "${DIM}${line}${NC}"
        else
            echo "$line"
        fi
    done < <(head -50 "$OUTPUT_FILE")

    line_count=$(wc -l < "$OUTPUT_FILE")
    if [[ $line_count -gt 50 ]]; then
        echo -e "${DIM}...${NC}"
        echo -e "${DIM}(${line_count} total lines)${NC}"
    fi

    echo -e "${DIM}────────────────────────────────────────${NC}"
}

# Collect new scenarios
collect_scenarios() {
    local start_num="${1:-1}"
    local scenarios=()
    local scenario_num=$start_num

    while true; do
        print_section "Scenario ${scenario_num}"

        scenario_name=$(prompt "Scenario name")
        if [[ -z "$scenario_name" ]]; then
            print_warning "Scenario name required. Try again."
            continue
        fi

        echo ""
        echo -e "${BOLD}${BLUE}Given${NC} ${DIM}(preconditions/context)${NC}"
        given_steps=$(collect_steps "Given" "${BLUE}")
        show_steps_preview "Given" "$given_steps" "${BLUE}"

        echo ""
        echo -e "${BOLD}${YELLOW}When${NC} ${DIM}(actions performed)${NC}"
        when_steps=$(collect_steps "When" "${YELLOW}")
        show_steps_preview "When" "$when_steps" "${YELLOW}"

        echo ""
        echo -e "${BOLD}${GREEN}Then${NC} ${DIM}(expected outcomes)${NC}"
        then_steps=$(collect_steps "Then" "${GREEN}")
        show_steps_preview "Then" "$then_steps" "${GREEN}"

        # Store scenario
        scenarios+=("${scenario_name}|${given_steps}|${when_steps}|${then_steps}")

        echo ""
        echo -en "${BOLD}${CYAN}▸${NC} Add another scenario? ${DIM}(y/n)${NC}: ${CYAN}"
        read -r add_more
        echo -en "${NC}"
        if [[ "$add_more" != "y" && "$add_more" != "Y" ]]; then
            break
        fi

        ((scenario_num++))
    done

    # Return scenarios
    printf '%s\n' "${scenarios[@]}"
}

# Append mode - add scenarios to existing file
append_mode() {
    print_header "BDD Feature Planner (Append Mode)"

    echo -e "${BOLD}File:${NC} ${CYAN}${OUTPUT_FILE}${NC}"

    # Parse existing file
    parse_existing_file "$OUTPUT_FILE"

    # Show summary
    show_existing_summary

    echo ""
    echo -en "${BOLD}${CYAN}▸${NC} Add new scenarios to this feature? ${DIM}(y/n)${NC}: ${CYAN}"
    read -r confirm
    echo -en "${NC}"

    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${DIM}Aborted.${NC}"
        exit 0
    fi

    # Collect new scenarios
    local start_num=$((${#EXISTING_SCENARIOS[@]} + 1))
    local new_scenarios_raw
    new_scenarios_raw=$(collect_scenarios "$start_num")

    # Parse new scenarios into array
    local new_scenarios=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && new_scenarios+=("$line")
    done <<< "$new_scenarios_raw"

    # Ask about adding notes
    print_section "Additional Notes ${DIM}(optional)${NC}"
    print_info "Add more implementation hints"
    local new_notes
    new_notes=$(collect_steps "Note" "${MAGENTA}")

    # Combine notes
    local combined_notes="$EXISTING_NOTES"
    if [[ -n "$new_notes" ]]; then
        combined_notes+="$new_notes"
    fi

    # Combine all scenarios
    local all_scenarios=("${EXISTING_SCENARIOS[@]}" "${new_scenarios[@]}")

    # Reconstruct user story for writing
    local user_story=""
    if [[ -n "$EXISTING_USER_STORY" ]]; then
        user_story="$EXISTING_USER_STORY"
    fi

    # Write the file
    print_section "Updating ${OUTPUT_FILE}"
    write_feature_file "$EXISTING_FEATURE" "$user_story" "$EXISTING_BACKGROUND" "$combined_notes" "${all_scenarios[@]}"

    echo ""
    print_success "Updated: ${OUTPUT_FILE}"
    print_success "Added ${#new_scenarios[@]} new scenario(s)"
    print_info "Total scenarios: ${#all_scenarios[@]}"

    show_preview

    echo ""
    echo -e "${GREEN}Ready to use with ${BOLD}/go-team${NC}${GREEN} or ${BOLD}/zig-team${NC}"
}

# Create mode - create new file
create_mode() {
    print_header "BDD Feature Planner (Create Mode)"

    echo -e "${BOLD}Output:${NC} ${CYAN}${OUTPUT_FILE}${NC}"

    # Feature name
    print_section "Feature Definition"
    feature_name=$(prompt "Feature name")

    if [[ -z "$feature_name" ]]; then
        print_error "Feature name is required!"
        exit 1
    fi

    # User story (optional)
    print_section "User Story ${DIM}(optional)${NC}"
    print_info "Describe WHO wants WHAT and WHY"
    as_a=$(prompt_optional "As a")
    i_want=$(prompt_optional "I want")
    so_that=$(prompt_optional "So that")

    # Build user story string
    local user_story=""
    [[ -n "$as_a" ]] && user_story+="As a ${as_a}"$'\n'
    [[ -n "$i_want" ]] && user_story+="I want ${i_want}"$'\n'
    [[ -n "$so_that" ]] && user_story+="So that ${so_that}"$'\n'

    # Background (optional)
    print_section "Background ${DIM}(optional)${NC}"
    print_info "Steps that run before EACH scenario"
    background_steps=$(collect_steps "Given" "${BLUE}")
    show_steps_preview "background" "$background_steps" "${BLUE}"

    # Collect scenarios
    local scenarios_raw
    scenarios_raw=$(collect_scenarios 1)

    # Parse scenarios into array
    local scenarios=()
    while IFS= read -r line; do
        [[ -n "$line" ]] && scenarios+=("$line")
    done <<< "$scenarios_raw"

    # Notes (optional)
    print_section "Implementation Notes ${DIM}(optional)${NC}"
    print_info "Hints for the developer implementing this feature"
    notes=$(collect_steps "Note" "${MAGENTA}")
    show_steps_preview "note" "$notes" "${MAGENTA}"

    # Write the file
    print_section "Generating ${OUTPUT_FILE}"
    write_feature_file "$feature_name" "$user_story" "$background_steps" "$notes" "${scenarios[@]}"

    echo ""
    print_success "Created: ${OUTPUT_FILE}"

    show_preview

    echo ""
    echo -e "${GREEN}Ready to use with ${BOLD}/go-team${NC}${GREEN} or ${BOLD}/zig-team${NC}"
}

# Main script
main() {
    # Check if file exists
    if [[ -f "$OUTPUT_FILE" ]]; then
        # File exists - append mode
        append_mode
    else
        # File doesn't exist - create mode
        create_mode
    fi
}

main "$@"

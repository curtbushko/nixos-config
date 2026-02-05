#!/usr/bin/env bash
#
# BDD Feature Planner - Interactive Gherkin specification creator
#
# Usage: planner.sh [output_file]
#        Default output: PLAN.md
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

# Main script
main() {
    print_header "BDD Feature Planner"

    echo -e "${BOLD}Output:${NC} ${CYAN}${OUTPUT_FILE}${NC}"

    # Check if file exists
    if [[ -f "$OUTPUT_FILE" ]]; then
        print_warning "File already exists: ${OUTPUT_FILE}"
        echo -en "${BOLD}${YELLOW}▸${NC} Overwrite? ${DIM}(y/n)${NC}: ${CYAN}"
        read -r confirm
        echo -en "${NC}"
        if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
            echo -e "${DIM}Aborted.${NC}"
            exit 0
        fi
    fi

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

    # Background (optional)
    print_section "Background ${DIM}(optional)${NC}"
    print_info "Steps that run before EACH scenario"
    background_steps=$(collect_steps "Given" "${BLUE}")
    show_steps_preview "background" "$background_steps" "${BLUE}"

    # Scenarios
    scenarios=()
    scenario_num=1

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

    # Notes (optional)
    print_section "Implementation Notes ${DIM}(optional)${NC}"
    print_info "Hints for the developer implementing this feature"
    notes=$(collect_steps "Note" "${MAGENTA}")
    show_steps_preview "note" "$notes" "${MAGENTA}"

    # Generate the feature file
    print_section "Generating Feature File"

    {
        echo "Feature: ${feature_name}"

        # User story
        if [[ -n "$as_a" || -n "$i_want" || -n "$so_that" ]]; then
            [[ -n "$as_a" ]] && echo "  As a ${as_a}"
            [[ -n "$i_want" ]] && echo "  I want ${i_want}"
            [[ -n "$so_that" ]] && echo "  So that ${so_that}"
        fi

        echo ""

        # Background
        if [[ -n "$background_steps" ]]; then
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
            done <<< "$background_steps"
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

    echo ""
    print_success "Created: ${OUTPUT_FILE}"
    echo ""
    echo -e "${BOLD}${CYAN}Preview:${NC}"
    echo -e "${DIM}────────────────────────────────────────${NC}"

    # Syntax highlighted preview
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
    done < <(head -40 "$OUTPUT_FILE")

    line_count=$(wc -l < "$OUTPUT_FILE")
    if [[ $line_count -gt 40 ]]; then
        echo -e "${DIM}...${NC}"
        echo -e "${DIM}(${line_count} total lines)${NC}"
    fi

    echo -e "${DIM}────────────────────────────────────────${NC}"
    echo ""
    echo -e "${GREEN}Ready to use with ${BOLD}/go-team${NC}${GREEN} or ${BOLD}/zig-team${NC}"
}

main "$@"

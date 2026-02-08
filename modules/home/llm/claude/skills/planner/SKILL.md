---
name: planner
description: Interactive BDD feature planner. Creates or appends to PLAN.md with Gherkin scenarios through guided prompts.
arguments:
  - name: output
    description: Output file path
    default: "PLAN.md"
---

# Planner - BDD Feature Specification Creator

## Overview

The Planner skill helps you create and extend BDD-style feature specifications through an interactive prompt-based workflow. It automatically detects whether to create a new file or append to an existing one.

**Two Modes:**
- **Create Mode** - When the output file doesn't exist, creates new feature from scratch
- **Append Mode** - When the output file exists, parses it and adds new scenarios

## EXECUTION INSTRUCTIONS

When this skill is invoked via `/planner`:

### Step 1: Determine Mode

Check if the output file (default: `PLAN.md` in the current working directory) exists.
- If it does NOT exist, follow **Create Mode** below.
- If it DOES exist, follow **Append Mode** below.

---

### Create Mode

#### 1a. Prompt for Feature Definition

Use AskUserQuestion to ask:

**Question**: "What is the feature name?"
- Header: "Feature"
- This is REQUIRED. Do not proceed without a feature name.

#### 1b. Prompt for User Story (optional)

Ask the user for the user story using AskUserQuestion:

**Question**: "Describe the user story. Provide the role (As a...), capability (I want...), and benefit (So that...). Leave blank to skip."
- Header: "User Story"
- Options: "Provide user story", "Skip"

If the user chooses to provide a story, ask them to describe it in free text. Parse the response to extract:
- **As a** [role]
- **I want** [capability]
- **So that** [benefit]

If the user gives a natural language description instead of the exact format, convert it into the As a/I want/So that structure.

#### 1c. Prompt for Background (optional)

Ask the user:

**Question**: "Are there common setup steps that should run before EACH scenario (Background)?"
- Header: "Background"
- Options: "Add background steps", "Skip"

If they choose to add background steps, ask them to list the Given preconditions. Collect all steps.

#### 1d. Collect Scenarios (at least 1 required)

For each scenario, ask the user:

1. **Scenario name** - What is this scenario called?
2. **Given steps** - What are the preconditions/context? (collect multiple)
3. **When steps** - What actions are performed? (collect multiple)
4. **Then steps** - What are the expected outcomes? (collect multiple)

After each scenario, ask:

**Question**: "Add another scenario?"
- Header: "More?"
- Options: "Yes, add another", "No, done with scenarios"

Continue collecting scenarios until the user says they're done.

#### 1e. Prompt for Notes (optional)

Ask the user:

**Question**: "Any implementation notes or hints to include?"
- Header: "Notes"
- Options: "Add notes", "Skip"

If they choose to add notes, collect them.

#### 1f. Write the File

Generate the PLAN.md file using the Gherkin format below and write it with the Write tool.

---

### Append Mode

#### 2a. Parse and Display Existing Content

Read the existing output file. Parse and display a summary:

```
Existing Feature: {name}
  As a {role}
  I want {capability}
  So that {benefit}
Background: {N} step(s)

Existing Scenarios:
  1. {scenario_name}
     Given:{N} When:{N} Then:{N}
  2. {scenario_name}
     Given:{N} When:{N} Then:{N}

Notes: {N} note(s)
```

#### 2b. Confirm Append

Ask the user:

**Question**: "Add new scenarios to this feature?"
- Header: "Append"
- Options: "Yes, add scenarios", "No, cancel"

If they say no, stop.

#### 2c. Collect New Scenarios

Follow the same scenario collection flow as Create Mode step 1d, numbering scenarios starting from the next number after existing ones.

#### 2d. Prompt for Additional Notes (optional)

Same as Create Mode step 1e.

#### 2e. Rewrite the File

Preserve ALL existing content (feature, user story, background, existing scenarios, existing notes) and append the new scenarios and notes. Write the complete file using the Write tool.

---

## Output Format (Gherkin)

The generated file MUST follow this exact format:

```gherkin
Feature: {FEATURE_NAME}
  As a {ROLE}
  I want {CAPABILITY}
  So that {BENEFIT}

  Background:
    Given {COMMON_PRECONDITION}
    And {ADDITIONAL_COMMON_PRECONDITION}

  Scenario: {SCENARIO_NAME}
    Given {PRECONDITION}
    And {ADDITIONAL_PRECONDITION}
    When {ACTION}
    And {ADDITIONAL_ACTION}
    Then {OUTCOME}
    And {ADDITIONAL_OUTCOME}

  Scenario: {SCENARIO_NAME_2}
    Given {PRECONDITION}
    When {ACTION}
    Then {OUTCOME}

  # Note: {IMPLEMENTATION_HINT}
  # Note: {ANOTHER_HINT}
```

Rules:
- Feature line has NO leading indentation
- User story lines are indented 2 spaces
- Background, Scenario are indented 2 spaces
- Given/When/Then/And steps are indented 4 spaces
- First step of each type uses Given/When/Then, subsequent steps of the same type use And
- Notes use `# Note:` prefix, indented 2 spaces
- Blank line between sections
- Omit User Story section if not provided
- Omit Background section if not provided
- Omit Notes section if not provided

## Compatibility

The generated file follows standard Gherkin syntax compatible with:
- go-team skill
- zig-team skill
- Cucumber/godog BDD runners

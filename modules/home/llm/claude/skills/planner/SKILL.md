---
name: planner
description: Interactive BDD feature planner. Creates PLAN.md with Gherkin scenarios through guided prompts.
arguments:
  - name: output
    description: Output file path
    default: "PLAN.md"
---

# Planner - BDD Feature Specification Creator

## Overview

The Planner skill helps you create BDD-style feature specifications through an interactive prompt-based workflow. It guides you through defining:

1. Feature name and user story
2. Background setup (common preconditions)
3. Scenarios with Given/When/Then steps

## Usage

### Run the Interactive Script

```bash
# Create PLAN.md in current directory
~/.claude/skills/planner/planner.sh

# Specify output file
~/.claude/skills/planner/planner.sh my-feature.feature

# Or use the skill invocation (runs the script)
/planner
/planner output="features/auth.feature"
```

## How It Works

The script will:

1. **Check for existing file** - Warns if PLAN.md already exists
2. **Prompt for Feature** - Name and user story (As a/I want/So that)
3. **Prompt for Background** - Optional common setup steps
4. **Loop for Scenarios** - Add scenarios with:
   - Scenario name
   - Given steps (preconditions)
   - When steps (actions)
   - Then steps (outcomes)
5. **Write PLAN.md** - Generates properly formatted Gherkin file

## Template

The script uses the template in `[[template.feature]]` as reference.

## Example Session

```
$ planner.sh

=== BDD Feature Planner ===

Output file: PLAN.md

--- Feature Definition ---
Feature name: User Authentication

--- User Story (optional, press Enter to skip) ---
As a: registered user
I want: to log in with my credentials
So that: I can access my account

--- Background (optional) ---
Add background steps that run before each scenario.
Background step (empty to finish): the authentication service is running
Background step (empty to finish):

--- Scenario 1 ---
Scenario name: Successful login with valid credentials

Given (empty to finish): I am on the login page
Given (empty to finish): I have a valid account with username "alice"
Given (empty to finish):

When (empty to finish): I enter username "alice" and password "secret123"
When (empty to finish): I click the login button
When (empty to finish):

Then (empty to finish): I should be redirected to the dashboard
Then (empty to finish): I should see "Welcome, Alice"
Then (empty to finish):

Add another scenario? (y/n): y

--- Scenario 2 ---
...

Created: PLAN.md
```

## Output Format

The generated file follows standard Gherkin syntax compatible with:
- go-team skill
- zig-team skill
- Cucumber/godog BDD runners

## EXECUTION INSTRUCTIONS

When this skill is invoked via `/planner`:

1. Run the script: `~/.claude/skills/planner/planner.sh {output}`
2. The script handles all interaction
3. Report the created file path when done

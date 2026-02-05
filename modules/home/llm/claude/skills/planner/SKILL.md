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
- **Create Mode** - When PLAN.md doesn't exist, creates new feature from scratch
- **Append Mode** - When PLAN.md exists, parses it and adds new scenarios

## Usage

### Run the Interactive Script

```bash
# Create new PLAN.md or append to existing one
~/.claude/skills/planner/planner.sh

# Specify output file
~/.claude/skills/planner/planner.sh my-feature.feature

# Or use the skill invocation (runs the script)
/planner
/planner output="features/auth.feature"
```

## Modes

### Create Mode (No Existing File)

When PLAN.md doesn't exist, the script:

1. **Prompt for Feature** - Name and user story (As a/I want/So that)
2. **Prompt for Background** - Optional common setup steps
3. **Loop for Scenarios** - Add scenarios with Given/When/Then
4. **Add Notes** - Optional implementation hints
5. **Write PLAN.md** - Generates properly formatted Gherkin file

### Append Mode (File Exists)

When PLAN.md already exists, the script:

1. **Parse existing file** - Extracts feature, user story, background, scenarios, notes
2. **Show summary** - Displays existing content with counts
3. **Confirm append** - Ask before modifying
4. **Add new scenarios** - Numbered from existing count + 1
5. **Add notes** - Optional additional implementation hints
6. **Rewrite file** - Preserves all existing content + new scenarios

**Append Mode Summary Display:**
```
┌─── Existing Feature ───
Feature: User Authentication
  As a registered user
  I want to log in
  So that I can access my account
Background: 2 step(s)

Existing Scenarios:
  1. Successful login
     Given:2 When:2 Then:2
  2. Invalid password
     Given:1 When:2 Then:2

Notes: 3 note(s)
```

## Template

The script uses the template in `[[template.feature]]` as reference.

## Example Sessions

### Create Mode Example

```
$ planner.sh

╔══════════════════════════════════════════════════════════╗
║  BDD Feature Planner (Create Mode)
╚══════════════════════════════════════════════════════════╝

Output: PLAN.md

┌─── Feature Definition ───
▸ Feature name: User Authentication

┌─── User Story (optional) ───
Describe WHO wants WHAT and WHY
▸ As a (Enter to skip): registered user
▸ I want (Enter to skip): to log in with my credentials
▸ So that (Enter to skip): I can access my account

┌─── Background (optional) ───
Steps that run before EACH scenario
▸ Given #1 (empty to finish): the authentication service is running
▸ Given #2 (empty to finish):
  └─ 1 background step(s) added

┌─── Scenario 1 ───
▸ Scenario name: Successful login with valid credentials

Given (preconditions/context)
▸ Given #1 (empty to finish): I am on the login page
▸ Given #2 (empty to finish): I have a valid account with username "alice"
▸ Given #3 (empty to finish):
  └─ 2 Given step(s) added

When (actions performed)
▸ When #1 (empty to finish): I enter username "alice" and password "secret123"
▸ When #2 (empty to finish): I click the login button
▸ When #3 (empty to finish):
  └─ 2 When step(s) added

Then (expected outcomes)
▸ Then #1 (empty to finish): I should be redirected to the dashboard
▸ Then #2 (empty to finish): I should see "Welcome, Alice"
▸ Then #3 (empty to finish):
  └─ 2 Then step(s) added

▸ Add another scenario? (y/n): n

✓ Created: PLAN.md
```

### Append Mode Example

```
$ planner.sh

╔══════════════════════════════════════════════════════════╗
║  BDD Feature Planner (Append Mode)
╚══════════════════════════════════════════════════════════╝

File: PLAN.md

┌─── Existing Feature ───
Feature: User Authentication
  As a registered user
  I want to log in with my credentials
  So that I can access my account
Background: 1 step(s)

Existing Scenarios:
  1. Successful login with valid credentials
     Given:2 When:2 Then:2

▸ Add new scenarios to this feature? (y/n): y

┌─── Scenario 2 ───
▸ Scenario name: Invalid password rejected

Given (preconditions/context)
▸ Given #1 (empty to finish): I am on the login page
▸ Given #2 (empty to finish):
  └─ 1 Given step(s) added

When (actions performed)
▸ When #1 (empty to finish): I enter username "alice" and wrong password
▸ When #2 (empty to finish):
  └─ 1 When step(s) added

Then (expected outcomes)
▸ Then #1 (empty to finish): I should see "Invalid credentials"
▸ Then #2 (empty to finish): I should remain on the login page
▸ Then #3 (empty to finish):
  └─ 2 Then step(s) added

▸ Add another scenario? (y/n): n

✓ Updated: PLAN.md
✓ Added 1 new scenario(s)
Total scenarios: 2
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

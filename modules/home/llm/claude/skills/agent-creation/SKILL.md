---
name: agent-creation
description: Use when creating Claude Code agents for automated tasks like code review, research, or workflow automation. Covers agent structure and prompt design.
---

# Agent Creation

## Core Principle

**Agents are specialized prompts that automate specific tasks.**

Agents leverage Claude's Task tool to dispatch focused subagents for review, research, or workflow tasks.

## Agent Location

Agents live in: `~/.claude/agents/<category>/<agent-name>.md`

## Directory Structure

```
agents/
  review/           # Code review agents
    code-quality-reviewer.md
    security-reviewer.md
    architecture-reviewer.md
  research/         # Research and exploration agents
    codebase-explorer.md
    documentation-researcher.md
  workflow/         # Workflow automation agents
    changelog-generator.md
    bug-validator.md
  docs/             # Documentation agents
    readme-generator.md
```

## Agent File Structure

```markdown
---
name: agent-name
description: [What this agent does and when to use it]
---

# Agent Name

## Purpose

[One paragraph on what this agent accomplishes]

## Dispatch Prompt

Use this prompt when dispatching via Task tool:

```
[The actual prompt to use when dispatching this agent]

Context:
- [What context to provide]

Check:
1. [First thing to check]
2. [Second thing to check]
...

Output:
[Expected output format]
```

## When to Use

[Specific situations that trigger this agent]

## Integration

[How this agent works with other agents or skills]
```

## Agent Design Principles

### 1. Single Responsibility

Each agent does ONE thing well:
- **Good:** "Reviews code for security vulnerabilities"
- **Bad:** "Reviews code for security, performance, and style"

### 2. Clear Output Format

Specify exactly what output to expect:

```
Output format:
## Findings
- [Issue]: [Location] - [Severity]

## Recommendations
1. [Specific action]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

### 3. Actionable Results

Agents should produce results that can be acted upon:
- Specific file paths and line numbers
- Clear severity levels
- Concrete recommendations

### 4. Context Requirements

Document what context the agent needs:

```
Required context:
- File paths to review
- Original requirements/spec
- Project conventions

Optional context:
- Related PRs or issues
- Performance baselines
```

## Agent Categories

### Review Agents

Purpose: Validate code quality, security, architecture

Examples:
- code-quality-reviewer
- security-reviewer
- architecture-reviewer
- test-coverage-reviewer

Output: Issues found, severity, recommendations, verdict

### Research Agents

Purpose: Gather information, explore codebase

Examples:
- codebase-explorer
- documentation-researcher
- dependency-analyzer

Output: Findings, relevant files, summaries

### Workflow Agents

Purpose: Automate development tasks

Examples:
- changelog-generator
- bug-validator
- release-manager

Output: Generated artifacts, validation results

## Customization for Your Setup

Agents should align with your existing patterns:

### For Go Projects
- Reference hexagonal architecture
- Check for proper error handling
- Verify interface usage

### For TDD Enforcement
- Verify tests exist and are meaningful
- Check test-first workflow was followed
- Validate coverage requirements

## Quick Checklist

- [ ] Single responsibility (one task)
- [ ] Clear dispatch prompt
- [ ] Specified output format
- [ ] Documented context requirements
- [ ] Actionable results
- [ ] Aligned with project conventions

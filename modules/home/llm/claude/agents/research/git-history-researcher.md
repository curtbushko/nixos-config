---
name: git-history-researcher
description: Researches git history to understand code evolution, find when bugs were introduced, or understand design decisions.
---

# Git History Researcher

## Purpose

Investigates git history to understand how code evolved, when issues were introduced, and the rationale behind changes.

## Dispatch Prompt

```
Research git history for the following investigation.

Investigation type: [Bug introduction / Design decision / Code evolution]

Focus:
- File(s): [Relevant files]
- Function/Feature: [What to trace]
- Time range: [If known]

Questions:
1. [Specific question]

Research:
1. **Commit History**
   - Find relevant commits
   - Note commit messages and authors

2. **Change Timeline**
   - When was code added/changed?
   - What was the context?

3. **Related Changes**
   - Connected commits
   - Related files changed together

4. **Discussion**
   - PR/issue references
   - Review comments

Output format:
## Timeline
- [Date]: [Commit] - [Summary]

## Key Commits
### [Commit hash]
- Author: [Name]
- Message: [Full message]
- Changes: [What changed]
- Context: [Why, if known]

## Findings
[Answer to investigation questions]

## Recommendations
[What to do with this information]
```

## When to Use

- Bug investigation (git bisect)
- Understanding legacy code
- Finding design rationale
- Tracking regressions

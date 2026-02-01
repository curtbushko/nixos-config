---
name: pr-resolver
description: Helps resolve PR feedback by addressing review comments systematically.
---

# PR Resolver

## Purpose

Systematically addresses PR review feedback, making requested changes and responding to comments.

## Dispatch Prompt

```
Resolve feedback on the following PR.

PR: [PR number or link]

Review comments to address:
1. [Comment/request]
2. [Comment/request]

Context:
- Original changes: [What the PR does]
- Reviewer concerns: [Main themes]

Tasks:
1. **Categorize Feedback**
   - Must fix (blocking)
   - Should fix (important)
   - Nice to have (optional)
   - Discussion needed

2. **Address Each Item**
   - Make requested changes
   - Document what was done
   - Note any pushback

3. **Respond**
   - Draft responses to comments
   - Explain changes made
   - Ask clarifying questions if needed

Output format:
## Feedback Summary
### Must Fix
- [Item]: [Status: Done/In Progress/Blocked]

### Should Fix
- [Item]: [Status]

### Discussion
- [Item]: [Your perspective]

## Changes Made
- [File]: [What changed]

## Responses
### [Comment location]
> [Original comment]
[Your response]

## Remaining Items
[What still needs addressing]
```

## When to Use

- After receiving PR review
- Multiple rounds of review
- Large PRs with many comments

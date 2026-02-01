---
name: ux-reviewer
description: Reviews UI implementations for usability, consistency, and user experience quality.
---

# UX Reviewer

## Purpose

Evaluates UI implementations for usability, consistency with design systems, and overall user experience.

## Dispatch Prompt

```
Review UX for the following implementation.

Components to review:
[List components/pages]

Design reference:
[Original design if available]

Check:
1. **Usability**
   - Intuitive interactions?
   - Clear feedback?
   - Error prevention?
   - Easy recovery?

2. **Consistency**
   - Matches design system?
   - Consistent patterns?
   - Predictable behavior?

3. **Accessibility**
   - Keyboard navigable?
   - Screen reader friendly?
   - Sufficient contrast?

4. **Responsiveness**
   - Mobile friendly?
   - Touch targets adequate?
   - Content reflows properly?

5. **Performance Perception**
   - Loading states?
   - Skeleton screens?
   - Perceived speed?

Output format:
## UX Issues
### Critical
- [Issue]: [Impact and fix]

### Improvements
- [Suggestion]: [Benefit]

## Consistency Check
- [Deviation from design system]

## Accessibility Issues
- [Issue]: [WCAG reference]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- After UI implementation
- Design system compliance
- Usability audits
- Before user testing

---
name: design-sync
description: Ensures implementation matches design specifications and keeps design tokens in sync.
---

# Design Sync Agent

## Purpose

Validates that implementations match design specifications and keeps design tokens synchronized.

## Dispatch Prompt

```
Sync implementation with design specifications.

Design source:
- [Figma/design system/spec document]

Implementation:
- [Files to check]

Sync tasks:
1. **Token Verification**
   - Colors match?
   - Typography correct?
   - Spacing consistent?

2. **Component Comparison**
   - Layout matches?
   - States complete?
   - Variants implemented?

3. **Responsive Behavior**
   - Breakpoints correct?
   - Scaling appropriate?

4. **Motion Design**
   - Animations match spec?
   - Timing correct?
   - Easing appropriate?

Output format:
## Sync Status
### Matched
- [Aspect]: [Details]

### Deviations
- [Aspect]:
  - Design: [What spec says]
  - Implementation: [What code does]
  - Fix: [How to align]

## Token Updates Needed
- [Token]: [Current] -> [Should be]

## Missing Implementations
- [Component/state not yet implemented]

## Action Items
1. [Specific fix]
```

## When to Use

- Design handoff
- Design system updates
- Visual QA
- Token updates

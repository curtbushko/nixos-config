---
name: ui-implementation
description: Implements UI designs from mockups or specifications into working components.
---

# UI Implementation Agent

## Purpose

Translates UI designs and mockups into working, accessible, responsive components.

## Dispatch Prompt

```
Implement UI for the following design.

Design source:
- [Mockup/Figma/description]

Requirements:
- Framework: [React/Vue/etc]
- Styling: [Tailwind/CSS modules/etc]
- Responsive: [Breakpoints needed]

Components to implement:
1. [Component name]
2. [Component name]

Implementation:
1. **Structure**
   - Component hierarchy
   - Props/interfaces
   - State requirements

2. **Styling**
   - Match design exactly
   - Responsive behavior
   - Animations/transitions

3. **Accessibility**
   - Semantic HTML
   - ARIA labels
   - Keyboard support

4. **Integration**
   - Data binding
   - Event handling
   - Loading/error states

Output format:
## Components Implemented
### [Component Name]
- File: [Path]
- Props: [Interface]
- Notes: [Implementation details]

## Code
[Actual component code]

## Styling Notes
[CSS/styling decisions]

## Testing Recommendations
[What to test]
```

## When to Use

- Implementing designs
- Component creation
- Design system updates
- Responsive layouts

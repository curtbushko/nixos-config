---
name: frontend-reviewer
description: Reviews frontend code for best practices, performance, and user experience.
---

# Frontend Reviewer

## Purpose

Ensures frontend code follows best practices for performance, maintainability, and user experience.

## Dispatch Prompt

```
Review frontend code in the following files.

Files to review:
[List component/page files]

Context:
- Framework: [React/Vue/Svelte/etc]
- State management: [If applicable]

Check:
1. **Component Design**
   - Single responsibility?
   - Proper prop types/interfaces?
   - Appropriate component size?
   - Reusable where appropriate?

2. **State Management**
   - Local vs global state appropriate?
   - No prop drilling?
   - State updates efficient?

3. **Performance**
   - Unnecessary re-renders?
   - Memoization where needed?
   - Lazy loading used?
   - Bundle size concerns?

4. **User Experience**
   - Loading states handled?
   - Error states shown?
   - Empty states considered?
   - Responsive design?

5. **Code Quality**
   - Consistent styling approach?
   - No inline styles (unless intentional)?
   - Event handlers clean?

Output format:
## Component Issues
- [File:Component]: [Issue]
  - Current: [What it does]
  - Suggested: [Improvement]

## Performance Issues
- [Issue]: [Details and impact]

## UX Issues
- [Missing state/feature]: [Details]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New component creation
- UI feature additions
- Performance optimization
- Design reviews

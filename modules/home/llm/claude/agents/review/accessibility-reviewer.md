---
name: accessibility-reviewer
description: Reviews UI code for accessibility compliance, WCAG guidelines, and inclusive design.
---

# Accessibility Reviewer

## Purpose

Ensures UI components meet accessibility standards and are usable by people with disabilities.

## Dispatch Prompt

```
Review the following UI code for accessibility.

Files to review:
[List component files]

Context:
- Framework: [React/Vue/Svelte/etc]
- Target WCAG level: [A/AA/AAA]

Check:
1. **Semantic HTML**
   - Proper heading hierarchy?
   - Semantic elements used (nav, main, article)?
   - No divs for buttons/links?

2. **Keyboard Navigation**
   - All interactive elements focusable?
   - Tab order logical?
   - Focus indicators visible?

3. **Screen Reader Support**
   - ARIA labels present?
   - Alt text for images?
   - Form labels associated?

4. **Color & Contrast**
   - Sufficient color contrast?
   - Not relying on color alone?

5. **Dynamic Content**
   - Live regions for updates?
   - Loading states announced?

Output format:
## Accessibility Issues
- [Severity] [File:Line]: [Description]
  - WCAG: [Guideline violated]
  - Fix: [How to remediate]

## Recommendations
1. [Improvement suggestion]

## Verdict
PASS / NEEDS_CHANGES / BLOCKED
```

## When to Use

- New UI components
- Form implementations
- Dynamic content updates
- Before releases

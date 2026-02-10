---
name: helios-design
description: Use when building CLI tools, TUI apps, or GUI applications. Provides a design system with semantic color tokens, typography scale, component patterns, elevation, and accessibility guidelines adapted from HashiCorp Helios for any platform.
---

# Helios Design System (Generic)

## Core Principles

1. **Rooted in Reality** - Ground decisions in data, not assumptions
2. **Guidance Over Control** - Balance configurability with consistency
3. **Quality by Default** - Commit to a baseline of quality in all output
4. **Design in Context** - Meet users where they are, consider current and future use
5. **Consider Everyone** - Inclusive from the start, accessible by default
6. **Invite Feedback** - Validate with stakeholders before finalizing

## When to Use

- Building a CLI tool with colored output, status indicators, or structured layouts
- Building a TUI (terminal UI) application with panels, forms, or navigation
- Building a GUI desktop application with buttons, modals, forms, or data tables
- Choosing semantic colors, type scale, or component patterns for any app

## Quick Reference

### Semantic Color Roles

| Role | Purpose | CLI Example |
|------|---------|-------------|
| `foreground-strong` | High-contrast primary text | Bold headings |
| `foreground-primary` | Standard body text | Default output |
| `foreground-faint` | De-emphasized text | Help text, timestamps |
| `foreground-disabled` | Non-interactive text | Greyed-out options |
| `action` | Interactive/clickable elements | Links, commands |
| `success` | Positive outcomes | Checkmarks, "done" |
| `warning` | Caution, side effects | Warnings, deprecations |
| `critical` | Errors, destructive actions | Error messages, delete |
| `highlight` | Prominent callouts | Feature flags, "new" |

### Status Feedback Pattern

| Feedback Type | Component | Persistence |
|---------------|-----------|-------------|
| Page-level event | Alert (page) | Until dismissed |
| Section-specific | Alert (inline) | Until dismissed |
| Quick notice | Alert (compact) | Always persistent |
| Action result | Toast | Auto-dismiss 7s |
| Destructive confirm | Modal (critical) | Blocks until response |
| Status metadata | Badge | Persistent |

### Component Decision Tree

See `references/components.md` for full component anatomy, variants, and do's/don'ts.

### Detailed References

- `references/colors.md` - Full semantic color system, palette structure, contrast ratios
- `references/typography.md` - Font families, type scale, weight system
- `references/components.md` - Buttons, alerts, modals, toasts, badges, dropdowns, forms, tables
- `references/accessibility.md` - WCAG compliance, focus management, keyboard navigation
- `references/layout.md` - App frame structure, elevation levels, spacing

## Common Mistakes

- Using palette colors directly instead of semantic tokens (use `success` not `green-300`)
- Multiple primary buttons on one screen - only one primary action per view
- Auto-dismissing critical/warning toasts - these must persist until user dismisses
- Skipping focus ring implementation on interactive elements
- Using color alone to convey meaning - always pair with icon or text
- Putting destructive actions without confirmation modals

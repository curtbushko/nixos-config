# Component Patterns

## Buttons

### Types

| Type | Usage | Limit |
|------|-------|-------|
| **Primary** | Most important action on the page | ONE per view |
| **Secondary** | Less important or equal-priority actions | Multiple allowed |
| **Critical** | Dangerous/destructive actions (delete, revoke) | Pair with confirmation |
| **Tertiary** | Low-priority actions, lighter visual weight | Requires icon |

### Sizes

- **Small** - Compact contexts (tables, toolbars)
- **Medium** - Default, preferred for most uses
- **Large** - Prominent placement (hero sections, landing)

### States

- Default, Hover, Active, Focus (with focus ring), Loading, Disabled

### Rules

- ONE primary button per view
- Keep text concise (~25 characters max)
- Never combine leading and trailing icons
- Maintain consistent width during loading states (prevent layout shift)
- Use chevron-right for forward navigation in multi-step flows
- Use arrow-right for internal navigation links
- Disabled state: use sparingly, only for incomplete flows or permission restrictions

## Alerts

### Types

| Type | Placement | Use |
|------|-----------|-----|
| **Page** | Between nav and content | Page-level events |
| **Inline** | Near relevant section | Contextual messages |
| **Compact** | Inline, less prominent | Low-emphasis notices |

### Color Variants

| Color | Urgency | Assistive Tech |
|-------|---------|----------------|
| Neutral | Non-urgent info | No auto-announce |
| Highlight | Prominent info | No auto-announce |
| Success | Action completed | Announced immediately |
| Warning | Potential issue | Announced immediately |
| Critical | Error/failure | Announced immediately |

### Rules

- Order multiple alerts by criticality: critical -> warning -> success -> neutral
- Keep descriptions under 90 characters
- Never auto-dismiss critical or warning alerts
- Pair warning/critical with guidance on resolution
- Don't display multiple same-color alerts on one page

## Toasts

### Behavior

- Position: bottom-right corner (GUI) or bottom of terminal (CLI)
- Width: 360-500px max
- Stack vertically with 16px spacing
- Auto-dismiss after 7 seconds (neutral, highlight, success only)
- Critical and warning toasts persist until user dismisses

### When to Use

- Background process completion
- Non-intrusive action feedback
- System-level notifications

### When NOT to Use

- Form validation errors (use inline alerts)
- Anything requiring user decision (use modal)

## Modals

### Color Variants

| Variant | Use | Primary Button Color |
|---------|-----|---------------------|
| Neutral | Create, edit, update | Standard/action |
| Warning | Recoverable impact to settings | Standard/action |
| Critical | Irreversible destructive actions | Critical/red |

### Sizes

- Small: 400px (simple confirmation)
- Medium: 600px (default, recommended)
- Large: 800px (complex content)

### Behavior

- Focus trapped inside modal
- Dismissible via: close button, Escape key, overlay click, cancel button
- Header and footer remain fixed; body scrolls if content overflows
- Page scrolling disabled while modal is open

### Rules

- Always include at least one interactive element
- Require confirmation for all destructive actions
- Don't nest modals
- Don't use for non-urgent tasks or complex multi-step forms

## Badges

### Types

| Type | Purpose |
|------|---------|
| Filled | Default; subtle callouts, many on a page |
| Inverted | Extra attention; use sparingly |
| Outlined | Alternative to filled |

### Colors

Neutral, Highlight, Success, Warning, Critical

### Sizes

- Small: data-dense contexts (tables)
- Medium: default general purpose
- Large: inline with headings

### Rules

- Labels ~25 characters max, no full sentences
- Include icons matching severity for status badges
- Use icon-only badges with accessible screen-reader text

## Dropdowns

### Toggle Types

- **Button**: Text + chevron, small/medium, primary/secondary color
- **Icon**: Icon-based, small/medium, for overflow menus

### Item Types

- **Interactive**: Action, Critical (destructive - always at bottom with separator)
- **Selection**: Checkmark (single), Checkbox (multi), Radio (single)
- **Non-interactive**: Title, Description, Separator, Loading

### Rules

- Width: 200px min, 400px max
- Position critical items at bottom with separator
- Use icons consistently within a list (all or none)
- Require confirmation for destructive actions
- Chevron required on button toggles for affordance

## Form Inputs (Text)

### States

Default, Focus, Disabled, Readonly, Invalid, Loading

### Anatomy

- Label (required, never use placeholder as label substitute)
- Required/Optional indicator
- Input field
- Helper text (optional, below input)
- Error message (on validation failure)

### Rules

- Always associate label with input
- Helper text for guidance; error messages for validation failures
- Support single or multiple error messages
- Use Body 200 for labels/inputs, Body 100 for helper/error text

## Table Multi-Select Pattern

### Selection Scope

1. **Global**: All rows via bulk selection dropdown
2. **Page-level**: Current page via header checkbox
3. **Row-level**: Individual rows via row checkboxes

### Bulk Actions

- Multiple actions: use small Dropdown
- Single action: use small Button (secondary or critical)
- Destructive actions: require confirmation modal

### Rules

- Always display selected count with `role="status"` for assistive tech
- Show selection as portion of total count
- Persist selection communication at all times
- Double confirmation before irreversible bulk changes

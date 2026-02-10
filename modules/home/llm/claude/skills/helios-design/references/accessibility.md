# Accessibility Guidelines

## WCAG 2.2 Level AA Compliance

### Contrast Ratios

| Element | Minimum Ratio |
|---------|---------------|
| Normal text (< 18px / < 14px bold) | 4.5:1 |
| Large text (>= 18px / >= 14px bold) | 3:1 |
| UI components and graphical objects | 3:1 |

Semantic token pairings (foreground on matching surface) are pre-validated.
Custom palette pairings require manual verification (use WebAIM contrast checker).

### CLI Accessibility

- Never use color as the sole indicator of meaning
- Always pair colors with text labels or icons (Nerd Font icons preferred)
- Support `NO_COLOR` environment variable to disable color output
- Provide `--no-color` flag as alternative
- Test output with monochrome terminal to verify usability

## Focus Management

### Focus Ring

- Apply on `:focus` and `:focus-visible` states
- Use `box-shadow` for the ring (not `outline` which clips on rounded elements)
- Always set matching `border-radius` on the focus ring
- Two color variants: `action` (default) and `critical` (for destructive contexts)

### Focus Behavior

- Focus must return to its trigger element when overlays close (modal -> button that opened it)
- Focus must be trapped inside modals and popups
- Focus order must match DOM/visual order
- Tab navigation must reach all interactive elements

### Route/View Transitions

- Announce route changes to assistive technology
- Move focus to main content or a heading on navigation

## Page Structure

### Landmark Roles

| Element | Role | Requirement |
|---------|------|-------------|
| `<header>` | banner | One per page, direct child of body |
| `<nav>` | navigation | Labeled if multiple |
| `<main>` | main | One per page, direct child of body |
| `<aside>` | complementary | Sidebar content |
| `<footer>` | contentinfo | One per page, direct child of body |

### Headings

- Every page requires a relevant title (`<title>` or equivalent)
- Headings must follow logical order without skipping levels
- One H1 per page

### Labels

- All form inputs require associated labels
- Placeholders are NOT label substitutes
- "No ARIA is better than bad ARIA" - only use `aria-label` on roles that support it

## Keyboard Navigation

- All mouse functionality must have keyboard equivalents
- Escape key dismisses overlays (modals, dropdowns, tooltips)
- Enter/Space activates buttons and links
- Arrow keys navigate within composite widgets (tabs, menus, radio groups)
- Tab moves between interactive elements in DOM order

## Assistive Technology

### Status Announcements

| Component | Announcement |
|-----------|-------------|
| Success/Warning/Critical alerts | Immediate (live region) |
| Neutral/Highlight alerts | No auto-announcement |
| Toast notifications | Announced on appearance |
| Selected count in tables | `role="status"` live region |
| Loading states | Announce start and completion |

### Screen Reader Testing

- Test with VoiceOver (macOS), NVDA (Windows), or Orca (Linux)
- Verify all interactive elements have accessible names
- Verify dynamic content changes are announced
- Verify form errors are associated with their inputs

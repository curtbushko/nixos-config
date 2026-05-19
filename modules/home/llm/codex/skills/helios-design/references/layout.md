# Layout and Elevation

## App Frame Structure

Five container regions for application-level layout:

```
+-----------------------------------------------+
|                  Header (nav)                  |
+----------+------------------------------------+
|          |                                    |
| Sidebar  |              Main                  |
|  (nav)   |            (content)               |
|          |                                    |
+----------+------------------------------------+
|                  Footer                        |
+-----------------------------------------------+
|              Modals (overlay layer)            |
+-----------------------------------------------+
```

### Regions

| Region | HTML Element | Required | Purpose |
|--------|-------------|----------|---------|
| Header | `<header>` | No | Top navigation bar |
| Sidebar | `<aside>` | No | Side navigation |
| Main | `<main>` | Yes | Primary content (skip-link target) |
| Footer | `<footer>` | No | Bottom section |
| Modals | `<div>` | No | Overlay container |

### Rules

- Main region is always required; others are optional
- Each region wraps content in semantic HTML elements
- Regions are content-agnostic (no intrinsic sizes except for frame structure)
- Main should have an `id` for skip-link navigation (e.g., `id="main"`)
- Toggle regions via boolean flags (`hasHeader`, `hasSidebar`, etc.)

### Responsive Behavior

- Fixed/sticky layout switches at 480px viewport height threshold
- Sidebar typically collapses to hamburger/overlay on small screens
- Main content fills remaining space

## Elevation System

Six levels of visual depth, applied via `box-shadow`:

| Level | Use Case | Visual Weight |
|-------|----------|--------------|
| **Inset** | Pressed/active states, recessed panels | Negative (inward) |
| **Low** | Cards, subtle lift | Minimal |
| **Mid** | Dropdowns, popovers, floating toolbars | Moderate |
| **High** | Sticky headers, raised panels | Prominent |
| **Higher** | Notifications, toasts | Very prominent |
| **Overlay** | Modals, blocking dialogs | Maximum |

### Surface Variants

Each elevation level has a corresponding surface treatment that combines background color with shadow:

| Surface | Use |
|---------|-----|
| Base | Default, flat content |
| Low | Cards, content groups |
| Mid | Floating elements |
| High | Prominent panels |
| Higher | Notifications |
| Overlay | Modal backdrops |

### Rules

- Apply elevation ONLY via `box-shadow` (not `z-index` alone)
- `border-radius` is NOT included with elevation tokens; set per element
- Higher elevation = more visual importance
- Don't skip levels dramatically (low -> overlay) without reason
- Overlay level should always be paired with a backdrop/scrim

## Spacing

### CLI Spacing

| Purpose | Terminal Lines |
|---------|---------------|
| Section separation | 1 blank line |
| Major section separation | 2 blank lines |
| Indented hierarchy | 2 spaces per level |
| Column alignment | Right-align numbers, left-align text |
| Table padding | 2 spaces between columns minimum |

### GUI Spacing Scale

Follow a 4px base grid. Common values:

| Token | Value | Use |
|-------|-------|-----|
| xs | 4px | Tight spacing within components |
| sm | 8px | Internal component padding |
| md | 16px | Standard spacing between elements |
| lg | 24px | Section spacing |
| xl | 32px | Major section separation |
| 2xl | 48px | Page-level spacing |

## Border Radius

| Token | Value | Use |
|-------|-------|-----|
| x-small | 2px | Tags, badges, small elements |
| small | 4px | Buttons, inputs, small cards |
| medium | 6px | Cards, containers |
| large | 8px | Modals, large panels |
| round | 9999px | Pills, avatars, circular elements |

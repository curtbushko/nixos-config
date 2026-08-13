# Color System

## Token Naming Convention

```
[category]-[element]-[role]-[modifier]
```

Examples: `color-foreground-primary`, `color-surface-warning`, `color-border-strong`

## Semantic Color Categories

### Foreground (Text, Icons)

| Token | Purpose | Contrast (on white) |
|-------|---------|---------------------|
| `foreground-strong` | Maximum contrast headings | 19.54:1 |
| `foreground-primary` | Standard body text | 10.82:1 |
| `foreground-faint` | De-emphasized (help, timestamps) | 4.5:1+ |
| `foreground-disabled` | Non-interactive text | Below 4.5:1 |
| `foreground-action` | Interactive elements (links, commands) | 4.5:1+ |
| `foreground-success` | Positive status | 4.5:1+ |
| `foreground-warning` | Caution status | 4.5:1+ |
| `foreground-critical` | Error/destructive status | 4.5:1+ |
| `foreground-highlight` | Prominent callouts | 4.5:1+ |

### Surface (Backgrounds)

| Token | Purpose |
|-------|---------|
| `surface-primary` | Default app background |
| `surface-faint` | Subtle section differentiation |
| `surface-strong` | Prominent section backgrounds |
| `surface-interactive` | Hover/active states on interactive elements |
| `surface-success` | Success context backgrounds |
| `surface-warning` | Warning context backgrounds |
| `surface-critical` | Error context backgrounds |

### Border

| Token | Purpose |
|-------|---------|
| `border-primary` | Default borders |
| `border-faint` | Subtle dividers |
| `border-strong` | Emphasized borders |
| `border-success` | Success state borders |
| `border-warning` | Warning state borders |
| `border-critical` | Error state borders |

## Core Palette (When Semantic Tokens Don't Fit)

Six hue families, each with shades 50-700:

- **Neutral** (grays) - UI chrome, backgrounds, borders
- **Blue** - Actions, links, information
- **Purple** - Branding, accent
- **Green** - Success, positive
- **Amber** - Warning, caution
- **Red** - Error, destructive, critical

Each hue also has alpha transparency variants for overlays.

## CLI/Terminal Color Mapping

Map semantic tokens to ANSI/256-color/truecolor as available:

| Semantic Role | ANSI 16 | 256-color | Truecolor |
|--------------|---------|-----------|-----------|
| `foreground-strong` | White (bold) | 255 | `#0c0c0e` on light / `#fafafa` on dark |
| `foreground-primary` | Default FG | 253 | `#3b3d45` / `#d2d5da` |
| `foreground-faint` | Dark gray | 245 | `#656a76` / `#8b919e` |
| `action` | Blue | 33 | `#1060ff` |
| `success` | Green | 34 | `#008a22` |
| `warning` | Yellow | 214 | `#c05c00` |
| `critical` | Red | 196 | `#c00f0f` |
| `highlight` | Magenta | 141 | `#7b61ff` |

## Accessibility Contrast Requirements

WCAG 2.2 Level AA minimums:

- **Normal text** (< 18px / < 14px bold): 4.5:1
- **Large text** (>= 18px / >= 14px bold): 3:1
- **UI components and graphical objects**: 3:1

Pre-validated safe pairings:
- `foreground-strong` on `surface-primary` = 19.54:1
- `foreground-primary` on `surface-primary` = 10.82:1
- Any semantic foreground on its matching surface = pre-validated

Custom palette pairings require manual contrast verification.

## Dark Mode Strategy

Maintain the same semantic token names. Swap underlying values:
- `surface-primary` becomes dark background
- `foreground-strong` becomes light text
- Status colors shift to lighter variants for visibility on dark backgrounds
- Ensure contrast ratios hold in both modes

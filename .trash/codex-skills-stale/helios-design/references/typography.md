# Typography System

## Font Families

### Sans-Serif (System Native)

| Platform | Large (>= 20px) | Small (< 20px) |
|----------|-----------------|-----------------|
| macOS/iOS | SF Pro Display | SF Pro Text |
| Windows | Segoe UI Display | Segoe UI Text |
| Linux | System sans-serif | System sans-serif |

### Monospace (System Native)

| Platform | Primary | Fallback |
|----------|---------|----------|
| macOS (Safari 13+) | SF Mono | Menlo |
| macOS (other) | Menlo | Monaco |
| Windows | Consolas | Courier New |
| Linux | System monospace | DejaVu Sans Mono |

Rationale: System fonts provide stability, proper internationalization, and zero download cost.

## Font Weights

| Weight | Value | Usage |
|--------|-------|-------|
| Regular | 400 | Body text, descriptions |
| Medium | 500 | Labels, sub-headings, emphasis |
| Semi-bold | 600 | Section headings, interactive labels |
| Bold | 700 | Display headings, strong emphasis |

## Type Scale

### Display (Headings, Visual Emphasis)

| Style | Size | Weight | HTML Mapping |
|-------|------|--------|-------------|
| Display 500 | 30px | Bold (700) | H1 |
| Display 400 | 24px | Bold / Semi-bold / Medium | H2 |
| Display 300 | 18px | Bold / Semi-bold / Medium | H3 |
| Display 200 | 16px | Semi-bold (600) | H4 |
| Display 100 | 13px | Medium (500) | H5 |

### Body (General Content)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Body 300 | 16px | Regular / Medium / Semi-bold | Large body text |
| Body 200 | 14px | Regular / Medium / Semi-bold | Default body (data-dense apps) |
| Body 100 | 13px | Regular / Medium / Semi-bold | Secondary text, help, captions |

### Code (Monospace)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Code 300 | 16px | Regular / Bold | Large code blocks |
| Code 200 | 14px | Regular / Bold | Default inline/block code |
| Code 100 | 13px | Regular / Bold | Small code, annotations |

## CLI Typography Mapping

Terminal apps have limited typographic control. Map the scale:

| Semantic Style | Terminal Representation |
|---------------|----------------------|
| Display 500 | ALL CAPS + Bold + top/bottom blank line |
| Display 400 | Bold + top blank line |
| Display 300 | Bold |
| Body 200 | Normal text (default) |
| Body 100 | Dim/faint attribute |
| Code | Inline: backtick-wrapped; Block: indented 2 spaces |

## Guidelines

- Body 200 (14px) is the default for data-dense applications
- Form labels and inputs use Body 200; helper text and errors use Body 100
- Display styles create hierarchy through size; weight differentiates semantic emphasis
- Never skip heading levels (Display 500 -> Display 300 without Display 400)

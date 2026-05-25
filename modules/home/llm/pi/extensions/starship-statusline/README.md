# Pi Starship Statusline

Custom Starship-style statusline for Pi coding agent, based on [@elianiva/pi-starship](https://github.com/elianiva/pi-starship).

## Features

- **Framed user messages**: Messages displayed with border frames and accent rails (zentui-inspired)
- **Starship-style prompt**: Clean `❯` prompt with no borders
- **Vim-style ex commands**: Type `:` to enter command mode
  - `:q` or `:quit` - Exit Pi (when editor is empty)
  - `:q!` or `:quit!` - Force exit
  - `:w` or `:write` - Save (Pi auto-saves)
  - `:wq` or `:x` - Save and exit
  - Press `Escape` to cancel command mode
- **Statusline footer** displaying:
  - Gradient decoration `▓▒░`
  - Model name with OpenAI icon 󰭹 (e.g., `gpt-4-t`)
  - Directory/repo name with context-aware icon (󱄅 for nixos-config, 󰊢 for generic)
  - Git branch with icon  and dirty indicator `✘!+?`
  - Powerline separators  with themed background colors

## Installation

This extension is automatically installed via the Nix configuration. It auto-loads on Pi session start.

## Components

### User Message Styling
Inspired by pi-zentui, user messages are rendered with:
- Horizontal border lines (`─`) above and below
- Vertical accent rail (`│`) on the left
- Padding lines for visual breathing room
- Theme-aware colors from flair/stylix

```
────────────────────────────────
│
│ Your message content here
│
────────────────────────────────
```

### StarshipEditor
Replaces the default editor with a minimal design featuring:
- `❯` prompt with no borders
- Vim-style ex command mode triggered by `:`
- Command buffer with visual feedback

### Widget
Displays system information in a compact, single-line format at the top of the terminal.

### Event Handlers
Automatically updates the widget on:
- Session switches
- Agent start/end
- Model selection
- Shell commands (with 300ms debouncing)
- Turn completion

## Customization

Colors are configured via `colors.json` (generated from flair/stylix theme):
- `a_bg`, `a_fg` - Segment A (gradient + model) background and foreground
- `b_bg`, `b_fg` - Segment B (directory) background and foreground
- `c_bg`, `c_fg` - Segment C (git branch) background and foreground
- `error` - Dirty indicator color

Powerline separators automatically use the background colors of adjacent segments for smooth transitions.

## Git Support

- Shows current branch name
- Displays dirty status with `*`
- 2-second caching for performance
- Refreshes automatically after shell commands

## Based On

This extension is based on [@elianiva/pi-starship](https://github.com/elianiva/pi-starship) with customizations for:
- Simplified display format
- Directory basename only (not full path)
- Custom icon set matching Starship prompt
- Integrated auto-loading

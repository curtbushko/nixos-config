# Pi Vim with Ex Commands

Custom vim extension for Pi coding agent with full vim motions and ex command support.

Based on [@burneikis/pi-vim](https://github.com/burneikis/pi-vim) with added ex command functionality.

## Features

### Vim Modes
- **Normal Mode**: Vim motions, operators, text objects
- **Insert Mode**: Standard text input
- **Visual Mode**: Visual selection (character and line)
- **Replace Mode**: Character replacement
- **Command Mode**: Ex commands and search

### Ex Commands
- `:q` or `:quit` - Exit Pi
- `:q!` or `:quit!` - Force exit
- `:w` or `:write` - Save (Pi auto-saves)
- `:wq` or `:x` - Save and exit

### Vim Motions
All standard vim motions including:
- Navigation: `hjkl`, `w`, `b`, `e`, `0`, `$`, `gg`, `G`
- Operators: `d`, `c`, `y`, `>`, `<`
- Text objects: `iw`, `aw`, `i"`, `a"`, `i(`, `a(`, etc.
- Search: `/`, `?`, `n`, `N`, `*`, `#`
- Registers: `"ayy`, `"ap`, etc.
- Dot repeat: `.`

## Usage

The extension is automatically loaded by Pi. Start typing in insert mode or press `Esc` to enter normal mode.

## Credits

- Original vim extension: [@burneikis/pi-vim](https://github.com/burneikis/pi-vim)
- Ex command support: Added by @curtbushko

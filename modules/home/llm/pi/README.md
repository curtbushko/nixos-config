# Pi Configuration Module

Declarative configuration for the Pi coding agent CLI.

## Structure

```
pi/
├── default.nix        # Main module configuration
├── config/            # Configuration files (for future expansion)
└── README.md          # This file
```

## Key Features

### NPM Wrapper
Uses a custom `pi-npm` wrapper that redirects the global npm prefix to `~/.pi/agent/npm/`, avoiding permission errors from trying to write to the read-only Nix store.

### Declarative Extensions
Extensions are declared in `settings.json` packages list and installed via idempotent activation hooks:
- `@burneikis/pi-fzfp` - Fuzzy find plugin

### Custom Local Extensions
- `pi-vim-ex` - Custom vim extension with ex command support (`:q`, `:w`, `:wq`)
  - Based on `@burneikis/pi-vim` with added ex commands
  - Full vim motions, operators, text objects
  - Visual mode, registers, dot repeat

### Custom Starship Statusline
Local extension (`extensions/starship-statusline/`) based on [@elianiva/pi-starship](https://github.com/elianiva/pi-starship):
- Starship-style `❯` prompt with no borders
- Info widget with gradient `▓▒░`, model 󰭹, directory 󰊢, git branch
- Token usage and cost tracking
- Auto-updates on git changes, model switches, and shell commands

### Custom Theme
Integrates with flair/stylix for consistent theming using base16 color scheme.

### Configuration Files
All configuration files are managed declaratively:
- `settings.json` - Core pi settings (no default provider for OAuth)
- `models.json` - Empty for OAuth providers (auto-configured after `/login`)
- `theme.json` - Custom theme using flair colors (base16 Gruvbox Material)
- `extensions/pi-vim-ex/` - Custom vim extension
- `extensions/starship-statusline/` - Custom statusline extension

## Adding Extensions

To add a new extension:

1. Add it to the `packages` list in `settings.json`:
   ```nix
   packages = [
     "npm:@burneikis/pi-fzfp"
     "npm:@burneikis/pi-vim"
     "npm:new-extension"  # Add here
   ];
   ```

2. Add an activation hook:
   ```nix
   home.activation.installNewExtension =
     lib.hm.dag.entryAfter ["writeBoundary"]
     ''
       if [ ! -d "$HOME/.pi/agent/npm/lib/node_modules/new-extension" ]; then
         $DRY_RUN_CMD ${piNpm}/bin/pi-npm install -g new-extension
       fi
     '';
   ```

## Authentication

Pi is configured to use OAuth authentication. Run `pi /login` to authenticate with:
- **ChatGPT Plus/Pro (Codex)** - Requires ChatGPT Plus or Pro subscription
- **Claude Pro/Max** - Requires Anthropic subscription
- **GitHub Copilot** - Requires GitHub Copilot subscription

OAuth credentials are stored in `~/.pi/agent/auth.json` and auto-refresh when expired.

## Environment Variables

- `PI_SKIP_VERSION_CHECK` - Disables version check notifications

## Inspiration

This module structure is inspired by [chenxin-yan/nix-dotfiles](https://github.com/chenxin-yan/nix-dotfiles/tree/main/modules/home/cli/pi), adapted for this configuration.

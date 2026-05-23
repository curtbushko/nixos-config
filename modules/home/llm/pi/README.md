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
- `@burneikis/pi-vim` - Vim mode plugin

### Custom Theme
Integrates with flair/stylix for consistent theming using base16 color scheme.

### Custom Statusline
Custom Node.js statusline script (`.pi/statusline.mjs`) that displays:
- Model name (with icon)
- Repository name
- Git branch
- All with themed colors from flair/stylix

### Configuration Files
All configuration files are managed declaratively:
- `settings.json` - Core pi settings
- `models.json` - OpenAI provider configuration
- `theme.json` - Custom theme using flair colors
- `keybindings.json` - Vim-style keybindings
- `statusline.mjs` - Custom statusline script

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

## Environment Variables

- `PI_SKIP_VERSION_CHECK` - Disables version check notifications
- `OPENAI_API_KEY` - OpenAI API key (set in shell or secrets)

## Shell Aliases

- `pi-gpt4` - Launch pi with GPT-4 Turbo
- `pi-gpt35` - Launch pi with GPT-3.5 Turbo

## Inspiration

This module structure is inspired by [chenxin-yan/nix-dotfiles](https://github.com/chenxin-yan/nix-dotfiles/tree/main/modules/home/cli/pi), adapted for this configuration.

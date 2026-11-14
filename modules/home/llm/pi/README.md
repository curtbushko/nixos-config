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
Extensions are declared in the `settings.json` package list:
- `@burneikis/pi-fzfp` - Fuzzy find plugin, bootstrapped by an activation hook.
- `pi-openai-codex-device-login` 0.1.0 - Checksum-pinned npm archive loaded directly
  from the Nix store; no runtime dependencies or npm activation hook.

### Shared Skills

`~/.pi/agent/skills` points at the same canonical `modules/home/llm/skills` tree
used by Claude Code and Codex. Pi-specific copies are intentionally not created.

### Per-machine models

Shared defaults expose `openai-codex/gpt-6.1-sol`, the three GPT 5.6 models
(Luna, Sol, Terra), and `anthropic/*` for explicitly selecting Claude. Personal
machines, including Steam Deck, start with OpenAI Codex / GPT 6.1 Sol.

Only the work Mac overrides `ns.llm.pi.defaultProvider` and
`ns.llm.pi.enabledModels` to use `github-copilot/*`. Its `defaultModel = null`
omits a fixed model so Pi can choose an available Copilot model. Authentication
remains local to each machine.

The local Qwen provider, `pi-local` alias, and local prompt are removed. Pi's
built-in llama.cpp discovery is disabled. No local endpoint is registered.
Stored GGUF files and session history are not deleted. A resumed session restores
its prior model, and project settings can override global defaults; start a fresh
Pi process/session or use `/model` to select Codex after applying these changes.

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
- `settings.json` - Codex/GPT Sol defaults on personal machines; Copilot on work
- `models.json` - Empty for OAuth providers (auto-configured after `/login`)
- `themes/flair.json` - Selected Pi theme using flair colors (base16 Gruvbox Material)
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
- **GitHub Copilot (work Mac only)** - Requires GitHub Copilot subscription

For device-code Codex login, run `/login`, choose **Use a subscription**, then
**ChatGPT Plus/Pro (Codex Device Code)** and **Device code (recommended)**. Open
the displayed URL on any browser and enter the one-time code. Browser OAuth is
still available as a fallback. Use `/reload` after applying the configuration if
Pi is already running.

The extension overrides only Codex authentication; model scopes and the work
Mac's Copilot default are unchanged. OAuth credentials are stored by Pi in
`~/.pi/agent/auth.json` and auto-refresh when expired. Nix does not manage them.

## Environment Variables

- `PI_SKIP_VERSION_CHECK` - Disables version check notifications

## Inspiration

This module structure is inspired by [chenxin-yan/nix-dotfiles](https://github.com/chenxin-yan/nix-dotfiles/tree/main/modules/home/cli/pi), adapted for this configuration.

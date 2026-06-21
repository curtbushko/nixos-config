{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: {
  config = let
    inherit (lib) mkIf;
    cfg = config.curtbushko.llm;

    # NPM wrapper that redirects global prefix to a writable location under ~/.pi/agent/
    # This avoids permission errors from trying to write to the read-only Nix store
    piNpm = pkgs.writeShellScriptBin "pi-npm" ''
      export PATH="${pkgs.nodejs}/bin:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.pi/agent/npm"
      exec ${pkgs.nodejs}/bin/npm "$@"
    '';

    # Read colors from flair's style.json (same source as stylix)
    # Note: Requires --impure flag for home-manager switch
    flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

    # Default fallback theme (gruvbox-material) if flair style.json doesn't exist
    defaultColors = {
      base00 = "#282828";
      base01 = "#1d2021";
      base02 = "#3c3836";
      base03 = "#504945";
      base04 = "#504945";
      base05 = "#d4be98";
      base06 = "#dbe0cd";
      base07 = "#fff8e3";
      base08 = "#ea6962";
      base09 = "#e78a4e";
      base0A = "#d8a657";
      base0B = "#9fc975";
      base0C = "#89b482";
      base0D = "#7daea3";
      base0E = "#9d7cd8";
      base0F = "#a9b665";
      # Statusline colors
      "statusline-a-bg" = "#504945";
      "statusline-a-fg" = "#282828";
      "statusline-b-bg" = "#32302f";
      "statusline-b-fg" = "#d4be98";
      "statusline-c-bg" = "#1d2021";
      "statusline-c-fg" = "#d4be98";
    };

    # Use flair colors if available, otherwise fall back to default
    colors =
      if builtins.pathExists flairStylePath
      then builtins.fromJSON (builtins.readFile flairStylePath)
      else defaultColors;

    # Statusline color variables
    a_bg = colors."statusline-a-bg";
    a_fg = colors."statusline-a-fg";
    b_bg = colors."statusline-b-bg";
    b_fg = colors."statusline-b-fg";
    c_bg = colors."statusline-c-bg";
    c_fg = colors."statusline-c-fg";
  in
    mkIf cfg.enable {
      home.packages = [
        pkgs.nodejs
        inputs.pi.packages.${system}.coding-agent
      ];

      # Disable pi's startup "new version available" toast. The pi binary
      # itself is pinned by Nix, so the upstream npm-registry version check
      # is pure noise and would nudge us toward `npm i -g` updates that fight
      # the read-only Nix store.
      home.sessionVariables = {
        PI_SKIP_VERSION_CHECK = "1";
      };

      # ========================================================================
      # Pi Configuration Files
      # ========================================================================

      home.file = {
        # Pi settings - core configuration
        ".pi/agent/settings.json".source = pkgs.writeText "pi-settings.json" (builtins.toJSON {
          # defaultProvider and defaultModel removed to allow OAuth login
          # Will be set after /login completes
          checkForUpdates = false;
          telemetry = false;
          quietStartup = true;
          notifications = true;
          # Pi shells out to npm for `pi install npm:...`. Under Nix, the
          # default global prefix points into the read-only Node store path, so
          # use a tiny wrapper that redirects npm's global prefix to a writable
          # location under ~/.pi/agent/.
          npmCommand = ["${piNpm}/bin/pi-npm"];
          # Declarative package list. Pi loads extensions from each entry's manifest.
          # We declare packages here directly and install them via activation hooks below.
          packages = [
            "npm:@burneikis/pi-fzfp"
          ];
        });

        # Models configuration - empty for OAuth providers
        # OAuth providers (ChatGPT Plus/Pro, Claude Pro/Max, GitHub Copilot)
        # have their models auto-configured after /login
        ".pi/agent/models.json".source = pkgs.writeText "pi-models.json" (builtins.toJSON {
          providers = {};
        });

        # Custom theme using flair/stylix colors (base16 scheme)
        # Pi requires ALL 51 color tokens to be defined
        ".pi/agent/theme.json".text = builtins.toJSON {
          "$schema" = "https://raw.githubusercontent.com/earendil-works/pi/main/packages/coding-agent/src/modes/interactive/theme/theme-schema.json";
          name = "flair";
          colors = {
            # UI colors
            accent = colors.base0D;
            border = colors.base02; # Subtle visible border
            borderAccent = colors.base0D; # Accent border (blue)
            borderMuted = colors.base03; # Muted border (gray)
            success = colors.base0B;
            error = colors.base08;
            warning = colors.base0A;
            muted = colors.base03;
            dim = colors.base02;
            text = colors.base05;
            thinkingText = colors.base03;

            # Backgrounds
            selectedBg = colors.base02;
            userMessageBg = colors.base01; # Slightly elevated background
            userMessageText = colors.base05;
            customMessageBg = colors.base01; # Slightly elevated background
            customMessageText = colors.base05;
            customMessageLabel = colors.base0D;
            toolPendingBg = colors.base01;
            toolSuccessBg = colors.base01;
            toolErrorBg = colors.base01;
            toolTitle = colors.base0D;
            toolOutput = colors.base05; # Use main text color

            # Markdown
            mdHeading = colors.base0A;
            mdLink = colors.base0D;
            mdLinkUrl = colors.base03;
            mdCode = colors.base0C;
            mdCodeBlock = colors.base05;
            mdCodeBlockBorder = colors.base02; # Subtle border for code blocks
            mdQuote = colors.base03;
            mdQuoteBorder = colors.base0D; # Accent border for quotes
            mdHr = colors.base03; # Visible horizontal rules
            mdListBullet = colors.base0C;

            # Diff colors
            toolDiffAdded = colors.base0B;
            toolDiffRemoved = colors.base08;
            toolDiffContext = colors.base03;

            # Syntax highlighting
            syntaxComment = colors.base03;
            syntaxKeyword = colors.base0E;
            syntaxFunction = colors.base0D;
            syntaxVariable = colors.base08;
            syntaxString = colors.base0B;
            syntaxNumber = colors.base09;
            syntaxType = colors.base0A;
            syntaxOperator = colors.base05;
            syntaxPunctuation = colors.base03;

            # Thinking indicators
            thinkingOff = colors.base03;
            thinkingMinimal = colors.base0D;
            thinkingLow = colors.base0C;
            thinkingMedium = colors.base0B;
            thinkingHigh = colors.base0A;
            thinkingXhigh = colors.base08;

            # Editor
            bashMode = colors.base00; # Match background to hide
          };
        };

        # Vim-style ex commands are implemented in the starship-statusline extension
        # No keybindings.json needed - commands are handled by StarshipEditor

        # Custom vim extension with ex command support
        # Based on @burneikis/pi-vim with added :q/:w/:wq commands
        ".pi/agent/extensions/pi-vim-ex" = {
          source = ./extensions/pi-vim-ex;
          recursive = true;
        };

        # Custom Starship statusline extension
        # Pi auto-discovers extensions from ~/.pi/agent/extensions/
        ".pi/agent/extensions/starship-statusline" = {
          source = ./extensions/starship-statusline;
          recursive = true;
        };

        # Starship statusline colors (from flair/stylix)
        ".pi/agent/extensions/starship-statusline/colors.json".text = builtins.toJSON {
          a_bg = a_bg;
          a_fg = a_fg;
          b_bg = b_bg;
          b_fg = b_fg;
          c_bg = c_bg;
          c_fg = c_fg;
          error = "#ea6962";
        };
      };

      # ========================================================================
      # Extension Installation (via activation hooks)
      # ========================================================================
      # Bootstrap npm artifacts for declarative `packages` entries.
      # Each install hook is idempotent (checks if directory exists first).
      # Pi resolves global npm packages from `<npmCommand> root -g`/lib/node_modules/<name>.

      home.activation.installPiFzfp =
        config.lib.dag.entryAfter ["writeBoundary"]
        ''
          if [ ! -d "$HOME/.pi/agent/npm/lib/node_modules/@burneikis/pi-fzfp" ]; then
            $DRY_RUN_CMD ${piNpm}/bin/pi-npm install -g @burneikis/pi-fzfp
          fi
        '';

      # pi-vim activation disabled - conflicts with editor extensions
      # home.activation.installPiVim =
      #   config.lib.dag.entryAfter ["writeBoundary"]
      #   ''
      #     if [ ! -d "$HOME/.pi/agent/npm/lib/node_modules/@burneikis/pi-vim" ]; then
      #       $DRY_RUN_CMD ${piNpm}/bin/pi-npm install -g @burneikis/pi-vim
      #     fi
      #   '';

      # ========================================================================
      # Shell Integration
      # ========================================================================

      programs.zsh.shellAliases = {
        # OAuth provider aliases (will work after /login)
        # Use the provider name shown in /login (e.g., "openai-codex" for ChatGPT Plus/Pro)
      };

      # Set OpenAI API key environment variable
      # Note: Add your actual key to secrets or export it in your shell
      programs.zsh.sessionVariables = {
      };
    };
}

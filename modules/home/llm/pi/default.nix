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
    cfg = config.ns.llm;

    # NPM wrapper that redirects global prefix to a writable location under ~/.pi/agent/
    # This avoids permission errors from trying to write to the read-only Nix store
    piNpm = pkgs.writeShellScriptBin "pi-npm" ''
      export PATH="${pkgs.nodejs}/bin:$PATH"
      export NPM_CONFIG_PREFIX="$HOME/.pi/agent/npm"
      exec ${pkgs.nodejs}/bin/npm "$@"
    '';

    piHerdr = pkgs.stdenvNoCC.mkDerivation {
      pname = "pi-herdr";
      version = "0.5.0";
      src = pkgs.fetchurl {
        url = "https://registry.npmjs.org/@andrewjacop/pi-herdr/-/pi-herdr-0.5.0.tgz";
        hash = "sha256-t4hxyXNx1Bt/ubo5UCYHIBI7M/YyKC1jXU92b6Y7NnA=";
      };
      sourceRoot = "package";
      installPhase = ''
        runHook preInstall
        mkdir -p "$out"
        cp -R . "$out/"
        runHook postInstall
      '';
    };

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

    # Convert "#RRGGBB" → "R;G;B" for ANSI 24-bit escapes.
    hexDigit = c: let
      digits = {
        "0" = 0; "1" = 1; "2" = 2; "3" = 3; "4" = 4;
        "5" = 5; "6" = 6; "7" = 7; "8" = 8; "9" = 9;
        "a" = 10; "b" = 11; "c" = 12; "d" = 13; "e" = 14; "f" = 15;
        "A" = 10; "B" = 11; "C" = 12; "D" = 13; "E" = 14; "F" = 15;
      };
    in digits.${c};
    hexPair = s:
      hexDigit (builtins.substring 0 1 s) * 16
      + hexDigit (builtins.substring 1 1 s);
    hexToRgb = hex: let
      h = builtins.substring 1 6 hex;
    in
      "${toString (hexPair (builtins.substring 0 2 h))};"
      + "${toString (hexPair (builtins.substring 2 2 h))};"
      + "${toString (hexPair (builtins.substring 4 2 h))}";

    # Build pi-vim-ex with flair colors baked into vim-editor.ts.
    piVimEx = pkgs.runCommand "pi-vim-ex" {} ''
      cp -r ${./extensions/pi-vim-ex} $out
      chmod -R +w $out
      substituteInPlace $out/vim-editor.ts \
        --replace-fail "@base08_rgb@" "${hexToRgb colors.base08}" \
        --replace-fail "@base09_rgb@" "${hexToRgb colors.base09}" \
        --replace-fail "@base0B_rgb@" "${hexToRgb colors.base0B}" \
        --replace-fail "@base0D_rgb@" "${hexToRgb colors.base0D}"
    '';
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
          defaultProvider = "openai-codex";
          defaultModel = "gpt-6-sol";
          defaultThinkingLevel = "medium";
          checkForUpdates = false;
          telemetry = false;
          quietStartup = true;
          notifications = true;
          enabledModels = cfg.pi.enabledModels;
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

        # Models configuration - local llama-server providers alongside OAuth.
        # OAuth providers (ChatGPT Plus/Pro, Claude Pro/Max, GitHub Copilot)
        # are auto-configured after /login and merged with these entries.
        ".pi/agent/models.json".source = pkgs.writeText "pi-models.json" (builtins.toJSON {
          providers = {
            local = {
              baseUrl = "http://localhost:8080/v1";
              api = "openai-completions";
              apiKey = "local";
              compat = {
                supportsDeveloperRole = false;
                supportsReasoningEffort = false;
                thinkingFormat = "qwen-chat-template";
              };
              models = [
                {
                  id = "qwen3.8-27b";
                  name = "Qwen3.8-27B (local)";
                  reasoning = true;
                  contextWindow = 32768;
                  maxTokens = 8192;
                }
              ];
            };
            gamingrig = {
              baseUrl = "http://gamingrig:8080/v1";
              api = "openai-completions";
              apiKey = "gamingrig";
              compat = {
                supportsDeveloperRole = false;
                supportsReasoningEffort = false;
                thinkingFormat = "qwen-chat-template";
              };
              models = [
                {
                  id = "qwen3.8-27b";
                  name = "Qwen3.8-27B (gamingrig)";
                  reasoning = true;
                  contextWindow = 32768;
                  maxTokens = 8192;
                }
              ];
            };
          };
        });

        # Pi consumes the exact canonical skill tree used by Claude and Codex.
        ".pi/agent/skills".source = ../skills;

        # Nix owns the pinned pi-herdr package; Pi only discovers the extension.
        ".pi/agent/extensions/pi-herdr" = {
          source = piHerdr;
          recursive = true;
        };

        # Minimal system prompt for local models. Used by the `pi-local`
        # wrapper alias to keep the context small so smaller local models
        # aren't drowned in the default multi-thousand-token prompt.
        ".pi/agent/prompts/local.md".text = ''
          You are a coding assistant running in the pi TUI.

          Rules:
          - Use the available tools to read, edit, and run code. Do not guess file contents.
          - Be concise. No preamble, no summaries of what you just did.
          - Prefer editing existing files over creating new ones.
          - When unsure, ask one short question instead of assuming.
          - Reference code as `path:line` so the user can jump to it.
        '';

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
          source = piVimEx;
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

        # Local llama-server on this host, minimal system prompt.
        pi-local = "pi --provider local --model qwen3.8-27b --system-prompt \"$(cat ~/.pi/agent/prompts/local.md)\"";
        # Remote llama-server on gamingrig, minimal system prompt.
        pi-gamingrig = "pi --provider gamingrig --model qwen3.8-27b --system-prompt \"$(cat ~/.pi/agent/prompts/local.md)\"";
      };

      # Set OpenAI API key environment variable
      # Note: Add your actual key to secrets or export it in your shell
      programs.zsh.sessionVariables = {
      };
    };
}

{
  config,
  inputs,
  lib,
  pkgs,
  system,
  ...
}: {
  config =
    let
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
        base00 = "#1d2021";
        base01 = "#282828";
        base02 = "#3c3836";
        base03 = "#504945";
        base04 = "#bdae93";
        base05 = "#d4be98";
        base06 = "#ebdbb2";
        base07 = "#fbf1c7";
        base08 = "#ea6962";
        base09 = "#e78a4e";
        base0A = "#d8a657";
        base0B = "#a9b665";
        base0C = "#89b482";
        base0D = "#7daea3";
        base0E = "#d3869b";
        base0F = "#bd6f3e";
        # Statusline colors
        "statusline-a-bg" = "#1d2021";
        "statusline-a-fg" = "#d4be98";
        "statusline-b-bg" = "#282828";
        "statusline-b-fg" = "#d4be98";
        "statusline-c-bg" = "#3c3836";
        "statusline-c-fg" = "#a9b665";
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
          defaultProvider = "openai";
          defaultModel = "gpt-4-turbo";
          checkForUpdates = false;
          telemetry = false;
          quietStartup = true;
          notifications = true;
          statusLine = {
            command = "node $HOME/.pi/statusline.mjs";
            padding = 0;
            type = "command";
          };
          # Pi shells out to npm for `pi install npm:...`. Under Nix, the
          # default global prefix points into the read-only Node store path, so
          # use a tiny wrapper that redirects npm's global prefix to a writable
          # location under ~/.pi/agent/.
          npmCommand = ["${piNpm}/bin/pi-npm"];
          # Declarative package list. Pi loads extensions from each entry's manifest.
          # We declare packages here directly and install them via activation hooks below.
          packages = [
            "npm:@burneikis/pi-fzfp"
            "npm:@burneikis/pi-vim"
          ];
        });

        # OpenAI provider configuration
        ".pi/agent/models.json".source = pkgs.writeText "pi-models.json" (builtins.toJSON {
          providers = {
            openai = {
              label = "ChatGPT (OpenAI)";
              baseUrl = "https://api.openai.com/v1";
              api = "openai-completions";
              apiKey = "$OPENAI_API_KEY"; # Set via environment variable
              compat = {
                supportsUsageInStreaming = true;
                maxTokensField = "max_tokens";
              };
              models = [
                {
                  id = "gpt-4-turbo";
                  label = "GPT-4 Turbo";
                  contextWindow = 128000;
                  maxOutputTokens = 4096;
                }
                {
                  id = "gpt-4";
                  label = "GPT-4";
                  contextWindow = 8192;
                  maxOutputTokens = 4096;
                }
                {
                  id = "gpt-3.5-turbo";
                  label = "GPT-3.5 Turbo";
                  contextWindow = 16385;
                  maxOutputTokens = 4096;
                }
              ];
            };
          };
        });

        # Custom theme using flair/stylix colors (base16 scheme)
        ".pi/agent/theme.json".text = builtins.toJSON {
          colors = {
            # Background colors
            background = colors.base00;
            backgroundAlt = colors.base01;
            surface = colors.base02;

            # Foreground colors
            foreground = colors.base05;
            foregroundAlt = colors.base04;
            comment = colors.base03;

            # Semantic colors
            primary = colors.base0D; # Blue - primary actions
            secondary = colors.base0E; # Purple - secondary actions
            success = colors.base0B; # Green - success states
            warning = colors.base0A; # Yellow - warnings
            error = colors.base08; # Red - errors
            info = colors.base0C; # Cyan - info

            # Syntax highlighting
            variable = colors.base08; # Red
            constant = colors.base09; # Orange
            string = colors.base0B; # Green
            keyword = colors.base0E; # Purple
            function = colors.base0D; # Blue
            operator = colors.base05; # Foreground
          };
          font = {
            family = "JetBrainsMono Nerd Font";
            size = 14;
          };
        };

        # Vim-style keybindings
        ".pi/agent/keybindings.json".text = builtins.toJSON {
          keybindings = [
            {
              key = ":q";
              command = "exit";
            }
          ];
        };

        # Custom statusline (Node.js for faster rendering)
        # Displays model, repository, and git branch with themed colors
        ".pi/statusline.mjs".text = ''
          import { execSync } from "node:child_process";
          import { readFileSync } from "node:fs";

          const A_BG = "${a_bg}";
          const A_FG = "${a_fg}";
          const B_BG = "${b_bg}";
          const B_FG = "${b_fg}";
          const C_BG = "${c_bg}";
          const C_FG = "${c_fg}";
          const RESET = "\x1b[0m";
          const CLR = "\x1b[K";

          function hexToFg(hex) {
            const r = parseInt(hex.slice(1, 3), 16);
            const g = parseInt(hex.slice(3, 5), 16);
            const b = parseInt(hex.slice(5, 7), 16);
            return "\x1b[38;2;" + r + ";" + g + ";" + b + "m";
          }

          function hexToBg(hex) {
            const r = parseInt(hex.slice(1, 3), 16);
            const g = parseInt(hex.slice(3, 5), 16);
            const b = parseInt(hex.slice(5, 7), 16);
            return "\x1b[48;2;" + r + ";" + g + ";" + b + "m";
          }

          function run(cmd) {
            try {
              return execSync(cmd, { encoding: "utf8", stdio: ["pipe", "pipe", "pipe"] }).trim();
            } catch {
              return "";
            }
          }

          function extractModel(raw) {
            let m;
            // gpt-4-turbo -> gpt-4-turbo
            m = raw.match(/gpt-(\d+)-turbo/);
            if (m) return "gpt-" + m[1] + "-t";
            // gpt-4 -> gpt-4
            m = raw.match(/gpt-(\d+(?:\.\d+)?)/);
            if (m) return "gpt-" + m[1];
            // qwen2.5-coder-7b -> qwen-2.5
            m = raw.match(/qwen(\d+\.\d+)/);
            if (m) return "qwen-" + m[1];
            // claude-3-5-sonnet -> sonnet-3.5
            m = raw.match(/claude-(\d+)-(\d+)-([a-z]+)/);
            if (m) return m[3] + "-" + m[1] + "." + m[2];
            // claude-sonnet-4-5 -> sonnet-4.5
            m = raw.match(/claude-([a-z]+)-(\d+)-(\d+)/);
            if (m) return m[1] + "-" + m[2] + "." + m[3];
            // claude-sonnet-4 -> sonnet-4
            m = raw.match(/claude-([a-z]+)-(\d+)\D/);
            if (m) return m[1] + "-" + m[2];
            return raw.slice(0, 10);
          }

          const input = JSON.parse(readFileSync(0, "utf8"));
          const branch = run("git branch --show-current");
          const rawModel = input.model?.display_name || "";

          // Icon: ChatGPT uses  (OpenAI logo)
          const icon = "󰭹 ";

          // Repo name
          const gitCommon = run("git rev-parse --git-common-dir");
          let repo = "";
          if (gitCommon === ".git") {
            repo = run("git rev-parse --show-toplevel").split("/").pop() || "";
          } else if (gitCommon) {
            const parts = gitCommon.split("/");
            repo = parts[parts.length - 2] || "";
          }
          if (!repo) {
            repo = (input.workspace?.current_dir || "").split("/").pop() || "";
          }

          // Extract and center-pad model name
          const model = extractModel(rawModel);
          const width = 12;
          const padLeft = Math.floor((width - model.length) / 2);
          const padRight = width - model.length - padLeft;
          const modelPadded = " ".repeat(Math.max(0, padLeft)) + model + " ".repeat(Math.max(0, padRight));

          const sep = " ";

          // Build statusline
          let out = RESET;
          out += hexToBg(A_BG) + hexToFg(A_FG) + "▓▒░";
          out += hexToBg(A_BG) + hexToFg(A_FG) + " " + icon + modelPadded;
          out += hexToBg(B_BG) + hexToFg(A_BG) + sep;
          out += hexToBg(B_BG) + hexToFg(B_FG) + "󰊢 " + repo + " ";
          if (branch) {
            out += hexToBg(C_BG) + hexToFg(B_BG) + sep;
            out += hexToBg(C_BG) + hexToFg(C_FG) + " " + branch + " ";
            out += hexToFg(C_BG) + sep + RESET + CLR;
          } else {
            out += hexToFg(B_BG) + sep + RESET + CLR;
          }

          process.stdout.write(out);
        '';
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

      home.activation.installPiVim =
        config.lib.dag.entryAfter ["writeBoundary"]
        ''
          if [ ! -d "$HOME/.pi/agent/npm/lib/node_modules/@burneikis/pi-vim" ]; then
            $DRY_RUN_CMD ${piNpm}/bin/pi-npm install -g @burneikis/pi-vim
          fi
        '';

      # ========================================================================
      # Shell Integration
      # ========================================================================

      programs.zsh.shellAliases = {
        # ChatGPT aliases
        pi-gpt4 = "pi --provider openai --model gpt-4-turbo";
        pi-gpt35 = "pi --provider openai --model gpt-3.5-turbo";
      };

      # Set OpenAI API key environment variable
      # Note: Add your actual key to secrets or export it in your shell
      programs.zsh.sessionVariables = {
        # OPENAI_API_KEY = "your-key-here";  # Uncomment and set your key
      };
    };
}

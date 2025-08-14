{
  config,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.llm;
in {
  options.curtbushko.llm = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable llm
      '';
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      claude-code
    ];
    programs.vscode = {
      enable = true;
      package = (pkgs.vscodium.override {
        commandLineArgs = "--enable-features=UseOzonePlatform --ozone-platform-hint=auto --ozone-platform=wayland --enable-wayland-ime";
      });
      profiles.default = {
        extensions = with pkgs.vscode-extensions;
        [
          formulahendry.auto-close-tag
          formulahendry.auto-rename-tag
          golang.go
          gruntfuggly.todo-tree
          jnoortheen.nix-ide
          mkhl.direnv
          redhat.vscode-yaml
          rooveterinaryinc.roo-cline
          shardulm94.trailing-spaces
          vscodevim.vim
          vscode-icons-team.vscode-icons
          usernamehw.errorlens
          yzhang.markdown-all-in-one
          ziglang.vscode-zig
          zhuangtongfa.material-theme
        ];
        userSettings = {
          # UI Settings. Everything else is inherited from Stylix
          "workbench.iconTheme" = "vscode-icons";
          #"update.mode" = "none";
          # Git settings
          "git.allowForcePush" = true;
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "git.enableSmartCommit" = true;
          "git.openRepositoryInParentFolders" = "always";

          #"extensions.autoUpdate" = false;
          "editor.bracketPairColorization.enabled" = true;
          "editor.fontLigatures" =
            "'calt', 'ss01', 'ss02', 'ss03', 'ss04', 'ss05', 'ss06', 'ss07', 'ss08', 'ss09', 'ss10', 'dlig', 'liga'";
          "editor.formatOnPaste" = true;
          "editor.formatOnSave" = true;
          "editor.formatOnType" = false;
          "editor.guides.bracketPairs" = true;
          "editor.guides.indentation" = true;
          "editor.inlineSuggest.enabled" = true;
          "editor.minimap.enabled" = false;
          "editor.minimap.renderCharacters" = false;
          "editor.overviewRulerBorder" = false;
          "editor.renderLineHighlight" = "all";
          "editor.smoothScrolling" = true;
          "editor.suggestSelection" = "first";

          # Terminal
          "terminal.integrated.cursorBlinking" = true;
          "terminal.integrated.defaultProfile.linux" = "zsh";
          "terminal.integrated.enableVisualBell" = false;
          "terminal.integrated.gpuAcceleration" = "on";

          # Workbench
          "workbench.fontAliasing" = "antialiased";
          "workbench.list.smoothScrolling" = true;
          "workbench.panel.defaultLocation" = "right";
          "workbench.startupEditor" = "none";

          # Miscellaneous
          "breadcrumbs.enabled" = true;
          "explorer.confirmDelete" = false;
          "files.trimTrailingWhitespace" = true;
          "javascript.updateImportsOnFileMove.enabled" = "always";
          "security.workspace.trust.enabled" = false;
          "todo-tree.filtering.includeHiddenFiles" = true;
          "typescript.updateImportsOnFileMove.enabled" = "always";
          "vsicons.dontShowNewVersionMessage" = true;
          "window.nativeTabs" = true;
          "window.restoreWindows" = "all";
          "window.titleBarStyle" = "custom";

          # Language
          "zig.zls.enabled" = "on";
          # Roo Settings
          "roo-cline.allowedCommands" = [
            "npm test"
            "npm install"
            "tsc"
            "git log"
            "git diff"
            "git show"
            "zig build"
            "zig build run"
            "*"
          ];
        };
      };
    };
    home.file.".aider.conf.yml" = {
      text = with config.lib.stylix.colors.withHashtag; ''

        # Docs: https://aider.chat/docs/config/aider_conf.html

        #######
        # Main:

        model: ollama/llama3.1:8b
        check-update: false
        show-model-warnings: false


        ###############
        # Git Settings:

        ## Enable/disable auto commit of LLM changes (default: True)
        auto-commits: false

        ## Attribute aider code changes in the git author name (default: True)
        attribute-author: false

        ## Attribute aider commits in the git committer name (default: True)
        attribute-committer: false

        ###############
        # Output Settings:

        dark-mode: true
        pretty: true

        ## Set the color for user input (default: #00cc00)
        user-input-color: ${base0D}

        ## Set the color for tool output (default: None)
        #tool-output-color: ${base05}

        ## Set the color for tool error messages (default: #FF2222)
        tool-error-color: ${base08}

        ## Set the color for tool warning messages (default: #FFA500)
        tool-warning-color: ${base0A}

        ## Set the color for assistant output (default: #0088ff)
        assistant-output-color: ${base0C}

        ## Set the markdown code theme (default: default, other options include monokai, solarized-dark, solarized-light)
        code-theme: monokai

        ## Show diffs when committing changes (default: False)
        show-diffs: false

      '';
    };
  };
}

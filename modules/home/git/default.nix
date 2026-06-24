{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.git;

  # Build sem from source - semantic version control tool
  sem = pkgs.rustPlatform.buildRustPackage rec {
    pname = "sem";
    version = "0.3.21";
    src = pkgs.fetchFromGitHub {
      owner = "ataraxy-labs";
      repo = "sem";
      rev = "v${version}";
      sha256 = "sha256-FG1WK225RqA0WT71a1/TpsGa8v2bFkMzPL82zUqa3L8=";
    };

    # The Cargo workspace is in the crates/ subdirectory
    sourceRoot = "source/crates";

    cargoHash = "sha256-woog5FhtGGsB+70Q1VzYC/xu9YSL/JVp1vUrla/6JO8=";

    nativeBuildInputs = with pkgs; [pkg-config];
    buildInputs = with pkgs; [openssl];

    # Build only the CLI package
    cargoBuildFlags = ["--package" "sem-cli"];
    cargoTestFlags = ["--package" "sem-cli"];

    meta = with lib; {
      description = "Semantic version control tool that works on top of Git";
      homepage = "https://github.com/ataraxy-labs/sem";
      license = licenses.asl20;
      maintainers = [];
    };
  };
in {
  imports = [
    inputs.hunk.homeManagerModules.default
  ];

  options.curtbushko.git = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = ''
        Whether to enable git
      '';
    };
  };

  config = mkIf cfg.enable {
    # Create a signed wrapper for hunk on macOS that shadows the unsigned binary
    home.packages =
      [
        pkgs.gh
        pkgs.lazygit
        pkgs.git-lfs
        sem
      ]
      ++ lib.optionals pkgs.stdenv.isDarwin [
        (lib.hiPrio (pkgs.writeShellScriptBin "hunk" ''
          HUNK_CACHE="$HOME/.cache/hunk-signed"
          HUNK_BINARY="$HUNK_CACHE/hunk"

          # Check if we need to (re)create the signed binary
          if [ ! -f "$HUNK_BINARY" ] || [ "${inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/hunk" -nt "$HUNK_BINARY" ]; then
            mkdir -p "$HUNK_CACHE"
            cp "${inputs.hunk.packages.${pkgs.stdenv.hostPlatform.system}.default}/bin/hunk" "$HUNK_BINARY"
            chmod +w "$HUNK_BINARY"
            codesign -s - -f "$HUNK_BINARY" 2>/dev/null || true
          fi

          exec "$HUNK_BINARY" "$@"
        ''))
      ];

    programs.git = {
      enable = true;
      ignores = ["*~" ".DS_Store" ".direnv" ".env" ".rgignore" ".aider*"];
      settings = {
        user = {
          name = "Curt Bushko";
          email = "cbushko@gmail.com";
        };
        init = {defaultBranch = "main";};
        push.autoSetupRemote = true;
        pull = {ff = "only";};
        url."ssh://git@github.com".insteadOf = "https://github.com";
        url."ssh://git@github.ibm.com".insteadOf = "https://github.ibm.com";
        url."ssh://git@gitlab.com:".insteadOf = "https://gitlab.com/";
        oh-my-zsh = {hide-dirty = "1";}; # this stops slowdowns in some repos with zsh
        submodule.recurse = true;
        alias = {
          addp = "add -p";
          al = "!git config --get-regexp 'alias.*' | colrm 1 6 | sed 's/[ ]/ = /'";
          as = "update-index --assume-unchanged";
          br = "checkout";
          ci = "commit";
          co = "checkout";
          cp = "cherry-pick";
          di = "diff";
          dif = "diff";
          diffs = "diff --cached";
          gerp = "grep";
          grpe = "grep";
          hist = "log --pretty=format:\"%h %ad | %s%d [%an]\" --graph --date=short";
          nas = "update-index --no-assume-unchanged";
          pub = "push -u origin HEAD";
          pullf = "pull --ff-only";
          shoe = "show";
          st = "status";
          stat = "status";
        };
      };
    };

    programs.hunk = let
      # Read colors from flair's style.json in ~/.config/flair/
      # Note: Requires --impure flag for nix build/home-manager switch
      flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

      # Default fallback colors if flair style.json doesn't exist (gruvbox-material)
      defaultColors = {
        base00 = "#2d353b"; # Default Background
        base01 = "#232a2e"; # Lighter Background (status bars)
        base03 = "#859289"; # Comments
        base05 = "#d3c6aa"; # Default Foreground
        base08 = "#e67e80"; # Red
        base0B = "#a7c080"; # Green
        base0D = "#7fbbb3"; # Blue/Cyan
        base0E = "#d699b6"; # Purple/Magenta
      };

      colors =
        if builtins.pathExists flairStylePath
        then builtins.fromJSON (builtins.readFile flairStylePath)
        else defaultColors;
    in {
      enable = true;
      enableGitIntegration = true;
      settings = {
        theme = "custom";
        mode = "auto";
        line_numbers = true;
        custom_theme = {
          label = "Flair";

          # Main backgrounds - all base01
          background = colors.base01;
          panel = colors.base01;
          panelAlt = colors.base01;
          contextBg = colors.base01;
          contextContentBg = colors.base01;
          lineNumberBg = colors.base01;

          # Text colors
          text = colors.base05;
          muted = colors.base03;
          lineNumberFg = colors.base04;

          # Borders and accents
          border = colors.base02;
          accent = colors.base0D;
          accentMuted = colors.base0C;
          noteBorder = colors.base0E;
          noteBackground = colors.base01;
          noteTitleBackground = colors.base01;

          # Diff backgrounds (using flair's diff colors if available)
          addedBg = colors."diff-added-bg" or colors.base0B;
          removedBg = colors."diff-deleted-bg" or colors.base08;
          addedContentBg = colors."diff-added-bg" or colors.base0B;
          removedContentBg = colors."diff-deleted-bg" or colors.base08;

          # Diff signs
          addedSignColor = colors."diff-added-sign" or colors.base0B;
          removedSignColor = colors."diff-deleted-sign" or colors.base08;

          # File status colors
          fileNew = colors."git-added" or colors.base0B;
          fileDeleted = colors."git-deleted" or colors.base08;
          fileModified = colors."git-modified" or colors.base0D;

          # Syntax colors
          syntaxColors = {
            default = colors.base05;
            keyword = colors.base0E;
            string = colors.base0B;
            comment = colors.base03;
            operator = colors.base0D;
            variable = colors.base05;
          };
        };
      };
    };
  };
}

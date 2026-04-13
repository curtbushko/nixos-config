{
  config,
  inputs,
  lib,
  pkgs,
  ...
}: let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.git;
in {
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
    home.packages = [
      pkgs.gh
      pkgs.lazygit
      pkgs.git-lfs
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

    programs.delta = let
      # Read colors from flair's style.json in ~/.config/flair/
      # Note: Requires --impure flag for nix build/home-manager switch
      flairStylePath = "${config.home.homeDirectory}/.config/flair/style.json";

      # Default fallback colors if flair style.json doesn't exist (gruvbox-material)
      defaultColors = {
        base0D = "#7daea3";  # Blue
        base0A = "#d8a657";  # Yellow
        base05 = "#d4be98";  # Foreground
        base0E = "#9d7cd8";  # Purple
        "diff-added-bg" = "#46503b";
        "diff-added-fg" = "#a9b665";
        "diff-deleted-bg" = "#593837";
        "diff-deleted-fg" = "#ea6952";
        "diff-changed-bg" = "#353c3a";
        "diff-changed-fg" = "#89bcae";
      };

      colors = if builtins.pathExists flairStylePath
               then builtins.fromJSON (builtins.readFile flairStylePath)
               else defaultColors;
    in {
      enable = true;
      enableGitIntegration = true;
      options = {
        side-by-side = true;
        line-numbers = true;
        syntax-theme = "none";
        decorations = {
          commit-decoration-style = "${colors.base0D} ol";        # Blue
          hunk-header-decoration-style = "${colors.base0D} box";  # Blue
          hunk-header-file-style = colors.base0D;                 # Blue
          hunk-header-line-number-style = colors.base0A;          # Yellow
          hunk-header-style = "file line-number";
          file-decoration-style = "none";
          file-style = "bold ${colors.base0A} ul";                # Yellow
          minus-style = "${colors."diff-deleted-fg"} ${colors."diff-deleted-bg"}";
          minus-emph-style = "${colors."diff-deleted-fg"} ${colors."diff-deleted-bg"}";
          plus-style = "${colors."diff-added-fg"} ${colors."diff-added-bg"}";
          plus-emph-style = "${colors."diff-added-fg"} ${colors."diff-added-bg"}";
          zero-style = colors.base05;                             # Main foreground
          commit-style = "raw";
          line-numbers-minus-style = colors."diff-deleted-fg";
          line-numbers-plus-style = colors."diff-added-fg";
          line-numbers-zero-style = colors.base0E;                # Purple
        };
        features = "decorations line-numbers";
        whitespace-error-style = "22 reverse";
      };
    };

    programs.worktrunk = {
      enable = true;
    };
  };
  imports = [
    inputs.worktrunk.homeModules.default
  ];

}

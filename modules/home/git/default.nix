{
  config,
  lib,
  pkgs,
  ...
}:
let
  inherit (lib) types mkOption mkIf;
  cfg = config.curtbushko.git;
in
{
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
    home.packages = 
    [
      pkgs.gh
      pkgs.lazygit
      pkgs.git-lfs
    ];

    programs.git = {
      enable = true;
      userName = "Curt Bushko";
      userEmail = "cbushko@gmail.com";
      ignores = ["*~" ".DS_Store" ".direnv" ".env" ".rgignore" ".aider*"];
      extraConfig = {
        init = {defaultBranch = "main";};
        push.autoSetupRemote = true;
        pull = {ff = "only";};
        url."ssh://git@github.com".insteadOf = "https://github.com";
        oh-my-zsh = {hide-dirty = "1";}; # this stops slowdowns in some repos with zsh
        submodule.recurse = true;
      };
      delta = {
        enable = true;
        options = {
          side-by-side = true;
          line-numbers = true;
          decorations = {
            commit-decoration-style = "blue ol";
            hunk-header-decoration-style = "blue box";
            hunk-header-file-style = "blue";
            hunk-header-line-number-style = "#ff9e64";
            hunk-header-style = "file line-number";
            file-decoration-style = "none";
            file-style = "bold yellow ul";
            minus-style = "red";
            minus-emph-style = "#ff5370";
            plus-style = "green";
            zero-style = "white";
            commit-style = "raw";
            line-numbers-minus-style = "red";
            line-numbers-plus-style = "green";
            line-numbers-zero-style = "purple";
          };
          features = "decorations, syntax-theme, line-numbers";
          whitespace-error-style = "22 reverse";
        };
      };
      aliases = {
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
      };
    };
  };
}
